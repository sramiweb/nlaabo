import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';
import '../models/match.dart';
import '../services/localization_service.dart';
import '../widgets/enhanced_empty_state.dart';
import '../widgets/match_card.dart' as match_card_widget;
import '../widgets/optimized_filter_bar.dart';
import '../design_system/spacing/app_spacing.dart';
import '../utils/responsive_utils.dart';
import '../constants/responsive_constants.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTime? _selectedDate;
  String _searchQuery = '';
  String _selectedMatchType = 'All';
  final List<String> _matchTypeOptions = ['All', 'Male', 'Female', 'Mixed'];
  String _selectedDuration = 'All';
  final List<String> _durationOptions = ['All', '45 min', '60 min', '90 min', '120 min'];
  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'Pending', 'Confirmed', 'Open', 'Closed', 'Completed', 'Cancelled'];
  final String _selectedLocation = 'All';
  List<String> _locationOptions = ['All'];
  String _selectedCity = 'All';
  List<String> _cityOptions = ['All'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchProvider>().loadAllMatches().then((_) {
        _extractLocations();
      });
    });
  }

  void _extractLocations() {
    final matchProvider = context.read<MatchProvider>();
    final locations = matchProvider.matches.map((m) => m.location).toSet().toList();
    final cities = locations.toSet().toList();
    setState(() {
      _locationOptions = ['All', ...locations];
      _cityOptions = ['All', ...cities];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }

  void _showMatchTypePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Match Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _matchTypeOptions.map((type) => ListTile(
            title: Text(type),
            trailing: _selectedMatchType == type ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _selectedMatchType = type);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDurationPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _durationOptions.map((duration) => ListTile(
            title: Text(duration),
            trailing: _selectedDuration == duration ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _selectedDuration = duration);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statusOptions.map((status) => ListTile(
            title: Text(status),
            trailing: _selectedStatus == status ? const Icon(Icons.check) : null,
            onTap: () {
              Navigator.of(context).pop();
              setState(() => _selectedStatus = status);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select City'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _cityOptions.length,
            itemBuilder: (context, index) {
              final city = _cityOptions[index];
              return ListTile(
                title: Text(city),
                trailing: _selectedCity == city ? const Icon(Icons.check) : null,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _selectedCity = city);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Match match) {
    return match_card_widget.MatchCard(
      match: match,
      onTap: () => context.push('/match/${match.id}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final matchProvider = context.watch<MatchProvider>();
    final hasTeam = authProvider.isAuthenticated;

    List<Match> filteredMatches = matchProvider.matches;
    
    // Status filter
    if (_selectedFilter == 'open') {
      filteredMatches = filteredMatches.where((match) => match.isOpen).toList();
    } else if (_selectedFilter == 'closed') {
      filteredMatches = filteredMatches.where((match) => match.isClosed).toList();
    }

    // Match type filter
    if (_selectedMatchType != 'All') {
      filteredMatches = filteredMatches.where((match) => 
        match.matchType.toLowerCase() == _selectedMatchType.toLowerCase()
      ).toList();
    }

    // Duration filter
    if (_selectedDuration != 'All') {
      final duration = int.parse(_selectedDuration.split(' ')[0]);
      filteredMatches = filteredMatches.where((match) => 
        match.durationMinutes == duration
      ).toList();
    }

    // Status filter (detailed)
    if (_selectedStatus != 'All') {
      filteredMatches = filteredMatches.where((match) => 
        match.status.toLowerCase() == _selectedStatus.toLowerCase()
      ).toList();
    }

    // Location/City filter
    if (_selectedLocation != 'All') {
      filteredMatches = filteredMatches.where((match) => 
        match.location == _selectedLocation
      ).toList();
    }
    
    if (_selectedCity != 'All') {
      filteredMatches = filteredMatches.where((match) => 
        match.location == _selectedCity
      ).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      filteredMatches = filteredMatches.where((match) {
        return match.location.toLowerCase().contains(_searchQuery) ||
               (match.title?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

    // Date filter
    if (_selectedDate != null) {
      filteredMatches = filteredMatches.where((match) {
        return match.matchDate.year == _selectedDate!.year &&
               match.matchDate.month == _selectedDate!.month &&
               match.matchDate.day == _selectedDate!.day;
      }).toList();
    }

    return Scaffold(
      body: Column(
        children: [
          OptimizedFilterBar(
            location: null,
            category: LocalizationService().translate('matches'),
            onRefresh: () => matchProvider.loadAllMatches().then((_) => _extractLocations()),
            onHome: () => context.go('/'),
          ),
          // Filters Row
          Container(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Type: $_selectedMatchType', Icons.sports, () => _showMatchTypePicker(context)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Duration: $_selectedDuration', Icons.timer, () => _showDurationPicker(context)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Status: $_selectedStatus', Icons.info, () => _showStatusPicker(context)),
                  const SizedBox(width: 8),
                  _buildFilterChip('City: $_selectedCity', Icons.location_city, () => _showCityPicker(context)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
          // Search and Date Filter
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: LocalizationService().translate('search_matches'),
                      prefixIcon: Icon(Icons.search, size: ResponsiveUtils.getIconSize(context, 20)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: ResponsiveUtils.getIconSize(context, 20)),
                              onPressed: () => _searchController.clear(),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              tooltip: 'Clear search',
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(context.borderRadius),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(context.borderRadius),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _selectedDate != null ? Icons.event_available : Icons.event,
                      color: _selectedDate != null ? Theme.of(context).colorScheme.primary : null,
                    ),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: 'Select date',
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedDate = null),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    tooltip: 'Clear date filter',
                  ),
              ],
            ),
          ),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Text(LocalizationService().translate('all'), textAlign: TextAlign.center),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = 'all');
                    },
                  ),
                ),
                SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                Expanded(
                  child: FilterChip(
                    label: Text(LocalizationService().translate('open'), textAlign: TextAlign.center),
                    selected: _selectedFilter == 'open',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = 'open');
                    },
                  ),
                ),
                SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                Expanded(
                  child: FilterChip(
                    label: Text(LocalizationService().translate('closed'), textAlign: TextAlign.center),
                    selected: _selectedFilter == 'closed',
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = 'closed');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: matchProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMatches.isEmpty
                 ? EnhancedEmptyState(
                     type: EmptyStateType.noMatches,
                     title: LocalizationService().translate('no_matches_found'),
                     message: _searchQuery.isNotEmpty || _selectedDate != null
                         ? LocalizationService().translate('try_different_filters')
                         : LocalizationService().translate('no_matches_available'),
                     onActionPressed: hasTeam ? () => context.push('/create-match') : null,
                     actionText: hasTeam ? LocalizationService().translate('create_match') : null,
                   )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 1200 ? 3 : constraints.maxWidth > 800 ? 2 : 1;
                      return GridView.builder(
                        padding: EdgeInsets.only(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          top: AppSpacing.lg,
                          bottom: context.isMobile ? 80 : AppSpacing.lg,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: context.isMobile ? 3.0 : 2.5,
                          crossAxisSpacing: context.gridSpacing,
                          mainAxisSpacing: context.gridSpacing,
                        ),
                        itemCount: filteredMatches.length,
                        itemBuilder: (context, index) => _buildMatchCard(filteredMatches[index]),
                      );
                    },
                  ),
          ),
              ],
            ),
          ),
        ],
      ),

      // FAB for creating matches (only if user has a team)
      floatingActionButton: hasTeam
          ? FloatingActionButton(
              onPressed: () => context.push('/create-match'),
              child: const Icon(Icons.add),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
