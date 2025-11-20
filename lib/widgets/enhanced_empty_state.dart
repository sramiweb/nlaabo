import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../services/localization_service.dart';
import '../utils/design_system.dart';

/// Enhanced empty state widget with illustrations and improved design
class EnhancedEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final String? titleTranslationKey;
  final String? messageTranslationKey;
  final IconData? icon;
  final Widget? illustration;
  final VoidCallback? onActionPressed;
  final String? actionText;
  final String? actionTranslationKey;
  final Color? iconColor;
  final Color? actionButtonColor;
  final double? iconSize;
  final EmptyStateType type;
  final bool showActionButton;

  const EnhancedEmptyState({
    super.key,
    this.title,
    this.message,
    this.titleTranslationKey,
    this.messageTranslationKey,
    this.icon,
    this.illustration,
    this.onActionPressed,
    this.actionText,
    this.actionTranslationKey,
    this.iconColor,
    this.actionButtonColor,
    this.iconSize,
    this.type = EmptyStateType.noData,
    this.showActionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = titleTranslationKey != null
        ? LocalizationService().translate(titleTranslationKey!)
        : title ?? _getDefaultTitle();

    final displayMessage = messageTranslationKey != null
        ? LocalizationService().translate(messageTranslationKey!)
        : message ?? _getDefaultMessage();

    final displayActionText = actionTranslationKey != null
        ? LocalizationService().translate(actionTranslationKey!)
        : actionText ?? _getDefaultActionText();

    final defaultIcon = icon ?? _getDefaultIcon();
    final defaultIconColor = iconColor ?? _getDefaultIconColor(context);

    return Center(
      child: Padding(
        padding: context.responsivePadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: context.maxContentWidth,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Illustration or Icon
              _buildIllustration(context, defaultIcon, defaultIconColor),

              SizedBox(height: context.itemSpacing * 1.5),

              // Title
              Text(
                displayTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: context.itemSpacing * 0.75),

              // Message
              Text(
                displayMessage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Action Button
              if (showActionButton && onActionPressed != null) ...[
                SizedBox(height: context.itemSpacing * 2.5),
                _buildActionButton(context, displayActionText),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context, IconData icon, Color color) {
    if (illustration != null) {
      return illustration!;
    }

    final size = iconSize ?? _getResponsiveIconSize(context);

    return Container(
      width: size * 2,
      height: size * 2,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String text) {
    return ElevatedButton.icon(
      onPressed: onActionPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: actionButtonColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(
          horizontal: context.itemSpacing * 2,
          vertical: context.itemSpacing * 1.25,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusSystem.medium),
        ),
        elevation: context.cardElevation,
      ),
      icon: Icon(
        _getActionIcon(),
        size: context.iconSize * 0.875,
      ),
      label: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double _getResponsiveIconSize(BuildContext context) {
    if (context.isMobile) return 48;
    if (context.isTablet) return 56;
    return 64;
  }

  String _getDefaultTitle() {
    switch (type) {
      case EmptyStateType.noData:
        return 'No Data Available';
      case EmptyStateType.noResults:
        return 'No Results Found';
      case EmptyStateType.noConnection:
        return 'No Internet Connection';
      case EmptyStateType.noFavorites:
        return 'No Favorites Yet';
      case EmptyStateType.noMatches:
        return 'No Matches Available';
      case EmptyStateType.noTeams:
        return 'No Teams Found';
      case EmptyStateType.emptyCart:
        return 'Your Cart is Empty';
      case EmptyStateType.noNotifications:
        return 'No Notifications';
    }
  }

  String _getDefaultMessage() {
    switch (type) {
      case EmptyStateType.noData:
        return 'There is no data to display at the moment. Please check back later.';
      case EmptyStateType.noResults:
        return 'We couldn\'t find any results matching your search. Try adjusting your filters.';
      case EmptyStateType.noConnection:
        return 'Please check your internet connection and try again.';
      case EmptyStateType.noFavorites:
        return 'Start adding items to your favorites to see them here.';
      case EmptyStateType.noMatches:
        return 'No matches are currently available. Create a new match to get started.';
      case EmptyStateType.noTeams:
        return 'No teams have been created yet. Be the first to create a team!';
      case EmptyStateType.emptyCart:
        return 'Your cart is empty. Add some items to get started.';
      case EmptyStateType.noNotifications:
        return 'You\'re all caught up! No new notifications at the moment.';
    }
  }

  String _getDefaultActionText() {
    switch (type) {
      case EmptyStateType.noData:
        return 'Refresh';
      case EmptyStateType.noResults:
        return 'Clear Filters';
      case EmptyStateType.noConnection:
        return 'Retry';
      case EmptyStateType.noFavorites:
        return 'Explore';
      case EmptyStateType.noMatches:
        return 'Create Match';
      case EmptyStateType.noTeams:
        return 'Create Team';
      case EmptyStateType.emptyCart:
        return 'Start Shopping';
      case EmptyStateType.noNotifications:
        return 'Explore App';
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case EmptyStateType.noData:
        return Icons.inbox;
      case EmptyStateType.noResults:
        return Icons.search_off;
      case EmptyStateType.noConnection:
        return Icons.wifi_off;
      case EmptyStateType.noFavorites:
        return Icons.favorite_border;
      case EmptyStateType.noMatches:
        return Icons.sports_soccer;
      case EmptyStateType.noTeams:
        return Icons.group_add;
      case EmptyStateType.emptyCart:
        return Icons.shopping_cart_outlined;
      case EmptyStateType.noNotifications:
        return Icons.notifications_none;
    }
  }

  Color _getDefaultIconColor(BuildContext context) {
    switch (type) {
      case EmptyStateType.noConnection:
        return Theme.of(context).colorScheme.error;
      case EmptyStateType.noResults:
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getActionIcon() {
    switch (type) {
      case EmptyStateType.noData:
        return Icons.refresh;
      case EmptyStateType.noResults:
        return Icons.filter_list_off;
      case EmptyStateType.noConnection:
        return Icons.refresh;
      case EmptyStateType.noFavorites:
        return Icons.explore;
      case EmptyStateType.noMatches:
        return Icons.add;
      case EmptyStateType.noTeams:
        return Icons.add;
      case EmptyStateType.emptyCart:
        return Icons.shopping_bag;
      case EmptyStateType.noNotifications:
        return Icons.explore;
    }
  }
}

/// Types of empty states for better semantic meaning
enum EmptyStateType {
  noData,
  noResults,
  noConnection,
  noFavorites,
  noMatches,
  noTeams,
  emptyCart,
  noNotifications,
}

/// Pre-configured empty state widgets for common scenarios
class EmptyStatePresets {
  /// No data available state
  static EnhancedEmptyState noData({
    VoidCallback? onRefresh,
    String? customTitle,
    String? customMessage,
  }) {
    return EnhancedEmptyState(
      type: EmptyStateType.noData,
      title: customTitle,
      message: customMessage,
      onActionPressed: onRefresh,
    );
  }

  /// No search results state
  static EnhancedEmptyState noResults({
    VoidCallback? onClearFilters,
    String? customTitle,
    String? customMessage,
  }) {
    return EnhancedEmptyState(
      type: EmptyStateType.noResults,
      title: customTitle,
      message: customMessage,
      onActionPressed: onClearFilters,
    );
  }

  /// No internet connection state
  static EnhancedEmptyState noConnection({
    VoidCallback? onRetry,
    String? customTitle,
    String? customMessage,
  }) {
    return EnhancedEmptyState(
      type: EmptyStateType.noConnection,
      title: customTitle,
      message: customMessage,
      onActionPressed: onRetry,
    );
  }

  /// No matches available state
  static EnhancedEmptyState noMatches({
    VoidCallback? onCreateMatch,
    String? customTitle,
    String? customMessage,
  }) {
    return EnhancedEmptyState(
      type: EmptyStateType.noMatches,
      title: customTitle,
      message: customMessage,
      onActionPressed: onCreateMatch,
    );
  }

  /// No teams available state
  static EnhancedEmptyState noTeams({
    VoidCallback? onCreateTeam,
    String? customTitle,
    String? customMessage,
  }) {
    return EnhancedEmptyState(
      type: EmptyStateType.noTeams,
      title: customTitle,
      message: customMessage,
      onActionPressed: onCreateTeam,
    );
  }

  /// No favorites state
  static EnhancedEmptyState noFavorites({
    VoidCallback? onExplore,
    String? customTitle,
    String? customMessage,
  }) {
    return EnhancedEmptyState(
      type: EmptyStateType.noFavorites,
      title: customTitle,
      message: customMessage,
      onActionPressed: onExplore,
    );
  }
}
