import 'package:flutter/material.dart';
import '../colors/app_colors_theme.dart';
import '../typography/app_text_styles.dart';
import '../spacing/app_spacing.dart';

/// Light theme configuration
/// This file provides a focused light theme implementation
/// that can be used independently or as part of the AppTheme
class LightTheme {
  // Private constructor to prevent instantiation
  LightTheme._();

  /// Get the complete light theme data
  static ThemeData get theme {
    final colors = AppColorsTheme.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: [colors],

      // Primary color scheme
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.surface,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: AppSpacing.buttonPaddingInsets,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTextStyles.buttonText,
          padding: AppSpacing.buttonPaddingInsets,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: BorderSide(color: colors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: BorderSide(color: colors.destructive, width: 2),
        ),
        contentPadding: AppSpacing.inputPaddingInsets,
        hintStyle: AppTextStyles.bodyText.copyWith(
          color: colors.textSubtle,
        ),
        labelStyle: AppTextStyles.labelText.copyWith(
          color: colors.textPrimary,
        ),
        errorStyle: AppTextStyles.caption.copyWith(
          color: colors.destructive,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.pageTitle.copyWith(color: colors.textPrimary),
        displayMedium: AppTextStyles.headingLarge.copyWith(color: colors.textPrimary),
        displaySmall: AppTextStyles.headingMedium.copyWith(color: colors.textPrimary),
        headlineLarge: AppTextStyles.headingSmall.copyWith(color: colors.textPrimary),
        headlineMedium: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
        headlineSmall: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
        titleLarge: AppTextStyles.subtitle.copyWith(color: colors.textPrimary),
        titleMedium: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
        titleSmall: AppTextStyles.bodyText.copyWith(color: colors.textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
        bodyMedium: AppTextStyles.bodyText.copyWith(color: colors.textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary),
        labelLarge: AppTextStyles.labelText.copyWith(color: colors.textPrimary),
        labelMedium: AppTextStyles.caption.copyWith(color: colors.textPrimary),
        labelSmall: AppTextStyles.overline.copyWith(color: colors.textPrimary),
      ),

      // Color scheme for Material 3
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.gray600,
        onSecondary: Colors.white,
        error: colors.destructive,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceTint: colors.surface,
        outline: colors.border,
        outlineVariant: colors.gray300,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 16,
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colors.textPrimary,
        size: AppSpacing.iconSize,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface,
        selectedColor: colors.primary.withValues(alpha: 0.1),
        checkmarkColor: colors.primary,
        deleteIconColor: colors.destructive,
        labelStyle: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary),
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: colors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          side: BorderSide(color: colors.border),
        ),
      ),
    );
  }
}
