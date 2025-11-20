#!/usr/bin/env dart
/// Automated touch target validation script for CI/CD pipeline
/// Validates that all interactive elements meet WCAG AA touch target requirements

import 'dart:io';
import 'package:path/path.dart' as path;

/// Touch target validation result
class ValidationResult {
  final String file;
  final String element;
  final int line;
  final bool isValid;
  final String? issue;

  ValidationResult({
    required this.file,
    required this.element,
    required this.line,
    required this.isValid,
    this.issue,
  });

  @override
  String toString() {
    final status = isValid ? '✅ PASS' : '❌ FAIL';
    final issueText = issue != null ? ' - $issue' : '';
    return '$file:$line - $element $status$issueText';
  }
}

/// Touch target validator for CI/CD
class TouchTargetValidator {
  static const int minTouchTargetSize = 48;

  /// Validate touch target size patterns in code
  static List<ValidationResult> validateFile(File file) {
    final results = <ValidationResult>[];
    final lines = file.readAsLinesSync();
    final fileName = path.basename(file.path);

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;

      // Check for IconButton without proper constraints
      if (line.contains('IconButton(') &&
          !line.contains('TouchTargetValidator.enforceMinimumTouchTarget') &&
          !line.contains('constraints:') &&
          !line.contains('minWidth:') &&
          !line.contains('minHeight:')) {
        results.add(ValidationResult(
          file: fileName,
          element: 'IconButton',
          line: lineNumber,
          isValid: false,
          issue: 'IconButton without minimum touch target constraints (48x48dp required)',
        ));
      }

      // Check for ElevatedButton, TextButton, OutlinedButton without proper constraints
      final buttonTypes = ['ElevatedButton', 'TextButton', 'OutlinedButton'];
      for (final buttonType in buttonTypes) {
        if (line.contains('$buttonType(') &&
            !line.contains('minimumSize:') &&
            !line.contains('TouchTargetValidator.enforceMinimumTouchTarget')) {
          results.add(ValidationResult(
            file: fileName,
            element: buttonType,
            line: lineNumber,
            isValid: false,
            issue: '$buttonType without minimum touch target size (48x48dp required)',
          ));
        }
      }

      // Check for InkWell without constraints
      if (line.contains('InkWell(') &&
          !line.contains('constraints:') &&
          !line.contains('minWidth:') &&
          !line.contains('minHeight:') &&
          !line.contains('TouchTargetValidator.enforceMinimumTouchTarget')) {
        results.add(ValidationResult(
          file: fileName,
          element: 'InkWell',
          line: lineNumber,
          isValid: false,
          issue: 'InkWell without minimum touch target constraints (48x48dp required)',
        ));
      }

      // Check for proper usage of TouchTargetValidator
      if (line.contains('TouchTargetValidator.enforceMinimumTouchTarget')) {
        results.add(ValidationResult(
          file: fileName,
          element: 'TouchTargetValidator',
          line: lineNumber,
          isValid: true,
          issue: 'Properly using TouchTargetValidator wrapper',
        ));
      }
    }

    return results;
  }

  /// Validate all Dart files in the lib directory
  static List<ValidationResult> validateProject(String projectRoot) {
    final results = <ValidationResult>[];
    final libDir = Directory(path.join(projectRoot, 'lib'));

    if (!libDir.existsSync()) {
      stderr.writeln('Error: lib directory not found in $projectRoot');
      exit(1);
    }

    // Find all Dart files
    final dartFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();

    for (final file in dartFiles) {
      results.addAll(validateFile(file));
    }

    return results;
  }
}

void main(List<String> args) {
  final projectRoot = args.isNotEmpty ? args[0] : Directory.current.path;

  stderr.writeln('🔍 Validating touch targets in $projectRoot...');

  final results = TouchTargetValidator.validateProject(projectRoot);

  final failedResults = results.where((r) => !r.isValid).toList();
  final passedResults = results.where((r) => r.isValid).toList();

  stderr.writeln('\n📊 Validation Results:');
  stderr.writeln('Total elements checked: ${results.length}');
  stderr.writeln('Passed: ${passedResults.length}');
  stderr.writeln('Failed: ${failedResults.length}');

  if (failedResults.isNotEmpty) {
    stderr.writeln('\n❌ Failed validations:');
    for (final result in failedResults) {
      stderr.writeln('  $result');
    }

    stderr.writeln('\n💡 Fix suggestions:');
    stderr.writeln('  1. Wrap IconButton with TouchTargetValidator.enforceMinimumTouchTarget()');
    stderr.writeln('  2. Add minimumSize: Size(48, 48) to button styles');
    stderr.writeln('  3. Use Container with constraints for custom interactive elements');
    stderr.writeln('  4. Ensure all interactive elements are at least 48x48dp');

    exit(1);
  } else {
    stderr.writeln('\n✅ All touch targets are compliant with WCAG AA standards!');
    exit(0);
  }
}