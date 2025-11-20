import '../models/match.dart';
import '../models/user.dart' as app_user;
import '../services/api_service.dart';
import '../services/error_handler.dart';
import '../utils/validators.dart';

class MatchRepository {
  final ApiService _apiService;
  
  static final _retryConfig = RetryConfig(
    maxAttempts: 2,
    initialDelay: const Duration(milliseconds: 500),
    shouldRetry: (error) => error is NetworkError,
  );

  MatchRepository(this._apiService);

  Future<List<Match>> getMatches({int? limit, int? offset}) async {
    return ErrorHandler.withErrorHandling(
      () => _apiService.getMatches(limit: limit, offset: offset),
      fallbackValue: [],
      context: 'MatchRepository.getMatches',
      rethrowOnError: false,
    );
  }

  Future<List<Match>> getAllMatches({int? limit, int? offset}) async {
    return ErrorHandler.withErrorHandling(
      () => _apiService.getAllMatches(limit: limit, offset: offset),
      fallbackValue: [],
      context: 'MatchRepository.getAllMatches',
      rethrowOnError: false,
    );
  }

  Future<Match> getMatch(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _apiService.getMatch(matchId),
      config: _retryConfig,
      context: 'MatchRepository.getMatch',
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
  }) async {
    return ErrorHandler.withRetry(
      () async {
        // Repository-level validation
        _validateMatchData(
          team1Id: team1Id,
          team2Id: team2Id,
          matchDate: matchDate,
          location: location,
          title: title,
          maxPlayers: maxPlayers,
          matchType: matchType,
        );

        return _apiService.createMatch(
          team1Id: team1Id,
          team2Id: team2Id,
          matchDate: matchDate,
          location: location,
          title: title,
          maxPlayers: maxPlayers,
          matchType: matchType,
        );
      },
      config: _retryConfig,
      context: 'MatchRepository.createMatch',
    );
  }

  Future<void> closeMatch(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _apiService.closeMatch(matchId),
      config: _retryConfig,
      context: 'MatchRepository.closeMatch',
    );
  }

  Future<void> joinMatch(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _apiService.joinMatch(matchId),
      config: _retryConfig,
      context: 'MatchRepository.joinMatch',
    );
  }

  Future<void> leaveMatch(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _apiService.leaveMatch(matchId),
      config: _retryConfig,
      context: 'MatchRepository.leaveMatch',
    );
  }

  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withErrorHandling(
      () => _apiService.getMatchPlayers(matchId),
      fallbackValue: [],
      context: 'MatchRepository.getMatchPlayers',
      rethrowOnError: false,
    );
  }

  Future<Match> acceptMatchRequest(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _apiService.acceptMatchRequest(matchId),
      config: _retryConfig,
      context: 'MatchRepository.acceptMatchRequest',
    );
  }

  Future<void> rejectMatchRequest(String matchId) async {
    if (matchId.trim().isEmpty) {
      throw ValidationError('Match ID cannot be empty');
    }

    return ErrorHandler.withRetry(
      () => _apiService.rejectMatchRequest(matchId),
      config: _retryConfig,
      context: 'MatchRepository.rejectMatchRequest',
    );
  }

  Future<List<Match>> getPendingMatchRequests() async {
    return ErrorHandler.withErrorHandling(
      () => _apiService.getPendingMatchRequests(),
      fallbackValue: [],
      context: 'MatchRepository.getPendingMatchRequests',
      rethrowOnError: false,
    );
  }

  void _validateMatchData({
    required String team1Id,
    required String team2Id,
    required DateTime matchDate,
    required String location,
    String? title,
    int? maxPlayers,
    String? matchType,
  }) {
    // Team validation
    if (team1Id.trim().isEmpty) {
      throw ValidationError('Team 1 ID cannot be empty');
    }
    if (team2Id.trim().isEmpty) {
      throw ValidationError('Team 2 ID cannot be empty');
    }

    // Date validation
    final dateError = validateMatchDateTime(matchDate);
    if (dateError != null) {
      throw ValidationError(dateError);
    }

    // Location validation
    final locationError = validateLocation(location);
    if (locationError != null) {
      throw ValidationError(locationError);
    }

    // Title validation
    if (title != null && title.isNotEmpty) {
      final titleError = validateMatchTitle(title);
      if (titleError != null) {
        throw ValidationError(titleError);
      }
    }

    // Max players validation
    if (maxPlayers != null) {
      final playersError = validateMaxPlayers(maxPlayers);
      if (playersError != null) {
        throw ValidationError(playersError);
      }
    }

    // Match type validation
    if (matchType != null && !['male', 'female', 'mixed'].contains(matchType)) {
      throw ValidationError('Match type must be male, female, or mixed');
    }
  }
}
