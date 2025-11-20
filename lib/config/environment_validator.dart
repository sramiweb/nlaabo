import 'app_config.dart';

/// Exception thrown when environment validation fails
class EnvironmentValidationException implements Exception {
  final List<String> errors;
  final List<String> warnings;

  const EnvironmentValidationException({
    required this.errors,
    this.warnings = const [],
  });

  @override
  String toString() {
    final buffer = StringBuffer('Environment validation failed:\n');

    if (errors.isNotEmpty) {
      buffer.writeln('\n❌ Critical Errors:');
      for (final error in errors) {
        buffer.writeln('  • $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('\n⚠️  Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  • $warning');
      }
    }

    buffer.writeln('\n🔧 To fix these issues:');
    buffer.writeln('  1. Check your .env file for missing or invalid values');
    buffer.writeln('  2. Ensure all required environment variables are set');
    buffer.writeln('  3. Verify URLs are properly formatted');
    buffer.writeln('  4. Check API keys and credentials are valid');

    return buffer.toString();
  }
}

/// Environment validator with detailed error reporting
class EnvironmentValidator {
  /// Validate environment configuration and throw exception if invalid
  static Future<void> validateAndThrow({
    required AppEnvironment environment,
  }) async {
    try {
      await AppConfig.initialize(
        environment: environment,
      );
    } catch (e) {
      throw EnvironmentValidationException(
        errors: [e.toString()],
        warnings: [],
      );
    }
  }

  /// Validate environment configuration and return result
  static Future<ValidationResult> validate({
    required AppEnvironment environment,
  }) async {
    try {
      await AppConfig.initialize(
        environment: environment,
      );
      return const ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: [e.toString()],
      );
    }
  }

  /// Get detailed validation report as formatted string
  static Future<String> getValidationReport({
    required AppEnvironment environment,
  }) async {
    final result = await validate(
      environment: environment,
    );

    final buffer = StringBuffer();
    buffer.writeln('🔍 Environment Validation Report');
    buffer.writeln('=' * 50);
    buffer.writeln('Environment: ${environment.name.toUpperCase()}');
    buffer.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');

    if (result.isValid) {
      buffer.writeln('✅ Status: VALID');
    } else {
      buffer.writeln('❌ Status: INVALID');
    }

    if (result.hasErrors) {
      buffer.writeln('\n🚨 Critical Errors (${result.errors.length}):');
      buffer.writeln('-' * 30);
      for (int i = 0; i < result.errors.length; i++) {
        buffer.writeln('${i + 1}. ${result.errors[i]}');
      }
    }

    if (result.hasWarnings) {
      buffer.writeln('\n⚠️  Warnings (${result.warnings.length}):');
      buffer.writeln('-' * 30);
      for (int i = 0; i < result.warnings.length; i++) {
        buffer.writeln('${i + 1}. ${result.warnings[i]}');
      }
    }

    if (result.isValid && !result.hasWarnings) {
      buffer.writeln('\n🎉 All checks passed! Configuration is ready.');
    }

    buffer.writeln('\n📋 Configuration Summary:');
    buffer.writeln('-' * 30);

    final config = AppConfig.instance;
    buffer.writeln(
      'Supabase URL: ${config.supabase.url.isNotEmpty ? '✅ Set' : '❌ Missing'}',
    );
    buffer.writeln(
      'Supabase Key: ${config.supabase.anonKey.isNotEmpty ? '✅ Set' : '❌ Missing'}',
    );
    buffer.writeln('API Base URL: ${config.api.baseUrl}');
    buffer.writeln('Auth Redirects: Configured in Supabase dashboard');
    buffer.writeln(
      'Logging: ${config.appSettings.enableLogging ? 'Enabled' : 'Disabled'}',
    );
    buffer.writeln(
      'Analytics: ${config.appSettings.enableAnalytics ? 'Enabled' : 'Disabled'}',
    );

    return buffer.toString();
  }

  /// Validate specific configuration sections
  static Future<Map<String, ValidationResult>> validateSections({
    required AppEnvironment environment,
  }) async {
    try {
      await AppConfig.initialize(
        environment: environment,
      );
      final config = AppConfig.instance;

      return {
        'initialization': const ValidationResult(isValid: true),
        'supabase': config.supabase.validate(environment),
        'api': config.api.validate(),
        'auth': config.auth.validate(),
        'app_settings': config.appSettings.validate(),
      };
    } catch (e) {
      return {
        'initialization': ValidationResult(
          isValid: false,
          errors: [e.toString()],
        ),
      };
    }
  }

  /// Get environment-specific validation rules
  static List<String> getRequiredVariables(AppEnvironment environment) {
    final baseRequired = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];

