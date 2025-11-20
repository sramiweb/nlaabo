import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/localization_provider.dart';
import '../utils/accessibility_utils.dart';
import 'package:provider/provider.dart';

/// A reusable language selector component for authentication screens
class AuthLanguageSelector extends StatelessWidget {
  const AuthLanguageSelector({super.key});

  Future<void> _changeLanguage(BuildContext context, String languageCode) async {
    try {
      final localizationProvider = Provider.of<LocalizationProvider>(context, listen: false);
      await localizationProvider.setLanguage(languageCode);

      // Update the theme provider to persist the language change
      if (context.mounted) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        try {
          await themeProvider.setLanguage(languageCode);
        } catch (themeError) {
          // If theme provider fails, revert localization provider
          await localizationProvider.setLanguage('en');
          throw Exception('Failed to update language settings: $themeError');
        }
      }
    } catch (error) {
      // Handle async gap by checking mounted before using context
      if (context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to change language: $error')),
            );
          }
        });
      }
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                leading: const Text('🇺🇸'),
                onTap: () {
                  _changeLanguage(context, 'en');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Français'),
                leading: const Text('🇫🇷'),
                onTap: () {
                  _changeLanguage(context, 'fr');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('العربية'),
                leading: const Text('🇲🇦'),
                onTap: () {
                  _changeLanguage(context, 'ar');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Debug Button (only in debug mode)
        if (kDebugMode)
          TouchTargetValidator.enforceMinimumTouchTarget(
            child: const Icon(Icons.bug_report, color: Colors.grey),
            onPressed: () => context.go('/debug'),
          ),
        // Language Button
        TouchTargetValidator.enforceMinimumTouchTarget(
          child: const Icon(Icons.language, color: Colors.grey),
          onPressed: () => _showLanguageDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
