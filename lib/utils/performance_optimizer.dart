import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Performance optimization utilities for responsive design
class PerformanceOptimizer {
  /// Cache for expensive computations based on screen size
  static final Map<String, dynamic> _cache = {};

  /// Get cached value or compute and cache it
  static T getCached<T>(String key, T Function() compute) {
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }
    final value = compute();
    _cache[key] = value;
    return value;
  }

  /// Clear cache when screen size changes
  static void clearCache() {
    _cache.clear();
  }

  /// Get optimized grid cross axis count with caching
  static int getOptimizedGridCrossAxisCount(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final cacheKey = 'grid_${screenSize.toString()}';

    return getCached(cacheKey, () {
      switch (screenSize) {
        case ScreenSize.extraSmallMobile:
          return 1; // Single column for very small screens
        case ScreenSize.smallMobile:
          return 2; // Two columns for small mobile
        case ScreenSize.largeMobile:
          return 2; // Two columns for large mobile
        case ScreenSize.tablet:
          return 3; // Three columns for tablets
        case ScreenSize.smallDesktop:
          return 4; // Four columns for small desktops
        case ScreenSize.desktop:
          return 5; // Five columns for desktops
        case ScreenSize.ultraWide:
          return 6; // Six columns for ultra-wide
      }
    });
  }

  /// Get optimized image dimensions with caching
  static Size getOptimizedImageSize(BuildContext context, double baseWidth, double baseHeight) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final cacheKey = 'image_${screenSize.toString()}_${baseWidth}_$baseHeight';

    return getCached(cacheKey, () {
      final scale = ResponsiveUtils.getTextScaleFactor(context);
      return Size(baseWidth * scale, baseHeight * scale);
    });
  }

  /// Check if heavy animations should be enabled
  static bool shouldEnableHeavyAnimations(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Disable heavy animations on mobile for better performance
    return screenSize == ScreenSize.desktop || screenSize == ScreenSize.ultraWide;
  }

  /// Get optimized list item count for virtual scrolling
  static int getOptimizedListItemCount(BuildContext context, int totalItems) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Show fewer items initially on mobile for better performance
    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return totalItems.clamp(0, 20); // Limit to 20 items on small screens
      case ScreenSize.largeMobile:
        return totalItems.clamp(0, 30); // Limit to 30 items on large mobile
      default:
        return totalItems; // Show all items on larger screens
    }
  }

  /// Get optimized image quality based on screen size
  static double getOptimizedImageQuality(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 0.7; // Lower quality for small screens
      case ScreenSize.smallMobile:
        return 0.8; // Medium quality for small mobile
      case ScreenSize.largeMobile:
        return 0.9; // High quality for large mobile
      default:
        return 1.0; // Full quality for tablets and desktops
    }
  }

  /// Check if device supports high refresh rate animations
  static bool supportsHighRefreshRate(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Assume high refresh rate support for larger screens
    return screenSize == ScreenSize.desktop || screenSize == ScreenSize.ultraWide;
  }

  /// Get optimized shadow elevation based on screen size
  static double getOptimizedElevation(BuildContext context, double baseElevation) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Reduce elevation on mobile for better performance
    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return baseElevation * 0.5; // Reduce elevation on small screens
      case ScreenSize.largeMobile:
        return baseElevation * 0.75; // Slightly reduce on large mobile
      default:
        return baseElevation; // Full elevation on larger screens
    }
  }

  /// Get optimized border radius based on screen size
  static double getOptimizedBorderRadius(BuildContext context, double baseRadius) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Adjust border radius for better touch targets on mobile
    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
        return baseRadius * 1.2; // Slightly larger radius for better touch
      default:
        return baseRadius; // Standard radius for larger screens
    }
  }

  /// Check if complex layouts should be simplified
  static bool shouldSimplifyLayout(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Simplify layouts on very small screens
    return screenSize == ScreenSize.extraSmallMobile;
  }

  /// Get optimized text rendering settings
  static TextStyle getOptimizedTextStyle(BuildContext context, TextStyle baseStyle) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    // Optimize text rendering for different screen sizes
    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        // Use simpler font rendering on small screens
        return baseStyle.copyWith(
          fontWeight: baseStyle.fontWeight != FontWeight.bold ? FontWeight.w400 : baseStyle.fontWeight,
        );
      default:
        return baseStyle;
    }
  }
}

/// Extension methods for performance optimization
extension PerformanceOptimizationExtensions on BuildContext {
  /// Get optimized grid cross axis count
  int get optimizedGridCrossAxisCount => PerformanceOptimizer.getOptimizedGridCrossAxisCount(this);

  /// Get optimized image size
  Size getOptimizedImageSize(double baseWidth, double baseHeight) {
    return PerformanceOptimizer.getOptimizedImageSize(this, baseWidth, baseHeight);
  }

  /// Check if heavy animations should be enabled
  bool get shouldEnableHeavyAnimations => PerformanceOptimizer.shouldEnableHeavyAnimations(this);

  /// Get optimized list item count
  int getOptimizedListItemCount(int totalItems) {
    return PerformanceOptimizer.getOptimizedListItemCount(this, totalItems);
  }

  /// Get optimized image quality
  double get optimizedImageQuality => PerformanceOptimizer.getOptimizedImageQuality(this);

  /// Check high refresh rate support
  bool get supportsHighRefreshRate => PerformanceOptimizer.supportsHighRefreshRate(this);

  /// Get optimized elevation
  double getOptimizedElevation(double baseElevation) {
    return PerformanceOptimizer.getOptimizedElevation(this, baseElevation);
  }

  /// Get optimized border radius
  double getOptimizedBorderRadius(double baseRadius) {
    return PerformanceOptimizer.getOptimizedBorderRadius(this, baseRadius);
  }

  /// Check if layout should be simplified
  bool get shouldSimplifyLayout => PerformanceOptimizer.shouldSimplifyLayout(this);

  /// Get optimized text style
  TextStyle getOptimizedTextStyle(TextStyle baseStyle) {
    return PerformanceOptimizer.getOptimizedTextStyle(this, baseStyle);
  }
}