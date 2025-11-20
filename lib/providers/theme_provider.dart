import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system/colors/app_colors_theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language_code';

  ThemeMode _themeMode = ThemeMode.system;
  String _languageCode = 'en'; // Default to English

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;

  /// Get the current theme data with AppColorsTheme extensions
  ThemeData get themeData {
    final appColorsTheme = isDarkMode ? AppColorsTheme.dark() : AppColorsTheme.light();

    return ThemeData(
      useMaterial3: true,
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      extensions: [appColorsTheme],
      // Add other theme configurations as needed
      colorScheme: isDarkMode
          ? const ColorScheme.dark(primary: Color(0xFF34D399))
          : const ColorScheme.light(primary: Color(0xFF34D399)),
    );
  }

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadSettings();
  }

  /// Load theme preference from SharedPreferences
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0; // 0 = system, 1 = light, 2 = dark

    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  /// Save theme preference to SharedPreferences
  Future<void> saveThemePreference(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);

    _themeMode = mode;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt(_themeKey) ?? 0; // 0 = system, 1 = light, 2 = dark
    final language = prefs.getString(_languageKey) ?? 'en';

    _themeMode = ThemeMode.values[themeIndex];
    _languageCode = language;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await saveThemePreference(mode);
  }

  Future<void> setLanguage(String languageCode) async {
    _languageCode = languageCode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}
