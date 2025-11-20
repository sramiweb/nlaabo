import 'package:flutter/material.dart';
import 'app_colors_theme.dart';

/// Extension on BuildContext to provide convenient access to theme-aware colors
/// This replaces the static AppColors approach with reactive color access that
/// automatically updates when the theme changes.
///
/// Usage:
/// ```dart
/// // Instead of: context.colors.primary
/// // Use: context.colors.primary
///
/// // Instead of: context.colors.background
/// // Use: context.colors.background
/// ```
extension AppColorsExtension on BuildContext {
  /// Access to all theme-aware colors through the AppColorsTheme extension
  AppColorsTheme get colors => AppColorsTheme.of(this);

  /// Primary color - Lime Green (#34D399)
  Color get primaryColor => colors.primary;

  /// Destructive color - Red (#EF4444)
  Color get destructiveColor => colors.destructive;

  /// Background color - adapts to light/dark theme
  Color get backgroundColor => colors.background;

  /// Surface color - adapts to light/dark theme
  Color get surfaceColor => colors.surface;

  /// Primary text color - adapts to light/dark theme
  Color get textPrimaryColor => colors.textPrimary;

  /// Subtle text color - adapts to light/dark theme
  Color get textSubtleColor => colors.textSubtle;

  /// Border color - adapts to light/dark theme
  Color get borderColor => colors.border;

  /// Success color - Green (#10B981)
  Color get successColor => colors.success;

  /// Warning color - Amber (#F59E0B)
  Color get warningColor => colors.warning;

  /// Info color - Blue (#3B82F6)
  Color get infoColor => colors.info;

  /// Neutral gray colors - same values for both themes
  Color get gray50 => colors.gray50;
  Color get gray100 => colors.gray100;
  Color get gray200 => colors.gray200;
  Color get gray300 => colors.gray300;
  Color get gray400 => colors.gray400;
  Color get gray500 => colors.gray500;
  Color get gray600 => colors.gray600;
  Color get gray700 => colors.gray700;
  Color get gray800 => colors.gray800;
  Color get gray900 => colors.gray900;

  // Convenience getters with shorter names for common usage
  /// Primary color (alias for primaryColor)
  Color get primary => colors.primary;

  /// Destructive color (alias for destructiveColor)
  Color get destructive => colors.destructive;

  /// Background color (alias for backgroundColor)
  Color get background => colors.background;

  /// Surface color (alias for surfaceColor)
  Color get surface => colors.surface;

  /// Primary text color (alias for textPrimaryColor)
  Color get textPrimary => colors.textPrimary;

  /// Subtle text color (alias for textSubtleColor)
  Color get textSubtle => colors.textSubtle;

  /// Border color (alias for borderColor)
  Color get border => colors.border;

  /// Success color (alias for successColor)
  Color get success => colors.success;

  /// Warning color (alias for warningColor)
  Color get warning => colors.warning;

  /// Info color (alias for infoColor)
  Color get info => colors.info;
}
