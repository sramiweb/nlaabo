import '../utils/color_extensions.dart';
import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../design_system/typography/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/localization_service.dart';
import '../models/match.dart';
import '../models/user.dart' as app_user;
import '../widgets/directional_icon.dart';
import '../widgets/match_management_widget.dart';

class MatchDetailsScreen extends StatefulWidget {
  final String matchId;

  const MatchDetailsScreen({super.key, required this.matchId});

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  final ApiService _apiService = ApiService();
  Match? _match;
  List<app_user.User> _players = [];
  bool _isLoading = true;
  bool _isLoadingPlayers = true;
  app_user.User? _currentUser;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMatchDetails();
    _loadMatchPlayers();
  }

  Future<void> _loadMatchDetails() async {
    try {
      final match = await _apiService.getMatch(widget.matchId);
      if (mounted) {
        setState(() {
          _match = match;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('failed_to_load_match')}: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // User not authenticated, that's okay
    }
  }

  Future<void> _loadMatchPlayers() async {
    try {
      final players = await _apiService.getMatchPlayers(widget.matchId);
      if (mounted) {
        setState(() {
          _players = players;
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPlayers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${LocalizationService().translate('failed_to_load_players')}: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _joinMatch() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationService().translate('please_login_to_join'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isJoining = true);

    // Optimistic update - add user to list immediately
    setState(() {
      _players.add(_currentUser!);
    });

    try {
      await _apiService.joinMatch(widget.matchId);
      // Reload to confirm server state
      await _loadMatchPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('joined_match')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      await _loadMatchPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Future<void> _leaveMatch() async {
    if (_currentUser == null) return;
    
    setState(() => _isJoining = true);

    // Optimistic update - remove user from list immediately
    final currentUserId = _currentUser!.id;
    setState(() {
      _players.removeWhere((player) => player.id == currentUserId);
    });

    try {
      await _apiService.leaveMatch(widget.matchId);
      // Reload to confirm server state
      await _loadMatchPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('left_match')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      await _loadMatchPlayers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'closed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'finished':
        return Colors.purple;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getLocalizedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return LocalizationService().translate('open');
      case 'closed':
        return LocalizationService().translate('closed');
      case 'pending':
        return LocalizationService().translate('pending');
      case 'confirmed':
        return LocalizationService().translate('confirmed');
      case 'finished':
        return LocalizationService().translate('finished');
      case 'cancelled':
        return LocalizationService().translate('cancelled');
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocalizationService().translate('match_details')),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.go('/home'),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          tooltip: 'Go back',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _match == null
          ? Center(
              child: Text(LocalizationService().translate('match_not_found')),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // avoid null-assertion by promoting after an explicit null-check
                  final match = _match;
                  if (match == null) {
                    // Redundant safety: if _match is unexpectedly null show not-found placeholder
                    return Center(
                      child: Text(
                        LocalizationService().translate('match_not_found'),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                          maxWidth: 800,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          // Enhanced Match Header using new design system
                          Card(
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.surface,
                                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getStatusColor(match.status).withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).colorScheme.primary,
                                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(Icons.sports_soccer, color: Colors.white, size: ResponsiveUtils.getIconSize(context, 24)),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(match.status),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _getStatusColor(match.status).withValues(alpha: 0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          _getLocalizedStatus(match.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.displayTitle,
                                    style: AppTextStyles.getResponsiveCardTitle(context).copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Enhanced Match Information Card
                          Card(
                            elevation: 3,
                            shadowColor: Colors.black.withValues(alpha: 0.15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Theme.of(context).colorScheme.surface,
                                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade400.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.info_outline, size: ResponsiveUtils.getIconSize(context, 14), color: Colors.blue.shade400),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        LocalizationService().translate('match_information'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade400.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.location_on, size: ResponsiveUtils.getIconSize(context, 14), color: Colors.red.shade400),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          match.location,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade400.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.access_time, size: 14, color: Colors.blue.shade400),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        match.formattedDate,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade400.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.sports, size: 14, color: Colors.orange.shade400),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              match.matchType == 'mixed'
                                                  ? LocalizationService().translate('mixed')
                                                  : match.matchType == 'male'
                                                  ? LocalizationService().translate('male')
                                                  : LocalizationService().translate('female'),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade400.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Icon(Icons.people, size: 14, color: Colors.green.shade400),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${match.defaultMaxPlayers} ${LocalizationService().translate('players')}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Enhanced Players Section
                          Container(
                            padding: const EdgeInsets.all(14),
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
                                      Icons.people,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      LocalizationService().translate('players'),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${_players.length}/${match.defaultMaxPlayers}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Players List
                                if (_isLoadingPlayers)
                                  const Center(child: CircularProgressIndicator())
                                else if (_players.isEmpty)
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 48,
                                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          LocalizationService().translate('no_players_yet'),
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _players.length,
                                    itemBuilder: (context, index) {
                                      final player = _players[index];
                                      final isCurrentUser = _currentUser?.id == player.id;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isCurrentUser
                                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                                              : Theme.of(context).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isCurrentUser
                                                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Enhanced Avatar
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                border: Border.all(
                                                  color: isCurrentUser
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Colors.transparent,
                                                  width: 2,
                                                ),
                                              ),
                                              child: player.imageUrl != null
                                                  ? ClipOval(
                                                      child: Image.network(
                                                        player.imageUrl!,
                                                        fit: BoxFit.cover,
                                                        width: 48,
                                                        height: 48,
                                                      ),
                                                    )
                                                  : Icon(
                                                      Icons.person,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      size: 24,
                                                    ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Player Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        player.name,
                                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      if (isCurrentUser) ...[
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Theme.of(context).colorScheme.primary,
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Text(
                                                            LocalizationService().translate('you'),
                                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context).colorScheme.onPrimary,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (player.position != null && player.position!.isNotEmpty)
                                                    Text(
                                                      player.position!,
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),

                                            // Status indicator
                                            if (isCurrentUser)
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check_circle,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 20,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Player Count Summary
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacitySafe(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      _players.length.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                    ),
                                    Text(
                                      LocalizationService().translate('joined'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 32,
                                  width: 1,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacitySafe(0.3),
                                ),
                                Column(
                                  children: [
                                    Text(
                                      // compute remaining spots with safe fallback
                                      (match.defaultMaxPlayers -
                                              _players.length)
                                          .toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ),
                                    ),
                                    Text(
                                      LocalizationService().translate(
                                        'spots_left',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacitySafe(0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Match Management (for owners)
                          MatchManagementWidget(
                            match: match,
                            isOwner: _currentUser?.id == match.createdBy,
                          ),

                          const SizedBox(height: 20),

                          // Join/Leave Button
                          if (_currentUser != null &&
                              match.status == 'open') ...[
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isJoining
                                    ? null
                                    : (_players.any(
                                            (player) =>
                                                player.id == _currentUser!.id,
                                          )
                                          ? _leaveMatch
                                          : _joinMatch),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _players.any((player) => player.id == _currentUser!.id)
                                      ? Colors.red.shade400
                                      : Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shadowColor: Colors.black.withValues(alpha: 0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isJoining
                                    ? SizedBox(
                                        height: 28,
                                        width: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                _players.any(
                                                      (player) =>
                                                          player.id ==
                                                          _currentUser!.id,
                                                    )
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.onSecondary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                              ),
                                        ),
                                      )
                                    : Text(
                                        _players.any(
                                              (player) =>
                                                  player.id == _currentUser!.id,
                                            )
                                            ? LocalizationService().translate(
                                                'leave_match',
                                              )
                                            : LocalizationService().translate(
                                                'join_match',
                                              ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                          ],
                        ),
                      ),
                    ),
                  ); // end SingleChildScrollView
                }, // end Builder
              ), // end LayoutBuilder
            ), // end SafeArea
      resizeToAvoidBottomInset: true, // Enable keyboard handling
    );
  }
}

