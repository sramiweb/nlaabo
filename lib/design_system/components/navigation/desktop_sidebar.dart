import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/colors/app_colors.dart';
import '../../../design_system/spacing/app_spacing.dart';
import '../../../design_system/typography/app_text_styles.dart';
import '../../../constants/responsive_constants.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/localization_provider.dart';

/// DesktopSidebar component with fixed width and dark background
/// as specified in the design system specifications
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, LocalizationProvider>(
      builder: (context, navigationProvider, localizationProvider, child) {
        return Container(
          width: AppSpacing.sidebarWidth,
          color: AppColors.darkSurface, // Always dark charcoal (#1F2937)
          child: Column(
            children: [
              // Logo/Brand area
              Container(
                height: 80,
                padding: AppSpacing.screenPaddingInsets,
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/icons/logo.png',
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),

              // Navigation items
              Expanded(
                child: Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    return ListView(
                      padding: EdgeInsets.zero,
                      children: NavigationProvider.navigationItems.map((item) {
                        final isActive = navigationProvider.isItemActive(item.route);
                        final badgeCount = item.route == '/notifications' ? notificationProvider.unreadCount : 0;
                        return _NavigationItemWidget(
                          item: item,
                          isActive: isActive,
                          badgeCount: badgeCount,
                          onTap: () {
                            navigationProvider.setCurrentRoute(item.route);
                            context.go(item.route);
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),


            ],
          ),
        );
      },
    );
  }
}

/// Individual navigation item widget
class _NavigationItemWidget extends StatefulWidget {
  final NavigationItem item;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavigationItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_NavigationItemWidget> createState() => _NavigationItemWidgetState();
}

class _NavigationItemWidgetState extends State<_NavigationItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final responsiveHorizontalPadding = ResponsiveConstants.getResponsiveSpacing(context, 'lg');
    final responsiveIconSpacing = ResponsiveConstants.getResponsiveSpacing(context, 'lg');

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.item.label,
      child: Focus(
        autofocus: widget.isActive,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 44.0, // Minimum touch target size (WCAG AA)
            minWidth: 44.0,
          ),
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) {
              setState(() => _isHovered = hovered);
            },
            child: Container(
              height: 56, // Keep fixed height for consistent desktop sidebar
              padding: EdgeInsets.symmetric(horizontal: responsiveHorizontalPadding),
              decoration: BoxDecoration(
                border: Directionality.of(context) == TextDirection.rtl
                    ? Border(
                        right: BorderSide(
                          color: widget.isActive ? AppColors.primary : Colors.transparent,
                          width: 4,
                        ),
                      )
                    : Border(
                        left: BorderSide(
                          color: widget.isActive ? AppColors.primary : Colors.transparent,
                          width: 4,
                        ),
                      ),
                color: widget.isActive
                    ? AppColors.primary.withOpacity(0.1)
                    : _isHovered
                        ? AppColors.darkBorder.withOpacity(0.3)
                        : Colors.transparent,
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        widget.item.icon,
                        size: AppSpacing.iconSize,
                        color: widget.isActive
                            ? AppColors.primary
                            : AppColors.darkTextSubtle,
                      ),
                      if (widget.badgeCount > 0)
                        Positioned(
                          right: -8,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              widget.badgeCount > 99 ? '99+' : widget.badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: responsiveIconSpacing),
                  Expanded(
                    child: Text(
                      widget.item.label,
                      style: AppTextStyles.bodyText.copyWith(
                        color: widget.isActive
                            ? AppColors.primary
                            : AppColors.darkTextSubtle,
                        fontWeight: widget.isActive
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
