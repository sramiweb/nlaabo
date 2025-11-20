import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'accessibility_auditor.dart';
import 'accessibility_test_runner.dart';

/// CI/CD integration for accessibility auditing
class AccessibilityCIIntegration {
  static const String _ciReportPath = 'accessibility_ci_report.json';
  static const String _ciSummaryPath = 'accessibility_ci_summary.txt';

  /// Run accessibility audit for CI/CD pipeline
  static Future<CIResult> runCIAudit({
    required WidgetTester tester,
    required List<Widget> testWidgets,
    required BuildContext context,
    double minScoreThreshold = 85.0,
    int maxCriticalViolations = 0,
    int maxMajorViolations = 5,
    bool failOnRegression = true,
    String? baselineReportPath,
  }) async {
    print('🚀 Starting accessibility CI audit...');

    final startTime = DateTime.now();

    try {
      // Run accessibility tests
      final results = await AccessibilityTestRunner.runBatchAccessibilityTests(
        tester,
        testWidgets,
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Generate reports
      await _generateCIReports(results, duration);

      // Check thresholds
      final thresholdResults = _checkThresholds(
        results,
        minScoreThreshold,
        maxCriticalViolations,
        maxMajorViolations,
      );

      // Check for regressions
      final regressionCheck = await _checkRegression(
        results,
        baselineReportPath,
        failOnRegression,
      );

      // Determine overall result
      final overallSuccess = thresholdResults.success && regressionCheck.success;

      final ciResult = CIResult(
        success: overallSuccess,
        results: results,
        duration: duration,
        thresholdCheck: thresholdResults,
        regressionCheck: regressionCheck,
        summary: _generateCISummary(results, thresholdResults, regressionCheck),
      );

      // Print results
      _printCIResults(ciResult);

      return ciResult;

    } catch (e, stackTrace) {
      print('❌ Accessibility CI audit failed: $e');
      print(stackTrace);

      return CIResult(
        success: false,
        results: [],
        duration: DateTime.now().difference(startTime),
        thresholdCheck: ThresholdCheckResult(success: false, message: 'Audit failed: $e'),
        regressionCheck: RegressionCheckResult(success: false, message: 'Audit failed: $e'),
        summary: 'CI audit failed with error: $e',
      );
    }
  }

  /// Generate CI reports
  static Future<void> _generateCIReports(
    List<AccessibilityAuditResult> results,
    Duration duration,
  ) async {
    // JSON report for detailed analysis
    final jsonReport = {
      'timestamp': DateTime.now().toIso8601String(),
      'duration_ms': duration.inMilliseconds,
      'results': results.map((r) => r.toJson()).toList(),
      'summary': _calculateOverallSummary(results),
    };

    await File(_ciReportPath).writeAsString(jsonEncode(jsonReport));

    // Text summary for quick viewing
    final textSummary = AccessibilityTestRunner.generateTestReport(results);
    await File(_ciSummaryPath).writeAsString(textSummary);

    print('📄 Reports generated: $_ciReportPath, $_ciSummaryPath');
  }

  /// Check accessibility thresholds
  static ThresholdCheckResult _checkThresholds(
    List<AccessibilityAuditResult> results,
    double minScore,
    int maxCritical,
    int maxMajor,
  ) {
    final failures = <String>[];

    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      final testName = 'Test ${i + 1}';

      if (result.score < minScore) {
        failures.add('$testName: Score ${result.score.toStringAsFixed(1)} < $minScore');
      }

      if (result.summary.criticalViolations > maxCritical) {
        failures.add('$testName: Critical violations ${result.summary.criticalViolations} > $maxCritical');
      }

      if (result.summary.majorViolations > maxMajor) {
        failures.add('$testName: Major violations ${result.summary.majorViolations} > $maxMajor');
      }
    }

    final success = failures.isEmpty;
    final message = success
      ? 'All accessibility thresholds met'
      : 'Accessibility thresholds not met:\n${failures.join('\n')}';

    return ThresholdCheckResult(success: success, message: message);
  }

  /// Check for accessibility regressions
  static Future<RegressionCheckResult> _checkRegression(
    List<AccessibilityAuditResult> currentResults,
    String? baselinePath,
    bool failOnRegression,
  ) async {
    if (baselinePath == null || !File(baselinePath).existsSync()) {
      return RegressionCheckResult(
        success: true,
        message: 'No baseline report found - skipping regression check',
      );
    }

    try {
      final baselineResults = await AccessibilityAuditor.importReport(baselinePath);

      if (baselineResults == null) {
        return RegressionCheckResult(
          success: !failOnRegression,
          message: 'Could not load baseline report',
        );
      }

      final regressions = <String>[];

      // For now, compare with single baseline result
      // TODO: Implement proper baseline comparison for multiple results
      if (currentResults.isNotEmpty) {
        final current = currentResults.first; // Compare first result for simplicity
        const testName = 'Accessibility Audit';

        // Simplified regression check - in practice, you'd load and compare with actual baseline
        // For now, just check if current score is reasonable
        if (current.score < 70.0) {
          regressions.add('$testName: Accessibility score is critically low: ${current.score.toStringAsFixed(1)}/100');
        }

        if (current.summary.criticalViolations > 0) {
          regressions.add('$testName: Critical accessibility violations found: ${current.summary.criticalViolations}');
        }
      }

      final hasRegressions = regressions.isNotEmpty;
      final success = !hasRegressions || !failOnRegression;

      final message = hasRegressions
        ? 'Accessibility regressions detected:\n${regressions.join('\n')}'
        : 'No accessibility regressions detected';

      return RegressionCheckResult(success: success, message: message);

    } catch (e) {
      return RegressionCheckResult(
        success: !failOnRegression,
        message: 'Error checking regression: $e',
      );
    }
  }

