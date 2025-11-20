import 'package:flutter/material.dart';

/// Centralized theme configuration for the application
class AppTheme {
  // Updated color palette
  static const Color primaryColor = Color(0xFF1B5E20);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color surfaceColor = Color(0xFFFFFFFF); // Adaptive surface
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);

  // Accessibility colors
  static const Color focusIndicatorColor = primaryColor;
  static const double focusIndicatorWidth = 2.0;

  /// Light theme configuration
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
          surface: surfaceColor,
          error: errorColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            minimumSize: const Size(44, 44), // Compact minimum touch target (WCAG AAA)
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: focusIndicatorColor, width: focusIndicatorWidth),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          constraints: BoxConstraints(minHeight: 44), // Compact minimum height
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 14),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      );

  /// Dark theme configuration
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212), // Adaptive surface for dark
          error: errorColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            minimumSize: const Size(48, 48), // Minimum touch target
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF424242)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF424242)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: focusIndicatorColor, width: focusIndicatorWidth),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          constraints: BoxConstraints(minHeight: 48), // Minimum touch target height
          labelStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.25,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),

        // Component specifications
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: primaryColor,
          unselectedItemColor: Color(0xFF757575),
          backgroundColor: surfaceColor,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),

        // Card theme with responsive specs
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          color: surfaceColor,
        ),

        // List tile theme
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minVerticalPadding: 8,
          minLeadingWidth: 24,
        ),

        // Icon button theme with minimum touch targets
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(44, 44), // Compact minimum touch target
            padding: const EdgeInsets.all(10),
          ),
        ),

        // Text button theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44), // Compact minimum touch target
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Outlined button theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(44, 44), // Compact minimum touch target
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            side: const BorderSide(color: primaryColor),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Floating action button theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          sizeConstraints: BoxConstraints.tightFor(width: 56, height: 56), // Minimum touch target
          elevation: 6,
          focusElevation: 8,
        ),

        // Chip theme
        chipTheme: const ChipThemeData(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          labelStyle: TextStyle(fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          side: BorderSide.none,
          elevation: 0,
          pressElevation: 2,
        ),

        // Tab bar theme
        tabBarTheme: const TabBarThemeData(
          labelPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
        ),

        // Dialog theme
        dialogTheme: const DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          elevation: 8,
          backgroundColor: surfaceColor,
        ),

        // SnackBar theme
        snackBarTheme: const SnackBarThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          elevation: 6,
          backgroundColor: Color(0xFF323232),
          contentTextStyle: TextStyle(color: Colors.white),
          actionTextColor: secondaryColor,
        ),

        // Tooltip theme
        tooltipTheme: const TooltipThemeData(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Color(0xFF323232),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          textStyle: TextStyle(color: Colors.white, fontSize: 14),
        ),

        // Divider theme
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
          color: Color(0xFFE0E0E0),
        ),

        // Progress indicator theme
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          linearTrackColor: Color(0xFFE0E0E0),
          circularTrackColor: Color(0xFFE0E0E0),
        ),

        // Switch theme
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return Colors.white;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor.withValues(alpha: 0.5);
            }
            return Colors.grey.shade400;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),

        // Checkbox theme
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: Color(0xFF757575)),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),

        // Radio theme
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return Colors.grey.shade600;
          }),
        ),

        // Slider theme
        sliderTheme: const SliderThemeData(
          activeTrackColor: primaryColor,
          inactiveTrackColor: Color(0x801B5E20),
          thumbColor: primaryColor,
          overlayColor: Color(0x331B5E20),
          valueIndicatorColor: primaryColor,
          trackHeight: 4,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 24),
        ),

        // Navigation rail theme for web side navigation
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: surfaceColor,
          selectedIconTheme: IconThemeData(color: primaryColor),
          unselectedIconTheme: IconThemeData(color: Color(0xFF757575)),
          selectedLabelTextStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelTextStyle: TextStyle(color: Color(0xFF757575)),
          labelType: NavigationRailLabelType.all,
          groupAlignment: 0,
          minWidth: 72,
          minExtendedWidth: 192,
        ),

        // Navigation drawer theme
        navigationDrawerTheme: const NavigationDrawerThemeData(
          backgroundColor: surfaceColor,
          surfaceTintColor: surfaceColor,
          elevation: 1,
          shadowColor: Color(0x19000000),
          indicatorColor: Color(0x191B5E20),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        // Data table theme
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor.withValues(alpha: 0.1);
            }
            return Colors.transparent;
          }),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF212121),
          ),
          dataTextStyle: const TextStyle(color: Color(0xFF212121)),
          dividerThickness: 1,
          horizontalMargin: 16,
          columnSpacing: 56,
          checkboxHorizontalMargin: 12,
        ),

        // Expansion tile theme
        expansionTileTheme: const ExpansionTileThemeData(
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          expandedAlignment: AlignmentDirectional.centerStart,
          childrenPadding: EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
          iconColor: Color(0xFF757575),
          collapsedIconColor: Color(0xFF757575),
          textColor: Color(0xFF212121),
          collapsedTextColor: Color(0xFF212121),
        ),

        // Popup menu theme
        popupMenuTheme: const PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          elevation: 8,
          color: surfaceColor,
          textStyle: TextStyle(color: Color(0xFF212121)),
        ),

        // Banner theme
        bannerTheme: const MaterialBannerThemeData(
          backgroundColor: primaryColor,
          contentTextStyle: TextStyle(color: Colors.white),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),

        // Bottom sheet theme
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surfaceColor,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          clipBehavior: Clip.antiAlias,
          modalBackgroundColor: surfaceColor,
          modalElevation: 8,
          modalBarrierColor: Color(0x80000000),
        ),

        // Time picker theme
        timePickerTheme: const TimePickerThemeData(
          backgroundColor: surfaceColor,
          hourMinuteColor: Color(0x191B5E20),
          hourMinuteTextColor: primaryColor,
          dayPeriodColor: Color(0x191B5E20),
          dayPeriodTextColor: primaryColor,
          dialHandColor: primaryColor,
          dialBackgroundColor: Color(0x191B5E20),
          entryModeIconColor: primaryColor,
        ),

        // Date picker theme
        datePickerTheme: DatePickerThemeData(
          backgroundColor: surfaceColor,
          headerBackgroundColor: primaryColor,
          headerForegroundColor: Colors.white,
          surfaceTintColor: surfaceColor,
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return Colors.transparent;
          }),
          todayBackgroundColor: WidgetStateProperty.all(const Color(0x331B5E20)),
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF212121);
          }),
          todayForegroundColor: WidgetStateProperty.all(primaryColor),
          yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return primaryColor;
            }
            return Colors.transparent;
          }),
          yearForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.white;
            }
            return const Color(0xFF212121);
          }),
        ),

        // Search bar theme
        searchBarTheme: SearchBarThemeData(
          backgroundColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          overlayColor: WidgetStateProperty.all(const Color(0x191B5E20)),
          shadowColor: WidgetStateProperty.all(const Color(0x19000000)),
          elevation: WidgetStateProperty.all(2),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16)),
          textStyle: WidgetStateProperty.all(const TextStyle(color: Color(0xFF212121))),
          hintStyle: WidgetStateProperty.all(const TextStyle(color: Color(0xFF757575))),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
          ),
        ),

        // Search view theme
        searchViewTheme: const SearchViewThemeData(
          backgroundColor: surfaceColor,
          surfaceTintColor: surfaceColor,
          dividerColor: Color(0xFFE0E0E0),
          elevation: 8,
        ),
      );
}
