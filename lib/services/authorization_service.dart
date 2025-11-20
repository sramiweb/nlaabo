import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Service for handling role-based authorization checks
class AuthorizationService {
  final ApiService _apiService;

  AuthorizationService(this._apiService);

  /// Check if user has permission to create matches
  Future<bool> canCreateMatch(String userId) async {
    try {
      final user = await _apiService.getUser(userId);
      // Allow players and admins to create matches
      return user.role == 'player' || user.role == 'admin' || user.role == 'organizer';
    } catch (e) {
      debugPrint('Authorization check failed for create match: $e');
      return false;
    }
  }

  /// Check if user has permission to join teams
  Future<bool> canJoinTeam(String userId) async {
    try {
      final user = await _apiService.getUser(userId);
      // All authenticated users can join teams
      return user.role == 'player' || user.role == 'admin' || user.role == 'organizer';
    } catch (e) {
      debugPrint('Authorization check failed for join team: $e');
      return false;
    }
  }

  /// Check if user has permission to create teams
  Future<bool> canCreateTeam(String userId) async {
    try {
      final user = await _apiService.getUser(userId);
      // Allow players and admins to create teams
      return user.role == 'player' || user.role == 'admin' || user.role == 'organizer';
    } catch (e) {
      debugPrint('Authorization check failed for create team: $e');
      return false;
    }
  }

  /// Check if user has permission to manage team (update settings, manage members)
  Future<bool> canManageTeam(String userId, String teamId) async {
    try {
      final user = await _apiService.getUser(userId);
      final team = await _apiService.getTeam(teamId);

      // Team owner or admin can manage team
      return team.ownerId == userId || user.role == 'admin';
    } catch (e) {
      debugPrint('Authorization check failed for manage team: $e');
      return false;
    }
  }

  /// Check if user has permission to delete team
  Future<bool> canDeleteTeam(String userId, String teamId) async {
    try {
      final user = await _apiService.getUser(userId);
      final team = await _apiService.getTeam(teamId);

      // Only team owner or admin can delete team
      return team.ownerId == userId || user.role == 'admin';
    } catch (e) {
      debugPrint('Authorization check failed for delete team: $e');
      return false;
    }
  }

  /// Check if user has permission to manage team join requests
  Future<bool> canManageJoinRequests(String userId, String teamId) async {
    try {
      final user = await _apiService.getUser(userId);
      final team = await _apiService.getTeam(teamId);

      // Team owner or admin can manage join requests
      return team.ownerId == userId || user.role == 'admin';
    } catch (e) {
      debugPrint('Authorization check failed for manage join requests: $e');
      return false;
    }
  }

  /// Check if user has permission to update their own profile
  Future<bool> canUpdateProfile(String userId, String targetUserId) async {
    try {
      final user = await _apiService.getUser(userId);

      // Users can update their own profile, admins can update any profile
      return userId == targetUserId || user.role == 'admin';
    } catch (e) {
      debugPrint('Authorization check failed for update profile: $e');
      return false;
    }
  }

  /// Check if user has admin privileges
  Future<bool> isAdmin(String userId) async {
    try {
      final user = await _apiService.getUser(userId);
      return user.role == 'admin';
    } catch (e) {
      debugPrint('Authorization check failed for admin role: $e');
      return false;
    }
  }

  /// Check if user has organizer privileges
  Future<bool> isOrganizer(String userId) async {
    try {
      final user = await _apiService.getUser(userId);
      return user.role == 'organizer' || user.role == 'admin';
    } catch (e) {
      debugPrint('Authorization check failed for organizer role: $e');
      return false;
    }
  }

  /// Get user role
  Future<String?> getUserRole(String userId) async {
    try {
      final user = await _apiService.getUser(userId);
      return user.role;
    } catch (e) {
      debugPrint('Failed to get user role: $e');
      return null;
    }
  }

  /// Validate operation with user context
  Future<void> validateOperation({
    required String userId,
    required String operation,
    String? resourceId,
    Map<String, dynamic>? context,
  }) async {
    bool hasPermission = false;

    switch (operation) {
      case 'create_match':
        hasPermission = await canCreateMatch(userId);
        break;
      case 'join_team':
        hasPermission = await canJoinTeam(userId);
        break;
      case 'create_team':
        hasPermission = await canCreateTeam(userId);
        break;
      case 'manage_team':
        if (resourceId != null) {
          hasPermission = await canManageTeam(userId, resourceId);
        }
        break;
      case 'delete_team':
        if (resourceId != null) {
          hasPermission = await canDeleteTeam(userId, resourceId);
        }
        break;
      case 'manage_join_requests':
        if (resourceId != null) {
          hasPermission = await canManageJoinRequests(userId, resourceId);
        }
        break;
      case 'update_profile':
        if (context != null && context['targetUserId'] != null) {
          hasPermission = await canUpdateProfile(userId, context['targetUserId']);
        }
        break;
      default:
        hasPermission = false;
    }

    if (!hasPermission) {
      throw Exception('Unauthorized: You do not have permission to perform this operation');
    }
  }
}
