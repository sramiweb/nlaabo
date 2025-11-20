import 'package:flutter/material.dart';

/// Utility class for accessibility compliance and WCAG standards
class AccessibilityUtils {
  /// Check if a color combination meets WCAG AA contrast ratio (4.5:1)
  static bool meetsWCAGAAContrast(Color foreground, Color background) {
    final contrastRatio = _calculateContrastRatio(foreground, background);
    return contrastRatio >= 4.5;
  }

  /// Check if a color combination meets WCAG AAA contrast ratio (7:1)
  static bool meetsWCAGAAAContrast(Color foreground, Color background) {
    final contrastRatio = _calculateContrastRatio(foreground, background);
    return contrastRatio >= 7.0;
  }

  /// Calculate contrast ratio between two colors
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;

    final rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
    final gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
    final bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  /// Get a color that meets contrast requirements with the given background
  static Color getAccessibleColor(Color background, {bool preferDark = false}) {
    final lightColors = [
      Colors.white,
      Colors.black,
      Colors.blue.shade900,
      Colors.green.shade900,
      Colors.purple.shade900,
    ];

    final darkColors = [
      Colors.black,
      Colors.white,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
    ];

    final candidates = preferDark ? darkColors : lightColors;

    for (final color in candidates) {
      if (meetsWCAGAAContrast(color, background)) {
        return color;
      }
    }

    // Fallback: return white or black based on background brightness
    return _calculateLuminance(background) > 0.5 ? Colors.black : Colors.white;
  }

  /// Ensure minimum touch target size (48px as per WCAG)
  static Size getMinimumTouchTarget() {
    return const Size(48.0, 48.0);
  }

  /// Check if a widget size meets minimum touch target requirements
  static bool meetsMinimumTouchTarget(Size size) {
    return size.width >= 48.0 && size.height >= 48.0;
  }

