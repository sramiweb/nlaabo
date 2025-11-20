import 'package:flutter/material.dart';

class ThemeFixes {
  /// Ensure text is always visible regardless of theme
  static TextStyle visibleText(BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? (isDark ? Colors.white : Colors.black.withValues(alpha: 0.87)),
    );
  }

  /// Get contrasting color for labels
  static Color getLabelColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark 
        ? Colors.white.withValues(alpha: 0.87) 
        : Colors.black.withValues(alpha: 0.87);
  }

  /// Get hint text color
  static Color getHintColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark 
        ? Colors.white54 
        : Colors.black54;
  }
}
