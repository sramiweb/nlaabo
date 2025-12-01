import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;
import '../utils/app_logger.dart';
import 'error_handler.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal() {
    _initializeProfiling();
  }

  final Map<String, Stopwatch> _activeTimers = {};
  final Queue<PerformanceMetric> _metrics = Queue();
  final Map<String, List<int>> _operationTimes = {};
  final Map<String, WidgetRebuildInfo> _widgetRebuilds = {};
  final Queue<NetworkRequestMetric> _networkMetrics = Queue();
  final Queue<MemoryUsageMetric> _memoryMetrics = Queue();

  static const int _maxMetricsHistory = 100;
  static const int _maxNetworkMetricsHistory = 50;
  static const int _maxMemoryMetricsHistory = 20;
  static const Duration _slowOperationThreshold = Duration(seconds: 2);
  static const Duration _memorySamplingInterval = Duration(seconds: 30);

  vm_service.VmService? _vmService;
  Timer? _memorySamplingTimer;
  final Map<String, PerformanceAlert> _activeAlerts = {};

  void _initializeProfiling() {
    if (!kDebugMode) return;

    // Initialize VM service for advanced profiling
    _connectToVmService();

    // Start memory sampling
    _startMemorySampling();
  }

  Future<void> _connectToVmService() async {
    try {
      final serverUri = (await developer.Service.getInfo()).serverUri;
      if (serverUri != null) {
        _vmService = await vm_service_io.vmServiceConnectUri(serverUri.toString());
      }
    } catch (e) {
      // VM service not available, continue without advanced profiling
      logWarning('VM service connection failed: $e');
    }
  }

  void _startMemorySampling() {
    _memorySamplingTimer = Timer.periodic(_memorySamplingInterval, (_) {
      _sampleMemoryUsage();
    });
  }

  Future<void> _sampleMemoryUsage() async {
    if (!kDebugMode) return;

    try {
      final memoryInfo = await _getMemoryInfo();
      if (memoryInfo != null) {
        _recordMemoryMetric(memoryInfo);
      }
    } catch (e) {
      // Memory sampling failed, continue
    }
  }

  Future<MemoryUsageInfo?> _getMemoryInfo() async {
    // Simplified memory tracking for basic monitoring
    // In a production app, you might use platform-specific APIs or third-party packages
    // for more accurate memory monitoring
    return MemoryUsageInfo(
      used: 0, // Placeholder - implement platform-specific memory tracking if needed
      capacity: 0,
      external: 0,
      timestamp: DateTime.now(),
    );
  }

  /// Start timing an operation
  void startTimer(String operationName) {
    if (!kDebugMode) return;
    
    final stopwatch = Stopwatch()..start();
    _activeTimers[operationName] = stopwatch;
  }

  /// Stop timing an operation and record the metric
  void stopTimer(String operationName, {Map<String, dynamic>? metadata}) {
    if (!kDebugMode) return;
    
    final stopwatch = _activeTimers.remove(operationName);
    if (stopwatch == null) return;
    
    stopwatch.stop();
    final duration = stopwatch.elapsedMilliseconds;
    
    _recordMetric(PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
    
    // Log slow operations
    if (stopwatch.elapsed > _slowOperationThreshold) {
      ErrorHandler.logError(
        'Slow operation detected: $operationName took ${stopwatch.elapsed}',
        null,
        'PerformanceMonitor',
      );
    }
  }

  /// Time an async operation
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!kDebugMode) return await operation();
    
    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName, metadata: metadata);
      return result;
    } catch (e) {
      stopTimer(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  /// Time a synchronous operation
  T timeSync<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    if (!kDebugMode) return operation();
    
    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName, metadata: metadata);
      return result;
    } catch (e) {
      stopTimer(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Track operation times for statistics
    _operationTimes.putIfAbsent(metric.operationName, () => []);
    _operationTimes[metric.operationName]!.add(metric.duration);
    
    // Keep only recent metrics
    while (_metrics.length > _maxMetricsHistory) {
      _metrics.removeFirst();
    }
    
    // Keep only recent operation times (last 50 per operation)
    for (final times in _operationTimes.values) {
      while (times.length > 50) {
        times.removeAt(0);
      }
    }
  }

  /// Get performance statistics for an operation
  PerformanceStats? getStats(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return null;
    
    times.sort();
    final count = times.length;
    final sum = times.reduce((a, b) => a + b);
    final average = sum / count;
    final median = count % 2 == 0
        ? (times[count ~/ 2 - 1] + times[count ~/ 2]) / 2
        : times[count ~/ 2].toDouble();
    final p95 = times[(count * 0.95).floor()];
    final min = times.first;
    final max = times.last;
    
    return PerformanceStats(
      operationName: operationName,
      count: count,
      averageMs: average,
      medianMs: median,
      p95Ms: p95,
      minMs: min,
      maxMs: max,
    );
  }

  /// Get all performance statistics
  Map<String, PerformanceStats> getAllStats() {
    final stats = <String, PerformanceStats>{};
    for (final operationName in _operationTimes.keys) {
      final stat = getStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }
    return stats;
  }

  /// Get recent metrics
  List<PerformanceMetric> getRecentMetrics({int limit = 20}) {
    final recent = _metrics.toList();
    recent.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return recent.take(limit).toList();
  }

  /// Get slow operations (above threshold)
  List<PerformanceMetric> getSlowOperations() {
    return _metrics
        .where((m) => m.duration > _slowOperationThreshold.inMilliseconds)
        .toList();
  }

  /// Record network request performance
  void recordNetworkRequest({
    required String url,
    required String method,
    required int statusCode,
    required int responseTimeMs,
    int? requestSizeBytes,
    int? responseSizeBytes,
    String? error,
  }) {
    if (!kDebugMode) return;

    final metric = NetworkRequestMetric(
      url: url,
      method: method,
      statusCode: statusCode,
      responseTimeMs: responseTimeMs,
      requestSizeBytes: requestSizeBytes,
      responseSizeBytes: responseSizeBytes,
      error: error,
      timestamp: DateTime.now(),
    );

    _networkMetrics.add(metric);

    // Keep only recent network metrics
    while (_networkMetrics.length > _maxNetworkMetricsHistory) {
      _networkMetrics.removeFirst();
    }

    // Check for slow network requests
    if (responseTimeMs > 5000) { // 5 seconds threshold
      _triggerAlert(
        'Slow Network Request',
        'Network request to $url took ${responseTimeMs}ms',
        AlertSeverity.warning,
      );
    }

    // Check for failed requests
    if (statusCode >= 400) {
      _triggerAlert(
        'Network Request Failed',
        'Request to $url failed with status $statusCode',
        AlertSeverity.error,
      );
    }
  }

  /// Track widget rebuilds
  void trackWidgetRebuild(String widgetName, {Map<String, dynamic>? metadata}) {
    if (!kDebugMode) return;

    final info = _widgetRebuilds.putIfAbsent(widgetName, () => WidgetRebuildInfo(widgetName));
    info.rebuildCount++;
    info.lastRebuild = DateTime.now();
    info.metadata = metadata;

    // Alert on excessive rebuilds
    if (info.rebuildCount > 10) {
      _triggerAlert(
        'Excessive Widget Rebuilds',
        'Widget $widgetName has been rebuilt ${info.rebuildCount} times',
        AlertSeverity.warning,
      );
    }
  }

  void _recordMemoryMetric(MemoryUsageInfo info) {
    final metric = MemoryUsageMetric(
      usedBytes: info.used,
      capacityBytes: info.capacity,
      externalBytes: info.external,
      timestamp: info.timestamp,
    );

    _memoryMetrics.add(metric);

    // Keep only recent memory metrics
    while (_memoryMetrics.length > _maxMemoryMetricsHistory) {
      _memoryMetrics.removeFirst();
    }

    // Check for high memory usage
    final usagePercent = (info.used / info.capacity) * 100;
    if (usagePercent > 80) {
      _triggerAlert(
        'High Memory Usage',
        'Memory usage is at ${usagePercent.toStringAsFixed(1)}%',
        AlertSeverity.warning,
      );
    }
  }

  void _triggerAlert(String title, String message, AlertSeverity severity) {
    final alert = PerformanceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      severity: severity,
      timestamp: DateTime.now(),
    );

    _activeAlerts[alert.id] = alert;

    // Log alert
    ErrorHandler.logError(
      'Performance Alert: $title - $message',
      null,
      'PerformanceMonitor',
    );

    // Auto-resolve alerts after 5 minutes
    Future.delayed(const Duration(minutes: 5), () {
      _activeAlerts.remove(alert.id);
    });
  }

  /// Get network performance statistics
  NetworkStats getNetworkStats() {
    if (_networkMetrics.isEmpty) {
      return NetworkStats.empty();
    }

    final responseTimes = _networkMetrics.map((m) => m.responseTimeMs).toList();
    responseTimes.sort();

    final successCount = _networkMetrics.where((m) => m.statusCode < 400).length;
    final errorCount = _networkMetrics.length - successCount;

    return NetworkStats(
      totalRequests: _networkMetrics.length,
      successCount: successCount,
      errorCount: errorCount,
      averageResponseTimeMs: responseTimes.reduce((a, b) => a + b) / responseTimes.length,
      p95ResponseTimeMs: responseTimes[(responseTimes.length * 0.95).floor()],
      slowestRequest: _networkMetrics
          .reduce((a, b) => a.responseTimeMs > b.responseTimeMs ? a : b),
    );
  }

  /// Get widget rebuild statistics
  Map<String, WidgetRebuildInfo> getWidgetRebuildStats() {
    return Map.from(_widgetRebuilds);
  }

  /// Get memory usage statistics
  MemoryStats getMemoryStats() {
    if (_memoryMetrics.isEmpty) {
      return MemoryStats.empty();
    }

    final usages = _memoryMetrics.map((m) => m.usedBytes).toList();
    usages.sort();

    return MemoryStats(
      averageUsageBytes: usages.reduce((a, b) => a + b) ~/ usages.length,
      peakUsageBytes: usages.last,
      currentUsageBytes: _memoryMetrics.last.usedBytes,
      sampleCount: _memoryMetrics.length,
    );
  }

  /// Get active performance alerts
  List<PerformanceAlert> getActiveAlerts() {
    return _activeAlerts.values.toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _operationTimes.clear();
    _activeTimers.clear();
    _networkMetrics.clear();
    _memoryMetrics.clear();
    _widgetRebuilds.clear();
    _activeAlerts.clear();
  }

  /// Generate comprehensive performance report
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('=== Comprehensive Performance Report ===');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln();

    // Operation Performance
    final stats = getAllStats();
    if (stats.isNotEmpty) {
      buffer.writeln('=== Operation Performance ===');
      final sortedStats = stats.values.toList()
        ..sort((a, b) => b.averageMs.compareTo(a.averageMs));

      buffer.writeln('Operation Performance (sorted by average time):');
      buffer.writeln('${'Operation'.padRight(30)} ${'Count'.padLeft(6)} ${'Avg(ms)'.padLeft(8)} ${'Med(ms)'.padLeft(8)} ${'P95(ms)'.padLeft(8)} ${'Min(ms)'.padLeft(8)} ${'Max(ms)'.padLeft(8)}');
      buffer.writeln('-' * 90);

      for (final stat in sortedStats) {
        buffer.writeln(
          '${stat.operationName.padRight(30)} '
          '${stat.count.toString().padLeft(6)} '
          '${stat.averageMs.toStringAsFixed(1).padLeft(8)} '
          '${stat.medianMs.toStringAsFixed(1).padLeft(8)} '
          '${stat.p95Ms.toString().padLeft(8)} '
          '${stat.minMs.toString().padLeft(8)} '
          '${stat.maxMs.toString().padLeft(8)}'
        );
      }
      buffer.writeln();
    }

    // Network Performance
    final networkStats = getNetworkStats();
    if (networkStats.totalRequests > 0) {
      buffer.writeln('=== Network Performance ===');
      buffer.writeln('Total Requests: ${networkStats.totalRequests}');
      buffer.writeln('Success Rate: ${((networkStats.successCount / networkStats.totalRequests) * 100).toStringAsFixed(1)}%');
      buffer.writeln('Average Response Time: ${networkStats.averageResponseTimeMs.toStringAsFixed(1)}ms');
      buffer.writeln('95th Percentile: ${networkStats.p95ResponseTimeMs}ms');
      buffer.writeln('Slowest Request: ${networkStats.slowestRequest?.url ?? 'N/A'} (${networkStats.slowestRequest?.responseTimeMs}ms)');
      buffer.writeln();
    }

    // Memory Usage
    final memoryStats = getMemoryStats();
    if (memoryStats.sampleCount > 0) {
      buffer.writeln('=== Memory Usage ===');
      buffer.writeln('Average Usage: ${(memoryStats.averageUsageBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      buffer.writeln('Peak Usage: ${(memoryStats.peakUsageBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      buffer.writeln('Current Usage: ${(memoryStats.currentUsageBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      buffer.writeln();
    }

    // Widget Rebuilds
    final rebuildStats = getWidgetRebuildStats();
    if (rebuildStats.isNotEmpty) {
      buffer.writeln('=== Widget Rebuilds ===');
      final sortedRebuilds = rebuildStats.values.toList()
        ..sort((a, b) => b.rebuildCount.compareTo(a.rebuildCount));

      for (final info in sortedRebuilds.take(10)) {
        buffer.writeln('${info.widgetName}: ${info.rebuildCount} rebuilds (last: ${info.lastRebuild})');
      }
      buffer.writeln();
    }

    // Active Alerts
    final alerts = getActiveAlerts();
    if (alerts.isNotEmpty) {
      buffer.writeln('=== Active Alerts ===');
      for (final alert in alerts) {
        buffer.writeln('[${alert.severity.name.toUpperCase()}] ${alert.title}: ${alert.message}');
      }
      buffer.writeln();
    }

    // Slow operations
    final slowOps = getSlowOperations();
    if (slowOps.isNotEmpty) {
      buffer.writeln('=== Slow Operations ===');
      buffer.writeln('Operations taking >${_slowOperationThreshold.inSeconds}s:');
      for (final op in slowOps.take(10)) {
        buffer.writeln('- ${op.operationName}: ${op.duration}ms at ${op.timestamp}');
      }
      buffer.writeln();
    }

    if (stats.isEmpty && networkStats.totalRequests == 0 && memoryStats.sampleCount == 0) {
      buffer.writeln('No performance data available.');
    }

    return buffer.toString();
  }

  /// Log performance report to debug console
  void logReport() {
    if (kDebugMode) {
      logInfo(generateReport());
    }
  }

  /// Export performance data for external analysis
  Map<String, dynamic> exportPerformanceData() {
    return {
      'operationStats': getAllStats().map((key, value) => MapEntry(key, {
        'count': value.count,
        'averageMs': value.averageMs,
        'medianMs': value.medianMs,
        'p95Ms': value.p95Ms,
        'minMs': value.minMs,
        'maxMs': value.maxMs,
      })),
      'networkStats': {
        'totalRequests': getNetworkStats().totalRequests,
        'successCount': getNetworkStats().successCount,
        'errorCount': getNetworkStats().errorCount,
        'averageResponseTimeMs': getNetworkStats().averageResponseTimeMs,
        'p95ResponseTimeMs': getNetworkStats().p95ResponseTimeMs,
      },
      'memoryStats': {
        'averageUsageBytes': getMemoryStats().averageUsageBytes,
        'peakUsageBytes': getMemoryStats().peakUsageBytes,
        'currentUsageBytes': getMemoryStats().currentUsageBytes,
        'sampleCount': getMemoryStats().sampleCount,
      },
      'widgetRebuilds': getWidgetRebuildStats().map((key, value) => MapEntry(key, {
        'rebuildCount': value.rebuildCount,
        'lastRebuild': value.lastRebuild?.toIso8601String(),
      })),
      'activeAlerts': getActiveAlerts().map((alert) => {
        'id': alert.id,
        'title': alert.title,
        'message': alert.message,
        'severity': alert.severity.name,
        'timestamp': alert.timestamp.toIso8601String(),
      }).toList(),
      'exportTimestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose resources
  void dispose() {
    _memorySamplingTimer?.cancel();
    _vmService?.dispose();
    clearMetrics();
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operationName;
  final int duration; // in milliseconds
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

/// Performance statistics data class
class PerformanceStats {
  final String operationName;
  final int count;
  final double averageMs;
  final double medianMs;
  final int p95Ms;
  final int minMs;
  final int maxMs;

  PerformanceStats({
    required this.operationName,
    required this.count,
    required this.averageMs,
    required this.medianMs,
    required this.p95Ms,
    required this.minMs,
    required this.maxMs,
  });
}

/// Network request performance metric
class NetworkRequestMetric {
  final String url;
  final String method;
  final int statusCode;
  final int responseTimeMs;
  final int? requestSizeBytes;
  final int? responseSizeBytes;
  final String? error;
  final DateTime timestamp;

  NetworkRequestMetric({
    required this.url,
    required this.method,
    required this.statusCode,
    required this.responseTimeMs,
    this.requestSizeBytes,
    this.responseSizeBytes,
    this.error,
    required this.timestamp,
  });
}

/// Network performance statistics
class NetworkStats {
  final int totalRequests;
  final int successCount;
  final int errorCount;
  final double averageResponseTimeMs;
  final int p95ResponseTimeMs;
  final NetworkRequestMetric? slowestRequest;

  NetworkStats({
    required this.totalRequests,
    required this.successCount,
    required this.errorCount,
    required this.averageResponseTimeMs,
    required this.p95ResponseTimeMs,
    this.slowestRequest,
  });

  factory NetworkStats.empty() => NetworkStats(
    totalRequests: 0,
    successCount: 0,
    errorCount: 0,
    averageResponseTimeMs: 0,
    p95ResponseTimeMs: 0,
  );
}

/// Widget rebuild information
class WidgetRebuildInfo {
  final String widgetName;
  int rebuildCount;
  DateTime? lastRebuild;
  Map<String, dynamic>? metadata;

  WidgetRebuildInfo(this.widgetName) : rebuildCount = 0;
}

/// Memory usage information
class MemoryUsageInfo {
  final int used;
  final int capacity;
  final int external;
  final DateTime timestamp;

  MemoryUsageInfo({
    required this.used,
    required this.capacity,
    required this.external,
    required this.timestamp,
  });
}

/// Memory usage metric
class MemoryUsageMetric {
  final int usedBytes;
  final int capacityBytes;
  final int externalBytes;
  final DateTime timestamp;

  MemoryUsageMetric({
    required this.usedBytes,
    required this.capacityBytes,
    required this.externalBytes,
    required this.timestamp,
  });
}

/// Memory statistics
class MemoryStats {
  final int averageUsageBytes;
  final int peakUsageBytes;
  final int currentUsageBytes;
  final int sampleCount;

  MemoryStats({
    required this.averageUsageBytes,
    required this.peakUsageBytes,
    required this.currentUsageBytes,
    required this.sampleCount,
  });

  factory MemoryStats.empty() => MemoryStats(
    averageUsageBytes: 0,
    peakUsageBytes: 0,
    currentUsageBytes: 0,
    sampleCount: 0,
  );
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  error,
}

/// Performance alert
class PerformanceAlert {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;

  PerformanceAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
  });
}

/// Extension for easy performance monitoring
extension PerformanceMonitorExtension<T> on Future<T> Function() {
  Future<T> withPerformanceMonitoring(String operationName, {Map<String, dynamic>? metadata}) {
    return PerformanceMonitor().timeOperation(operationName, this, metadata: metadata);
  }
}

extension SyncPerformanceMonitorExtension<T> on T Function() {
  T withPerformanceMonitoring(String operationName, {Map<String, dynamic>? metadata}) {
    return PerformanceMonitor().timeSync(operationName, this, metadata: metadata);
  }
}
