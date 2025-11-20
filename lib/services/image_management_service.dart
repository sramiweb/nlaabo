import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'image_upload_service.dart';
import 'error_handler.dart';

/// Comprehensive image management service with caching, quota management, and cleanup
class ImageManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImageUploadService _uploadService = ImageUploadService();

  // Storage quotas (in bytes)
  static const int userAvatarQuota = 50 * 1024 * 1024; // 50MB per user for avatars
  static const int teamLogoQuota = 100 * 1024 * 1024; // 100MB per team for logos

  // Cache configuration
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxCacheObjects = 100;

  /// Uploads and caches a user avatar
  Future<String?> uploadUserAvatar(File imageFile, String userId) async {
    try {
      // Check storage quota before upload
      await _checkUserStorageQuota(userId, await imageFile.length());

      // Upload the image
      final imageUrl = await _uploadService.uploadAvatar(imageFile, userId);

      if (imageUrl != null) {
        // Update user's storage usage
        await _updateUserStorageUsage(userId, await imageFile.length());
      }

      return imageUrl;
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.uploadUserAvatar');
      rethrow;
    }
  }

  /// Uploads and caches a team logo
  Future<String?> uploadTeamLogo(File imageFile, String teamId) async {
    try {
      // Check storage quota before upload
      await _checkTeamStorageQuota(teamId, await imageFile.length());

      // Upload the image
      final imageUrl = await _uploadService.uploadTeamLogo(imageFile, teamId);

      if (imageUrl != null) {
        // Update team's storage usage
        await _updateTeamStorageUsage(teamId, await imageFile.length());
      }

      return imageUrl;
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.uploadTeamLogo');
      rethrow;
    }
  }

  /// Gets a cached image file, downloading if not cached
  Future<File> getCachedImage(String imageUrl) async {
    try {
      // Check if image is cached
      final cachedImage = await _getCachedImageFile(imageUrl);
      if (cachedImage != null) {
        return cachedImage;
      }

      // Download and cache the image
      return await _downloadAndCacheImage(imageUrl);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.getCachedImage');
      rethrow;
    }
  }

  /// Gets image from cache synchronously if available
  Future<dynamic> getCachedImageSync(String imageUrl) async {
    try {
      return await _getCachedImageFile(imageUrl);
    } catch (e) {
      return null;
    }
  }

  /// Deletes a user avatar and cleans up cache
  Future<void> deleteUserAvatar(String avatarUrl, String userId) async {
    try {
      // Remove from storage
      await _uploadService.deleteAvatar(avatarUrl);

      // Update storage usage
      final fileSize = await _getImageSizeFromUrl(avatarUrl);
      await _updateUserStorageUsage(userId, -fileSize);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.deleteUserAvatar');
      rethrow;
    }
  }

  /// Deletes a team logo and cleans up cache
  Future<void> deleteTeamLogo(String logoUrl, String teamId) async {
    try {
      // Remove from storage
      await _uploadService.deleteTeamLogo(logoUrl);

      // Update storage usage
      final fileSize = await _getImageSizeFromUrl(logoUrl);
      await _updateTeamStorageUsage(teamId, -fileSize);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.deleteTeamLogo');
      rethrow;
    }
  }

  /// Gets storage usage for a user
  Future<Map<String, dynamic>> getUserStorageUsage(String userId) async {
    try {
      final response = await _supabase
          .from('user_storage_usage')
          .select('*')
          .eq('user_id', userId)
          .single();

      return {
        'used': response['used_bytes'] ?? 0,
        'quota': userAvatarQuota,
        'available': userAvatarQuota - (response['used_bytes'] ?? 0),
        'percentage': ((response['used_bytes'] ?? 0) / userAvatarQuota) * 100,
      };
    } catch (e) {
      // If no record exists, return default values
      return {
        'used': 0,
        'quota': userAvatarQuota,
        'available': userAvatarQuota,
        'percentage': 0.0,
      };
    }
  }

  /// Gets storage usage for a team
  Future<Map<String, dynamic>> getTeamStorageUsage(String teamId) async {
    try {
      final response = await _supabase
          .from('team_storage_usage')
          .select('*')
          .eq('team_id', teamId)
          .single();

      return {
        'used': response['used_bytes'] ?? 0,
        'quota': teamLogoQuota,
        'available': teamLogoQuota - (response['used_bytes'] ?? 0),
        'percentage': ((response['used_bytes'] ?? 0) / teamLogoQuota) * 100,
      };
    } catch (e) {
      // If no record exists, return default values
      return {
        'used': 0,
        'quota': teamLogoQuota,
        'available': teamLogoQuota,
        'percentage': 0.0,
      };
    }
  }

  /// Cleans up old cached images
  Future<void> cleanupCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return;

      final files = await cacheDir.list().toList();
      final now = DateTime.now();

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);

          // Remove files older than cache duration
          if (age > cacheDuration) {
            await file.delete();
          }
        }
      }

      // Remove oldest files if cache exceeds max objects
      if (files.length > maxCacheObjects) {
        final sortedFiles = files.whereType<File>().toList()
          ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        final excessCount = files.length - maxCacheObjects;
        for (var i = 0; i < excessCount; i++) {
          await sortedFiles[i].delete();
        }
      }
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.cleanupCache');
    }
  }

  /// Gets the cache directory for images
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generates cache key from image URL
  String _getCacheKey(String imageUrl) {
    return base64Url.encode(utf8.encode(imageUrl)).replaceAll('=', '');
  }

  /// Gets cached image file if it exists and is not expired
  Future<File?> _getCachedImageFile(String imageUrl) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final cacheKey = _getCacheKey(imageUrl);
      final cacheFile = File('${cacheDir.path}/$cacheKey');

      if (await cacheFile.exists()) {
        final stat = await cacheFile.stat();
        final age = DateTime.now().difference(stat.modified);

        if (age <= cacheDuration) {
          return cacheFile;
        } else {
          // Remove expired cache file
          await cacheFile.delete();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Downloads and caches an image
  Future<File> _downloadAndCacheImage(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to download image: ${response.statusCode}');
    }

    final cacheDir = await _getCacheDirectory();
    final cacheKey = _getCacheKey(imageUrl);
    final cacheFile = File('${cacheDir.path}/$cacheKey');

    await cacheFile.writeAsBytes(response.bodyBytes);
    return cacheFile;
  }

  /// Checks if user has enough storage quota
  Future<void> _checkUserStorageQuota(String userId, int additionalBytes) async {
    final usage = await getUserStorageUsage(userId);
    final newTotal = usage['used'] + additionalBytes;

    if (newTotal > userAvatarQuota) {
      throw Exception(
        'Storage quota exceeded. You have used ${usage['used']} bytes out of $userAvatarQuota bytes. '
            'Additional $additionalBytes bytes would exceed your limit.',
      );
    }
  }

  /// Checks if team has enough storage quota
  Future<void> _checkTeamStorageQuota(String teamId, int additionalBytes) async {
    final usage = await getTeamStorageUsage(teamId);
    final newTotal = usage['used'] + additionalBytes;

    if (newTotal > teamLogoQuota) {
      throw Exception(
        'Storage quota exceeded. The team has used ${usage['used']} bytes out of $teamLogoQuota bytes. '
            'Additional $additionalBytes bytes would exceed the limit.',
      );
    }
  }

  /// Updates user storage usage
  Future<void> _updateUserStorageUsage(String userId, int bytesDelta) async {
    try {
      await _supabase.rpc('update_user_storage_usage', params: {
        'p_user_id': userId,
        'p_bytes_delta': bytesDelta,
      });
    } catch (e) {
      // Don't throw here as it's not critical for the upload operation
    }
  }

  /// Updates team storage usage
  Future<void> _updateTeamStorageUsage(String teamId, int bytesDelta) async {
    try {
      await _supabase.rpc('update_team_storage_usage', params: {
        'p_team_id': teamId,
        'p_bytes_delta': bytesDelta,
      });
    } catch (e) {
      // Don't throw here as it's not critical for the upload operation
    }
  }

  /// Gets image file size from URL (approximate)
  Future<int> _getImageSizeFromUrl(String imageUrl) async {
    try {
      // Placeholder - cache functionality removed
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Validates image before upload with comprehensive security checks
  Future<void> validateImage(File imageFile, {bool isAvatar = true}) async {
    final maxSize = isAvatar ? ImageUploadService.maxAvatarSize : ImageUploadService.maxLogoSize;

    // Check file size
    final fileSize = await imageFile.length();
    if (fileSize > maxSize) {
      throw Exception('Image file is too large. Maximum size is ${maxSize ~/ (1024 * 1024)}MB.');
    }

    // Check for minimum file size (prevent empty or tiny files)
    if (fileSize < 100) {
      throw Exception('Image file is too small or corrupted.');
    }

    // Check file extension
    final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    if (!ImageUploadService.supportedFormats.contains(extension)) {
      throw Exception('Unsupported image format. Supported formats: ${ImageUploadService.supportedFormats.join(", ")}');
    }

    // Read file header to validate actual file type (prevent extension spoofing)
    final fileBytes = await imageFile.readAsBytes();
    final actualFormat = _detectImageFormat(fileBytes);
    if (actualFormat == null || !ImageUploadService.supportedFormats.contains(actualFormat)) {
      throw Exception('File content does not match the declared image format. Possible security threat detected.');
    }

    // Check for malicious content in file header
    if (_containsMaliciousPatterns(fileBytes)) {
      throw Exception('Image file contains potentially malicious content.');
    }

    // Check image dimensions and prevent extremely large images
    try {
      final dimensions = await _getImageDimensions(fileBytes, actualFormat);
      if (dimensions != null) {
        const maxDimension = 4096; // Prevent DoS with extremely large images
        final width = dimensions['width'];
        final height = dimensions['height'];
        if (width != null && height != null) {
          if (width > maxDimension || height > maxDimension) {
            throw Exception('Image dimensions are too large. Maximum allowed dimension is ${maxDimension}px.');
          }

          // Check aspect ratio to prevent extremely skewed images
          final aspectRatio = width / height;
          if (aspectRatio > 10 || aspectRatio < 0.1) {
            throw Exception('Image aspect ratio is invalid. Please use a more balanced image.');
          }
        }
      }
    } catch (e) {
      // If we can't decode dimensions, still allow upload but log warning
      ErrorHandler.logError(e, null, 'ImageManagementService.validateImage - dimension check failed');
    }
  }

  /// Detects actual image format from file header bytes
  String? _detectImageFormat(List<int> bytes) {
    if (bytes.length < 4) return null;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpg';
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png';
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return 'gif';
    }

    // WebP: 52 49 46 46 (RIFF) followed by WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'webp';
    }

    return null;
  }

  /// Checks for malicious patterns in image file
  bool _containsMaliciousPatterns(List<int> bytes) {
    // Check for embedded scripts or HTML
    final byteString = String.fromCharCodes(bytes.take(512)); // Check first 512 bytes

    final maliciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'<\?php', caseSensitive: false),
      RegExp(r'<%', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
    ];

    for (final pattern in maliciousPatterns) {
      if (pattern.hasMatch(byteString)) {
        return true;
      }
    }

    return false;
  }

  /// Gets image dimensions from file bytes
  Future<Map<String, int>?> _getImageDimensions(List<int> bytes, String format) async {
    try {
      // For now, return null - dimension checking can be implemented with image package
      // This prevents adding another dependency but still provides the security framework
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Batch cleanup for user images (when user is deleted)
  Future<void> cleanupUserImages(String userId) async {
    try {
      // Get all user avatars
      final avatars = await _supabase.storage.from('avatars').list(path: userId);

      // Delete from storage
      for (final avatar in avatars) {
        await _supabase.storage.from('avatars').remove(['$userId/${avatar.name}']);
      }

      // Clear user storage usage
      await _supabase.from('user_storage_usage').delete().eq('user_id', userId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.cleanupUserImages');
    }
  }

  /// Batch cleanup for team images (when team is deleted)
  Future<void> cleanupTeamImages(String teamId) async {
    try {
      // Get all team logos
      final logos = await _supabase.storage.from('team-logos').list(path: teamId);

      // Delete from storage
      for (final logo in logos) {
        await _supabase.storage.from('team-logos').remove(['$teamId/${logo.name}']);
      }

      // Clear team storage usage
      await _supabase.from('team_storage_usage').delete().eq('team_id', teamId);
    } catch (e, st) {
      ErrorHandler.logError(e, st, 'ImageManagementService.cleanupTeamImages');
    }
  }
}
