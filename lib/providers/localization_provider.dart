import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// Provider for managing localization state and language changes
class LocalizationProvider extends ChangeNotifier {
  final LocalizationService _localizationService = LocalizationService();
  Locale _locale = const Locale('ar'); // Default to Arabic

  LocalizationProvider() {
    // Initialize with Arabic first
    _locale = const Locale('ar');
    // Load Arabic translations synchronously during initialization
    _initializeWithArabic();
    // Then auto-initialize with current language state
    _initializeWithCurrentLanguage();
  }

  /// Internal initialization method to load Arabic synchronously
  void _initializeWithArabic() {
    // Load Arabic translations synchronously during provider creation
    _localizationService.loadLanguage('ar');
    debugPrint('LocalizationProvider: Initialized with Arabic translations');
  }

  /// Internal initialization method
  void _initializeWithCurrentLanguage() {
    final currentLanguage = _localizationService.currentLanguage;
    if (currentLanguage != _locale.languageCode) {
      _locale = Locale(currentLanguage);
      debugPrint('LocalizationProvider: Auto-initialized with language: $currentLanguage');
    }
  }

  /// Initialize the provider with the correct initial language state
  /// This should be called after the initial language is loaded from shared preferences
  void initializeWithCurrentLanguage() {
    final currentLanguage = _localizationService.currentLanguage;
    if (currentLanguage != _locale.languageCode) {
      _locale = Locale(currentLanguage);
      debugPrint('LocalizationProvider: Initialized with language: $currentLanguage');
      notifyListeners();
    }
  }

  /// Get current locale
  Locale get locale => _locale;

  /// Get current language code
  String get currentLanguage => _localizationService.currentLanguage;

  /// Get text direction for current language
  TextDirection get textDirection => _localizationService.textDirection;

  /// Check if current language is RTL
  bool get isRTL => _localizationService.isRTL;

  /// Translate a key
  String translate(String key) => _localizationService.translate(key);

  /// Check if a translation key exists
  bool hasKey(String key) => _localizationService.hasKey(key);

  /// Get all available translation keys
  Set<String> get availableKeys => _localizationService.availableKeys;

  /// Get supported language variants
  static Map<String, String> get supportedVariants => LocalizationService.supportedVariants;

  /// Change language and notify listeners
  Future<void> setLanguage(String languageCode) async {
    debugPrint('LocalizationProvider: setLanguage called with: $languageCode');
    debugPrint('LocalizationProvider: Current language: ${_localizationService.currentLanguage}');

    if (languageCode == _localizationService.currentLanguage) {
      debugPrint('LocalizationProvider: No language change needed');
      return; // No change needed
    }

    debugPrint('LocalizationProvider: Loading language: $languageCode');
    await _localizationService.loadLanguage(languageCode);
    _locale = Locale(languageCode);

    debugPrint('LocalizationProvider: Language changed to: $languageCode, locale: $_locale');
    debugPrint('LocalizationProvider: Notifying listeners...');
    notifyListeners();
    debugPrint('LocalizationProvider: Language change complete');
  }

  /// Helper method for easier access (similar to service)
  static String tr(String key) {
    return LocalizationService().translate(key);
  }
}
