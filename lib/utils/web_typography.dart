import 'package:flutter/material.dart';

/// WebTypography provides responsive font scaling for large screens
/// Implements the requirements from improvements_needed.md for Web Typography Scaling Enhancement
/// Enhanced with granular breakpoints and specific base font sizes per device type
class WebTypography {
  /// Calculates scaled font size based on screen width with enhanced breakpoints
  /// Scale factor: 0.8x-2x, clamped between min and max values
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Enhanced scaling logic with breakpoints
    double scaleFactor;
    if (screenWidth < 320) { // Extra Small Mobile
      scaleFactor = 0.8;
    } else if (screenWidth < 360) { // Small Mobile
      scaleFactor = 0.9;
    } else if (screenWidth < 480) { // Large Mobile
      scaleFactor = 1.0;
    } else if (screenWidth < 720) { // Small Tablet
      scaleFactor = 1.1;
    } else if (screenWidth < 1024) { // Large Tablet
      scaleFactor = 1.2;
    } else if (screenWidth < 1200) { // Small Desktop
      scaleFactor = 1.3;
    } else if (screenWidth < 1920) { // Desktop
      scaleFactor = 1.4;
    } else { // Ultra-wide
      scaleFactor = 1.5;
    }

    return baseSize * scaleFactor;
  }

  /// Returns a responsive TextStyle with font size scaling and clamping
  /// Ensures readability on large screens while maintaining minimum sizes
  /// Minimum 14px body/18px headings, maximum 24px body/36px headings
  static TextStyle getResponsiveTextStyle(
    BuildContext context,
    TextStyle baseStyle, {
    double minFontSize = 14.0,
    double maxFontSize = 24.0,
  }) {
    final scaledSize = getScaledFontSize(context, baseStyle.fontSize ?? 16.0);
    final clampedSize = scaledSize.clamp(minFontSize, maxFontSize);

    return baseStyle.copyWith(fontSize: clampedSize);
  }

  /// Predefined responsive text styles for common use cases
  /// Base font sizes: Mobile 14-16px body/18-24px headings, Tablet 16-18px body/20-28px headings, Desktop 16-20px body/24-32px headings
  /// Line height: 1.4-1.6
  static TextStyle getResponsiveHeadlineLarge(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.headlineLarge ?? const TextStyle(),
      minFontSize: 24.0, // Mobile: 24px headings
      maxFontSize: 36.0, // Desktop: 32px headings, clamped to 36px max
    ).copyWith(height: 1.4);
  }

  static TextStyle getResponsiveHeadlineMedium(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.headlineMedium ?? const TextStyle(),
      minFontSize: 20.0, // Mobile: 20px headings
      maxFontSize: 32.0, // Desktop: 28px headings, clamped to 32px max
    ).copyWith(height: 1.4);
  }

  static TextStyle getResponsiveHeadlineSmall(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.headlineSmall ?? const TextStyle(),
      minFontSize: 18.0, // Mobile: 18px headings
      maxFontSize: 28.0, // Desktop: 24px headings, clamped to 28px max
    ).copyWith(height: 1.5);
  }

  static TextStyle getResponsiveTitleLarge(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
      minFontSize: 16.0, // Mobile: 16px body
      maxFontSize: 24.0, // Desktop: 20px body, clamped to 24px max
    ).copyWith(height: 1.5);
  }

  static TextStyle getResponsiveTitleMedium(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.titleMedium ?? const TextStyle(),
      minFontSize: 16.0, // Mobile: 16px body
      maxFontSize: 22.0, // Desktop: 18px body, clamped to 22px max
    ).copyWith(height: 1.5);
  }

  static TextStyle getResponsiveTitleSmall(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.titleSmall ?? const TextStyle(),
      minFontSize: 14.0, // Mobile: 14px body
      maxFontSize: 20.0, // Desktop: 16px body, clamped to 20px max
    ).copyWith(height: 1.5);
  }

  static TextStyle getResponsiveBodyLarge(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.bodyLarge ?? const TextStyle(),
      minFontSize: 14.0, // Mobile: 14px body
      maxFontSize: 20.0, // Desktop: 16px body, clamped to 20px max
    ).copyWith(height: 1.6);
  }

  static TextStyle getResponsiveBodyMedium(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
      minFontSize: 14.0, // Mobile: 14px body
      maxFontSize: 18.0, // Desktop: 16px body, clamped to 18px max
    ).copyWith(height: 1.6);
  }

  static TextStyle getResponsiveBodySmall(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
      minFontSize: 12.0,
      maxFontSize: 16.0,
    ).copyWith(height: 1.6);
  }

  static TextStyle getResponsiveLabelLarge(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.labelLarge ?? const TextStyle(),
      minFontSize: 12.0,
      maxFontSize: 16.0,
    ).copyWith(height: 1.5);
  }

  static TextStyle getResponsiveLabelMedium(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
      minFontSize: 11.0,
      maxFontSize: 14.0,
    ).copyWith(height: 1.5);
  }

  static TextStyle getResponsiveLabelSmall(BuildContext context) {
    return getResponsiveTextStyle(
      context,
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
      minFontSize: 10.0,
      maxFontSize: 12.0,
    ).copyWith(height: 1.5);
  }
}
