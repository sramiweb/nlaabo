import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nlaabo/providers/theme_provider.dart';
import 'package:nlaabo/design_system/colors/app_colors_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Persistence Tests', () {
    late ThemeProvider themeProvider;

    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
      // ThemeProvider loads settings automatically in constructor
    });

    tearDown(() {
      themeProvider.dispose();
    });

    testWidgets('Theme preference persists across app restarts', (WidgetTester tester) async {
      // First app instance - set dark theme
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: const Scaffold(
                  body: Text('First Instance'),
                ),
              );
            },
          ),
        ),
      );

      // Set dark theme and verify
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      var colors = AppColorsTheme.of(tester.element(find.byType(Scaffold)));
      expect(colors.background, const Color(0xFF111827));
      expect(themeProvider.themeMode, ThemeMode.dark);

      // Simulate app restart by creating new provider instance
      final newThemeProvider = ThemeProvider();
      // Wait for settings to load (ThemeProvider loads automatically in constructor)
      await Future.delayed(const Duration(milliseconds: 100));

      // Second app instance - verify theme is restored
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: newThemeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: newThemeProvider.themeData,
                home: const Scaffold(
                  body: Text('Second Instance'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dark theme is restored
      colors = AppColorsTheme.of(tester.element(find.byType(Scaffold)));
      expect(colors.background, const Color(0xFF111827));
      expect(newThemeProvider.themeMode, ThemeMode.dark);

      newThemeProvider.dispose();
    });

    testWidgets('Light theme persists across app restarts', (WidgetTester tester) async {
      // Set light theme
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: const Scaffold(
                  body: Text('Light Theme Test'),
                ),
              );
            },
          ),
        ),
      );

      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      var colors = AppColorsTheme.of(tester.element(find.byType(Scaffold)));
      expect(colors.background, const Color(0xFFF3F4F6));
      expect(themeProvider.themeMode, ThemeMode.light);

      // Simulate restart
      final newThemeProvider = ThemeProvider();
      // Wait for settings to load
      await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: newThemeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: newThemeProvider.themeData,
                home: const Scaffold(
                  body: Text('Restarted App'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify light theme is restored
      colors = AppColorsTheme.of(tester.element(find.byType(Scaffold)));
      expect(colors.background, const Color(0xFFF3F4F6));
      expect(newThemeProvider.themeMode, ThemeMode.light);

      newThemeProvider.dispose();
    });

    testWidgets('System theme defaults to light when no preference saved', (WidgetTester tester) async {
      // Clear any existing preferences
      SharedPreferences.setMockInitialValues({});

      final newThemeProvider = ThemeProvider();
      // Wait for settings to load
      await Future.delayed(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: newThemeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: newThemeProvider.themeData,
                home: const Scaffold(
                  body: Text('Default Theme Test'),
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should default to light theme when no preference is saved
      final colors = AppColorsTheme.of(tester.element(find.byType(Scaffold)));
      expect(colors.background, const Color(0xFFF3F4F6));
      expect(newThemeProvider.themeMode, ThemeMode.light);

      newThemeProvider.dispose();
    });

    testWidgets('Theme changes are immediately applied and persisted', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: Scaffold(
                  body: Container(
                    color: AppColorsTheme.of(context).background,
                    child: const Text('Theme Change Test'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Start with light theme
      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      var container = tester.widget<Container>(find.byType(Container));
      expect((container.decoration as BoxDecoration).color, const Color(0xFFF3F4F6));

      // Change to dark theme
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      container = tester.widget<Container>(find.byType(Container));
      expect((container.decoration as BoxDecoration).color, const Color(0xFF111827));

      // Verify persistence by creating new instance
      final persistedThemeProvider = ThemeProvider();
      // Wait for settings to load
      await Future.delayed(const Duration(milliseconds: 100));

      expect(persistedThemeProvider.themeMode, ThemeMode.dark);

      persistedThemeProvider.dispose();
    });
  });
}