import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nlaabo/providers/theme_provider.dart';
import 'package:nlaabo/design_system/components/buttons/primary_button.dart';
import 'package:nlaabo/design_system/components/buttons/secondary_button.dart';
import 'package:nlaabo/design_system/components/buttons/destructive_button.dart';
import 'package:nlaabo/design_system/components/cards/base_card.dart';
import 'package:nlaabo/design_system/components/forms/app_text_field.dart';
import 'package:nlaabo/design_system/colors/app_colors_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Component Theme Switching Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      themeProvider = ThemeProvider();
    });

    tearDown(() {
      themeProvider.dispose();
    });

    testWidgets('PrimaryButton adapts to light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: Scaffold(
                  body: PrimaryButton(
                    text: 'Test Button',
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );

      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      final colors = AppColorsTheme.of(tester.element(find.byType(PrimaryButton)));
      expect(colors.primary, const Color(0xFF34D399));

      // Verify button is rendered
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('PrimaryButton adapts to dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: Scaffold(
                  body: PrimaryButton(
                    text: 'Test Button',
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );

      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      final colors = AppColorsTheme.of(tester.element(find.byType(PrimaryButton)));
      expect(colors.primary, const Color(0xFF34D399));

      // Verify button is rendered
      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('SecondaryButton adapts to themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: Scaffold(
                  body: Column(
                    children: [
                      SecondaryButton(
                        text: 'Light Theme',
                        onPressed: () {},
                      ),
                      SecondaryButton(
                        text: 'Dark Theme',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Test light theme
      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      var colors = AppColorsTheme.of(tester.element(find.byType(Column)));
      expect(colors.surface, const Color(0xFFFFFFFF));

      // Test dark theme
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      colors = AppColorsTheme.of(tester.element(find.byType(Column)));
      expect(colors.surface, const Color(0xFF1F2937));

      // Verify buttons are rendered
      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets('DestructiveButton adapts to themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: Scaffold(
                  body: DestructiveButton(
                    text: 'Delete',
                    onPressed: () {},
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Test light theme
      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      var colors = AppColorsTheme.of(tester.element(find.byType(DestructiveButton)));
      expect(colors.destructive, const Color(0xFFEF4444));

      // Test dark theme
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      colors = AppColorsTheme.of(tester.element(find.byType(DestructiveButton)));
      expect(colors.destructive, const Color(0xFFEF4444));

      // Verify button is rendered
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('BaseCard adapts to themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: const Scaffold(
                  body: BaseCard(
                    child: Text('Card Content'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Test light theme
      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      var colors = AppColorsTheme.of(tester.element(find.byType(BaseCard)));
      expect(colors.surface, const Color(0xFFFFFFFF));

      // Test dark theme
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      colors = AppColorsTheme.of(tester.element(find.byType(BaseCard)));
      expect(colors.surface, const Color(0xFF1F2937));

      // Verify card content is rendered
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('AppTextField adapts to themes', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: const Scaffold(
                  body: AppTextField(
                    labelText: 'Test Field',
                    hintText: 'Enter text',
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Test light theme
      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      var colors = AppColorsTheme.of(tester.element(find.byType(AppTextField)));
      expect(colors.textPrimary, const Color(0xFF1F2937));
      expect(colors.surface, const Color(0xFFFFFFFF));

      // Test dark theme
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      colors = AppColorsTheme.of(tester.element(find.byType(AppTextField)));
      expect(colors.textPrimary, const Color(0xFFF9FAFB));
      expect(colors.surface, const Color(0xFF1F2937));

      // Verify text field is rendered
      expect(find.text('Test Field'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('Theme switching maintains component functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                theme: themeProvider.themeData,
                home: Scaffold(
                  body: Column(
                    children: [
                      PrimaryButton(
                        text: 'Primary',
                        onPressed: () {},
                      ),
                      SecondaryButton(
                        text: 'Secondary',
                        onPressed: () {},
                      ),
                      const AppTextField(
                        labelText: 'Input',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Enter text in light theme
      await themeProvider.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'test input');
      expect(find.text('test input'), findsOneWidget);

      // Switch to dark theme
      await themeProvider.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      // Verify text is preserved and components still work
      expect(find.text('test input'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);

      // Verify buttons are still interactive
      final primaryButton = find.byType(ElevatedButton).first;
      final secondaryButton = find.byType(OutlinedButton).first;

      expect(tester.widget<ElevatedButton>(primaryButton).enabled, isTrue);
      expect(tester.widget<OutlinedButton>(secondaryButton).enabled, isTrue);
    });
  });
}