import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/city.dart';
import '../models/team.dart' as team_models;
import '../models/user.dart' as app_user;
import '../repositories/team_repository.dart';
import '../services/api_service.dart';

class TeamProvider with ChangeNotifier {
  final TeamRepository _teamRepository;
  final ApiService _apiService;

  List<Team> _teams = [];
  List<Team> _userTeams = [];
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  TeamProvider(this._teamRepository, this._apiService) {
    _initializeRealtimeUpdates();
  }

  List<Team> get teams => _teams;
  List<Team> get userTeams => _userTeams;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _initializeRealtimeUpdates() {
    // Listen to all teams changes
    _apiService.teamsStream.listen(
      (teams) {
        if (!_disposed) {
          _teams = teams;
          _isLoading = false;
          _error = null;
          notifyListeners();
        }
      },
      onError: (error) {
        if (!_disposed) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        }
      },
    ).onDone(() {
      if (!_disposed) {
        _error = 'Connection lost. Attempting to reconnect...';
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          if (!_disposed && _teams.isEmpty) {
            loadTeams();
          }
        });
      }
    });

    // Listen to user-specific teams changes
    _apiService.userTeamsStream.listen(
      (userTeams) {
        if (!_disposed) {
          _userTeams = userTeams;
          _isLoading = false;
          _error = null;
          notifyListeners();
        }
      },
      onError: (error) {
        if (!_disposed) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        }
      },
    ).onDone(() {
      if (!_disposed) {
        _error = 'Connection lost. Attempting to reconnect...';
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          if (!_disposed && _userTeams.isEmpty) {
            loadUserTeams();
          }
        });
      }
    });
  }

  Future<void> loadTeams() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final teams = await _teamRepository.getAllTeams();
      if (_disposed) return;
      _teams = teams;
      _error = null;
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadUserTeams() async {
    if (_disposed) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userTeams = await _teamRepository.getUserTeams();
      if (_disposed) return;
      _userTeams = userTeams;
      _error = null;
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> createTeam(
    String name, {
    String? location,
    int? numberOfPlayers,
    String? description,
    String? logo,
    bool? isRecruiting,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _teamRepository.createTeam(
        name,
        location: location,
        numberOfPlayers: numberOfPlayers,
        description: description,
        logo: logo,
        isRecruiting: isRecruiting,
      );
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleTeamRecruiting(String teamId) async {
    try {
      await _teamRepository.toggleTeamRecruiting(teamId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTeam(String teamId, {String? reason}) async {
    try {
      await _teamRepository.deleteTeam(teamId, reason: reason);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<Team>> searchTeams(String query) async {
    try {
      return await _teamRepository.searchTeams(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<City>> getCities() async {
    try {
      return await _teamRepository.getCities();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<Team> getTeam(String teamId) async {
    try {
      return await _teamRepository.getTeam(teamId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<app_user.User>> getTeamMembers(String teamId) async {
    try {
      return await _teamRepository.getTeamMembers(teamId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<team_models.TeamJoinRequest>> getTeamJoinRequests(String teamId) async {
    try {
      return await _teamRepository.getTeamJoinRequests(teamId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
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
      _error = e.toString();
      notifyListeners();
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
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<List<team_models.TeamJoinRequest>> getMyJoinRequests() async {
    try {
      return await _teamRepository.getMyJoinRequests();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelJoinRequest(String teamId, String requestId) async {
    try {
      await _teamRepository.cancelJoinRequest(teamId, requestId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leaveTeam(String teamId) async {
    try {
      await _teamRepository.leaveTeam(teamId);
      // Real-time updates will handle the UI refresh
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Clean up real-time subscriptions to prevent memory leaks
    _apiService.teamsStream.drain();
    _apiService.userTeamsStream.drain();
    super.dispose();
  }
}
