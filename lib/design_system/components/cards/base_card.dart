import 'package:flutter/material.dart';
import '../../colors/app_colors_extensions.dart';
import '../../spacing/app_spacing.dart';

/// BaseCard component following the design system specifications
/// - Background: Theme-based surface color (AppColors.surface)
/// - Border: 1px solid theme border color (AppColors.border)
/// - Border radius: 16px (AppSpacing.borderRadiusXl)
/// - Padding: 24px (AppSpacing.xl)
/// - Hover: Border color changes to primary (AppColors.primary), subtle glow
/// - Shadow: Subtle elevation in light mode
/// - Theme-aware and responsive
/// - Supports hover states and animations
/// - Accessibility features included
class BaseCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool isHoverable;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final double? elevation;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.isHoverable = true,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.elevation,
  });

  @override
  State<BaseCard> createState() => _BaseCardState();
}

class _BaseCardState extends State<BaseCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    if (widget.isHoverable) {
      if (hovering) {
        _hoverController.forward();
        _glowController.forward();
      } else {
        _hoverController.reverse();
        _glowController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    final backgroundColor = widget.backgroundColor ?? context.colors.surface;
    final borderColor = widget.borderColor ?? context.colors.border;
    final borderRadius = widget.borderRadius ?? AppSpacing.borderRadiusXl;
    final padding = widget.padding ?? const EdgeInsets.all(AppSpacing.xl);
    final elevation = widget.elevation ?? (isLightMode ? 2.0 : 0.0);

    return Semantics(
      container: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverAnimation, _glowAnimation]),
        builder: (context, child) {
          final currentBorderColor = Color.lerp(
            borderColor,
            context.colors.primary,
            _hoverAnimation.value,
          )!;

          final glowOpacity = _glowAnimation.value * 0.1;

          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: currentBorderColor,
                width: 1.0,
              ),
              boxShadow: [
                if (elevation > 0)
                  BoxShadow(
                    color: context.colors.gray900.withValues(alpha: 0.1 * elevation),
                    blurRadius: elevation * 4,
                    offset: Offset(0, elevation),
                  ),
                if (_glowAnimation.value > 0)
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: glowOpacity),
                    blurRadius: 12.0,
                    spreadRadius: 2.0,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTap: widget.onTap,
                onHover: _handleHover,
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding,
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}