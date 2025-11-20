import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accessibility Touch Target Utilities
///
/// This utility provides comprehensive touch target auditing and accessibility
/// compliance checking for Flutter applications. It supports multiple
/// accessibility standards and provides automated suggestions for fixes.
///
/// ## Features
/// - Configurable accessibility standards (WCAG, Android, iOS)
/// - Automated touch target measurement and validation
/// - Detailed reporting with suggestions for fixes
/// - Integration with Flutter testing framework
/// - Support for various interactive widget types
///
/// ## Usage Example
/// ```dart
/// final auditor = TouchTargetAuditor(
///   standard: AccessibilityStandard.wcag,
/// );
///
/// // Audit a specific widget
/// auditor.auditElement('Button', const Size(40, 40));
///
/// // Get suggestions for fixes
/// final suggestions = auditor.getFixSuggestions();
/// ```
class TouchTargetAuditor {
  /// Supported accessibility standards with their minimum touch target sizes
  static const Map<AccessibilityStandard, Size> _standardSizes = {
    AccessibilityStandard.wcag: Size(48.0, 48.0), // WCAG 2.1 AA
    AccessibilityStandard.android: Size(48.0, 48.0), // Android Material Design
    AccessibilityStandard.ios: Size(44.0, 44.0), // iOS Human Interface Guidelines
    AccessibilityStandard.custom: Size(48.0, 48.0), // Default fallback
  };

  final AccessibilityStandard standard;
  final List<TouchTargetResult> results = [];
  final List<String> measurementErrors = [];
  final List<AccessibilitySuggestion> suggestions = [];

  TouchTargetAuditor({
    this.standard = AccessibilityStandard.wcag,
  });

  /// Get the minimum touch target size for the current standard
  Size get minTouchTargetSize => _standardSizes[standard]!;

  /// Audit a single element for touch target compliance
  void auditElement(String type, Size size, {String? key, String? context}) {
    final isValid = _validateSize(size);
    String? issue;
    AccessibilitySuggestion? suggestion;

    if (!isValid) {
      final issues = <String>[];
      final minSize = minTouchTargetSize;

      if (size.width < minSize.width) {
        issues.add('Width ${size.width.round()}dp < ${minSize.width.round()}dp');
      }
      if (size.height < minSize.height) {
        issues.add('Height ${size.height.round()}dp < ${minSize.height.round()}dp');
      }
      issue = issues.join(', ');

      // Generate suggestion for fix
      suggestion = _generateSuggestion(type, size, context);
    }

    final result = TouchTargetResult(
      elementType: type,
      elementKey: key,
      size: size,
      isValid: isValid,
      issue: issue,
      standard: standard,
      context: context,
    );

    results.add(result);

    if (suggestion != null) {
      suggestions.add(suggestion);
    }
  }

