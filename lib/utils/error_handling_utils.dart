import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/error_handler.dart';

/// Utility functions for error handling and recovery
class ErrorHandlingUtils {
  /// Execute a function with error handling
  static Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? context,
    bool logError = true,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      if (logError) {
        ErrorHandler.logError(e, stackTrace, context ?? 'ErrorHandlingUtils');
      }
      return defaultValue;
    }
  }

  /// Execute a synchronous function with error handling
  static T? executeSyncWithErrorHandling<T>(
    T Function() operation, {
    String? context,
    bool logError = true,
    T? defaultValue,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      if (logError) {
        ErrorHandler.logError(e, stackTrace, context ?? 'ErrorHandlingUtils');
      }
      return defaultValue;
    }
  }

  /// Retry an operation with exponential backoff
  static Future<T> retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffFactor = 2.0,
    bool Function(Object)? shouldRetry,
    String? context,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e, stackTrace) {
        attempt++;

        if (attempt >= maxRetries) {
          ErrorHandler.logError(
            e,
            stackTrace,
            context ?? 'RetryWithBackoff',
          );
          rethrow;
        }

        if (shouldRetry != null && !shouldRetry(e)) {
          ErrorHandler.logError(
            e,
            stackTrace,
            context ?? 'RetryWithBackoff',
          );
          rethrow;
        }

        debugPrint('Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * backoffFactor).round());
      }
    }

    throw StateError('Should not reach here');
  }

  /// Wrap a stream with error handling
  static Stream<T> handleStreamErrors<T>(
    Stream<T> stream, {
    String? context,
    T? defaultValue,
  }) {
    return stream.handleError((error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace,
        context ?? 'StreamError',
      );
      if (defaultValue != null) {
        // For streams, we can't emit a default value directly
        // This would need to be handled by the stream consumer
      }
    });
  }

  /// Create a timeout wrapper for operations
  static Future<T> withTimeout<T>(
    Future<T> operation,
    Duration timeout, {
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await operation.timeout(timeout);
    } on TimeoutException catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace,
        context ?? 'TimeoutError',
      );
      if (defaultValue != null) {
        return defaultValue;
      }
      rethrow;
    }
  }

  /// Safe async operation that completes with a default value on error
  static Future<T> safeAsync<T>(
    Future<T> operation,
    T defaultValue, {
    String? context,
  }) async {
    try {
      return await operation;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace,
        context ?? 'SafeAsync',
      );
      return defaultValue;
    }
  }

  /// Check if an error is recoverable
  static bool isRecoverableError(Object error) {
    // Network errors are often recoverable
    if (error is TimeoutException) return true;
    if (error.toString().contains('network') ||
        error.toString().contains('connection') ||
        error.toString().contains('timeout')) {
      return true;
    }

    // Authentication errors might be recoverable
    if (error.toString().contains('auth') ||
        error.toString().contains('token') ||
        error.toString().contains('401')) {
      return true;
    }

    return false;
  }

  /// Get user-friendly error message
  static String getUserFriendlyErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection error. Please check your internet connection.';
    }

    if (errorString.contains('auth') || errorString.contains('token') || errorString.contains('401')) {
      return 'Authentication error. Please log in again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. You may not have permission for this action.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'The requested resource was not found.';
    }

    if (errorString.contains('500') || errorString.contains('server error') || 
        errorString.contains('service unavailable') || errorString.contains('internal server')) {
      return 'Server error. Please try again later.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
