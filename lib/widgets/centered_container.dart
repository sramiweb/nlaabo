import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/design_system.dart';

/// A container widget that centers content with responsive max-width constraints
/// as specified in the FootConnect design system.
class CenteredContainer extends StatelessWidget {
  /// The child widget to center
  final Widget child;

  /// Custom maximum width override (if null, uses responsive defaults)
  final double? maxWidth;

  /// Additional padding around the container
  final EdgeInsetsGeometry? padding;

  /// Whether to add responsive horizontal padding
  final bool addResponsivePadding;

  /// Background color for the container
  final Color? backgroundColor;

  /// Border radius for the container
  final double? borderRadius;

  const CenteredContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.addResponsivePadding = true,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? _getMaxWidth(context);
    final effectivePadding = padding ?? (addResponsivePadding ? _getResponsivePadding(context) : EdgeInsets.zero);

    return Container(
      width: double.infinity,
      color: backgroundColor,
      child: Padding(
        padding: effectivePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: effectiveMaxWidth,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  double _getMaxWidth(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        return double.infinity; // Full width on mobile
      case ScreenSize.tablet:
        return FootConnectBreakpoints.tabletContentMax; // 720px
      case ScreenSize.smallDesktop:
        return FootConnectBreakpoints.desktopContentMax; // 1200px
      case ScreenSize.desktop:
        return FootConnectBreakpoints.desktopContentMax; // 1200px
      case ScreenSize.ultraWide:
        return FootConnectBreakpoints.ultraWideContentMax; // 1200px (capped)
    }
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return const EdgeInsets.symmetric(horizontal: FootConnectSpacing.space3); // 12px
      case ScreenSize.largeMobile:
        return const EdgeInsets.symmetric(horizontal: FootConnectSpacing.space4); // 16px
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: FootConnectSpacing.space5); // 20px
      case ScreenSize.smallDesktop:
        return const EdgeInsets.symmetric(horizontal: FootConnectSpacing.space6); // 24px
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: FootConnectSpacing.space8); // 32px
      case ScreenSize.ultraWide:
        return const EdgeInsets.symmetric(horizontal: FootConnectSpacing.space10); // 40px
    }
  }
}

/// Extension method to easily wrap any widget with centered container constraints
extension CenteredContainerExtension on Widget {
  /// Wrap this widget with centered container constraints
  Widget inCenteredContainer({
    double? maxWidth,
    EdgeInsetsGeometry? padding,
    bool addResponsivePadding = true,
    Color? backgroundColor,
    double? borderRadius,
  }) {
    return CenteredContainer(
      maxWidth: maxWidth,
      padding: padding,
      addResponsivePadding: addResponsivePadding,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: this,
    );
  }
}

/// A section container that provides consistent spacing and centering for page sections
class SectionContainer extends StatelessWidget {
  /// The child widget for this section
  final Widget child;

  /// Custom maximum width override
  final double? maxWidth;

  /// Vertical padding for the section
  final double? verticalPadding;

  /// Background color for the section
  final Color? backgroundColor;

  /// Whether this section should have top and bottom margins
  final bool addVerticalMargins;

  const SectionContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.verticalPadding,
    this.backgroundColor,
    this.addVerticalMargins = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveVerticalPadding = verticalPadding ?? FootConnectSpacing.space6; // 24px default
    final effectiveVerticalMargin = addVerticalMargins ? FootConnectSpacing.space6 : 0.0;

    return Container(
      color: backgroundColor,
      margin: EdgeInsets.symmetric(vertical: effectiveVerticalMargin),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: effectiveVerticalPadding),
        child: CenteredContainer(
          maxWidth: maxWidth,
          addResponsivePadding: true,
          child: child,
        ),
      ),
    );
  }
}

/// Extension method for section containers
extension SectionContainerExtension on Widget {
  /// Wrap this widget in a section container
  Widget inSection({
    double? maxWidth,
    double? verticalPadding,
    Color? backgroundColor,
    bool addVerticalMargins = true,
  }) {
    return SectionContainer(
      maxWidth: maxWidth,
      verticalPadding: verticalPadding,
      backgroundColor: backgroundColor,
      addVerticalMargins: addVerticalMargins,
      child: this,
    );
  }
}
