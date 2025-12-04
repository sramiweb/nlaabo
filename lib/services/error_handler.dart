import 'package:flutter/foundation.dart';
import 'localization_service.dart';
import 'dart:async';

/// Error types for app initialization failures
enum AppInitializationError {
  configurationMissing,
  configurationInvalid,
  networkUnavailable,
  supabaseUnreachable,
  unknown,
}

/// Standardized error types for consistent error handling across the app
abstract class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError(this.message, {this.code, this.originalError, this.stackTrace});

  @override
  String toString() => message;
}

/// Network-related errors (connection, timeout, etc.)
class NetworkError extends AppError {
  NetworkError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'NETWORK_ERROR');
}

/// Authentication and authorization errors
class AuthError extends AppError {
  AuthError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'AUTH_ERROR');
}

/// Validation errors (invalid input, missing fields, etc.)
class ValidationError extends AppError {
  ValidationError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'VALIDATION_ERROR');
}

/// Database and server errors
class DatabaseError extends AppError {
  DatabaseError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'DATABASE_ERROR');
}

/// Upload/storage related errors
class UploadError extends AppError {
  UploadError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'UPLOAD_ERROR');
}

/// Generic application errors
class GenericError extends AppError {
  GenericError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'GENERIC_ERROR');
}

/// Permission and access control errors
class PermissionError extends AppError {
  PermissionError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'PERMISSION_ERROR');
}

/// Rate limiting errors
class RateLimitError extends AppError {
  final Duration retryAfter;

  RateLimitError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
    this.retryAfter = const Duration(seconds: 60),
  }) : super(code: code ?? 'RATE_LIMIT_ERROR');
}

/// Timeout errors for operations that take too long
class TimeoutError extends AppError {
  final Duration timeoutDuration;

  TimeoutError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
    this.timeoutDuration = const Duration(seconds: 30),
  }) : super(code: code ?? 'TIMEOUT_ERROR');
}

/// Configuration and setup errors
class ConfigurationError extends AppError {
  ConfigurationError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'CONFIGURATION_ERROR');
}

/// Offline mode errors when operations require connectivity
class OfflineError extends AppError {
  OfflineError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'OFFLINE_ERROR');
}

/// Data integrity and consistency errors
class DataIntegrityError extends AppError {
  DataIntegrityError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'DATA_INTEGRITY_ERROR');
}

/// Service unavailable errors
class ServiceUnavailableError extends AppError {
  final bool isTemporary;

  ServiceUnavailableError(
    super.message, {
    String? code,
    super.originalError,
    super.stackTrace,
    this.isTemporary = true,
  }) : super(code: code ?? 'SERVICE_UNAVAILABLE_ERROR');
}

/// Input validation errors with field-specific information
class FieldValidationError extends ValidationError {
  final String fieldName;
  final String? fieldValue;

  FieldValidationError(
    super.message, {
    required this.fieldName,
    this.fieldValue,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'FIELD_VALIDATION_ERROR');
}

/// Business logic errors (domain-specific validation failures)
class BusinessLogicError extends AppError {
  final String operation;
  final Map<String, dynamic>? context;

  BusinessLogicError(
    super.message, {
    required this.operation,
    this.context,
    String? code,
    super.originalError,
    super.stackTrace,
  }) : super(code: code ?? 'BUSINESS_LOGIC_ERROR');
}

/// Retry configuration for failed operations
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(AppError)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });
}

/// Enhanced error handler with retry logic and standardized error types
class ErrorHandler {
  static const RetryConfig defaultRetryConfig = RetryConfig();

