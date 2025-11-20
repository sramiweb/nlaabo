import '../models/team.dart';
import '../models/city.dart';
import '../models/team.dart' as team_models;
import '../models/user.dart' as app_user;
import '../repositories/team_repository.dart';
import '../services/cache_service.dart';
import '../services/user_service.dart';
import '../services/image_management_service.dart';
import '../services/error_handler.dart';
import '../utils/validators.dart';
import 'dart:io';

class TeamService {
  final TeamRepository _teamRepository;
  final CacheService _cacheService;
  final ImageManagementService _imageService;
  
  static final _retryConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: const Duration(seconds: 1),
    shouldRetry: (error) => error is NetworkError || error is DatabaseError,
  );

  TeamService(this._teamRepository)
      : _cacheService = CacheService(),
        _imageService = ImageManagementService();

  UserService? _userService;
  void setUserService(UserService userService) {
    _userService = userService;
  }

  Future<List<Team>> getUserTeams() async {
    return ErrorHandler.withFallback(
      () => _teamRepository.getUserTeams(),
      [],
      context: 'TeamService.getUserTeams',
    );
  }

  Future<List<Team>> getMyTeams() async {
    return ErrorHandler.withFallback(
      () => _teamRepository.getMyTeams(),
      [],
      context: 'TeamService.getMyTeams',
    );
  }

  Future<List<Team>> getAllTeams() async {
    return ErrorHandler.withErrorHandling(
      () async {
        // Try cache first
        final cachedTeams = _cacheService.getCachedTeams();
        if (cachedTeams != null && cachedTeams.isNotEmpty) {
          return cachedTeams;
        }

        // Fetch from API and cache
        final teams = await _teamRepository.getAllTeams();
        await _cacheService.cacheTeams(teams);
        return teams;
      },
      fallbackValue: [],
      context: 'TeamService.getAllTeams',
      rethrowOnError: false,
    );
  }

  Future<List<City>> getCities() async {
    return ErrorHandler.withErrorHandling(
      () async {
        // Try cache first
        final cachedCities = _cacheService.getCachedCities();
        if (cachedCities != null && cachedCities.isNotEmpty) {
          return cachedCities;
        }

        // Fetch from API and cache
        final cities = await _teamRepository.getCities();
        await _cacheService.cacheCities(cities);
        return cities;
      },
      fallbackValue: [],
      context: 'TeamService.getCities',
      rethrowOnError: false,
    );
  }

  Future<Team> getTeam(String teamId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _teamRepository.getTeam(teamId),
      config: _retryConfig,
      context: 'TeamService.getTeam',
    );
  }

  Future<List<Team>> searchTeams(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    return ErrorHandler.withFallback(
      () => _teamRepository.searchTeams(query),
      [],
      context: 'TeamService.searchTeams',
    );
  }

  Future<Team> createTeam({
    required String name,
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
        // Comprehensive validation
        _validateTeamData(
          name: name,
          location: location,
          numberOfPlayers: numberOfPlayers,
          description: description,
        );

        return _teamRepository.createTeam(
          name.trim(),
          location: location,
          numberOfPlayers: numberOfPlayers,
          description: description?.trim(),
          logo: logo,
          isRecruiting: isRecruiting,
          gender: gender,
          minAge: minAge,
          maxAge: maxAge,
        );
      },
      config: _retryConfig,
      context: 'TeamService.createTeam',
    );
  }

  Future<Team> uploadTeamLogo(String teamId, File imageFile) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () async {
        final logoUrl = await _imageService.uploadTeamLogo(imageFile, teamId);
        
        if (logoUrl == null) {
          throw UploadError('Failed to upload team logo');
        }

        final updatedTeam = await _teamRepository.updateTeam(teamId, logo: logoUrl);
        await _cacheService.invalidateTeamsCache();
        return updatedTeam;
      },
      config: _retryConfig,
      context: 'TeamService.uploadTeamLogo',
    );
  }

  Future<Team> deleteTeamLogo(String teamId, String logoUrl) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () async {
        await _imageService.deleteTeamLogo(logoUrl, teamId);
        final updatedTeam = await _teamRepository.updateTeam(teamId, logo: null);
        await _cacheService.invalidateTeamsCache();
        return updatedTeam;
      },
      config: _retryConfig,
      context: 'TeamService.deleteTeamLogo',
    );
  }

  Future<Map<String, dynamic>> getTeamStorageUsage(String teamId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withFallback(
      () => _imageService.getTeamStorageUsage(teamId),
      {'used': 0, 'total': 0},
      context: 'TeamService.getTeamStorageUsage',
    );
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _teamRepository.toggleTeamRecruiting(teamId),
      config: _retryConfig,
      context: 'TeamService.toggleTeamRecruiting',
    );
  }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _teamRepository.deleteTeam(teamId, reason: reason),
      config: _retryConfig,
      context: 'TeamService.deleteTeam',
    );
  }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(String teamId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withFallback(
      () => _teamRepository.getTeamJoinRequests(teamId),
      [],
      context: 'TeamService.getTeamJoinRequests',
    );
  }

  Future<team_models.TeamJoinRequest> createJoinRequest(String teamId, {String? message}) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _teamRepository.createJoinRequest(teamId, message: message),
      config: _retryConfig,
      context: 'TeamService.createJoinRequest',
    );
  }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(
    String teamId,
    String requestId,
    String status,
  ) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    if (requestId.trim().isEmpty) {
      throw ValidationError('Request ID cannot be empty');
    }
    
    final validStatuses = ['accepted', 'rejected', 'pending'];
    if (!validStatuses.contains(status)) {
      throw ValidationError('Invalid status: $status');
    }

    return ErrorHandler.withRetry(
      () => _teamRepository.updateJoinRequestStatus(teamId, requestId, status),
      config: _retryConfig,
      context: 'TeamService.updateJoinRequestStatus',
    );
  }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
    return ErrorHandler.withFallback(
      () => _teamRepository.getMyJoinRequests(),
      [],
      context: 'TeamService.getMyJoinRequests',
    );
  }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    if (requestId.trim().isEmpty) {
      throw ValidationError('Request ID cannot be empty');
    }
    
    return ErrorHandler.withRetry(
      () => _teamRepository.cancelJoinRequest(teamId, requestId),
      config: _retryConfig,
      context: 'TeamService.cancelJoinRequest',
    );
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }
    
    return ErrorHandler.withFallback(
      () => _teamRepository.getTeamMembers(teamId),
      [],
      context: 'TeamService.getTeamMembers',
    );
  }

  Future<Map<String, dynamic>> getTeamDataBatch(List<String> teamIds) async {
    if (teamIds.isEmpty) {
      return {'owners': <String, Map<String, dynamic>>{}, 'memberCounts': <String, int>{}};
    }

    return ErrorHandler.withFallback(
      () async {
        final Map<String, Map<String, dynamic>> ownersMap = {};
        final Map<String, int> memberCountsMap = {};

        const batchSize = 5;
        for (var i = 0; i < teamIds.length; i += batchSize) {
          final batch = teamIds.sublist(
            i,
            i + batchSize > teamIds.length ? teamIds.length : i + batchSize,
          );

          final futures = batch.map((teamId) => processTeamBatch(teamId));
          final results = await Future.wait(futures);

          for (final result in results) {
            final teamId = result['teamId'] as String;
            ownersMap[teamId] = result['owner'] as Map<String, dynamic>;
            memberCountsMap[teamId] = result['memberCount'] as int;
          }
        }

        return {'owners': ownersMap, 'memberCounts': memberCountsMap};
      },
      {'owners': <String, Map<String, dynamic>>{}, 'memberCounts': <String, int>{}},
      context: 'TeamService.getTeamDataBatch',
    );
  }

  Future<Map<String, dynamic>> processTeamBatch(String teamId) async {
    return ErrorHandler.withFallback(
      () async {
        final team = await _teamRepository.getTeam(teamId);

        // Try to get cached owner data first
        Map<String, dynamic>? cachedOwner = _cacheService.getCachedOwner(team.ownerId);

        if (cachedOwner != null) {
          // Use cached owner data
          final members = await getTeamMembers(teamId);
          return {
            'teamId': teamId,
            'owner': cachedOwner,
            'memberCount': members.length,
          };
        }

        // Check if there's a cached error for this owner
        final cachedError = _cacheService.getCachedOwnerError(team.ownerId);
        if (cachedError != null) {
          // Return fallback data without attempting fetch
          final members = await getTeamMembers(teamId);
          return {
            'teamId': teamId,
            'owner': {'name': 'Unknown Owner', 'id': team.ownerId, 'error': cachedError},
            'memberCount': members.length,
          };
        }

        // Fetch owner with retry logic for robustness
        Map<String, dynamic> ownerData;
        try {
          final owner = _userService != null
              ? await ErrorHandler.withRetry(
                  () => _userService!.getUserById(team.ownerId),
                  config: _retryConfig,
                  context: 'TeamService._processTeamBatch.owner',
                )
              : null;

          ownerData = owner != null
              ? {
                  'name': owner.name,
                  'id': owner.id,
                  'position': owner.position,
                  'imageUrl': owner.imageUrl,
                }
              : {'name': 'Unknown Owner', 'id': team.ownerId};

          // Cache successful owner data
          await _cacheService.cacheOwner(team.ownerId, ownerData);
        } catch (e) {
          // Cache the error to prevent repeated failed fetches
          await _cacheService.cacheOwnerError(team.ownerId, e.toString());

          ownerData = {'name': 'Unknown Owner', 'id': team.ownerId, 'error': e.toString()};
        }

        final members = await getTeamMembers(teamId);

        return {
          'teamId': teamId,
          'owner': ownerData,
          'memberCount': members.length,
        };
      },
      {
        'teamId': teamId,
        'owner': {'name': 'Unknown Owner', 'id': teamId, 'error': 'Failed to fetch owner data'},
        'memberCount': 0,
      },
      context: 'TeamService._processTeamBatch',
    );
  }

  Future<void> leaveTeam(String teamId) async {
    if (teamId.trim().isEmpty) {
      throw ValidationError('Team ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _teamRepository.leaveTeam(teamId),
      config: _retryConfig,
      context: 'TeamService.leaveTeam',
    );
  }

  Future<void> invalidateOwnerCache(String ownerId) async {
    if (ownerId.trim().isEmpty) {
      throw ValidationError('Owner ID cannot be empty');
    }

    return ErrorHandler.withErrorHandling(
      () => _cacheService.invalidateOwnerCache(ownerId),
      context: 'TeamService.invalidateOwnerCache',
      rethrowOnError: false,
    );
  }

  Future<void> invalidateAllOwnerCaches() async {
    return ErrorHandler.withErrorHandling(
      () => _cacheService.invalidateAllOwnerCaches(),
      context: 'TeamService.invalidateAllOwnerCaches',
      rethrowOnError: false,
    );
  }

  void _validateTeamData({
    required String name,
    String? location,
    int? numberOfPlayers,
    String? description,
  }) {
    // Name validation
    final nameError = validateTeamName(name);
    if (nameError != null) {
      throw ValidationError(nameError);
    }

    // Location validation
    if (location != null && location.isNotEmpty) {
      final locationError = validateLocation(location);
      if (locationError != null) {
        throw ValidationError(locationError);
      }
    }

    // Number of players validation
    if (numberOfPlayers != null) {
      final playersError = validateMaxPlayers(numberOfPlayers);
      if (playersError != null) {
        throw ValidationError(playersError);
      }
    }

    // Description validation (optional but if provided should be reasonable)
    if (description != null && description.length > 500) {
      throw ValidationError('Description cannot exceed 500 characters');
    }
  }
}
