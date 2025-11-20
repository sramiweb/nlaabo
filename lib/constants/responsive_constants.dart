import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_spacing.dart';

/// Standardized responsive constants for spacing and padding values
/// Provides mappings that can replace hardcoded values throughout the app
/// while ensuring compatibility with ResponsiveSpacing and ResponsiveUtils classes
class ResponsiveConstants {
  // ===========================================================================
  // SPACING MAPS - Standardized spacing values for consistent UI
  // ===========================================================================

  /// Standard spacing scale - replaces hardcoded spacing values
  static const Map<String, double> spacing = {
    // Extra small spacing (4-8px)
    'xs': 4.0,    // Extra small - minimal gaps, tight layouts
    'xs2': 6.0,   // Extra small 2 - slightly more breathing room

    // Small spacing (8-12px)
    'sm': 8.0,    // Small - component internal spacing
    'sm2': 10.0,  // Small 2 - between small elements

    // Medium spacing (12-16px)
    'md': 12.0,   // Medium - standard component spacing
    'md2': 14.0,  // Medium 2 - between medium elements

    // Large spacing (16-24px)
    'lg': 16.0,   // Large - section spacing, card padding
    'lg2': 20.0,  // Large 2 - between major sections

    // Extra large spacing (24-32px)
    'xl': 24.0,   // Extra large - major section breaks
    'xl2': 28.0,  // Extra large 2 - page section spacing

    // 2XL spacing (32-48px)
    '2xl': 32.0,  // 2XL - large section breaks
    '2xl2': 40.0, // 2XL 2 - generous spacing

    // 3XL+ spacing (48px+)
    '3xl': 48.0,  // 3XL - page breaks, major layout spacing
    '4xl': 64.0,  // 4XL - ultra-wide screen spacing
  };

  /// Component-specific spacing values
  static const Map<String, double> componentSpacing = {
    // Button spacing
    'buttonPaddingHorizontal': 16.0,
    'buttonPaddingVertical': 12.0,
    'buttonGap': 8.0,

    // Card spacing
    'cardPadding': 16.0,
    'cardMargin': 8.0,
    'cardBorderRadius': 12.0,

    // Form spacing
    'formFieldGap': 16.0,
    'formSectionGap': 24.0,
    'formFieldPadding': 12.0,

    // List spacing
    'listItemGap': 8.0,
    'listSectionGap': 16.0,

    // Navigation spacing
    'navItemGap': 4.0,
    'navSectionGap': 12.0,
  };

  // ===========================================================================
  // PADDING MAPS - Standardized padding values for consistent UI
  // ===========================================================================

  /// Standard padding scale - replaces hardcoded padding values
  static const Map<String, EdgeInsets> padding = {
    // Zero padding
    'none': EdgeInsets.zero,

    // Extra small padding (4-8px)
    'xs': EdgeInsets.all(4.0),
    'xs2': EdgeInsets.all(6.0),
    'xsHorizontal': EdgeInsets.symmetric(horizontal: 4.0),
    'xsVertical': EdgeInsets.symmetric(vertical: 4.0),

    // Small padding (8-12px)
    'sm': EdgeInsets.all(8.0),
    'sm2': EdgeInsets.all(10.0),
    'smHorizontal': EdgeInsets.symmetric(horizontal: 8.0),
    'smVertical': EdgeInsets.symmetric(vertical: 8.0),

    // Medium padding (12-16px)
    'md': EdgeInsets.all(12.0),
    'md2': EdgeInsets.all(14.0),
    'mdHorizontal': EdgeInsets.symmetric(horizontal: 12.0),
    'mdVertical': EdgeInsets.symmetric(vertical: 12.0),

    // Large padding (16-24px)
    'lg': EdgeInsets.all(16.0),
    'lg2': EdgeInsets.all(20.0),
    'lgHorizontal': EdgeInsets.symmetric(horizontal: 16.0),
    'lgVertical': EdgeInsets.symmetric(vertical: 16.0),

    // Extra large padding (24-32px)
    'xl': EdgeInsets.all(24.0),
    'xlHorizontal': EdgeInsets.symmetric(horizontal: 24.0),
    'xlVertical': EdgeInsets.symmetric(vertical: 24.0),

    // 2XL padding (32px+)
    '2xl': EdgeInsets.all(32.0),
    '2xlHorizontal': EdgeInsets.symmetric(horizontal: 32.0),
    '2xlVertical': EdgeInsets.symmetric(vertical: 32.0),
  };

