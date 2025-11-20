import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/constants/responsive_constants.dart';

void main() {
  group('ResponsiveConstants', () {
    test('spacing map contains expected values', () {
      expect(ResponsiveConstants.spacing['xs'], 4.0);
      expect(ResponsiveConstants.spacing['sm'], 8.0);
      expect(ResponsiveConstants.spacing['md'], 12.0);
      expect(ResponsiveConstants.spacing['lg'], 16.0);
      expect(ResponsiveConstants.spacing['xl'], 24.0);
      expect(ResponsiveConstants.spacing['2xl'], 32.0);
      expect(ResponsiveConstants.spacing['3xl'], 48.0);
      expect(ResponsiveConstants.spacing['4xl'], 64.0);
    });

    test('padding map contains expected values', () {
      expect(ResponsiveConstants.padding['none'], EdgeInsets.zero);
      expect(ResponsiveConstants.padding['xs'], const EdgeInsets.all(4.0));
      expect(ResponsiveConstants.padding['sm'], const EdgeInsets.all(8.0));
      expect(ResponsiveConstants.padding['md'], const EdgeInsets.all(12.0));
      expect(ResponsiveConstants.padding['lg'], const EdgeInsets.all(16.0));
      expect(ResponsiveConstants.padding['xl'], const EdgeInsets.all(24.0));
      expect(ResponsiveConstants.padding['2xl'], const EdgeInsets.all(32.0));
    });

    test('component spacing map contains expected values', () {
      expect(ResponsiveConstants.componentSpacing['buttonPaddingHorizontal'], 16.0);
      expect(ResponsiveConstants.componentSpacing['cardPadding'], 16.0);
      expect(ResponsiveConstants.componentSpacing['formFieldGap'], 16.0);
      expect(ResponsiveConstants.componentSpacing['listItemGap'], 8.0);
    });

    test('utility methods work correctly', () {
      expect(ResponsiveConstants.spacingValue('md'), 12.0);
      expect(ResponsiveConstants.paddingValue('lg'), const EdgeInsets.all(16.0));
      expect(ResponsiveConstants.componentSpacingValue('cardPadding'), 16.0);

      expect(ResponsiveConstants.hasSpacing('xs'), true);
      expect(ResponsiveConstants.hasSpacing('invalid'), false);
      expect(ResponsiveConstants.hasPadding('sm'), true);
      expect(ResponsiveConstants.hasPadding('invalid'), false);
      expect(ResponsiveConstants.hasComponentSpacing('buttonPaddingHorizontal'), true);
      expect(ResponsiveConstants.hasComponentSpacing('invalid'), false);
    });

    test('available sizes lists are correct', () {
      expect(ResponsiveConstants.availableSpacingSizes.length, greaterThan(0));
      expect(ResponsiveConstants.availablePaddingSizes.length, greaterThan(0));
      expect(ResponsiveConstants.availableComponentSpacing.length, greaterThan(0));

      expect(ResponsiveConstants.availableSpacingSizes.contains('xs'), true);
      expect(ResponsiveConstants.availablePaddingSizes.contains('sm'), true);
      expect(ResponsiveConstants.availableComponentSpacing.contains('cardPadding'), true);
    });

    testWidgets('responsive methods throw on invalid keys', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final context = tester.element(find.byType(Scaffold));

      expect(() => ResponsiveConstants.getResponsiveSpacing(context, 'invalid'), throwsArgumentError);
      expect(() => ResponsiveConstants.getResponsivePadding(context, 'invalid'), throwsArgumentError);
      expect(() => ResponsiveConstants.getComponentSpacing(context, 'invalid'), throwsArgumentError);
      expect(() => ResponsiveConstants.getScreenPadding(context, 'invalid'), throwsArgumentError);
    });

    testWidgets('utility methods throw on invalid keys', (WidgetTester tester) async {
      expect(() => ResponsiveConstants.spacingValue('invalid'), throwsArgumentError);
      expect(() => ResponsiveConstants.paddingValue('invalid'), throwsArgumentError);
      expect(() => ResponsiveConstants.componentSpacingValue('invalid'), throwsArgumentError);
    });
  });
}