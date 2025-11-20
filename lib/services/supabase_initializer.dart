import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseInitializer {
  static bool _initialized = false;
  
  /// Initialize Supabase with proper error handling and validation
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      final url = await supabaseUrl;
      final key = await supabaseAnonKey;
      
      if (url.isEmpty || key.isEmpty) {
        throw Exception('Supabase configuration is missing. Please initialize credentials using SecureCredentialService.');
      }
      
      debugPrint('Initializing Supabase...');
      debugPrint('URL: ${url.length > 10 ? '${url.substring(0, 10)}...' : url}');
      debugPrint('Key length: ${key.length}');
      
      await Supabase.initialize(
        url: url,
        anonKey: key,
        debug: kDebugMode,
      );
      
      _initialized = true;
      debugPrint('Supabase initialized successfully');
      
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }
  
  /// Check if Supabase is properly initialized
  static bool get isInitialized => _initialized;
  
  /// Get Supabase client with initialization check
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase not initialized. Call SupabaseInitializer.initialize() first.');
    }
    return Supabase.instance.client;
  }
}
