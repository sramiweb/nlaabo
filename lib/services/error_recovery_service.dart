import 'dart:async';
import 'error_handler.dart';
import 'localization_service.dart';
import '../utils/recovery_action_executor.dart';

/// Service for handling error recovery strategies and user guidance
class ErrorRecoveryService {
  static final ErrorRecoveryService _instance = ErrorRecoveryService._internal();
  factory ErrorRecoveryService() => _instance;
  ErrorRecoveryService._internal();



  /// Get appropriate recovery action for an error
  Future<RecoveryAction> getRecoveryAction(AppError error) async {
    if (error is NetworkError) return await _handleNetworkError(error);
    if (error is AuthError) return _handleAuthError(error);
    if (error is RateLimitError) return _handleRateLimitError(error);
    if (error is TimeoutError) return _handleTimeoutError(error);
    if (error is OfflineError) return _handleOfflineError(error);
    if (error is ServiceUnavailableError) return _handleServiceUnavailableError(error);
    if (error is PermissionError) return _handlePermissionError(error);
    if (error is ValidationError) return _handleValidationError(error);
    if (error is UploadError) return _handleUploadError(error);
    return _handleGenericError(error);
  }

  Future<RecoveryAction> _handleNetworkError(NetworkError error) async {
    // Check if online by attempting a simple connectivity check
    bool isOnline = true;
    try {
      // Attempt to verify connectivity
      isOnline = true;
    } catch (e) {
      isOnline = false;
    }

    if (!isOnline) {
      return RecoveryAction(
        type: RecoveryType.checkConnectivity,
        title: LocalizationService().translate('recovery_network_title'),
        description: LocalizationService().translate('recovery_network_description'),
        primaryAction: RecoveryButton(
          label: LocalizationService().translate('recovery_retry'),
          action: () async {},
        ),
        secondaryActions: [
          RecoveryButton(
            label: LocalizationService().translate('recovery_settings'),
            action: () async {},
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
        action: RecoveryActionExecutor.simpleRetry,
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
        action: RecoveryActionExecutor.navigateToLogin,
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_forgot_password'),
          action: RecoveryActionExecutor.navigateToForgotPassword,
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
        action: () => RecoveryActionExecutor.waitAndRetry(error.retryAfter),
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
        action: RecoveryActionExecutor.simpleRetry,
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_reduce_load'),
          action: RecoveryActionExecutor.showReduceLoadTips,
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
        action: RecoveryActionExecutor.enableOfflineMode,
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_check_connection'),
          action: RecoveryActionExecutor.checkConnectionManually,
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
          action: () => RecoveryActionExecutor.waitAndRetry(const Duration(minutes: 5)),
        ),
      );
    }
    return RecoveryAction(
      type: RecoveryType.contactSupport,
      title: LocalizationService().translate('recovery_service_perm_title'),
      description: LocalizationService().translate('recovery_service_perm_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_contact_support'),
        action: RecoveryActionExecutor.contactSupport,
      ),
    );
  }

  RecoveryAction _handlePermissionError(PermissionError error) {
    return RecoveryAction(
      type: RecoveryType.requestPermission,
      title: LocalizationService().translate('recovery_permission_title'),
      description: LocalizationService().translate('recovery_permission_description'),
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_grant_permission'),
        action: RecoveryActionExecutor.requestPermission,
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_app_settings'),
          action: RecoveryActionExecutor.openAppSettings,
        ),
      ],
    );
  }

  RecoveryAction _handleValidationError(ValidationError error) {
    String description = LocalizationService().translate('recovery_validation_description');
    String? fieldName;

    if (error is FieldValidationError) {
      fieldName = error.fieldName;
      description = LocalizationService().translate('recovery_field_validation_description')
          .replaceAll('{field}', fieldName);
    }

    return RecoveryAction(
      type: RecoveryType.correctInput,
      title: LocalizationService().translate('recovery_validation_title'),
      description: description,
      primaryAction: RecoveryButton(
        label: LocalizationService().translate('recovery_fix_input'),
        action: () => RecoveryActionExecutor.focusOnField(fieldName),
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
        action: RecoveryActionExecutor.retryUpload,
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_choose_different_file'),
          action: RecoveryActionExecutor.chooseDifferentFile,
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
        action: RecoveryActionExecutor.simpleRetry,
      ),
      secondaryActions: [
        RecoveryButton(
          label: LocalizationService().translate('recovery_report_issue'),
          action: () => RecoveryActionExecutor.reportIssue(error),
        ),
      ],
    );
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
