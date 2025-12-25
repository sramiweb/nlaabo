import 'package:flutter/material.dart';

/// Helper for managing common screen state patterns
class ScreenStateHelper {
  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
      ),
    );
  }

  /// Close loading dialog
  static void closeLoadingDialog(BuildContext context) {
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
  }) async {
    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Execute async operation with loading state
  static Future<T?> executeWithLoading<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorTitle,
  }) async {
    try {
      showLoadingDialog(context, message: loadingMessage);
      final result = await operation();
      if (context.mounted) {
        closeLoadingDialog(context);
        if (successMessage != null) {
          showSuccess(context, successMessage);
        }
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        closeLoadingDialog(context);
        showError(context, '${errorTitle ?? 'Error'}: $e');
      }
      return null;
    }
  }

  /// Safe setState wrapper
  static void safeSetState(
    State state,
    VoidCallback fn,
  ) {
    if (state.mounted) {
      // ignore: invalid_use_of_protected_member
      state.setState(fn);
    }
  }
}