  /// Safely measure widget size with comprehensive error handling and retry logic
  void safeMeasureElement(
    WidgetTester tester,
    Element element,
    String elementType, {
    String? key,
    String? context,
    int maxRetries = 3,
  }) {
    const Duration retryDelay = Duration(milliseconds: 100);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final renderObject = element.renderObject;
        if (renderObject == null) {
          if (attempt < maxRetries) {
            tester.pump(retryDelay);
            continue;
          }
          final errorMsg = 'Failed to measure $elementType: renderObject is null after $maxRetries attempts';
          measurementErrors.add(errorMsg);
          debugPrint('⚠️ $errorMsg');
          return;
        }

        if (renderObject is! RenderBox) {
          final errorMsg = 'Failed to measure $elementType: renderObject is not a RenderBox (type: ${renderObject.runtimeType})';
          measurementErrors.add(errorMsg);
          debugPrint('⚠️ $errorMsg');
          return;
        }

        final size = renderObject.size;
        if (size.width.isNaN || size.height.isNaN || size.width.isInfinite || size.height.isInfinite) {
          if (attempt < maxRetries) {
            tester.pump(retryDelay);
            continue;
          }
          final errorMsg = 'Failed to measure $elementType: invalid size values after $maxRetries attempts (width: ${size.width}, height: ${size.height})';
          measurementErrors.add(errorMsg);
          debugPrint('⚠️ $errorMsg');
          return;
        }

        auditElement(elementType, size, key: key, context: context);
        return;
      } catch (e, stackTrace) {
        if (attempt < maxRetries) {
          tester.pump(retryDelay);
          continue;
        }
        final errorMsg = 'Failed to measure $elementType after $maxRetries attempts: $e\nStack trace: $stackTrace';
        measurementErrors.add(errorMsg);
        debugPrint('⚠️ $errorMsg');
        return;
      }
    }
  }

  /// Audit multiple elements of the same type
  void auditElements(
    WidgetTester tester,
    Finder finder,
    String elementType, {
    String? context,
  }) {
    for (final element in finder.evaluate()) {
      safeMeasureElement(
        tester,
        element,
        elementType,
        key: element.widget.key?.toString(),
        context: context,
      );
    }
  }

  /// Get all failed results
  List<TouchTargetResult> get failedResults =>
      results.where((r) => !r.isValid).toList();

  /// Get all passed results
  List<TouchTargetResult> get passedResults =>
      results.where((r) => r.isValid).toList();

  /// Get critical failures (elements significantly below minimum)
  List<TouchTargetResult> get criticalFailures {
    final minSize = minTouchTargetSize;
    final criticalThreshold = Size(minSize.width - 4, minSize.height - 4);
    return failedResults.where((r) =>
        r.size.width < criticalThreshold.width ||
        r.size.height < criticalThreshold.height).toList();
  }

  /// Generate comprehensive audit report
  Map<String, dynamic> generateReport() {
    final totalElements = results.length;
    final passed = passedResults.length;
    final failed = failedResults.length;
    final critical = criticalFailures.length;

    return {
      'standard': standard.name,
      'min_touch_target': {
        'width': minTouchTargetSize.width.round(),
        'height': minTouchTargetSize.height.round(),
      },
      'summary': {
        'total_elements': totalElements,
        'passed': passed,
        'failed': failed,
        'critical_failures': critical,
        'measurement_errors': measurementErrors.length,
        'success_rate': totalElements > 0 ? (passed / totalElements * 100).round() : 0,
      },
      'results': {
        'passed_elements': passedResults.map((r) => r.toMap()).toList(),
        'failed_elements': failedResults.map((r) => r.toMap()).toList(),
        'critical_failures': criticalFailures.map((r) => r.toMap()).toList(),
      },
      'issues': {
        'measurement_errors': measurementErrors,
        'suggestions': suggestions.map((s) => s.toMap()).toList(),
      },
      'recommendations': _generateRecommendations(),
    };
  }

  /// Get all fix suggestions
  List<AccessibilitySuggestion> getFixSuggestions() => suggestions;

  /// Apply automated fixes to improve touch targets
  List<Widget> applyAutomatedFixes(List<Widget> widgets) {
    // This would be implemented to automatically wrap widgets with proper touch targets
    // For now, return the original widgets with suggestions
    return widgets;
  }

  bool _validateSize(Size size) {
    final minSize = minTouchTargetSize;
    return size.width >= minSize.width && size.height >= minSize.height;
  }

  AccessibilitySuggestion _generateSuggestion(String type, Size currentSize, String? context) {
    final minSize = minTouchTargetSize;
    final widthDiff = minSize.width - currentSize.width;
    final heightDiff = minSize.height - currentSize.height;

    final fixes = <String>[];

    if (widthDiff > 0) {
      fixes.add('Increase width by ${widthDiff.round()}dp (to ${minSize.width.round()}dp minimum)');
    }
    if (heightDiff > 0) {
      fixes.add('Increase height by ${heightDiff.round()}dp (to ${minSize.height.round()}dp minimum)');
    }

    String codeExample = _generateCodeExample(type, minSize);

    return AccessibilitySuggestion(
      elementType: type,
      currentSize: currentSize,
      recommendedSize: minSize,
      fixes: fixes,
      codeExample: codeExample,
      priority: _calculatePriority(currentSize),
      context: context,
    );
  }

  /// Validate touch target for a specific standard
  bool validateForStandard(Size size, AccessibilityStandard standard) {
    final minSize = _standardSizes[standard]!;
    return size.width >= minSize.width && size.height >= minSize.height;
  }

  /// Get compliance status for all audited elements
  Map<AccessibilityStandard, int> getComplianceByStandard() {
    final compliance = <AccessibilityStandard, int>{};

    for (final standard in AccessibilityStandard.values) {
      final validCount = results.where((r) => validateForStandard(r.size, standard)).length;
      compliance[standard] = validCount;
    }

    return compliance;
  }

  /// Export results in different formats
  String exportAsJson() => '''
{
  "audit_report": ${generateReport()},
  "exported_at": "${DateTime.now().toIso8601String()}",
  "version": "1.0.0"
}
''';

  String exportAsMarkdown() {
    final report = generateReport();
    final summary = report['summary'] as Map<String, dynamic>;

    return '''
# Touch Target Accessibility Audit Report

**Standard:** ${report['standard']}
**Minimum Touch Target:** ${report['min_touch_target']['width']}×${report['min_touch_target']['height']}dp
**Generated:** ${DateTime.now().toIso8601String()}

## Summary

- **Total Elements:** ${summary['total_elements']}
- **Passed:** ${summary['passed']}
- **Failed:** ${summary['failed']}
- **Critical Failures:** ${summary['critical_failures']}
- **Success Rate:** ${summary['success_rate']}%

## Failed Elements

${failedResults.map((r) => '- ❌ $r').join('\n')}

## Recommendations

${(report['recommendations'] as List<String>).map((r) => '- $r').join('\n')}

## Fix Suggestions

${suggestions.map((s) => '''
### ${s.elementType}
**Priority:** ${s.priority.name}
**Current Size:** ${s.currentSize.width.round()}×${s.currentSize.height.round()}dp
**Recommended Size:** ${s.recommendedSize.width.round()}×${s.recommendedSize.height.round()}dp

**Fixes:**
${s.fixes.map((f) => '- $f').join('\n')}

**Code Example:**
```dart
${s.codeExample}
```
''').join('\n')}
''';
  }
  
    String _generateCodeExample(String type, Size minSize) {
    switch (type.toLowerCase()) {
      case 'elevatedbutton':
        return '''
// Fix: Add minimumSize to ElevatedButton style
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(${minSize.width}, ${minSize.height}),
  ),
  onPressed: () {},
  child: Text('Button'),
)
''';
      case 'textbutton':
        return '''
// Fix: Add minimumSize to TextButton style
TextButton(
  style: TextButton.styleFrom(
    minimumSize: Size(${minSize.width}, ${minSize.height}),
  ),
  onPressed: () {},
  child: Text('Button'),
)
''';
      case 'outlinedbutton':
        return '''
// Fix: Add minimumSize to OutlinedButton style
OutlinedButton(
  style: OutlinedButton.styleFrom(
    minimumSize: Size(${minSize.width}, ${minSize.height}),
  ),
  onPressed: () {},
  child: Text('Button'),
)
''';
      case 'iconbutton':
        return '''
// Fix: Wrap in Container with minimum constraints
Container(
  constraints: BoxConstraints(
    minWidth: ${minSize.width},
    minHeight: ${minSize.height},
  ),
  child: IconButton(
    onPressed: () {},
    icon: Icon(Icons.add),
  ),
)
''';
      case 'floatingactionbutton':
        return '''
// FABs typically meet requirements, but ensure proper sizing
FloatingActionButton(
  onPressed: () {},
  child: Icon(Icons.add),
  // Default size is usually 56x56, which meets requirements
)
''';
      default:
        return '''
// Fix: Wrap in Container with minimum touch target
Container(
  constraints: BoxConstraints(
    minWidth: ${minSize.width},
    minHeight: ${minSize.height},
  ),
  child: YourWidget(),
)
''';
    }
  }

  SuggestionPriority _calculatePriority(Size currentSize) {
    final minSize = minTouchTargetSize;
    final widthRatio = currentSize.width / minSize.width;
    final heightRatio = currentSize.height / minSize.height;
    final minRatio = widthRatio < heightRatio ? widthRatio : heightRatio;

    if (minRatio < 0.8) return SuggestionPriority.critical;
    if (minRatio < 0.9) return SuggestionPriority.high;
    return SuggestionPriority.medium;
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    final criticalFailures = this.criticalFailures;
    final failedResults = this.failedResults;
    final measurementErrors = this.measurementErrors;

    if (criticalFailures.isNotEmpty) {
      recommendations.add('Address ${criticalFailures.length} critical touch target failures immediately');
    }

    if (failedResults.isNotEmpty) {
      recommendations.add('Review ${failedResults.length} elements that fail touch target requirements');
    }

    if (measurementErrors.isNotEmpty) {
      recommendations.add('Investigate ${measurementErrors.length} measurement errors - may indicate rendering issues');
    }

    recommendations.add('Consider using the provided code examples to fix touch target issues');
    recommendations.add('Test on actual devices to ensure touch targets work in practice');

    return recommendations;
  }
}