  /// Convert any exception to a standardized AppError
  static AppError standardizeError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) return error;
    if (error == null) return GenericError('Unknown error occurred', stackTrace: stackTrace);

    final String errorString = error.toString().toLowerCase();

    // DNS resolution errors
    if (errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('nodename nor servname provided')) {
      return NetworkError(
        'Cannot connect to FootConnect servers. Please check your internet connection and try switching between WiFi and mobile data.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
    
    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('timed out') ||
        errorString.contains('timeout') ||
        errorString.contains('connection refused')) {
      return NetworkError(
        LocalizationService().translate('error_network'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Auth errors
    if (errorString.contains('unauthor') ||
        errorString.contains('401') ||
        errorString.contains('not authenticated') ||
        errorString.contains('invalid token') ||
        errorString.contains('expired token')) {
      return AuthError(
        LocalizationService().translate('error_unauthorized'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Validation errors
    if (errorString.contains('invalid') ||
        errorString.contains('validation') ||
        errorString.contains('missing') ||
        errorString.contains('required') ||
        errorString.contains('bad request') ||
        errorString.contains('400')) {
      return ValidationError(
        LocalizationService().translate('error_invalid_input'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Upload/storage errors
    if (errorString.contains('upload') ||
        errorString.contains('storage') ||
        errorString.contains('s3') ||
        errorString.contains('avatar')) {
      return UploadError(
        LocalizationService().translate('error_upload_failed'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Database errors
    if (errorString.contains('database') ||
        errorString.contains('null value') ||
        errorString.contains('pg') ||
        errorString.contains('foreign key')) {
       return DatabaseError(
         LocalizationService().translate('error_database'),
         originalError: error,
         stackTrace: stackTrace,
       );
    }

    // Duplicate key constraint errors (specific handling)
    if (errorString.contains('duplicate') ||
        errorString.contains('unique constraint') ||
        errorString.contains('violates unique constraint') ||
        errorString.contains('already exists')) {
       // Check if it's related to user registration
       if (errorString.contains('users_email_key') ||
           errorString.contains('users.email') ||
           errorString.contains('user') ||
           errorString.contains('email')) {
         return ValidationError(
           'An account with this email already exists. Please try logging in instead.',
           code: 'DUPLICATE_EMAIL',
           originalError: error,
           stackTrace: stackTrace,
         );
       } else {
         return DatabaseError(
           'This information already exists. Please use different values.',
           code: 'DUPLICATE_DATA',
           originalError: error,
           stackTrace: stackTrace,
         );
       }
    }

    // Constraint violations
    if (errorString.contains('constraint') ||
        errorString.contains('violates check constraint')) {
       return ValidationError(
         'Invalid data provided. Please check your information and try again.',
         code: 'CONSTRAINT_VIOLATION',
         originalError: error,
         stackTrace: stackTrace,
       );
    }

    // Show detailed signup errors but filter out network false positives
    if (errorString.contains('signup failed:')) {
      String message = error.toString();
      // If it's a DNS error during signup, provide a more helpful message
      if (message.contains('failed host lookup') || message.contains('no address associated with hostname')) {
        return NetworkError(
          'Cannot connect to FootConnect servers. Please check your internet connection and try again. If the problem persists, try switching between WiFi and mobile data.',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
      // If it's a network error during signup, provide a more helpful message
      if (message.contains('network connectivity lost') || message.contains('no internet connection')) {
        return NetworkError(
          'Connection issue during signup. Please check your internet connection and try again.',
          originalError: error,
          stackTrace: stackTrace,
        );
      }
      return ValidationError(
        message,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Permission errors
    if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('403')) {
      return PermissionError(
        LocalizationService().translate('error_permission_denied'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Rate limiting
    if (errorString.contains('rate limit') ||
        errorString.contains('too many requests') ||
        errorString.contains('429')) {
      return RateLimitError(
        LocalizationService().translate('error_rate_limit'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Timeout errors
    if (errorString.contains('timeout') ||
        errorString.contains('timed out') ||
        errorString.contains('deadline exceeded')) {
      return TimeoutError(
        LocalizationService().translate('error_timeout'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Configuration errors
    if (errorString.contains('configuration') ||
        errorString.contains('config') ||
        errorString.contains('setup') ||
        errorString.contains('initialization')) {
      return ConfigurationError(
        LocalizationService().translate('error_configuration'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Offline errors
    if (errorString.contains('offline') ||
        errorString.contains('no internet') ||
        errorString.contains('network unavailable')) {
      return OfflineError(
        LocalizationService().translate('error_offline'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Data integrity errors
    if (errorString.contains('integrity') ||
        errorString.contains('constraint') ||
        errorString.contains('data corruption') ||
        errorString.contains('inconsistent')) {
      return DataIntegrityError(
        LocalizationService().translate('error_data_integrity'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Service unavailable
    if (errorString.contains('service unavailable') ||
        errorString.contains('503') ||
        errorString.contains('maintenance') ||
        errorString.contains('temporarily unavailable')) {
      return ServiceUnavailableError(
        LocalizationService().translate('error_service_unavailable'),
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // Generic fallback
    return GenericError(
      LocalizationService().translate('error_generic'),
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Log errors securely. In release builds hide sensitive details.
  /// Use context to help locate the error source without exposing secrets.
  static void logError(Object? e, [StackTrace? st, String? context]) {
    if (e == null) return;

    final AppError standardizedError = standardizeError(e, st);
    
    // Only log in debug mode to avoid console spam
    if (kDebugMode) {
      final String ctx = context != null ? ' [$context]' : '';
      logError(
        'Error$ctx: ${standardizedError.runtimeType} (${standardizedError.code})',
      );
    }
  }

  /// Map exceptions to user-friendly localized messages.
  /// Keep mapping simple and conservative to avoid leaking internal info.
  static String userMessage(Object? e) {
    if (e == null) return LocalizationService().translate('error_generic');
    final AppError standardizedError = standardizeError(e);
    return _sanitizeErrorMessage(standardizedError.message);
  }

  /// Sanitize error messages to prevent information leakage
  static String _sanitizeErrorMessage(String message) {
    // Remove any potential sensitive information like URLs, tokens, or internal paths
    final sanitized = message
        .replaceAll(RegExp(r'https?://[^\s]+'), '[URL]')
        .replaceAll(RegExp(r'\b\d{4,}\b'), '[NUMBER]') // Replace long numbers (potentially IDs)
        .replaceAll(RegExp(r'\b[A-Za-z0-9+/=]{20,}\b'), '[TOKEN]') // Replace base64-like tokens
        .replaceAll(RegExp(r'/[^\s]*\.(php|asp|jsp|py|js|ts|dart)[^\s]*'), '[SCRIPT]') // Replace script paths
        .replaceAll(RegExp(r'\b\d+\.\d+\.\d+\.\d+\b'), '[IP]') // Replace IP addresses
        .replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[EMAIL]'); // Replace emails

    return sanitized;
  }

  /// Get recovery suggestions for different error types
  static String? getRecoverySuggestion(AppError error) {
    if (error is NetworkError) {
      return LocalizationService().translate('error_recovery_network');
    } else if (error is AuthError) {
      return LocalizationService().translate('error_recovery_auth');
    } else if (error is ValidationError) {
      // Provide specific suggestions for different validation error codes
      if (error.code == 'DUPLICATE_EMAIL') {
        return 'Try logging in with this email address instead, or use a different email to create a new account.';
      } else if (error.code == 'CONSTRAINT_VIOLATION') {
        return 'Please check that all required fields are filled correctly and try again.';
      } else {
        return LocalizationService().translate('error_recovery_validation');
      }
    } else if (error is DatabaseError) {
      if (error.code == 'DUPLICATE_DATA') {
        return 'This information is already in use. Please use different values and try again.';
      } else {
        return LocalizationService().translate('error_recovery_database');
      }
    } else if (error is UploadError) {
      return LocalizationService().translate('error_recovery_upload');
    } else if (error is PermissionError) {
      return LocalizationService().translate('error_recovery_permission');
    } else if (error is RateLimitError) {
      return LocalizationService().translate('error_recovery_rate_limit');
    } else if (error is TimeoutError) {
      return LocalizationService().translate('error_recovery_timeout');
    } else if (error is ConfigurationError) {
      return LocalizationService().translate('error_recovery_configuration');
    } else if (error is OfflineError) {
      return LocalizationService().translate('error_recovery_offline');
    } else if (error is ServiceUnavailableError) {
      return error.isTemporary
          ? LocalizationService().translate('error_recovery_service_temporary')
          : LocalizationService().translate('error_recovery_service_permanent');
    } else if (error is DataIntegrityError) {
      return LocalizationService().translate('error_recovery_data_integrity');
    } else if (error is FieldValidationError) {
      return LocalizationService().translate('error_recovery_field_validation');
    } else if (error is BusinessLogicError) {
      return LocalizationService().translate('error_recovery_business_logic');
    }
    return null;
  }

  /// Check if an error is recoverable
  static bool isRecoverable(AppError error) {
    return error is NetworkError ||
           error is GenericError ||
           error is TimeoutError ||
           error is RateLimitError ||
           (error is ServiceUnavailableError && error.isTemporary) ||
           error is OfflineError;
  }

  /// Execute an async operation with retry logic
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = defaultRetryConfig,
    String? context,
    Future<void> Function(AppError error, int attempt)? onRetryAttempt,
  }) async {
    int attempts = 0;
    Duration delay = config.initialDelay;

    while (attempts < config.maxAttempts) {
      try {
        return await operation();
      } catch (e, st) {
        attempts++;
        final error = standardizeError(e, st);

        // Log the error attempt
        logError(
          error,
          st,
          '$context (attempt $attempts/${config.maxAttempts})',
        );

        // Notify about retry attempt
        if (onRetryAttempt != null) {
          await onRetryAttempt(error, attempts);
        }

        // Check if we should retry
        final shouldRetry =
            config.shouldRetry?.call(error) ??
            (error is NetworkError ||
             error is GenericError ||
             error is TimeoutError ||
             error is RateLimitError ||
             (error is ServiceUnavailableError && error.isTemporary));

        if (!shouldRetry || attempts >= config.maxAttempts) {
          rethrow;
        }

        // Special handling for rate limit errors
        if (error is RateLimitError) {
          delay = error.retryAfter;
        } else {
          // Add jitter to prevent thundering herd
          final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.1).round());
          final actualDelay = delay + Duration(milliseconds: (jitter.inMilliseconds * (0.5 - (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).round());

          // Wait before retrying
          await Future.delayed(actualDelay);

          // Calculate next delay with exponential backoff
          delay = Duration(
            milliseconds: (delay.inMilliseconds * config.backoffMultiplier)
                .round(),
          );

          // Cap the delay
          if (delay > config.maxDelay) {
            delay = config.maxDelay;
          }
        }
      }
    }

    throw GenericError('Max retry attempts exceeded');
  }

  /// Execute an operation with fallback value on failure
  static Future<T> withFallback<T>(
    Future<T> Function() operation,
    T fallbackValue, {
    String? context,
    bool Function(AppError)? shouldUseFallback,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      final error = standardizeError(e, st);
      logError(error, st, context ?? 'withFallback');

      // Check if we should use fallback for this error type
      if (shouldUseFallback != null && !shouldUseFallback(error)) {
        rethrow;
      }

      return fallbackValue;
    }
  }

  /// Execute an operation with custom error handling
  static Future<T> withErrorHandling<T>(
    Future<T> Function() operation, {
    T? fallbackValue,
    String? context,
    bool rethrowOnError = true,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      logError(e, st, context);

      if (fallbackValue != null) {
        return fallbackValue;
      }

      if (rethrowOnError) {
        rethrow;
      }

      throw standardizeError(e, st);
    }
  }

  /// Execute operation with circuit breaker pattern for resilience
  static Future<T> withCircuitBreaker<T>(
    Future<T> Function() operation, {
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 60),
    String? context,
  }) async {
    // Simple circuit breaker implementation
    // In a real implementation, this would track state across calls
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (e, st) {
      throw TimeoutError(
        'Operation timed out after ${timeout.inSeconds} seconds',
        originalError: e,
        stackTrace: st,
      );
    } catch (e, st) {
      throw standardizeError(e, st);
    }
  }

  /// Execute operation with graceful degradation
  static Future<T> withGracefulDegradation<T>(
    Future<T> Function() operation,
    T degradedValue, {
    String? context,
    bool Function(AppError)? shouldDegrade,
  }) async {
    try {
      return await operation();
    } catch (e, st) {
      final error = standardizeError(e, st);
      logError(error, st, '$context (degraded)');

      if (shouldDegrade != null && !shouldDegrade(error)) {
        rethrow;
      }

      return degradedValue;
    }
  }

  /// Execute operation with multiple fallback strategies
  static Future<T> withFallbackChain<T>(
    List<Future<T> Function()> operations, {
    String? context,
    bool rethrowOnAllFailed = true,
  }) async {
    for (int i = 0; i < operations.length; i++) {
      try {
        return await operations[i]();
      } catch (e, st) {
        final error = standardizeError(e, st);
        logError(error, st, '$context (fallback ${i + 1}/${operations.length})');

        // If this is the last operation and we should rethrow, do so
        if (i == operations.length - 1 && rethrowOnAllFailed) {
          rethrow;
        }
      }
    }

    throw GenericError('All fallback operations failed');
  }
}
