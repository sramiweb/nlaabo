import 'package:flutter/material.dart';

/// AppSpacing class containing all spacing constants for consistent layout
/// Uses a scale-based approach with 4px base unit for consistency
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Spacing scale (multiples of base unit)
  static const double xs = unit * 1;      // 4px
  static const double sm = unit * 2;      // 8px
  static const double md = unit * 3;      // 12px
  static const double lg = unit * 4;      // 16px
  static const double xl = unit * 6;      // 24px
  static const double xxl = unit * 8;     // 32px
  static const double xxxl = unit * 12;   // 48px

  // Component-specific spacing
  static const double cardPadding = lg;          // 16px
  static const double cardMargin = md;           // 12px
  static const double buttonPaddingVertical = md; // 12px
  static const double buttonPaddingHorizontal = lg; // 16px
  static const double inputPadding = lg;         // 16px
  static const double iconSize = xl;             // 24px
  static const double avatarSize = xxxl;         // 48px

  // Layout spacing
  static const double screenPadding = lg;        // 16px
  static const double sectionSpacing = xl;       // 24px
  static const double elementSpacing = md;       // 12px
  static const double listItemSpacing = sm;      // 8px

  // Navigation spacing
  static const double navBarHeight = 70.0;      // 70px for mobile bottom nav
  static const double sidebarWidth = 280.0;     // 280px for desktop sidebar
  static const double navItemSpacing = md;      // 12px

  // Border radius
  static const double borderRadiusSm = sm;       // 8px
  static const double borderRadiusMd = md;       // 12px
  static const double borderRadiusLg = lg;       // 16px
  static const double borderRadiusXl = xl;       // 24px

  // Shadows and elevation
  static const double shadowBlur = lg;           // 16px
  static const double shadowOffset = xs;         // 4px

  // EdgeInsets helpers for consistent padding/margin
  static const EdgeInsets screenPaddingInsets = EdgeInsets.all(screenPadding);
  static const EdgeInsets cardPaddingInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets buttonPaddingInsets = EdgeInsets.symmetric(
    vertical: buttonPaddingVertical,
    horizontal: buttonPaddingHorizontal,
  );
  static const EdgeInsets inputPaddingInsets = EdgeInsets.all(inputPadding);

  // Spacing between elements
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalXxl = SizedBox(height: xxl);

  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
  static const SizedBox horizontalXl = SizedBox(width: xl);
  static const SizedBox horizontalXxl = SizedBox(width: xxl);
}
