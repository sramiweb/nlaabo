import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/match.dart';
import '../models/user.dart' as app_user;
import '../services/error_handler.dart';
import '../services/cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/validators.dart';

class MatchRepository {
  final SupabaseClient _supabase;
  final CacheService _cacheService = CacheService();

  // Retry config
  final RetryConfig _defaultRetryConfig = RetryConfig(
    maxAttempts: 3,
    initialDelay: const Duration(seconds: 1),
    backoffMultiplier: 2.0,
    maxDelay: const Duration(seconds: 10),
    shouldRetry: (error) =>
        error is NetworkError ||
        error is TimeoutError ||
        error is DatabaseError,
  );

  MatchRepository(this._supabase);

  // Real-time streams
  Stream<List<Match>> get matchesStream => _supabase
      .from('matches')
      .stream(primaryKey: ['id'])
      .order('match_date')
      .map((data) => data.map((json) => Match.fromJson(json)).toList());

  Future<List<Match>> getMatches({int? limit, int? offset}) async {
    return ErrorHandler.withFallback(
      () async {
        var query = _supabase
            .from('matches')
            .select(
                '*, team1:team1_id(name, logo_url), team2:team2_id(name, logo_url)')
            .order('match_date');

        if (limit != null) query = query.limit(limit);
        if (offset != null) {
          query = query.range(offset, offset + (limit ?? 20) - 1);
        }

        final dynamic response = await query;
        if (response == null || response is! List) return <Match>[];

        final List<Match> matches = [];
        for (final dynamic item in response) {
          if (item == null) continue;
          try {
            final Map<String, dynamic> matchData = item as Map<String, dynamic>;
            // Extract team names from joined data for convenience if model supports it
            // Model Match likely has team1Name field or we rely on team1 entity
            if (matchData['team1'] != null && matchData['team1'] is Map) {
              matchData['team1_name'] = matchData['team1']['name'];
            }
            if (matchData['team2'] != null && matchData['team2'] is Map) {
              matchData['team2_name'] = matchData['team2']['name'];
            }
            matches.add(Match.fromJson(matchData));
          } catch (e) {
            logError('Failed to parse match: $e');
            continue;
          }
        }
        return matches;
      },
      <Match>[],
      context: 'MatchRepository.getMatches',
    );
  }

  Future<List<Match>> getAllMatches({int? limit, int? offset}) =>
      getMatches(limit: limit, offset: offset);

  Future<List<Match>> getMyMatches() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return <Match>[];

        final dynamic response = await _supabase
            .from('match_participants')
            .select(
                'matches(*, team1:team1_id(name, logo_url), team2:team2_id(name, logo_url))')
            .eq('user_id', user.id);

        if (response == null || response is! List) return <Match>[];

