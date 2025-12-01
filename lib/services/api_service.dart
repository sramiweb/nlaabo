import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../utils/app_logger.dart';
import '../utils/response_parser.dart';
import 'error_handler.dart';
import 'robust_supabase_client.dart';
import '../models/user.dart' as app_user;
import '../models/match.dart';
import '../models/team.dart';
import '../models/notification.dart';
import '../models/team.dart' as team_models;
import '../models/city.dart';
import '../utils/validators.dart';
import '../utils/input_sanitizer.dart';
import 'cache_service.dart';
import 'performance_monitor.dart';
import 'authorization_service.dart';

// Default retry configuration for network operations
final _defaultRetryConfig = RetryConfig(
  maxAttempts: 3,
  initialDelay: const Duration(seconds: 1),
  backoffMultiplier: 2.0,
  maxDelay: const Duration(seconds: 10),
  shouldRetry: (error) => error is NetworkError ||
                         error is TimeoutError ||
                         error is RateLimitError ||
                         (error is ServiceUnavailableError && error.isTemporary),
);

class ApiService {
    SupabaseClient get _supabase {
      try {
        return RobustSupabaseClient.client;
      } catch (e) {
        throw StateError('Supabase not initialized. Please ensure RobustSupabaseClient.initialize() is called first.');
      }
    }
    final CacheService _cacheService = CacheService();
    late final AuthorizationService _authService;

    ApiService() {
      _authService = AuthorizationService(this);
    }

    // Subscription management
    final Map<String, RealtimeChannel> _activeSubscriptions = {};

    /// Cleanup method to dispose of subscriptions
    Future<void> dispose() async {
      final subscriptions = List.from(_activeSubscriptions.values);
      _activeSubscriptions.clear();
      
      for (final subscription in subscriptions) {
        try {
          await subscription.unsubscribe();
        } catch (e) {
          ErrorHandler.logError(e, null, 'ApiService.dispose');
        }
      }
    }



  // Real-time subscriptions
  Stream<List<Match>> get matchesStream => _supabase
      .from('matches')
      .stream(primaryKey: ['id'])
      .eq('status', 'open')
      .order('match_date')
      .map((data) {
        final List<Match> matches = [];
        for (final json in data) {
          try {
            final teamId = json['team_id'] ?? json['team1_id'] ?? json['team_1_id'];
            if (teamId == null || teamId.toString().trim().isEmpty) {
              logDebug('Skipping match with missing team ID in stream: ${json['id']}');
              continue;
            }
            matches.add(Match.fromJson(json));
          } catch (e) {
            logError('Failed to parse match data in stream: $e');
            continue;
          }
        }
        return matches;
      });

  Stream<List<Team>> get teamsStream => _supabase
      .from('teams')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((data) => data.map((json) => Team.fromJson(json)).toList());

