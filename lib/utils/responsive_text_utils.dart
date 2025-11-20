import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Enhanced responsive text utilities for consistent text scaling across the app
/// Provides comprehensive text scaling methods that integrate with ResponsiveUtils
class ResponsiveTextUtils {
  // Private constructor to prevent instantiation
  ResponsiveTextUtils._();

  /// Text style types for consistent typography
  static const Map<String, double> _baseFontSizes = {
    'displayLarge': 57.0,
    'displayMedium': 45.0,
    'displaySmall': 36.0,
    'headlineLarge': 32.0,
    'headlineMedium': 28.0,
    'headlineSmall': 24.0,
    'titleLarge': 22.0,
    'titleMedium': 16.0,
    'titleSmall': 14.0,
    'bodyLarge': 16.0,
    'bodyMedium': 14.0,
    'bodySmall': 12.0,
    'labelLarge': 14.0,
    'labelMedium': 12.0,
    'labelSmall': 11.0,
  };

  /// Font weights for different text styles
  static const Map<String, FontWeight> _fontWeights = {
    'displayLarge': FontWeight.w400,
    'displayMedium': FontWeight.w400,
    'displaySmall': FontWeight.w400,
    'headlineLarge': FontWeight.w400,
    'headlineMedium': FontWeight.w400,
    'headlineSmall': FontWeight.w400,
    'titleLarge': FontWeight.w500,
    'titleMedium': FontWeight.w500,
    'titleSmall': FontWeight.w500,
    'bodyLarge': FontWeight.w400,
    'bodyMedium': FontWeight.w400,
    'bodySmall': FontWeight.w400,
    'labelLarge': FontWeight.w500,
    'labelMedium': FontWeight.w500,
    'labelSmall': FontWeight.w500,
  };

  /// Line heights for different text styles
  static const Map<String, double> _lineHeights = {
    'displayLarge': 1.12,
    'displayMedium': 1.16,
    'displaySmall': 1.22,
    'headlineLarge': 1.25,
    'headlineMedium': 1.29,
    'headlineSmall': 1.33,
    'titleLarge': 1.27,
    'titleMedium': 1.50,
    'titleSmall': 1.43,
    'bodyLarge': 1.50,
    'bodyMedium': 1.43,
    'bodySmall': 1.33,
    'labelLarge': 1.43,
    'labelMedium': 1.33,
    'labelSmall': 1.18,
  };

