import 'package:flutter/material.dart';

/// AppColorsTheme extension that integrates with Flutter's ThemeExtension system
/// This replaces the static AppColors approach with reactive theme-aware colors
/// as specified in the UI redesign specification section 3.1
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  // Primary colors with semantic naming
  final Color primary;
  final Color destructive;

  // Background and surface colors
  final Color background;
  final Color surface;

  // Text colors
  final Color textPrimary;
  final Color textSubtle;

  // Border color
  final Color border;

  // Additional semantic colors
  final Color success;
  final Color warning;
  final Color info;

  // Neutral grays for both themes
  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;

  const AppColorsTheme({
    required this.primary,
    required this.destructive,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSubtle,
    required this.border,
    required this.success,
    required this.warning,
    required this.info,
    required this.gray50,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
  });

  /// Light theme factory constructor with exact color values from specification
  factory AppColorsTheme.light() {
    return const AppColorsTheme(
      // Primary colors
      primary: Color(0xFF34D399),      // Lime Green
      destructive: Color(0xFFEF4444),  // Red

      // Light theme colors
      background: Color(0xFFF3F4F6),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1F2937),
      textSubtle: Color(0xFF6B7280),
      border: Color(0xFFE5E7EB),

      // Semantic colors
      success: Color(0xFF10B981),     // Green
      warning: Color(0xFFF59E0B),     // Amber
      info: Color(0xFF3B82F6),        // Blue

      // Neutral grays
      gray50: Color(0xFFF9FAFB),
      gray100: Color(0xFFF3F4F6),
      gray200: Color(0xFFE5E7EB),
      gray300: Color(0xFFD1D5DB),
      gray400: Color(0xFF9CA3AF),
      gray500: Color(0xFF6B7280),
      gray600: Color(0xFF4B5563),
      gray700: Color(0xFF374151),
      gray800: Color(0xFF1F2937),
      gray900: Color(0xFF111827),
    );
  }

  /// Dark theme factory constructor with exact color values from specification
  factory AppColorsTheme.dark() {
    return const AppColorsTheme(
      // Primary colors (same for both themes)
      primary: Color(0xFF34D399),      // Lime Green
      destructive: Color(0xFFEF4444),  // Red

      // Dark theme colors
      background: Color(0xFF111827),
      surface: Color(0xFF1F2937),
      textPrimary: Color(0xFFF9FAFB),
      textSubtle: Color(0xFF9CA3AF),
      border: Color(0xFF374151),

      // Semantic colors (same for both themes)
      success: Color(0xFF10B981),     // Green
      warning: Color(0xFFF59E0B),     // Amber
      info: Color(0xFF3B82F6),        // Blue

      // Neutral grays (same for both themes)
      gray50: Color(0xFFF9FAFB),
      gray100: Color(0xFFF3F4F6),
      gray200: Color(0xFFE5E7EB),
      gray300: Color(0xFFD1D5DB),
      gray400: Color(0xFF9CA3AF),
      gray500: Color(0xFF6B7280),
      gray600: Color(0xFF4B5563),
      gray700: Color(0xFF374151),
      gray800: Color(0xFF1F2937),
      gray900: Color(0xFF111827),
    );
  }

  @override
  AppColorsTheme copyWith({
    Color? primary,
    Color? destructive,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSubtle,
    Color? border,
    Color? success,
    Color? warning,
    Color? info,
    Color? gray50,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
  }) {
    return AppColorsTheme(
      primary: primary ?? this.primary,
      destructive: destructive ?? this.destructive,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      textPrimary: textPrimary ?? this.textPrimary,
      textSubtle: textSubtle ?? this.textSubtle,
      border: border ?? this.border,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gray50: gray50 ?? this.gray50,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
    );
  }

  @override
  AppColorsTheme lerp(ThemeExtension<AppColorsTheme>? other, double t) {
    if (other is! AppColorsTheme) {
      return this;
    }

    return AppColorsTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      gray50: Color.lerp(gray50, other.gray50, t)!,
      gray100: Color.lerp(gray100, other.gray100, t)!,
      gray200: Color.lerp(gray200, other.gray200, t)!,
      gray300: Color.lerp(gray300, other.gray300, t)!,
      gray400: Color.lerp(gray400, other.gray400, t)!,
      gray500: Color.lerp(gray500, other.gray500, t)!,
      gray600: Color.lerp(gray600, other.gray600, t)!,
      gray700: Color.lerp(gray700, other.gray700, t)!,
      gray800: Color.lerp(gray800, other.gray800, t)!,
      gray900: Color.lerp(gray900, other.gray900, t)!,
    );
  }

  /// Extension method to access AppColorsTheme from BuildContext
  static AppColorsTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final appColorsTheme = theme.extension<AppColorsTheme>();
    assert(appColorsTheme != null, 'AppColorsTheme not found in theme. Make sure to add AppColorsTheme.light() or AppColorsTheme.dark() to your theme extensions.');
    return appColorsTheme!;
  }
}
