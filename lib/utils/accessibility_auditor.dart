import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'accessibility_utils.dart';

/// Automated accessibility auditing tool for Flutter applications
class AccessibilityAuditor {
  static const String _reportFileName = 'accessibility_report.json';

  /// Comprehensive accessibility audit results
  final List<AccessibilityIssue> issues = [];
  final List<AccessibilityViolation> violations = [];
  final Map<String, dynamic> auditMetadata = {};

  /// Calculate contrast ratio between two colors
  static double _calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _calculateLuminance(color1);
    final luminance2 = _calculateLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calculate relative luminance of a color
  static double _calculateLuminance(Color color) {
    final r = color.r;
    final g = color.g;
    final b = color.b;

    final rLinear = r <= 0.03928 ? r / 12.92 : pow((r + 0.055) / 1.055, 2.4);
    final gLinear = g <= 0.03928 ? g / 12.92 : pow((g + 0.055) / 1.055, 2.4);
    final bLinear = b <= 0.03928 ? b / 12.92 : pow((b + 0.055) / 1.055, 2.4);

    return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
  }

  /// Run complete accessibility audit on the application
  static Future<AccessibilityAuditResult> runAudit({
    required WidgetTester tester,
    required BuildContext context,
    bool includePerformanceMetrics = true,
    bool includeSemanticAnalysis = true,
  }) async {
    final auditor = AccessibilityAuditor();
    await auditor._performAudit(tester, context, includePerformanceMetrics, includeSemanticAnalysis);
    return auditor._generateReport();
  }

  /// Perform the actual audit
  Future<void> _performAudit(
    WidgetTester tester,
    BuildContext context,
    bool includePerformanceMetrics,
    bool includeSemanticAnalysis,
  ) async {
    auditMetadata['timestamp'] = DateTime.now().toIso8601String();
    auditMetadata['flutter_version'] = '3.9.2';
    auditMetadata['platform'] = Platform.operatingSystem;

    // Audit color contrast
    await _auditColorContrast(tester, context);

    // Audit touch targets
    await _auditTouchTargets(tester);

    // Audit text accessibility
    await _auditTextAccessibility(tester);

    // Audit semantic elements
    if (includeSemanticAnalysis) {
      await _auditSemanticElements(tester);
    }

    // Audit keyboard navigation
    await _auditKeyboardNavigation(tester);

    // Audit screen reader support
    await _auditScreenReaderSupport(tester);

    // Performance metrics
    if (includePerformanceMetrics) {
      await _auditPerformanceMetrics(tester);
    }
  }

  /// Audit color contrast ratios
  Future<void> _auditColorContrast(WidgetTester tester, BuildContext context) async {
    final theme = Theme.of(context);

    // Check primary colors
    _checkContrastRatio(
      'Primary on Primary',
      theme.colorScheme.onPrimary,
      theme.colorScheme.primary,
    );

    // Check surface colors
    _checkContrastRatio(
      'On Surface on Surface',
      theme.colorScheme.onSurface,
      theme.colorScheme.surface,
    );

    // Check background colors
    _checkContrastRatio(
      'On Background on Background',
      theme.colorScheme.onSurface,
      theme.colorScheme.surface,
    );

    // Check error colors
    _checkContrastRatio(
      'On Error on Error',
      theme.colorScheme.onError,
      theme.colorScheme.error,
    );
  }

  /// Check contrast ratio and add issues if needed
  void _checkContrastRatio(String element, Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    final meetsAA = ratio >= 4.5;
    final meetsAAA = ratio >= 7.0;

    if (!meetsAA) {
      violations.add(AccessibilityViolation(
        severity: ViolationSeverity.critical,
        type: ViolationType.colorContrast,
        element: element,
        description: 'Contrast ratio $ratio:1 does not meet WCAG AA requirements (4.5:1)',
        recommendation: 'Increase contrast between foreground and background colors',
        wcagGuideline: '1.4.3 Contrast (Minimum)',
      ));
    } else if (!meetsAAA) {
      issues.add(AccessibilityIssue(
        severity: IssueSeverity.warning,
        type: IssueType.colorContrast,
        element: element,
        description: 'Contrast ratio $ratio:1 meets AA but not AAA requirements (7:1)',
        recommendation: 'Consider improving contrast for enhanced accessibility',
        wcagGuideline: '1.4.6 Contrast (Enhanced)',
      ));
    }
  }