  /// Get scaled text style with responsive scaling
  /// Applies the ResponsiveUtils textScaleFactor to any TextStyle
  static TextStyle getScaledTextStyle(BuildContext context, TextStyle baseStyle) {
    final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize != null ? baseStyle.fontSize! * scaleFactor : null,
      height: baseStyle.height,
      letterSpacing: baseStyle.letterSpacing,
    );
  }

  /// Get responsive text style with base font sizes and automatic scaling
  /// Uses predefined base font sizes and applies responsive scaling
  static TextStyle getResponsiveTextStyle(
    BuildContext context,
    String styleType, {
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) {
    final baseSize = _baseFontSizes[styleType];
    if (baseSize == null) {
      throw ArgumentError('Unknown style type: $styleType. Available types: ${_baseFontSizes.keys.join(', ')}');
    }

    final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
    final scaledSize = baseSize * scaleFactor;

    return TextStyle(
      fontSize: scaledSize,
      fontWeight: fontWeight ?? _fontWeights[styleType] ?? FontWeight.w400,
      height: _lineHeights[styleType] ?? 1.2,
      color: color,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
    );
  }

  /// Get responsive display text styles
  static TextStyle getDisplayLarge(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'displayLarge', color: color);

  static TextStyle getDisplayMedium(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'displayMedium', color: color);

  static TextStyle getDisplaySmall(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'displaySmall', color: color);

  /// Get responsive headline text styles
  static TextStyle getHeadlineLarge(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'headlineLarge', color: color);

  static TextStyle getHeadlineMedium(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'headlineMedium', color: color);

  static TextStyle getHeadlineSmall(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'headlineSmall', color: color);

  /// Get responsive title text styles
  static TextStyle getTitleLarge(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'titleLarge', color: color);

  static TextStyle getTitleMedium(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'titleMedium', color: color);

  static TextStyle getTitleSmall(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'titleSmall', color: color);

  /// Get responsive body text styles
  static TextStyle getBodyLarge(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'bodyLarge', color: color);

  static TextStyle getBodyMedium(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'bodyMedium', color: color);

  static TextStyle getBodySmall(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'bodySmall', color: color);

  /// Get responsive label text styles
  static TextStyle getLabelLarge(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'labelLarge', color: color);

  static TextStyle getLabelMedium(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'labelMedium', color: color);

  static TextStyle getLabelSmall(BuildContext context, {Color? color}) =>
      getResponsiveTextStyle(context, 'labelSmall', color: color);

  /// Get custom scaled font size based on base size and screen constraints
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
    return baseSize * scaleFactor;
  }

  /// Get responsive font size with minimum and maximum constraints
  static double getConstrainedFontSize(
    BuildContext context,
    double baseSize, {
    double? minSize,
    double? maxSize,
  }) {
    final scaledSize = getScaledFontSize(context, baseSize);
    final effectiveMinSize = minSize ?? baseSize * 0.8;
    final effectiveMaxSize = maxSize ?? baseSize * 1.4;

    return scaledSize.clamp(effectiveMinSize, effectiveMaxSize);
  }

  /// Get responsive letter spacing based on font size
  static double? getResponsiveLetterSpacing(BuildContext context, double baseSize) {
    final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
    final scaledSize = baseSize * scaleFactor;

    // Apply letter spacing for larger text sizes
    if (scaledSize >= 24) {
      return -0.5; // Tighter spacing for headlines
    } else if (scaledSize >= 16) {
      return 0.0; // Normal spacing for body text
    } else {
      return 0.25; // Slight spacing for small text
    }
  }

  /// Create a responsive text theme that can be used with ThemeData
  static TextTheme getResponsiveTextTheme(BuildContext context, {Color? textColor}) {
    return TextTheme(
      displayLarge: getDisplayLarge(context).copyWith(color: textColor),
      displayMedium: getDisplayMedium(context).copyWith(color: textColor),
      displaySmall: getDisplaySmall(context).copyWith(color: textColor),
      headlineLarge: getHeadlineLarge(context).copyWith(color: textColor),
      headlineMedium: getHeadlineMedium(context).copyWith(color: textColor),
      headlineSmall: getHeadlineSmall(context).copyWith(color: textColor),
      titleLarge: getTitleLarge(context).copyWith(color: textColor),
      titleMedium: getTitleMedium(context).copyWith(color: textColor),
      titleSmall: getTitleSmall(context).copyWith(color: textColor),
      bodyLarge: getBodyLarge(context).copyWith(color: textColor),
      bodyMedium: getBodyMedium(context).copyWith(color: textColor),
      bodySmall: getBodySmall(context).copyWith(color: textColor),
      labelLarge: getLabelLarge(context).copyWith(color: textColor),
      labelMedium: getLabelMedium(context).copyWith(color: textColor),
      labelSmall: getLabelSmall(context).copyWith(color: textColor),
    );
  }

  /// Get all available text style types
  static List<String> getAvailableStyleTypes() {
    return _baseFontSizes.keys.toList();
  }

  /// Check if a style type is valid
  static bool isValidStyleType(String styleType) {
    return _baseFontSizes.containsKey(styleType);
  }
}

/// Extension methods for responsive text on BuildContext
extension ResponsiveTextContext on BuildContext {
  /// Get scaled text style
  TextStyle getScaledTextStyle(TextStyle baseStyle) {
    return ResponsiveTextUtils.getScaledTextStyle(this, baseStyle);
  }

  /// Get responsive text style by type
  TextStyle getResponsiveTextStyle(String styleType, {Color? color}) {
    return ResponsiveTextUtils.getResponsiveTextStyle(this, styleType, color: color);
  }

  /// Get scaled font size
  double getScaledFontSize(double baseSize) {
    return ResponsiveTextUtils.getScaledFontSize(this, baseSize);
  }

  /// Get constrained font size
  double getConstrainedFontSize(double baseSize, {double? minSize, double? maxSize}) {
    return ResponsiveTextUtils.getConstrainedFontSize(this, baseSize,
        minSize: minSize, maxSize: maxSize);
  }

  /// Get responsive letter spacing
  double? getResponsiveLetterSpacing(double baseSize) {
    return ResponsiveTextUtils.getResponsiveLetterSpacing(this, baseSize);
  }

  /// Get responsive text theme
  TextTheme getResponsiveTextTheme({Color? textColor}) {
    return ResponsiveTextUtils.getResponsiveTextTheme(this, textColor: textColor);
  }
}

/// Extension methods for responsive text on TextStyle
extension ResponsiveTextStyle on TextStyle {
  /// Apply responsive scaling to this text style
  TextStyle scaled(BuildContext context) {
    return ResponsiveTextUtils.getScaledTextStyle(context, this);
  }

  /// Apply constrained scaling to this text style
  TextStyle constrained(BuildContext context, {double? minSize, double? maxSize}) {
    if (fontSize == null) return this;

    final constrainedSize = ResponsiveTextUtils.getConstrainedFontSize(
      context,
      fontSize!,
      minSize: minSize,
      maxSize: maxSize,
    );

    return copyWith(fontSize: constrainedSize);
  }
}