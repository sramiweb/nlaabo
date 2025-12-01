import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../models/notification.dart';
import '../services/localization_service.dart';
import '../services/api_service.dart';
import '../services/team_service.dart';
import '../widgets/optimized_filter_bar.dart';
import '../utils/notification_handler.dart';
import '../services/team_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  late TeamService _teamService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _teamService = context.read<TeamService>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data
      final notificationProvider = context.read<NotificationProvider>();
      notificationProvider.loadNotifications();
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final notificationProvider = context.read<NotificationProvider>();
      await notificationProvider.markAsRead(notificationId);
    } catch (error) {
      if (mounted) {
        NotificationHandler.showError(context, 'Failed to mark as read: $error');
      }
    }
  }

  Future<void> _acceptMatchRequest(String matchId, String notificationId) async {
    try {
      await _apiService.acceptMatchRequest(matchId);
      await _markAsRead(notificationId);
      if (mounted) {
        NotificationHandler.showSuccess(context, LocalizationService().translate('notification.match_request_accepted.title'));
        context.read<NotificationProvider>().loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        NotificationHandler.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _rejectMatchRequest(String matchId, String notificationId) async {
    try {
      await _apiService.rejectMatchRequest(matchId);
      await _markAsRead(notificationId);
      if (mounted) {
        NotificationHandler.showSuccess(context, LocalizationService().translate('notification.match_request_rejected.title'));
        context.read<NotificationProvider>().loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        NotificationHandler.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _acceptJoinRequest(String teamId, String? requestId, String notificationId) async {
    try {
      final teamService = context.read<TeamService>();
      // If requestId is not provided, fetch pending requests for this team
      String? finalRequestId = requestId;
      if (finalRequestId == null) {
        final requests = await teamService.getTeamJoinRequests(teamId);
        final pendingRequest = requests.where((r) => r.status == 'pending').firstOrNull;
        if (pendingRequest == null) {
          throw Exception('No pending request found');
        }
        finalRequestId = pendingRequest.id;
      }
      
      await teamService.updateJoinRequestStatus(teamId, finalRequestId, 'accepted');
      await _markAsRead(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('request_approved'))),
        );
        context.read<NotificationProvider>().loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectJoinRequest(String teamId, String? requestId, String notificationId) async {
    try {
      final teamService = context.read<TeamService>();
      // If requestId is not provided, fetch pending requests for this team
      String? finalRequestId = requestId;
      if (finalRequestId == null) {
        final requests = await teamService.getTeamJoinRequests(teamId);
        final pendingRequest = requests.where((r) => r.status == 'pending').firstOrNull;
        if (pendingRequest == null) {
          throw Exception('No pending request found');
        }
        finalRequestId = pendingRequest.id;
      }
      
      await teamService.updateJoinRequestStatus(teamId, finalRequestId, 'rejected');
      await _markAsRead(notificationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LocalizationService().translate('request_rejected'))),
        );
        context.read<NotificationProvider>().loadNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'match_request':
        return Colors.blue;
      case 'team_join_request':
        return Colors.green;
      case 'match_accepted':
        return Colors.green;
      case 'match_rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'match_request':
        return Icons.sports_soccer;
      case 'team_join_request':
        return Icons.group_add;
      case 'match_accepted':
        return Icons.check_circle;
      case 'match_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await NotificationHandler.showConfirmDialog(
      context,
      title: LocalizationService().translate('clear_all_notifications'),
      message: LocalizationService().translate('clear_all_notifications_confirm'),
      confirmLabel: LocalizationService().translate('clear_all'),
      confirmColor: Colors.red,
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<NotificationProvider>().clearAllNotifications();
        if (mounted) {
          NotificationHandler.showSuccess(context, LocalizationService().translate('notifications_cleared'));
        }
      } catch (e) {
        if (mounted) {
          NotificationHandler.showError(context, 'Error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: notificationProvider.notifications.isNotEmpty
          ? AppBar(
              title: Text(LocalizationService().translate('notifications')),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: _clearAllNotifications,
                  tooltip: LocalizationService().translate('clear_all'),
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          OptimizedFilterBar(
            location: null,
            category: LocalizationService().translate('notifications'),
            onRefresh: () => notificationProvider.loadNotifications(),
            onHome: () => context.go('/'),
          ),
          Expanded(
            child: notificationProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationProvider.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                final isMatchRequest = notification.type == 'match_request';
                final isJoinRequest = notification.type == 'team_join_request';
                final needsAction = (isMatchRequest || isJoinRequest) && notification.relatedId != null;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: notification.isRead ? 1 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getNotificationColor(notification.type),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        trailing: notification.isRead
                            ? null
                            : Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                        onTap: !needsAction ? () {
                          if (!notification.isRead) {
                            _markAsRead(notification.id);
                          }
                          _handleNotificationTap(notification);
                        } : null,
                      ),
                      if (needsAction)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  if (isMatchRequest) {
                                    context.push('/matches/${notification.relatedId}');
                                  } else if (isJoinRequest) {
                                    context.push('/teams/${notification.relatedId}');
                                  }
                                },
                                icon: const Icon(Icons.info_outline, size: 18),
                                label: Text(LocalizationService().translate('view_details')),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      if (isMatchRequest) {
                                        _rejectMatchRequest(
                                          notification.relatedId!,
                                          notification.id,
                                        );
                                      } else if (isJoinRequest) {
                                        final teamId = notification.relatedId!;
                                        final requestId = notification.metadata?['request_id'] as String?;
                                        _rejectJoinRequest(teamId, requestId, notification.id);
                                      }
                                    },
                                    icon: const Icon(Icons.close, size: 18),
                                    label: Text(LocalizationService().translate('reject')),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (isMatchRequest) {
                                        _acceptMatchRequest(
                                          notification.relatedId!,
                                          notification.id,
                                        );
                                      } else if (isJoinRequest) {
                                        final teamId = notification.relatedId!;
                                        final requestId = notification.metadata?['request_id'] as String?;
                                        _acceptJoinRequest(teamId, requestId, notification.id);
                                      }
                                    },
                                    icon: const Icon(Icons.check, size: 18),
                                    label: Text(LocalizationService().translate('accept')),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (notification.relatedId == null) return;

    switch (notification.type) {
      case 'match_created':
      case 'match_joined':
      case 'match_left':
      case 'match_reminder':
      case 'match_request':
      case 'match_accepted':
      case 'match_rejected':
        context.push('/matches/${notification.relatedId}');
        break;
      case 'team_invite':
      case 'team_join_request':
      case 'team_join_approved':
      case 'team_join_rejected':
      case 'team_member_left':
      case 'team_member_removed':
        context.push('/teams/${notification.relatedId}');
        break;
    }
  }
}
