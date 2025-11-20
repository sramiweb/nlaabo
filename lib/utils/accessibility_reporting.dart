import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'accessibility_auditor.dart';
import 'accessibility_monitoring.dart';

/// Accessibility reporting and alerting system
class AccessibilityReporting {
  static const String _alertsLogPath = 'accessibility_alerts.log';
  static const String _weeklyReportPath = 'accessibility_weekly_report.md';

  /// Generate comprehensive accessibility report
  static Future<String> generateComprehensiveReport({
    required List<AccessibilityAuditResult> auditResults,
    AccessibilityMonitoringStats? monitoringStats,
    DateTimeRange? dateRange,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('# Accessibility Compliance Report');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}\n');

    if (dateRange != null) {
      buffer.writeln('**Report Period:** ${dateRange.start.toIso8601String()} to ${dateRange.end.toIso8601String()}\n');
    }

    // Executive Summary
    buffer.writeln('## Executive Summary\n');
    _generateExecutiveSummary(buffer, auditResults, monitoringStats);

    // Detailed Results
    buffer.writeln('## Detailed Audit Results\n');
    _generateDetailedResults(buffer, auditResults);

    // Trend Analysis
    if (monitoringStats != null) {
      buffer.writeln('## Trend Analysis\n');
      _generateTrendAnalysis(buffer, monitoringStats);
    }

    // Issues and Violations
    buffer.writeln('## Issues and Violations\n');
    _generateIssuesAndViolations(buffer, auditResults);

    // Recommendations
    buffer.writeln('## Recommendations\n');
    _generateRecommendations(buffer, auditResults);

    // Compliance Status
    buffer.writeln('## Compliance Status\n');
    _generateComplianceStatus(buffer, auditResults);

    return buffer.toString();
  }

  /// Generate executive summary
  static void _generateExecutiveSummary(
    StringBuffer buffer,
    List<AccessibilityAuditResult> results,
    AccessibilityMonitoringStats? stats,
  ) {
    if (results.isEmpty) {
      buffer.writeln('No accessibility audit results available.\n');
      return;
    }

    final averageScore = results.map((r) => r.score).reduce((a, b) => a + b) / results.length;
    final totalCritical = results.map((r) => r.summary.criticalViolations).reduce((a, b) => a + b);
    final totalMajor = results.map((r) => r.summary.majorViolations).reduce((a, b) => a + b);
    final totalTests = results.length;

    buffer.writeln('| Metric | Value | Status |');
    buffer.writeln('|--------|-------|--------|');
    buffer.writeln('| Average Accessibility Score | ${averageScore.toStringAsFixed(1)}/100 | ${_getScoreStatus(averageScore)} |');
    buffer.writeln('| Total Tests Audited | $totalTests | - |');
    buffer.writeln('| Critical Violations | $totalCritical | ${_getViolationStatus(totalCritical, 0)} |');
    buffer.writeln('| Major Violations | $totalMajor | ${_getViolationStatus(totalMajor, 5)} |');

    if (stats != null) {
      buffer.writeln('| Monitoring Trend | ${stats.trendDirection.name} | ${_getTrendStatus(stats.trendDirection)} |');
      buffer.writeln('| Total Monitoring Audits | ${stats.totalAudits} | - |');
    }

    buffer.writeln();
    buffer.writeln('**Overall Assessment:** ${_getOverallAssessment(averageScore, totalCritical, totalMajor)}\n');
  }

  /// Generate detailed results
  static void _generateDetailedResults(StringBuffer buffer, List<AccessibilityAuditResult> results) {
    for (var i = 0; i < results.length; i++) {
      final result = results[i];
      buffer.writeln('### Test ${i + 1}: ${result.metadata['widget_type'] ?? 'Unknown Widget'}\n');

      buffer.writeln('**Score:** ${result.score.toStringAsFixed(1)}/100');
      buffer.writeln('**Timestamp:** ${result.metadata['timestamp'] ?? 'Unknown'}\n');

      if (result.violations.isNotEmpty) {
        buffer.writeln('**Violations:**');
        for (final violation in result.violations) {
          buffer.writeln('- **${violation.severity.name.toUpperCase()}** ${violation.description}');
          buffer.writeln('  - *WCAG:* ${violation.wcagGuideline}');
          buffer.writeln('  - *Fix:* ${violation.recommendation}');
        }
        buffer.writeln();
      }

      if (result.issues.isNotEmpty) {
        buffer.writeln('**Issues:**');
        for (final issue in result.issues) {
          buffer.writeln('- **${issue.severity.name}** ${issue.description}');
          buffer.writeln('  - *WCAG:* ${issue.wcagGuideline}');
          buffer.writeln('  - *Suggestion:* ${issue.recommendation}');
        }
        buffer.writeln();
      }
    }
  }

