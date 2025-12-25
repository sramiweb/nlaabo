import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/error_handler.dart';
import '../utils/app_logger.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    String method = 'email', // Added parameters
    String? phone,
  }) async {
    return ErrorHandler.withRetry(
      () async {
        logDebug('Attempting signup for $email with role $role');

        final response = await _supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'role': role,
            'email': email,
            'signup_method': method,
            if (phone != null) 'phone': phone,
          },
        );

        if (response.user != null) {
          logDebug('Signup successful, user ID: ${response.user!.id}');
        } else {
          logWarning('Signup completed but no user returned');
        }

        return response;
      },
      context: 'AuthRepository.signup',
    );
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return ErrorHandler.withRetry(
      () async {
        logDebug('Attempting login for $email');

        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.user != null) {
          logDebug('Login successful for user: ${response.user!.id}');
        }

        return response;
      },
      context: 'AuthRepository.login',
    );
  }

  Future<void> logout() async {
    return ErrorHandler.withErrorHandling(
      () async {
        await _supabase.auth.signOut();
        logDebug('User scheduled logout');
      },
      context: 'AuthRepository.logout',
    );
  }

  // Alias for logout
  Future<void> signOut() => logout();

  Future<void> requestPasswordReset(String email) async {
    return ErrorHandler.withRetry(
      () async {
        await _supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: 'io.supabase.nlaabo://reset-password',
        );
        logDebug('Password reset requested for $email');
      },
      context: 'AuthRepository.requestPasswordReset',
    );
  }

  Future<void> resetPassword(String newPassword) async {
    return ErrorHandler.withRetry(
      () async {
        await _supabase.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        logDebug('Password updated successfully');
      },
      context: 'AuthRepository.resetPassword',
    );
  }

  bool needsOnboarding() {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    // Check metadata 'onboarded'. Default to true (need onboarding) if missing?
    // Usually logical is: if !onboarded then true.
    // Let's assume 'onboarded' = true means done.
    final onboarded = user.userMetadata?['onboarded'] as bool? ?? false;
    return !onboarded;
  }

  Future<void> completeOnboarding() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.auth.updateUser(UserAttributes(data: {'onboarded': true}));
  }

  // Helper to get formatted error message (moved from ApiService or duplicated for utility)
  String getAuthErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    }
    return error.toString();
  }
}
