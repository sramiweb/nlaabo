import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// A comprehensive responsive spacing system for FootConnect
class ResponsiveSpacing {
  // Base spacing values (in logical pixels)
  static const double space1 = 4.0;   // 4px - Extra small
  static const double space2 = 8.0;   // 8px - Small
  static const double space3 = 12.0;  // 12px - Medium
  static const double space4 = 16.0;  // 16px - Large
  static const double space5 = 20.0;  // 20px - Extra large
  static const double space6 = 24.0;  // 24px - 2XL
  static const double space7 = 32.0;  // 32px - 3XL
  static const double space8 = 40.0;  // 40px - 4XL
  static const double space9 = 48.0;  // 48px - 5XL
  static const double space10 = 64.0; // 64px - 6XL

  /// Get responsive spacing based on screen size
  static double getSpacing(BuildContext context, double baseSpacing) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return baseSpacing * 0.75; // Reduce spacing on very small screens
      case ScreenSize.smallMobile:
        return baseSpacing * 0.875; // Slightly reduce spacing
      case ScreenSize.largeMobile:
        return baseSpacing; // Base spacing
      case ScreenSize.tablet:
        return baseSpacing * 1.125; // Increase spacing for tablets
      case ScreenSize.smallDesktop:
        return baseSpacing * 1.25; // More spacing for small desktops
      case ScreenSize.desktop:
        return baseSpacing * 1.375; // Generous spacing for desktops
      case ScreenSize.ultraWide:
        return baseSpacing * 1.5; // Maximum spacing for ultra-wide
    }
  }

  /// Get responsive padding for containers
  static EdgeInsets getContainerPadding(BuildContext context) {
    final basePadding = ResponsiveUtils.getResponsivePadding(context);
    return basePadding;
  }

  /// Get responsive margin for components
  static EdgeInsets getComponentMargin(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return const EdgeInsets.all(8.0);
      case ScreenSize.smallMobile:
        return const EdgeInsets.all(10.0);
      case ScreenSize.largeMobile:
        return const EdgeInsets.all(12.0);
      case ScreenSize.tablet:
        return const EdgeInsets.all(16.0);
      case ScreenSize.smallDesktop:
        return const EdgeInsets.all(20.0);
      case ScreenSize.desktop:
        return const EdgeInsets.all(24.0);
      case ScreenSize.ultraWide:
        return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive gap between list items
  static double getListItemGap(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 8.0;
      case ScreenSize.smallMobile:
        return 10.0;
      case ScreenSize.largeMobile:
        return 12.0;
      case ScreenSize.tablet:
        return 16.0;
      case ScreenSize.smallDesktop:
        return 20.0;
      case ScreenSize.desktop:
        return 24.0;
      case ScreenSize.ultraWide:
        return 28.0;
    }
  }

  /// Get responsive section spacing
  static double getSectionSpacing(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 16.0;
      case ScreenSize.smallMobile:
        return 20.0;
      case ScreenSize.largeMobile:
        return 24.0;
      case ScreenSize.tablet:
        return 32.0;
      case ScreenSize.smallDesktop:
        return 40.0;
      case ScreenSize.desktop:
        return 48.0;
      case ScreenSize.ultraWide:
        return 64.0;
    }
  }

  /// Get responsive card spacing
  static EdgeInsets getCardSpacing(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return const EdgeInsets.all(12.0);
      case ScreenSize.smallMobile:
        return const EdgeInsets.all(14.0);
      case ScreenSize.largeMobile:
        return const EdgeInsets.all(16.0);
      case ScreenSize.tablet:
        return const EdgeInsets.all(20.0);
      case ScreenSize.smallDesktop:
        return const EdgeInsets.all(24.0);
      case ScreenSize.desktop:
        return const EdgeInsets.all(28.0);
      case ScreenSize.ultraWide:
        return const EdgeInsets.all(32.0);
    }
  }
}

/// Extension methods for responsive spacing
extension ResponsiveSpacingExtensions on BuildContext {
  /// Get responsive spacing value
  double responsiveSpacing(double baseSpacing) {
    return ResponsiveSpacing.getSpacing(this, baseSpacing);
  }

  /// Get responsive container padding
  EdgeInsets get spacingPadding => ResponsiveSpacing.getContainerPadding(this);

  /// Get responsive component margin
  EdgeInsets get responsiveMargin => ResponsiveSpacing.getComponentMargin(this);

  /// Get responsive list item gap
  double get listItemGap => ResponsiveSpacing.getListItemGap(this);

  /// Get responsive section spacing
  double get sectionSpacing => ResponsiveSpacing.getSectionSpacing(this);

  /// Get responsive card spacing
  EdgeInsets get cardSpacing => ResponsiveSpacing.getCardSpacing(this);
}

/// Pre-built spacing widgets
class ResponsiveSpacer extends StatelessWidget {
  final double height;

  const ResponsiveSpacer(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: context.responsiveSpacing(height));
  }
}

class ResponsiveHSpace extends StatelessWidget {
  final double width;

  const ResponsiveHSpace(this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: context.responsiveSpacing(width));
  }
}

class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? context.spacingPadding;
    return Padding(
      padding: effectivePadding,
      child: child,
    );
  }
}
