import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../models/user.dart' as app_user;
import '../services/api_service.dart';
import '../utils/app_logger.dart';
import '../constants/home_constants.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService;

  bool _isDisposed = false;

  List<Match> _allMatches = [];
  List<Team> _allTeams = [];
  List<Match> _featuredMatches = [];
  List<Team> _featuredTeams = [];
  bool _isLoading = true;
  bool _isUserInTeam = false;
  String _searchQuery = '';
  String? _errorMessage;
  late TextEditingController _searchController;

  // Getters
  List<Match> get allMatches => _allMatches;
  List<Team> get allTeams => _allTeams;
  List<Match> get featuredMatches => _featuredMatches;
  List<Team> get featuredTeams => _featuredTeams;
  bool get isLoading => _isLoading;
  bool get isUserInTeam => _isUserInTeam;
  String get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;
  TextEditingController get searchController => _searchController;

  HomeProvider({ApiService? apiService})
      : _apiService = apiService ?? ApiService() {
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _notifyIfNotDisposed() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    try {
      _errorMessage = null;
      _isLoading = true;
      _notifyIfNotDisposed();

      // Load fresh data from API with fallback
      try {
        logDebug('HomeProvider: Fetching matches and teams...');
        final matches = await _apiService.getMatches();
        final teams = await _apiService.getAllTeams();

        // Check if disposed before updating state
        if (_isDisposed) return;

        _allMatches = matches;
        _allTeams = teams;

        logDebug(
            'HomeProvider: Fetched ${_allMatches.length} matches, ${_allTeams.length} teams');

        // Show error if both are empty
        if (_allMatches.isEmpty && _allTeams.isEmpty) {
          _errorMessage =
              'No matches or teams available. Create your first team or match to get started!';
          logWarning('HomeProvider: Database appears empty');
        }
      } catch (apiError) {
        logError('HomeProvider: API call failed: $apiError');
        _errorMessage =
            'Failed to load data. Please check your connection and try again.';
        _allMatches = [];
        _allTeams = [];
      }

      // Check if disposed before final updates
      if (_isDisposed) return;

      _isLoading = false;
      _filterContent();
      _notifyIfNotDisposed();
    } catch (e) {
      logError('HomeProvider.loadData error: $e');
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _allMatches = [];
      _allTeams = [];
      _isLoading = false;
      _filterContent();
      _notifyIfNotDisposed();
    }
  }

  Future<void> checkUserTeamMembership(app_user.User? user) async {
    if (user == null) {
      _isUserInTeam = false;
    } else {
      try {
        // Use already loaded _allTeams data instead of making another API call
        _isUserInTeam = _allTeams.any((team) => team.ownerId == user.id);
      } catch (e) {
        _isUserInTeam = false;
      }
    }
    _notifyIfNotDisposed();
  }

  void _onSearchChanged() {
    updateSearchQuery(_searchController.text);
  }

  void clearSearchController() {
    _searchController.clear();
    updateSearchQuery('');
  }

  void updateSearchQuery(String query) {
    // Sanitize and validate search input
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.length > HomeConstants.maxSearchQueryLength) {
      // Limit search query length to prevent abuse
      return;
    }

    // Basic validation - only allow alphanumeric characters, spaces, and common punctuation
    final validPattern = RegExp(HomeConstants.searchValidationPattern);
    if (sanitizedQuery.isNotEmpty && !validPattern.hasMatch(sanitizedQuery)) {
      // Invalid characters in search query - silently ignore
      return;
    }

    _searchQuery = sanitizedQuery;
    _filterContent();
    _notifyIfNotDisposed();
  }

  void clearSearch() {
    _searchQuery = '';
    _filterContent();
    _notifyIfNotDisposed();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }

  void _filterContent() {
    if (_searchQuery.isEmpty) {
      // Remove duplicates based on match ID (primary key)
      final seenMatchIds = <String>{};
      _featuredMatches = _allMatches
          .where((match) {
            if (seenMatchIds.contains(match.id)) return false;
            seenMatchIds.add(match.id);
            return true;
          })
          .take(HomeConstants.featuredItemsCount)
          .toList();

      final seenTeamIds = <String>{};
      _featuredTeams = _allTeams
          .where((team) {
            if (seenTeamIds.contains(team.id)) return false;
            seenTeamIds.add(team.id);
            return true;
          })
          .take(HomeConstants.featuredItemsCount)
          .toList();
    } else {
      final query = _searchQuery.toLowerCase();
      final filteredMatches = _allMatches.where((match) {
        return match.title?.toLowerCase().contains(query) == true ||
            match.location.toLowerCase().contains(query);
      }).toList();

      final filteredTeams = _allTeams.where((team) {
        return team.name.toLowerCase().contains(query) ||
            team.location?.toLowerCase().contains(query) == true;
      }).toList();

      // Remove duplicates from search results
      final seenMatchIds = <String>{};
      _featuredMatches = filteredMatches
          .where((match) {
            if (seenMatchIds.contains(match.id)) return false;
            seenMatchIds.add(match.id);
            return true;
          })
          .take(HomeConstants.maxSearchResults)
          .toList();

      final seenTeamIds = <String>{};
      _featuredTeams = filteredTeams
          .where((team) {
            if (seenTeamIds.contains(team.id)) return false;
            seenTeamIds.add(team.id);
            return true;
          })
          .take(HomeConstants.maxSearchResults)
          .toList();
    }
  }
}
