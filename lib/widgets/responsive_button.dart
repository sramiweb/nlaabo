import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/design_system.dart';

/// Enum for button size types
enum ButtonSize {
  /// Small button size
  small,

  /// Medium button size (default)
  medium,

  /// Large button size
  large,
}

/// Enum for button variants
enum ButtonVariant {
  /// Primary button with gradient background
  primary,

  /// Secondary button with outline
  secondary,

  /// Text-only button
  text,

  /// Icon-only button
  icon,
}

/// A comprehensive button widget that implements the FootConnect design system
/// with gradients, proper styling, animations, and responsive behavior.
class FootConnectButton extends StatefulWidget {
  /// The button text
  final String? text;

  /// The button icon
  final IconData? icon;

  /// The size of the button
  final ButtonSize size;

  /// The variant of the button
  final ButtonVariant variant;

  /// Whether the button should take full width
  final bool fullWidth;

  /// Whether the button is disabled
  final bool disabled;

  /// Whether to show loading state
  final bool loading;

  /// The callback when button is pressed
  final VoidCallback? onPressed;

  /// Custom width override
  final double? width;

  /// Custom height override
  final double? height;

  const FootConnectButton({
    super.key,
    this.text,
    this.icon,
    this.size = ButtonSize.medium,
    this.variant = ButtonVariant.primary,
    this.fullWidth = false,
    this.disabled = false,
    this.loading = false,
    this.onPressed,
    this.width,
    this.height,
  }) : assert(text != null || icon != null, 'Either text or icon must be provided');

  @override
  State<FootConnectButton> createState() => _FootConnectButtonState();
}

class _FootConnectButtonState extends State<FootConnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: FootConnectAnimations.fastDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: FootConnectAnimations.buttonPressScale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: FootConnectAnimations.materialCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled && !widget.loading) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.disabled || widget.loading;
    final effectiveOnPressed = isDisabled ? null : widget.onPressed;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: Semantics(
              button: true,
              enabled: !isDisabled,
              label: widget.text ?? 'Button',
              hint: 'Tap to activate',
              child: Container(
                width: widget.width ?? _getButtonWidth(context),
                height: widget.height ?? _getButtonHeight(context),
                decoration: _getButtonDecoration(context, isDisabled),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: effectiveOnPressed,
                    borderRadius: BorderRadius.circular(FootConnectBorderRadius.button),
                    child: _buildButtonContent(context, isDisabled),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getButtonDecoration(BuildContext context, bool isDisabled) {
    switch (widget.variant) {
      case ButtonVariant.primary:
        return BoxDecoration(
          gradient: isDisabled
              ? null
              : FootConnectColors.primaryGradient,
          color: isDisabled ? FootConnectColors.neutralGray : null,
          borderRadius: BorderRadius.circular(FootConnectBorderRadius.button),
          boxShadow: isDisabled
              ? null
              : [FootConnectShadows.buttonShadow],
        );

      case ButtonVariant.secondary:
        return BoxDecoration(
          color: isDisabled
              ? FootConnectColors.neutralGray.withValues(alpha: 0.1)
              : FootConnectColors.backgroundPrimary,
          border: Border.all(
            color: isDisabled
                ? FootConnectColors.neutralGray.withValues(alpha: 0.3)
                : FootConnectColors.primaryBlue,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(FootConnectBorderRadius.button),
        );

      case ButtonVariant.text:
        return const BoxDecoration(
          color: Colors.transparent,
        );

      case ButtonVariant.icon:
        return BoxDecoration(
          color: isDisabled
              ? FootConnectColors.neutralGray.withValues(alpha: 0.1)
              : FootConnectColors.backgroundTertiary,
          borderRadius: BorderRadius.circular(FootConnectBorderRadius.button),
        );
    }
  }

  Widget _buildButtonContent(BuildContext context, bool isDisabled) {
    final textStyle = _getTextStyle(context, isDisabled);
    final iconSize = _getIconSize(context);

    if (widget.loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(FootConnectColors.primaryBlue),
          ),
        ),
      );
    }

    final children = <Widget>[];

    if (widget.icon != null) {
      children.add(Icon(
        widget.icon,
        size: iconSize,
        color: _getIconColor(isDisabled),
      ));

      if (widget.text != null) {
        children.add(const SizedBox(width: 6.0)); // Reduced spacing for compactness
      }
    }

    if (widget.text != null) {
      children.add(Text(
        widget.text!,
        style: textStyle,
        textAlign: TextAlign.center,
      ));
    }

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  double _getButtonWidth(BuildContext context) {
    if (widget.fullWidth) return double.infinity;

    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (widget.size) {
      case ButtonSize.small:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
            return 80.0;
          case ScreenSize.largeMobile:
            return 100.0;
          case ScreenSize.tablet:
            return 120.0;
          case ScreenSize.smallDesktop:
            return 140.0;
          case ScreenSize.desktop:
            return 160.0;
          case ScreenSize.ultraWide:
            return 180.0;
        }
      case ButtonSize.medium:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
            return 120.0;
          case ScreenSize.largeMobile:
            return 140.0;
          case ScreenSize.tablet:
            return 160.0;
          case ScreenSize.smallDesktop:
            return 180.0;
          case ScreenSize.desktop:
            return 200.0;
          case ScreenSize.ultraWide:
            return 220.0;
        }
      case ButtonSize.large:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
            return 160.0;
          case ScreenSize.largeMobile:
            return 180.0;
          case ScreenSize.tablet:
            return 200.0;
          case ScreenSize.smallDesktop:
            return 220.0;
          case ScreenSize.desktop:
            return 240.0;
          case ScreenSize.ultraWide:
            return 260.0;
        }
    }
  }

  double _getButtonHeight(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (widget.size) {
      case ButtonSize.small:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
          case ScreenSize.largeMobile:
            return 28.0; // Mobile: 28px for small buttons
          case ScreenSize.tablet:
            return 30.0; // Tablet: 30px for small buttons
          case ScreenSize.smallDesktop:
          case ScreenSize.desktop:
          case ScreenSize.ultraWide:
            return 32.0; // Desktop: 32px for small buttons
        }

      case ButtonSize.medium:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
          case ScreenSize.largeMobile:
            return 44.0; // Mobile: 44px for medium buttons
          case ScreenSize.tablet:
            return 46.0; // Tablet: 46px for medium buttons
          case ScreenSize.smallDesktop:
          case ScreenSize.desktop:
          case ScreenSize.ultraWide:
            return 48.0; // Desktop: 48px for medium buttons
        }

      case ButtonSize.large:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
          case ScreenSize.largeMobile:
            return 48.0; // Mobile: 48px for large buttons
          case ScreenSize.tablet:
            return 50.0; // Tablet: 50px for large buttons
          case ScreenSize.smallDesktop:
          case ScreenSize.desktop:
          case ScreenSize.ultraWide:
            return 52.0; // Desktop: 52px for large buttons
        }
    }
  }

  double _getIconSize(BuildContext context) {
    // Reduced icon sizes for more compact buttons
    switch (widget.size) {
      case ButtonSize.small:
        return 14.0;
      case ButtonSize.medium:
        return 16.0;
      case ButtonSize.large:
        return 18.0;
    }
  }

  TextStyle _getTextStyle(BuildContext context, bool isDisabled) {
    final baseStyle = _getBaseTextStyle();

    if (isDisabled) {
      return baseStyle.copyWith(
        color: FootConnectColors.neutralGray.withValues(alpha: 0.5),
      );
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return baseStyle.copyWith(
          color: FootConnectColors.textInverse,
        );
      case ButtonVariant.secondary:
      case ButtonVariant.icon:
        return baseStyle.copyWith(
          color: FootConnectColors.primaryBlue,
        );
      case ButtonVariant.text:
        return baseStyle.copyWith(
          color: FootConnectColors.primaryBlue,
          decoration: TextDecoration.underline,
        );
    }
  }

  TextStyle _getBaseTextStyle() {
    switch (widget.size) {
      case ButtonSize.small:
        return FootConnectTypography.buttonSmallStyle;
      case ButtonSize.medium:
        return FootConnectTypography.buttonRegularStyle;
      case ButtonSize.large:
        return FootConnectTypography.buttonLargeStyle;
    }
  }

  Color _getIconColor(bool isDisabled) {
    if (isDisabled) {
      return FootConnectColors.neutralGray.withValues(alpha: 0.5);
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
        return FootConnectColors.textInverse;
      case ButtonVariant.secondary:
      case ButtonVariant.icon:
      case ButtonVariant.text:
        return FootConnectColors.primaryBlue;
    }
  }
}

