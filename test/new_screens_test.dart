import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nlaabo/providers/auth_provider.dart';
import 'package:nlaabo/providers/localization_provider.dart';
import 'package:nlaabo/screens/team_members_management_screen.dart';
import 'package:nlaabo/screens/match_history_screen.dart';
import 'package:nlaabo/screens/advanced_search_screen.dart';

void main() {
  group('New Screens Integration Tests', () {
    late AuthProvider authProvider;
    late LocalizationProvider localizationProvider;

    setUp(() {
      authProvider = AuthProvider();
      localizationProvider = LocalizationProvider();
    });

    Widget createTestWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<LocalizationProvider>.value(value: localizationProvider),
        ],
        child: MaterialApp(
          home: child,
          localizationsDelegates: const [],
        ),
      );
    }

    testWidgets('TeamMembersManagementScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const TeamMembersManagementScreen(teamId: 'test-team-id'),
        ),
      );
      expect(find.byType(TeamMembersManagementScreen), findsOneWidget);
    });

    testWidgets('MatchHistoryScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(const MatchHistoryScreen()),
      );
      expect(find.byType(MatchHistoryScreen), findsOneWidget);
    });

    testWidgets('AdvancedSearchScreen renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(const AdvancedSearchScreen()),
      );
      expect(find.byType(AdvancedSearchScreen), findsOneWidget);
    });
  });
}
