import 'package:flutter/foundation.dart';

/// Web-specific configuration for Nlaabo
class WebConfig {
  static const bool isWeb = kIsWeb;
  
  // Web renderer configuration
  static const String webRenderer = 'canvaskit';
  
  // Performance settings
  static const bool enableWebCaching = true;
  static const bool enableServiceWorker = true;
  static const bool enablePWA = true;
  
  // Network timeouts (optimized for web)
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration supabaseTimeout = Duration(seconds: 25);
  
  // Cache settings
  static const Duration cacheMaxAge = Duration(hours: 24);
  static const Duration staticCacheMaxAge = Duration(days: 30);
  
  // PWA settings
  static const String manifestPath = '/manifest.json';
  static const String serviceWorkerPath = '/flutter_service_worker.js';
  
  // Web-specific features
  static const bool supportsFileDownload = true;
  static const bool supportsClipboard = true;
  static const bool supportsFullscreen = true;
  
  // Security settings
  static const Map<String, String> securityHeaders = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
  };
  
  // CDN and external resources
  static const String canvasKitBaseUrl = 'https://unpkg.com/canvaskit-wasm@0.38.0/bin/';
  static const String fontsBaseUrl = 'https://fonts.googleapis.com';
  
  /// Check if running in production web environment
  static bool get isProductionWeb => isWeb && !kDebugMode;
  
  /// Check if running in development web environment
  static bool get isDevelopmentWeb => isWeb && kDebugMode;
  
  /// Get web-specific user agent info
  static String get userAgent {
    if (!isWeb) return 'Not Web';
    // In web, we can access navigator.userAgent through dart:html
    return 'Web Browser';
  }
  
  /// Web-specific initialization
  static Future<void> initialize() async {
    if (!isWeb) return;
    
    debugPrint('Initializing web configuration...');
    
    // Web-specific initialization logic
    await _setupWebFeatures();
    await _registerServiceWorker();
    
    debugPrint('Web configuration initialized successfully');
  }
  
  static Future<void> _setupWebFeatures() async {
    // Setup web-specific features like clipboard, fullscreen, etc.
    debugPrint('Setting up web features...');
  }
  
  static Future<void> _registerServiceWorker() async {
    if (!enableServiceWorker) return;
    
    debugPrint('Registering service worker...');
    // Service worker registration is handled in index.html
  }
  
  /// Get optimized image loading settings for web
  static Map<String, dynamic> get imageLoadingConfig => {
    'enableCaching': enableWebCaching,
    'maxCacheSize': 100 * 1024 * 1024, // 100MB
    'compressionQuality': 0.8,
    'enableWebP': true,
    'enableLazyLoading': true,
  };
  
  /// Get web-specific network configuration
  static Map<String, dynamic> get networkConfig => {
    'connectTimeout': connectTimeout.inMilliseconds,
    'receiveTimeout': receiveTimeout.inMilliseconds,
    'enableRetry': true,
    'maxRetries': 3,
    'retryDelay': 1000, // 1 second
  };
}