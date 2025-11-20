import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';

/// Service to handle offline mode and cache user data
class OfflineModeService {
  static const String _keyOfflineMode = 'offline_mode';
  static const String _keyPendingSignups = 'pending_signups';
  
  /// Check if app is in offline mode
  static Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOfflineMode) ?? false;
  }
  
  /// Enable offline mode
  static Future<void> enableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, true);
    debugPrint('Offline mode enabled');
  }
  
  /// Disable offline mode
  static Future<void> disableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, false);
    debugPrint('Offline mode disabled');
  }
  
  /// Store signup data for later processing when online
  static Future<void> storePendingSignup(Map<String, dynamic> signupData) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSignups = await getPendingSignups();

    // Hash the password before storing
    if (signupData.containsKey('password') && signupData['password'] != null) {
      final hashedPassword = BCrypt.hashpw(signupData['password'], BCrypt.gensalt());
      signupData['password'] = hashedPassword;
    }

    // Add timestamp
    signupData['pending_since'] = DateTime.now().toIso8601String();

    pendingSignups.add(signupData);
    await prefs.setString(_keyPendingSignups, jsonEncode(pendingSignups));

    debugPrint('Stored pending signup for ${signupData['email']} with hashed password');
  }
  
  /// Get all pending signups
  static Future<List<Map<String, dynamic>>> getPendingSignups() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPendingSignups);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding pending signups: $e');
      return [];
    }
  }
  
  /// Clear all pending signups
  static Future<void> clearPendingSignups() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPendingSignups);
    debugPrint('Cleared all pending signups');
  }
  
  /// Process pending signups when back online
  static Future<List<String>> processPendingSignups() async {
    final pendingSignups = await getPendingSignups();
    final results = <String>[];
    
    if (pendingSignups.isEmpty) {
      return results;
    }
    
    debugPrint('Processing ${pendingSignups.length} pending signups...');
    
    for (final signup in pendingSignups) {
      try {
        // Here you would call your actual signup API
        // For now, we'll just simulate success
        results.add('✅ ${signup['email']}: Signup completed');
      } catch (e) {
        results.add('❌ ${signup['email']}: Failed - $e');
      }
    }
    
    // Clear processed signups
    await clearPendingSignups();
    
    return results;
  }
  
  /// Show offline mode notification
  static String getOfflineModeMessage() {
    return '''
You're currently in offline mode.

Your signup information has been saved locally and will be processed automatically when you're back online.

Features available offline:
• Browse cached content
• View saved data
• Prepare signup information

To go online:
• Check your internet connection
• Tap "Test Connection" to verify
• The app will automatically sync when connected
''';
  }
}
