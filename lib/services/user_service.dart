import 'dart:io';
import 'dart:typed_data';
import '../models/user.dart' as app_user;
import '../models/notification.dart';
import '../repositories/user_repository.dart';
import 'error_handler.dart';
import '../utils/validators.dart';
import 'phone_service.dart';

class UserService {
  final UserRepository _userRepository;
  
  static final _retryConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: const Duration(seconds: 1),
    shouldRetry: (error) => error is NetworkError || error is DatabaseError,
  );

  UserService(this._userRepository);

  Future<app_user.User> getCurrentUser() async {
    return ErrorHandler.withRetry(
      () => _userRepository.getCurrentUser(),
      config: _retryConfig,
      context: 'UserService.getCurrentUser',
    );
  }

  Future<app_user.User> getUserById(String userId) async {
    if (userId.trim().isEmpty) {
      throw ValidationError('User ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _userRepository.getUserById(userId),
      config: _retryConfig,
      context: 'UserService.getUserById',
    );
  }

  Future<app_user.User> getUser(String userId) async {
    if (userId.trim().isEmpty) {
      throw ValidationError('User ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _userRepository.getUser(userId),
      config: _retryConfig,
      context: 'UserService.getUser',
    );
  }

  Future<List<app_user.User>> getAllUsers() async {
    return ErrorHandler.withFallback(
      () => _userRepository.getAllUsers(),
      [],
      context: 'UserService.getAllUsers',
    );
  }

  Future<void> deleteUser(String userId) async {
    if (userId.trim().isEmpty) {
      throw ValidationError('User ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _userRepository.deleteUser(userId),
      config: _retryConfig,
      context: 'UserService.deleteUser',
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
  }) async {
    return ErrorHandler.withRetry(
      () async {
        // Comprehensive validation
        await _validateProfileData(
          name: name,
          position: position,
          bio: bio,
          gender: gender,
          phone: phone,
          age: age,
          location: location,
        );

        return _userRepository.updateProfile(
          name: name?.trim(),
          position: position?.trim(),
          bio: bio?.trim(),
          imageUrl: imageUrl,
          gender: gender,
          phone: phone?.trim(),
          age: age,
          location: location?.trim(),
        );
      },
      config: _retryConfig,
      context: 'UserService.updateProfile',
    );
  }

  Future<String?> uploadAvatar(File imageFile) async {
    return ErrorHandler.withRetry(
      () async {
        // File validation
        _validateImageFile(imageFile);
        return _userRepository.uploadAvatar(imageFile);
      },
      config: _retryConfig,
      context: 'UserService.uploadAvatar',
    );
  }

  Future<String?> uploadAvatarBytes(Uint8List imageBytes, String filename) async {
    return ErrorHandler.withRetry(
      () async {
        // Bytes validation
        _validateImageBytes(imageBytes, filename);
        return _userRepository.uploadAvatarBytes(imageBytes, filename);
      },
      config: _retryConfig,
      context: 'UserService.uploadAvatarBytes',
    );
  }

  Future<Map<String, dynamic>> getUserStats() async {
    return ErrorHandler.withFallback(
      () => _userRepository.getUserStats(),
      {'matches_joined': 0, 'matches_created': 0, 'teams_owned': 0},
      context: 'UserService.getUserStats',
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    return ErrorHandler.withFallback(
      () => _userRepository.getNotifications(),
      [],
      context: 'UserService.getNotifications',
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    if (notificationId.trim().isEmpty) {
      throw ValidationError('Notification ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _userRepository.markNotificationAsRead(notificationId),
      config: _retryConfig,
      context: 'UserService.markNotificationAsRead',
    );
  }

  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    return ErrorHandler.withRetry(
      () async {
        // Comprehensive validation
        _validateNotificationData(
          userId: userId,
          title: title,
          message: message,
          type: type,
        );

        return _userRepository.createNotification(
          userId: userId.trim(),
          title: title.trim(),
          message: message.trim(),
          type: type,
          relatedId: relatedId,
        );
      },
      config: _retryConfig,
      context: 'UserService.createNotification',
    );
  }

  Future<void> _validateProfileData({
    String? name,
    String? position,
    String? bio,
    String? gender,
    String? phone,
    int? age,
    String? location,
  }) async {
    // Name validation
    if (name != null) {
      final nameError = validateName(name);
      if (nameError != null) {
        throw ValidationError(nameError);
      }
    }

    // Phone validation
    if (phone != null && phone.isNotEmpty) {
      final phoneError = await PhoneService.validatePhoneNumber(phone, isRealTime: false);
      if (phoneError != null) {
        throw ValidationError(phoneError);
      }
    }

    // Age validation
    if (age != null) {
      final ageError = validateAgeOptional(age.toString());
      if (ageError != null) {
        throw ValidationError(ageError);
      }
    }

    // Location validation
    if (location != null && location.isNotEmpty) {
      final locationError = validateLocation(location);
      if (locationError != null) {
        throw ValidationError(locationError);
      }
    }

    // Bio validation
    if (bio != null && bio.length > 500) {
      throw ValidationError('Bio cannot exceed 500 characters');
    }

    // Position validation
    if (position != null && position.length > 100) {
      throw ValidationError('Position cannot exceed 100 characters');
    }

    // Gender validation
    if (gender != null && !['male', 'female', 'other'].contains(gender.toLowerCase())) {
      throw ValidationError('Invalid gender value');
    }
  }

  void _validateImageFile(File imageFile) {
    if (!imageFile.existsSync()) {
      throw ValidationError('Image file does not exist');
    }

    // Check file extension
    final extension = imageFile.path.toLowerCase().split('.').last;
    if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      throw ValidationError('Invalid image format. Supported: JPG, PNG, GIF, WebP');
    }
  }

  void _validateImageBytes(Uint8List imageBytes, String filename) {
    if (imageBytes.isEmpty) {
      throw ValidationError('Image data cannot be empty');
    }

    if (imageBytes.length > 5 * 1024 * 1024) {
      throw ValidationError('Image size must be less than 5MB');
    }

    if (filename.trim().isEmpty) {
      throw ValidationError('Filename cannot be empty');
    }

    // Check filename extension
    final extension = filename.toLowerCase().split('.').last;
    if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      throw ValidationError('Invalid image format. Supported: JPG, PNG, GIF, WebP');
    }
  }

  void _validateNotificationData({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) {
    if (userId.trim().isEmpty) {
      throw ValidationError('User ID cannot be empty');
    }

    if (title.trim().isEmpty) {
      throw ValidationError('Notification title cannot be empty');
    }

    if (title.length > 100) {
      throw ValidationError('Notification title cannot exceed 100 characters');
    }

    if (message.trim().isEmpty) {
      throw ValidationError('Notification message cannot be empty');
    }

    if (message.length > 500) {
      throw ValidationError('Notification message cannot exceed 500 characters');
    }

    final validTypes = ['info', 'warning', 'error', 'success', 'match', 'team', 'system'];
    if (!validTypes.contains(type)) {
      throw ValidationError('Invalid notification type: $type');
    }
  }
}
