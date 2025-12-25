import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/team.dart';
import '../utils/validators.dart';
import '../widgets/enhanced_form_field.dart';
import '../widgets/required_field_indicator.dart';
import '../widgets/directional_icon.dart';
import '../design_system/colors/app_colors_extensions.dart';
import '../utils/responsive_utils.dart';
import '../constants/responsive_constants.dart';
import '../utils/orientation_helper.dart';

class CreateMatchScreen extends StatefulWidget {
  final String? preselectedTeam1Id;

  const CreateMatchScreen({super.key, this.preselectedTeam1Id});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final ApiService _apiService = ApiService();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  String? _selectedTeam1Id;
  String? _selectedTeam2Id;
  String _selectedMatchType = 'male';
  int _totalPlayers = 22;
  int _durationMinutes = 90;
  bool _isRecurring = false;
  String? _recurrencePattern;
  List<Team> _allTeams = [];
  Map<String, int> _teamMemberCounts = {};
  bool _isLoading = false;
  bool _isLoadingTeams = true;
  // Local form submitting flag to prevent duplicate submissions.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTeam1Id = widget.preselectedTeam1Id;
    _loadAllTeams();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllTeams() async {
    try {
      final teams = await _apiService.getAllTeams();
      final teamIds = teams.map((t) => t.id).toList();
      final memberCounts = await _apiService.getTeamMemberCounts(teamIds);

      setState(() {
        _allTeams = teams;
        _teamMemberCounts = memberCounts;
        _isLoadingTeams = false;
      });
    } catch (error) {
      setState(() => _isLoadingTeams = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('failed_to_load_teams')}: $error',
            ),
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<List<Team>> _getAvailableTeamsForTeam2() async {
    if (_selectedTeam1Id == null) return _allTeams;

    final team1MemberCount = _teamMemberCounts[_selectedTeam1Id];
    if (team1MemberCount == null) return _allTeams;

    final matchDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final availableTeams = <Team>[];
    for (final team in _allTeams) {
      if (team.id == _selectedTeam1Id) continue;

      final teamMemberCount = _teamMemberCounts[team.id];
      if (teamMemberCount != team1MemberCount) continue;

      final isAvailable =
          await _apiService.isTeamAvailableAtTime(team.id, matchDateTime);
      if (isAvailable) {
        availableTeams.add(team);
      }
    }

    return availableTeams;
  }

  Future<void> _createMatch() async {
    // Synchronous form validation first.
    if (!_formKey.currentState!.validate()) return;

    // Additional null checks for team selections
    if (_selectedTeam1Id == null || _selectedTeam1Id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate('team_1_required'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTeam2Id == null || _selectedTeam2Id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate('team_2_required'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTeam1Id == _selectedTeam2Id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate('teams_must_be_different'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final matchDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Validate date/time using shared validator (returns localized error key if invalid).
    final dateError = validateMatchDateTime(matchDateTime);
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dateError), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      // Auth token is now handled automatically by Supabase client

      await _apiService.createMatch(
        team1Id: _selectedTeam1Id!,
        team2Id: _selectedTeam2Id!,
        matchDate: matchDateTime,
        location: _locationController.text.trim(),
        title: _titleController.text.trim(),
        maxPlayers: _totalPlayers,
        matchType: _selectedMatchType,
        durationMinutes: _durationMinutes,
        isRecurring: _isRecurring,
        recurrencePattern: _recurrencePattern,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('match_created_successfully'),
            ),
          ),
        );
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('error')}: $error',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('create_match')),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: ResponsiveUtils.getResponsiveHorizontalPadding(context)
                    .left,
                right: ResponsiveUtils.getResponsiveHorizontalPadding(context)
                    .right,
                top: ResponsiveConstants.getResponsiveSpacing(context, 'xl'),
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    ResponsiveConstants.getResponsiveSpacing(context, 'xl'),
              ),
              child: _isLoadingTeams
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading teams...'),
                      ],
                    )
                  : _allTeams.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.group_off,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              LocalizationService()
                                  .translate('no_teams_available'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LocalizationService()
                                  .translate('create_teams_first_message'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/teams/create'),
                              icon: const Icon(Icons.add),
                              label: Text(LocalizationService()
                                      .translate('create_team') ??
                                  'Create Team'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Enhanced Header
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withValues(alpha: 0.05),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.sports_soccer,
                                          size: 40,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        LocalizationService()
                                            .translate('create_match'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        LocalizationService()
                                            .translate('set_up_new_match'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Enhanced Form Section
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            LocalizationService()
                                                .translate('match_information'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'md')),

                                      OrientationHelper.buildFormFieldLayout(
                                        context: context,
                                        fields: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${LocalizationService().translate('match_title')} ${RequiredFieldIndicator.text}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context
                                                          .colors.textPrimary,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(
                                                  height: ResponsiveConstants
                                                      .getResponsiveSpacing(
                                                          context, 'xs2')),
                                              EnhancedFormField(
                                                controller: _titleController,
                                                labelText: LocalizationService()
                                                    .translate('match_title'),
                                                hintText: LocalizationService()
                                                    .translate(
                                                        'enter_match_title'),
                                                prefixIcon: Icon(Icons.title,
                                                    color:
                                                        context.colors.primary),
                                                validator: (value) =>
                                                    validateMatchTitle(value),
                                                showValidationFeedback: true,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${LocalizationService().translate('location')} ${RequiredFieldIndicator.text}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context
                                                          .colors.textPrimary,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(
                                                  height: ResponsiveConstants
                                                      .getResponsiveSpacing(
                                                          context, 'xs2')),
                                              EnhancedFormField(
                                                controller: _locationController,
                                                labelText: LocalizationService()
                                                    .translate('location'),
                                                hintText: LocalizationService()
                                                    .translate(
                                                        'enter_location'),
                                                prefixIcon: Icon(
                                                    Icons.location_on,
                                                    color:
                                                        context.colors.primary),
                                                validator: (value) =>
                                                    validateLocation(value),
                                                showValidationFeedback: true,
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${LocalizationService().translate('team_1')} ${RequiredFieldIndicator.text}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context
                                                          .colors.textPrimary,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(
                                                  height: ResponsiveConstants
                                                      .getResponsiveSpacing(
                                                          context, 'xs2')),
                                              Container(
                                                height: ResponsiveUtils
                                                    .getButtonHeight(context),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          context.borderRadius),
                                                  border: Border.all(
                                                      color:
                                                          context.colors.border,
                                                      width: 1),
                                                ),
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  initialValue:
                                                      _selectedTeam1Id,
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        LocalizationService()
                                                            .translate(
                                                                'team_1'),
                                                    border: InputBorder.none,
                                                    prefixIcon: Icon(
                                                        Icons.group,
                                                        color: context
                                                            .colors.primary),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          ResponsiveConstants
                                                              .getResponsiveSpacing(
                                                                  context,
                                                                  'lg'),
                                                      vertical: ResponsiveConstants
                                                          .getResponsiveSpacing(
                                                              context, 'md'),
                                                    ),
                                                  ),
                                                  items: _allTeams.map((team) {
                                                    return DropdownMenuItem(
                                                      value: team.id,
                                                      child: Text(team.name,
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodyMedium),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) =>
                                                      setState(() =>
                                                          _selectedTeam1Id =
                                                              value),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return LocalizationService()
                                                          .translate(
                                                              'team_1_required');
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${LocalizationService().translate('team_2')} ${RequiredFieldIndicator.text}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: context
                                                          .colors.textPrimary,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(
                                                  height: ResponsiveConstants
                                                      .getResponsiveSpacing(
                                                          context, 'xs2')),
                                              Container(
                                                height: ResponsiveUtils
                                                    .getButtonHeight(context),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          context.borderRadius),
                                                  border: Border.all(
                                                      color:
                                                          context.colors.border,
                                                      width: 1),
                                                ),
                                                child:
                                                    FutureBuilder<List<Team>>(
                                                  future:
                                                      _getAvailableTeamsForTeam2(),
                                                  builder: (context, snapshot) {
                                                    final availableTeams =
                                                        snapshot.data ??
                                                            _allTeams;
                                                    return DropdownButtonFormField<
                                                        String>(
                                                      initialValue: availableTeams
                                                              .any((t) =>
                                                                  t.id ==
                                                                  _selectedTeam2Id)
                                                          ? _selectedTeam2Id
                                                          : null,
                                                      decoration:
                                                          InputDecoration(
                                                        labelText:
                                                            LocalizationService()
                                                                .translate(
                                                                    'team_2'),
                                                        border:
                                                            InputBorder.none,
                                                        prefixIcon: Icon(
                                                            Icons.group,
                                                            color: context
                                                                .colors
                                                                .primary),
                                                        contentPadding:
                                                            EdgeInsets
                                                                .symmetric(
                                                          horizontal:
                                                              ResponsiveConstants
                                                                  .getResponsiveSpacing(
                                                                      context,
                                                                      'lg'),
                                                          vertical:
                                                              ResponsiveConstants
                                                                  .getResponsiveSpacing(
                                                                      context,
                                                                      'md'),
                                                        ),
                                                      ),
                                                      items: availableTeams
                                                          .map((team) {
                                                        final memberCount =
                                                            _teamMemberCounts[
                                                                    team.id] ??
                                                                0;
                                                        return DropdownMenuItem(
                                                          value: team.id,
                                                          child: Text(
                                                              '${team.name} ($memberCount)',
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyMedium),
                                                        );
                                                      }).toList(),
                                                      onChanged: (value) =>
                                                          setState(() =>
                                                              _selectedTeam2Id =
                                                                  value),
                                                      validator: (value) {
                                                        if (value == null ||
                                                            value.isEmpty) {
                                                          return LocalizationService()
                                                              .translate(
                                                                  'team_2_required');
                                                        }
                                                        return null;
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'sm2')),

                                      Text(
                                        '${LocalizationService().translate('max_players')} ${RequiredFieldIndicator.text}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.textPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'xs2')),
                                      Container(
                                        height: ResponsiveUtils.getButtonHeight(
                                            context),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              context.borderRadius),
                                          border: Border.all(
                                            color: context.colors.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: DropdownButtonFormField<int>(
                                          initialValue: _totalPlayers,
                                          decoration: InputDecoration(
                                            labelText: LocalizationService()
                                                .translate(
                                                    'number_of_players_required'),
                                            border: InputBorder.none,
                                            prefixIcon: Icon(Icons.people,
                                                color: context.colors.primary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'lg'),
                                              vertical: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'md'),
                                            ),
                                          ),
                                          items: [10, 11, 15, 18, 22, 25, 30]
                                              .map((players) {
                                            return DropdownMenuItem(
                                              value: players,
                                              child: Text(
                                                  '$players ${LocalizationService().translate('players')}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium),
                                            );
                                          }).toList(),
                                          onChanged: (value) => setState(() =>
                                              _totalPlayers = value ?? 22),
                                          validator: (value) =>
                                              validateMaxPlayers(value),
                                        ),
                                      ),

                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'sm2')),

                                      Text(
                                        '${LocalizationService().translate('match_type')} ${RequiredFieldIndicator.text}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.textPrimary,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'xs2')),
                                      Container(
                                        height: ResponsiveUtils.getButtonHeight(
                                            context),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              context.borderRadius),
                                          border: Border.all(
                                            color: context.colors.border,
                                            width: 1,
                                          ),
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          initialValue: _selectedMatchType,
                                          decoration: InputDecoration(
                                            labelText: LocalizationService()
                                                .translate('match_type'),
                                            border: InputBorder.none,
                                            prefixIcon: Icon(Icons.group_work,
                                                color: context.colors.primary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'lg'),
                                              vertical: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'md'),
                                            ),
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                                value: 'mixed',
                                                child: Text(
                                                    LocalizationService()
                                                        .translate('mixed'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium)),
                                            DropdownMenuItem(
                                                value: 'male',
                                                child: Text(
                                                    LocalizationService()
                                                        .translate('male'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium)),
                                            DropdownMenuItem(
                                                value: 'female',
                                                child: Text(
                                                    LocalizationService()
                                                        .translate('female'),
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium)),
                                          ],
                                          onChanged: (value) => setState(() =>
                                              _selectedMatchType =
                                                  value ?? 'mixed'),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return LocalizationService()
                                                  .translate(
                                                      'match_type_required');
                                            }
                                            return null;
                                          },
                                        ),
                                      ),

                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'sm2')),

                                      Text(
                                        'Match Recurrence',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.textPrimary,
                                            ),
                                      ),
                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'xs2')),
                                      Container(
                                        height: ResponsiveUtils.getButtonHeight(
                                            context),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              context.borderRadius),
                                          border: Border.all(
                                              color: context.colors.border,
                                              width: 1),
                                        ),
                                        child: DropdownButtonFormField<bool>(
                                          initialValue: _isRecurring,
                                          decoration: InputDecoration(
                                            labelText: 'One-time or Recurring',
                                            border: InputBorder.none,
                                            prefixIcon: Icon(Icons.repeat,
                                                color: context.colors.primary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'lg'),
                                              vertical: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'md'),
                                            ),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                                value: false,
                                                child: Text('One-time')),
                                            DropdownMenuItem(
                                                value: true,
                                                child: Text('Recurring')),
                                          ],
                                          onChanged: (value) => setState(() {
                                            _isRecurring = value ?? false;
                                            if (!_isRecurring)
                                              _recurrencePattern = null;
                                          }),
                                        ),
                                      ),

                                      if (_isRecurring) ...[
                                        SizedBox(
                                            height: ResponsiveConstants
                                                .getResponsiveSpacing(
                                                    context, 'sm2')),
                                        Text(
                                          'Recurrence Pattern',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    context.colors.textPrimary,
                                              ),
                                        ),
                                        SizedBox(
                                            height: ResponsiveConstants
                                                .getResponsiveSpacing(
                                                    context, 'xs2')),
                                        Container(
                                          height:
                                              ResponsiveUtils.getButtonHeight(
                                                  context),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                context.borderRadius),
                                            border: Border.all(
                                                color: context.colors.border,
                                                width: 1),
                                          ),
                                          child:
                                              DropdownButtonFormField<String>(
                                            initialValue: _recurrencePattern,
                                            decoration: InputDecoration(
                                              labelText: 'Pattern',
                                              border: InputBorder.none,
                                              prefixIcon: Icon(
                                                  Icons.calendar_month,
                                                  color:
                                                      context.colors.primary),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                horizontal: ResponsiveConstants
                                                    .getResponsiveSpacing(
                                                        context, 'lg'),
                                                vertical: ResponsiveConstants
                                                    .getResponsiveSpacing(
                                                        context, 'md'),
                                              ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                  value: 'daily',
                                                  child: Text('Daily')),
                                              DropdownMenuItem(
                                                  value: 'weekly',
                                                  child: Text('Weekly')),
                                              DropdownMenuItem(
                                                  value: 'monthly',
                                                  child: Text('Monthly')),
                                            ],
                                            onChanged: (value) => setState(() =>
                                                _recurrencePattern = value),
                                          ),
                                        ),
                                      ],

                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'sm2')),

                                      Text(
                                        'Duration ${RequiredFieldIndicator.text}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.textPrimary,
                                            ),
                                      ),
                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'xs2')),
                                      Container(
                                        height: ResponsiveUtils.getButtonHeight(
                                            context),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              context.borderRadius),
                                          border: Border.all(
                                              color: context.colors.border,
                                              width: 1),
                                        ),
                                        child: DropdownButtonFormField<int>(
                                          initialValue: _durationMinutes,
                                          decoration: InputDecoration(
                                            labelText: 'Duration (minutes)',
                                            border: InputBorder.none,
                                            prefixIcon: Icon(Icons.timer,
                                                color: context.colors.primary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'lg'),
                                              vertical: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'md'),
                                            ),
                                          ),
                                          items:
                                              [45, 60, 90, 120].map((minutes) {
                                            return DropdownMenuItem(
                                                value: minutes,
                                                child: Text('$minutes min'));
                                          }).toList(),
                                          onChanged: (value) => setState(() =>
                                              _durationMinutes = value ?? 90),
                                        ),
                                      ),

                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'sm2')),

                                      Text(
                                        '${LocalizationService().translate('match_date')} & ${LocalizationService().translate('match_time')} ${RequiredFieldIndicator.text}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: context.colors.textPrimary,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'xs2')),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _selectDate(context),
                                              child: Container(
                                                height: ResponsiveUtils
                                                    .getButtonHeight(context),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          context.borderRadius),
                                                  border: Border.all(
                                                    color:
                                                        context.colors.border,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        LocalizationService()
                                                            .translate(
                                                                'match_date'),
                                                    prefixIcon: Icon(
                                                        Icons.calendar_today,
                                                        color: context
                                                            .colors.primary),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          ResponsiveConstants
                                                              .getResponsiveSpacing(
                                                                  context,
                                                                  'lg'),
                                                      vertical: ResponsiveConstants
                                                          .getResponsiveSpacing(
                                                              context, 'md'),
                                                    ),
                                                  ),
                                                  child: Text(
                                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium),
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                              width: ResponsiveConstants
                                                  .getResponsiveSpacing(
                                                      context, 'md')),
                                          Expanded(
                                            child: InkWell(
                                              onTap: () => _selectTime(context),
                                              child: Container(
                                                height: ResponsiveUtils
                                                    .getButtonHeight(context),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          context.borderRadius),
                                                  border: Border.all(
                                                    color:
                                                        context.colors.border,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    labelText:
                                                        LocalizationService()
                                                            .translate(
                                                                'match_time'),
                                                    prefixIcon: Icon(
                                                        Icons.access_time,
                                                        color: context
                                                            .colors.primary),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal:
                                                          ResponsiveConstants
                                                              .getResponsiveSpacing(
                                                                  context,
                                                                  'lg'),
                                                      vertical: ResponsiveConstants
                                                          .getResponsiveSpacing(
                                                              context, 'md'),
                                                    ),
                                                  ),
                                                  child: Text(
                                                      _selectedTime
                                                          .format(context),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                          height: ResponsiveConstants
                                              .getResponsiveSpacing(
                                                  context, 'lg')),

                                      // Enhanced Create Button
                                      SizedBox(
                                        width: double.infinity,
                                        height: ResponsiveUtils.getButtonHeight(
                                            context),
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              (_isLoading || _isSubmitting)
                                                  ? null
                                                  : _createMatch,
                                          icon: _isLoading || _isSubmitting
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white),
                                                )
                                              : const Icon(Icons.sports_soccer),
                                          label: Text(LocalizationService()
                                              .translate('create_match')),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                context.colors.primary,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      context.borderRadius),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
