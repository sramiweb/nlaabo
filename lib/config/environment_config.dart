import 'package:flutter/foundation.dart';
import 'app_config.dart';

/// Determine environment based on build flavor or runtime detection
AppEnvironment detectEnvironment() {
  // Check for environment override in system properties
  const environment = String.fromEnvironment('ENVIRONMENT');
  if (environment.isNotEmpty) {
    switch (environment.toLowerCase()) {
      case 'development':
      case 'dev':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'production':
      case 'prod':
        return AppEnvironment.production;
    }
  }

  // Default to development for debug builds
  return AppEnvironment.development;
}

/// Get environment name as string
String getEnvironmentName(AppEnvironment environment) {
  switch (environment) {
    case AppEnvironment.development:
      return 'development';
    case AppEnvironment.staging:
      return 'staging';
    case AppEnvironment.production:
      return 'production';
  }
}

/// Check if running in debug mode
bool get isDebugMode => kDebugMode;

/// Check if running in release mode
bool get isReleaseMode => kReleaseMode;
