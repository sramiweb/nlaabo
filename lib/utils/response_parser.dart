import '../utils/app_logger.dart';
import '../services/error_handler.dart';

/// Standardized response parsing utility for consistent API response handling
class ResponseParser {
  /// Parse a single JSON object response
  static T parseSingle<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
  }) {
    if (response == null) {
      throw ValidationError('Response is null');
    }

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    try {
      return fromJson(response);
    } catch (e) {
      logError('Failed to parse single response in $context: $e');
      rethrow;
    }
  }

  /// Parse a list of JSON objects
  static List<T> parseList<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
    bool skipInvalid = true,
  }) {
    if (response == null) {
      return <T>[];
    }

    if (response is! List) {
      throw ValidationError('Expected List, got ${response.runtimeType}');
    }

    final List<T> items = [];
    int skippedCount = 0;

    for (final dynamic item in response) {
      if (item == null) {
        if (!skipInvalid) throw ValidationError('Null item in list');
        skippedCount++;
        continue;
      }

      try {
        final Map<String, dynamic> itemData = item as Map<String, dynamic>;
        items.add(fromJson(itemData));
      } catch (e) {
        if (!skipInvalid) {
          logError('Failed to parse list item in $context: $e');
          rethrow;
        }
        logDebug('Skipped invalid item in $context: $e');
        skippedCount++;
      }
    }

    if (skippedCount > 0) {
      logDebug('$context: Parsed ${items.length} items (skipped: $skippedCount)');
    }

    return items;
  }

  /// Parse a nested object from response
  static T? parseNested<T>(
    dynamic response,
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
  }) {
    if (response == null) return null;

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    final nested = response[key];
    if (nested == null) return null;

    if (nested is! Map<String, dynamic>) {
      throw ValidationError('Expected nested Map<String, dynamic>, got ${nested.runtimeType}');
    }

    try {
      return fromJson(nested);
    } catch (e) {
      logError('Failed to parse nested object "$key" in $context: $e');
      rethrow;
    }
  }

  /// Parse a list of nested objects from response
  static List<T> parseNestedList<T>(
    dynamic response,
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    String? context,
    bool skipInvalid = true,
  }) {
    if (response == null) return <T>[];

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    final nested = response[key];
    if (nested == null) return <T>[];

    return parseList(nested, fromJson, context: '$context.$key', skipInvalid: skipInvalid);
  }

  /// Validate response structure before parsing
  static void validateStructure(
    dynamic response, {
    required List<String> requiredFields,
    String? context,
  }) {
    if (response == null) {
      throw ValidationError('Response is null');
    }

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    for (final field in requiredFields) {
      if (!response.containsKey(field) || response[field] == null) {
        throw ValidationError('Missing required field: $field in $context');
      }
    }
  }

  /// Extract and validate a field from response
  static T? extractField<T>(
    dynamic response,
    String fieldName, {
    T? defaultValue,
    String? context,
  }) {
    if (response == null) return defaultValue;

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    final value = response[fieldName];
    if (value == null) return defaultValue;

    if (value is! T) {
      logWarning('Field "$fieldName" has unexpected type ${value.runtimeType}, expected $T in $context');
      return defaultValue;
    }

    return value;
  }

  /// Parse response with custom validation
  static T parseWithValidation<T>(
    dynamic response,
    T Function(Map<String, dynamic>) fromJson, {
    bool Function(Map<String, dynamic>)? validate,
    String? context,
  }) {
    if (response == null) {
      throw ValidationError('Response is null');
    }

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    if (validate != null && !validate(response)) {
      throw ValidationError('Response validation failed in $context');
    }

    try {
      return fromJson(response);
    } catch (e) {
      logError('Failed to parse response with validation in $context: $e');
      rethrow;
    }
  }

  /// Handle paginated responses
  static Map<String, dynamic> parsePaginated(
    dynamic response, {
    String? context,
  }) {
    if (response == null) {
      return {
        'data': <dynamic>[],
        'total': 0,
        'page': 1,
        'pageSize': 0,
      };
    }

    if (response is! Map<String, dynamic>) {
      throw ValidationError('Expected Map<String, dynamic>, got ${response.runtimeType}');
    }

    return {
      'data': response['data'] ?? <dynamic>[],
      'total': response['total'] ?? 0,
      'page': response['page'] ?? 1,
      'pageSize': response['pageSize'] ?? response['page_size'] ?? 0,
    };
  }

  /// Safe type casting with fallback
  static T? safeCast<T>(
    dynamic value, {
    T? defaultValue,
    String? context,
  }) {
    try {
      if (value is T) return value;
      return defaultValue;
    } catch (e) {
      logDebug('Safe cast failed for type $T in $context: $e');
      return defaultValue;
    }
  }

  /// Parse response with error recovery
  static Future<T> parseWithRecovery<T>(
    Future<dynamic> Function() operation,
    T Function(Map<String, dynamic>) fromJson, {
    T? fallbackValue,
    String? context,
  }) async {
    try {
      final response = await operation();
      return parseSingle(response, fromJson, context: context);
    } catch (e) {
      if (fallbackValue != null) {
        logWarning('Parse operation failed, using fallback in $context: $e');
        return fallbackValue;
      }
      rethrow;
    }
  }
}
