import 'package:flutter/material.dart';
import '../../colors/app_colors_extensions.dart';
import '../../typography/app_text_styles.dart';
import '../../spacing/app_spacing.dart';

/// DestructiveButton component following the design system specifications
/// - Background: AppColors.destructive (Red)
/// - Text: White
/// - Padding: 16px vertical, 24px horizontal
/// - Border radius: 12px
/// - Font: Inter, 16px, FontWeight.w600
/// - Hover: Scale 1.02, slight shadow
/// - Disabled: 50% opacity
/// - Supports loading states with spinner
/// - Accessibility features included
class DestructiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  const DestructiveButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  State<DestructiveButton> createState() => _DestructiveButtonState();
}

class _DestructiveButtonState extends State<DestructiveButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

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
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.text,
      hint: isEnabled ? 'Tap to ${widget.text.toLowerCase()}' : null,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _hoverAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.width,
                height: widget.height ?? 48.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  boxShadow: [
                    if (_hoverAnimation.value > 0)
                      BoxShadow(
                        color: context.colors.destructive.withValues(alpha: 0.3 * _hoverAnimation.value),
                        blurRadius: 8.0,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? widget.onPressed : null,
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    onHover: (hovering) {
                      if (hovering && isEnabled) {
                        _hoverController.forward();
                      } else {
                        _hoverController.reverse();
                      }
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? context.colors.destructive
                            : context.colors.destructive.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.buttonPaddingVertical,
                          horizontal: AppSpacing.buttonPaddingHorizontal,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.leadingIcon != null && !widget.isLoading) ...[
                              Icon(
                                widget.leadingIcon,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              const SizedBox(width: 8.0),
                            ],
                            if (widget.isLoading) ...[
                              const SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color.fromRGBO(255, 255, 255, 0.8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                            ],
                            Flexible(
                              child: Text(
                                widget.text,
                                style: AppTextStyles.buttonText.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.trailingIcon != null && !widget.isLoading) ...[
                              const SizedBox(width: 8.0),
                              Icon(
                                widget.trailingIcon,
                                color: Colors.white,
                                size: 20.0,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}