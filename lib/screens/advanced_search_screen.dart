import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/match.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../widgets/directional_icon.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  
  List<Match> _matchResults = [];
  List<Team> _teamResults = [];
  bool _isLoading = false;
  String _searchType = 'all';

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_searchType == 'all' || _searchType == 'matches') {
        final matches = await _apiService.getMatches();
        _matchResults = matches
            .where((m) => m.location.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                (m.team1Name?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false))
            .toList();
      }
      if (_searchType == 'all' || _searchType == 'teams') {
        final teams = await _apiService.searchTeams(_searchController.text);
        _teamResults = teams;
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('advanced_search')),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: LocalizationService().translate('search_matches_teams'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _matchResults = [];
                                _teamResults = [];
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'all', label: Text(LocalizationService().translate('all_results'))),
                          ButtonSegment(value: 'matches', label: Text(LocalizationService().translate('matches_only'))),
                          ButtonSegment(value: 'teams', label: Text(LocalizationService().translate('teams_only'))),
                        ],
                        selected: {_searchType},
                        onSelectionChanged: (value) {
                          setState(() => _searchType = value.first);
                          _search();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _matchResults.isEmpty && _teamResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty 
                            ? LocalizationService().translate('search_hint')
                            : LocalizationService().translate('no_results_found'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_matchResults.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(LocalizationService().translate('matches'), style: Theme.of(context).textTheme.titleMedium),
                              ),
                              ..._matchResults.map((match) => ListTile(
                                title: Text('${match.team1Name} vs ${match.team2Name}'),
                                subtitle: Text(match.location),
                                onTap: () => context.push('/match/${match.id}'),
                              )),
                            ],
                            if (_teamResults.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(LocalizationService().translate('teams'), style: Theme.of(context).textTheme.titleMedium),
                              ),
                              ..._teamResults.map((team) => ListTile(
                                title: Text(team.name),
                                subtitle: Text(team.location ?? 'No location'),
                                onTap: () => context.push('/teams/${team.id}'),
                              )),
                            ],
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
