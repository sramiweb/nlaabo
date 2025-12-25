// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class WebCacheService {
  static const String _keyPrefix = 'nlaabo_';

  static Future<void> initialize() async {
    // Initialize for any platform, but only do web-specific work on web
    if (kIsWeb) {
      // Web-specific initialization
    }
  }

  static Future<void> setString(String key, String value) async {
    if (kIsWeb) {
      html.window.localStorage['$_keyPrefix$key'] = value;
    } else {
      // For non-web platforms, could fall back to shared_preferences or other storage
      // For now, silently ignore to maintain compatibility
    }
  }

  static String? getString(String key) {
    if (kIsWeb) {
      return html.window.localStorage['$_keyPrefix$key'];
    }
    // For non-web platforms, return null (could implement fallback storage)
    return null;
  }

  static Future<void> remove(String key) async {
    if (kIsWeb) {
      html.window.localStorage.remove('$_keyPrefix$key');
    } else {
      // For non-web platforms, could implement fallback removal
    }
  }

  static Future<void> clear() async {
    if (kIsWeb) {
      final keys = html.window.localStorage.keys
          .where((key) => key.startsWith(_keyPrefix))
          .toList();
      for (final key in keys) {
        html.window.localStorage.remove(key);
      }
    } else {
      // For non-web platforms, could implement fallback clearing
    }
  }
}
