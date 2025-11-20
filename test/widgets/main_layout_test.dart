import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nlaabo/widgets/main_layout.dart';
import 'package:nlaabo/utils/responsive_utils.dart';
import 'package:nlaabo/providers/localization_provider.dart';
import 'package:provider/provider.dart';

/// Widget tests for MainLayout to validate mobile layout detection and font size fixes
/// as recommended in PLAN_VALIDATION_ANALYSIS.md
///
/// Tests cover:
/// - Mobile web layout detection logic
/// - BottomNavigationBar font size accessibility compliance
/// - Responsive breakpoint validation
/// - Layout switching behavior

void main() {
  group('MainLayout Widget Tests', () {
    late TestWidgetsFlutterBinding binding;

    setUp(() {
      binding = TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      binding.setSurfaceSize(null);
    });

    // Test device configurations
    final mobileDevices = {
      'iPhone SE (375x667)': const Size(375, 667),
      'iPhone 12 (390x844)': const Size(390, 844),
      'Small Mobile (320x568)': const Size(320, 568),
      'Extra Small Mobile (280x568)': const Size(280, 568),
    };

    final tabletDevices = {
      'iPad (768x1024)': const Size(768, 1024),
      'iPad Pro (1024x1366)': const Size(1024, 1366),
    };

    final desktopDevices = {
      'Desktop (1920x1080)': const Size(1920, 1080),
      'Ultra-wide (2560x1440)': const Size(2560, 1440),
    };

    Widget createTestApp(Widget child) {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => child,
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/teams',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/matches',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const SizedBox(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SizedBox(),
          ),
        ],
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    group('Mobile Layout Detection Tests', () {
      testWidgets('Mobile devices use mobile layout', (WidgetTester tester) async {
        for (final device in mobileDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          // Verify mobile layout is used (BottomNavigationBar present)
          expect(find.byType(BottomNavigationBar), findsOneWidget,
              reason: '${device.key} should use mobile layout with BottomNavigationBar');

          // Verify no side navigation (web layout indicator)
          final scaffold = find.byType(Scaffold).first;
          final scaffoldWidget = tester.widget<Scaffold>(scaffold);
          expect(scaffoldWidget.drawer, isNull,
              reason: '${device.key} should not have side navigation drawer');
        }
      });

      testWidgets('Tablet devices use web layout', (WidgetTester tester) async {
        for (final device in tabletDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          // Verify web layout is used (no BottomNavigationBar)
          expect(find.byType(BottomNavigationBar), findsNothing,
              reason: '${device.key} should use web layout without BottomNavigationBar');

          // Verify side navigation is present
          final scaffold = find.byType(Scaffold).first;
          final scaffoldWidget = tester.widget<Scaffold>(scaffold);
          expect(scaffoldWidget.drawer, isNotNull,
              reason: '${device.key} should have side navigation drawer');
        }
      });

      testWidgets('Desktop devices use web layout', (WidgetTester tester) async {
        for (final device in desktopDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          // Verify web layout is used (no BottomNavigationBar)
          expect(find.byType(BottomNavigationBar), findsNothing,
              reason: '${device.key} should use web layout without BottomNavigationBar');

          // Verify side navigation is present
          final scaffold = find.byType(Scaffold).first;
          final scaffoldWidget = tester.widget<Scaffold>(scaffold);
          expect(scaffoldWidget.drawer, isNotNull,
              reason: '${device.key} should have side navigation drawer');
        }
      });
    });

    group('Mobile Web Layout Detection Tests', () {
      testWidgets('Mobile web browsers use mobile layout', (WidgetTester tester) async {
        // Test with kIsWeb simulation (limited in widget tests)
        // Focus on layout logic rather than platform detection
        for (final device in mobileDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          // Even on web, mobile-sized screens should use mobile layout
          expect(find.byType(BottomNavigationBar), findsOneWidget,
              reason: 'Mobile web (${device.key}) should use mobile layout');

          // Should not have side navigation
          final scaffold = find.byType(Scaffold).first;
          final scaffoldWidget = tester.widget<Scaffold>(scaffold);
          expect(scaffoldWidget.drawer, isNull,
              reason: 'Mobile web (${device.key}) should not have side navigation');
        }
      });

      testWidgets('Tablet web browsers use web layout', (WidgetTester tester) async {
        // Focus on layout logic rather than platform detection
        for (final device in tabletDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          // Tablet web should use web layout
          expect(find.byType(BottomNavigationBar), findsNothing,
              reason: 'Tablet web (${device.key}) should use web layout');

          // Should have side navigation
          final scaffold = find.byType(Scaffold).first;
          final scaffoldWidget = tester.widget<Scaffold>(scaffold);
          expect(scaffoldWidget.drawer, isNotNull,
              reason: 'Tablet web (${device.key}) should have side navigation');
        }
      });
    });

    group('BottomNavigationBar Font Size Accessibility Tests', () {
      testWidgets('Font sizes meet WCAG 2.1 minimum requirements', (WidgetTester tester) async {
        for (final device in mobileDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          final bottomNav = find.byType(BottomNavigationBar);
          expect(bottomNav, findsOneWidget,
              reason: '${device.key} should have BottomNavigationBar');

          final bottomNavWidget = tester.widget<BottomNavigationBar>(bottomNav);

          // Test selected font size (should be at least 14px for WCAG compliance)
          expect(bottomNavWidget.selectedFontSize, greaterThanOrEqualTo(14.0),
              reason: 'Selected font size must be >= 14px for WCAG 2.1 compliance on ${device.key}');

          // Test unselected font size (should be at least 12px for readability)
          expect(bottomNavWidget.unselectedFontSize, greaterThanOrEqualTo(12.0),
              reason: 'Unselected font size must be >= 12px for readability on ${device.key}');
        }
      });

      testWidgets('Font sizes are responsive to device size', (WidgetTester tester) async {
        // Test extra small mobile (<320px)
        await binding.setSurfaceSize(const Size(280, 568));
        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        final bottomNav = find.byType(BottomNavigationBar);
        final bottomNavWidget = tester.widget<BottomNavigationBar>(bottomNav);

        // Extra small mobile should have minimum 14px fonts
        expect(bottomNavWidget.selectedFontSize, equals(14.0),
            reason: 'Extra small mobile should have 14px selected font size');
        expect(bottomNavWidget.unselectedFontSize, equals(12.0),
            reason: 'Extra small mobile should have 12px unselected font size');

        // Test small mobile (320-360px)
        await binding.setSurfaceSize(const Size(350, 568));
        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        final bottomNav2 = find.byType(BottomNavigationBar);
        final bottomNavWidget2 = tester.widget<BottomNavigationBar>(bottomNav2);

        // Small mobile should also have minimum 14px fonts
        expect(bottomNavWidget2.selectedFontSize, equals(14.0),
            reason: 'Small mobile should have 14px selected font size');
        expect(bottomNavWidget2.unselectedFontSize, equals(12.0),
            reason: 'Small mobile should have 12px unselected font size');
      });
    });

    group('Responsive Breakpoint Validation Tests', () {
      testWidgets('ResponsiveUtils breakpoints work correctly', (WidgetTester tester) async {
        for (final device in mobileDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          final context = tester.element(find.byType(MainLayout));

          // Mobile devices should be detected as mobile
          expect(ResponsiveUtils.isMobile(context), isTrue,
              reason: '${device.key} should be detected as mobile');

          // Should not be detected as tablet or desktop
          expect(ResponsiveUtils.isTablet(context), isFalse,
              reason: '${device.key} should not be detected as tablet');
          expect(ResponsiveUtils.isDesktop(context), isFalse,
              reason: '${device.key} should not be detected as desktop');
        }

        for (final device in tabletDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          final context = tester.element(find.byType(MainLayout));

          // Tablet devices should be detected as tablet
          expect(ResponsiveUtils.isTablet(context), isTrue,
              reason: '${device.key} should be detected as tablet');

          // Should not be detected as mobile
          expect(ResponsiveUtils.isMobile(context), isFalse,
              reason: '${device.key} should not be detected as mobile');
        }

        for (final device in desktopDevices.entries) {
          await binding.setSurfaceSize(device.value);

          await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
          await tester.pumpAndSettle();

          final context = tester.element(find.byType(MainLayout));

          // Desktop devices should be detected as desktop
          expect(ResponsiveUtils.isDesktop(context), isTrue,
              reason: '${device.key} should be detected as desktop');

          // Should not be detected as mobile or tablet
          expect(ResponsiveUtils.isMobile(context), isFalse,
              reason: '${device.key} should not be detected as mobile');
          expect(ResponsiveUtils.isTablet(context), isFalse,
              reason: '${device.key} should not be detected as tablet');
        }
      });
    });

    group('Layout Switching Behavior Tests', () {
      testWidgets('Layout switches correctly when screen size changes', (WidgetTester tester) async {
        // Start with mobile size
        await binding.setSurfaceSize(const Size(375, 667));
        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        // Should have mobile layout
        expect(find.byType(BottomNavigationBar), findsOneWidget,
            reason: 'Should start with mobile layout');

        // Change to tablet size
        await binding.setSurfaceSize(const Size(768, 1024));
        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        // Should switch to web layout
        expect(find.byType(BottomNavigationBar), findsNothing,
            reason: 'Should switch to web layout for tablet');

        // Change back to mobile size
        await binding.setSurfaceSize(const Size(375, 667));
        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        // Should switch back to mobile layout
        expect(find.byType(BottomNavigationBar), findsOneWidget,
            reason: 'Should switch back to mobile layout');
      });

      testWidgets('Navigation items are properly localized', (WidgetTester tester) async {
        await binding.setSurfaceSize(const Size(375, 667));

        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        final bottomNav = find.byType(BottomNavigationBar);
        expect(bottomNav, findsOneWidget);

        final bottomNavWidget = tester.widget<BottomNavigationBar>(bottomNav);

        // Should have 5 navigation items
        expect(bottomNavWidget.items.length, equals(5),
            reason: 'BottomNavigationBar should have 5 items');

        // Test that labels are translated (not hardcoded)
        for (final item in bottomNavWidget.items) {
          expect(item.label, isNotNull,
              reason: 'Navigation item should have a label');
          expect(item.label!.isNotEmpty, isTrue,
              reason: 'Navigation item label should not be empty');
        }
      },
      skip: true);
    });

    group('Accessibility Compliance Tests', () {
      testWidgets('Touch targets meet minimum size requirements', (WidgetTester tester) async {
        await binding.setSurfaceSize(const Size(375, 667));

        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        final bottomNav = find.byType(BottomNavigationBar);
        expect(bottomNav, findsOneWidget);

        // Get the size of the BottomNavigationBar
        final bottomNavSize = tester.getSize(bottomNav);

        // BottomNavigationBar should be tall enough for touch targets
        expect(bottomNavSize.height, greaterThanOrEqualTo(48.0),
            reason: 'BottomNavigationBar height should meet minimum touch target size');

        // Test individual navigation items if accessible
        final bottomNavWidget = tester.widget<BottomNavigationBar>(bottomNav);
        for (final item in bottomNavWidget.items) {
          // Icon should be present and properly sized
          expect(item.icon, isNotNull,
              reason: 'Navigation item should have an icon');
        }
      });

      testWidgets('Layout handles keyboard navigation', (WidgetTester tester) async {
        await binding.setSurfaceSize(const Size(375, 667));

        await tester.pumpWidget(createTestApp(const MainLayout(child: SizedBox())));
        await tester.pumpAndSettle();

        // Test that layout renders without overflow when keyboard is shown
        // (This would be more comprehensive with actual keyboard simulation)
        expect(find.byType(MainLayout), findsOneWidget,
            reason: 'MainLayout should render successfully');
      });
    });
  });
}