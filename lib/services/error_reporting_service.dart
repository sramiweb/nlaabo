import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'error_handler.dart';
import '../config/supabase_config.dart';

/// Service for reporting errors to external monitoring systems
class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  static const String _reportingEndpoint = 'https://api.sentry.io/api/0/projects/{project}/events/';
  static const String _sentryDsn = ''; // Would be configured in production

  // Device info will be collected manually without external packages for now
  Map<String, dynamic>? _cachedDeviceInfo;

  /// Initialize the error reporting service
  Future<void> initialize() async {
    // Cache device info on initialization
    _cachedDeviceInfo = await _getDeviceInfo();
  }

  /// Report an error to monitoring systems
  Future<void> reportError(
    AppError error, {
    String? userId,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (kReleaseMode && _sentryDsn.isEmpty) {
      // Don't report in production without proper DSN
      return;
    }

    try {
      final errorReport = await _buildErrorReport(
        error,
        userId: userId,
        context: context,
        additionalData: additionalData,
      );

      await _sendToSentry(errorReport);
      await _sendToCustomEndpoint(errorReport);

      debugPrint('Error reported successfully: ${error.code}');
    } catch (e) {
      debugPrint('Failed to report error: $e');
      // Don't throw here to avoid cascading errors
    }
  }

  /// Report a non-fatal issue for monitoring
  Future<void> reportIssue(
    String message, {
    String? category,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final issueReport = await _buildIssueReport(
        message,
        category: category,
        userId: userId,
        additionalData: additionalData,
      );

      await _sendToCustomEndpoint(issueReport);
      debugPrint('Issue reported: $category');
    } catch (e) {
      debugPrint('Failed to report issue: $e');
    }
  }

  /// Build a comprehensive error report
  Future<Map<String, dynamic>> _buildErrorReport(
    AppError error, {
    String? userId,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    final deviceInfo = await _getDeviceInfo();
    final timestamp = DateTime.now().toUtc().toIso8601String();

    return {
      'error': {
        'type': error.runtimeType.toString(),
        'code': error.code,
        'message': error.message,
        'original_error': error.originalError?.toString(),
        'stack_trace': error.stackTrace?.toString(),
      },
      'context': {
        'user_id': userId,
        'operation_context': context,
        'timestamp': timestamp,
        'app_version': '1.0.0', // TODO: Get from pubspec.yaml
        'build_number': '1', // TODO: Get from pubspec.yaml
      },
      'device': deviceInfo,
      'environment': {
        'platform': kIsWeb ? 'web' : 'mobile',
        'debug_mode': kDebugMode,
        'release_mode': kReleaseMode,
        'profile_mode': kProfileMode,
      },
      'additional_data': additionalData ?? {},
    };
  }

  /// Build an issue report
  Future<Map<String, dynamic>> _buildIssueReport(
    String message, {
    String? category,
    String? userId,
    Map<String, dynamic>? additionalData,
  }) async {
    final deviceInfo = await _getDeviceInfo();
    final timestamp = DateTime.now().toUtc().toIso8601String();

    return {
      'issue': {
        'message': message,
        'category': category ?? 'general',
      },
      'context': {
        'user_id': userId,
        'timestamp': timestamp,
        'app_version': '1.0.0', // TODO: Get from pubspec.yaml
      },
      'device': deviceInfo,
      'environment': {
        'platform': kIsWeb ? 'web' : 'mobile',
        'debug_mode': kDebugMode,
      },
      'additional_data': additionalData ?? {},
    };
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    if (_cachedDeviceInfo != null) {
      return _cachedDeviceInfo!;
    }

    try {
      if (kIsWeb) {
        return {
          'platform': 'web',
          'browser': 'unknown',
          'user_agent': 'unknown',
        };
      } else {
        // Mobile platforms - basic info without external packages
        return {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
          'locale': Platform.localeName,
        };
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }

    return {
      'platform': 'unknown',
      'error': 'Failed to retrieve device information',
    };
  }

  /// Send error report to Sentry
  Future<void> _sendToSentry(Map<String, dynamic> report) async {
    if (_sentryDsn.isEmpty) return;

    try {
      final sentryEvent = _convertToSentryEvent(report);
      final response = await http.post(
        Uri.parse(_reportingEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_sentryDsn',
        },
        body: jsonEncode(sentryEvent),
      );

      if (response.statusCode != 200) {
        debugPrint('Sentry reporting failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to send to Sentry: $e');
    }
  }

  /// Send report to custom monitoring endpoint
  Future<void> _sendToCustomEndpoint(Map<String, dynamic> report) async {
    try {
      // Get credentials asynchronously
      final url = await supabaseUrl;
      final key = await supabaseAnonKey;
      
      if (url.isEmpty || key.isEmpty) return;
      
      final customEndpoint = '$url/functions/v1';

      final response = await http.post(
        Uri.parse('$customEndpoint/errors'),
        headers: {
          'Content-Type': 'application/json',
          'apikey': key,
        },
        body: jsonEncode(report),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Custom endpoint reporting failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to send to custom endpoint: $e');
    }
  }

  /// Convert our error report to Sentry event format
  Map<String, dynamic> _convertToSentryEvent(Map<String, dynamic> report) {
    final error = report['error'] as Map<String, dynamic>;
    final context = report['context'] as Map<String, dynamic>;
    final device = report['device'] as Map<String, dynamic>;

    return {
      'event_id': _generateEventId(),
      'timestamp': context['timestamp'],
      'level': 'error',
      'platform': 'flutter',
      'exception': {
        'values': [
          {
            'type': error['type'],
            'value': error['message'],
            'stacktrace': {
              'frames': _parseStackTrace(error['stack_trace']),
            },
          },
        ],
      },
      'tags': {
        'error_code': error['code'],
        'app_version': context['app_version'],
        'platform': device['platform'],
      },
      'user': {
        'id': context['user_id'],
      },
      'contexts': {
        'device': device,
        'app': {
          'app_version': context['app_version'],
          'build_number': context['build_number'],
        },
      },
    };
  }

  /// Generate a unique event ID
  String _generateEventId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${1000 + (DateTime.now().microsecondsSinceEpoch % 9000)}';
  }

  /// Parse stack trace into Sentry frame format
  List<Map<String, dynamic>> _parseStackTrace(String? stackTrace) {
    if (stackTrace == null) return [];

    final frames = <Map<String, dynamic>>[];
    final lines = stackTrace.split('\n');

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // Basic stack trace parsing - could be enhanced
      frames.add({
        'filename': 'unknown',
        'function': 'unknown',
        'lineno': 0,
        'in_app': true,
        'context_line': line.trim(),
      });
    }

    return frames;
  }

  /// Get error statistics for monitoring
  Map<String, int> getErrorStatistics() {
    // This would track error counts in a real implementation
    return {
      'total_errors': 0,
      'network_errors': 0,
      'auth_errors': 0,
      'validation_errors': 0,
    };
  }

  /// Clear error statistics (useful for testing)
  void clearStatistics() {
    // Implementation would clear stored statistics
    debugPrint('Error statistics cleared');
  }
}