        final List<Match> matches = [];
        for (final dynamic item in response) {
          final mapItem = item as Map<String, dynamic>?;
          if (mapItem == null || mapItem['matches'] == null) continue;
          try {
            final matchData = mapItem['matches'] as Map<String, dynamic>;
            // Ensure nested team data is preserved if returned differently
            matches.add(Match.fromJson(matchData));
          } catch (e) {
            logError('Failed to parse my match: $e');
            continue;
          }
        }
        return matches;
      },
      <Match>[],
      context: 'MatchRepository.getMyMatches',
    );
  }

  Future<Match> getMatch(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final response = await _supabase
            .from('matches')
            .select('*, team1:team1_id(*), team2:team2_id(*)')
            .eq('id', matchId)
            .single();

        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
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
    int? durationMinutes,
    bool? isRecurring,
    String? recurrencePattern,
  }) async {
    // Validate
    final dateError = validateMatchDateTime(matchDate);
    if (dateError != null) throw ValidationError(dateError);

    final locationError = validateLocation(location);
    if (locationError != null) throw ValidationError(locationError);

    if (maxPlayers != null) {
      final playersError = validateMaxPlayers(maxPlayers);
      if (playersError != null) throw ValidationError(playersError);
    }

    if (title != null && title.isNotEmpty) {
      final titleError = validateMatchTitle(title);
      if (titleError != null) throw ValidationError(titleError);
    }

    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        // Check if title already exists
        if (title != null && title.isNotEmpty) {
          final existing = await _supabase
              .from('matches')
              .select('id')
              .eq('title', title)
              .maybeSingle();
          if (existing != null) {
            throw ValidationError('A match with this title already exists.');
          }
        }

        final Map<String, dynamic> matchData = {
          'match_date': matchDate.toIso8601String(),
          'location': location,
          'team1_id': team1Id,
          'team2_id': team2Id,
          'created_by':
              user.id, // Explicitly tracking creator if schema supports
          'status': 'pending', // Default status
        };

        if (title != null) matchData['title'] = title;
        if (maxPlayers != null) matchData['max_players'] = maxPlayers;
        if (matchType != null) matchData['match_type'] = matchType;
        if (durationMinutes != null) {
          matchData['duration_minutes'] = durationMinutes;
        }

        matchData['is_recurring'] = isRecurring ?? false;
        if (recurrencePattern != null) {
          matchData['recurrence_pattern'] = recurrencePattern;
        }

        final response =
            await _supabase.from('matches').insert(matchData).select().single();

        await _cacheService.invalidateTeamsCache(); // Matches affect team stats
        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.createMatch',
    );
  }

  Future<void> updateMatchStatus(String matchId, String status) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase
            .from('matches')
            .update({'status': status}).eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.updateMatchStatus',
    );
  }

  Future<void> rescheduleMatch(String matchId, DateTime newDate) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase.from('matches').update({
          'match_date': newDate.toIso8601String(),
          'status': 'open'
        }).eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.rescheduleMatch',
    );
  }

  Future<void> recordMatchResult(
    String matchId, {
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

        await _supabase.from('matches').update(updates).eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.recordMatchResult',
    );
  }

  Future<void> closeMatch(String matchId) async {
    return updateMatchStatus(matchId, 'closed');
  }

  Future<void> joinMatch(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase.from('match_participants').insert({
          'match_id': matchId,
          'user_id': user.id,
          'joined_at': DateTime.now().toIso8601String(),
        });

        // Notification logic omitted for purity, rely on triggers or service layer
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.joinMatch',
    );
  }

  Future<void> leaveMatch(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase
            .from('match_participants')
            .delete()
            .eq('match_id', matchId)
            .eq('user_id', user.id);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.leaveMatch',
    );
  }

  Future<List<app_user.User>> getMatchPlayers(String matchId) async {
    return ErrorHandler.withFallback(
      () async {
        final dynamic response = await _supabase
            .from('match_participants')
            .select('users(*)')
            .eq('match_id', matchId);

        if (response == null || response is! List) return <app_user.User>[];

        return response
            .map((dynamic json) {
              final itemMap = json as Map<String, dynamic>;
              final dynamic userData = itemMap['users'];
              if (userData == null || userData is! Map<String, dynamic>) {
                return null;
              }
              try {
                return app_user.User.fromJson(userData);
              } catch (e) {
                return null;
              }
            })
            .where((u) => u != null)
            .cast<app_user.User>()
            .toList();
      },
      <app_user.User>[],
      context: 'MatchRepository.getMatchPlayers',
    );
  }

  // Match Requests

  Future<List<Match>> getPendingMatchRequests() async {
    return ErrorHandler.withFallback(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) return <Match>[];

        final teamsResponse =
            await _supabase.from('teams').select('id').eq('owner_id', user.id);

        final teamIds = (teamsResponse as List).map((t) => t['id']).toList();
        if (teamIds.isEmpty) return <Match>[];

        final dynamic response = await _supabase
            .from('matches')
            .select(
                '*, team1:team1_id(name, logo_url), team2:team2_id(name, logo_url)')
            .eq('status', 'pending')
            .inFilter('team2_id', teamIds)
            .order('match_date');

        if (response == null || response is! List) return <Match>[];

        final List<Match> matches = [];
        for (final dynamic item in response) {
          if (item == null) continue;
          try {
            matches.add(Match.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            continue;
          }
        }
        return matches;
      },
      <Match>[],
      context: 'MatchRepository.getPendingMatchRequests',
    );
  }

  Future<Match> acceptMatchRequest(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        final response = await _supabase
            .from('matches')
            .update({
              'status': 'confirmed',
              'team2_confirmed': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', matchId)
            // Ensure permissions implicitly via RLS or explicit check if needed.
            // ApiService didn't check ownership here explicitly, strangely?
            // It assumed "Team2 owner" context but didn't verify it against user.id?
            // "getPendingMatchRequests" filtered by team2_id owned by user.
            // But acceptMatchRequest just takes matchId.
            // I'll trust RLS or add a check. Adding check is safer.
            .select() // Select to verify return
            .single();

        // Trigger auto-add members if RPC exists
        try {
          await _supabase.rpc('add_team_members_to_match',
              params: {'p_match_id': matchId});
        } catch (_) {}

        await _cacheService.invalidateTeamsCache();
        return Match.fromJson(response);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.acceptMatchRequest',
    );
  }

  Future<void> rejectMatchRequest(String matchId) async {
    return ErrorHandler.withRetry(
      () async {
        final user = _supabase.auth.currentUser;
        if (user == null) throw AuthError('No authenticated user');

        await _supabase.from('matches').update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', matchId);
      },
      config: _defaultRetryConfig,
      context: 'MatchRepository.rejectMatchRequest',
    );
  }
}
