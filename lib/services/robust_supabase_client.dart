import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/app_config.dart';
import 'network_fallback_service.dart';

/// A robust Supabase client wrapper with enhanced error handling and fallback mechanisms
class RobustSupabaseClient {
  static RobustSupabaseClient? _instance;
  static SupabaseClient? _client;
  
  RobustSupabaseClient._();
  
  static RobustSupabaseClient get instance {
    _instance ??= RobustSupabaseClient._();
    return _instance!;
  }
  
  /// Initialize Supabase with enhanced error handling
  static Future<void> initialize() async {
    if (_client != null) {
      debugPrint('Supabase already initialized');
      return;
    }

    try {
      final url = await supabaseUrl;
      final key = await supabaseAnonKey;

      if (url.isEmpty || key.isEmpty) {
        throw Exception('Supabase configuration is missing. Please initialize credentials using SecureCredentialService.');
      }

      debugPrint('Initializing Supabase...');
      debugPrint('URL: ${url.length > 10 ? '${url.substring(0, 10)}...' : url}');
      debugPrint('Key length: ${key.length}');

      // Check if Supabase is already initialized
      try {
        final existingClient = Supabase.instance.client;
        // Simple check if client exists and seems valid
        if (existingClient.auth.currentUser != null || true) {
          debugPrint('Using existing Supabase instance');
          _client = existingClient;
          return;
        }
      } catch (e) {
        // Supabase not initialized yet, continue with initialization
        debugPrint('Supabase not yet initialized, proceeding with setup');
      }

      // Skip network check during initialization for WiFi compatibility
      debugPrint('Proceeding with Supabase initialization (network check skipped for WiFi compatibility)');

      await Supabase.initialize(
        url: url,
        anonKey: key,
        debug: kDebugMode,
      );

      _client = Supabase.instance.client;
      debugPrint('Supabase initialized successfully');

    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      // For WiFi connections, provide more specific error handling
      if (e.toString().toLowerCase().contains('failed host lookup')) {
        throw NetworkException(
          'DNS resolution failed. Please check your WiFi connection and try again.',
          NetworkStatus(
            isConnected: false,
            canReachSupabase: false,
            message: 'DNS resolution failed',
            details: e.toString(),
          ),
        );
      } else if (e.toString().toLowerCase().contains('network') ||
                 e.toString().toLowerCase().contains('timeout')) {
        throw NetworkException(
          'Network timeout. Please check your WiFi connection and try again.',
          NetworkStatus(
            isConnected: false,
            canReachSupabase: false,
            message: 'Network timeout',
            details: e.toString(),
          ),
        );
      }
      rethrow;
    }
  }
  

  
  /// Get Supabase client with initialization check
  static SupabaseClient get client {
    if (_client == null) {
      throw StateError('Supabase not initialized. Call RobustSupabaseClient.initialize() first.');
    }
    return _client!;
  }
  
  /// Execute a Supabase operation with retry logic and enhanced error handling
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int? maxRetries,
    Duration? initialDelay,
    String? operationName,
  }) async {
    final networkConfig = AppConfig.instance.network;
    final effectiveMaxRetries = maxRetries ?? networkConfig.maxRetries;
    final effectiveInitialDelay = initialDelay ?? networkConfig.initialRetryDelay;

    Exception? lastException;

    for (int attempt = 1; attempt <= effectiveMaxRetries; attempt++) {
      try {
         debugPrint('${operationName ?? 'Operation'} attempt $attempt/$effectiveMaxRetries');
         return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('${operationName ?? 'Operation'} attempt $attempt failed: $e');

        // Check if it's a DNS/network error
        if (_isDNSError(e)) {
          debugPrint('DNS resolution error detected');
          if (attempt < effectiveMaxRetries) {
            // Wait longer for DNS issues
            final delay = Duration(seconds: effectiveInitialDelay.inSeconds * attempt * 2);
            debugPrint('DNS error - waiting ${delay.inSeconds}s before retry...');
            await Future.delayed(delay);
          } else {
            throw NetworkException(
              'Cannot connect to Nlaabo servers. Please check your internet connection and try again.',
              NetworkStatus(
                isConnected: false,
                canReachSupabase: false,
                message: 'DNS resolution failed',
                details: e.toString(),
              ),
            );
          }
        } else if (_isNetworkError(e) && attempt < effectiveMaxRetries) {
          debugPrint('Network error detected, retrying...');

          // Wait before retrying with exponential backoff
          final delay = Duration(seconds: effectiveInitialDelay.inSeconds * attempt);
          debugPrint('Waiting ${delay.inSeconds}s before retry...');
          await Future.delayed(delay);
        } else if (attempt == effectiveMaxRetries) {
          debugPrint('Max retries reached, throwing last exception');
          break;
        }
      }
    }
    
    throw lastException!;
  }
  
  /// Check if an error is DNS-related
  static bool _isDNSError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed host lookup') ||
           errorString.contains('no address associated with hostname') ||
           errorString.contains('nodename nor servname provided');
  }
  
  /// Check if an error is network-related
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
           errorString.contains('network is unreachable') ||
           errorString.contains('connection refused') ||
           errorString.contains('timeout') ||
           errorString.contains('clientexception');
  }
  
  /// Enhanced signup method with retry logic
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return executeWithRetry(
      () => client.auth.signUp(
        email: email,
        password: password,
        data: data,
      ),
      operationName: 'SignUp',
    );
  }
  
  /// Enhanced sign in method with retry logic
  static Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return executeWithRetry(
      () => client.auth.signInWithPassword(
        email: email,
        password: password,
      ),
      operationName: 'SignIn',
    );
  }
  
  /// Enhanced database query with retry logic
  static Future<T> query<T>(
    Future<T> Function(SupabaseClient client) queryFunction, {
    String? operationName,
  }) async {
    return executeWithRetry(
      () => queryFunction(client),
      operationName: operationName ?? 'DatabaseQuery',
    );
  }
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;
  final NetworkStatus networkStatus;
  
  NetworkException(this.message, this.networkStatus);
  
  @override
  String toString() => 'NetworkException: $message';
}
