import 'package:flutter/foundation.dart';
import '../services/secure_credential_service.dart';

/// Supabase configuration loaded from secure storage.
/// These are defined as getters so the values are read at access time (after
/// credentials have been initialized).

/// Gets the Supabase URL from secure storage with validation.
/// Throws an exception if the URL is missing or empty to prevent runtime failures.
Future<String> get supabaseUrl async {
  final url = await SecureCredentialService.getSupabaseUrl();

  if (url == null || url.isEmpty) {
    debugPrint('ERROR: SUPABASE_URL is not set in secure storage');
    throw Exception(
      'Missing Supabase configuration: SUPABASE_URL is not set. '
      'Please initialize credentials using SecureCredentialService.initializeCredentials().'
    );
  }

  return url;
}

/// Gets the Supabase anonymous key from secure storage with validation.
/// Throws an exception if the key is missing or empty to prevent runtime failures.
Future<String> get supabaseAnonKey async {
  final key = await SecureCredentialService.getSupabaseAnonKey();

  if (key == null || key.isEmpty) {
    debugPrint('ERROR: SUPABASE_ANON_KEY is not set in secure storage');
    throw Exception(
      'Missing Supabase configuration: SUPABASE_ANON_KEY is not set. '
      'Please initialize credentials using SecureCredentialService.initializeCredentials().'
    );
  }

  return key;
}

// Redirect URLs are configured in Supabase dashboard
