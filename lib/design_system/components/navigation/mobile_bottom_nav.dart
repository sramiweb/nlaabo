import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../design_system/colors/app_colors_extensions.dart';
import '../../../design_system/spacing/app_spacing.dart';
import '../../../design_system/typography/app_text_styles.dart';
import '../../../constants/responsive_constants.dart';
import '../../../providers/navigation_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/localization_provider.dart';
import '../../../services/localization_service.dart';

/// MobileBottomNav component with glassmorphism effect
/// as specified in the design system specifications
class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, LocalizationProvider>(
      builder: (context, navigationProvider, localizationProvider, child) {
        final responsiveSpacing = ResponsiveConstants.getResponsiveSpacing(context, 'md');
        final responsiveBottomSpacing = ResponsiveConstants.getResponsiveSpacing(context, 'xs');
        final responsiveBorderRadius = ResponsiveConstants.getResponsiveSpacing(context, 'xl');

        return SafeArea(
          child: Container(
            height: AppSpacing.navBarHeight, // Keep fixed height for consistent nav bar
            margin: EdgeInsets.only(
              left: responsiveSpacing,
              right: responsiveSpacing,
              bottom: responsiveBottomSpacing,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(responsiveBorderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface.withValues(alpha: 0.8),
                    border: Border.all(
                      color: context.colors.border.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(responsiveBorderRadius),
                  ),
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: NavigationProvider.navigationItems.map((item) {
                          final isActive = navigationProvider.isItemActive(item.route);
                          final badgeCount = item.route == '/notifications' ? notificationProvider.unreadCount : 0;
                          return Expanded(
                            child: _NavigationItemWidget(
                              item: item,
                              isActive: isActive,
                              badgeCount: badgeCount,
                              onTap: () {
                                navigationProvider.setCurrentRoute(item.route);
                                context.go(item.route);
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Individual navigation item widget for mobile bottom nav
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

class _NavigationItemWidgetState extends State<_NavigationItemWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(_NavigationItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsiveVerticalPadding = ResponsiveConstants.getResponsiveSpacing(context, 'sm');
    final responsiveHorizontalPadding = ResponsiveConstants.getResponsiveSpacing(context, 'xs');
    final responsiveBorderRadius = ResponsiveConstants.getResponsiveSpacing(context, 'md');
    final responsiveIconSpacing = ResponsiveConstants.getResponsiveSpacing(context, 'xs');

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: LocalizationService().translate(widget.item.labelKey),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 44.0, // Minimum touch target size (WCAG AA)
          minWidth: 44.0,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(responsiveBorderRadius),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: responsiveVerticalPadding,
                    horizontal: responsiveHorizontalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            widget.item.icon,
                            size: 24,
                            color: widget.isActive
                                ? context.colors.primary
                                : context.colors.textSubtle,
                          ),
                          if (widget.badgeCount > 0)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  widget.badgeCount > 9 ? '9+' : widget.badgeCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: responsiveIconSpacing),
                      Flexible(
                        child: Text(
                          LocalizationService().translate(widget.item.mobileLabelKey ?? widget.item.labelKey),
                          style: AppTextStyles.caption.copyWith(
                            color: widget.isActive
                                ? context.colors.primary
                                : context.colors.textSubtle,
                            fontSize: 11,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
