import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/responsive_utils.dart';

/// AppTextStyles class containing all typography styles using Inter font
/// as specified in the UI redesign specification section 3.2
/// Enhanced with responsive scaling for different screen sizes
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // Page title - 36px, w700
  static TextStyle get pageTitle => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Section title - 24px, w700
  static TextStyle get sectionTitle => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // Card title - 20px, w700
  static TextStyle get cardTitle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  // Body text - 16px, w500
  static TextStyle get bodyText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  // Label text - 14px, w600
  static TextStyle get labelText => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Additional text styles for comprehensive design system

  // Large heading - 32px, w700
  static TextStyle get headingLarge => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  // Medium heading - 28px, w700
  static TextStyle get headingMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  // Small heading - 22px, w600
  static TextStyle get headingSmall => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Subtitle - 18px, w600
  static TextStyle get subtitle => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Body large - 18px, w400
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Body small - 14px, w400
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Caption - 12px, w500
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // Button text - 16px, w600
  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Button small - 14px, w600
  static TextStyle get buttonSmall => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // Overline - 12px, w700, uppercase
  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 1.2,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Get responsive text style based on screen size
  static TextStyle getResponsiveTextStyle(BuildContext context, TextStyle baseStyle) {
    final scaleFactor = ResponsiveUtils.getTextScaleFactor(context);
    return baseStyle.copyWith(
      fontSize: baseStyle.fontSize! * scaleFactor,
      height: baseStyle.height,
      letterSpacing: baseStyle.letterSpacing,
    );
  }

  /// Responsive page title - scales from 28px (mobile) to 40px (desktop)
  static TextStyle getResponsivePageTitle(BuildContext context) {
    return getResponsiveTextStyle(context, pageTitle);
  }

  /// Responsive section title - scales from 20px (mobile) to 28px (desktop)
  static TextStyle getResponsiveSectionTitle(BuildContext context) {
    return getResponsiveTextStyle(context, sectionTitle);
  }

  /// Responsive card title - scales from 18px (mobile) to 22px (desktop)
  static TextStyle getResponsiveCardTitle(BuildContext context) {
    return getResponsiveTextStyle(context, cardTitle);
  }

  /// Responsive body text - scales from 14px (mobile) to 18px (desktop)
  static TextStyle getResponsiveBodyText(BuildContext context) {
    return getResponsiveTextStyle(context, bodyText);
  }

  /// Responsive label text - scales from 12px (mobile) to 16px (desktop)
  static TextStyle getResponsiveLabelText(BuildContext context) {
    return getResponsiveTextStyle(context, labelText);
  }
}
