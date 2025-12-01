import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../services/error_reporting_service.dart';
import '../services/feedback_service.dart';
import '../services/robust_supabase_client.dart';
import '../models/user.dart' as app_user;
import '../utils/app_logger.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  app_user.User? _currentUser;
  bool _isLoading = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();


  void _safeNotifyListeners() {
    // Only notify if there are active listeners to prevent assertion errors
    if (hasListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Clean up resources when the provider is disposed
    _profileSubscription?.cancel();
    _apiService.dispose();
    _currentUser = null;
    super.dispose();
  }

  app_user.User? get currentUser => _currentUser;
  app_user.User? get user => _currentUser; // For compatibility
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null; // For compatibility
  bool get isAdmin => _currentUser?.role == 'admin';

  // Add token getter for backward compatibility with tests
  String? get token => null; // Supabase handles tokens automatically

  AuthProvider() {
    _initialize();
  }

  StreamSubscription? _profileSubscription;

  void _initializeRealtimeUpdates() {
    // Only setup real-time updates if user is authenticated
    if (_currentUser == null) return;

    // Cancel existing subscription to prevent duplicates
    _profileSubscription?.cancel();

    _profileSubscription = _apiService.userProfileStream.listen(
      (user) {
        if (user != null) {
          _currentUser = user;
          _isLoading = false;
          _safeNotifyListeners();
        }
      },
      onError: (error) {
        _isLoading = false;
        _safeNotifyListeners();
      },
    );
  }

  Future<void> _initialize() async {
    // Commented out to preserve authentication between app restarts
    // await clearAllStoredData();
    await _loadSavedToken();
  }

  Future<void> _loadSavedToken() async {
    // With Supabase, token management is handled automatically
    // We just need to check if user is authenticated
    try {
      _isLoading = true;
      _safeNotifyListeners();

      // Check if Supabase is initialized before trying to get current user
      try {
        final user = await _apiService.getCurrentUser();
        _currentUser = user;

        // Initialize real-time updates only after successful authentication
        if (_currentUser != null) {
          _initializeRealtimeUpdates();
          // Initialize real-time subscriptions in ApiService
          _apiService.initializeRealtimeSubscriptions();
        }
      } catch (e) {
        if (e.toString().contains('not initialized')) {
          logDebug('Supabase not initialized yet during auth check: $e');
        } else {
          logDebug('User not authenticated: $e');
        }
        _currentUser = null;
      }
    } catch (e) {
      logError('Error in _loadSavedToken: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Token management is now handled automatically by Supabase client
  // These methods are kept for backward compatibility but don't store tokens
  Future<void> _saveToken(String token) async {
    // Supabase handles token storage automatically
  }

  Future<void> _clearToken() async {
    // Supabase handles token clearing automatically
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    int? age,
    String? phone,
    String? gender,
    String? role,
  }) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      logDebug('Starting signup process for email: $email');

      final response = await _apiService.signup(
        name: name,
        email: email,
        password: password,
        age: age,
        phone: phone,
        gender: gender,
        role: role ?? 'player',
      );

      logDebug('Signup API call completed successfully');

      // Handle different API response structures
      if (response.containsKey('user') || response.containsKey('data')) {
        final dynamic userData = response['user'] ?? response['data']?['user'];
        final dynamic sessionData = response['session'] ?? response['data']?['session'];

        if (userData != null) {
          _currentUser = _createUserSafely(
            userData: userData as Map<String, dynamic>,
            fallbackName: name,
            fallbackEmail: email,
          );

          logDebug('User object created successfully. User ID: ${_currentUser?.id}');

          // Store session token if available (for confirmed accounts)
          if (sessionData != null && sessionData is Map<String, dynamic> && sessionData.containsKey('access_token')) {
            await _saveToken(sessionData['access_token'] as String);
            logDebug('Session token saved. User is logged in.');

            // Initialize real-time updates after successful login
            _initializeRealtimeUpdates();
            _apiService.initializeRealtimeSubscriptions();

            _isLoading = false;
            _safeNotifyListeners();
            return true; // Email confirmed and session active
          } else {
            // Email confirmation required - user created but not confirmed
            logDebug('Email confirmation required. User created but not logged in.');
            _isLoading = false;
            _safeNotifyListeners();
            return false; // Email confirmation pending
          }
        }
      }

      logError('Invalid response structure received');
      throw Exception('Signup failed: Invalid response structure');
    } catch (e, st) {
      logError('Signup failed with error: $e');

      final standardizedError = ErrorHandler.standardizeError(e, st);
      ErrorHandler.logError(standardizedError, st, 'AuthProvider.signup');

      // Report signup errors for monitoring
      final reportingService = ErrorReportingService();
      await reportingService.reportError(
        standardizedError,
        context: 'AuthProvider.signup',
        additionalData: {
          'email': email,
          'error_type': standardizedError.runtimeType.toString(),
          'error_code': standardizedError.code,
        },
      );

      _isLoading = false;
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      logDebug('Starting login process for email: $email');

      final response = await _apiService.login(
        email: email,
        password: password,
      );

      logDebug('Login API call completed successfully');

      // Handle the response structure
      if (response.containsKey('user')) {
        final dynamic userData = response['user'];

        if (userData is Map<String, dynamic>) {
          _currentUser = _createUserSafely(
            userData: userData,
            fallbackEmail: email,
          );
        } else {
          _currentUser = userData as app_user.User;
        }

        logDebug('User object created successfully. User ID: ${_currentUser?.id}');

        // Save token if available
        if (response.containsKey('access_token')) {
          await _saveToken(response['access_token'] as String);
          logDebug('Session token saved');
        }

        // Initialize real-time updates after successful login
        _initializeRealtimeUpdates();
        // Initialize real-time subscriptions in ApiService
        _apiService.initializeRealtimeSubscriptions();

        logDebug('Login process completed successfully');
      } else {
        logError('Invalid response structure - no user data found');
        throw Exception('Login failed: Invalid response structure');
      }

      _isLoading = false;
      _safeNotifyListeners();
    } catch (e, st) {
      logError('Login failed with error: $e');

      final standardizedError = ErrorHandler.standardizeError(e, st);
      ErrorHandler.logError(standardizedError, st, 'AuthProvider.login');

      // Report auth errors for monitoring
      final reportingService = ErrorReportingService();
      await reportingService.reportError(
        standardizedError,
        context: 'AuthProvider.login',
        additionalData: {
          'email': email,
          'error_type': standardizedError.runtimeType.toString(),
          'error_code': standardizedError.code,
        },
      );

      _isLoading = false;
      _safeNotifyListeners();
      rethrow;
    }
  }

  /// Login with enhanced error handling and user feedback
  Future<void> loginWithFeedback(
    BuildContext context, {
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      // Assuming the response contains token and user data
      if (response.containsKey('access_token') &&
          response.containsKey('user')) {
        await _saveToken(response['access_token'] as String);

        final dynamic userData = response['user'];
        if (userData is Map<String, dynamic>) {
          _currentUser = _createUserSafely(
            userData: userData,
            fallbackEmail: email,
          );
        }
      }

      _isLoading = false;
      _safeNotifyListeners();

      // Show success feedback
      if (context.mounted) {
        context.showSuccess('Login successful!');
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.loginWithFeedback');
      _isLoading = false;
      _safeNotifyListeners();

      // Show error feedback
      if (context.mounted) {
        context.showError(
          e,
          onRetry: () =>
              loginWithFeedback(context, email: email, password: password),
        );
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Clean up real-time subscriptions before logout
      _profileSubscription?.cancel();
      await _apiService.dispose();

      // Sign out from Supabase
      await RobustSupabaseClient.client.auth.signOut();
      
      await _clearToken();
      _currentUser = null;
      _safeNotifyListeners();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.logout');
      // Even if logout fails, clear local state
      _currentUser = null;
      _safeNotifyListeners();
    }
  }

  Future<void> clearAllStoredData() async {
    await _secureStorage.deleteAll();
    _currentUser = null;
    // Auth token is now handled automatically by Supabase client
    _safeNotifyListeners();
  }

  // Debug method to force clear stored data (for development)
  Future<void> forceClearStoredData() async {
    await clearAllStoredData();
  }

  Future<void> refreshUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      _currentUser = user;
      _safeNotifyListeners();
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.refreshUser');
      // Report auth errors for monitoring
      final reportingService = ErrorReportingService();
      await reportingService.reportError(
        ErrorHandler.standardizeError(e, st),
        userId: _currentUser?.id,
        context: 'AuthProvider.refreshUser',
      );
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? name,
    String? position,
    String? bio,
    String? imageUrl,
    String? gender,
    String? phone,
    int? age,
    String? location,
    String? skillLevel,
  }) async {
    logDebug('updateProfile called with: name=$name, position=$position, bio=$bio, phone=$phone, age=$age, location=$location, gender=$gender, skillLevel=$skillLevel, imageUrl=$imageUrl');
    
    try {
      final updatedUser = await _apiService.updateProfile(
        name: name,
        position: position,
        bio: bio,
        imageUrl: imageUrl,
        gender: gender,
        phone: phone,
        age: age,
        location: location,
        skillLevel: skillLevel,
      );
      logDebug('updateProfile completed successfully');
      
      _currentUser = updatedUser;
      _safeNotifyListeners();
    } catch (e, st) {
      logError('updateProfile error: $e');
      ErrorHandler.logError(e, st, 'AuthProvider.updateProfile');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
    try {
      return await _apiService.getUserStats(forceRefresh: forceRefresh);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'AuthProvider.getUserStats');
      return {'matches_joined': 0, 'matches_created': 0, 'teams_owned': 0};
    }
  }

  /// Safely create User object with proper null safety and validation
  app_user.User _createUserSafely({
    required Map<String, dynamic> userData,
    String? fallbackName,
    String? fallbackEmail,
  }) {
    try {
      final completeData = {
        ...userData,
        if (fallbackName != null && (userData['name'] == null || userData['full_name'] == null))
          'name': fallbackName,
      };
      return app_user.User.fromJson(completeData);
    } catch (e) {
      logWarning('User.fromJson failed: $e. Creating fallback user.');
      
      final id = userData['id']?.toString();
      if (id == null || id.isEmpty) {
        throw ArgumentError('Cannot create user without valid ID');
      }

      final email = userData['email']?.toString() ?? fallbackEmail ?? '';
      if (email.isEmpty) {
        throw ArgumentError('Cannot create user without valid email');
      }

      final name = userData['name']?.toString() ??
          userData['full_name']?.toString() ??
          fallbackName ??
          email.split('@').first;

      DateTime createdAt;
      try {
        createdAt = userData['created_at'] != null
            ? DateTime.parse(userData['created_at'].toString())
            : DateTime.now();
      } catch (_) {
        createdAt = DateTime.now();
      }

      return app_user.User(
        id: id,
        name: name,
        email: email,
        role: userData['role']?.toString() ?? 'player',
        createdAt: createdAt,
        age: userData['age'] != null ? int.tryParse(userData['age'].toString()) : null,
        phone: userData['phone']?.toString(),
        gender: userData['gender']?.toString(),
        location: userData['location']?.toString(),
        position: userData['position']?.toString(),
        bio: userData['bio']?.toString(),
        imageUrl: userData['avatar_url']?.toString() ?? userData['image_url']?.toString(),
      );
    }
  }
}
