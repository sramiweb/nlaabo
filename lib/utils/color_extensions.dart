import 'package:flutter/material.dart';

/// Extension methods on Color for safe opacity operations
extension ColorExtensions on Color {
  /// Safely applies opacity to a color, handling null values
  Color withOpacitySafe(double opacity) {
    return withValues(alpha: opacity.clamp(0.0, 1.0));
  }
}