  /// Audit touch target sizes
  Future<void> _auditTouchTargets(WidgetTester tester) async {
    // Find all interactive elements
    final buttons = find.byType(ElevatedButton);
    final textButtons = find.byType(TextButton);
    final iconButtons = find.byType(IconButton);
    final gestureDetectors = find.byType(GestureDetector);
    final inkWells = find.byType(InkWell);

    // Check button sizes
    await _checkWidgetSizes(tester, buttons, 'ElevatedButton');
    await _checkWidgetSizes(tester, textButtons, 'TextButton');
    await _checkWidgetSizes(tester, iconButtons, 'IconButton');
    await _checkWidgetSizes(tester, gestureDetectors, 'GestureDetector');
    await _checkWidgetSizes(tester, inkWells, 'InkWell');
  }

  /// Check sizes of widgets
  Future<void> _checkWidgetSizes(WidgetTester tester, Finder finder, String widgetType) async {
    final elements = tester.widgetList(finder);

    for (final element in elements) {
      if (element is ElevatedButton || element is TextButton || element is IconButton) {
        final renderBox = tester.renderObject(find.byWidget(element)) as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          if (!AccessibilityUtils.meetsMinimumTouchTarget(size)) {
            violations.add(AccessibilityViolation(
              severity: ViolationSeverity.major,
              type: ViolationType.touchTarget,
              element: '$widgetType at ${renderBox.localToGlobal(Offset.zero)}',
              description: 'Touch target size ${size.width.toInt()}x${size.height.toInt()} is below minimum 48x48dp',
              recommendation: 'Increase button size or add padding to meet minimum touch target requirements',
              wcagGuideline: '2.5.5 Target Size',
            ));
          }
        }
      }
    }
  }

  /// Audit text accessibility
  Future<void> _auditTextAccessibility(WidgetTester tester) async {
    final textWidgets = find.byType(Text);
    final textFields = find.byType(TextField);

    // Check text sizes
    final textElements = tester.widgetList<Text>(textWidgets);
    for (final textWidget in textElements) {
      final fontSize = textWidget.style?.fontSize ?? 14.0;
      if (!AccessibilityUtils.isAccessibleTextSize(fontSize)) {
        issues.add(AccessibilityIssue(
          severity: IssueSeverity.warning,
          type: IssueType.textSize,
          element: 'Text widget',
          description: 'Font size ${fontSize.toInt()}sp is below recommended minimum of 14sp',
          recommendation: 'Increase font size for better readability',
          wcagGuideline: '1.4.4 Resize text',
        ));
      }
    }

    // Check text field labels
    final textFieldElements = tester.widgetList<TextField>(textFields);
    for (final textField in textFieldElements) {
      if (textField.decoration?.labelText == null && textField.decoration?.hintText == null) {
        violations.add(AccessibilityViolation(
          severity: ViolationSeverity.major,
          type: ViolationType.missingLabel,
          element: 'TextField',
          description: 'Text field is missing a label or hint text',
          recommendation: 'Add labelText or hintText to the TextField decoration',
          wcagGuideline: '2.5.3 Label in Name',
        ));
      }
    }
  }

  /// Audit semantic elements
  Future<void> _auditSemanticElements(WidgetTester tester) async {
    // Check for missing semantic labels on images
    final images = find.byType(Image);
    final imageElements = tester.widgetList<Image>(images);

    for (final image in imageElements) {
      if (image.semanticLabel == null) {
        issues.add(AccessibilityIssue(
          severity: IssueSeverity.warning,
          type: IssueType.missingSemanticLabel,
          element: 'Image widget',
          description: 'Image is missing semantic label for screen readers',
          recommendation: 'Add semanticLabel property to Image widget',
          wcagGuideline: '1.1.1 Non-text Content',
        ));
      }
    }

    // Check for proper heading hierarchy (simplified check)
    final textWidgets = find.byType(Text);
    final textElements = tester.widgetList<Text>(textWidgets);
    final headings = textElements.where((text) {
      final style = text.style;
      return style?.fontWeight == FontWeight.bold && (style?.fontSize ?? 0) > 16;
    });

    if (headings.isEmpty) {
      issues.add(AccessibilityIssue(
        severity: IssueSeverity.info,
        type: IssueType.headingStructure,
        element: 'Page content',
        description: 'No heading elements detected on the page',
        recommendation: 'Consider adding heading widgets for better content structure',
        wcagGuideline: '1.3.1 Info and Relationships',
      ));
    }
  }

  /// Audit keyboard navigation
  Future<void> _auditKeyboardNavigation(WidgetTester tester) async {
    // Check for focusable widgets
    final focusableWidgets = find.byType(Focus);
    final focusElements = tester.widgetList<Focus>(focusableWidgets);

    if (focusElements.isEmpty) {
      issues.add(AccessibilityIssue(
        severity: IssueSeverity.info,
        type: IssueType.keyboardNavigation,
        element: 'Interactive elements',
        description: 'No explicit Focus widgets found - keyboard navigation may be limited',
        recommendation: 'Consider adding Focus widgets for better keyboard navigation',
        wcagGuideline: '2.1.1 Keyboard',
      ));
    }
  }

  /// Audit screen reader support
  Future<void> _auditScreenReaderSupport(WidgetTester tester) async {
    // Check for Semantics widgets
    final semanticsWidgets = find.byType(Semantics);
    final semanticsElements = tester.widgetList<Semantics>(semanticsWidgets);

    if (semanticsElements.isEmpty) {
      issues.add(AccessibilityIssue(
        severity: IssueSeverity.info,
        type: IssueType.screenReader,
        element: 'Screen reader support',
        description: 'No Semantics widgets found - screen reader support may be limited',
        recommendation: 'Consider adding Semantics widgets for better screen reader support',
        wcagGuideline: '4.1.2 Name, Role, Value',
      ));
    }
  }

  /// Audit performance metrics related to accessibility
  Future<void> _auditPerformanceMetrics(WidgetTester tester) async {
    // This would integrate with performance monitoring
    // For now, just add a placeholder
    auditMetadata['performance_metrics'] = {
      'audit_duration_ms': 0,
      'widgets_analyzed': tester.widgetList(find.byType(Widget)).length,
    };
  }

  /// Generate audit report
  AccessibilityAuditResult _generateReport() {
    final totalIssues = issues.length + violations.length;
    final criticalViolations = violations.where((v) => v.severity == ViolationSeverity.critical).length;
    final majorViolations = violations.where((v) => v.severity == ViolationSeverity.major).length;

    final score = _calculateAccessibilityScore();

    return AccessibilityAuditResult(
      issues: issues,
      violations: violations,
      metadata: auditMetadata,
      score: score,
      summary: AccessibilitySummary(
        totalIssues: totalIssues,
        criticalViolations: criticalViolations,
        majorViolations: majorViolations,
        warnings: issues.where((i) => i.severity == IssueSeverity.warning).length,
        info: issues.where((i) => i.severity == IssueSeverity.info).length,
      ),
    );
  }

  /// Calculate accessibility score (0-100)
  double _calculateAccessibilityScore() {
    final totalViolations = violations.length;
    final totalIssues = issues.length;

    // Weight violations more heavily than issues
    final violationPenalty = totalViolations * 10;
    final issuePenalty = totalIssues * 2;

    final rawScore = 100 - violationPenalty - issuePenalty;
    return rawScore.clamp(0, 100).toDouble();
  }

  /// Export audit results to file
  static Future<void> exportReport(AccessibilityAuditResult result, {String? filePath}) async {
    final path = filePath ?? _reportFileName;
    final jsonResult = jsonEncode(result.toJson());

    await File(path).writeAsString(jsonResult);
  }

  /// Import audit results from file
  static Future<AccessibilityAuditResult?> importReport(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);
      return AccessibilityAuditResult.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }
}