/// Result of a touch target audit for a single element
class TouchTargetResult {
  final String elementType;
  final String? elementKey;
  final Size size;
  final bool isValid;
  final String? issue;
  final AccessibilityStandard standard;
  final String? context;

  TouchTargetResult({
    required this.elementType,
    this.elementKey,
    required this.size,
    required this.isValid,
    this.issue,
    required this.standard,
    this.context,
  });

  @override
  String toString() {
    final keyStr = elementKey != null ? ' ($elementKey)' : '';
    final contextStr = context != null ? ' [$context]' : '';
    final status = isValid ? 'PASS' : 'FAIL: $issue';
    return '$elementType$keyStr$contextStr: ${size.width.round()}x${size.height.round()} - $status';
  }

  Map<String, dynamic> toMap() {
    return {
      'element_type': elementType,
      'element_key': elementKey,
      'size': {
        'width': size.width.round(),
        'height': size.height.round(),
      },
      'is_valid': isValid,
      'issue': issue,
      'standard': standard.name,
      'context': context,
    };
  }
}

/// Suggestion for fixing accessibility issues
class AccessibilitySuggestion {
  final String elementType;
  final Size currentSize;
  final Size recommendedSize;
  final List<String> fixes;
  final String codeExample;
  final SuggestionPriority priority;
  final String? context;

