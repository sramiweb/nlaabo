import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/team_service.dart';
import '../services/web_team_service.dart';
import '../services/localization_service.dart';
import '../utils/validators.dart';
import '../models/city.dart';
import '../repositories/team_repository.dart';
import '../widgets/directional_icon.dart';

import '../widgets/enhanced_form_field.dart';
import '../constants/form_constants.dart';
import '../utils/design_system.dart';
import '../utils/responsive_utils.dart';
import '../widgets/required_field_indicator.dart';
import '../design_system/colors/app_colors_extensions.dart';

class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  TeamService? _teamService;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  City? _selectedCity; // Selected city object
  int _numberOfPlayers = 11;
  bool _isRecruiting = false;
  String _gender = 'mixed';
  int? _minAge;
  int? _maxAge;
  bool _isLoading = false;
  bool _isLoadingCities = true; // Loading state for cities
  // Local submitting flag to prevent duplicate submissions and disable button while submitting.
  bool _isSubmitting = false;

  // Available cities fetched from API
  List<City> _availableCities = [];

  // Focus management
  late final FocusNode _nameFocusNode;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _cityFocusNode;
  late final FocusNode _playersFocusNode;

  @override
  void initState() {
    super.initState();

    // Initialize focus nodes
    _nameFocusNode = FocusNode();
    _descriptionFocusNode = FocusNode();
    _cityFocusNode = FocusNode();
    _playersFocusNode = FocusNode();

    // Add focus listeners for IME management
    _nameFocusNode.addListener(_onFocusChanged);
    _descriptionFocusNode.addListener(_onFocusChanged);
    _cityFocusNode.addListener(_onFocusChanged);
    _playersFocusNode.addListener(_onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auth token is now handled automatically by Supabase client
      // Initialize repositories and services
      final teamRepository = TeamRepository(Supabase.instance.client);
      _teamService = TeamService(teamRepository);

      _loadCities();

      // Request initial focus on name field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _nameFocusNode.requestFocus();
        }
      });
    });
  }

  Future<void> _loadCities() async {
    if (mounted) {
      setState(() {
        _isLoadingCities = true;
      });
    }

    try {
      final cities = await _teamService?.getCities() ?? [];
      if (mounted) {
        setState(() {
          _availableCities = cities;
          // Set default city to the first one (Nador if available)
          if (_availableCities.isNotEmpty && _selectedCity == null) {
            _selectedCity = _availableCities.firstWhere(
              (city) => city.name == 'Nador',
              orElse: () => _availableCities.first,
            );
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

  void _onFocusChanged() {
    // Handle IME state changes and focus management
    setState(() {
      // This will trigger a rebuild to update UI state based on focus
    });

    // Log focus changes for debugging IME issues
    final focusedNode = [
      _nameFocusNode,
      _descriptionFocusNode,
      _cityFocusNode,
      _playersFocusNode
    ].firstWhere((node) => node.hasFocus, orElse: () => FocusNode());

    if (focusedNode != FocusNode()) {
      debugPrint('Focus changed to: ${focusedNode.toString()}');

      // Handle IME visibility for text fields
      if (focusedNode == _nameFocusNode ||
          focusedNode == _descriptionFocusNode) {
        _handleImeVisibility(true);
      } else {
        _handleImeVisibility(false);
      }
    } else {
      // No field has focus, hide IME
      _handleImeVisibility(false);
    }
  }

  void _handleImeVisibility(bool show) {
    // Handle IME visibility changes
    if (show) {
      // Ensure the form scrolls to show the focused field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final focusedNode = [
            _nameFocusNode,
            _descriptionFocusNode,
            _cityFocusNode,
            _playersFocusNode
          ].firstWhere((node) => node.hasFocus, orElse: () => _nameFocusNode);
          if (focusedNode.context != null) {
            Scrollable.ensureVisible(
              focusedNode.context!,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    }
  }

  void _submitForm() {
    // Submit the form when done is pressed on the last field
    if (_formKey.currentState?.validate() == true) {
      _createTeam();
    }
  }

  @override
  void dispose() {
    // Clean up focus nodes
    _nameFocusNode.removeListener(_onFocusChanged);
    _descriptionFocusNode.removeListener(_onFocusChanged);
    _cityFocusNode.removeListener(_onFocusChanged);
    _playersFocusNode.removeListener(_onFocusChanged);

    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _cityFocusNode.dispose();
    _playersFocusNode.dispose();

    // Clean up controllers
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isLoading = true;
      _isSubmitting = true;
    });

    try {
      final team = kIsWeb
          ? await WebTeamService.createTeamWeb(
              name: _nameController.text.trim(),
              location: _selectedCity?.name,
              numberOfPlayers: _numberOfPlayers,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              isRecruiting: _isRecruiting,
              gender: _gender,
              minAge: _minAge,
              maxAge: _maxAge,
            )
          : await _teamService?.createTeam(
              name: _nameController.text.trim(),
              location: _selectedCity?.name,
              numberOfPlayers: _numberOfPlayers,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              isRecruiting: _isRecruiting,
              gender: _gender,
              minAge: _minAge,
              maxAge: _maxAge,
            );

      if (team != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('team_created')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('duplicate') ||
            errorMessage.contains('already exists')) {
          errorMessage = 'You already have a team with this name';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${LocalizationService().translate('error')}: $errorMessage'),
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
        title: Text(LocalizationService().translate('create_team')),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Container(
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.all(
                MediaQuery.of(context).size.width > 600 ? 32 : 16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Enhanced Header
                    Container(
                      padding: ResponsiveUtils.getResponsivePadding(context),
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.group_add,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocalizationService().translate('create_team'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocalizationService()
                                .translate('build_team_subtitle'),
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

                    const SizedBox(height: 32),

                    // Enhanced Form Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                LocalizationService()
                                    .translate('team_information'),
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
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              const Text(
                                RequiredFieldIndicator.text,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocalizationService().translate('team_name'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: FootConnectSpacing.space2),
                          EnhancedFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            labelText:
                                LocalizationService().translate('team_name'),
                            hintText: LocalizationService()
                                .translate('enter_team_name'),
                            prefixIcon: Icon(
                              Icons.group,
                              color: context.colors.primary,
                            ),
                            validator: (value) => validateTeamName(value),
                            showValidationFeedback: true,
                          ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          Row(
                            children: [
                              const Text(
                                RequiredFieldIndicator.text,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocalizationService().translate('location'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _isLoadingCities
                              ? const Center(child: CircularProgressIndicator())
                              : Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: context.colors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Focus(
                                    focusNode: _cityFocusNode,
                                    child: DropdownButtonFormField<City>(
                                      initialValue: _selectedCity,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: LocalizationService()
                                            .translate('location'),
                                        border: InputBorder.none,
                                        prefixIcon: Icon(
                                          Icons.location_city,
                                          color: context.colors.primary,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                      ),
                                      items: _availableCities.map((city) {
                                        return DropdownMenuItem(
                                          value: city,
                                          child: Text(
                                            city.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() => _selectedCity = value);
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (mounted) {
                                            _playersFocusNode.requestFocus();
                                          }
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return LocalizationService()
                                              .translate('location_required');
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          Row(
                            children: [
                              const Text(
                                RequiredFieldIndicator.text,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocalizationService().translate('max_players'),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.colors.border,
                                width: 1,
                              ),
                            ),
                            child: Focus(
                              focusNode: _playersFocusNode,
                              child: DropdownButtonFormField<int>(
                                initialValue: _numberOfPlayers,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                decoration: InputDecoration(
                                  labelText: LocalizationService()
                                      .translate('max_players'),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.people,
                                    color: context.colors.primary,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                items: [5, 7, 9, 10, 11, 13, 15, 18, 22]
                                    .map((players) {
                                  return DropdownMenuItem(
                                    value: players,
                                    child: Text(
                                      '$players ${LocalizationService().translate('players')}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(
                                      () => _numberOfPlayers = value ?? 11);
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    if (mounted) {
                                      _descriptionFocusNode.requestFocus();
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return LocalizationService().translate(
                                        'number_of_players_required');
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          Text(
                            LocalizationService().translate('team_description'),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                          ),
                          const SizedBox(height: FootConnectSpacing.space2),
                          TextFormField(
                            controller: _descriptionController,
                            focusNode: _descriptionFocusNode,
                            decoration: InputDecoration(
                              labelText: LocalizationService()
                                  .translate('team_description'),
                              hintText: LocalizationService()
                                  .translate('team_description_hint'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.description,
                                color: context.colors.primary,
                              ),
                              filled: true,
                              fillColor: context.colors.surface,
                            ),
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submitForm(),
                          ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          // Gender Selection
                          Text(
                            'Gender',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: context.colors.border, width: 1),
                            ),
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.wc,
                                    color: context.colors.primary),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'mixed', child: Text('Mixed')),
                                DropdownMenuItem(
                                    value: 'male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'female', child: Text('Female')),
                              ],
                              onChanged: (value) =>
                                  setState(() => _gender = value ?? 'mixed'),
                            ),
                          ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          // Age Range
                          Text(
                            'Age Range (Optional)',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.colors.textPrimary,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: context.colors.border, width: 1),
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _minAge,
                                    decoration: InputDecoration(
                                      labelText: 'Min Age',
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.calendar_today,
                                          color: context.colors.primary),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                    ),
                                    items: [
                                      13,
                                      16,
                                      18,
                                      21,
                                      25,
                                      30,
                                      35,
                                      40,
                                      45,
                                      50
                                    ].map((age) {
                                      return DropdownMenuItem(
                                          value: age, child: Text('$age'));
                                    }).toList(),
                                    onChanged: (value) =>
                                        setState(() => _minAge = value),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: context.colors.border, width: 1),
                                  ),
                                  child: DropdownButtonFormField<int>(
                                    initialValue: _maxAge,
                                    decoration: InputDecoration(
                                      labelText: 'Max Age',
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.calendar_today,
                                          color: context.colors.primary),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                    ),
                                    items: [
                                      18,
                                      21,
                                      25,
                                      30,
                                      35,
                                      40,
                                      45,
                                      50,
                                      60,
                                      100
                                    ].map((age) {
                                      return DropdownMenuItem(
                                          value: age, child: Text('$age'));
                                    }).toList(),
                                    onChanged: (value) =>
                                        setState(() => _maxAge = value),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          // Enhanced Recruiting Toggle
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isRecruiting
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isRecruiting
                                        ? Icons.people
                                        : Icons.people_outline,
                                    color: _isRecruiting
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        LocalizationService()
                                            .translate('recruiting'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      Text(
                                        LocalizationService().translate(
                                            'allow_join_requests_description'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isRecruiting,
                                  onChanged: (value) =>
                                      setState(() => _isRecruiting = value),
                                  activeThumbColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: FormConstants.sectionSpacing),

                          // Enhanced Create Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: (_isLoading || _isSubmitting)
                                  ? null
                                  : _createTeam,
                              icon: _isLoading || _isSubmitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.group_add),
                              label: Text(LocalizationService()
                                  .translate('create_team')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
    );
  }
}