/// Accessibility audit result
class AccessibilityAuditResult {
  final List<AccessibilityIssue> issues;
  final List<AccessibilityViolation> violations;
  final Map<String, dynamic> metadata;
  final double score;
  final AccessibilitySummary summary;

  AccessibilityAuditResult({
    required this.issues,
    required this.violations,
    required this.metadata,
    required this.score,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
    'issues': issues.map((i) => i.toJson()).toList(),
    'violations': violations.map((v) => v.toJson()).toList(),
    'metadata': metadata,
    'score': score,
    'summary': summary.toJson(),
  };

  factory AccessibilityAuditResult.fromJson(Map<String, dynamic> json) {
    return AccessibilityAuditResult(
      issues: (json['issues'] as List).map((i) => AccessibilityIssue.fromJson(i)).toList(),
      violations: (json['violations'] as List).map((v) => AccessibilityViolation.fromJson(v)).toList(),
      metadata: json['metadata'],
      score: json['score'],
      summary: AccessibilitySummary.fromJson(json['summary']),
    );
  }
}

/// Accessibility issue (non-blocking)
class AccessibilityIssue {
  final IssueSeverity severity;
  final IssueType type;
  final String element;
  final String description;
  final String recommendation;
  final String wcagGuideline;

  AccessibilityIssue({
    required this.severity,
    required this.type,
    required this.element,
    required this.description,
    required this.recommendation,
    required this.wcagGuideline,
  });

