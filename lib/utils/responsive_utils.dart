import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/responsive_constants.dart';

/// Enhanced breakpoints for granular responsive design
class ResponsiveBreakpoints {
  // Mobile breakpoints (320px-768px)
  static const double extraSmallMobileMaxWidth = 320;
  static const double smallMobileMaxWidth = 360;
  static const double largeMobileMaxWidth = 480;
  static const double mobileMaxWidth = 768; // End of mobile range

  // Tablet breakpoints (768px-1024px)
  static const double tabletMinWidth = 768;
  static const double tabletMaxWidth = 1024;

  // Desktop breakpoints (1024px+)
  static const double desktopMinWidth = 1024;
  static const double ultraWideMinWidth = 1920;
  static const double maxContentWidth = 1200;
}

/// Enhanced screen size types for granular responsive design
enum ScreenSize {
  extraSmallMobile, // <320px
  smallMobile,      // 320-360px
  largeMobile,      // 360-480px
  tablet,           // 480-768px (mobile to tablet transition)
  smallDesktop,     // 768-1024px (tablet to desktop transition)
  desktop,          // 1024-1920px
  ultraWide,        // >1920px
}

/// Web-specific responsive utilities for ultra-wide screen support
class WebResponsiveUtils {
  /// Get maximum content width for ultra-wide screens
  /// Returns 1200px max width for screens >1920px, otherwise 80% of screen width
  static double getMaxContentWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Max content width of 1200px for ultra-wide screens
    return math.min(screenWidth * 0.8, 1200.0);
  }

  /// Get content padding that centers content on ultra-wide screens
  static EdgeInsets getContentPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1920) {
      // Center content on ultra-wide screens
      final sidePadding = (screenWidth - 1200.0) / 2;
      return EdgeInsets.symmetric(horizontal: math.max(sidePadding, 24.0));
    }
    return const EdgeInsets.symmetric(horizontal: 24.0);
  }
}

/// Responsive utilities for FootConnect Flutter app
/// Provides breakpoints, helper methods, and responsive design patterns
class ResponsiveUtils {
  // Enhanced breakpoints for granular responsive design
  static const double extraSmallMobileMaxWidth = 320;
  static const double smallMobileMaxWidth = 360;
  static const double largeMobileMaxWidth = 480;
  static const double tabletMaxWidth = 600; // Optimized tablet range (480-600px)
  static const double desktopMaxWidth = 1024;
  static const double ultraWideMinWidth = 1920;

  // Legacy breakpoints for backward compatibility
  static const double mobileMaxWidth = 600;

  // Touch target minimum sizes (WCAG AAA min 44dp; keep compact density for mobile)
  static const double minTouchTargetSize = 44.0;
  static const double minButtonHeight = 44.0;

