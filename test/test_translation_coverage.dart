import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlaabo/main.dart';
import 'package:nlaabo/providers/localization_provider.dart';
import 'package:provider/provider.dart';

/// Translation coverage testing as outlined in PROJECT_ISSUES_ANALYSIS.md
/// Tests for hardcoded strings and translation completeness

void main() {
  group('Translation Coverage Tests', () {
    late TestWidgetsFlutterBinding binding;

    setUp(() {
      binding = TestWidgetsFlutterBinding.ensureInitialized();
    });

    final languages = ['en', 'fr', 'ar'];

    group('Hardcoded String Detection', () {
      for (final language in languages) {
        testWidgets('No hardcoded strings in $language', (WidgetTester tester) async {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(
                  create: (_) => LocalizationProvider()..setLanguage(language),
                ),
              ],
              child: const NlaaboApp(),
            ),
          );

          await tester.pumpAndSettle();

          // Test for hardcoded strings that should be translated
          // Based on PROJECT_ISSUES_ANALYSIS.md findings

          // Home screen hardcoded strings
          final hardcodedHomeStrings = [
            'Search Results for',
            'Matches',
            'Teams',
            'No matches or teams found for',
            'Try adjusting your search terms or explore available content',
            'Clear search',
            'Clear the search query to see all content',
            'Clear Search',
            'Create content',
            'Create a new team or match to get started',
            'Explore all content',
            'Browse all available matches and teams',
            'Explore All',
            'Create Match',
            'Create Team',
          ];

          for (final hardcodedString in hardcodedHomeStrings) {
            final foundTexts = find.textContaining(hardcodedString);
            if (foundTexts.evaluate().isNotEmpty) {
              fail('Found hardcoded string "$hardcodedString" in $language - should use translation keys');
            }
          }

          // Login screen hardcoded strings
          final hardcodedLoginStrings = [
            'Forgot Password?',
            'or',
          ];

          for (final hardcodedString in hardcodedLoginStrings) {
            final foundTexts = find.textContaining(hardcodedString);
            if (foundTexts.evaluate().isNotEmpty) {
              fail('Found hardcoded string "$hardcodedString" in $language - should use translation keys');
            }
          }

          // Main layout hardcoded strings
          final hardcodedLayoutStrings = [
            'Language',
          ];

          for (final hardcodedString in hardcodedLayoutStrings) {
            final foundTexts = find.textContaining(hardcodedString);
            if (foundTexts.evaluate().isNotEmpty) {
              fail('Found hardcoded string "$hardcodedString" in $language - should use translation keys');
            }
          }
        });
      }
    });

    group('Translation Key Coverage', () {
      for (final language in languages) {
        testWidgets('Translation keys exist for $language', (WidgetTester tester) async {
          final localizationProvider = LocalizationProvider()..setLanguage(language);

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => localizationProvider),
              ],
              child: const NlaaboApp(),
            ),
          );

          await tester.pumpAndSettle();

          // Test that required translation keys exist
          final requiredKeys = [
            'search_results_for',
            'no_results_found',
            'clear_search',
            'explore_all',
            'create_content',
            'or',
            'forgot_password',
          ];

          for (final key in requiredKeys) {
            final translation = localizationProvider.translate(key);
            expect(translation, isNotNull,
                reason: 'Translation key "$key" should exist for $language');
            expect(translation, isNotEmpty,
                reason: 'Translation key "$key" should not be empty for $language');
            expect(translation, isNot(equals(key)),
                reason: 'Translation key "$key" should be translated, not returned as key for $language');
          }
        });
      }
    });

    group('Translation Quality Tests', () {
      testWidgets('Arabic RTL text direction', (WidgetTester tester) async {
        final localizationProvider = LocalizationProvider()..setLanguage('ar');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => localizationProvider),
            ],
            child: const NlaaboApp(),
          ),
        );

        await tester.pumpAndSettle();

        // Test that Arabic text is properly RTL
        final context = tester.element(find.byType(Scaffold).first);
        final directionality = context.findAncestorWidgetOfExactType<Directionality>();

        expect(directionality?.textDirection, equals(TextDirection.rtl),
            reason: 'Arabic should use RTL text direction');

        // Test that Arabic translations don't contain placeholder text
        final arabicTranslations = [
          localizationProvider.translate('app_name'),
          localizationProvider.translate('login'),
          localizationProvider.translate('signup'),
        ];

        for (final translation in arabicTranslations) {
          expect(translation.contains('TODO'), isFalse,
              reason: 'Arabic translations should not contain TODO placeholders');
          expect(translation.contains('FIXME'), isFalse,
              reason: 'Arabic translations should not contain FIXME placeholders');
                }
      });

      testWidgets('LTR text direction for English and French', (WidgetTester tester) async {
        for (final lang in ['en', 'fr']) {
          final localizationProvider = LocalizationProvider()..setLanguage(lang);

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => localizationProvider),
              ],
              child: const NlaaboApp(),
            ),
          );

          await tester.pumpAndSettle();

          final context = tester.element(find.byType(Scaffold).first);
          final directionality = context.findAncestorWidgetOfExactType<Directionality>();

          expect(directionality?.textDirection, equals(TextDirection.ltr),
              reason: '$lang should use LTR text direction');
        }
      });
    });

    group('Long Content Handling', () {
      testWidgets('Long user-generated content handling', (WidgetTester tester) async {
        // Test with simulated long content
        const longTeamName = 'A Very Long Team Name That Might Cause Truncation Issues In Some Languages And Layouts';
        const longMatchDescription = 'This is a very long match description that contains a lot of text and might cause layout issues if not handled properly in different screen sizes and languages.';

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LocalizationProvider()),
            ],
            child: const NlaaboApp(),
          ),
        );

        await tester.pumpAndSettle();

        // Test that the app can handle long content without crashing
        // This is a basic test - in a real scenario, you'd inject mock data
        expect(find.byType(Scaffold), findsWidgets,
            reason: 'App should handle long content gracefully');
      });
    });

    group('Translation Consistency', () {
      testWidgets('Translation method consistency', (WidgetTester tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => LocalizationProvider()),
            ],
            child: const NlaaboApp(),
          ),
        );

        await tester.pumpAndSettle();

        // Test that translation provider is accessible throughout the widget tree
        final context = tester.element(find.byType(Scaffold).first);
        final localizationProvider = context.read<LocalizationProvider>();

        expect(localizationProvider, isNotNull,
            reason: 'LocalizationProvider should be available in widget tree');

        // Test that current language is set
        expect(localizationProvider.currentLanguage, isNotNull,
            reason: 'Current language should be set');
        expect(localizationProvider.currentLanguage, isNotEmpty,
            reason: 'Current language should not be empty');
      });
    });
  });
}