  Map<String, dynamic> toJson() => {
    'severity': severity.name,
    'type': type.name,
    'element': element,
    'description': description,
    'recommendation': recommendation,
    'wcagGuideline': wcagGuideline,
  };

  factory AccessibilityIssue.fromJson(Map<String, dynamic> json) {
    return AccessibilityIssue(
      severity: IssueSeverity.values.firstWhere((e) => e.name == json['severity']),
      type: IssueType.values.firstWhere((e) => e.name == json['type']),
      element: json['element'],
      description: json['description'],
      recommendation: json['recommendation'],
      wcagGuideline: json['wcagGuideline'],
    );
  }
}

/// Accessibility violation (blocking)
class AccessibilityViolation {
  final ViolationSeverity severity;
  final ViolationType type;
  final String element;
  final String description;
  final String recommendation;
  final String wcagGuideline;

  AccessibilityViolation({
    required this.severity,
    required this.type,
    required this.element,
    required this.description,
    required this.recommendation,
    required this.wcagGuideline,
  });

  Map<String, dynamic> toJson() => {
    'severity': severity.name,
    'type': type.name,
    'element': element,
    'description': description,
    'recommendation': recommendation,
    'wcagGuideline': wcagGuideline,
  };

  factory AccessibilityViolation.fromJson(Map<String, dynamic> json) {
    return AccessibilityViolation(
      severity: ViolationSeverity.values.firstWhere((e) => e.name == json['severity']),
      type: ViolationType.values.firstWhere((e) => e.name == json['type']),
      element: json['element'],
      description: json['description'],
      recommendation: json['recommendation'],
      wcagGuideline: json['wcagGuideline'],
    );
  }
}

/// Accessibility summary
class AccessibilitySummary {
  final int totalIssues;
  final int criticalViolations;
  final int majorViolations;
  final int warnings;
  final int info;

  AccessibilitySummary({
    required this.totalIssues,
    required this.criticalViolations,
    required this.majorViolations,
    required this.warnings,
    required this.info,
  });

  Map<String, dynamic> toJson() => {
    'totalIssues': totalIssues,
    'criticalViolations': criticalViolations,
    'majorViolations': majorViolations,
    'warnings': warnings,
    'info': info,
  };

  factory AccessibilitySummary.fromJson(Map<String, dynamic> json) {
    return AccessibilitySummary(
      totalIssues: json['totalIssues'],
      criticalViolations: json['criticalViolations'],
      majorViolations: json['majorViolations'],
      warnings: json['warnings'],
      info: json['info'],
    );
  }
}

/// Issue severity levels
enum IssueSeverity { info, warning }

/// Violation severity levels
enum ViolationSeverity { minor, major, critical }

/// Issue types
enum IssueType {
  colorContrast,
  textSize,
  missingSemanticLabel,
  headingStructure,
  keyboardNavigation,
  screenReader,
}

/// Violation types
enum ViolationType {
  colorContrast,
  touchTarget,
  missingLabel,
}