  Stream<List<NotificationModel>> get notificationsStream => _supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());

  // User profile real-time stream
  Stream<app_user.User?> get userProfileStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(null);

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return app_user.User.fromJson(data.first);
        });
  }

  // User-specific notifications stream
  Stream<List<NotificationModel>> get userNotificationsStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => NotificationModel.fromJson(json)).toList());
  }

  // User teams stream
  Stream<List<Team>> get userTeamsStream {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

    return _supabase
        .from('teams')
        .stream(primaryKey: ['id'])
        .eq('owner_id', user.id)
        .order('created_at', ascending: false)
        .map((teams) => teams.where((t) => t['deleted_at'] == null).toList())
        .asyncMap((ownedTeams) async {
          final memberResponse = await _supabase
              .from('team_members')
              .select('teams!inner(*)')
              .eq('user_id', user.id);

          final List<Team> allTeams = ownedTeams.map((json) => Team.fromJson(json)).toList();

          for (final item in memberResponse) {
            if (item['teams'] != null) {
              final teamData = item['teams'] as Map<String, dynamic>;
              if (teamData['deleted_at'] == null) {
                final team = Team.fromJson(teamData);
                if (!allTeams.any((t) => t.id == team.id)) {
                  allTeams.add(team);
                }
              }
            }
          }
        
          allTeams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return allTeams;
        });
  }

  /// Initialize real-time subscriptions after authentication
  /// This should be called from AuthProvider after successful login
  void initializeRealtimeSubscriptions() {
    // Only initialize if not already initialized
    if (_activeSubscriptions.isNotEmpty) return;

    // Set up real-time listeners for critical data with error handling
    _setupSubscription('teams', 'teams', (payload) {
      // Only invalidate teams cache when data changes
      _cacheService.invalidateTeamsCache();
    });

    _setupSubscription('users', 'users', (payload) {
      // Only invalidate user stats cache when user data changes
      _cacheService.invalidateUserStatsCache();
    });
  }

   void _setupSubscription(String channelName, String tableName, Function(PostgresChangePayload) callback) {
     // Check authentication before setting up subscription
     final user = _supabase.auth.currentUser;
     if (user == null) {
       logDebug('Skipping real-time subscription setup for $channelName: user not authenticated');
       return;
     }

     try {
       final channel = _supabase.channel(channelName);

       channel.onPostgresChanges(
         event: PostgresChangeEvent.all,
         schema: 'public',
         table: tableName,
         callback: (payload) {
           try {
             callback(payload);
           } catch (e) {
             ErrorHandler.logError(e, null, 'RealtimeCallback_$tableName');
           }
         },
       );

       // Store reference for cleanup
       _activeSubscriptions[channelName] = channel;

       channel.subscribe(
         (status, error) {
           if (status == RealtimeSubscribeStatus.subscribed) {
             logInfo('Successfully subscribed to $channelName');
           } else if (status == RealtimeSubscribeStatus.closed) {
             // Subscription closed, schedule removal to avoid concurrent modification
             Future.microtask(() => _activeSubscriptions.remove(channelName));
             logDebug('Subscription closed for $channelName');
           } else if (error != null) {
             ErrorHandler.logError(error, null, 'RealtimeSubscription_$channelName');
             // Only attempt to resubscribe if user is still authenticated
             final currentUser = _supabase.auth.currentUser;
             if (currentUser != null && !_activeSubscriptions.containsKey(channelName)) {
               Future.delayed(const Duration(seconds: 5), () {
                 _setupSubscription(channelName, tableName, callback);
               });
             }
           }
         },
       );
     } catch (e) {
       ErrorHandler.logError(e, null, 'SetupRealtimeSubscription_$channelName');
     }
   }

  // Password reset methods
  Future<void> requestPasswordReset(String email) async {
    final emailError = validateEmail(email);
    if (emailError != null) throw ValidationError(emailError);

    return ErrorHandler.withRetry(
      () async {
        try {
          await _supabase.auth.resetPasswordForEmail(email);
        } on AuthException catch (e) {
          if (e.message.contains('rate limit') || e.message.contains('too many requests')) {
            throw RateLimitError('Too many password reset requests. Please wait before trying again.');
          } else if (e.message.contains('invalid email') || e.message.contains('not found')) {
            throw ValidationError('No account found with this email address.');
          } else {
            throw ValidationError('Failed to send password reset email: ${e.message}');
          }
        }
      },
      config: _defaultRetryConfig,
      context: 'ApiService.requestPasswordReset',
    );
  }

  Future<void> resetPassword(String newPassword) async {
    final passwordError = validatePassword(newPassword);
    if (passwordError != null) throw ValidationError(passwordError);

    return ErrorHandler.withRetry(
      () async {
        try {
          await _supabase.auth.updateUser(UserAttributes(password: newPassword));
        } on AuthException catch (e) {
          if (e.message.contains('session not found') || e.message.contains('invalid token')) {
            throw AuthError('Password reset session expired. Please request a new reset link.');
          } else {
            throw ValidationError('Failed to reset password: ${e.message}');
          }
        }
      },
      config: _defaultRetryConfig,
      context: 'ApiService.resetPassword',
    );
  }

  // Auth methods - Using Supabase Auth directly
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    String role = 'player',
    String? gender,
    int? age,
    String? phone,
  }) async {
    // Sanitize inputs
    final sanitizedName = InputSanitizer.sanitizeName(name);
    if (sanitizedName == null) throw ValidationError('Invalid name format');
    
    final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
    if (sanitizedEmail == null) throw ValidationError('Invalid email format');
    
    final sanitizedPhone = phone != null ? InputSanitizer.sanitizePhone(phone) : null;
    
    // Input validation
    final nameError = validateName(sanitizedName);
    if (nameError != null) throw ValidationError(nameError);

    final emailError = validateEmail(sanitizedEmail);
    if (emailError != null) throw ValidationError(emailError);

    final passwordError = validatePassword(password);
    if (passwordError != null) throw ValidationError(passwordError);

    if (age != null) {
      final ageError = validateAgeOptional(age.toString());
      if (ageError != null) throw ValidationError(ageError);
    }

    if (phone != null && phone.isNotEmpty) {
      final phoneError = validatePhoneOptional(phone);
      if (phoneError != null) throw ValidationError(phoneError);
    }

    return ErrorHandler.withRetry(
      () async {
        try {
          logDebug('Starting signup process for email: $email');

          // Use Robust Supabase Client for signup with retry logic
          final authResponse = await RobustSupabaseClient.signUp(
            email: sanitizedEmail,
            password: password,
            data: {
              'name': sanitizedName,
              'role': role,
              'gender': gender,
              'age': age,
              'phone': sanitizedPhone,
            },
          );

          logDebug('Auth signup completed. User created: ${authResponse.user != null}');

          if (authResponse.user != null) {
            // Profile creation is now handled by database trigger
            // No need for manual profile creation to avoid conflicts

            // Wait a moment for the trigger to complete
            await Future.delayed(const Duration(milliseconds: 500));

            // Try to get the created profile to confirm it exists
            try {
              await _supabase
                  .from('users')
                  .select('*')
                  .eq('id', authResponse.user!.id)
                  .single();

              logDebug('User profile confirmed in database');

              return {
                'user': {
                  ...authResponse.user!.toJson(),
                  'name': name, // Include the name from signup parameters
                },
                'session': authResponse.session?.toJson(),
                'message': 'Account created successfully. Please check your email to confirm your account.',
              };
            } catch (profileError) {
              // Profile might not be created yet due to trigger delay
              logWarning('Profile not found immediately after signup (trigger might be processing): $profileError');

              // Return success anyway since auth user was created
              return {
                'user': {
                  ...authResponse.user!.toJson(),
                  'name': name, // Include the name from signup parameters
                },
                'session': authResponse.session?.toJson(),
                'message': 'Account created successfully. Please check your email to confirm your account.',
              };
            }
          } else {
            throw ValidationError('Failed to create account. Please try again.');
          }
        } on AuthException catch (e) {
          logError('AuthException during signup: ${e.message}');

          // Enhanced error handling for different signup scenarios
          if (e.message.contains('already registered') ||
              e.message.contains('User already registered') ||
              e.message.contains('already in use')) {
            throw ValidationError('An account with this email already exists. Please try logging in instead.');
          } else if (e.message.contains('Password should be at least') ||
                     e.message.contains('password is too weak')) {
            throw ValidationError('Password is too weak. Please choose a stronger password with at least 6 characters.');
          } else if (e.message.contains('Invalid email') ||
                     e.message.contains('invalid email')) {
            throw ValidationError('Please enter a valid email address.');
          } else if (e.message.contains('signup is disabled') ||
                     e.message.contains('signup disabled')) {
            throw ServiceUnavailableError('Account creation is temporarily disabled. Please try again later.');
          } else if (e.message.contains('rate limit') ||
                     e.message.contains('too many requests') ||
                     e.message.contains('rate limited')) {
            throw RateLimitError('Too many signup attempts. Please wait a few minutes before trying again.');
          } else if (e.message.contains('email not confirmed') ||
                     e.message.contains('confirm your email')) {
            throw ValidationError('This email address needs to be confirmed first. Please check your email and confirm your account before signing up.');
          } else {
            logError('Unhandled AuthException: ${e.message}');
            throw ValidationError('Signup failed: ${e.message}');
          }
        } on PostgrestException catch (e) {
          logError('PostgrestException during signup: ${e.message}');

          // Handle database constraint violations
          if (e.message.contains('duplicate key') ||
              e.message.contains('unique constraint') ||
              e.message.contains('already exists')) {
            throw ValidationError('An account with this email already exists. Please try logging in instead.');
          } else if (e.message.contains('violates check constraint')) {
            throw ValidationError('Invalid data provided. Please check your information and try again.');
          } else {
            throw DatabaseError('Database error during signup: ${e.message}');
          }
        } catch (e) {
          logError('Unexpected error during signup: $e');
          if (e is ValidationError || e is DatabaseError || e is RateLimitError || e is ServiceUnavailableError) rethrow;
          throw GenericError('Signup failed: ${e.toString()}');
        }
      },
      config: _defaultRetryConfig,
      context: 'ApiService.signup',
    );
  }

  Future<Map<String, dynamic>> login({
     required String email,
     required String password,
   }) async {
     // Sanitize inputs
     final sanitizedEmail = InputSanitizer.sanitizeEmail(email);
     if (sanitizedEmail == null) throw ValidationError('Invalid email format');
     
     // Input validation
     final emailError = validateEmail(sanitizedEmail);
     if (emailError != null) throw ValidationError(emailError);

     final passwordError = validatePassword(password);
     if (passwordError != null) throw ValidationError(passwordError);

     return ErrorHandler.withRetry(
       () async {
         try {
           logDebug('Starting login process for email: $email');

           final authResponse = await RobustSupabaseClient.signInWithPassword(
             email: sanitizedEmail,
             password: password,
           );

           logDebug('Auth login completed. User authenticated: ${authResponse.user != null}');

           if (authResponse.user != null && authResponse.session != null) {
             // Try to get user profile from users table
             try {
               final userProfile = await _supabase
                   .from('users')
                   .select('*')
                   .eq('id', authResponse.user!.id)
                   .single();

               logDebug('User profile found in database');

               return {
                 'user': app_user.User.fromJson(userProfile).toJson(),
                 'session': authResponse.session!.toJson(),
                 'access_token': authResponse.session!.accessToken,
                 'message': 'Login successful',
               };
             } catch (profileError) {
               // If profile doesn't exist, create it from auth user data
               logWarning('User profile not found, creating from auth data: $profileError');

               final userData = authResponse.user!.userMetadata ?? {};
               final newProfile = {
                 'id': authResponse.user!.id,
                 'email': authResponse.user!.email!,
                 'name': userData['name'] ?? authResponse.user!.email!.split('@')[0],
                 'role': userData['role'] ?? 'player',
                 'gender': userData['gender'],
                 'age': userData['age'],
                 'phone': userData['phone'],
                 'created_at': authResponse.user!.createdAt,
                 'updated_at': DateTime.now().toIso8601String(),
               };

               try {
                 await _supabase.from('users').insert(newProfile);
                 logDebug('User profile created successfully during login');

                 return {
                   'user': app_user.User.fromJson(newProfile).toJson(),
                   'session': authResponse.session!.toJson(),
                   'access_token': authResponse.session!.accessToken,
                   'message': 'Login successful',
                 };
               } catch (insertError) {
                 // If insert fails due to RLS or other issues, return basic user data from auth
                 logWarning('Failed to create user profile during login: $insertError');

                 // Return basic user data from auth (profile creation might be handled by trigger)
                 return {
                   'user': {
                     'id': authResponse.user!.id,
                     'email': authResponse.user!.email!,
                     'name': userData['name'] ?? authResponse.user!.email!.split('@')[0],
                     'role': userData['role'] ?? 'player',
                   },
                   'session': authResponse.session!.toJson(),
                   'access_token': authResponse.session!.accessToken,
                   'message': 'Login successful',
                 };
               }
             }
           } else {
             throw AuthError('Invalid email or password');
           }
         } on AuthException catch (e) {
           logError('AuthException during login: ${e.message}');

           // Enhanced error handling for different login scenarios
           if (e.message.contains('Invalid login credentials') ||
               e.message.contains('invalid credentials')) {
             throw AuthError('Invalid email or password. Please check your credentials and try again.');
           } else if (e.message.contains('Email not confirmed') ||
                      e.message.contains('email not confirmed')) {
             throw ValidationError('Please confirm your email address before logging in. Check your email for a confirmation link.');
           } else if (e.message.contains('rate limit') ||
                      e.message.contains('too many requests') ||
                      e.message.contains('rate limited')) {
             throw RateLimitError('Too many login attempts. Please wait a few minutes before trying again.');
           } else if (e.message.contains('account locked') ||
                      e.message.contains('suspended') ||
                      e.message.contains('disabled')) {
             throw AuthError('Your account has been temporarily suspended. Please contact support for assistance.');
           } else if (e.message.contains('signup is disabled') ||
                      e.message.contains('signup disabled')) {
             throw ServiceUnavailableError('Account access is temporarily disabled. Please try again later.');
           } else {
             logError('Unhandled AuthException: ${e.message}');
             throw ValidationError('Login failed: ${e.message}');
           }
         } on PostgrestException catch (e) {
           logError('PostgrestException during login: ${e.message}');

           // Handle database issues during profile access
           if (e.message.contains('duplicate key') ||
               e.message.contains('unique constraint')) {
             throw ValidationError('Account conflict detected. Please try logging in again.');
           } else if (e.message.contains('violates check constraint')) {
             throw ValidationError('Account data is invalid. Please contact support.');
           } else {
             throw DatabaseError('Database error during login: ${e.message}');
           }
         } catch (e) {
           logError('Unexpected error during login: $e');
           if (e is AuthError || e is ValidationError || e is DatabaseError || e is RateLimitError || e is ServiceUnavailableError) rethrow;
           throw GenericError('Login failed: ${e.toString()}');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.login',
     );
   }

  // User methods
   Future<app_user.User> getCurrentUser() async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         final userProfile = await _supabase
             .from('users')
             .select('*')
             .eq('id', user.id)
             .single();

         return app_user.User.fromJson(userProfile);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.getCurrentUser',
     );
   }

  Future<String?> uploadAvatar(File imageFile) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Upload to Supabase Storage
         final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
         final fileBytes = await imageFile.readAsBytes();

         final response = await _supabase.storage
             .from('avatars')
             .uploadBinary(fileName, fileBytes);

         if (response.isNotEmpty) {
           // Get public URL
           final publicUrl = _supabase.storage
               .from('avatars')
               .getPublicUrl(fileName);

           // Update user profile with avatar URL
           await _supabase
               .from('users')
               .update({'avatar_url': publicUrl})
               .eq('id', user.id);

           return publicUrl;
         } else {
           throw UploadError('Failed to upload avatar');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.uploadAvatar',
     );
   }

  Future<String?> uploadAvatarBytes(
     Uint8List imageBytes,
     String filename,
   ) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Upload to Supabase Storage
         final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}_$filename';

         final response = await _supabase.storage
             .from('avatars')
             .uploadBinary(fileName, imageBytes);

         if (response.isNotEmpty) {
           // Get public URL
           final publicUrl = _supabase.storage
               .from('avatars')
               .getPublicUrl(fileName);

           // Update user profile with avatar URL
           await _supabase
               .from('users')
               .update({'avatar_url': publicUrl})
               .eq('id', user.id);

           return publicUrl;
         } else {
           throw UploadError('Failed to upload avatar');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.uploadAvatarBytes',
     );
   }

  Future<app_user.User> updateProfile({
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
     // Sanitize inputs
     final sanitizedName = name != null ? InputSanitizer.sanitizeName(name) : null;
     final sanitizedBio = bio != null ? InputSanitizer.sanitizeTextField(bio) : null;
     final sanitizedPhone = phone != null ? InputSanitizer.sanitizePhone(phone) : null;
     final sanitizedLocation = location != null ? InputSanitizer.sanitizeTextField(location, maxLength: 100) : null;
     
     logDebug('updateProfile called with: name=$sanitizedName, position=$position, bio=$sanitizedBio, gender=$gender, phone=$sanitizedPhone, age=$age, location=$sanitizedLocation, skillLevel=$skillLevel');

     // Input validation with enhanced error messages
     if (sanitizedName != null) {
       final nameError = validateName(sanitizedName);
       if (nameError != null) {
         logWarning('Validation failed for name: $nameError');
         throw ValidationError('Invalid name: $nameError');
       }
     }

     // Phone validation already done in the form, skip re-validation
     // if (phone != null && phone.isNotEmpty) {
     //   final phoneError = await PhoneService.validatePhoneNumber(phone, isRealTime: false);
     //   if (phoneError != null) {
     //     debugPrint('Validation failed for phone: $phoneError');
     //     throw ValidationError('Invalid phone number: $phoneError');
     //   }
     // }

     if (age != null) {
       final ageError = validateAgeOptional(age.toString());
       if (ageError != null) {
         logWarning('Validation failed for age: $ageError');
         throw ValidationError('Invalid age: $ageError');
       }
     }

     if (location != null && location.isNotEmpty) {
       final locationError = validateLocation(location);
       if (locationError != null) {
         logWarning('Validation failed for location: $locationError');
         throw ValidationError('Invalid location: $locationError');
       }
     }

     // Validate imageUrl if provided
     if (imageUrl != null && imageUrl.isNotEmpty) {
       // Basic URL validation (can be enhanced with a proper URL validator if available)
       if (!Uri.tryParse(imageUrl)!.hasScheme) {
         logWarning('Validation failed for imageUrl: Invalid URL format');
         throw ValidationError('Invalid image URL format');
       }
     }

     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           logError('No authenticated user found during profile update');
           throw AuthError('No authenticated user');
         }

         final Map<String, dynamic> updates = {};
         if (sanitizedName != null) updates['name'] = sanitizedName;
         if (position != null) updates['position'] = position;
         if (sanitizedBio != null) updates['bio'] = sanitizedBio;
         if (imageUrl != null) updates['image_url'] = imageUrl;
         if (gender != null) updates['gender'] = gender;
         if (sanitizedPhone != null) updates['phone'] = sanitizedPhone;
         if (age != null) updates['age'] = age;
         if (sanitizedLocation != null) updates['location'] = sanitizedLocation;
         if (skillLevel != null) updates['skill_level'] = skillLevel;

         logDebug('Updating user profile for user ${user.id}');

         try {
           final response = await _supabase
               .from('users')
               .update(updates)
               .eq('id', user.id)
               .select()
               .single();

           logDebug('Profile update successful for user ${user.id}');

           // Invalidate user stats cache since profile was updated
           await _cacheService.invalidateUserStatsCache();

           return app_user.User.fromJson(response);
         } catch (e) {
           logError('Database update failed for user ${user.id}: $e');
           logError('Update data: $updates');
           rethrow;
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.updateProfile',
     );
   }

  Future<app_user.User> getUserById(String userId) async {
     return ErrorHandler.withRetry(
       () async {
         try {
           final response = await _supabase
               .from('users')
               .select('*')
               .eq('id', userId)
               .single();
           return app_user.User.fromJson(response);
         } catch (e) {
           logError('Error fetching user $userId: $e');
           throw GenericError('Failed to load user data');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.getUserById',
     );
   }

  Future<List<app_user.User>> getAllUsers() async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('users')
            .select('*')
            .order('created_at');

        return ResponseParser.parseList(
          response,
          (json) => app_user.User.fromJson(json),
          context: 'ApiService.getAllUsers',
        );
      },
      <app_user.User>[],
      context: 'ApiService.getAllUsers',
    );
  }

  Future<void> deleteUser(String userId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase.from('users').delete().eq('id', userId);
    }, context: 'ApiService.deleteUser');
  }

  // Match methods
  Future<List<Match>> getMyMatches() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return <Match>[];

        final dynamic response = await _supabase
            .from('matches')
            .select('*')
            .or('created_by.eq.${user.id},team1_id.eq.${user.id},team2_id.eq.${user.id}')
            .order('match_date');

        if (response == null) return <Match>[];
        if (response is! List) return <Match>[];
        
        final List<Match> matches = [];
        for (final dynamic item in response) {
          if (item == null) continue;
          try {
            final Map<String, dynamic> matchData = item as Map<String, dynamic>;
            final teamId = matchData['team_id'] ?? matchData['team1_id'] ?? matchData['team_1_id'];
            if (teamId == null || teamId.toString().trim().isEmpty) {
              logDebug('Skipping match with missing team ID: ${matchData['id']}');
              continue;
            }
            final match = Match.fromJson(matchData);
            matches.add(match);
          } catch (e) {
            logError('Failed to parse match data in getMyMatches: $e');
            continue;
          }
        }
        return matches;
      },
      <Match>[],
      context: 'ApiService.getMyMatches',
    );
  }

  Future<List<Match>> getMatches({int? limit, int? offset}) async {
    return PerformanceMonitor().timeOperation(
      'ApiService.getMatches',
      () => ErrorHandler.withFallback(
        () async {
          try {
            logDebug('getMatches: Starting query...');
            var query = _supabase
                .from('matches')
                .select('*, team1:team1_id(name), team2:team2_id(name)')
                .order('match_date');

            if (limit != null) query = query.limit(limit);
            if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

            final dynamic response = await query;
            logDebug('getMatches: Response type: ${response.runtimeType}, length: ${response is List ? response.length : 'N/A'}');
            
            if (response == null) {
              logWarning('getMatches: Response is null');
              return <Match>[];
            }
            if (response is! List) {
              logWarning('getMatches: Response is not a List');
              return <Match>[];
            }
            
            final List<Match> matches = [];
            int skippedCount = 0;
            for (final dynamic item in response) {
              if (item == null) continue;
              try {
                final Map<String, dynamic> matchData = item as Map<String, dynamic>;
                final teamId = matchData['team_id'] ?? matchData['team1_id'] ?? matchData['team_1_id'];
                if (teamId == null || teamId.toString().trim().isEmpty) {
                  logDebug('Skipping match with missing team ID: ${matchData['id']}');
                  skippedCount++;
                  continue;
                }
                
                // Extract team names from joined data
                if (matchData['team1'] != null && matchData['team1'] is Map) {
                  matchData['team1_name'] = matchData['team1']['name'];
                }
                if (matchData['team2'] != null && matchData['team2'] is Map) {
                  matchData['team2_name'] = matchData['team2']['name'];
                }
                
                final match = Match.fromJson(matchData);
                matches.add(match);
              } catch (e) {
                logError('Failed to parse match data: $e');
                continue;
              }
            }
            logDebug('getMatches: Returning ${matches.length} matches (skipped: $skippedCount)');
            return matches;
          } catch (e) {
            logError('Error in getMatches: $e');
            return <Match>[];
          }
        },
        <Match>[],
        context: 'ApiService.getMatches',
      ),
      metadata: {'limit': limit, 'offset': offset},
    );
  }

  Future<List<Match>> getAllMatches({int? limit, int? offset}) async {
     return ErrorHandler.withFallback(
       () async {
         var query = _supabase
             .from('matches')
             .select('*, team1:team1_id(name), team2:team2_id(name)')
             .order('match_date');

         if (limit != null) query = query.limit(limit);
         if (offset != null) query = query.range(offset, offset + (limit ?? 20) - 1);

         final dynamic response = await query;
         if (response == null) return <Match>[];
         if (response is! List) return <Match>[];
         
         final List<Match> matches = [];
         for (final dynamic item in response) {
           if (item == null) continue;
           try {
             final Map<String, dynamic> matchData = item as Map<String, dynamic>;
             final teamId = matchData['team_id'] ?? matchData['team1_id'] ?? matchData['team_1_id'];
             if (teamId == null || teamId.toString().trim().isEmpty) {
               logDebug('Skipping match with missing team ID: ${matchData['id']}');
               continue;
             }
             
             // Extract team names from joined data
             if (matchData['team1'] != null && matchData['team1'] is Map) {
               matchData['team1_name'] = matchData['team1']['name'];
             }
             if (matchData['team2'] != null && matchData['team2'] is Map) {
               matchData['team2_name'] = matchData['team2']['name'];
             }
             
             final match = Match.fromJson(matchData);
             matches.add(match);
           } catch (e) {
             logError('Failed to parse match data in getAllMatches: $e');
             continue;
           }
         }
         return matches;
       },
       <Match>[],
       context: 'ApiService.getAllMatches',
     );
   }

  Future<Match> getMatch(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final response = await _supabase
            .from('matches')
            .select('*')
            .eq('id', matchId)
            .single();

        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.getMatch',
    );
  }

  Future<Match> createMatch({
    required String team1Id,
    required String team2Id,
    required DateTime matchDate,
    required String location,
    String? title,
    int? maxPlayers,
    String? matchType,
    int? durationMinutes,
    bool? isRecurring,
    String? recurrencePattern,
  }) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          throw AuthError('No authenticated user');
        }

        // Authorization check
        await _authService.validateOperation(
          userId: user.id,
          operation: 'create_match',
        );

        // Input validation
        final dateError = validateMatchDateTime(matchDate);
        if (dateError != null) throw ValidationError(dateError);

        final locationError = validateLocation(location);
        if (locationError != null) throw ValidationError(locationError);

        if (title != null && title.isNotEmpty) {
          final titleError = validateMatchTitle(title);
          if (titleError != null) throw ValidationError(titleError);
          
          // Check if title already exists
          final existing = await _supabase
              .from('matches')
              .select('id')
              .eq('title', title)
              .maybeSingle();
          
          if (existing != null) {
            throw ValidationError('A match with this title already exists. Please choose a different title.');
          }
        }

        if (maxPlayers != null) {
          final playersError = validateMaxPlayers(maxPlayers);
          if (playersError != null) throw ValidationError(playersError);
        }

        final Map<String, dynamic> matchData = {
          'match_date': matchDate.toIso8601String(),
          'location': location,
          'team1_id': team1Id,
          'team2_id': team2Id,
        };

        if (title != null && title.isNotEmpty) {
          matchData['title'] = title;
        }

        if (maxPlayers != null) {
          matchData['max_players'] = maxPlayers;
        }

        if (matchType != null && matchType.isNotEmpty) {
          matchData['match_type'] = matchType;
        }

        if (durationMinutes != null) {
          matchData['duration_minutes'] = durationMinutes;
        }

        matchData['is_recurring'] = isRecurring ?? false;
        if (recurrencePattern != null) {
          matchData['recurrence_pattern'] = recurrencePattern;
        }

        final response = await _supabase
            .from('matches')
            .insert(matchData)
            .select()
            .single();

        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.createMatch',
    );
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    final validStatuses = ['open', 'closed', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.contains(status)) {
      throw ValidationError('Invalid status. Must be one of: ${validStatuses.join(', ')}');
    }

    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase
            .from('matches')
            .update({'status': status})
            .eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.updateMatchStatus',
    );
  }

  Future<void> rescheduleMatch(String matchId, DateTime newDate) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase
            .from('matches')
            .update({
              'match_date': newDate.toIso8601String(),
              'status': 'open'
            })
            .eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.rescheduleMatch',
    );
  }

  Future<void> recordMatchResult(String matchId, {
    int? team1Score,
    int? team2Score,
    String? notes,
  }) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        final updates = {
          'status': 'completed',
          'completed_at': DateTime.now().toIso8601String(),
        };
        
        if (team1Score != null) updates['team1_score'] = team1Score.toString();
        if (team2Score != null) updates['team2_score'] = team2Score.toString();
        if (notes != null) updates['result_notes'] = notes;

        await _supabase
            .from('matches')
            .update(updates)
            .eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.recordMatchResult',
    );
  }

  Future<void> closeMatch(String matchId) async {
    return updateMatchStatus(matchId, 'closed');
  }

  // Team methods
  Future<List<Team>> getUserTeams() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return <Team>[];

        // Get teams where user is owner (exclude soft-deleted)
        final dynamic ownedResponse = await _supabase
            .from('teams')
            .select('*')
            .eq('owner_id', user.id)
            .filter('deleted_at', 'is', null)
            .order('created_at');

        // Get teams where user is a member (exclude soft-deleted)
        final dynamic memberResponse = await _supabase
            .from('team_members')
            .select('teams!inner(*)')
            .eq('user_id', user.id)
            .filter('teams.deleted_at', 'is', null);

        final List<Team> teams = [];

        if (ownedResponse != null && ownedResponse is List) {
          teams.addAll(ownedResponse.map((dynamic json) => Team.fromJson(json as Map<String, dynamic>)).toList());
        }

        if (memberResponse != null && memberResponse is List) {
          for (final item in memberResponse) {
            if (item['teams'] != null) {
              final team = Team.fromJson(item['teams'] as Map<String, dynamic>);
              if (!teams.any((t) => t.id == team.id)) {
                teams.add(team);
              }
            }
          }
        }

        teams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return teams;
      },
      <Team>[], // Return empty list as fallback
      context: 'ApiService.getUserTeams',
    );
  }

  Future<List<Team>> getMyTeams() async {
     return ErrorHandler.withFallback(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) return <Team>[];

         final dynamic response = await _supabase
             .from('teams')
             .select('*')
             .eq('owner_id', user.id)
             .filter('deleted_at', 'is', null)
             .order('created_at', ascending: false);

         if (response == null) return <Team>[];
         if (response is! List) return <Team>[];
         return response.map((dynamic json) => Team.fromJson(json as Map<String, dynamic>)).toList();
       },
       <Team>[], // Return empty list as fallback
       context: 'ApiService.getMyTeams',
     );
   }

  Future<Team> createTeam(
     String name, {
     String? location,
     int? numberOfPlayers,
     String? description,
     String? logo,
     bool? isRecruiting,
     String? gender,
     int? minAge,
     int? maxAge,
   }) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           logError('No authenticated user found');
           throw AuthError('No authenticated user');
         }

         // Sanitize inputs
         final sanitizedName = InputSanitizer.sanitizeName(name);
         if (sanitizedName == null) throw ValidationError('Invalid team name format');
         
         final sanitizedLocation = location != null ? InputSanitizer.sanitizeTextField(location, maxLength: 100) : null;
         final sanitizedDescription = description != null ? InputSanitizer.sanitizeTextField(description) : null;

         // Check if team name already exists
         final existing = await _supabase
             .from('teams')
             .select('id')
             .eq('name', sanitizedName)
             .maybeSingle();
         
         if (existing != null) {
           throw ValidationError('A team with this name already exists. Please choose a different name.');
         }

         // Proactive session refresh for web platform
         if (kIsWeb) {
           try {
             await _supabase.auth.refreshSession();
             logDebug('Web session refreshed proactively');
           } catch (refreshError) {
             logWarning('Proactive session refresh failed: $refreshError');
           }
         }

         logDebug('Creating team for user: ${user.id}');
         logDebug('Platform: ${kIsWeb ? "Web" : "Mobile"}');

         final teamData = {
           'name': sanitizedName,
           'owner_id': user.id,
           'location': sanitizedLocation,
           'description': sanitizedDescription,
           'max_players': numberOfPlayers ?? 11,
           'is_recruiting': isRecruiting ?? false,
           'gender': gender ?? 'mixed',
           'min_age': minAge,
           'max_age': maxAge,
         };

         logDebug('Team data prepared for creation');

         try {
           final response = await _supabase
               .from('teams')
               .insert(teamData)
               .select()
               .single();

           logDebug('Team created successfully');
           final team = Team.fromJson(response);

           // Owner is automatically added by database trigger
           // Wait briefly for trigger to complete
           await Future.delayed(const Duration(milliseconds: 300));
           logDebug('Team owner added by trigger');
           await _cacheService.invalidateTeamsCache();
           return team;
         } catch (e) {
           logError('Team creation failed: $e');
           if (kIsWeb && e.toString().contains('JWT')) {
             logWarning('Web JWT issue detected, attempting refresh and retry');
             try {
               await _supabase.auth.refreshSession();
               // Retry the operation once after refresh
               final retryResponse = await _supabase
                   .from('teams')
                   .insert(teamData)
                   .select()
                   .single();
               
               final team = Team.fromJson(retryResponse);
               
               // Owner is automatically added by database trigger
               logDebug('Team owner will be added automatically by trigger (retry)');
               await _cacheService.invalidateTeamsCache();
               return team;
             } catch (refreshError) {
               throw AuthError('Session expired. Please refresh the page and try again.');
             }
           }
           rethrow;
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.createTeam',
     );
   }

  // Participant methods
  Future<void> joinMatch(String matchId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('match_participants')
             .insert({
               'match_id': matchId,
               'user_id': user.id,
               'joined_at': DateTime.now().toIso8601String(),
             });

         try {
           final match = await getMatch(matchId);
           final currentUser = await getCurrentUser();
           if (match.createdBy != null && match.createdBy != user.id) {
             await createNotification(
               userId: match.createdBy!,
               title: 'New Player Joined',
               message: '${currentUser.name} joined your match',
               type: 'match_joined',
               relatedId: matchId,
             );
           }
         } catch (e) {
           logWarning('Failed to create notification: $e');
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.joinMatch',
     );
   }

  Future<void> leaveMatch(String matchId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('match_participants')
             .delete()
             .eq('match_id', matchId)
             .eq('user_id', user.id);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.leaveMatch',
     );
   }

  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    return ErrorHandler.withFallback(
      () async {
        final dynamic response = await _supabase
            .from('match_participants')
            .select('users(*)')
            .eq('match_id', matchId);

        if (response == null) return <app_user.User>[];
        if (response is! List) return <app_user.User>[];
        return response.map((dynamic json) {
          final dynamic userData = json['users'];
          if (userData == null || userData is! Map<String, dynamic>) return null;
          try {
            return app_user.User.fromJson(userData);
          } catch (e) {
            return null;
          }
        }).where((user) => user != null).cast<app_user.User>().toList();
      },
      <app_user.User>[], // Return empty list as fallback
      context: 'ApiService.getMatchPlayers',
    );
  }

  // Notification methods
  Future<List<NotificationModel>> getNotifications() async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('notifications')
            .select('*')
            .order('created_at', ascending: false);

        return ResponseParser.parseList(
          response,
          (json) => NotificationModel.fromJson(json),
          context: 'ApiService.getNotifications',
        );
      },
      <NotificationModel>[],
      context: 'ApiService.getNotifications',
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    }, context: 'ApiService.markNotificationAsRead');
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
    Map<String, dynamic>? metadata,
  }) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'metadata': metadata,
      });
    }, context: 'ApiService.createNotification');
  }

  // Team browsing methods
  Future<List<Team>> getAllTeams({int? limit, int? offset}) async {
    // Skip cache for paginated requests
    if (limit != null || offset != null) {
      return _fetchTeamsFromNetwork(limit: limit, offset: offset);
    }

    // Try to get from cache first
    final cachedTeams = _cacheService.getCachedTeams();
    if (cachedTeams != null && cachedTeams.isNotEmpty) {
      // Background refresh for teams data
      _cacheService.refreshCriticalData(() async {
        final freshTeams = await _fetchTeamsFromNetwork();
        await _cacheService.cacheTeams(freshTeams);
      });
      return cachedTeams;
    }

    // Fetch from network if not cached
    final teams = await _fetchTeamsFromNetwork();
    await _cacheService.cacheTeams(teams);
    return teams;
  }

  Future<List<Team>> _fetchTeamsFromNetwork({int? limit, int? offset}) async {
     return PerformanceMonitor().timeOperation(
       'ApiService._fetchTeamsFromNetwork',
       () => ErrorHandler.withFallback(
         () async {
           logDebug('_fetchTeamsFromNetwork: Starting query...');
           
           // Get current user for filtering
           final user = _supabase.auth.currentUser;
           String? userGender;
           int? userAge;
           
           if (user != null) {
             try {
               final userProfile = await _supabase
                   .from('users')
                   .select('*')
                   .eq('id', user.id)
                   .single();
               userGender = userProfile['gender'] as String?;
               userAge = userProfile['age'] as int?;
             } catch (e) {
               logWarning('Could not fetch user profile for filtering: $e');
               userGender = null;
               userAge = null;
             }
           }
           
           // Build query with gender filter and exclude soft-deleted teams
           var baseQuery = _supabase.from('teams').select('*').filter('deleted_at', 'is', null);
           
           final filteredQuery = (userGender != null && userGender != 'other')
               ? baseQuery.or('gender.eq.mixed,gender.eq.$userGender')
               : baseQuery;
           
           var orderedQuery = filteredQuery.order('created_at', ascending: false);
           
           if (limit != null) {
             orderedQuery = orderedQuery.limit(limit);
           }
           if (offset != null) {
             orderedQuery = orderedQuery.range(offset, offset + (limit ?? 20) - 1);
           }

           final dynamic response = await orderedQuery;
           logDebug('_fetchTeamsFromNetwork: Response type: ${response.runtimeType}, length: ${response is List ? response.length : 'N/A'}');
           
           if (response == null) {
             logWarning('_fetchTeamsFromNetwork: Response is null');
             return <Team>[];
           }
           if (response is! List) {
             logWarning('_fetchTeamsFromNetwork: Response is not a List');
             return <Team>[];
           }
           
           final teams = response.map((dynamic json) => Team.fromJson(json as Map<String, dynamic>)).toList();
           logDebug('_fetchTeamsFromNetwork: Returning ${teams.length} teams');
           return teams;
         },
         <Team>[],
         context: 'ApiService.getAllTeams',
       ),
       metadata: {'limit': limit, 'offset': offset},
     );
   }

  Future<List<City>> getCities() async {
    // Try to get from cache first
    final cachedCities = _cacheService.getCachedCities();
    if (cachedCities != null && cachedCities.isNotEmpty) {
      // Background refresh for critical data
      _cacheService.refreshCriticalData(() async {
        final freshCities = await _fetchCitiesFromNetwork();
        await _cacheService.cacheCities(freshCities);
      });
      return cachedCities;
    }

    // Fetch from network if not cached
    final cities = await _fetchCitiesFromNetwork();
    await _cacheService.cacheCities(cities);
    return cities;
  }

  Future<List<City>> _fetchCitiesFromNetwork() async {
     return ErrorHandler.withFallback(
       () async {
         final dynamic response = await _supabase
             .from('cities')
             .select('*')
             .order('name');

         // Add null checks and validation for API response
         if (response == null) {
           throw ValidationError('No city data received from server');
         }

         if (response is! List) {
           throw ValidationError('Invalid city response format from server');
         }

         final List<City> cities = <City>[];
         for (final dynamic item in response) {
           if (item == null) continue; // Skip null items

           try {
             final city = City.fromJson(item as Map<String, dynamic>);
             // Additional validation for city data
             if (city.id.trim().isEmpty || city.name.trim().isEmpty) {
               logDebug('Skipping invalid city data: ${city.id}');
               continue;
             }
             cities.add(city);
           } catch (e) {
             logError('Failed to parse city data: $e');
             continue; // Skip invalid items instead of failing completely
           }
         }

         return cities;
       },
       <City>[], // Return empty list as fallback
       context: 'ApiService._fetchCitiesFromNetwork',
       shouldUseFallback: (dynamic error) => error is NetworkError || error is DatabaseError, // Use fallback for network or database issues
     );
   }

  Future<Team> getTeam(String teamId) async {
    return ErrorHandler.withRetry(
      () async {
        final response = await _supabase
            .from('teams')
            .select('*')
            .eq('id', teamId)
            .single();

        return Team.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.getTeam',
    );
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    return ErrorHandler.withFallback(
      () async {
        logDebug('Fetching team members for teamId: $teamId');
        
        try {
          final dynamic response = await _supabase
              .from('team_members')
              .select('*, users(*)')
              .eq('team_id', teamId);

          if (response == null || response is! List) {
            logWarning('Team members response is null or not a List');
            return <app_user.User>[];
          }
          logDebug('Found ${response.length} team member records');
          
          final members = response.map((dynamic json) {
            final dynamic userData = json['users'];
            if (userData == null || userData is! Map<String, dynamic>) {
              return null;
            }
            try {
              return app_user.User.fromJson(userData);
            } catch (e) {
              logError('Error parsing user data: $e');
              return null;
            }
          }).where((user) => user != null).cast<app_user.User>().toList();
          
          logDebug('Returning ${members.length} parsed members');
          return members;
        } catch (e) {
          logError('Error fetching team members: $e');
          return <app_user.User>[];
        }
      },
      <app_user.User>[],
      context: 'ApiService.getTeamMembers',
    );
  }

  Future<Map<String, int>> getTeamMemberCounts(List<String> teamIds) async {
    return ErrorHandler.withFallback(
      () async {
        final Map<String, int> counts = {};
        for (final teamId in teamIds) {
          final members = await getTeamMembers(teamId);
          counts[teamId] = members.length;
        }
        return counts;
      },
      <String, int>{},
      context: 'ApiService.getTeamMemberCounts',
    );
  }

  Future<bool> isTeamAvailableAtTime(String teamId, DateTime matchTime) async {
    return ErrorHandler.withFallback(
      () async {
        final startTime = matchTime.subtract(const Duration(hours: 2));
        final endTime = matchTime.add(const Duration(hours: 2));

        final response = await _supabase
            .from('matches')
            .select('id')
            .or('team1_id.eq.$teamId,team2_id.eq.$teamId')
            .gte('match_date', startTime.toIso8601String())
            .lte('match_date', endTime.toIso8601String());

        return (response.isEmpty);
      },
      true,
      context: 'ApiService.isTeamAvailableAtTime',
    );
  }

  // Team Join Request methods
  Future<team_models.TeamJoinRequest> createJoinRequest(
     String teamId, {
     String? message,
   }) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _authService.validateOperation(
           userId: user.id,
           operation: 'join_team',
         );

         final response = await _supabase
             .from('team_join_requests')
             .insert({
               'team_id': teamId,
               'user_id': user.id,
               'message': message,
               'status': 'pending',
             })
             .select()
             .single();

         try {
           final team = await getTeam(teamId);
           final currentUser = await getCurrentUser();
           await createNotification(
             userId: team.ownerId,
             title: 'New Join Request',
             message: '${currentUser.name} wants to join ${team.name}',
             type: 'team_join_request',
             relatedId: teamId,
             metadata: {'request_id': response['id']},
           );
         } catch (e) {
           logWarning('Failed to create notification: $e');
         }

         return team_models.TeamJoinRequest.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.createJoinRequest',
     );
   }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(
     String teamId,
   ) async {
     return ErrorHandler.withFallback(
       () async {
         final dynamic response = await _supabase
             .from('team_join_requests')
             .select('*, users(*)')
             .eq('team_id', teamId)
             .eq('status', 'pending')
             .order('created_at');

         if (response == null) return <team_models.TeamJoinRequest>[];
         if (response is! List) return <team_models.TeamJoinRequest>[];
         return response.map((dynamic json) => team_models.TeamJoinRequest.fromJson(json as Map<String, dynamic>)).toList();
       },
       <team_models.TeamJoinRequest>[], // Return empty list as fallback
       context: 'ApiService.getTeamJoinRequests',
     );
   }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(
     String teamId,
     String requestId,
     String status,
   ) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         logDebug('updateJoinRequestStatus: teamId=$teamId, requestId=$requestId, status=$status');

         await _authService.validateOperation(
           userId: user.id,
           operation: 'manage_join_requests',
           resourceId: teamId,
         );

         final response = await _supabase
             .from('team_join_requests')
             .update({'status': status})
             .eq('id', requestId)
             .eq('team_id', teamId)
             .select('*, users(*), teams(*)')
             .single();

         logDebug('Join request updated');

         try {
           final request = team_models.TeamJoinRequest.fromJson(response);
           logDebug('Parsed request: userId=${request.userId}, status=${request.status}');
           
           if (status == 'approved') {
             try {
               logDebug('Adding team member using safe function: teamId=$teamId, userId=${request.userId}');
               final insertResult = await _supabase.rpc('add_team_member_safe', params: {
                 'p_team_id': teamId,
                 'p_user_id': request.userId,
                 'p_role': 'member',
               });
               logDebug('Team member added successfully');
               
               // Invalidate caches to refresh team data
               await _cacheService.invalidateTeamsCache();
               await _cacheService.invalidateUserStatsCache();
               logDebug('Caches invalidated');
             } catch (e) {
               logError('Error adding team member: $e');
               if (e.toString().contains('duplicate') || 
                   e.toString().contains('already exists') ||
                   e.toString().contains('Member already exists')) {
                 logWarning('Member already exists in team, continuing...');
               } else {
                 rethrow;
               }
             }
             await createNotification(
               userId: request.userId,
               title: 'Join Request Approved',
               message: 'Your request to join ${request.team?.name ?? "the team"} was approved',
               type: 'team_invite',
               relatedId: teamId,
             );
             logDebug('Notification sent to user ${request.userId}');
           } else if (status == 'rejected') {
             await createNotification(
               userId: request.userId,
               title: 'Join Request Rejected',
               message: 'Your request to join ${request.team?.name ?? "the team"} was rejected',
               type: 'general',
               relatedId: teamId,
             );
           }
         } catch (e) {
           logError('Failed to process approval/notification: $e');
         }

         return team_models.TeamJoinRequest.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.updateJoinRequestStatus',
     );
   }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
     return ErrorHandler.withFallback(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) return <team_models.TeamJoinRequest>[];

         final dynamic response = await _supabase
             .from('team_join_requests')
             .select('*, teams(*)')
             .eq('user_id', user.id)
             .order('created_at', ascending: false);

         if (response == null) return <team_models.TeamJoinRequest>[];
         if (response is! List) return <team_models.TeamJoinRequest>[];
         return response.map((dynamic json) => team_models.TeamJoinRequest.fromJson(json as Map<String, dynamic>)).toList();
       },
       <team_models.TeamJoinRequest>[], // Return empty list as fallback
       context: 'ApiService.getMyJoinRequests',
     );
   }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         await _supabase
             .from('team_join_requests')
             .delete()
             .eq('id', requestId)
             .eq('user_id', user.id)
             .eq('team_id', teamId);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.cancelJoinRequest',
     );
   }

  Future<List<Team>> searchTeams(String query) async {
    return ErrorHandler.withFallback(
      () async {
        final response = await _supabase
            .from('teams')
            .select('*')
            .or('name.ilike.%$query%,location.ilike.%$query%')
            .order('created_at', ascending: false);

        return ResponseParser.parseList(
          response,
          (json) => Team.fromJson(json),
          context: 'ApiService.searchTeams',
        );
      },
      <Team>[],
      context: 'ApiService.searchTeams',
    );
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Authorization check
         await _authService.validateOperation(
           userId: user.id,
           operation: 'manage_team',
           resourceId: teamId,
         );

         // First get current recruiting status
         final team = await _supabase
             .from('teams')
             .select('is_recruiting')
             .eq('id', teamId)
             .eq('owner_id', user.id)
             .single();

         // Toggle the status
         await _supabase
             .from('teams')
             .update({'is_recruiting': !(team['is_recruiting'] ?? false)})
             .eq('id', teamId)
             .eq('owner_id', user.id);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.toggleTeamRecruiting',
     );
   }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
     await ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Authorization check
         await _authService.validateOperation(
           userId: user.id,
           operation: 'delete_team',
           resourceId: teamId,
         );

         await _supabase
             .from('teams')
             .delete()
             .eq('id', teamId)
             .eq('owner_id', user.id);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.deleteTeam',
     );

     // Invalidate teams cache since we deleted a team
     await _cacheService.invalidateTeamsCache();
   }

  // User statistics methods
  Future<void> clearUserStatsCache() async {
    await _cacheService.invalidateUserStatsCache();
  }

  Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
    // Force refresh bypasses cache
    if (forceRefresh) {
      final stats = await _fetchUserStatsFromNetwork();
      await _cacheService.cacheUserStats(stats);
      return stats;
    }

    // Try to get from cache first
    final cachedStats = _cacheService.getCachedUserStats();
    if (cachedStats != null) {
      // Background refresh for user stats
      _cacheService.refreshCriticalData(() async {
        final freshStats = await _fetchUserStatsFromNetwork();
        await _cacheService.cacheUserStats(freshStats);
      });
      return cachedStats;
    }

    // Fetch from network if not cached
    final stats = await _fetchUserStatsFromNetwork();
    await _cacheService.cacheUserStats(stats);
    return stats;
  }

  Future<Map<String, dynamic>> _fetchUserStatsFromNetwork() async {
     return ErrorHandler.withFallback(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Get matches joined count
         final dynamic matchesJoined = await _supabase
             .from('match_participants')
             .select('id')
             .eq('user_id', user.id);

         // Get matches created count (as team owner)
         final dynamic matchesCreated = await _supabase
             .from('matches')
             .select('id')
             .or('team1_id.eq.${user.id},team2_id.eq.${user.id}');

         // Get teams owned count (exclude soft-deleted)
         final dynamic teamsOwned = await _supabase
             .from('teams')
             .select('id')
             .eq('owner_id', user.id)
             .filter('deleted_at', 'is', null);

         return <String, dynamic>{
           'matches_joined': (matchesJoined as List).length,
           'matches_created': (matchesCreated as List).length,
           'teams_owned': (teamsOwned as List).length,
         };
       },
       <String, dynamic>{
         'matches_joined': 0,
         'matches_created': 0,
         'teams_owned': 0,
       }, // Safe defaults
       context: 'ApiService.getUserStats',
     );
   }

  Future<app_user.User> getUser(String userId) async {
     return ErrorHandler.withRetry(
       () async {
         final response = await _supabase
             .from('users')
             .select('*')
             .eq('id', userId)
             .single();

         return app_user.User.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.getUser',
     );
   }

  Future<Team> updateTeam(String teamId, {String? logo}) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         // Authorization check
         await _authService.validateOperation(
           userId: user.id,
           operation: 'manage_team',
           resourceId: teamId,
         );

         final Map<String, dynamic> updates = {};
         if (logo != null) updates['logo_url'] = logo;

         final response = await _supabase
             .from('teams')
             .update(updates)
             .eq('id', teamId)
             .eq('owner_id', user.id) // Ensure only owner can update
             .select()
             .single();

         return Team.fromJson(response);
       },
       config: _defaultRetryConfig,
       context: 'ApiService.updateTeam',
     );
   }

  Future<void> leaveTeam(String teamId) async {
     return ErrorHandler.withRetry(
       () async {
         final user = _supabase.auth.currentUser;
         if (user == null) {
           throw AuthError('No authenticated user');
         }

         try {
           final team = await getTeam(teamId);
           final currentUser = await getCurrentUser();
           
           await _supabase
               .from('team_members')
               .delete()
               .eq('team_id', teamId)
               .eq('user_id', user.id);
           
           await createNotification(
             userId: team.ownerId,
             title: 'Player Left Team',
             message: '${currentUser.name} left ${team.name}',
             type: 'team_member_left',
             relatedId: teamId,
           );
         } catch (e) {
           logError('Error in leaveTeam: $e');
           rethrow;
         }
       },
       config: _defaultRetryConfig,
       context: 'ApiService.leaveTeam',
     );
   }

  Future<void> clearAllNotifications() async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          throw AuthError('No authenticated user');
        }

        await _supabase
            .from('notifications')
            .delete()
            .eq('user_id', user.id);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.clearAllNotifications',
    );
  }

  Future<void> removeTeamMember(String teamId, String userId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          throw AuthError('No authenticated user');
        }

        await _authService.validateOperation(
          userId: user.id,
          operation: 'manage_team',
          resourceId: teamId,
        );

        final team = await getTeam(teamId);
        
        await _supabase
            .from('team_members')
            .delete()
            .eq('team_id', teamId)
            .eq('user_id', userId);
        
        try {
          await createNotification(
            userId: userId,
            title: 'Removed from Team',
            message: 'You have been removed from ${team.name}',
            type: 'general',
            relatedId: teamId,
          );
        } catch (e) {
          logWarning('Failed to create notification (non-critical): $e');
        }
      },
      config: _defaultRetryConfig,
      context: 'ApiService.removeTeamMember',
    );
  }

  // Match request methods
  /// Get pending match requests for teams owned by current user
  Future<List<Match>> getMyPendingMatchRequests() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return <Match>[];

        // Get user's team IDs
        final teamsResponse = await _supabase
            .from('teams')
            .select('id')
            .eq('owner_id', user.id);
        
        final teamIds = (teamsResponse as List).map((t) => t['id'] as String).toList();
        if (teamIds.isEmpty) return <Match>[];

        // Get pending matches where user's team is team2
        final dynamic response = await _supabase
            .from('matches')
            .select('*, team1:team1_id(name, logo_url), team2:team2_id(name, logo_url)')
            .eq('status', 'pending')
            .inFilter('team2_id', teamIds)
            .order('match_date');

        if (response == null || response is! List) return <Match>[];
        
        return response.map((json) => Match.fromJson(json as Map<String, dynamic>)).toList();
      },
      <Match>[],
      context: 'ApiService.getMyPendingMatchRequests',
    );
  }

  /// Accept a match request (Team2 owner)
  Future<Match> acceptMatchRequest(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        logDebug('Accepting match request: $matchId');

        // Update match status - trigger handles notifications
        final response = await _supabase
            .from('matches')
            .update({
              'status': 'confirmed',
              'team2_confirmed': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', matchId)
            .select('*, team1:team1_id(name), team2:team2_id(name)')
            .single();

        logDebug('Match status updated to confirmed');

        // Add all team members from both teams to match_participants
        // This is optional - if the function doesn't exist, players can join manually
        try {
          logDebug('Adding team members to match participants');
          await _supabase.rpc('add_team_members_to_match', params: {
            'p_match_id': matchId,
          });
          logDebug('Team members added to match participants');
        } catch (e) {
          logWarning('Could not auto-add team members (function may not exist): $e');
          // This is non-critical - the match is confirmed
          // Players can join manually if the function doesn't exist
        }

        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.acceptMatchRequest',
    );
  }

  /// Reject a match request (Team2 owner)
  Future<void> rejectMatchRequest(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        // Update match status to cancelled - trigger handles notifications
        await _supabase
            .from('matches')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'ApiService.rejectMatchRequest',
    );
  }

  Future<List<Match>> getPendingMatchRequests() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return <Match>[];

        // Get user's team IDs first
        final teamsResponse = await _supabase
            .from('teams')
            .select('id')
            .eq('owner_id', user.id);
        
        final teamIds = (teamsResponse as List).map((t) => t['id']).toList();
        if (teamIds.isEmpty) return <Match>[];

        final dynamic response = await _supabase
            .from('matches')
            .select('*, team1:team1_id(name), team2:team2_id(name)')
            .eq('status', 'pending')
            .inFilter('team2_id', teamIds)
            .order('match_date');

        if (response == null) return <Match>[];
        if (response is! List) return <Match>[];
        
        final List<Match> matches = [];
        for (final dynamic item in response) {
          if (item == null) continue;
          try {
            final Map<String, dynamic> matchData = item as Map<String, dynamic>;
            if (matchData['team1'] != null && matchData['team1'] is Map) {
              matchData['team1_name'] = matchData['team1']['name'];
            }
            if (matchData['team2'] != null && matchData['team2'] is Map) {
              matchData['team2_name'] = matchData['team2']['name'];
            }
            matches.add(Match.fromJson(matchData));
          } catch (e) {
            logError('Failed to parse match request: $e');
            continue;
          }
        }
        return matches;
      },
      <Match>[],
      context: 'ApiService.getPendingMatchRequests',
    );
  }
}
