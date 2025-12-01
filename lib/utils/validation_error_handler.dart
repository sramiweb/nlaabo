import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/localization_service.dart';
import 'error_message_formatter.dart';

/// Centralized validation error handling and display
class ValidationErrorHandler {
  /// Get validation error message with field context
  static String getFieldErrorMessage(
    String? validationError, {
    String? fieldName,
  }) {
    if (validationError == null) return '';
    
    // If it's already a localized message, return as-is
    if (validationError.isEmpty) return '';
    
    // Add field context if provided
    if (fieldName != null && !validationError.contains(fieldName)) {
      return '$fieldName: $validationError';
    }
    
    return validationError;
  }

  /// Show validation error in snackbar
  static void showValidationError(
    BuildContext context,
    String? error, {
    String? fieldName,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (error == null || error.isEmpty) return;

    final message = getFieldErrorMessage(error, fieldName: fieldName);
    context.showWarning(message, duration: duration);
  }

  /// Show multiple validation errors
  static void showMultipleValidationErrors(
    BuildContext context,
    Map<String, String> errors, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (errors.isEmpty) return;

    final errorList = errors.entries
        .map((e) => '• ${e.key}: ${e.value}')
        .join('\n');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Validation Errors',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              errorList,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  /// Validate form and show errors
  static bool validateFormAndShowErrors(
    BuildContext context,
    GlobalKey<FormState> formKey, {
    VoidCallback? onValidationFailed,
  }) {
    if (formKey.currentState?.validate() ?? false) {
      return true;
    }

    onValidationFailed?.call();
    return false;
  }

  /// Create a field validation error
  static FieldValidationError createFieldError(
    String fieldName,
    String message, {
    String? fieldValue,
  }) {
    return FieldValidationError(
      message,
      fieldName: fieldName,
      fieldValue: fieldValue,
    );
  }

  /// Get validation error icon
  static IconData getValidationErrorIcon() => Icons.warning_amber;

  /// Get validation error color
  static Color getValidationErrorColor() => Colors.amber;

  /// Check if error is validation-related
  static bool isValidationError(dynamic error) {
    return error is ValidationError || error is FieldValidationError;
  }

  /// Extract field name from validation error
  static String? extractFieldName(dynamic error) {
    if (error is FieldValidationError) {
      return error.fieldName;
    }
    return null;
  }

  /// Format validation errors for display
  static String formatValidationErrors(List<String> errors) {
    if (errors.isEmpty) return '';
    if (errors.length == 1) return errors.first;
    return errors.map((e) => '• $e').join('\n');
  }
}

/// Extension for FormFieldState to show validation errors
extension ValidationErrorExtension<T> on FormFieldState<T> {
  /// Show validation error in snackbar
  void showError(BuildContext context, {String? fieldName}) {
    if (errorText != null) {
      ValidationErrorHandler.showValidationError(
        context,
        errorText,
        fieldName: fieldName ?? widget.label,
      );
    }
  }

  /// Get formatted error message
  String? getFormattedError({String? fieldName}) {
    return ValidationErrorHandler.getFieldErrorMessage(
      errorText,
      fieldName: fieldName ?? widget.label,
    );
  }
}

/// Extension for Form validation
extension FormValidationExtension on FormState {
  /// Validate and collect all errors
  Map<String, String> validateAndCollectErrors() {
    final errors = <String, String>{};
    
    for (final field in fields) {
      if (field is FormFieldState) {
        field.validate();
        if (field.errorText != null) {
          errors[field.widget.label ?? 'Field'] = field.errorText!;
        }
      }
    }
    
    return errors;
  }

  /// Show all validation errors
  void showAllValidationErrors(BuildContext context) {
    final errors = validateAndCollectErrors();
    if (errors.isNotEmpty) {
      ValidationErrorHandler.showMultipleValidationErrors(context, errors);
    }
  }
}
