/// Business rules
class BusinessRules {
  // Team rules
  static const int minTeamNameLength = 2;
  static const int maxTeamNameLength = 100;
  static const int defaultTeamSize = 11;
  static const int minTeamSize = 1;
  static const int maxTeamSize = 50;
  static const int minTeamAge = 13;
  static const int maxTeamAge = 120;

  // Match rules
  static const int minMatchDuration = 30; // minutes
  static const int maxMatchDuration = 180; // minutes
  static const int defaultMatchDuration = 90; // minutes
  static const int minMatchPlayers = 2;
  static const int maxMatchPlayers = 50;
  static const int defaultMaxPlayers = 22;

  // Player rules
  static const int minPlayerAge = 13;
  static const int maxPlayerAge = 120;
  static const int minBioLength = 0;
  static const int maxBioLength = 500;

  // Availability rules
  static const int teamAvailabilityWindow = 2; // hours before/after match
  static const int matchCreationAdvanceTime = 1; // days in advance
}

/// Cache durations
class CacheDurations {
  static const Duration userProfile = Duration(hours: 1);
  static const Duration teams = Duration(minutes: 30);
  static const Duration matches = Duration(minutes: 15);
  static const Duration notifications = Duration(minutes: 5);
  static const Duration cities = Duration(days: 7);
  static const Duration userStats = Duration(hours: 1);
}

/// Retry policies
class RetryPolicies {
  static const int maxRetries = 3;
  static const int initialDelayMs = 1000;
  static const double backoffMultiplier = 2.0;
  static const int maxDelayMs = 10000;
}

/// Rate limiting
class RateLimiting {
  static const int loginAttempts = 5;
  static const Duration loginWindow = Duration(minutes: 15);
  static const int apiCallsPerSecond = 10;
  static const int apiCallsPerMinute = 300;
}

/// Feature flags
class FeatureFlags {
  static const bool enableOfflineMode = true;
  static const bool enableNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
}

/// Default values
class DefaultValues {
  static const String defaultLanguage = 'en';
  static const String defaultTheme = 'light';
  static const String defaultGender = 'other';
  static const String defaultRole = 'player';
  static const String defaultSkillLevel = 'intermediate';
  static const String defaultTeamGender = 'mixed';
}