  /// Get current screen size based on width with enhanced breakpoints
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < ResponsiveBreakpoints.extraSmallMobileMaxWidth) {
      return ScreenSize.extraSmallMobile;
    } else if (width < ResponsiveBreakpoints.smallMobileMaxWidth) {
      return ScreenSize.smallMobile;
    } else if (width < ResponsiveBreakpoints.largeMobileMaxWidth) {
      return ScreenSize.largeMobile;
    } else if (width < ResponsiveBreakpoints.mobileMaxWidth) {
      return ScreenSize.tablet;
    } else if (width < ResponsiveBreakpoints.tabletMaxWidth) {
      return ScreenSize.smallDesktop;
    } else if (width < ResponsiveBreakpoints.ultraWideMinWidth) {
      return ScreenSize.desktop;
    } else {
      return ScreenSize.ultraWide;
    }
  }

  /// Check if device is small mobile (320-360px)
  static bool isSmallMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.extraSmallMobileMaxWidth && width < ResponsiveBreakpoints.smallMobileMaxWidth;
  }

  /// Check if device is extra small mobile (<320px)
  static bool isExtraSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < ResponsiveBreakpoints.extraSmallMobileMaxWidth;
  }

  /// Get responsive padding for small mobile devices
  static EdgeInsets getSmallMobilePadding(BuildContext context) {
    if (isExtraSmallMobile(context)) {
      return const EdgeInsets.all(8.0); // Enhanced padding for <320px devices
    } else if (isSmallMobile(context)) {
      return const EdgeInsets.all(12.0); // Enhanced padding for 320-360px devices
    }
    return getResponsivePadding(context);
  }

  /// Get responsive font size for small mobile devices
  static double getSmallMobileFontSize(BuildContext context, double baseSize) {
    if (isExtraSmallMobile(context)) {
      return baseSize * 0.8; // Enhanced font scaling for <320px devices
    } else if (isSmallMobile(context)) {
      return baseSize * 0.9; // Enhanced font scaling for 320-360px devices
    }
    return baseSize;
  }

  /// Check if device is large mobile (360-480px)
  static bool isLargeMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.smallMobileMaxWidth && width < ResponsiveBreakpoints.largeMobileMaxWidth;
  }

  /// Check if device is in mobile range (320px-768px)
  static bool isMobileRange(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.extraSmallMobileMaxWidth && width < ResponsiveBreakpoints.mobileMaxWidth;
  }

  /// Check if device is in tablet range (768px-1024px)
  static bool isTabletRange(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= ResponsiveBreakpoints.tabletMinWidth && width < ResponsiveBreakpoints.tabletMaxWidth;
  }

  /// Check if device is in desktop range (1024px+)
  static bool isDesktopRange(BuildContext context) {
    return MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktopMinWidth;
  }

  /// Check if current screen is mobile (any mobile size)
  static bool isMobile(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.extraSmallMobile ||
           screenSize == ScreenSize.smallMobile ||
           screenSize == ScreenSize.largeMobile;
  }

  /// Check if current screen is tablet (any tablet size)
  static bool isTablet(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.tablet;
  }

  /// Check if current screen is desktop (any desktop size)
  static bool isDesktop(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.smallDesktop ||
           screenSize == ScreenSize.desktop ||
           screenSize == ScreenSize.ultraWide;
  }

  /// Check if current screen is ultra-wide (>1920px)
  static bool isUltraWide(BuildContext context) {
    return getScreenSize(context) == ScreenSize.ultraWide;
  }

  /// Check if device is in landscape orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Check if device is in portrait orientation
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return const EdgeInsets.all(12.0); // Mobile: compact padding
      case ScreenSize.largeMobile:
        return const EdgeInsets.all(16.0); // Mobile: standard padding
      case ScreenSize.tablet:
        return const EdgeInsets.all(20.0); // Tablet: increased padding
      case ScreenSize.smallDesktop:
        return const EdgeInsets.all(24.0); // Small desktop: moderate padding
      case ScreenSize.desktop:
        return const EdgeInsets.all(32.0); // Desktop: generous padding
      case ScreenSize.ultraWide:
        return const EdgeInsets.all(40.0); // Ultra-wide: spacious padding
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return const EdgeInsets.symmetric(horizontal: 12.0);
      case ScreenSize.largeMobile:
        return const EdgeInsets.symmetric(horizontal: 16.0);
      case ScreenSize.tablet:
        return const EdgeInsets.symmetric(horizontal: 20.0);
      case ScreenSize.smallDesktop:
        return const EdgeInsets.symmetric(horizontal: 28.0);
      case ScreenSize.desktop:
        return const EdgeInsets.symmetric(horizontal: 32.0);
      case ScreenSize.ultraWide:
        return const EdgeInsets.symmetric(horizontal: 40.0);
    }
  }

  /// Get responsive card width for horizontal lists
  static double getCardWidth(BuildContext context, {double? maxWidth}) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return maxWidth ?? (screenWidth * 0.9); // Mobile: 90% for better visibility
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        return maxWidth ?? (screenWidth * 0.85); // Mobile: 85% of screen width
      case ScreenSize.tablet:
        return maxWidth ?? 280.0; // Tablet: fixed width for consistency
      case ScreenSize.smallDesktop:
        return maxWidth ?? 320.0; // Small desktop: larger cards
      case ScreenSize.desktop:
        return maxWidth ?? 360.0; // Desktop: generous card width
      case ScreenSize.ultraWide:
        return maxWidth ?? 400.0; // Ultra-wide: spacious cards
    }
  }

  /// Get responsive grid cross axis count
  static int getGridCrossAxisCount(
    BuildContext context, {
    int extraSmallMobileCount = 1,
    int smallMobileCount = 1,
    int largeMobileCount = 1,
    int tabletCount = 2,
    int smallDesktopCount = 3,
    int desktopCount = 3,
    int ultraWideCount = 4,
  }) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return extraSmallMobileCount;
      case ScreenSize.smallMobile:
        return smallMobileCount;
      case ScreenSize.largeMobile:
        return largeMobileCount;
      case ScreenSize.tablet:
        return tabletCount;
      case ScreenSize.smallDesktop:
        return smallDesktopCount;
      case ScreenSize.desktop:
        return desktopCount;
      case ScreenSize.ultraWide:
        return ultraWideCount;
    }
  }

  /// Get responsive spacing between items
  static double getItemSpacing(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return 10.0;
      case ScreenSize.largeMobile:
        return 12.0;
      case ScreenSize.tablet:
        return 14.0;
      case ScreenSize.smallDesktop:
        return 18.0;
      case ScreenSize.desktop:
        return 20.0;
      case ScreenSize.ultraWide:
        return 24.0;
    }
  }

  /// Get responsive text scale factor
  static double getTextScaleFactor(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 0.9; // Mobile: smaller text for very small screens
      case ScreenSize.smallMobile:
        return 0.95; // Mobile: slightly smaller text
      case ScreenSize.largeMobile:
        return 1.0; // Mobile: base text size
      case ScreenSize.tablet:
        return 1.05; // Tablet: slightly larger text
      case ScreenSize.smallDesktop:
        return 1.1; // Small desktop: moderate scaling
      case ScreenSize.desktop:
        return 1.15; // Desktop: comfortable reading size
      case ScreenSize.ultraWide:
        return 1.2; // Ultra-wide: larger text for better readability
    }
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context, double baseSize) {
    final scaleFactor = getTextScaleFactor(context);
    return baseSize * scaleFactor;
  }

  /// Get responsive button height (compact on mobile)
  static double getButtonHeight(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        // Minimum compact height on small mobiles
        return minButtonHeight; // 44
      case ScreenSize.largeMobile:
        return 46.0;
      case ScreenSize.tablet:
        return 48.0;
      case ScreenSize.smallDesktop:
        return 52.0;
      case ScreenSize.desktop:
        return 56.0;
      case ScreenSize.ultraWide:
        return 60.0;
    }
  }

  /// Get responsive max width for centered content
  static double getMaxContentWidth(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        return double.infinity; // Mobile: full width
      case ScreenSize.tablet:
        return 600.0; // Tablet: constrained width for readability
      case ScreenSize.smallDesktop:
        return 800.0; // Small desktop: moderate width
      case ScreenSize.desktop:
        return 1000.0; // Desktop: generous content width
      case ScreenSize.ultraWide:
        return 1200.0; // Ultra-wide: max content width
    }
  }

  /// Get responsive form field width
  static double getFormFieldWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        // Mobile: full width for usability, constrained on web for readability
        if (kIsWeb) {
          return math.min(screenWidth * 0.95, 480.0);
        }
        return double.infinity;
      case ScreenSize.tablet:
        return 520.0; // Tablet: optimal form width
      case ScreenSize.smallDesktop:
        return 580.0; // Small desktop: larger forms
      case ScreenSize.desktop:
        return 640.0; // Desktop: generous form width
      case ScreenSize.ultraWide:
        return 640.0; // Ultra-wide: max form width
    }
  }

  /// Get responsive side navigation width
  static double getResponsiveSideNavWidth(BuildContext context) {
    final screenSize = getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        return 280.0; // Mobile: wider for better usability
      case ScreenSize.tablet:
        return 260.0; // Tablet: moderate width
      case ScreenSize.smallDesktop:
        return 240.0; // Small desktop: standard width
      case ScreenSize.desktop:
        return 260.0; // Desktop: slightly wider
      case ScreenSize.ultraWide:
        return 280.0; // Ultra-wide: generous width
    }
  }

  /// Get RTL-aware directional icon (deprecated - use DirectionalIcon widget instead)
  @deprecated
  static IconData getDirectionalIcon(BuildContext context, IconData ltrIcon, IconData? rtlIcon) {
    final textDirection = Directionality.of(context);
    if (textDirection == TextDirection.rtl && rtlIcon != null) {
      return rtlIcon;
    }
    return ltrIcon;
  }

  /// Get RTL-aware arrow icon (deprecated - use DirectionalIcon widget instead)
  @deprecated
  static IconData getArrowIcon(BuildContext context, {bool forward = true}) {
    final textDirection = Directionality.of(context);
    if (textDirection == TextDirection.rtl) {
      return forward ? Icons.arrow_back : Icons.arrow_forward;
    }
    return forward ? Icons.arrow_forward : Icons.arrow_back;
  }

  /// Get RTL-aware chevron icon (deprecated - use DirectionalIcon widget instead)
  @deprecated
  static IconData getChevronIcon(BuildContext context, {bool right = true}) {
    final textDirection = Directionality.of(context);
    if (textDirection == TextDirection.rtl) {
      return right ? Icons.chevron_left : Icons.chevron_right;
    }
    return right ? Icons.chevron_right : Icons.chevron_left;
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Get safe area padding considering keyboard
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding + mediaQuery.viewInsets;
  }

  /// Build responsive layout with LayoutBuilder
  static Widget buildResponsiveLayout({
    required BuildContext context,
    required Widget mobileLayout,
    required Widget tabletLayout,
    required Widget desktopLayout,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = getScreenSize(context);

        switch (screenSize) {
          case ScreenSize.extraSmallMobile:
          case ScreenSize.smallMobile:
          case ScreenSize.largeMobile:
            return mobileLayout;
          case ScreenSize.tablet:
            return tabletLayout;
          case ScreenSize.smallDesktop:
          case ScreenSize.desktop:
          case ScreenSize.ultraWide:
            return desktopLayout;
        }
      },
    );
  }

  /// Create responsive grid delegate
  static SliverGridDelegate getResponsiveGridDelegate(
    BuildContext context, {
    double childAspectRatio = 0.75,
    int? mobileCrossAxisCount,
    int? tabletCrossAxisCount,
    int? desktopCrossAxisCount,
  }) {
    final crossAxisCount = getGridCrossAxisCount(
      context,
      largeMobileCount: mobileCrossAxisCount ?? 1,
      tabletCount: tabletCrossAxisCount ?? 2,
      desktopCount: desktopCrossAxisCount ?? 3,
    );

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: getItemSpacing(context),
      mainAxisSpacing: getItemSpacing(context),
    );
  }

  /// Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(
    BuildContext context, {
    double? maxWidth,
    double? maxHeight,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth ?? getMaxContentWidth(context),
      maxHeight: maxHeight ?? double.infinity,
    );
  }
}

