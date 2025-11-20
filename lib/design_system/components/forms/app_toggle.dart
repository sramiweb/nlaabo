import 'package:flutter/material.dart';
import '../../colors/app_colors_extensions.dart';

/// AppToggle component following the design system specifications
/// - Switch component with proper styling
/// - Theme-aware colors and animations
/// - Accessibility features included
/// - Smooth animations for state changes
/// - Customizable size and appearance
class AppToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final String? label;
  final String? description;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.description,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<AppToggle> createState() => _AppToggleState();
}

class _AppToggleState extends State<AppToggle> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _thumbController;
  late Animation<double> _thumbAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _thumbController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _thumbAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _thumbController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(AppToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      if (widget.value) {
        _animationController.forward();
        _thumbController.forward();
      } else {
        _animationController.reverse();
        _thumbController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.enabled && widget.onChanged != null) {
      widget.onChanged!(!widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;

    final activeColor = widget.activeColor ?? context.colors.primary;
    final inactiveColor = widget.inactiveColor ??
        (isLightMode ? context.colors.gray300 : context.colors.gray600);
    final thumbColor = widget.thumbColor ?? context.colors.surface;

    final trackWidth = widget.width ?? 52.0;
    final trackHeight = widget.height ?? 28.0;
    final thumbSize = trackHeight - 4.0;
    final padding = widget.padding ?? EdgeInsets.zero;

    return Semantics(
      toggled: widget.value,
      enabled: widget.enabled,
      label: widget.label,
      hint: widget.description,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: widget.enabled ? _handleTap : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.label != null) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.enabled
                                ? context.colors.textPrimary
                                : context.colors.textSubtle,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 2.0),
                          Text(
                            widget.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSubtle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                ],
                AnimatedBuilder(
                  animation: Listenable.merge([_animation, _thumbAnimation]),
                  builder: (context, child) {
                    final trackColor = Color.lerp(
                      inactiveColor,
                      activeColor,
                      _animation.value,
                    )!;

                    final thumbPosition = _animation.value * (trackWidth - thumbSize - 4.0) + 2.0;

                    return Container(
                      width: trackWidth,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: widget.enabled ? trackColor : trackColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                        boxShadow: [
                          if (widget.enabled && _animation.value > 0)
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.3),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Thumb
                          Positioned(
                            left: thumbPosition,
                            top: 2.0,
                            child: Container(
                              width: thumbSize,
                              height: thumbSize,
                              decoration: BoxDecoration(
                                color: widget.enabled ? thumbColor : thumbColor.withValues(alpha: 0.7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2.0,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: widget.enabled
                                  ? Icon(
                                      widget.value ? Icons.check : Icons.close,
                                      size: thumbSize * 0.5,
                                      color: widget.value ? activeColor : inactiveColor,
                                    )
                                  : null,
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
        ),
      ),
    );
  }
}
