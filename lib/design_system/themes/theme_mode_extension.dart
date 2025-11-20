import 'package:flutter/material.dart';

/// Extension methods for ThemeMode to provide additional functionality
extension ThemeModeExtension on ThemeMode {
  /// Get theme mode as string for debugging and serialization
  String get stringValue {
    switch (this) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }

  /// Get display name for the theme mode
  String get displayName {
    switch (this) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  /// Check if this theme mode represents dark theme
  bool get isDark {
    switch (this) {
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
    }
  }

  /// Get the opposite theme mode
  ThemeMode get opposite {
    switch (this) {
      case ThemeMode.system:
        return ThemeMode.light;
      case ThemeMode.light:
        return ThemeMode.dark;
      case ThemeMode.dark:
        return ThemeMode.light;
    }
  }
}

/// Utility functions for theme mode operations
class ThemeModeUtils {
  /// Parse string to ThemeMode
  static ThemeMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'system':
        return ThemeMode.system;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Get all available theme modes
  static List<ThemeMode> get allModes => [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  /// Get theme mode icons
  static IconData getIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.settings;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}