/// Extension methods for responsive design
extension ResponsiveContext on BuildContext {
  /// Get current screen size
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);

  /// Check if mobile (any mobile size)
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Check if tablet (any tablet size)
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Check if desktop (any desktop size)
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Check if ultra-wide
  bool get isUltraWide => ResponsiveUtils.isUltraWide(this);

  /// Check if landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);

  /// Check if portrait
  bool get isPortrait => ResponsiveUtils.isPortrait(this);

  /// Get responsive padding
  EdgeInsets get responsivePadding =>
      ResponsiveUtils.getResponsivePadding(this);

  /// Get responsive horizontal padding
  EdgeInsets get responsiveHorizontalPadding =>
      ResponsiveUtils.getResponsiveHorizontalPadding(this);

  /// Get responsive item spacing
  double get itemSpacing => ResponsiveUtils.getItemSpacing(this);

  /// Get responsive text scale factor
  double get textScaleFactor => ResponsiveUtils.getTextScaleFactor(this);

  /// Get responsive button height
  double get buttonHeight => ResponsiveUtils.getButtonHeight(this);

  /// Get responsive max content width
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(this);

  /// Get responsive form field width
  double get formFieldWidth => ResponsiveUtils.getFormFieldWidth(this);

  /// Check if keyboard is visible
  bool get isKeyboardVisible => ResponsiveUtils.isKeyboardVisible(this);

  /// Get keyboard height
  double get keyboardHeight => ResponsiveUtils.getKeyboardHeight(this);

  /// Get responsive icon size
  double get iconSize => ResponsiveUtils.getIconSize(this, 24);

  /// Get responsive mobile navigation height (for bottom nav)
  double get mobileNavHeight {
    if (isMobile) return 80.0; // Mobile: taller for better touch targets
    if (isTablet) return 70.0; // Tablet: moderate height
    return 0.0; // Desktop: no bottom nav
  }

  /// Get responsive app bar height
  double get appBarHeight {
    if (isMobile) return 56.0; // Mobile: standard height
    if (isTablet) return 64.0; // Tablet: slightly taller
    return 72.0; // Desktop: taller for better proportions
  }

  /// Get responsive border radius
  double get borderRadius {
    if (isMobile) return 12;
    if (isTablet) return 16;
    return 20;
  }

  /// Get responsive elevation
  double get cardElevation {
    if (isMobile) return 2;
    if (isTablet) return 4;
    return 6;
  }

  /// Get responsive touch target size (minimum 44px for accessibility)
  double get touchTargetSize => 48;

  /// Get responsive keyboard spacing (extra space when keyboard is visible)
  double get keyboardSpacing {
    final viewInsets = MediaQuery.of(this).viewInsets;
    return viewInsets.bottom > 0 ? viewInsets.bottom + 16 : 0;
  }

  /// Get responsive aspect ratio for cards
  double get cardAspectRatio {
    if (isMobile) return 0.8;
    if (isTablet) return 0.75;
    return 0.7;
  }

  /// Get responsive horizontal list height
  double get horizontalListHeight {
    if (isMobile) return 180;
    if (isTablet) return 200;
    return 220;
  }

  /// Get responsive card height based on content and screen size
  double getCardHeight({
    required bool isMatchCard,
    double? contentHeight,
  }) {
    // Increased base heights to accommodate content better
    final baseHeight = isMatchCard ? 220.0 : 200.0;

    // Adjust based on screen size
    final screenMultiplier = isMobile ? 0.95 : (isTablet ? 1.05 : 1.1);

    // Calculate responsive height
    final responsiveHeight = baseHeight * screenMultiplier;

    // If content height is provided, ensure card can accommodate it with more flexibility
    if (contentHeight != null) {
      final minHeight = isMatchCard ? 200.0 : 180.0;
      const maxHeight = 320.0; // Increased max height to prevent overflow
      return contentHeight.clamp(minHeight, maxHeight);
    }

    return responsiveHeight.clamp(180.0, 320.0);
  }

  /// Get responsive grid spacing
  double get gridSpacing {
    return ResponsiveUtils.getItemSpacing(this);
  }

  /// Get responsive card width for horizontal lists
  double get cardWidth {
    return ResponsiveUtils.getCardWidth(this);
  }

  /// Get responsive grid cross axis count
  int get gridCrossAxisCount {
    return ResponsiveUtils.getGridCrossAxisCount(this);
  }

  /// Get responsive content centering for ultra-wide screens
  Widget getCenteredContent({required Widget child}) {
    if (ResponsiveUtils.isUltraWide(this)) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxContentWidth),
          child: child,
        ),
      );
    }
    return child;
  }
}

