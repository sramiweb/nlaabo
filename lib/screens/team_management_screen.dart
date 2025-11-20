import 'package:flutter/material.dart';
import '../widgets/directional_icon.dart';
import 'package:go_router/go_router.dart';
import '../constants/responsive_constants.dart';
import '../services/api_service.dart';
import '../models/team.dart';
import '../services/localization_service.dart';

class TeamManagementScreen extends StatefulWidget {
  final String teamId;

  const TeamManagementScreen({super.key, required this.teamId});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ApiService _apiService = ApiService();
  Team? _team;
  List<TeamJoinRequest> _joinRequests = [];
  bool _isLoading = true;
  bool _isTogglingRecruiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final team = await _apiService.getTeam(widget.teamId);
      final joinRequests = await _apiService.getTeamJoinRequests(widget.teamId);

      setState(() {
        _team = team;
        _joinRequests = joinRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _toggleRecruiting() async {
    if (_team == null) return;

    setState(() {
      _isTogglingRecruiting = true;
    });

    try {
      await _apiService.toggleTeamRecruiting(widget.teamId);

      // Reload team data to get updated recruiting status
      await _loadData();

      setState(() {
        _isTogglingRecruiting = false;
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _team!.isRecruiting
                      ? LocalizationService().translate('recruiting_enabled')
                      : LocalizationService().translate('recruiting_disabled'),
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      setState(() {
        _isTogglingRecruiting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _updateJoinRequestStatus(String requestId, String status) async {
    try {
      await _apiService.updateJoinRequestStatus(
        widget.teamId,
        requestId,
        status,
      );

      // Update local state
      setState(() {
        _joinRequests = _joinRequests.map((request) {
          if (request.id == requestId) {
            return request.copyWith(status: status);
          }
          return request;
        }).toList();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'approved'
                  ? LocalizationService().translate('request_approved')
                  : LocalizationService().translate('request_rejected'),
            ),
          ),
        );
      }

      // Reload data to get updated member count
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteTeamDialog() async {
    final TextEditingController reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('delete_team')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LocalizationService().translate('delete_team_confirmation')),
              SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg')),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate('reason_optional'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocalizationService().translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text(LocalizationService().translate('delete')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteTeam(reasonController.text.trim());
    }
  }

  Future<void> _deleteTeam(String reason) async {
    try {
      await _apiService.deleteTeam(
        widget.teamId,
        reason: reason.isNotEmpty ? reason : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('team_deleted_successfully'),
            ),
          ),
        );
        context.go('/teams'); // Navigate back to teams list
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${LocalizationService().translate('error')}: $e'),
              ),
            );
          }
        });
      }
    }
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getSkillLevelText(String skillLevel) {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 900;
    final isMediumScreen = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _team?.name ?? LocalizationService().translate('team_management'),
        ),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: isLargeScreen
                  ? constraints.maxWidth * 0.8
                  : (isMediumScreen
                        ? constraints.maxWidth * 0.9
                        : double.infinity),
              constraints: const BoxConstraints(maxWidth: 1200),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _team == null
                  ? Center(
                      child: Text(
                        LocalizationService().translate('team_not_found'),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Team Info Card
                          Container(
                            padding: ResponsiveConstants.getResponsivePadding(context, 'xl'),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _team!.name.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'lg2')),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _team!.name,
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                                          if (_team!.location != null)
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                                SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                                                Text(
                                                  _team!.location!,
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                              SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                                              Text(
                                                '${LocalizationService().translate('max_players')}: ${_team!.maxPlayers}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg2')),
                                Container(
                                  padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              LocalizationService().translate('recruiting_status'),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                                            Text(
                                              _team!.isRecruiting
                                                  ? LocalizationService().translate('recruiting')
                                                  : LocalizationService().translate('not_recruiting'),
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: _team!.isRecruiting
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _isTogglingRecruiting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Switch(
                                               value: _team!.isRecruiting,
                                               onChanged: (_) => _toggleRecruiting(),
                                               activeThumbColor: Theme.of(context).colorScheme.primary,
                                             ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg2')),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => context.go('/create-match?team1=${widget.teamId}'),
                                        icon: const Icon(Icons.add),
                                        label: Text(LocalizationService().translate('create_match')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.secondary,
                                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                          padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                    ElevatedButton.icon(
                                      onPressed: () => _showDeleteTeamDialog(),
                                      icon: const Icon(Icons.delete),
                                      label: Text(LocalizationService().translate('delete_team')),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                        foregroundColor: Theme.of(context).colorScheme.onError,
                                        padding: EdgeInsets.symmetric(vertical: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xl')),

                          // Enhanced Join Requests Section
                          Container(
                            padding: ResponsiveConstants.getResponsivePadding(context, 'lg2'),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                    SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                    Text(
                                      LocalizationService().translate('join_requests'),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'md'), vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_joinRequests.length}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg2')),

                                _joinRequests.isEmpty
                                    ? Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.inbox,
                                              size: 48,
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                            ),
                                            SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                            Text(
                                              LocalizationService().translate('no_join_requests'),
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: _joinRequests.length,
                                        itemBuilder: (context, index) {
                                          final request = _joinRequests[index];

                                          return Container(
                                            margin: EdgeInsets.only(bottom: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                            padding: ResponsiveConstants.getResponsivePadding(context, 'lg'),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.surface,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          request.user?.name.substring(0, 1).toUpperCase() ?? '?',
                                                          style: TextStyle(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            request.user?.name ?? LocalizationService().translate('unknown_user'),
                                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                              fontWeight: FontWeight.w600,
                                                              color: Theme.of(context).colorScheme.onSurface,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          if (request.user?.phone != null && request.user!.phone!.isNotEmpty)
                                                            Row(
                                                              children: [
                                                                Icon(Icons.phone, size: 14, color: Theme.of(context).colorScheme.primary),
                                                                const SizedBox(width: 4),
                                                                Text(
                                                                  request.user!.phone!,
                                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                    color: Theme.of(context).colorScheme.primary,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          Text(
                                                            '${LocalizationService().translate('requested')}: ${request.createdAt.toString().split(' ')[0]}',
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'sm'), vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                                                      decoration: BoxDecoration(
                                                        color: request.status == 'pending'
                                                            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                                                            : request.status == 'approved'
                                                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                                                            : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: request.status == 'pending'
                                                              ? Theme.of(context).colorScheme.secondary
                                                              : request.status == 'approved'
                                                              ? Theme.of(context).colorScheme.primary
                                                              : Theme.of(context).colorScheme.error,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        request.status.toUpperCase(),
                                                        style: TextStyle(
                                                          color: request.status == 'pending'
                                                              ? Theme.of(context).colorScheme.secondary
                                                              : request.status == 'approved'
                                                              ? Theme.of(context).colorScheme.primary
                                                              : Theme.of(context).colorScheme.error,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
                                                Container(
                                                  padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (request.user?.age != null)
                                                        _buildInfoChip(context, Icons.calendar_today, '${request.user!.age} ${LocalizationService().translate('age').toLowerCase()}'),
                                                      if (request.user?.gender != null)
                                                        _buildInfoChip(context, Icons.person, request.user!.gender == 'male' ? LocalizationService().translate('male') : LocalizationService().translate('female')),
                                                      if (request.user?.position != null && request.user!.position!.isNotEmpty)
                                                        _buildInfoChip(context, Icons.sports_soccer, request.user!.position!),
                                                      if (request.user?.skillLevel != null && request.user!.skillLevel!.isNotEmpty)
                                                        _buildInfoChip(context, Icons.star, _getSkillLevelText(request.user!.skillLevel!)),
                                                      if (request.user?.location != null && request.user!.location!.isNotEmpty)
                                                        _buildInfoChip(context, Icons.location_on, request.user!.location!),
                                                      if (request.user?.bio != null && request.user!.bio!.isNotEmpty) ...[
                                                        const SizedBox(height: 8),
                                                        Text(
                                                          request.user!.bio!,
                                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                            fontStyle: FontStyle.italic,
                                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                if (request.message != null && request.message!.isNotEmpty) ...[
                                                  SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                                                  Container(
                                                    padding: ResponsiveConstants.getResponsivePadding(context, 'md'),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Icon(Icons.message, size: 16, color: Theme.of(context).colorScheme.primary),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            request.message!,
                                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                              color: Theme.of(context).colorScheme.onSurface,
                                                            ),
                                                            maxLines: 3,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                if (request.status == 'pending') ...[
                                                  SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg')),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      TextButton(
                                                        onPressed: () => _updateJoinRequestStatus(request.id, 'rejected'),
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: Theme.of(context).colorScheme.error,
                                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'lg'), vertical: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                                                        ),
                                                        child: Text(LocalizationService().translate('reject')),
                                                      ),
                                                      SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                                                      ElevatedButton(
                                                        onPressed: () => _updateJoinRequestStatus(request.id, 'approved'),
                                                        style: ElevatedButton.styleFrom(
                                                          padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'lg'), vertical: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                                                        ),
                                                        child: Text(LocalizationService().translate('approve')),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