  /// Screen-specific padding values
  static const Map<String, EdgeInsets> screenPadding = {
    // Screen container padding
    'screen': EdgeInsets.all(16.0),
    'screenHorizontal': EdgeInsets.symmetric(horizontal: 16.0),
    'screenVertical': EdgeInsets.symmetric(vertical: 16.0),

    // Safe area padding
    'safeArea': EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 16.0),

    // Dialog/Modal padding
    'dialog': EdgeInsets.all(24.0),
    'modal': EdgeInsets.all(20.0),

    // Bottom sheet padding
    'bottomSheet': EdgeInsets.all(16.0),
  };

  // ===========================================================================
  // HELPER METHODS - Integration with ResponsiveSpacing and ResponsiveUtils
  // ===========================================================================

  /// Get responsive spacing value based on screen size
  /// Uses ResponsiveSpacing.getSpacing() for dynamic scaling
  static double getResponsiveSpacing(BuildContext context, String size) {
    final baseValue = spacing[size];
    if (baseValue == null) {
      throw ArgumentError('Invalid spacing size: $size. Available sizes: ${spacing.keys.join(', ')}');
    }
    return ResponsiveSpacing.getSpacing(context, baseValue);
  }

  /// Get responsive padding based on screen size
  /// Uses ResponsiveUtils.getResponsivePadding() for dynamic scaling
  static EdgeInsets getResponsivePadding(BuildContext context, String size) {
    final basePadding = padding[size];
    if (basePadding == null) {
      throw ArgumentError('Invalid padding size: $size. Available sizes: ${padding.keys.join(', ')}');
    }

    // Scale the padding based on screen size
    final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
    return EdgeInsets.fromLTRB(
      basePadding.left * scaleFactor,
      basePadding.top * scaleFactor,
      basePadding.right * scaleFactor,
      basePadding.bottom * scaleFactor,
    );
  }

  /// Get responsive component spacing
  /// Uses ResponsiveSpacing methods for component-specific spacing
  static double getComponentSpacing(BuildContext context, String component) {
    final baseValue = componentSpacing[component];
    if (baseValue == null) {
      throw ArgumentError('Invalid component spacing: $component. Available components: ${componentSpacing.keys.join(', ')}');
    }
    return ResponsiveSpacing.getSpacing(context, baseValue);
  }

  /// Get responsive screen padding
  /// Uses ResponsiveUtils.getResponsivePadding() as base
  static EdgeInsets getScreenPadding(BuildContext context, String type) {
    final basePadding = screenPadding[type];
    if (basePadding == null) {
      throw ArgumentError('Invalid screen padding type: $type. Available types: ${screenPadding.keys.join(', ')}');
    }

    // For screen padding, use ResponsiveUtils.getResponsivePadding as base
    final responsiveBase = ResponsiveUtils.getResponsivePadding(context);

    // Adjust based on the specific type
    switch (type) {
      case 'screen':
        return responsiveBase;
      case 'screenHorizontal':
        return EdgeInsets.symmetric(horizontal: responsiveBase.left);
      case 'screenVertical':
        return EdgeInsets.symmetric(vertical: responsiveBase.top);
      case 'safeArea':
        final safeAreaPadding = MediaQuery.of(context).padding;
        return responsiveBase + safeAreaPadding;
      case 'dialog':
        return responsiveBase * 1.5; // Larger padding for dialogs
      case 'modal':
        return responsiveBase * 1.25; // Slightly larger for modals
      case 'bottomSheet':
        return responsiveBase; // Standard responsive padding
      default:
        return responsiveBase;
    }
  }

  /// Get responsive card spacing
  /// Uses ResponsiveSpacing.getCardSpacing() for consistency
  static EdgeInsets getCardSpacing(BuildContext context) {
    return ResponsiveSpacing.getCardSpacing(context);
  }

  /// Get responsive list item gap
  /// Uses ResponsiveSpacing.getListItemGap() for consistency
  static double getListItemGap(BuildContext context) {
    return ResponsiveSpacing.getListItemGap(context);
  }

  /// Get responsive section spacing
  /// Uses ResponsiveSpacing.getSectionSpacing() for consistency
  static double getSectionSpacing(BuildContext context) {
    return ResponsiveSpacing.getSectionSpacing(context);
  }

  /// Get responsive container padding
  /// Uses ResponsiveSpacing.getContainerPadding() for consistency
  static EdgeInsets getContainerPadding(BuildContext context) {
    return ResponsiveSpacing.getContainerPadding(context);
  }

  // ===========================================================================
  // UTILITY METHODS - Convenience functions for common use cases
  // ===========================================================================

  /// Get spacing value by size key (non-responsive, direct access)
  static double spacingValue(String size) {
    final value = spacing[size];
    if (value == null) {
      throw ArgumentError('Invalid spacing size: $size');
    }
    return value;
  }

  /// Get padding value by size key (non-responsive, direct access)
  static EdgeInsets paddingValue(String size) {
    final value = padding[size];
    if (value == null) {
      throw ArgumentError('Invalid padding size: $size');
    }
    return value;
  }

  /// Get component spacing value by component key (non-responsive, direct access)
  static double componentSpacingValue(String component) {
    final value = componentSpacing[component];
    if (value == null) {
      throw ArgumentError('Invalid component spacing: $component');
    }
    return value;
  }

  /// Check if a spacing size exists
  static bool hasSpacing(String size) {
    return spacing.containsKey(size);
  }

  /// Check if a padding size exists
  static bool hasPadding(String size) {
    return padding.containsKey(size);
  }

  /// Check if a component spacing exists
  static bool hasComponentSpacing(String component) {
    return componentSpacing.containsKey(component);
  }

  /// Get all available spacing sizes
  static List<String> get availableSpacingSizes => spacing.keys.toList();

  /// Get all available padding sizes
  static List<String> get availablePaddingSizes => padding.keys.toList();

  /// Get all available component spacing types
  static List<String> get availableComponentSpacing => componentSpacing.keys.toList();
}

/// Extension methods for easy access to responsive constants
extension ResponsiveConstantsExtensions on BuildContext {
  /// Get responsive spacing using standardized sizes
  double responsiveSpacing(String size) {
    return ResponsiveConstants.getResponsiveSpacing(this, size);
  }

  /// Get responsive padding using standardized sizes
  EdgeInsets responsivePadding(String size) {
    return ResponsiveConstants.getResponsivePadding(this, size);
  }

  /// Get responsive component spacing
  double componentSpacing(String component) {
    return ResponsiveConstants.getComponentSpacing(this, component);
  }

  /// Get responsive screen padding
  EdgeInsets screenPadding(String type) {
    return ResponsiveConstants.getScreenPadding(this, type);
  }

  /// Get responsive card spacing
  EdgeInsets get cardSpacing => ResponsiveConstants.getCardSpacing(this);

  /// Get responsive list item gap
  double get listItemGap => ResponsiveConstants.getListItemGap(this);

  /// Get responsive section spacing
  double get sectionSpacing => ResponsiveConstants.getSectionSpacing(this);

  /// Get responsive container padding
  EdgeInsets get containerPadding => ResponsiveConstants.getContainerPadding(this);
}