  /// Generate trend analysis
  static void _generateTrendAnalysis(StringBuffer buffer, AccessibilityMonitoringStats stats) {
    buffer.writeln('**Current Trend:** ${stats.trendDirection.name}\n');

    buffer.writeln('**Monitoring Statistics:**');
    buffer.writeln('- Total Audits: ${stats.totalAudits}');
    buffer.writeln('- Average Score: ${stats.averageScore.toStringAsFixed(1)}/100');
    buffer.writeln('- Last Audit: ${stats.lastAuditDate?.toIso8601String() ?? 'Never'}');
    buffer.writeln('- Alerts Generated: ${stats.alertsGenerated}\n');

    // Trend interpretation
    switch (stats.trendDirection) {
      case TrendDirection.improving:
        buffer.writeln('📈 **Positive Trend:** Accessibility scores are improving over time.');
        break;
      case TrendDirection.stable:
        buffer.writeln('➡️ **Stable Trend:** Accessibility scores are consistent.');
        break;
      case TrendDirection.declining:
        buffer.writeln('📉 **Negative Trend:** Accessibility scores are declining. Immediate attention required.');
        break;
    }
    buffer.writeln();
  }

  /// Generate issues and violations summary
  static void _generateIssuesAndViolations(StringBuffer buffer, List<AccessibilityAuditResult> results) {
    final allViolations = results.expand((r) => r.violations).toList();
    final allIssues = results.expand((r) => r.issues).toList();

    if (allViolations.isEmpty && allIssues.isEmpty) {
      buffer.writeln('✅ No accessibility issues or violations found.\n');
      return;
    }

    // Group violations by type
    final violationsByType = <ViolationType, List<AccessibilityViolation>>{};
    for (final violation in allViolations) {
      violationsByType.putIfAbsent(violation.type, () => []).add(violation);
    }

    // Group issues by type
    final issuesByType = <IssueType, List<AccessibilityIssue>>{};
    for (final issue in allIssues) {
      issuesByType.putIfAbsent(issue.type, () => []).add(issue);
    }

    if (violationsByType.isNotEmpty) {
      buffer.writeln('### Violations by Type\n');
      for (final entry in violationsByType.entries) {
        buffer.writeln('**${entry.key.name}:** ${entry.value.length} violations');
        for (final violation in entry.value.take(3)) { // Show first 3 examples
          buffer.writeln('- ${violation.description}');
        }
        if (entry.value.length > 3) {
          buffer.writeln('- ... and ${entry.value.length - 3} more');
        }
        buffer.writeln();
      }
    }

    if (issuesByType.isNotEmpty) {
      buffer.writeln('### Issues by Type\n');
      for (final entry in issuesByType.entries) {
        buffer.writeln('**${entry.key.name}:** ${entry.value.length} issues');
        for (final issue in entry.value.take(3)) { // Show first 3 examples
          buffer.writeln('- ${issue.description}');
        }
        if (entry.value.length > 3) {
          buffer.writeln('- ... and ${entry.value.length - 3} more');
        }
        buffer.writeln();
      }
    }
  }

  /// Generate recommendations
  static void _generateRecommendations(StringBuffer buffer, List<AccessibilityAuditResult> results) {
    final recommendations = <String>[];

    final totalCritical = results.map((r) => r.summary.criticalViolations).reduce((a, b) => a + b);
    final totalMajor = results.map((r) => r.summary.majorViolations).reduce((a, b) => a + b);
    final averageScore = results.map((r) => r.score).reduce((a, b) => a + b) / results.length;

    if (totalCritical > 0) {
      recommendations.add('🚨 **CRITICAL:** Address all critical violations immediately before deployment');
      recommendations.add('   - Focus on color contrast and touch target size issues');
      recommendations.add('   - Test with screen readers and keyboard navigation');
    }

    if (totalMajor > 5) {
      recommendations.add('⚠️ **HIGH PRIORITY:** Review and fix major accessibility violations');
      recommendations.add('   - Implement proper semantic labels');
      recommendations.add('   - Ensure adequate text sizing');
    }

    if (averageScore < 85) {
      recommendations.add('📈 **IMPROVEMENT:** Work towards achieving 85+ accessibility score');
      recommendations.add('   - Conduct accessibility training for development team');
      recommendations.add('   - Implement accessibility-first design practices');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ **MAINTENANCE:** Continue current accessibility practices');
      recommendations.add('   - Regular monitoring and testing');
      recommendations.add('   - Stay updated with accessibility guidelines');
    }

    for (final rec in recommendations) {
      buffer.writeln('- $rec');
    }
    buffer.writeln();
  }

