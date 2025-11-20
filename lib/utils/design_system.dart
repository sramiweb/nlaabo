import 'package:flutter/material.dart';

/// Comprehensive design system for FootConnect based on the design philosophy specification
/// This replaces the previous basic design system with a complete implementation
/// that includes colors, typography, spacing, and component specifications.

/// Color Palette - Primary Colors
class FootConnectColors {
  // Primary Colors
  static const Color primaryBlue = Color(0xFF3B7FBF); // Main brand color
  static const Color primaryDark = Color(0xFF2C5F8F); // Hover states, dark mode
  static const Color primaryLight = Color(0xFF5A9DD5); // Accents, highlights

  // Secondary Colors
  static const Color successGreen = Color(0xFF10B981); // Recruitment badge, success states
  static const Color warningOrange = Color(0xFFF59E0B); // Pending actions
  static const Color errorRed = Color(0xFFEF4444); // Destructive actions
  static const Color neutralGray = Color(0xFF6B7280); // Secondary text, borders

  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF); // Light mode
  static const Color backgroundSecondary = Color(0xFFF9FAFB); // Cards, sections
  static const Color backgroundTertiary = Color(0xFFF3F4F6); // Subtle highlights

  // Dark Mode Background Colors
  static const Color darkBackgroundPrimary = Color(0xFF1F2937);
  static const Color darkBackgroundSecondary = Color(0xFF111827);
  static const Color darkBackgroundTertiary = Color(0xFF374151);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // Headings, important text
  static const Color textSecondary = Color(0xFF6B7280); // Body text, descriptions
  static const Color textTertiary = Color(0xFF9CA3AF); // Meta info, captions
  static const Color textInverse = Color(0xFFFFFFFF); // On dark backgrounds

  // Helper methods for opacity variations
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Gradient definitions
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryBlue, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient primaryHoverGradient = const LinearGradient(
    colors: [primaryDark, Color(0xFF1E4A6F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Typography System - Font Family and Sizes
class FootConnectTypography {
  // Font Families (as specified in design)
  static const String primaryFont = 'Inter'; // Web primary
  static const String secondaryFont = 'Roboto'; // Android fallback
  static const String iosFont = 'SF Pro'; // iOS

  // Font Sizes (as specified in design)
  static const double h1 = 28.0; // Page titles
  static const double h2 = 24.0; // Section headers
  static const double h3 = 20.0; // Card titles
  static const double h4 = 18.0; // Subsections

  static const double bodyLarge = 16.0; // Primary content
  static const double bodyRegular = 14.0; // Standard text
  static const double bodySmall = 12.0; // Meta info, captions

  static const double buttonLarge = 16.0;
  static const double buttonRegular = 14.0;
  static const double buttonSmall = 12.0;

  // Font Weights
  static const FontWeight h1Weight = FontWeight.w700;
  static const FontWeight h2Weight = FontWeight.w600;
  static const FontWeight h3Weight = FontWeight.w600;
  static const FontWeight h4Weight = FontWeight.w500;

  static const FontWeight bodyLargeWeight = FontWeight.w400;
  static const FontWeight bodyRegularWeight = FontWeight.w400;
  static const FontWeight bodySmallWeight = FontWeight.w400;

  static const FontWeight buttonLargeWeight = FontWeight.w600;
  static const FontWeight buttonRegularWeight = FontWeight.w500;
  static const FontWeight buttonSmallWeight = FontWeight.w500;

  // Line Heights
  static const double headingLineHeight = 1.2;
  static const double bodyLineHeight = 1.5;
  static const double captionLineHeight = 1.4;

  // Text Styles
  static TextStyle h1Style = const TextStyle(
    fontFamily: primaryFont,
    fontSize: h1,
    fontWeight: h1Weight,
    height: headingLineHeight,
    color: FootConnectColors.textPrimary,
  );

  static TextStyle h2Style = const TextStyle(
    fontFamily: primaryFont,
    fontSize: h2,
    fontWeight: h2Weight,
    height: headingLineHeight,
    color: FootConnectColors.textPrimary,
  );

  static TextStyle h3Style = const TextStyle(
    fontFamily: primaryFont,
    fontSize: h3,
    fontWeight: h3Weight,
    height: headingLineHeight,
    color: FootConnectColors.textPrimary,
  );

  static TextStyle h4Style = const TextStyle(
    fontFamily: primaryFont,
    fontSize: h4,
    fontWeight: h4Weight,
    height: headingLineHeight,
    color: FootConnectColors.textPrimary,
  );

  static TextStyle bodyLargeStyle = const TextStyle(
    fontFamily: primaryFont,
    fontSize: bodyLarge,
    fontWeight: bodyLargeWeight,
    height: bodyLineHeight,
    color: FootConnectColors.textSecondary,
  );

  static TextStyle bodyRegularStyle = const TextStyle(
    fontFamily: primaryFont,
    fontSize: bodyRegular,
    fontWeight: bodyRegularWeight,
    height: bodyLineHeight,
    color: FootConnectColors.textSecondary,
  );

  static TextStyle bodySmallStyle = const TextStyle(
    fontFamily: primaryFont,
    fontSize: bodySmall,
    fontWeight: bodySmallWeight,
    height: captionLineHeight,
    color: FootConnectColors.textTertiary,
  );

  static TextStyle buttonLargeStyle = const TextStyle(
    fontFamily: primaryFont,
    fontSize: buttonLarge,
    fontWeight: buttonLargeWeight,
    height: bodyLineHeight,
    color: FootConnectColors.textInverse,
  );

  static TextStyle buttonRegularStyle = const TextStyle(
    fontFamily: primaryFont,
    fontSize: buttonRegular,
    fontWeight: buttonRegularWeight,
    height: bodyLineHeight,
    color: FootConnectColors.primaryBlue,
  );

  static TextStyle buttonSmallStyle = const TextStyle(
    fontFamily: primaryFont,
    fontSize: buttonSmall,
    fontWeight: buttonSmallWeight,
    height: captionLineHeight,
    color: FootConnectColors.primaryBlue,
  );
}

/// Spacing System - Base Unit: 4px
class FootConnectSpacing {
  static const double space1 = 4;   // Tight spacing
  static const double space2 = 8;   // Compact spacing
  static const double space3 = 12;  // Standard spacing
  static const double space4 = 16;  // Comfortable spacing
  static const double space5 = 20;  // Section spacing
  static const double space6 = 24;  // Large spacing
  static const double space8 = 32;  // Extra large
  static const double space10 = 40; // Section dividers
  static const double space12 = 48; // Page sections
}

/// Border Radius System
class FootConnectBorderRadius {
  static const double none = 0;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;

  // Component-specific
  static const double button = 12;
  static const double card = 16;
  static const double input = 12;
  static const double badge = 12;
}

/// Shadow System
class FootConnectShadows {
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    offset: Offset(0, 1),
    blurRadius: 3,
  );

  static const BoxShadow cardHoverShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  static const BoxShadow buttonShadow = BoxShadow(
    color: Color.fromRGBO(59, 127, 191, 0.25),
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  static const BoxShadow buttonHoverShadow = BoxShadow(
    color: Color.fromRGBO(59, 127, 191, 0.35),
    offset: Offset(0, 4),
    blurRadius: 12,
  );
}

/// Animation & Transition System
class FootConnectAnimations {
  static const Duration standardDuration = Duration(milliseconds: 200);
  static const Duration fastDuration = Duration(milliseconds: 100);
  static const Duration slowDuration = Duration(milliseconds: 300);

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve materialCurve = Cubic(0.4, 0.0, 0.2, 1); // Material standard

  // Scale animations
  static const double buttonPressScale = 0.98;
  static const double cardHoverScale = 1.0; // No scale, just translate

  // Opacity animations
  static const double shimmerOpacity = 0.1;
}

/// Responsive Breakpoints (as specified in design)
class FootConnectBreakpoints {
  static const double mobileMax = 768;
  static const double tabletMin = 768;
  static const double tabletMax = 1024;
  static const double desktopMin = 1024;

  // Content max widths
  static const double mobileContentMax = double.infinity;
  static const double tabletContentMax = 720;
  static const double desktopContentMax = 1200;
  static const double ultraWideContentMax = 1200; // Capped at 1200px
}

/// Component-specific sizing
class FootConnectComponentSizing {
  // Button heights (further optimized for mobile UX)
  static const double buttonHeightLarge = 40; // Further reduced for mobile
  static const double buttonHeightMedium = 32; // Further reduced for mobile
  static const double buttonHeightSmall = 24; // Further reduced for mobile

  // Mobile button heights (already optimized)
  static const double mobileButtonHeightLarge = 44;
  static const double mobileButtonHeightMedium = 36;
  static const double mobileButtonHeightSmall = 28;

  // Tablet button heights (optimized)
  static const double tabletButtonHeightLarge = 42; // Reduced from 46px
  static const double tabletButtonHeightMedium = 34; // Reduced from 38px
  static const double tabletButtonHeightSmall = 26; // Reduced from 30px

  // Form field heights (further optimized for mobile UX)
  static const double textFieldHeight = 40; // Mobile (further reduced for better UX)
  static const double desktopTextFieldHeight = 44; // Desktop (further reduced for consistency)

  // Card dimensions
  static const double cardBorderRadius = 16;
  static const double cardPadding = 20;

  // Navigation
  static const double bottomNavHeight = 64;
  static const double sidebarWidth = 240;
  static const double topBarHeight = 64;

  // Touch targets (accessibility)
  static const double minTouchTarget = 44; // WCAG AAA
  static const double recommendedTouchTarget = 48;
}

/// Legacy compatibility - keeping old constants for backward compatibility
/// TODO: Gradually migrate away from these
class DesignSystem {
  // Spacing scale (multiples of 4)
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // Form-specific spacing
  static const double fieldSpacing = 16.0;       // Between form fields
  static const double sectionSpacing = 24.0;     // Between sections

  // Content padding for form fields
  static const double horizontalPadding = 12.0;
  static const double verticalPadding = 14.0;

  // Maximum form width
  static const double maxFormWidth = 600.0;
  static const double tabletMaxFormWidth = 500.0;
}

class BorderRadiusSystem {
  static const double none = 0;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double extraLarge = 24;

  // Form-specific border radius
  static const double formBorderRadius = 8.0;
}

class ButtonSizing {
  // Desktop button heights
  static const double heightLarge = 48.0;   // Primary actions
  static const double heightMedium = 40.0;  // Secondary actions
  static const double heightSmall = 32.0;   // Tertiary actions

  // Mobile-specific button heights
  static const double mobileHeightLarge = 44.0;
  static const double mobileHeightMedium = 36.0;
  static const double mobileHeightSmall = 28.0;

  // Tablet-specific button heights
  static const double tabletHeightLarge = 46.0;
  static const double tabletHeightMedium = 38.0;
  static const double tabletHeightSmall = 30.0;
}

class FormFieldSizing {
  // Desktop form field heights
  static const double textFieldHeight = 48.0;    // Standard text fields
  static const double dropdownHeight = 48.0;     // Dropdown fields

  // Mobile-specific form field heights
  static const double mobileTextFieldHeight = 44.0;
  static const double mobileDropdownHeight = 44.0;

  // Tablet-specific form field heights
  static const double tabletTextFieldHeight = 46.0;
  static const double tabletDropdownHeight = 46.0;
}

class OpacitySystem {
  static const double disabled = 0.5;
  static const double hover = 0.8;
  static const double focus = 0.9;
}
