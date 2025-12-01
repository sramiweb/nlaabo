import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/city.dart';
import '../models/team.dart' as team_models;
import '../models/user.dart' as app_user;
import '../repositories/team_repository.dart';
import '../services/api_service.dart';
import 'base_provider_mixin.dart';

class TeamProvider with ChangeNotifier, BaseProviderMixin {
  final TeamRepository _teamRepository;
  final ApiService _apiService;

  List<Team> _teams = [];
  List<Team> _userTeams = [];

  TeamProvider(this._teamRepository, this._apiService) {
    _initializeRealtimeUpdates();
  }

  List<Team> get teams => _teams;
  List<Team> get userTeams => _userTeams;

  void _initializeRealtimeUpdates() {
    _apiService.teamsStream.listen(
      (teams) {
        if (!disposed) {
          _teams = teams;
          clearError();
          notifyListeners();
        }
      },
      onError: (error) {
        handleStreamError(error, loadTeams);
      },
    );

    _apiService.userTeamsStream.listen(
      (userTeams) {
        if (!disposed) {
          _userTeams = userTeams;
          clearError();
          notifyListeners();
        }
      },
      onError: (error) {
        handleStreamError(error, loadUserTeams);
      },
    );
  }

  Future<void> loadTeams() async {
    _teams = await executeAsync(() => _teamRepository.getAllTeams());
    if (!disposed) notifyListeners();
  }

  Future<void> loadUserTeams() async {
    _userTeams = await executeAsync(() => _teamRepository.getUserTeams());
    if (!disposed) notifyListeners();
  }

  Future<void> createTeam(
    String name, {
    String? location,
    int? numberOfPlayers,
    String? description,
    String? logo,
    bool? isRecruiting,
  }) async {
    await executeAsync(
      () => _teamRepository.createTeam(
        name,
        location: location,
        numberOfPlayers: numberOfPlayers,
        description: description,
        logo: logo,
        isRecruiting: isRecruiting,
      ),
    );
    await loadUserTeams();
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
    try {
      await _teamRepository.toggleTeamRecruiting(teamId);
      await loadTeams();
      await loadUserTeams();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
    try {
      await _teamRepository.deleteTeam(teamId, reason: reason);
      await loadTeams();
      await loadUserTeams();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<List<Team>> searchTeams(String query) async {
    try {
      return await _teamRepository.searchTeams(query);
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<List<City>> getCities() async {
    try {
      return await _teamRepository.getCities();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<Team> getTeam(String teamId) async {
    try {
      return await _teamRepository.getTeam(teamId);
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    try {
      return await _teamRepository.getTeamMembers(teamId);
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(String teamId) async {
    try {
      return await _teamRepository.getTeamJoinRequests(teamId);
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<team_models.TeamJoinRequest> createJoinRequest(
    String teamId, {
    String? message,
  }) async {
    try {
      return await _teamRepository.createJoinRequest(teamId, message: message);
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<team_models.TeamJoinRequest> updateJoinRequestStatus(
    String teamId,
    String requestId,
    String status,
  ) async {
    try {
      return await _teamRepository.updateJoinRequestStatus(teamId, requestId, status);
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
    try {
      return await _teamRepository.getMyJoinRequests();
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
    try {
      await _teamRepository.cancelJoinRequest(teamId, requestId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }

  Future<void> leaveTeam(String teamId) async {
    try {
      await _teamRepository.leaveTeam(teamId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      setError(e.toString());
      rethrow;
    }
  }


}
