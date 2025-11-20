import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Device configuration utilities for comprehensive testing
/// Based on PROJECT_ISSUES_ANALYSIS.md requirements

class DeviceConfig {
  final String name;
  final Size size;
  final String category;
  final bool supportsLandscape;

  const DeviceConfig({
    required this.name,
    required this.size,
    required this.category,
    this.supportsLandscape = true,
  });

  Size get landscapeSize => Size(size.height, size.width);

  @override
  String toString() => '$name (${size.width}x${size.height}) - $category';
}

class TestDeviceConfigs {
  // Mobile devices as specified in PROJECT_ISSUES_ANALYSIS.md
  static const List<DeviceConfig> mobileDevices = [
    DeviceConfig(
      name: 'iPhone SE',
      size: Size(375, 667),
      category: 'Small Mobile',
    ),
    DeviceConfig(
      name: 'iPhone 14 Pro',
      size: Size(393, 852),
      category: 'Modern Mobile',
    ),
  ];

  // Tablet devices
  static const List<DeviceConfig> tabletDevices = [
    DeviceConfig(
      name: 'iPad',
      size: Size(768, 1024),
      category: 'Standard Tablet',
    ),
    DeviceConfig(
      name: 'iPad Pro',
      size: Size(1024, 1366),
      category: 'Large Tablet',
    ),
  ];

  // Desktop devices
  static const List<DeviceConfig> desktopDevices = [
    DeviceConfig(
      name: 'Desktop',
      size: Size(1920, 1080),
      category: 'Standard Desktop',
    ),
    DeviceConfig(
      name: 'Ultra-wide',
      size: Size(2560, 1440),
      category: 'Large Desktop',
    ),
  ];

  // All devices combined
  static List<DeviceConfig> get allDevices => [
    ...mobileDevices,
    ...tabletDevices,
    ...desktopDevices,
  ];

  // Language configurations
  static const List<String> supportedLanguages = ['en', 'fr', 'ar'];

  // Test scenarios
  static const List<String> testScenarios = [
    'responsive_behavior',
    'landscape_mode',
    'translation_coverage',
    'rtl_support',
    'touch_targets',
    'web_features',
    'text_truncation',
  ];
}

extension DeviceConfigTesting on WidgetTester {
  /// Test a widget on multiple device configurations
  Future<void> testOnDevices(
    List<DeviceConfig> devices,
    Widget Function() widgetBuilder,
    void Function(DeviceConfig device, WidgetTester tester) testFunction,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();

    for (final device in devices) {
      testWidgets('Testing on ${device.name}', (WidgetTester tester) async {
        await binding.setSurfaceSize(device.size);

        await tester.pumpWidget(widgetBuilder());
        await tester.pumpAndSettle();

        testFunction(device, tester);

        await binding.setSurfaceSize(null);
      });
    }
  }

  /// Test landscape mode for devices
  Future<void> testLandscapeOnDevices(
    List<DeviceConfig> devices,
    Widget Function() widgetBuilder,
    void Function(DeviceConfig device, WidgetTester tester) testFunction,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();

    for (final device in devices.where((d) => d.supportsLandscape)) {
      testWidgets('Testing ${device.name} in Landscape', (WidgetTester tester) async {
        await binding.setSurfaceSize(device.landscapeSize);

        await tester.pumpWidget(widgetBuilder());
        await tester.pumpAndSettle();

        testFunction(device, tester);

        await binding.setSurfaceSize(null);
      });
    }
  }
}

/// Test results collector for comprehensive reporting
class TestResultsCollector {
  final Map<String, TestResult> results = {};

  void recordResult(String testName, bool passed, {String? details, dynamic error}) {
    results[testName] = TestResult(
      testName: testName,
      passed: passed,
      details: details,
      error: error,
      timestamp: DateTime.now(),
    );
  }

  void recordDeviceTest(String deviceName, String scenario, bool passed, {String? details}) {
    final testName = '${deviceName}_$scenario';
    recordResult(testName, passed, details: details);
  }

  void recordLanguageTest(String language, String scenario, bool passed, {String? details}) {
    final testName = '${language}_$scenario';
    recordResult(testName, passed, details: details);
  }

  Map<String, dynamic> generateReport() {
    final passed = results.values.where((r) => r.passed).length;
    final failed = results.values.where((r) => !r.passed).length;
    final total = results.length;

    return {
      'summary': {
        'total_tests': total,
        'passed': passed,
        'failed': failed,
        'success_rate': total > 0 ? (passed / total * 100).round() : 0,
      },
      'results': results.map((key, value) => MapEntry(key, value.toJson())),
      'timestamp': DateTime.now().toIso8601String(),
      'test_categories': _categorizeResults(),
    };
  }

  Map<String, List<String>> _categorizeResults() {
    final categories = <String, List<String>>{};

    for (final result in results.entries) {
      final category = _extractCategory(result.key);
      categories.putIfAbsent(category, () => []).add(result.key);
    }

    return categories;
  }

  String _extractCategory(String testName) {
    if (testName.contains('responsive')) return 'responsive';
    if (testName.contains('landscape')) return 'landscape';
    if (testName.contains('translation')) return 'translation';
    if (testName.contains('rtl')) return 'rtl';
    if (testName.contains('touch')) return 'accessibility';
    if (testName.contains('web')) return 'web';
    if (testName.contains('truncation')) return 'text';
    return 'other';
  }
}

class TestResult {
  final String testName;
  final bool passed;
  final String? details;
  final dynamic error;
  final DateTime timestamp;

  TestResult({
    required this.testName,
    required this.passed,
    this.details,
    this.error,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'test_name': testName,
    'passed': passed,
    'details': details,
    'error': error?.toString(),
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Utility for checking touch target sizes
class TouchTargetAuditor {
  static bool isValidTouchTarget(Size size) {
    return size.width >= 48.0 && size.height >= 48.0;
  }

  static String getTouchTargetIssue(Size size) {
    final issues = <String>[];
    if (size.width < 48.0) issues.add('Width ${size.width} < 48dp');
    if (size.height < 48.0) issues.add('Height ${size.height} < 48dp');
    return issues.join(', ');
  }
}

/// Utility for RTL testing
class RTLTestHelper {
  static bool isRTLLayout(BuildContext context) {
    final directionality = context.findAncestorWidgetOfExactType<Directionality>();
    return directionality?.textDirection == TextDirection.rtl;
  }

  static bool isLTRLayout(BuildContext context) {
    final directionality = context.findAncestorWidgetOfExactType<Directionality>();
    return directionality?.textDirection == TextDirection.ltr;
  }
}