import 'package:flutter/material.dart';
import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../services/api_service.dart';
import 'base_provider_mixin.dart';

class MatchProvider with ChangeNotifier, BaseProviderMixin {
  final MatchRepository _matchRepository;
  final ApiService _apiService;

  List<Match> _matches = [];

  MatchProvider(this._matchRepository, this._apiService) {
    _initializeRealtimeUpdates();
  }

  List<Match> get matches => _matches;

  void _initializeRealtimeUpdates() {
    _apiService.matchesStream.listen(
      (matches) {
        if (!disposed) {
          _matches = removeDuplicates(matches, (m) => m.id);
          clearError();
          notifyListeners();
        }
      },
      onError: (error) {
        handleStreamError(error, loadAllMatches);
      },
    );
  }

  Future<void> loadMatches() async {
    _matches = await executeAsync(
      () async {
        final matches = await _matchRepository.getMatches();
        return removeDuplicates(matches, (m) => m.id);
      },
    );
    if (!disposed) notifyListeners();
  }

  Future<void> loadAllMatches() async {
    _matches = await executeAsync(
      () async {
        final matches = await _matchRepository.getAllMatches();
        return removeDuplicates(matches, (m) => m.id);
      },
    );
    if (!disposed) notifyListeners();
  }

  Future<void> createMatch({
    required String team1Id,
    required String team2Id,
    required DateTime matchDate,
    required String location,
    String? title,
    int? maxPlayers,
    String? matchType,
  }) async {
    await executeAsync(
      () => _matchRepository.createMatch(
        team1Id: team1Id,
        team2Id: team2Id,
        matchDate: matchDate,
        location: location,
        title: title,
        maxPlayers: maxPlayers,
        matchType: matchType,
      ),
    );
  }

  Future<void> joinMatch(String matchId) async {
    await executeAsync(
      () => _matchRepository.joinMatch(matchId),
      setLoadingState: false,
    );
  }

  Future<void> leaveMatch(String matchId) async {
    await executeAsync(
      () => _matchRepository.leaveMatch(matchId),
      setLoadingState: false,
    );
  }
}