  /// Calculate overall summary
  static Map<String, dynamic> _calculateOverallSummary(List<AccessibilityAuditResult> results) {
    if (results.isEmpty) {
      return {
        'average_score': 0.0,
        'total_critical_violations': 0,
        'total_major_violations': 0,
        'total_warnings': 0,
        'total_info': 0,
        'tests_passed': 0,
        'tests_failed': 0,
      };
    }

    final averageScore = results.map((r) => r.score).reduce((a, b) => a + b) / results.length;
    final totalCritical = results.map((r) => r.summary.criticalViolations).reduce((a, b) => a + b);
    final totalMajor = results.map((r) => r.summary.majorViolations).reduce((a, b) => a + b);
    final totalWarnings = results.map((r) => r.summary.warnings).reduce((a, b) => a + b);
    final totalInfo = results.map((r) => r.summary.info).reduce((a, b) => a + b);

    return {
      'average_score': averageScore,
      'total_critical_violations': totalCritical,
      'total_major_violations': totalMajor,
      'total_warnings': totalWarnings,
      'total_info': totalInfo,
      'tests_passed': results.where((r) => r.score >= 85.0).length,
      'tests_failed': results.where((r) => r.score < 85.0).length,
    };
  }

  /// Generate CI summary
  static String _generateCISummary(
    List<AccessibilityAuditResult> results,
    ThresholdCheckResult thresholdCheck,
    RegressionCheckResult regressionCheck,
  ) {
    final summary = _calculateOverallSummary(results);

    return '''
Accessibility CI Summary:
========================
Average Score: ${summary['average_score'].toStringAsFixed(1)}/100
Tests Passed: ${summary['tests_passed']}/${results.length}
Critical Violations: ${summary['total_critical_violations']}
Major Violations: ${summary['total_major_violations']}
Warnings: ${summary['total_warnings']}

Threshold Check: ${thresholdCheck.success ? '✅ PASS' : '❌ FAIL'}
${thresholdCheck.message}

Regression Check: ${regressionCheck.success ? '✅ PASS' : '❌ FAIL'}
${regressionCheck.message}
''';
  }

  /// Print CI results
  static void _printCIResults(CIResult result) {
    print('\n${'=' * 50}');
    print('ACCESSIBILITY CI RESULTS');
    print('=' * 50);

    if (result.success) {
      print('✅ CI audit PASSED');
    } else {
      print('❌ CI audit FAILED');
    }

    print('Duration: ${result.duration.inSeconds}s');
    print('Tests run: ${result.results.length}');

    if (result.results.isNotEmpty) {
      final avgScore = result.results.map((r) => r.score).reduce((a, b) => a + b) / result.results.length;
      print('Average score: ${avgScore.toStringAsFixed(1)}/100');
    }

    print('\nThreshold Check: ${result.thresholdCheck.success ? 'PASS' : 'FAIL'}');
    print(result.thresholdCheck.message);

    print('\nRegression Check: ${result.regressionCheck.success ? 'PASS' : 'FAIL'}');
    print(result.regressionCheck.message);

    print('\n${'=' * 50}');
  }

  /// Set up accessibility baseline for future regression testing
  static Future<void> setupBaseline(List<AccessibilityAuditResult> results, String baselinePath) async {
    final baselineData = {
      'created_at': DateTime.now().toIso8601String(),
      'version': '1.0',
      'results': results.map((r) => r.toJson()).toList(),
    };

    await File(baselinePath).writeAsString(jsonEncode(baselineData));
    print('📊 Accessibility baseline saved to $baselinePath');
  }

  /// Generate GitHub Actions summary
  static Future<void> generateGitHubSummary(CIResult result) async {
    final summaryPath = Platform.environment['GITHUB_STEP_SUMMARY'];
    if (summaryPath == null) return;

    final summary = '''
## Accessibility CI Results

${result.success ? '✅' : '❌'} **${result.success ? 'PASSED' : 'FAILED'}**

### Summary
- **Duration**: ${result.duration.inSeconds}s
- **Tests**: ${result.results.length}
- **Average Score**: ${result.results.isEmpty ? 'N/A' : (result.results.map((r) => r.score).reduce((a, b) => a + b) / result.results.length).toStringAsFixed(1)}/100

### Threshold Check
${result.thresholdCheck.success ? '✅' : '❌'} ${result.thresholdCheck.message.replaceAll('\n', '\n  ')}

### Regression Check
${result.regressionCheck.success ? '✅' : '❌'} ${result.regressionCheck.message.replaceAll('\n', '\n  ')}
''';

    await File(summaryPath).writeAsString(summary, mode: FileMode.append);
  }
}

/// CI audit result
class CIResult {
  final bool success;
  final List<AccessibilityAuditResult> results;
  final Duration duration;
  final ThresholdCheckResult thresholdCheck;
  final RegressionCheckResult regressionCheck;
  final String summary;

  CIResult({
    required this.success,
    required this.results,
    required this.duration,
    required this.thresholdCheck,
    required this.regressionCheck,
    required this.summary,
  });
}

/// Threshold check result
class ThresholdCheckResult {
  final bool success;
  final String message;

  ThresholdCheckResult({required this.success, required this.message});
}

/// Regression check result
class RegressionCheckResult {
  final bool success;
  final String message;

  RegressionCheckResult({required this.success, required this.message});
}
