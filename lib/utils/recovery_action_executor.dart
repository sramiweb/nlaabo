import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/error_handler.dart';
import '../services/connectivity_service.dart';
import 'app_logger.dart';

/// Consolidated recovery action executor for all error recovery operations
class RecoveryActionExecutor {
  static final RecoveryActionExecutor _instance = RecoveryActionExecutor._internal();
  factory RecoveryActionExecutor() => _instance;
  RecoveryActionExecutor._internal();

  // Callbacks for navigation and UI operations (set by app initialization)
  static VoidCallback? onNavigateToLogin;
  static VoidCallback? onNavigateToForgotPassword;
  static VoidCallback? onOpenNetworkSettings;
  static VoidCallback? onOpenAppSettings;
  static VoidCallback? onEnableOfflineMode;
  static Function(String?)? onFocusField;
  static Function(AppError)? onReportIssue;
  static VoidCallback? onRetryUpload;
  static VoidCallback? onChooseDifferentFile;
  static VoidCallback? onShowReduceLoadTips;
  static Future<void> Function()? onCheckConnectionManually;

  /// Execute retry with connectivity check
  static Future<void> retryWithConnectivityCheck() async {
    logInfo('Executing retry with connectivity check');
    final result = await ConnectivityService.checkSupabaseConnectivity();
    if (result == ConnectivityResult.success) {
      logInfo('Connectivity check passed, retrying operation');
    } else {
      logWarning('Connectivity check failed');
    }
  }

  /// Open network settings
  static Future<void> openNetworkSettings() async {
    logInfo('Opening network settings');
    onOpenNetworkSettings?.call();
  }

  /// Simple retry operation
  static Future<void> simpleRetry() async {
    logInfo('Executing simple retry');
  }

  /// Navigate to login screen
  static Future<void> navigateToLogin() async {
    logInfo('Navigating to login screen');
    onNavigateToLogin?.call();
  }

  /// Navigate to forgot password screen
  static Future<void> navigateToForgotPassword() async {
    logInfo('Navigating to forgot password screen');
    onNavigateToForgotPassword?.call();
  }

  /// Show tips to reduce load
  static Future<void> showReduceLoadTips() async {
    logInfo('Showing reduce load tips');
    onShowReduceLoadTips?.call();
  }

  /// Enable offline mode
  static Future<void> enableOfflineMode() async {
    logInfo('Enabling offline mode');
    onEnableOfflineMode?.call();
  }

  /// Check connection manually
  static Future<void> checkConnectionManually() async {
    logInfo('Checking connection manually');
    await onCheckConnectionManually?.call();
  }

  /// Contact support
  static Future<void> contactSupport() async {
    logInfo('Contacting support');
    // Implementation would open email client or support chat
  }

  /// Request permission
  static Future<void> requestPermission() async {
    logInfo('Requesting permission');
    // Implementation would use permission_handler package
  }

  /// Open app settings
  static Future<void> openAppSettings() async {
    logInfo('Opening app settings');
    onOpenAppSettings?.call();
  }

  /// Focus on field
  static Future<void> focusOnField(String? fieldName) async {
    logInfo('Focusing on field: $fieldName');
    onFocusField?.call(fieldName);
  }

  /// Retry upload
  static Future<void> retryUpload() async {
    logInfo('Retrying upload');
    onRetryUpload?.call();
  }

  /// Choose different file
  static Future<void> chooseDifferentFile() async {
    logInfo('Choosing different file');
    onChooseDifferentFile?.call();
  }

  /// Report issue
  static Future<void> reportIssue(AppError error) async {
    logInfo('Reporting issue: ${error.message}');
    onReportIssue?.call(error);
  }

  /// Wait and retry after delay
  static Future<void> waitAndRetry(Duration delay) async {
    logInfo('Waiting ${delay.inSeconds}s before retry');
    await Future.delayed(delay);
  }
}
