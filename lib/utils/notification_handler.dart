import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/localization_service.dart';
import 'app_logger.dart';

/// Consolidated notification handling utility
class NotificationHandler {
  /// Show snack bar with message
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  /// Show error snack bar
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  /// Show success snack bar
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    
    showSnackBar(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    Color? confirmColor,
  }) {
    if (!context.mounted) return Future.value(null);
    
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(cancelLabel ?? LocalizationService().translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(confirmLabel ?? LocalizationService().translate('confirm')),
          ),
        ],
      ),
    );
  }

  /// Get notification color by type
  static Color getNotificationColor(String type) {
    switch (type) {
      case 'match_created':
      case 'match_joined':
        return Colors.green;
      case 'match_left':
        return Colors.orange;
      case 'team_invite':
      case 'team_join_request':
      case 'team_join_approved':
        return Colors.purple;
      case 'team_join_rejected':
      case 'team_member_left':
      case 'team_member_removed':
        return Colors.red;
      case 'match_request':
      case 'match_accepted':
        return Colors.blue;
      case 'match_rejected':
        return Colors.orange;
      case 'match_reminder':
        return Colors.amber;
      case 'system_notification':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get notification icon by type
  static IconData getNotificationIcon(String type) {
    switch (type) {
      case 'match_created':
        return Icons.sports_soccer;
      case 'match_joined':
        return Icons.person_add;
      case 'match_left':
        return Icons.exit_to_app;
      case 'team_invite':
      case 'team_join_request':
      case 'team_join_approved':
        return Icons.group_add;
      case 'team_join_rejected':
      case 'team_member_left':
      case 'team_member_removed':
        return Icons.person_remove;
      case 'match_request':
      case 'match_accepted':
      case 'match_rejected':
        return Icons.sports_soccer;
      case 'match_reminder':
        return Icons.alarm;
      case 'system_notification':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  /// Format date for notification display
  static String formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return LocalizationService().translate('just_now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays == 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return LocalizationService().translate('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Log notification action
  static void logNotificationAction(String action, NotificationModel notification) {
    logInfo('Notification action: $action for ${notification.type} (${notification.id})');
  }
}