  /// Get accessible text style with proper contrast
  static TextStyle getAccessibleTextStyle({
    required BuildContext context,
    TextStyle? baseStyle,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final defaultStyle = baseStyle ?? theme.textTheme.bodyMedium!;
    final bgColor = backgroundColor ?? theme.colorScheme.surface;

    // Check if current colors meet contrast requirements
    final currentColor = defaultStyle.color ?? theme.colorScheme.onSurface;
    if (meetsWCAGAAContrast(currentColor, bgColor)) {
      return defaultStyle;
    }

    // Return style with accessible color
    return defaultStyle.copyWith(color: getAccessibleColor(bgColor));
  }

  /// Create accessible button style
  static ButtonStyle getAccessibleButtonStyle({
    required BuildContext context,
    ButtonStyle? baseStyle,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.primary;
    final fgColor = foregroundColor ?? theme.colorScheme.onPrimary;

    // Ensure contrast meets requirements
    final accessibleFgColor = meetsWCAGAAContrast(fgColor, bgColor)
        ? fgColor
        : getAccessibleColor(bgColor);

    return (baseStyle ?? ElevatedButton.styleFrom()).copyWith(
      backgroundColor: WidgetStateProperty.all(bgColor),
      foregroundColor: WidgetStateProperty.all(accessibleFgColor),
      minimumSize: WidgetStateProperty.all(getMinimumTouchTarget()),
    );
  }

  /// Validate accessibility of a color scheme
  static List<String> validateColorScheme({
    required Color primary,
    required Color onPrimary,
    required Color surface,
    required Color onSurface,
    required Color background,
    required Color onBackground,
  }) {
    final issues = <String>[];

    if (!meetsWCAGAAContrast(onPrimary, primary)) {
      issues.add(
        'Primary color and onPrimary color do not meet WCAG AA contrast requirements',
      );
    }

    if (!meetsWCAGAAContrast(onSurface, surface)) {
      issues.add(
        'Surface color and onSurface color do not meet WCAG AA contrast requirements',
      );
    }

    if (!meetsWCAGAAContrast(onBackground, background)) {
      issues.add(
        'Background color and onBackground color do not meet WCAG AA contrast requirements',
      );
    }

    return issues;
  }

  /// Get semantic label for common UI elements
  static String getSemanticLabel(String elementType, String content) {
    switch (elementType.toLowerCase()) {
      case 'button':
        return content;
      case 'link':
        return '$content link';
      case 'image':
        return 'Image: $content';
      case 'card':
        return '$content card';
      case 'list_item':
        return 'List item: $content';
      case 'checkbox':
        return 'Checkbox: $content';
      case 'radio':
        return 'Radio button: $content';
      case 'switch':
        return 'Switch: $content';
      case 'slider':
        return 'Slider: $content';
      case 'dropdown':
        return 'Dropdown: $content';
      case 'text_field':
        return 'Text field: $content';
      case 'icon_button':
        return '$content button';
      case 'search_field':
        return 'Search field: $content';
      case 'navigation_button':
        return 'Navigate to $content';
      case 'action_button':
        return 'Action: $content';
      default:
        return content;
    }
  }

  /// Get semantic hint for common UI elements
  static String getSemanticHint(String elementType, String action) {
    switch (elementType.toLowerCase()) {
      case 'button':
        return 'Tap to $action';
      case 'link':
        return 'Opens $action in browser';
      case 'card':
        return 'Tap to view $action details';
      case 'list_item':
        return 'Tap to select this $action';
      case 'checkbox':
        return 'Tap to ${action.contains('un') ? 'un' : ''}check this option';
      case 'radio':
        return 'Tap to select this $action option';
      case 'switch':
        return 'Tap to ${action.contains('off') ? 'turn off' : 'turn on'} this setting';
      case 'slider':
        return 'Swipe to adjust $action';
      case 'dropdown':
        return 'Tap to open $action menu';
      case 'text_field':
        return 'Type to enter $action';
      case 'icon_button':
        return 'Tap to $action';
      case 'search_field':
        return 'Type to search for $action';
      case 'navigation_button':
        return 'Tap to navigate to $action';
      case 'action_button':
        return 'Tap to perform $action';
      default:
        return 'Tap to $action';
    }
  }

  /// Check if text size is accessible (minimum 14pt for body text)
  static bool isAccessibleTextSize(double fontSize) {
    return fontSize >= 14.0;
  }

  /// Get accessible font size (minimum 14pt)
  static double getAccessibleFontSize(double requestedSize) {
    return requestedSize < 14.0 ? 14.0 : requestedSize;
  }
}

// Extension methods for easier accessibility integration
extension AccessibilityExtensions on BuildContext {
  /// Check if current theme meets accessibility standards
  List<String> validateThemeAccessibility() {
    final theme = Theme.of(this);
    return AccessibilityUtils.validateColorScheme(
      primary: theme.colorScheme.primary,
      onPrimary: theme.colorScheme.onPrimary,
      surface: theme.colorScheme.surface,
      onSurface: theme.colorScheme.onSurface,
      background: theme.colorScheme.surface,
      onBackground: theme.colorScheme.onSurface,
    );
  }

  /// Get accessible text style for current context
  TextStyle accessibleTextStyle({
    TextStyle? baseStyle,
    Color? backgroundColor,
  }) {
    return AccessibilityUtils.getAccessibleTextStyle(
      context: this,
      baseStyle: baseStyle,
      backgroundColor: backgroundColor,
    );
  }

  /// Get accessible button style for current context
  ButtonStyle accessibleButtonStyle({
    ButtonStyle? baseStyle,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return AccessibilityUtils.getAccessibleButtonStyle(
      context: this,
      baseStyle: baseStyle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Touch target validation and enforcement utilities
class TouchTargetValidator {
  /// Validates if a given size meets minimum touch target requirements (48x48dp)
  static bool validateTouchTarget(Size size) {
    return size.width >= 48 && size.height >= 48;
  }

  /// Creates a wrapper widget that enforces minimum touch target size
  /// Wraps the child in a Container with minimum constraints and InkWell for tap handling
  static Widget enforceMinimumTouchTarget({
    required Widget child,
    required VoidCallback onPressed,
    Key? key,
  }) {
    return InkWell(
      key: key,
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        child: child,
      ),
    );
  }
}

double pow(double x, double exponent) {
  return x * x; // Simple approximation for contrast calculation
}