  AccessibilitySuggestion({
    required this.elementType,
    required this.currentSize,
    required this.recommendedSize,
    required this.fixes,
    required this.codeExample,
    required this.priority,
    this.context,
  });

  Map<String, dynamic> toMap() {
    return {
      'element_type': elementType,
      'current_size': {
        'width': currentSize.width.round(),
        'height': currentSize.height.round(),
      },
      'recommended_size': {
        'width': recommendedSize.width.round(),
        'height': recommendedSize.height.round(),
      },
      'fixes': fixes,
      'code_example': codeExample,
      'priority': priority.name,
      'context': context,
    };
  }
}

/// Priority levels for accessibility suggestions
enum SuggestionPriority {
  low,
  medium,
  high,
  critical,
}

/// Supported accessibility standards
enum AccessibilityStandard {
  wcag, // Web Content Accessibility Guidelines
  android, // Android Material Design
  ios, // iOS Human Interface Guidelines
  custom, // Custom requirements
}

/// Additional accessibility testing utilities
class AccessibilityTestUtils {
  /// Test color contrast ratios
  static bool testColorContrast(Color foreground, Color background, {double minRatio = 4.5}) {
    // Implementation would calculate contrast ratio
    return true; // Placeholder
  }

  /// Test text readability
  static bool testTextReadability(String text, double fontSize, {double minSize = 14.0}) {
    return fontSize >= minSize;
  }

  /// Test semantic labeling
  static bool testSemanticLabel(String? label, String elementType) {
    return label != null && label.isNotEmpty;
  }

  /// Generate accessibility report for a screen
  static Map<String, dynamic> generateScreenReport(
    BuildContext context, {
    required String screenName,
  }) {
    // Implementation would analyze the entire screen
    return {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
      'issues': <String>[],
      'recommendations': <String>[],
    };
  }
}

/// Extension methods for easier integration
extension TouchTargetAuditorExtensions on TouchTargetAuditor {
  /// Audit common Flutter widgets
  void auditCommonWidgets(WidgetTester tester) {
    // Audit buttons
    auditElements(tester, find.byType(ElevatedButton), 'ElevatedButton');
    auditElements(tester, find.byType(TextButton), 'TextButton');
    auditElements(tester, find.byType(OutlinedButton), 'OutlinedButton');
    auditElements(tester, find.byType(IconButton), 'IconButton');
    auditElements(tester, find.byType(FloatingActionButton), 'FloatingActionButton');

    // Audit interactive elements
    auditElements(tester, find.byType(GestureDetector), 'GestureDetector');
    auditElements(tester, find.byType(InkWell), 'InkWell');
  }

  /// Print formatted audit results
  void printResults() {
    final report = generateReport();

    debugPrint('=== Touch Target Audit Results ===');
    debugPrint('Standard: ${report['standard']}');
    debugPrint('Minimum Size: ${report['min_touch_target']['width']}x${report['min_touch_target']['height']}dp');
    debugPrint('');

    final summary = report['summary'] as Map<String, dynamic>;
    debugPrint('Summary:');
    debugPrint('  Total Elements: ${summary['total_elements']}');
    debugPrint('  Passed: ${summary['passed']}');
    debugPrint('  Failed: ${summary['failed']}');
    debugPrint('  Critical Failures: ${summary['critical_failures']}');
    debugPrint('  Success Rate: ${summary['success_rate']}%');
    debugPrint('');

    if (failedResults.isNotEmpty) {
      debugPrint('Failed Elements:');
      for (final result in failedResults) {
        debugPrint('  ❌ $result');
      }
      debugPrint('');
    }

    if (suggestions.isNotEmpty) {
      debugPrint('Fix Suggestions:');
      for (final suggestion in suggestions) {
        debugPrint('  💡 ${suggestion.elementType}: ${suggestion.fixes.join(', ')}');
      }
      debugPrint('');
    }

    final recommendations = report['recommendations'] as List<String>;
    if (recommendations.isNotEmpty) {
      debugPrint('Recommendations:');
      for (final rec in recommendations) {
        debugPrint('  • $rec');
      }
    }
  }
}
