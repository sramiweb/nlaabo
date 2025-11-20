import 'package:flutter/material.dart';
import '../colors/app_colors_theme.dart';
import '../typography/app_text_styles.dart';
import '../spacing/app_spacing.dart';

/// AppTheme class that manages theme switching and provides theme data
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      extensions: [AppColorsTheme.light()],

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF34D399),
        onPrimary: Colors.white,
        secondary: Color(0xFF4B5563),
        onSecondary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1F2937),
      ),

      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF1F2937),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34D399),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: AppSpacing.buttonPaddingInsets,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFF34D399), width: 2),
        ),
        contentPadding: AppSpacing.inputPaddingInsets,
        hintStyle: AppTextStyles.bodyText.copyWith(
          color: const Color(0xFF6B7280),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.pageTitle.copyWith(color: const Color(0xFF1F2937)),
        displayMedium: AppTextStyles.headingLarge.copyWith(color: const Color(0xFF1F2937)),
        displaySmall: AppTextStyles.headingMedium.copyWith(color: const Color(0xFF1F2937)),
        headlineLarge: AppTextStyles.headingSmall.copyWith(color: const Color(0xFF1F2937)),
        headlineMedium: AppTextStyles.sectionTitle.copyWith(color: const Color(0xFF1F2937)),
        headlineSmall: AppTextStyles.cardTitle.copyWith(color: const Color(0xFF1F2937)),
        titleLarge: AppTextStyles.subtitle.copyWith(color: const Color(0xFF1F2937)),
        titleMedium: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFF1F2937)),
        titleSmall: AppTextStyles.bodyText.copyWith(color: const Color(0xFF1F2937)),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFF1F2937)),
        bodyMedium: AppTextStyles.bodyText.copyWith(color: const Color(0xFF1F2937)),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFF1F2937)),
        labelLarge: AppTextStyles.labelText.copyWith(color: const Color(0xFF1F2937)),
        labelMedium: AppTextStyles.caption.copyWith(color: const Color(0xFF1F2937)),
        labelSmall: AppTextStyles.overline.copyWith(color: const Color(0xFF1F2937)),
      ),
    );
  }

  /// Dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      extensions: [AppColorsTheme.dark()],

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF34D399),
        onPrimary: Color(0xFF111827),
        secondary: Color(0xFF9CA3AF),
        onSecondary: Color(0xFF111827),
        error: Color(0xFFEF4444),
        onError: Color(0xFF111827),
        surface: Color(0xFF1F2937),
        onSurface: Color(0xFFF9FAFB),
      ),

      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFF111827),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F2937),
        foregroundColor: Color(0xFFF9FAFB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: const Color(0xFF1F2937),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF34D399),
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          padding: AppSpacing.buttonPaddingInsets,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
          borderSide: const BorderSide(color: Color(0xFF34D399), width: 2),
        ),
        contentPadding: AppSpacing.inputPaddingInsets,
        hintStyle: AppTextStyles.bodyText.copyWith(
          color: const Color(0xFF9CA3AF),
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.pageTitle.copyWith(color: const Color(0xFFF9FAFB)),
        displayMedium: AppTextStyles.headingLarge.copyWith(color: const Color(0xFFF9FAFB)),
        displaySmall: AppTextStyles.headingMedium.copyWith(color: const Color(0xFFF9FAFB)),
        headlineLarge: AppTextStyles.headingSmall.copyWith(color: const Color(0xFFF9FAFB)),
        headlineMedium: AppTextStyles.sectionTitle.copyWith(color: const Color(0xFFF9FAFB)),
        headlineSmall: AppTextStyles.cardTitle.copyWith(color: const Color(0xFFF9FAFB)),
        titleLarge: AppTextStyles.subtitle.copyWith(color: const Color(0xFFF9FAFB)),
        titleMedium: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFFF9FAFB)),
        titleSmall: AppTextStyles.bodyText.copyWith(color: const Color(0xFFF9FAFB)),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: const Color(0xFFF9FAFB)),
        bodyMedium: AppTextStyles.bodyText.copyWith(color: const Color(0xFFF9FAFB)),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFF9FAFB)),
        labelLarge: AppTextStyles.labelText.copyWith(color: const Color(0xFFF9FAFB)),
        labelMedium: AppTextStyles.caption.copyWith(color: const Color(0xFFF9FAFB)),
        labelSmall: AppTextStyles.overline.copyWith(color: const Color(0xFFF9FAFB)),
      ),
    );
  }
}
