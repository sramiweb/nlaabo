import 'package:flutter/material.dart';
import '../../typography/app_text_styles.dart';

/// FormValidationStyles provides consistent styling for form validation states
/// across all form components in the design system
class FormValidationStyles {
  // Private constructor to prevent instantiation
  FormValidationStyles._();

  // Error styling
  static const Color errorColor = Color(0xFFDC2626);
  static const Color errorBorderColor = Color(0xFFDC2626);
  static const Color errorBackgroundColor = Color(0xFFFFF5F5);

  // Success styling
  static const Color successColor = Color(0xFF10B981);
  static const Color successBorderColor = Color(0xFF10B981);
  static const Color successBackgroundColor = Color(0xFFF0FDF4);

  // Warning styling
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color warningBorderColor = Color(0xFFF59E0B);
  static const Color warningBackgroundColor = Color(0xFFFFFBEB);

  // Info styling
  static const Color infoColor = Color(0xFF3B82F6);
  static const Color infoBorderColor = Color(0xFF3B82F6);
  static const Color infoBackgroundColor = Color(0xFFEEF2FF);

  // Validation message styling
  static TextStyle get errorTextStyle => AppTextStyles.caption.copyWith(
        color: errorColor,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get successTextStyle => AppTextStyles.caption.copyWith(
        color: successColor,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get warningTextStyle => AppTextStyles.caption.copyWith(
        color: warningColor,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get infoTextStyle => AppTextStyles.caption.copyWith(
        color: infoColor,
        fontWeight: FontWeight.w500,
      );

  // Helper text styling
  static TextStyle helperTextStyle(BuildContext context) => AppTextStyles.caption.copyWith(
        color: const Color(0xFF6B7280),
      );

  // Validation container styling
  static BoxDecoration errorContainerDecoration({
    double borderRadius = 8.0,
    bool isDarkMode = false,
  }) =>
      BoxDecoration(
        color: isDarkMode ? errorBackgroundColor.withValues(alpha: 0.1) : errorBackgroundColor,
        border: Border.all(color: errorBorderColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(borderRadius),
      );

  static BoxDecoration successContainerDecoration({
    double borderRadius = 8.0,
    bool isDarkMode = false,
  }) =>
      BoxDecoration(
        color: isDarkMode ? successBackgroundColor.withValues(alpha: 0.1) : successBackgroundColor,
        border: Border.all(color: successBorderColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(borderRadius),
      );

  static BoxDecoration warningContainerDecoration({
    double borderRadius = 8.0,
    bool isDarkMode = false,
  }) =>
      BoxDecoration(
        color: isDarkMode ? warningBackgroundColor.withValues(alpha: 0.1) : warningBackgroundColor,
        border: Border.all(color: warningBorderColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(borderRadius),
      );

  static BoxDecoration infoContainerDecoration({
    double borderRadius = 8.0,
    bool isDarkMode = false,
  }) =>
      BoxDecoration(
        color: isDarkMode ? infoBackgroundColor.withValues(alpha: 0.1) : infoBackgroundColor,
        border: Border.all(color: infoBorderColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(borderRadius),
      );

  // Validation icon styling
  static Widget errorIcon({double size = 16.0}) => Icon(
        Icons.error_outline,
        color: errorColor,
        size: size,
      );

  static Widget successIcon({double size = 16.0}) => Icon(
        Icons.check_circle_outline,
        color: successColor,
        size: size,
      );

  static Widget warningIcon({double size = 16.0}) => Icon(
        Icons.warning_amber_outlined,
        color: warningColor,
        size: size,
      );

  static Widget infoIcon({double size = 16.0}) => Icon(
        Icons.info_outline,
        color: infoColor,
        size: size,
      );

  // Validation message widget builders
  static Widget buildErrorMessage(String message, {bool showIcon = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          errorIcon(),
          const SizedBox(width: 8.0),
        ],
        Expanded(
          child: Text(
            message,
            style: errorTextStyle,
          ),
        ),
      ],
    );
  }

  static Widget buildSuccessMessage(String message, {bool showIcon = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          successIcon(),
          const SizedBox(width: 8.0),
        ],
        Expanded(
          child: Text(
            message,
            style: successTextStyle,
          ),
        ),
      ],
    );
  }

  static Widget buildWarningMessage(String message, {bool showIcon = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          warningIcon(),
          const SizedBox(width: 8.0),
        ],
        Expanded(
          child: Text(
            message,
            style: warningTextStyle,
          ),
        ),
      ],
    );
  }

  static Widget buildInfoMessage(String message, {bool showIcon = true}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          infoIcon(),
          const SizedBox(width: 8.0),
        ],
        Expanded(
          child: Text(
            message,
            style: infoTextStyle,
          ),
        ),
      ],
    );
  }

  static Widget buildHelperMessage(BuildContext context, String message) {
    return Text(
      message,
      style: helperTextStyle(context),
    );
  }

  // Validation state enum and utilities
  static ValidationState getValidationState({
    String? errorText,
    String? successText,
    String? warningText,
    String? infoText,
  }) {
    if (errorText != null && errorText.isNotEmpty) return ValidationState.error;
    if (successText != null && successText.isNotEmpty) return ValidationState.success;
    if (warningText != null && warningText.isNotEmpty) return ValidationState.warning;
    if (infoText != null && infoText.isNotEmpty) return ValidationState.info;
    return ValidationState.none;
  }

  static Color getBorderColor(ValidationState state) {
    switch (state) {
      case ValidationState.error:
        return errorBorderColor;
      case ValidationState.success:
        return successBorderColor;
      case ValidationState.warning:
        return warningBorderColor;
      case ValidationState.info:
        return infoBorderColor;
      case ValidationState.none:
        return const Color(0xFFE5E7EB);
    }
  }

  static TextStyle getMessageTextStyle(ValidationState state, BuildContext context) {
    switch (state) {
      case ValidationState.error:
        return errorTextStyle;
      case ValidationState.success:
        return successTextStyle;
      case ValidationState.warning:
        return warningTextStyle;
      case ValidationState.info:
        return infoTextStyle;
      case ValidationState.none:
        return helperTextStyle(context);
    }
  }

  static Widget? getValidationIcon(ValidationState state, {double size = 16.0}) {
    switch (state) {
      case ValidationState.error:
        return errorIcon(size: size);
      case ValidationState.success:
        return successIcon(size: size);
      case ValidationState.warning:
        return warningIcon(size: size);
      case ValidationState.info:
        return infoIcon(size: size);
      case ValidationState.none:
        return null;
    }
  }
}

/// Validation state enum for consistent validation handling
enum ValidationState {
  none,
  error,
  success,
  warning,
  info,
}

/// Extension methods for ValidationState
extension ValidationStateExtension on ValidationState {
  bool get hasValidation => this != ValidationState.none;
  bool get isError => this == ValidationState.error;
  bool get isSuccess => this == ValidationState.success;
  bool get isWarning => this == ValidationState.warning;
  bool get isInfo => this == ValidationState.info;
}
