import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/notification.dart';
import '../services/error_handler.dart';
import '../services/cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/validators.dart';
import '../utils/input_sanitizer.dart';
import '../utils/response_parser.dart';

class UserRepository {
  final SupabaseClient _supabase;
  final CacheService _cacheService = CacheService();

  // Retry config moved or injected. Using default for now.
  final RetryConfig _defaultRetryConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: const Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: const Duration(seconds: 10),
    shouldRetry: (error) => error is NetworkError || error is TimeoutError,
  );

  UserRepository(this._supabase);

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
        .map((data) =>
            data.map((json) => NotificationModel.fromJson(json)).toList());
  }

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
      context: 'UserRepository.getCurrentUser',
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
      context: 'UserRepository.getUserById',
    );
  }

  // Alias for compatibility if needed, else redundant
  Future<app_user.User> getUser(String userId) => getUserById(userId);

  Future<List<app_user.User>> getAllUsers() async {
    return ErrorHandler.withFallback(
      () async {
        final response =
            await _supabase.from('users').select('*').order('created_at');

        return ResponseParser.parseList(
          response,
          (json) => app_user.User.fromJson(json),
          context: 'UserRepository.getAllUsers',
        );
      },
      <app_user.User>[],
      context: 'UserRepository.getAllUsers',
    );
  }

  Future<void> deleteUser(String userId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase.from('users').delete().eq('id', userId);
    }, context: 'UserRepository.deleteUser');
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
    final sanitizedName =
        name != null ? InputSanitizer.sanitizeName(name) : null;
    final sanitizedBio =
        bio != null ? InputSanitizer.sanitizeTextField(bio) : null;
    final sanitizedPhone =
        phone != null ? InputSanitizer.sanitizePhone(phone) : null;
    final sanitizedLocation = location != null
        ? InputSanitizer.sanitizeTextField(location, maxLength: 100)
        : null;

    // Input validation
    if (sanitizedName != null) {
      final nameError = validateName(sanitizedName);
      if (nameError != null) throw ValidationError('Invalid name: $nameError');
    }

    if (age != null) {
      final ageError = validateAgeOptional(age.toString());
      if (ageError != null) throw ValidationError('Invalid age: $ageError');
    }

    if (sanitizedLocation != null) {
      final locationError = validateLocation(sanitizedLocation);
      if (locationError != null) {
        throw ValidationError('Invalid location: $locationError');
      }
    }

    // imageUrl validation is basic
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (!Uri.tryParse(imageUrl)!.hasScheme) {
        throw ValidationError('Invalid image URL format');
      }
    }

    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) {
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

        updates['updated_at'] = DateTime.now().toIso8601String();

        try {
          final response = await _supabase
              .from('users')
              .update(updates)
              .eq('id', user.id)
              .select()
              .single();

          // Invalidate user stats cache
          await _cacheService.invalidateUserStatsCache();

          return app_user.User.fromJson(response);
        } catch (e) {
          logError('Database update failed for user ${user.id}: $e');
          rethrow;
        }
      },
      config: _defaultRetryConfig,
      context: 'UserRepository.updateProfile',
    );
  }

  Future<String?> uploadAvatar(File imageFile) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final fileBytes = await imageFile.readAsBytes();

        final response = await _supabase.storage
            .from('avatars')
            .uploadBinary(fileName, fileBytes);

        if (response.isNotEmpty) {
          final publicUrl =
              _supabase.storage.from('avatars').getPublicUrl(fileName);

          await _supabase
              .from('users')
              .update({'avatar_url': publicUrl}).eq('id', user.id);

          return publicUrl;
        } else {
          throw UploadError('Failed to upload avatar');
        }
      },
      config: _defaultRetryConfig,
      context: 'UserRepository.uploadAvatar',
    );
  }

  Future<String?> uploadAvatarBytes(
      Uint8List imageBytes, String filename) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        final fileName =
            '${user.id}_${DateTime.now().millisecondsSinceEpoch}_$filename';

        final response = await _supabase.storage
            .from('avatars')
            .uploadBinary(fileName, imageBytes);

        if (response.isNotEmpty) {
          final publicUrl =
              _supabase.storage.from('avatars').getPublicUrl(fileName);

          await _supabase
              .from('users')
              .update({'avatar_url': publicUrl}).eq('id', user.id);

          return publicUrl;
        } else {
          throw UploadError('Failed to upload avatar');
        }
      },
      config: _defaultRetryConfig,
      context: 'UserRepository.uploadAvatarBytes',
    );
  }

  Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
    if (forceRefresh) {
      final stats = await _fetchUserStatsFromNetwork();
      await _cacheService.cacheUserStats(stats);
      return stats;
    }

    final cachedStats = _cacheService.getCachedUserStats();
    if (cachedStats != null) {
      // Background refresh
      _cacheService.refreshCriticalData(() async {
        final freshStats = await _fetchUserStatsFromNetwork();
        await _cacheService.cacheUserStats(freshStats);
      });
      return cachedStats;
    }

    final stats = await _fetchUserStatsFromNetwork();
    await _cacheService.cacheUserStats(stats);
    return stats;
  }

  Future<Map<String, dynamic>> _fetchUserStatsFromNetwork() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        final dynamic matchesJoined = await _supabase
            .from('match_participants')
            .select('id')
            .eq('user_id', user.id);

        final dynamic matchesCreated = await _supabase
            .from('matches')
            .select('id')
            .or('team1_id.eq.${user.id},team2_id.eq.${user.id}');

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
      },
      context: 'UserRepository.getUserStats',
    );
  }

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
          context: 'UserRepository.getNotifications',
        );
      },
      <NotificationModel>[],
      context: 'UserRepository.getNotifications',
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    return ErrorHandler.withErrorHandling(() async {
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    }, context: 'UserRepository.markNotificationAsRead');
  }

  Future<void> clearAllNotifications() async {
    return ErrorHandler.withErrorHandling(() async {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase
          .from('notifications')
          .update({'is_read': true}).eq('user_id', user.id);
    }, context: 'UserRepository.clearAllNotifications');
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
    }, context: 'UserRepository.createNotification');
  }
}