  /// Generate compliance status
  static void _generateComplianceStatus(StringBuffer buffer, List<AccessibilityAuditResult> results) {
    final averageScore = results.map((r) => r.score).reduce((a, b) => a + b) / results.length;
    final totalCritical = results.map((r) => r.summary.criticalViolations).reduce((a, b) => a + b);

    String status;
    String icon;
    String description;

    if (totalCritical == 0 && averageScore >= 95) {
      status = 'Fully Compliant';
      icon = '🏆';
      description = 'Excellent accessibility compliance with enhanced standards';
    } else if (totalCritical == 0 && averageScore >= 85) {
      status = 'Compliant';
      icon = '✅';
      description = 'Good accessibility compliance meeting basic requirements';
    } else if (totalCritical == 0 && averageScore >= 70) {
      status = 'Partially Compliant';
      icon = '⚠️';
      description = 'Basic accessibility requirements met, but improvements needed';
    } else if (totalCritical > 0) {
      status = 'Non-Compliant';
      icon = '❌';
      description = 'Critical accessibility violations must be addressed';
    } else {
      status = 'Needs Improvement';
      icon = '📉';
      description = 'Accessibility improvements required';
    }

    buffer.writeln('$icon **Status:** $status\n');
    buffer.writeln('**Description:** $description\n');

    // WCAG Compliance Level
    String wcagLevel;
    if (averageScore >= 95) {
      wcagLevel = 'WCAG 2.1 AAA (Enhanced)';
    } else if (averageScore >= 85) {
      wcagLevel = 'WCAG 2.1 AA (Minimum)';
    } else {
      wcagLevel = 'Below WCAG 2.1 AA standards';
    }

    buffer.writeln('**WCAG Compliance Level:** $wcagLevel\n');
  }

  /// Helper methods for status determination
  static String _getScoreStatus(double score) {
    if (score >= 95) return '🏆 Excellent';
    if (score >= 85) return '✅ Good';
    if (score >= 70) return '⚠️ Needs Work';
    return '❌ Poor';
  }

  static String _getViolationStatus(int count, int threshold) {
    if (count == 0) return '✅ None';
    if (count <= threshold) return '⚠️ Acceptable';
    return '❌ Too Many';
  }

  static String _getTrendStatus(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving: return '📈 Improving';
      case TrendDirection.stable: return '➡️ Stable';
      case TrendDirection.declining: return '📉 Declining';
    }
  }

  static String _getOverallAssessment(double score, int critical, int major) {
    if (critical > 0) return 'Critical violations must be addressed immediately';
    if (score >= 95) return 'Excellent accessibility compliance';
    if (score >= 85) return 'Good accessibility compliance';
    if (score >= 70) return 'Basic accessibility requirements met';
    return 'Accessibility improvements needed';
  }

  /// Send alert notification (placeholder for actual implementation)
  static Future<void> sendAlertNotification(AccessibilityAlert alert) async {
    // In a real implementation, this would integrate with:
    // - Slack notifications
    // - Email alerts
    // - SMS alerts
    // - Dashboard updates

    final alertEntry = {
      'timestamp': alert.timestamp.toIso8601String(),
      'type': alert.type.name,
      'severity': alert.severity.name,
      'message': alert.message,
      'recommendations': alert.recommendations,
    };

    // Append to alerts log
    final logEntry = '${jsonEncode(alertEntry)}\n';
    await File(_alertsLogPath).writeAsString(logEntry, mode: FileMode.append);

    print('🚨 Accessibility Alert: ${alert.message}');
  }

  /// Generate weekly accessibility report
  static Future<void> generateWeeklyReport(AccessibilityMonitoring monitoring) async {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));

    final report = await generateComprehensiveReport(
      auditResults: [], // Would be populated with week's results
      monitoringStats: monitoring.getMonitoringStats(),
      dateRange: DateTimeRange(start: weekStart, end: now),
    );

    await File(_weeklyReportPath).writeAsString(report);
    print('📊 Weekly accessibility report generated: $_weeklyReportPath');
  }

  /// Export report to various formats
  static Future<void> exportReport(
    String reportContent,
    String format, {
    String? filePath,
  }) async {
    final path = filePath ?? 'accessibility_report.${format.toLowerCase()}';

    switch (format.toLowerCase()) {
      case 'json':
        // Convert markdown to JSON structure
        final jsonReport = {
          'generated_at': DateTime.now().toIso8601String(),
          'format': 'accessibility_report',
          'content': reportContent,
        };
        await File(path).writeAsString(jsonEncode(jsonReport));
        break;

      case 'html':
        // Convert markdown to basic HTML
        final htmlContent = _convertMarkdownToHtml(reportContent);
        await File(path).writeAsString(htmlContent);
        break;

      case 'md':
      default:
        await File(path).writeAsString(reportContent);
        break;
    }

    print('📄 Report exported to $path');
  }

  /// Convert markdown to basic HTML
  static String _convertMarkdownToHtml(String markdown) {
    // Basic markdown to HTML conversion
    var html = markdown
        .replaceAll('# ', '<h1>')
        .replaceAll('## ', '<h2>')
        .replaceAll('### ', '<h3>')
        .replaceAll('\n\n', '</p><p>')
        .replaceAll('**', '<strong>')
        .replaceAll('*', '<em>')
        .replaceAll('- ', '<li>')
        .replaceAll('\n', '<br>');

    // Wrap in basic HTML structure
    html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Accessibility Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .status-excellent { color: #28a745; }
        .status-good { color: #17a2b8; }
        .status-warning { color: #ffc107; }
        .status-error { color: #dc3545; }
    </style>
</head>
<body>
    <p>$html</p>
</body>
</html>
''';

    return html;
  }
}
