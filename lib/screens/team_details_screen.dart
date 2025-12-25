import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/team.dart';
import '../models/user.dart';
import '../services/localization_service.dart';
import '../widgets/cached_image.dart';
import '../widgets/directional_icon.dart';

enum OwnerLoadingState { loading, loaded, error }

class TeamDetailsScreen extends StatefulWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  final ApiService _apiService = ApiService();
  Team? _team;
  String? _ownerName;
  OwnerLoadingState _ownerLoadingState = OwnerLoadingState.loading;

  List<User> _members = [];
  List<TeamJoinRequest> _joinRequests = [];
  List<TeamJoinRequest> _myJoinRequests = [];
  bool _isLoading = true;
  bool _isJoining = false;
  bool _isCancellingRequest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeamData();
    });
  }

  Future<void> _loadOwnerData() async {
    if (_team == null) return;

    setState(() {
      _ownerLoadingState = OwnerLoadingState.loading;
    });

    try {
      final owner = await _apiService.getUserById(_team!.ownerId);
      if (!mounted) return;
      setState(() {
        _ownerName = owner.name;
        _ownerLoadingState = OwnerLoadingState.loaded;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Failed to load owner: $e');
      setState(() {
        _ownerLoadingState = OwnerLoadingState.error;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _ownerLoadingState == OwnerLoadingState.error) {
          _loadOwnerData();
        }
      });
    }
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final localContext = context;
      final localWidgetTeamId = widget.teamId;
      final authProvider = localContext.read<AuthProvider>();

      final team = await _apiService.getTeam(localWidgetTeamId);
      final members = await _apiService.getTeamMembers(localWidgetTeamId);

      final isOwner = authProvider.user?.id == team.ownerId;

      // Load join requests if user is the owner
      List<TeamJoinRequest> joinRequests = [];
      if (isOwner) {
        try {
          joinRequests = (await _apiService.getTeamJoinRequests(
            localWidgetTeamId,
          ))
              .cast<TeamJoinRequest>();
        } catch (e) {
          // Silently fail for join requests - not critical for team display
        }
      }

      // Load user's join requests to check for pending requests to this team
      List<TeamJoinRequest> myJoinRequests = [];
      try {
        myJoinRequests = await _apiService.getMyJoinRequests();
      } catch (e) {
        // Silently fail for user's join requests - not critical for team display
      }

      if (!mounted) return;
      setState(() {
        _team = team;
        _members = members;
        _joinRequests = joinRequests;
        _myJoinRequests = myJoinRequests;
        _isLoading = false;
      });

      // Load owner data separately
      await _loadOwnerData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService().translate('error')}: $e'),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showJoinRequestDialog() async {
    final TextEditingController messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocalizationService().translate('join_team')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${LocalizationService().translate('join_team_request_message')} "${_team!.name}"',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: LocalizationService().translate(
                    'message_optional',
                  ),
                  hintText: LocalizationService().translate(
                    'enter_message_hint',
                  ),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 200,
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
              child: Text(LocalizationService().translate('send_request')),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _joinTeam(
        messageController.text.trim().isEmpty
            ? null
            : messageController.text.trim(),
      );
    }
  }

  Future<void> _joinTeam([String? message]) async {
    if (_team == null) return;

    setState(() {
      _isJoining = true;
    });

    try {
      await _apiService.createJoinRequest(widget.teamId, message: message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('join_request_sent')),
          ),
        );
        // Reload data to update UI
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  Future<void> _cancelJoinRequest() async {
    final pendingRequest = _getPendingRequestForCurrentTeam();
    if (pendingRequest == null) return;

    setState(() {
      _isCancellingRequest = true;
    });

    try {
      await _apiService.cancelJoinRequest(widget.teamId, pendingRequest.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocalizationService().translate('join_request_cancelled'),
            ),
          ),
        );
        // Reload data to update UI
        await _loadTeamData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isCancellingRequest = false;
      });
    }
  }

  Future<void> _leaveTeam() async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    setState(() => _isJoining = true);

    // Optimistic update - remove user from members list immediately
    setState(() {
      _members.removeWhere((member) => member.id == currentUserId);
    });

    try {
      await _apiService.leaveTeam(widget.teamId);
      // Reload to confirm server state
      await _loadTeamData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService().translate('left_team')),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      await _loadTeamData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${LocalizationService().translate('error')}: $e'),
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

  TeamJoinRequest? _getPendingRequestForCurrentTeam() {
    return _myJoinRequests.cast<TeamJoinRequest?>().firstWhere(
          (request) =>
              request?.team?.id == widget.teamId &&
              request?.status == 'pending',
          orElse: () => null,
        );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isOwner = authProvider.user?.id == _team?.ownerId;
    final isMember = _members.any(
      (member) => member.id == authProvider.user?.id,
    );
    final hasPendingRequest = _getPendingRequestForCurrentTeam() != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _team?.name ?? LocalizationService().translate('team_details'),
        ),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.go('/teams'),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          tooltip: 'Go back to teams',
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/teams/${widget.teamId}/manage'),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              tooltip: 'Team settings',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _team == null
              ? Center(
                  child: Text(
                    LocalizationService().translate('team_not_found'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeamData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Team Header
                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: (_team!.isRecruiting
                                          ? Colors.green
                                          : Colors.grey)
                                      .withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.95),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.7),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: _team!.logo != null &&
                                                  _team!.logo!.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: CachedImage(
                                                    imageUrl: _team!.logo!,
                                                    width: 60,
                                                    height: 60,
                                                    fit: BoxFit.cover,
                                                    errorWidget: const Icon(
                                                        Icons.groups,
                                                        color: Colors.white,
                                                        size: 30),
                                                  ),
                                                )
                                              : const Icon(Icons.groups,
                                                  color: Colors.white,
                                                  size: 30),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _team!.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: (_team!.isRecruiting
                                                          ? Colors.green
                                                          : Colors.grey)
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  _team!.isRecruiting
                                                      ? LocalizationService()
                                                          .translate(
                                                              'recruiting')
                                                      : LocalizationService()
                                                          .translate(
                                                              'not_recruiting'),
                                                  style: TextStyle(
                                                    color: _team!.isRecruiting
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_team!.description != null &&
                                        _team!.description!.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        _team!.description!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    _buildOwnerInfoRow(context),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        context,
                                        Icons.location_on,
                                        Colors.red.shade400,
                                        LocalizationService()
                                            .translate('location'),
                                        _team!.location ??
                                            LocalizationService()
                                                .translate('not_specified')),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        context,
                                        Icons.calendar_today,
                                        Colors.blue.shade400,
                                        LocalizationService()
                                            .translate('created'),
                                        _formatDate(_team!.createdAt)),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                        context,
                                        Icons.group,
                                        Colors.green.shade400,
                                        LocalizationService()
                                            .translate('members'),
                                        '${_members.length}/${_team!.maxPlayers}'),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Action Button
                            if (!isOwner &&
                                !isMember &&
                                !hasPendingRequest &&
                                _team!.isRecruiting)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isJoining
                                      ? null
                                      : _showJoinRequestDialog,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: _isJoining
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : Text(LocalizationService()
                                          .translate('join_team')),
                                ),
                              )
                            else if (hasPendingRequest)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isCancellingRequest
                                      ? null
                                      : _cancelJoinRequest,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: _isCancellingRequest
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : Text(LocalizationService()
                                          .translate('cancel_request')),
                                ),
                              )
                            else if (isMember && !isOwner)
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isJoining ? null : _leaveTeam,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade400,
                                    foregroundColor: Colors.white,
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: _isJoining
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : Text(LocalizationService()
                                          .translate('leave_team')),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Team Members
                            Text(
                              LocalizationService().translate('team_members'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),

                            Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(context)
                                          .colorScheme
                                          .surface
                                          .withValues(alpha: 0.95),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _members.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            LocalizationService()
                                                .translate('no_members'),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _members.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(height: 16),
                                        itemBuilder: (context, index) {
                                          final member = _members[index];
                                          final isCurrentUser = member.id ==
                                              authProvider.user?.id;

                                          return Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      member.role == 'admin'
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .secondary,
                                                      (member.role == 'admin'
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary)
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (member.role ==
                                                                  'admin'
                                                              ? Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary)
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    member.name
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            member.name,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.copyWith(
                                                                  fontWeight: isCurrentUser
                                                                      ? FontWeight
                                                                          .bold
                                                                      : FontWeight
                                                                          .w500,
                                                                ),
                                                          ),
                                                        ),
                                                        if (isCurrentUser)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.15),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              LocalizationService()
                                                                  .translate(
                                                                      'you'),
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        if (member.role ==
                                                            'admin')
                                                          Container(
                                                            margin: EdgeInsetsDirectional
                                                                .only(
                                                                    start:
                                                                        isCurrentUser
                                                                            ? 4
                                                                            : 0),
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        6,
                                                                    vertical:
                                                                        2),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              'ADMIN',
                                                              style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .onPrimary,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (member.position !=
                                                            null &&
                                                        member.position!
                                                            .isNotEmpty)
                                                      Text(
                                                        member.position!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6),
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ),

                            // Join Requests Section (for team owners only)
                            if (isOwner && _joinRequests.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                '${LocalizationService().translate('join_requests')} (${_joinRequests.length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _joinRequests.length,
                                itemBuilder: (context, index) {
                                  final request = _joinRequests[index];
                                  final user = request.user;

                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .surface,
                                            Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withValues(alpha: 0.95),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary
                                                          .withValues(
                                                              alpha: 0.3),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    user?.name
                                                            .substring(0, 1)
                                                            .toUpperCase() ??
                                                        '?',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user?.name ??
                                                          LocalizationService()
                                                              .translate(
                                                                  'unknown_user'),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                    ),
                                                    if (user?.email != null)
                                                      Text(
                                                        user!.email,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withValues(
                                                                      alpha:
                                                                          0.6),
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  LocalizationService()
                                                      .translate('pending'),
                                                  style: const TextStyle(
                                                    color: Colors.orange,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (request.message != null &&
                                              request.message!.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.05),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '"${request.message}"',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                        fontStyle:
                                                            FontStyle.italic),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: () =>
                                                      _rejectJoinRequest(
                                                          request.id),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                        color: Colors.red),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                  ),
                                                  child: Text(
                                                      LocalizationService()
                                                          .translate('reject'),
                                                      style: const TextStyle(
                                                          color: Colors.red)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      _acceptJoinRequest(
                                                          request.id),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    elevation: 2,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                  ),
                                                  child: Text(
                                                      LocalizationService()
                                                          .translate('accept')),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _acceptJoinRequest(String requestId) async {
    try {
      debugPrint(
          '🔵 Accepting join request: $requestId for team: ${widget.teamId}');
      await _apiService.updateJoinRequestStatus(
        widget.teamId,
        requestId,
        'approved',
      );
      debugPrint('✅ Join request approved, reloading team data...');
      await _loadTeamData(); // Refresh data
      debugPrint('✅ Team data reloaded. Members count: ${_members.length}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content:
                Text(LocalizationService().translate('request_approved'))));
      }
    } catch (e) {
      debugPrint('❌ Error accepting request: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error accepting request: $e')));
      }
    }
  }

  Future<void> _rejectJoinRequest(String requestId) async {
    try {
      await _apiService.updateJoinRequestStatus(
        widget.teamId,
        requestId,
        'rejected',
      );
      await _loadTeamData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content:
                Text(LocalizationService().translate('request_rejected'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error rejecting request: $e')));
      }
    }
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, Color color,
      String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerInfoRow(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade400.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.person, size: 14, color: Colors.blue.shade400),
        ),
        const SizedBox(width: 8),
        Text(
          '${LocalizationService().translate('owner')}: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: _buildOwnerDisplay(context),
        ),
      ],
    );
  }

  Widget _buildOwnerDisplay(BuildContext context) {
    switch (_ownerLoadingState) {
      case OwnerLoadingState.loading:
        return Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              LocalizationService().translate('loading'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
          ],
        );
      case OwnerLoadingState.loaded:
        return Text(
          _ownerName ?? LocalizationService().translate('unknown_user'),
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case OwnerLoadingState.error:
        return Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                LocalizationService().translate('failed_to_load'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _loadOwnerData,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(LocalizationService().translate('retry')),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                minimumSize: const Size(88, 48),
              ),
            ),
          ],
        );
    }
  }
}
