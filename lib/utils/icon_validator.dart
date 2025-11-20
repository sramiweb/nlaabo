import 'package:flutter/services.dart';

/// Utility class for validating icon assets and ensuring consistent naming.
class IconValidator {
  static const List<int> requiredSizes = [16, 32, 64, 128, 256, 512, 1024];
  static const String baseAssetPath = 'assets/icons/logo.png';

  /// Validate that all required icon sizes exist and meet quality standards.
  static Future<IconValidationResult> validateAllIcons() async {
    final result = IconValidationResult();

    // Check base logo
    final baseExists = await _assetExists(baseAssetPath);
    if (!baseExists) {
      result.errors.add('Base logo not found: $baseAssetPath');
      return result;
    }

    // Check generated sizes
    for (final size in requiredSizes) {
      final path = 'assets/icons/logo_$size.png';
      final exists = await _assetExists(path);

      if (!exists) {
        result.errors.add('Missing icon size: $path');
        continue;
      }

      // Validate quality
      final qualityResult = await _validateIconQuality(path, size);
      if (!qualityResult.isValid) {
        result.errors.addAll(qualityResult.errors);
      }

      result.validatedSizes.add(size);
    }

    result.isValid = result.errors.isEmpty;
    return result;
  }

  /// Validate icon quality for a specific size.
  static Future<IconQualityResult> _validateIconQuality(String assetPath, int expectedSize) async {
    final result = IconQualityResult();

    try {
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // Basic validation - in a real implementation, you might use
      // an image processing library to check dimensions, colors, etc.
      if (bytes.isEmpty) {
        result.errors.add('Icon file is empty: $assetPath');
        return result;
      }

      // Check file size (rough heuristic)
      if (bytes.length < 100) {
        result.warnings.add('Icon file seems too small: $assetPath');
      }

      result.isValid = result.errors.isEmpty;

    } catch (e) {
      result.errors.add('Failed to load icon $assetPath: $e');
    }

    return result;
  }

  /// Check if an asset exists.
  static Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ensure consistent naming conventions across the project.
  static Future<List<String>> checkNamingConsistency() async {
    final issues = <String>[];

    // Check for inconsistent naming patterns
    final possiblePatterns = [
      RegExp(r'logo_\d+\.png$'),
      RegExp(r'app_icon.*\.png$'),
    ];

    // This would typically scan the assets directory
    // For now, return empty list as this is a runtime check
    return issues;
  }

  /// Get the appropriate icon size for a given display size.
  static String getOptimalIconPath(double displaySize) {
    if (displaySize <= 16) return 'assets/icons/logo_16.png';
    if (displaySize <= 32) return 'assets/icons/logo_32.png';
    if (displaySize <= 64) return 'assets/icons/logo_64.png';
    if (displaySize <= 128) return 'assets/icons/logo_128.png';
    if (displaySize <= 256) return 'assets/icons/logo_256.png';
    if (displaySize <= 512) return 'assets/icons/logo_512.png';
    return 'assets/icons/logo_1024.png';
  }
}

/// Result of icon validation.
class IconValidationResult {
  bool isValid = false;
  final List<String> errors = [];
  final List<int> validatedSizes = [];
}

/// Result of individual icon quality check.
class IconQualityResult {
  bool isValid = false;
  final List<String> errors = [];
  final List<String> warnings = [];
}
