import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Mobile-specific secure credential storage using flutter_secure_storage
class SecureCredentialService {
  static const _storage = FlutterSecureStorage();

  static const _supabaseUrlKey = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  static const _credentialsInitializedKey = 'credentials_initialized';

  static Future<void> initializeCredentials({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    try {
      debugPrint('Initializing secure credentials...');

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw ArgumentError('Supabase URL and anonymous key cannot be empty');
      }

      await _storage.write(key: _supabaseUrlKey, value: supabaseUrl);
      await _storage.write(key: _supabaseAnonKey, value: supabaseAnonKey);
      await _storage.write(key: _credentialsInitializedKey, value: 'true');

      debugPrint('Secure credentials initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize secure credentials: $e');
      rethrow;
    }
  }

  static Future<bool> areCredentialsInitialized() async {
    try {
      final initialized = await _storage.read(key: _credentialsInitializedKey);
      return initialized == 'true';
    } catch (e) {
      debugPrint('Error checking credential initialization: $e');
      return false;
    }
  }

  static Future<String?> getSupabaseUrl() async {
    try {
      return await _storage.read(key: _supabaseUrlKey);
    } catch (e) {
      debugPrint('Error reading Supabase URL: $e');
      return null;
    }
  }

  static Future<String?> getSupabaseAnonKey() async {
    try {
      return await _storage.read(key: _supabaseAnonKey);
    } catch (e) {
      debugPrint('Error reading Supabase anonymous key: $e');
      return null;
    }
  }

  static Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _supabaseUrlKey);
      await _storage.delete(key: _supabaseAnonKey);
      await _storage.delete(key: _credentialsInitializedKey);
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
