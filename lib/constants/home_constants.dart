/// Constants for the home screen UI and functionality
library;
import '../utils/design_system.dart';

class HomeConstants {
  // Featured items limits
  static const int featuredItemsCount = 3;
  static const int maxSearchResults = 6;

  // Card height constraints (minimum heights for consistency)
  static const double minMatchCardHeight = 180.0;
  static const double minTeamCardHeight = 160.0;
  static const double maxCardHeight = 280.0; // Prevent cards from becoming too tall

  // UI dimensions
  static const double borderRadius = 12.0;
  static const double emptyStateHeight = 280.0; // Increased for better visual balance
  static const double emptyStateIconSize = 80.0; // Increased from 64px to 80px
  static const double emptyStateSpacing = DesignSystem.spacingMd;

  // Typography
  static const double sectionHeaderFontSize = 20.0;

  // Opacity values
  static const double borderAlpha = 0.2;
  static const double emptyStateIconAlpha = 0.5;
  static const double emptyStateTextAlpha = 0.7;

  // Search validation
  static const int maxSearchQueryLength = 100;
  static const String searchValidationPattern = r"^[a-zA-Z0-9\s\-\.\,']+$";
}
