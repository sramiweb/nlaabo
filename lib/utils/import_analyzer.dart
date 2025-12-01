/// Utility to help identify unused imports
/// Run: dart lib/utils/import_analyzer.dart
/// 
/// Common unused imports to look for:
/// - Unused service imports (team_service, user_service, etc.)
/// - Unused repository imports
/// - Unused widget imports
/// - Unused utility imports

class ImportAnalyzer {
  static const Map<String, List<String>> commonUnused = {
    'home_screen.dart': [
      'team_service', // Not used - data loaded via provider
      'user_service', // Not used - data loaded via provider
      'team_repository', // Not used - initialized but not directly used
      'user_repository', // Not used - initialized but not directly used
      'api_service', // Not used - initialized but not directly used
    ],
    'teams_screen.dart': [
      'team_service', // Partially used - can be moved to provider
      'user_service', // Not used
    ],
  };

  static void printAnalysis() {
    print('=== Unused Import Analysis ===\n');
    commonUnused.forEach((file, imports) {
      print('$file:');
      for (final import in imports) {
        print('  - $import');
      }
      print('');
    });
  }
}
