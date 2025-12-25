// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// Web-specific secure credential storage using localStorage
class SecureCredentialService {
  // Storage keys
  static const _supabaseUrlKey = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  static const _credentialsInitializedKey = 'credentials_initialized';

  static Future<void> initializeCredentials({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      debugPrint('Initializing secure credentials (web)...');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw ArgumentError('Supabase URL and anonymous key cannot be empty');
      }

      html.window.localStorage[_supabaseUrlKey] = supabaseUrl;
      html.window.localStorage[_supabaseAnonKey] = supabaseAnonKey;
      html.window.localStorage[_credentialsInitializedKey] = 'true';

      debugPrint('Secure credentials initialized successfully (web)');
    } catch (e) {
      debugPrint('Failed to initialize secure credentials: $e');
      rethrow;
    }
  }

  static Future<bool> areCredentialsInitialized() async {
    try {
      return html.window.localStorage[_credentialsInitializedKey] == 'true';
    } catch (e) {
      debugPrint('Error checking credential initialization: $e');
      return false;
    }
  }

  static Future<String?> getSupabaseUrl() async {
    try {
      return html.window.localStorage[_supabaseUrlKey];
    } catch (e) {
      debugPrint('Error reading Supabase URL: $e');
      return null;
    }
  }

  static Future<String?> getSupabaseAnonKey() async {
    try {
      return html.window.localStorage[_supabaseAnonKey];
    } catch (e) {
      debugPrint('Error reading Supabase anonymous key: $e');
      return null;
    }
  }

  static Future<void> clearCredentials() async {
    try {
      html.window.localStorage.remove(_supabaseUrlKey);
      html.window.localStorage.remove(_supabaseAnonKey);
      html.window.localStorage.remove(_credentialsInitializedKey);
      debugPrint('Secure credentials cleared');
    } catch (e) {
      debugPrint('Error clearing credentials: $e');
      rethrow;
    }
  }

  static Future<CredentialValidationResult> validateCredentials() async {
    try {
      final url = await getSupabaseUrl();
      final key = await getSupabaseAnonKey();
      final initialized = await areCredentialsInitialized();

      if (!initialized) {
        return CredentialValidationResult(
          isValid: false,
          error: 'Credentials not initialized',
          missingFields: ['url', 'key'],
        );
      }

      final missingFields = <String>[];
      if (url == null || url.isEmpty) missingFields.add('url');
      if (key == null || key.isEmpty) missingFields.add('key');

      if (missingFields.isNotEmpty) {
        return CredentialValidationResult(
          isValid: false,
          error: 'Missing required credentials',
          missingFields: missingFields,
        );
      }

      if (!url!.startsWith('https://') || !url.contains('.supabase.co')) {
        return CredentialValidationResult(
          isValid: false,
          error: 'Invalid Supabase URL format',
        );
      }

      if (!key!.contains('.') || key.split('.').length != 3) {
        return CredentialValidationResult(
          isValid: false,
          error: 'Invalid Supabase anonymous key format',
        );
      }

      return CredentialValidationResult(isValid: true);
    } catch (e) {
      return CredentialValidationResult(
        isValid: false,
        error: 'Validation failed: $e',
      );
    }
  }

  static Future<Map<String, String?>> getAllCredentials() async {
    try {
      final url = await getSupabaseUrl();
      final key = await getSupabaseAnonKey();
      final initialized = await areCredentialsInitialized();

      return {
        'url': url,
        'key': key,
        'initialized': initialized.toString(),
      };
    } catch (e) {
      debugPrint('Error getting all credentials: $e');
      return {};
    }
  }
}

class CredentialValidationResult {
  final bool isValid;
  final String? error;
  final List<String> missingFields;

  CredentialValidationResult({
    required this.isValid,
    this.error,
    this.missingFields = const [],
  });

  @override
  String toString() {
    if (isValid) return 'Credentials are valid';
    return 'Invalid credentials: $error${missingFields.isNotEmpty ? ' (missing: ${missingFields.join(', ')})' : ''}';
  }
}
