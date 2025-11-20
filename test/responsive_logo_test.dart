import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nlaabo/widgets/responsive_logo.dart';
import 'package:nlaabo/utils/icon_validator.dart';

void main() {
  group('ResponsiveLogo Widget Tests', () {
    testWidgets('ResponsiveLogo renders with default parameters', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLogo(),
          ),
        ),
      );

      // Check if the widget renders without errors
      expect(find.byType(ResponsiveLogo), findsOneWidget);
    });

    testWidgets('ResponsiveLogo adapts to screen width', (WidgetTester tester) async {
      // Test with different screen sizes
      const smallScreenSize = Size(320, 568); // iPhone SE size
      const largeScreenSize = Size(1024, 768); // iPad size

      // Test small screen
      await tester.binding.setSurfaceSize(smallScreenSize);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLogo(maxWidth: 200),
          ),
        ),
      );

      final smallScreenLogo = find.byType(ResponsiveLogo);
      expect(smallScreenLogo, findsOneWidget);

      // Test large screen
      await tester.binding.setSurfaceSize(largeScreenSize);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLogo(maxWidth: 200),
          ),
        ),
      );

      final largeScreenLogo = find.byType(ResponsiveLogo);
      expect(largeScreenLogo, findsOneWidget);
    });

    testWidgets('ResponsiveLogo shows error placeholder when asset fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLogo(
              assetPath: 'non_existent_asset.png', // This should fail
            ),
          ),
        ),
      );

      // Wait for error to be handled
      await tester.pump(const Duration(milliseconds: 100));

      // Check if error placeholder is shown
      expect(find.byIcon(Icons.broken_image), findsOneWidget);
    });

    testWidgets('ResponsiveLogo respects maxWidth and maxHeight constraints', (WidgetTester tester) async {
      const maxWidth = 150.0;
      const maxHeight = 50.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResponsiveLogo(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
            ),
          ),
        ),
      );

      final logoFinder = find.byType(ResponsiveLogo);
      expect(logoFinder, findsOneWidget);

      // The widget should be constrained by the max dimensions
      final logoWidget = tester.widget<ResponsiveLogo>(logoFinder);
      expect(logoWidget.maxWidth, equals(maxWidth));
      expect(logoWidget.maxHeight, equals(maxHeight));
    });
  });

  group('LogoAssets Utility Tests', () {
    test('LogoAssets provides correct asset paths', () {
      expect(LogoAssets.logo, equals('assets/icons/logo.png'));
      expect(LogoAssets.logo16, equals('assets/icons/logo_16.png'));
      expect(LogoAssets.logo32, equals('assets/icons/logo_32.png'));
      expect(LogoAssets.logo64, equals('assets/icons/logo_64.png'));
      expect(LogoAssets.logo128, equals('assets/icons/logo_128.png'));
      expect(LogoAssets.logo256, equals('assets/icons/logo_256.png'));
      expect(LogoAssets.logo512, equals('assets/icons/logo_512.png'));
      expect(LogoAssets.logo1024, equals('assets/icons/logo_1024.png'));
    });

    test('getLogoForWidth returns appropriate size', () {
      expect(LogoAssets.getLogoForWidth(10), equals('assets/icons/logo_16.png'));
      expect(LogoAssets.getLogoForWidth(20), equals('assets/icons/logo_32.png'));
      expect(LogoAssets.getLogoForWidth(50), equals('assets/icons/logo_64.png'));
      expect(LogoAssets.getLogoForWidth(100), equals('assets/icons/logo_128.png'));
      expect(LogoAssets.getLogoForWidth(200), equals('assets/icons/logo_256.png'));
      expect(LogoAssets.getLogoForWidth(400), equals('assets/icons/logo_512.png'));
      expect(LogoAssets.getLogoForWidth(800), equals('assets/icons/logo_1024.png'));
    });
  });

  group('IconValidator Tests', () {
    test('IconValidator has correct required sizes', () {
      expect(IconValidator.requiredSizes, equals([16, 32, 64, 128, 256, 512, 1024]));
    });

    test('getOptimalIconPath returns correct paths', () {
      expect(IconValidator.getOptimalIconPath(10), equals('assets/icons/logo_16.png'));
      expect(IconValidator.getOptimalIconPath(30), equals('assets/icons/logo_32.png'));
      expect(IconValidator.getOptimalIconPath(100), equals('assets/icons/logo_128.png'));
      expect(IconValidator.getOptimalIconPath(300), equals('assets/icons/logo_512.png'));
      expect(IconValidator.getOptimalIconPath(1000), equals('assets/icons/logo_1024.png'));
    });
  });
}