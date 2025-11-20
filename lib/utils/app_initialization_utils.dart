import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/localization_service.dart';
import '../services/cache_service.dart';

import '../services/api_service.dart';

/// Utility functions for app initialization
class AppInitializationUtils {
  /// Initialize configuration and validate it
  static Future<void> initializeConfiguration(AppEnvironment environment) async {
    await AppConfig.initialize(environment: environment);
  }

  /// Load initial language from shared preferences
  static Future<void> loadInitialLanguage() async {
    try {
      final localizationService = LocalizationService();
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString('language_code') ?? 'ar';
      await localizationService.loadLanguage(savedLanguage);
      debugPrint('Initial language loaded: $savedLanguage');
    } catch (e) {
      debugPrint('Failed to load initial language, using default: $e');
      // Continue with default language - don't fail initialization
    }
  }

  /// Initialize cache service
  static Future<void> initializeCache() async {
    final cacheService = CacheService();
    await cacheService.initialize();
  }

  /// Warm cache in background with common data
  static Future<void> warmCache() async {
    try {
      final apiService = ApiService();
      final cacheService = CacheService();

      await cacheService.warmCache(
        fetchCities: () => apiService.getCities(),
        fetchTeams: () => apiService.getAllTeams(limit: 50),
      );
    } catch (e) {
      // Silently fail cache warming - app will fetch data on demand
      debugPrint('Cache warming failed: $e');
    }
  }

  /// Create error screen widget for configuration failures
  static Widget createConfigurationErrorScreen(
    Object error,
    VoidCallback onRetry,
  ) {
    return ScreenErrorBoundary(
      screenName: 'ConfigurationError',
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Configuration Error',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App initialization failed: $error\n\nPlease check your configuration and try again.',
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen error boundary widget for initialization errors
class ScreenErrorBoundary extends StatelessWidget {
  final String screenName;
  final Widget child;

  const ScreenErrorBoundary({
    super.key,
    required this.screenName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