/// Legacy wrapper for backward compatibility
/// TODO: Gradually migrate to FootConnectButton
class ResponsiveButton extends StatelessWidget {
  final Widget child;
  final ButtonSize size;
  final bool fullWidth;

  const ResponsiveButton({
    super.key,
    required this.child,
    this.size = ButtonSize.medium,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _getButtonHeight(context),
      width: fullWidth ? double.infinity : _getButtonWidth(context),
      child: child,
    );
  }

  double _getButtonHeight(BuildContext context) {
    final baseHeight = ResponsiveUtils.getButtonHeight(context);

    switch (size) {
      case ButtonSize.small:
        return baseHeight * 0.8;
      case ButtonSize.medium:
        return baseHeight;
      case ButtonSize.large:
        return baseHeight * 1.2;
    }
  }

  double _getButtonWidth(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (size) {
      case ButtonSize.small:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
            return 80.0;
          case ScreenSize.largeMobile:
            return 100.0;
          case ScreenSize.tablet:
            return 120.0;
          case ScreenSize.smallDesktop:
            return 140.0;
          case ScreenSize.desktop:
            return 160.0;
          case ScreenSize.ultraWide:
            return 180.0;
        }
      case ButtonSize.medium:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
            return 120.0;
          case ScreenSize.largeMobile:
            return 140.0;
          case ScreenSize.tablet:
            return 160.0;
          case ScreenSize.smallDesktop:
            return 180.0;
          case ScreenSize.desktop:
            return 200.0;
          case ScreenSize.ultraWide:
            return 220.0;
        }
      case ButtonSize.large:
        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
            return 160.0;
          case ScreenSize.largeMobile:
            return 180.0;
          case ScreenSize.tablet:
            return 200.0;
          case ScreenSize.smallDesktop:
            return 220.0;
          case ScreenSize.desktop:
            return 240.0;
          case ScreenSize.ultraWide:
            return 260.0;
        }
    }
  }
}

/// Extension method to easily wrap any button widget with responsive sizing
extension ResponsiveButtonExtension on Widget {
  /// Wrap this widget with responsive button sizing
  Widget asResponsiveButton({
    ButtonSize size = ButtonSize.medium,
    bool fullWidth = false,
  }) {
    return ResponsiveButton(
      size: size,
      fullWidth: fullWidth,
      child: this,
    );
  }
}