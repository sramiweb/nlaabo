import 'dart:async';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';
import 'connectivity_service.dart';
import 'localization_service.dart';

/// Service for handling error recovery strategies and user guidance
class ErrorRecoveryService {
  static final ErrorRecoveryService _instance = ErrorRecoveryService._internal();
  factory ErrorRecoveryService() => _instance;
  ErrorRecoveryService._internal();



  /// Get appropriate recovery action for an error
  Future<RecoveryAction> getRecoveryAction(AppError error) async {
    if (error is NetworkError) {
      return await _handleNetworkError(error);
    } else if (error is AuthError) {
      return _handleAuthError(error);
    } else if (error is RateLimitError) {
      return _handleRateLimitError(error);
    } else if (error is TimeoutError) {
      return _handleTimeoutError(error);
    } else if (error is OfflineError) {
      return _handleOfflineError(error);
    } else if (error is ServiceUnavailableError) {
      return _handleServiceUnavailableError(error);
    } else if (error is PermissionError) {
      return _handlePermissionError(error);
    } else if (error is ValidationError) {
      return _handleValidationError(error);
    } else if (error is UploadError) {
      return _handleUploadError(error);
    }
    return _handleGenericError(error);
  }

  Future<RecoveryAction> _handleNetworkError(NetworkError error) async {
    final connectivityResult = await ConnectivityService.checkSupabaseConnectivity();
    final isOnline = connectivityResult == ConnectivityResult.success;

    if (!isOnline) {
      return RecoveryAction(
        type: RecoveryType.checkConnectivity,
        title: LocalizationService().translate('recovery_network_title'),
        description: LocalizationService().translate('recovery_network_description'),
        primaryAction: RecoveryButton(
          label: LocalizationService().translate('recovery_retry'),
          action: () => _retryWithConnectivityCheck(),
        ),
        secondaryActions: [
          RecoveryButton(
            label: LocalizationService().translate('recovery_settings'),
            action: () => _openNetworkSettings(),
          ),
        ],
      );
    }

    return RecoveryAction(
      type: RecoveryType.retry,
      title: LocalizationService().translate('recovery_network_retry_title'),
      description: LocalizationService().translate('recovery_network_retry_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_retry'),
        action: () => _simpleRetry(),
      ),
    );
  }

  RecoveryAction _handleAuthError(AuthError error) {
    return RecoveryAction(
      type: RecoveryType.reauthenticate,
      title: LocalizationService().translate('recovery_auth_title'),
      description: LocalizationService().translate('recovery_auth_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_login'),
        action: () => _navigateToLogin(),
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_forgot_password'),
          action: () => _navigateToForgotPassword(),
        ),
      ],
    );
  }

  RecoveryAction _handleRateLimitError(RateLimitError error) {
    final waitTime = error.retryAfter.inMinutes > 0
        ? '${error.retryAfter.inMinutes} minutes'
        : '${error.retryAfter.inSeconds} seconds';

    return RecoveryAction(
      type: RecoveryType.wait,
      title: LocalizationService().translate('recovery_rate_limit_title'),
      description: LocalizationService().translate('recovery_rate_limit_description')
          .replaceAll('{time}', waitTime),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_wait_and_retry'),
        action: () => Future.delayed(error.retryAfter, _simpleRetry),
      ),
      autoRetryDelay: error.retryAfter,
    );
  }

  RecoveryAction _handleTimeoutError(TimeoutError error) {
    return RecoveryAction(
      type: RecoveryType.retry,
      title: LocalizationService().translate('recovery_timeout_title'),
      description: LocalizationService().translate('recovery_timeout_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_retry'),
        action: () => _simpleRetry(),
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_reduce_load'),
          action: () => _showReduceLoadTips(),
        ),
      ],
    );
  }

  RecoveryAction _handleOfflineError(OfflineError error) {
    return RecoveryAction(
      type: RecoveryType.offlineMode,
      title: LocalizationService().translate('recovery_offline_title'),
      description: LocalizationService().translate('recovery_offline_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_go_offline'),
        action: () => _enableOfflineMode(),
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_check_connection'),
          action: () => _checkConnectionManually(),
        ),
      ],
    );
  }

  RecoveryAction _handleServiceUnavailableError(ServiceUnavailableError error) {
    if (error.isTemporary) {
      return RecoveryAction(
        type: RecoveryType.retry,
        title: LocalizationService().translate('recovery_service_temp_title'),
        description: LocalizationService().translate('recovery_service_temp_description'),
        primaryAction: RecoveryButton(
          label: LocalizationService().translate('recovery_retry_later'),
          action: () => Future.delayed(const Duration(minutes: 5), _simpleRetry),
        ),
      );
    } else {
      return RecoveryAction(
        type: RecoveryType.contactSupport,
        title: LocalizationService().translate('recovery_service_perm_title'),
        description: LocalizationService().translate('recovery_service_perm_description'),
        primaryAction: RecoveryButton(
          label: LocalizationService().translate('recovery_contact_support'),
          action: () => _contactSupport(),
        ),
      );
    }
  }

  RecoveryAction _handlePermissionError(PermissionError error) {
    return RecoveryAction(
      type: RecoveryType.requestPermission,
      title: LocalizationService().translate('recovery_permission_title'),
      description: LocalizationService().translate('recovery_permission_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_grant_permission'),
        action: () => _requestPermission(),
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_app_settings'),
          action: () => _openAppSettings(),
        ),
      ],
    );
  }

  RecoveryAction _handleValidationError(ValidationError error) {
    String description = LocalizationService().translate('recovery_validation_description');

    if (error is FieldValidationError) {
      description = LocalizationService().translate('recovery_field_validation_description')
          .replaceAll('{field}', error.fieldName);
    }

    return RecoveryAction(
      type: RecoveryType.correctInput,
      title: LocalizationService().translate('recovery_validation_title'),
      description: description,
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_fix_input'),
        action: () => _focusOnField(error is FieldValidationError ? error.fieldName : null),
      ),
    );
  }

  RecoveryAction _handleUploadError(UploadError error) {
    return RecoveryAction(
      type: RecoveryType.retry,
      title: LocalizationService().translate('recovery_upload_title'),
      description: LocalizationService().translate('recovery_upload_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_retry_upload'),
        action: () => _retryUpload(),
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_choose_different_file'),
          action: () => _chooseDifferentFile(),
        ),
      ],
    );
  }

  RecoveryAction _handleGenericError(AppError error) {
    return RecoveryAction(
      type: RecoveryType.retry,
      title: LocalizationService().translate('recovery_generic_title'),
      description: LocalizationService().translate('recovery_generic_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_retry'),
        action: () => _simpleRetry(),
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_report_issue'),
          action: () => _reportIssue(error),
        ),
      ],
    );
  }

  // Action implementations (these would be implemented based on app navigation and services)
  Future<void> _retryWithConnectivityCheck() async {
    // Implementation would check connectivity and retry
    debugPrint('Retrying with connectivity check');
  }

  Future<void> _openNetworkSettings() async {
    // Implementation would open device network settings
    debugPrint('Opening network settings');
  }

  Future<void> _simpleRetry() async {
    // Implementation would trigger a retry of the failed operation
    // This method should be overridden by the calling context to provide specific retry logic
    debugPrint('Simple retry');
  }

  Future<void> _navigateToLogin() async {
    // Implementation would navigate to login screen
    debugPrint('Navigating to login');
  }

  Future<void> _navigateToForgotPassword() async {
    // Implementation would navigate to forgot password screen
    // This should be implemented by the calling context to provide proper navigation
    debugPrint('Navigating to forgot password');
  }

  Future<void> _showReduceLoadTips() async {
    // Implementation would show tips to reduce load
    debugPrint('Showing reduce load tips');
  }

  Future<void> _enableOfflineMode() async {
    // Implementation would enable offline mode
    // This should integrate with the offline mode service to switch to offline functionality
    debugPrint('Enabling offline mode');
  }

  Future<void> _checkConnectionManually() async {
    // Implementation would manually check connection
    // This should trigger a manual connectivity test and show results to user
    debugPrint('Checking connection manually');
  }

  Future<void> _contactSupport() async {
    // Implementation would open support contact
    // This should open email client, support chat, or support website
    debugPrint('Contacting support');
  }

  Future<void> _requestPermission() async {
    // Implementation would request the required permission
    // This should use permission_handler package to request specific permissions
    debugPrint('Requesting permission');
  }

  Future<void> _openAppSettings() async {
    // Implementation would open app settings
    // This should open the device settings for this specific app
    debugPrint('Opening app settings');
  }

  Future<void> _focusOnField(String? fieldName) async {
    // Implementation would focus on the problematic field
    // This should find the form field by name and request focus on it
    debugPrint('Focusing on field: $fieldName');
  }

  Future<void> _retryUpload() async {
    // Implementation would retry the upload
    // This should trigger a retry of the failed upload operation
    debugPrint('Retrying upload');
  }

  Future<void> _chooseDifferentFile() async {
    // Implementation would open file picker for different file
    // This should open a file picker dialog to select a different file
    debugPrint('Choosing different file');
  }

  Future<void> _reportIssue(AppError error) async {
    // Implementation would report the issue
    // This should send error details to error reporting service
    debugPrint('Reporting issue: ${error.message}');
  }
}

/// Types of recovery actions available
enum RecoveryType {
  retry,
  reauthenticate,
  wait,
  checkConnectivity,
  offlineMode,
  contactSupport,
  requestPermission,
  correctInput,
  reportIssue,
}

/// Represents a recovery action with UI elements
class RecoveryAction {
  final RecoveryType type;
  final String title;
  final String description;
  final RecoveryButton primaryAction;
  final List<RecoveryButton> secondaryActions;
  final Duration? autoRetryDelay;

  const RecoveryAction({
    required this.type,
    required this.title,
    required this.description,
    required this.primaryAction,
    this.secondaryActions = const [],
    this.autoRetryDelay,
  });
}

/// Represents a button in the recovery UI
class RecoveryButton {
  final String label;
  final Future<void> Function() action;

  const RecoveryButton({
    required this.label,
    required this.action,
  });
}
