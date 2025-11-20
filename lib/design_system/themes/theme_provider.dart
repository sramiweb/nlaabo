import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// ThemeProvider manages theme switching between light and dark modes
/// Uses Provider pattern for state management and SharedPreferences for persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'is_dark_mode';

  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Initialize SharedPreferences and load saved theme
  Future<void> _loadThemeFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(_themeKey) ?? false;
    notifyListeners();
  }

  /// Get current theme mode
  bool get isDarkMode => _isDarkMode;

  /// Get current theme data
  ThemeData get themeData => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  /// Set theme mode explicitly
  Future<void> setThemeMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    }
  }

  /// Get theme mode as string for debugging
  String get themeModeString => _isDarkMode ? 'dark' : 'light';
}