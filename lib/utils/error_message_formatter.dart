import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/localization_service.dart';

/// Standardized error message formatting and display
class ErrorMessageFormatter {
  /// Format error for display with icon and message
  static ({IconData icon, String message, Color color}) formatError(
    dynamic error, {
    bool includeRecovery = false,
  }) {
    final appError = error is AppError ? error : ErrorHandler.standardizeError(error);
    final message = _getDisplayMessage(appError);
    final icon = _getErrorIcon(appError);
    final color = _getErrorColor(appError);

    return (icon: icon, message: message, color: color);
  }

  /// Get user-friendly error message
  static String getUserMessage(dynamic error) {
    final appError = error is AppError ? error : ErrorHandler.standardizeError(error);
    return _getDisplayMessage(appError);
  }

  /// Get recovery suggestion for error
  static String? getRecoverySuggestion(dynamic error) {
    final appError = error is AppError ? error : ErrorHandler.standardizeError(error);
    return ErrorHandler.getRecoverySuggestion(appError);
  }

  /// Format error with recovery suggestion
  static String formatErrorWithRecovery(dynamic error) {
    final message = getUserMessage(error);
    final recovery = getRecoverySuggestion(error);
    return recovery != null ? '$message\n\n$recovery' : message;
  }

  /// Get appropriate icon for error type
  static IconData _getErrorIcon(AppError error) {
    if (error is NetworkError) return Icons.wifi_off;
    if (error is AuthError) return Icons.lock_outline;
    if (error is ValidationError) return Icons.warning_amber;
    if (error is DatabaseError) return Icons.storage;
    if (error is UploadError) return Icons.cloud_upload_outlined;
    if (error is PermissionError) return Icons.block;
    if (error is RateLimitError) return Icons.schedule;
    if (error is TimeoutError) return Icons.schedule;
    if (error is OfflineError) return Icons.cloud_off;
    if (error is ServiceUnavailableError) return Icons.cloud_off;
    return Icons.error_outline;
  }

  /// Get appropriate color for error type
  static Color _getErrorColor(AppError error) {
    if (error is NetworkError) return Colors.orange;
    if (error is AuthError) return Colors.red;
    if (error is ValidationError) return Colors.amber;
    if (error is PermissionError) return Colors.red;
    if (error is RateLimitError) return Colors.orange;
    if (error is TimeoutError) return Colors.orange;
    if (error is OfflineError) return Colors.orange;
    return Colors.red;
  }

  /// Get display message for error
  static String _getDisplayMessage(AppError error) {
    // Use localized messages when available
    final localization = LocalizationService();

    if (error is NetworkError) {
      return localization.translate('error_network');
    } else if (error is AuthError) {
      return localization.translate('error_unauthorized');
    } else if (error is ValidationError) {
      if (error.code == 'DUPLICATE_EMAIL') {
        return 'An account with this email already exists.';
      }
      return localization.translate('error_invalid_input');
    } else if (error is DatabaseError) {
      if (error.code == 'DUPLICATE_DATA') {
        return 'This information is already in use.';
      }
      return localization.translate('error_database');
    } else if (error is UploadError) {
      return localization.translate('error_upload_failed');
    } else if (error is PermissionError) {
      return localization.translate('error_permission_denied');
    } else if (error is RateLimitError) {
      return localization.translate('error_rate_limit');
    } else if (error is TimeoutError) {
      return localization.translate('error_timeout');
    } else if (error is OfflineError) {
      return localization.translate('error_offline');
    } else if (error is ServiceUnavailableError) {
      return localization.translate('error_service_unavailable');
    } else if (error is FieldValidationError) {
      return 'Invalid ${error.fieldName}: ${error.message}';
    } else if (error is BusinessLogicError) {
      return error.message;
    }

    return error.message;
  }

  /// Check if error is recoverable
  static bool isRecoverable(dynamic error) {
    final appError = error is AppError ? error : ErrorHandler.standardizeError(error);
    return ErrorHandler.isRecoverable(appError);
  }

  /// Get error severity level
  static ErrorSeverity getSeverity(dynamic error) {
    final appError = error is AppError ? error : ErrorHandler.standardizeError(error);

    if (appError is ValidationError || appError is FieldValidationError) {
      return ErrorSeverity.low;
    } else if (appError is NetworkError ||
        appError is TimeoutError ||
        appError is OfflineError ||
        appError is RateLimitError) {
      return ErrorSeverity.medium;
    } else if (appError is AuthError ||
        appError is PermissionError ||
        appError is DatabaseError) {
      return ErrorSeverity.high;
    }

    return ErrorSeverity.medium;
  }
}

/// Error severity levels
enum ErrorSeverity { low, medium, high, critical }

/// Extension for BuildContext to show errors
extension ErrorDisplayExtension on BuildContext {
  /// Show error snackbar
  void showError(
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final formatter = ErrorMessageFormatter.formatError(error);
    final recovery = ErrorMessageFormatter.getRecoverySuggestion(error);

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(formatter.icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatter.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            if (recovery != null) ...[
              const SizedBox(height: 8),
              Text(
                recovery,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        backgroundColor: formatter.color,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Show success snackbar
  void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show info snackbar
  void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration,
      ),
    );
  }

  /// Show warning snackbar
  void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  /// Show error dialog
  Future<void> showErrorDialog(
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    final formatter = ErrorMessageFormatter.formatError(error);
    final recovery = ErrorMessageFormatter.getRecoverySuggestion(error);

    return showDialog(
      context: this,
      builder: (context) => AlertDialog(
        icon: Icon(formatter.icon, color: formatter.color),
        title: const Text('Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formatter.message),
            if (recovery != null) ...[
              const SizedBox(height: 12),
              Text(
                recovery,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}