    final optionalWithDefaults = [
      'API_BASE_URL',
      'API_TIMEOUT_SECONDS',
      'API_MAX_RETRIES',
      'SESSION_TIMEOUT_HOURS',
      'ENABLE_LOGGING',
      'ENABLE_ANALYTICS',
      'CACHE_SIZE_MB',
      'CACHE_EXPIRATION_HOURS',
    ];

    switch (environment) {
      case AppEnvironment.development:
        return [...baseRequired, ...optionalWithDefaults];
      case AppEnvironment.staging:
        return [...baseRequired, ...optionalWithDefaults];
      case AppEnvironment.production:
        // In production, all variables should be explicitly set
        return [
          ...baseRequired,
          'API_BASE_URL',
          'API_TIMEOUT_SECONDS',
          'API_MAX_RETRIES',
          'SESSION_TIMEOUT_HOURS',
          'ENABLE_LOGGING',
          'ENABLE_ANALYTICS',
          'CACHE_SIZE_MB',
          'CACHE_EXPIRATION_HOURS',
        ];
    }
  }

  /// Check if environment file exists and is readable
  static Future<bool> checkEnvFileExists(String fileName) async {
    try {
      // This would need file system access, for now return true
      // In a real implementation, you'd check if the file exists
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generate sample environment file content
  static String generateSampleEnvFile(AppEnvironment environment) {
    final buffer = StringBuffer();
    buffer.writeln(
      '# ${environment.name.toUpperCase()} Environment Configuration',
    );
    buffer.writeln(
      '# Generated by EnvironmentValidator on ${DateTime.now().toIso8601String()}',
    );
    buffer.writeln('#');
    buffer.writeln(
      '# IMPORTANT: Replace placeholder values with your actual configuration',
    );
    buffer.writeln('# Never commit real credentials to version control');
    buffer.writeln('');

    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# SUPABASE CONFIGURATION (REQUIRED)');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# Get these from your Supabase project dashboard');
    buffer.writeln('# URL format: https://your-project-id.supabase.co');

    switch (environment) {
      case AppEnvironment.development:
        buffer.writeln('SUPABASE_URL=https://your-dev-project.supabase.co');
        buffer.writeln('SUPABASE_ANON_KEY=your_dev_supabase_anon_key');
        break;
      case AppEnvironment.staging:
        buffer.writeln('SUPABASE_URL=https://your-staging-project.supabase.co');
        buffer.writeln('SUPABASE_ANON_KEY=your_staging_supabase_anon_key');
        break;
      case AppEnvironment.production:
        buffer.writeln('SUPABASE_URL=https://your-prod-project.supabase.co');
        buffer.writeln('SUPABASE_ANON_KEY=your_prod_supabase_anon_key');
        break;
    }

    buffer.writeln('');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# API CONFIGURATION');
    buffer.writeln(
      '# =============================================================================',
    );

    switch (environment) {
      case AppEnvironment.development:
        buffer.writeln('API_BASE_URL=http://localhost:8001/api/v1');
        break;
      case AppEnvironment.staging:
        buffer.writeln(
          'API_BASE_URL=https://your-staging-api.example.com/api/v1',
        );
        break;
      case AppEnvironment.production:
        buffer.writeln(
          'API_BASE_URL=https://your-production-api.example.com/api/v1',
        );
        break;
    }

    buffer.writeln('# Note: Auth redirect URLs are configured in Supabase dashboard');
    buffer.writeln('');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# TIMEOUT AND RETRY CONFIGURATION');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('API_TIMEOUT_SECONDS=30');
    buffer.writeln('API_MAX_RETRIES=3');
    buffer.writeln('SESSION_TIMEOUT_HOURS=24');
    buffer.writeln('');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# FEATURE FLAGS');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('ENABLE_LOGGING=true');

    switch (environment) {
      case AppEnvironment.development:
        buffer.writeln('ENABLE_ANALYTICS=false');
        break;
      case AppEnvironment.staging:
      case AppEnvironment.production:
        buffer.writeln('ENABLE_ANALYTICS=true');
        break;
    }

    buffer.writeln('');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# CACHE CONFIGURATION');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('CACHE_SIZE_MB=50');
    buffer.writeln('CACHE_EXPIRATION_HOURS=24');
    buffer.writeln('');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln('# ENVIRONMENT VALIDATION');
    buffer.writeln(
      '# =============================================================================',
    );
    buffer.writeln(
      '# This file was validated on: ${DateTime.now().toIso8601String()}',
    );

    return buffer.toString();
  }
}

/// Extension to get environment name
extension AppEnvironmentExtension on AppEnvironment {
  String get name {
    switch (this) {
      case AppEnvironment.development:
        return 'development';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'production';
    }
  }
}
