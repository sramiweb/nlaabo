import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';
import '../models/team.dart';
import '../models/city.dart';
import '../services/localization_service.dart';
import '../repositories/team_repository.dart';
import '../repositories/user_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/responsive_utils.dart';
import '../widgets/team_card.dart';
import '../widgets/optimized_filter_bar.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  late final TeamService _teamService;
  late final UserService _userService;
  Map<String, Map<String, dynamic>> _teamOwners = {}; // teamId -> owner info
  Map<String, int> _teamMemberCounts = {}; // teamId -> member count
  final Map<String, bool> _ownerLoadingStates =
      {}; // teamId -> is loading owner
  bool _isLoadingCities = true; // Loading state for cities
  bool _isLoadingTeams = false; // Loading state for teams
  String _selectedCity = 'Nador'; // Default city for filtering
  List<City> _availableCities = []; // Available cities fetched from API
  String _selectedAgeGroup = 'All'; // Age filter
  final List<String> _ageGroups = [
    'All',
    '16-20',
    '21-25',
    '26-30',
    '31-35',
    '36+'
  ];
  List<Team> _filteredTeams = []; // Filtered teams to display

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auth token is now handled automatically by Supabase client

      // Initialize repositories and services
      final teamRepository = TeamRepository(Supabase.instance.client);
      final userRepository = UserRepository(Supabase.instance.client);
      _teamService = TeamService(teamRepository);
      _userService = UserService(userRepository);

      // Set UserService for batch operations
      _teamService.setUserService(_userService);

      _loadCities();
      // Load initial data with filters
      _loadTeams();
    });
  }

  Future<void> _loadCities() async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
      });
    }

    try {
      final cities = await _teamService.getCities();
      if (mounted) {
        setState(() {
          _availableCities = cities;
          // Ensure selected city exists in the list, otherwise set to first available
          if (_availableCities.isNotEmpty &&
              !_availableCities.any((city) => city.name == _selectedCity)) {
            _selectedCity = _availableCities.first.name;
          }
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadTeams() async {
    if (mounted) {
      setState(() => _isLoadingTeams = true);
    }

    try {
      final authProvider = context.read<AuthProvider>();
      final allTeams = await _teamService.getAllTeams();

      // Filter teams by selected city and age group
      final teams = allTeams
          .where((team) => team.location == _selectedCity)
          .where((team) => _matchesAgeFilter(team))
          .toList();

      // Sort teams to prioritize user's own teams first
      final userId = authProvider.user?.id;
      teams.sort((a, b) {
        final aIsOwned = a.ownerId == userId;
        final bIsOwned = b.ownerId == userId;
        if (aIsOwned && !bIsOwned) return -1;
        if (!aIsOwned && bIsOwned) return 1;
        return 0; // Keep original order for non-owned teams
      });

      // Set loading states for all teams
      final teamIds = teams.map((team) => team.id).toList();
      if (mounted) {
        setState(() {
          _filteredTeams = teams;
          for (final teamId in teamIds) {
            _ownerLoadingStates[teamId] = true;
          }
        });
      }

      // Use batch API calls for better performance
      final batchData = await _teamService.getTeamDataBatch(teamIds);

      final ownersMap =
          batchData['owners'] as Map<String, Map<String, dynamic>>;
      final memberCountsMap = batchData['memberCounts'] as Map<String, int>;

      if (mounted) {
        setState(() {
          _teamOwners = ownersMap;
          _teamMemberCounts = memberCountsMap;
          _isLoadingTeams = false;
          // Set loading to false for all teams
          for (final teamId in teamIds) {
            _ownerLoadingStates[teamId] = false;
          }
        });
      }
    } catch (e) {
      // Even on error, set loading to false for all teams to prevent stuck loading
      if (mounted) {
        setState(() {
          _ownerLoadingStates.clear(); // Reset all loading states
          _isLoadingTeams = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  void _refreshTeams() {
    _loadTeams();
  }

  Future<void> _retryLoadOwner(String teamId) async {
    if (!mounted) return;

    setState(() {
      _ownerLoadingStates[teamId] = true;
    });

    try {
      final result = await _teamService.processTeamBatch(teamId);
      if (mounted) {
        setState(() {
          _teamOwners[teamId] = result['owner'] as Map<String, dynamic>;
          _teamMemberCounts[teamId] = result['memberCount'] as int;
          _ownerLoadingStates[teamId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ownerLoadingStates[teamId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${LocalizationService().translate('error_loading_owner')}: $e'),
          ),
        );
      }
    }
  }

  bool _matchesAgeFilter(Team team) {
    if (_selectedAgeGroup == 'All') return true;

    // For now, we'll use a simple random distribution since we don't have owner age data
    // In a real app, you'd filter based on team owner's age or team's target age group
    final teamHash = team.id.hashCode;
    final ageCategory = teamHash % 5;

    switch (_selectedAgeGroup) {
      case '16-20':
        return ageCategory == 0;
      case '21-25':
        return ageCategory == 1;
      case '26-30':
        return ageCategory == 2;
      case '31-35':
        return ageCategory == 3;
      case '36+':
        return ageCategory == 4;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final teamProvider = context.watch<TeamProvider>();

    return Scaffold(
      body: Column(
        children: [
          OptimizedFilterBar(
            location: null,
            category: LocalizationService().translate('teams'),
            onRefresh: _refreshTeams,
            onHome: () => context.go('/'),
          ),
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                      '${LocalizationService().translate('city')}: $_selectedCity'),
                  onSelected: (_) => _showCityPicker(context),
                  avatar: const Icon(Icons.location_on, size: 18),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                      '${LocalizationService().translate('age')}: $_selectedAgeGroup'),
                  onSelected: (_) => _showAgePicker(context),
                  avatar: const Icon(Icons.calendar_today, size: 18),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingTeams
                ? const Center(child: CircularProgressIndicator())
                : _filteredTeams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.groups,
                              size: 80,
                              color: Theme.of(
                                context,
                              )
                                  .colorScheme
                                  .onSurface
                                  .withAlpha((0.5 * 255).round()),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${LocalizationService().translate('no_teams_found_in_city')} $_selectedCity',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    )
                                        .colorScheme
                                        .onSurface
                                        .withAlpha((0.7 * 255).round()),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTeams,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth > 1200
                                ? 3
                                : constraints.maxWidth > 800
                                    ? 2
                                    : 1;

                            return GridView.builder(
                              key: const PageStorageKey('teams_grid'),
                              padding: EdgeInsets.only(
                                left: constraints.maxWidth > 600 ? 32 : 16,
                                right: constraints.maxWidth > 600 ? 32 : 16,
                                top: 16,
                                bottom: context.isMobile ? 80 : 16,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: context.isMobile ? 3.0 : 2.5,
                                crossAxisSpacing: context.gridSpacing,
                                mainAxisSpacing: context.gridSpacing,
                              ),
                              itemCount: _filteredTeams.length,
                              itemBuilder: (context, index) {
                                final team = _filteredTeams[index];
                                final isOwner =
                                    authProvider.user?.id == team.ownerId;
                                final ownerInfo = _teamOwners[team.id] ??
                                    {'name': 'غير محدد'};
                                final memberCount =
                                    _teamMemberCounts[team.id] ?? 0;

                                return TeamCard(
                                  key: ValueKey(team.id),
                                  team: team,
                                  ownerInfo: ownerInfo,
                                  memberCount: memberCount,
                                  isOwnerLoading:
                                      _ownerLoadingStates[team.id] ?? false,
                                  onRetry: () => _retryLoadOwner(team.id),
                                  onTap: () => _showTeamDetails(context, team),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: LocalizationService().translate('create_team'),
        hint: 'Create a new team to start organizing matches',
        child: FloatingActionButton(
          onPressed: () => context.push('/create-team'),
          tooltip: LocalizationService().translate('create_team'),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showCityPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService().translate('select_city')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _availableCities.length,
            itemBuilder: (context, index) {
              final city = _availableCities[index];
              return ListTile(
                title: Text(city.name),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _selectedCity = city.name);
                  _loadTeams();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAgePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService().translate('select_age_group')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _ageGroups
              .map((age) => ListTile(
                    title: Text(age),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedAgeGroup = age);
                      _loadTeams();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showTeamDetails(BuildContext context, Team team) {
    context.push('/teams/${team.id}');
  }

  void _showTeamManagement(BuildContext context, Team team) {
    context.push('/teams/${team.id}/manage');
  }

  void _showJoinRequestDialog(BuildContext context, Team team) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${LocalizationService().translate('join_team')} ${team.name}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  LocalizationService().translate('join_request_message_hint')),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: LocalizationService().translate('optional_message'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LocalizationService().translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _teamService.createJoinRequest(
                  team.id,
                  message: messageController.text.trim().isEmpty
                      ? null
                      : messageController.text.trim(),
                );

                if (mounted) {
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        LocalizationService().translate('join_request_sent'),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${LocalizationService().translate('error')}: $e',
                      ),
                    ),
                  );
                }
              }
            },
            child: Text(LocalizationService().translate('send_request')),
          ),
        ],
      ),
    );
  }
}