/// Extension for responsive widgets
extension ResponsiveWidget on Widget {
  /// Add responsive padding
  Widget withResponsivePadding(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: this,
    );
  }

  /// Constrain width responsively
  Widget withResponsiveWidth(BuildContext context, {double? maxWidth}) {
    return Container(
      constraints: ResponsiveUtils.getResponsiveConstraints(
        context,
        maxWidth: maxWidth,
      ),
      child: this,
    );
  }

  /// Center with responsive max width
  Widget centeredWithResponsiveWidth(BuildContext context) {
    return Center(
      child: Container(
        constraints: ResponsiveUtils.getResponsiveConstraints(context),
        child: this,
      ),
    );
  }

  /// Add responsive gap (spacing) using standardized sizes from ResponsiveConstants
  Widget gap(BuildContext context, String size) {
    return SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, size));
  }

  /// Add responsive padding using standardized sizes from ResponsiveConstants
  Widget paddingAll(BuildContext context, String size) {
    return Padding(
      padding: ResponsiveConstants.getResponsivePadding(context, size),
      child: this,
    );
  }

  /// Add responsive margin using standardized sizes from ResponsiveConstants
  Widget marginAll(BuildContext context, String size) {
    final spacing = ResponsiveConstants.getResponsiveSpacing(context, size);
    return Container(
      margin: EdgeInsets.all(spacing),
      child: this,
    );
  }

  /// Add responsive horizontal margin
  Widget marginHorizontal(BuildContext context, String size) {
    final spacing = ResponsiveConstants.getResponsiveSpacing(context, size);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing),
      child: this,
    );
  }

  /// Add responsive vertical margin
  Widget marginVertical(BuildContext context, String size) {
    final spacing = ResponsiveConstants.getResponsiveSpacing(context, size);
    return Container(
      margin: EdgeInsets.symmetric(vertical: spacing),
      child: this,
    );
  }

  /// Apply responsive border radius
  Widget withBorderRadius(BuildContext context, double baseRadius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.borderRadius * baseRadius),
      child: this,
    );
  }

  /// Apply responsive elevation (shadow)
  Widget withElevation(BuildContext context, double baseElevation) {
    return Material(
      elevation: context.cardElevation * baseElevation,
      borderRadius: BorderRadius.circular(context.borderRadius),
      child: this,
    );
  }

  /// Constrain height responsively
  Widget withResponsiveHeight(BuildContext context, double height) {
    return SizedBox(
      height: height * context.textScaleFactor,
      child: this,
    );
  }

  /// Add responsive horizontal gap between widgets in a row
  Widget spacedHorizontally(BuildContext context, {String size = 'sm'}) {
    return Row(
      children: [
        this,
        SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, size)),
      ],
    );
  }

  /// Add responsive vertical gap between widgets in a column
  Widget spacedVertically(BuildContext context, {String size = 'sm'}) {
    return Column(
      children: [
        this,
        SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, size)),
      ],
    );
  }
}
