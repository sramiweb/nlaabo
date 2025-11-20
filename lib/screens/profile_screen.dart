import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/team_provider.dart';
import '../services/localization_service.dart';
import '../services/api_service.dart';
import '../models/user.dart' as app_user;
import '../models/team.dart';
import '../widgets/cached_image.dart';
import '../widgets/enhanced_empty_state.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_utils.dart';
import '../constants/responsive_constants.dart';
import '../design_system/components/cards/base_card.dart';
import '../design_system/components/buttons/primary_button.dart';
import '../design_system/components/buttons/secondary_button.dart';
import '../design_system/typography/app_text_styles.dart';
import '../design_system/colors/app_colors_extensions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _userStats = {};
  bool _isLoadingStats = false;
  app_user.User? _currentUser;
  bool _isLoadingUser = false;
  String? _errorMessage;
  bool _isDisposed = false;
  bool _isLoadingUserData = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentUser == null && !_isLoadingUser && !_isLoadingUserData) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _isLoadingUserData = false;
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_isLoadingUserData) return;
    _isLoadingUserData = true;

    setState(() {
      _isLoadingUser = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.refreshUser();

      if (mounted && !_isDisposed) {
        setState(() {
          _currentUser = authProvider.user;
          _isLoadingUser = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) {
        _isLoadingUserData = false;
        return;
      }
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        if (mounted && !_isDisposed) {
          setState(() {
            _currentUser = authProvider.user;
            _isLoadingUser = false;
            _errorMessage = 'Using cached data. Some information may be outdated.';
          });
        }
      } else {
        if (mounted && !_isDisposed) {
          setState(() {
            _isLoadingUser = false;
            _errorMessage = 'Failed to load profile data. Please check your connection and try again.';
          });
        }
      }
    } finally {
      _isLoadingUserData = false;
    }
  }

  Future<void> _loadUserStats() async {
    if (_isDisposed) return;

    if (mounted && !_isDisposed) {
      setState(() => _isLoadingStats = true);
    }

    try {
      // Clear cache first to ensure fresh data
      await _apiService.clearUserStatsCache();
      
      final authProvider = context.read<AuthProvider>();
      final stats = await authProvider.getUserStats(forceRefresh: true);
      debugPrint('📊 Profile stats: $stats');
      
      if (mounted && !_isDisposed) {
        setState(() {
          _userStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Stats error: $e');
      if (mounted && !_isDisposed) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _leaveTeam(String teamId) async {
    try {
      final teamProvider = context.read<TeamProvider>();
      await teamProvider.leaveTeam(teamId);
      await teamProvider.loadUserTeams();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('left_team_successfully'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocalizationService().translate('error')}: $e')),
        );
      }
    }
  }

  Future<void> _showLeaveTeamDialog(Team team) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${LocalizationService().translate('leave_team')} ${team.name}'),
          content: Text(LocalizationService().translate('leave_team_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocalizationService().translate('cancel')),
            ),
            PrimaryButton(
              text: LocalizationService().translate('leave'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _leaveTeam(team.id);
    }
  }

  String _getSkillLevelTranslation(String skillLevel) {
    switch (skillLevel) {
      case 'beginner':
        return LocalizationService().translate('beginner');
      case 'intermediate':
        return LocalizationService().translate('intermediate');
      case 'advanced':
        return LocalizationService().translate('advanced');
      default:
        return skillLevel;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyText.copyWith(color: context.colors.textSubtle)),
        Text(value, style: AppTextStyles.bodyText.copyWith(fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
      ],
    );
  }

  Widget _buildEnhancedInfoRow(String label, String value, IconData icon) {
    return BaseCard(
      padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
      backgroundColor: context.colors.surface.withValues(alpha: 0.8),
      child: Row(
        children: [
          Container(
            padding: ResponsiveConstants.getResponsivePadding(context, 'xs2'),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(context.borderRadius * 0.5),
            ),
            child: Icon(icon, size: ResponsiveUtils.getIconSize(context, 16), color: context.colors.primary),
          ),
          SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ResponsiveTextUtils.getScaledTextStyle(context, AppTextStyles.labelText.copyWith(color: context.colors.textSubtle, fontWeight: FontWeight.w500))),
                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs') * 0.5),
                Text(value, style: ResponsiveTextUtils.getScaledTextStyle(context, AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: context.colors.textPrimary))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: ResponsiveConstants.getResponsivePadding(context, 'xs2'),
          decoration: BoxDecoration(
            color: context.colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(context.borderRadius * 0.5),
          ),
          child: Icon(icon, size: ResponsiveUtils.getIconSize(context, 16), color: context.colors.primary),
        ),
        SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: context.colors.textPrimary.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ),
        Text(value, style: AppTextStyles.headingSmall.copyWith(fontWeight: FontWeight.bold, color: context.colors.primary)),
      ],
    );
  }

  Widget _buildEnhancedStatCard(String label, String value, IconData icon, Color accentColor) {
    return BaseCard(
      padding: ResponsiveConstants.getResponsivePadding(context, 'md2'),
      backgroundColor: context.colors.surface,
      child: Row(
        children: [
          Container(
            padding: ResponsiveConstants.getResponsivePadding(context, 'sm'),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(context.borderRadius * 0.5),
            ),
            child: Icon(icon, size: ResponsiveUtils.getIconSize(context, 22), color: accentColor),
          ),
          SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: ResponsiveTextUtils.getScaledTextStyle(context, AppTextStyles.bodyText.copyWith(color: context.colors.textSubtle, fontWeight: FontWeight.w500))),
                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs') * 0.5),
                Text(value, style: ResponsiveTextUtils.getScaledTextStyle(context, AppTextStyles.headingMedium.copyWith(fontWeight: FontWeight.bold, color: accentColor))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<TeamProvider>();

    if (_isLoadingUser) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const CircularProgressIndicator(), SizedBox(height: context.responsiveSpacing('lg')), const Text('Loading...')],
        ),
      );
    }

    if (_errorMessage != null && _currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: context.colors.destructive),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.bodyText.copyWith(color: context.colors.destructive)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadUserData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_errorMessage != null && _currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Using cached profile data. Some information may be outdated.'),
              backgroundColor: context.colors.info,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(label: 'Refresh', onPressed: _loadUserData),
            ),
          );
        }
      });
    }

    if (_currentUser == null) {
      return Center(child: Text(LocalizationService().translate('no_user_data_available')));
    }

    final user = _currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('profile'), style: AppTextStyles.headingSmall),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: context.colors.textPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.primary.withValues(alpha: 0.05), context.colors.surface.withValues(alpha: 0.02)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'md'),
                  vertical: ResponsiveConstants.getResponsiveSpacing(context, 'md'),
                ),
                child: BaseCard(
                  padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                  backgroundColor: context.colors.surface,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [context.colors.primary, context.colors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: user.imageUrl != null
                            ? CachedCircleImage(imageUrl: user.imageUrl!, radius: context.isMobile ? 40 : 50)
                            : CircleAvatar(
                                radius: context.isMobile ? 40 : 50,
                                backgroundColor: context.colors.surface,
                                child: Icon(Icons.person, size: context.isMobile ? 28 : 36, color: context.colors.textSubtle),
                              ),
                      ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                      Text(
                        user.name,
                        style: AppTextStyles.headingLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                          fontSize: context.isMobile ? 20 : 24,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      if (user.position != null && user.position!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'md'),
                            vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs'),
                          ),
                          decoration: BoxDecoration(color: context.colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(user.position!, style: AppTextStyles.subtitle.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600, fontSize: context.isMobile ? 13 : 15)),
                        ),
                      ],
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
                        Container(
                          constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                          padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
                          decoration: BoxDecoration(
                            color: context.colors.surface.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.colors.border.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            user.bio!,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: context.colors.textPrimary.withValues(alpha: 0.9),
                              fontSize: context.isMobile ? 12 : 14,
                              height: 1.5,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
              Container(
                constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                child: BaseCard(
                  padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_circle, color: context.colors.primary, size: ResponsiveUtils.getIconSize(context, 20)),
                          SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                          Text(LocalizationService().translate('account_info'), style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        ],
                      ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                      _buildEnhancedInfoRow(LocalizationService().translate('full_name'), user.name, Icons.person),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                      _buildEnhancedInfoRow(LocalizationService().translate('email'), user.email, Icons.email),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                      _buildEnhancedInfoRow(LocalizationService().translate('teams_owned'), teamProvider.userTeams.where((team) => team.ownerId == user.id).length.toString(), Icons.group),
                      if (user.phone != null && user.phone!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('phone'), user.phone!, Icons.phone),
                      ],
                      if (user.age != null) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('age'), user.age.toString(), Icons.calendar_today),
                      ],
                      if (user.gender != null) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('gender'), user.gender == 'male' ? LocalizationService().translate('male') : LocalizationService().translate('female'), Icons.people),
                      ],
                      if (user.location != null && user.location!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('location'), user.location!, Icons.location_on),
                      ],
                      if (user.position != null && user.position!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('position'), user.position!, Icons.sports_soccer),
                      ],
                      if (user.skillLevel != null && user.skillLevel!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('skill_level'), _getSkillLevelTranslation(user.skillLevel!), Icons.star),
                      ],
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                        _buildEnhancedInfoRow(LocalizationService().translate('bio'), user.bio!, Icons.description),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
              Container(
                constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                child: BaseCard(
                  padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bar_chart, color: context.colors.primary, size: ResponsiveUtils.getIconSize(context, 20)),
                          SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                          Text(LocalizationService().translate('user_stats'), style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                        ],
                      ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                      if (_isLoadingStats)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        _buildEnhancedStatCard(LocalizationService().translate('matches_joined'), _userStats['matches_joined']?.toString() ?? '0', Icons.sports_soccer, Theme.of(context).colorScheme.primary),
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
                        _buildEnhancedStatCard(LocalizationService().translate('matches_created'), _userStats['matches_created']?.toString() ?? '0', Icons.add_circle, Theme.of(context).colorScheme.secondary),
                        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
                        _buildEnhancedStatCard(LocalizationService().translate('teams_owned'), _userStats['teams_owned']?.toString() ?? '0', Icons.group, Theme.of(context).colorScheme.tertiary),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
              Container(
                constraints: BoxConstraints(maxWidth: context.maxContentWidth),
                child: BaseCard(
                  padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.groups, color: context.colors.primary, size: ResponsiveUtils.getIconSize(context, 20)),
                              SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                              Text(LocalizationService().translate('my_teams'), style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
                            ],
                          ),
                          if (!context.isMobile)
                            TextButton.icon(
                              onPressed: () => context.go('/teams'),
                              icon: const Icon(Icons.group_add),
                              label: Text(LocalizationService().translate('view_all_teams')),
                              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                            ),
                        ],
                      ),
                      if (context.isMobile)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: () => context.go('/teams'),
                            icon: const Icon(Icons.group_add),
                            label: Text(LocalizationService().translate('view_all_teams'), style: ResponsiveTextUtils.getResponsiveTextStyle(context, 'bodySmall')),
                            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                      if (teamProvider.userTeams.isEmpty)
                        EnhancedEmptyState(
                          type: EmptyStateType.noTeams,
                          title: LocalizationService().translate('no_teams_yet'),
                          message: LocalizationService().translate('create_first_team_message'),
                          onActionPressed: () => context.go('/create-team'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: teamProvider.userTeams.length,
                          itemBuilder: (context, index) {
                            final team = teamProvider.userTeams[index];
                            final isOwner = team.ownerId == _currentUser?.id;

                            return Container(
                              margin: EdgeInsets.only(
                                bottom: ResponsiveConstants.getResponsiveSpacing(context, 'sm'),
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isOwner ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1), width: isOwner ? 2 : 1),
                                boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, isOwner ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.7) : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7)]),
                                  ),
                                  child: CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Theme.of(context).colorScheme.surface,
                                    child: team.logo != null
                                        ? CachedImage(imageUrl: team.logo!, width: 36, height: 36, fit: BoxFit.cover, borderRadius: BorderRadius.circular(20))
                                        : Text(team.name.substring(0, 1).toUpperCase(), style: ResponsiveTextUtils.getResponsiveTextStyle(context, 'titleMedium', color: isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(team.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                    if (isOwner)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(20)),
                                        child: Text(LocalizationService().translate('your_team'), style: ResponsiveTextUtils.getScaledTextStyle(context, TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 9, fontWeight: FontWeight.bold))),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(color: isOwner ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Text(isOwner ? LocalizationService().translate('team_owner_manage') : LocalizationService().translate('team_member_text'), style: ResponsiveTextUtils.getResponsiveTextStyle(context, 'labelSmall', color: isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500)),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                        const SizedBox(width: 3),
                                        Flexible(child: Text(team.location ?? LocalizationService().translate('no_location_set'), style: ResponsiveTextUtils.getScaledTextStyle(context, Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))), overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.people, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                                        const SizedBox(width: 3),
                                        Flexible(child: Text('${LocalizationService().translate('max_players')}: ${team.maxPlayers}', style: ResponsiveTextUtils.getScaledTextStyle(context, Theme.of(context).textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))), overflow: TextOverflow.ellipsis)),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(color: team.isRecruiting ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                          child: Text(team.isRecruiting ? LocalizationService().translate('recruiting') : LocalizationService().translate('not_recruiting'), style: ResponsiveTextUtils.getScaledTextStyle(context, TextStyle(color: team.isRecruiting ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error, fontWeight: FontWeight.w500, fontSize: 9))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(isOwner ? Icons.settings : Icons.exit_to_app, color: isOwner ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error),
                                  onPressed: isOwner ? () => context.go('/teams/${team.id}/manage') : () => _showLeaveTeamDialog(team),
                                  padding: const EdgeInsets.all(12),
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  tooltip: isOwner ? 'Manage team settings' : 'Leave team',
                                ),
                                onTap: () => context.go('/teams/${team.id}'),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg')),
              Container(
                constraints: BoxConstraints(maxWidth: context.isMobile ? double.infinity : 400),
                height: context.buttonHeight,
                child: PrimaryButton(text: LocalizationService().translate('edit_profile'), onPressed: () => context.go('/edit-profile'), leadingIcon: Icons.edit),
              ),
              SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
              if (user.isAdmin) ...[
                Container(
                  constraints: BoxConstraints(maxWidth: context.isMobile ? double.infinity : 400),
                  height: context.buttonHeight,
                  child: SecondaryButton(text: LocalizationService().translate('admin_dashboard'), onPressed: () => context.go('/admin'), leadingIcon: Icons.admin_panel_settings),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
