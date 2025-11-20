import 'package:flutter/material.dart';

/// Legacy AppColors class for backward compatibility
/// This class is deprecated and should be replaced with AppColorsTheme
/// Use context.colors instead of AppColors static access
@deprecated
class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF34D399);      // Lime Green
  static const Color destructive = Color(0xFFEF4444);  // Red

  // Light theme colors
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1F2937);
  static const Color lightTextSubtle = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF111827);
  static const Color darkSurface = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSubtle = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF374151);

  // Semantic colors
  static const Color success = Color(0xFF10B981);     // Green
  static const Color warning = Color(0xFFF59E0B);     // Amber
  static const Color info = Color(0xFF3B82F6);        // Blue

  // Neutral grays
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Computed properties for backward compatibility
  static Color get surface => _isDarkMode ? darkSurface : lightSurface;
  static Color get border => _isDarkMode ? darkBorder : lightBorder;
  static Color get textSubtle => _isDarkMode ? darkTextSubtle : lightTextSubtle;

  static bool _isDarkMode = false;

  /// Set the current theme mode for backward compatibility
  static void setThemeMode(bool isDark) {
    _isDarkMode = isDark;
  }
}