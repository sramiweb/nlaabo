import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import 'error_message_formatter.dart';

/// Mixin for managing form state (loading, error, submitting)
mixin FormStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isLoading || _isSubmitting;

  void setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  void setSubmitting(bool value) {
    if (mounted) {
      setState(() => _isSubmitting = value);
    }
  }

  void setError(String? error) {
    if (mounted) {
      setState(() => _errorMessage = error);
    }
  }

  void clearError() {
    if (mounted) {
      setState(() => _errorMessage = null);
    }
  }

  void clearState() {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSubmitting = false;
        _errorMessage = null;
      });
    }
  }
}

/// Helper for form submission with error handling
class FormSubmissionHelper {
  /// Execute form submission with automatic state management
  static Future<T?> executeFormSubmission<T>(
    BuildContext context,
    GlobalKey<FormState> formKey,
    Future<T> Function() operation, {
    VoidCallback? onLoading,
    VoidCallback? onSuccess,
    VoidCallback? onError,
    bool showErrorDialog = false,
  }) async {
    // Validate form first
    if (formKey.currentState?.validate() != true) {
      onError?.call();
      return null;
    }

    onLoading?.call();

    try {
      final result = await operation();
      onSuccess?.call();
      return result;
    } catch (error, st) {
      final appError = error is AppError ? error : ErrorHandler.standardizeError(error, st);
      ErrorHandler.logError(appError, st, 'FormSubmission');

      if (context.mounted) {
        if (showErrorDialog) {
          await context.showErrorDialog(appError);
        } else {
          context.showError(appError);
        }
      }

      onError?.call();
      return null;
    }
  }

  /// Execute form submission with retry capability
  static Future<T?> executeFormSubmissionWithRetry<T>(
    BuildContext context,
    GlobalKey<FormState> formKey,
    Future<T> Function() operation, {
    int maxRetries = 3,
    VoidCallback? onLoading,
    VoidCallback? onSuccess,
    VoidCallback? onError,
  }) async {
    if (formKey.currentState?.validate() != true) {
      onError?.call();
      return null;
    }

    onLoading?.call();

    try {
      return await ErrorHandler.withRetry(
        operation,
        context: 'FormSubmission',
      );
    } catch (error, st) {
      final appError = error is AppError ? error : ErrorHandler.standardizeError(error, st);
      ErrorHandler.logError(appError, st, 'FormSubmissionWithRetry');

      if (context.mounted) {
        context.showError(appError, onRetry: () {
          executeFormSubmissionWithRetry(
            context,
            formKey,
            operation,
            maxRetries: maxRetries,
            onLoading: onLoading,
            onSuccess: onSuccess,
            onError: onError,
          );
        });
      }

      onError?.call();
      return null;
    }
  }
}

/// Helper for managing form field state
class FormFieldStateHelper {
  /// Show error for a specific field
  static void showFieldError(
    BuildContext context,
    String fieldName,
    String errorMessage,
  ) {
    context.showWarning('$fieldName: $errorMessage');
  }

  /// Validate and show all form errors
  static bool validateFormAndShowErrors(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) {
    if (formKey.currentState?.validate() ?? false) {
      return true;
    }
    return false;
  }

  /// Reset form to initial state
  static void resetForm(GlobalKey<FormState> formKey) {
    formKey.currentState?.reset();
  }

  /// Save form state
  static void saveForm(GlobalKey<FormState> formKey) {
    formKey.currentState?.save();
  }
}

/// Extension for easier form state management
extension FormStateExtension on GlobalKey<FormState> {
  /// Validate form
  bool validate() => currentState?.validate() ?? false;

  /// Save form
  void save() => currentState?.save();

  /// Reset form
  void reset() => currentState?.reset();

  /// Get form validation status
  bool get isValid => validate();

  /// Get form validation status without triggering validation
  bool get isValidWithoutValidation {
    try {
      return validate();
    } catch (_) {
      return false;
    }
  }
}

/// Helper for managing async form operations
class AsyncFormHelper {
  /// Execute async operation with loading state
  static Future<T?> executeWithLoadingState<T>(
    BuildContext context,
    Future<T> Function() operation, {
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(dynamic error) onError,
  }) async {
    onLoadingStart();

    try {
      final result = await operation();
      onLoadingEnd();
      return result;
    } catch (error) {
      onLoadingEnd();
      onError(error);
      return null;
    }
  }

  /// Execute multiple async operations sequentially
  static Future<List<T>> executeSequential<T>(
    BuildContext context,
    List<Future<T> Function()> operations, {
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(dynamic error) onError,
  }) async {
    onLoadingStart();
    final results = <T>[];

    try {
      for (final operation in operations) {
        final result = await operation();
        results.add(result);
      }
      onLoadingEnd();
      return results;
    } catch (error) {
      onLoadingEnd();
      onError(error);
      return [];
    }
  }
}
