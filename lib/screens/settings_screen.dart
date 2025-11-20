import 'package:flutter/material.dart';
import '../widgets/directional_icon.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../design_system/components/buttons/destructive_button.dart';
import '../design_system/components/forms/app_toggle.dart';
import '../design_system/components/cards/base_card.dart';
import '../design_system/colors/app_colors_extensions.dart';
import '../design_system/typography/app_text_styles.dart';
import '../design_system/spacing/app_spacing.dart';
import '../utils/responsive_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final localizationProvider = context.watch<LocalizationProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizationProvider.translate('settings'),
          style: AppTextStyles.cardTitle,
        ),
        leading: IconButton(
          icon: const DirectionalIcon(icon: Icons.arrow_back),
          onPressed: () => context.go('/home'),
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          tooltip: 'Go back to home',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: AppSpacing.screenPaddingInsets,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Header
                BaseCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.settings,
                        size: ResponsiveUtils.getIconSize(context, 64),
                        color: context.colors.primary,
                      ),
                      AppSpacing.verticalLg,
                      Text(
                        localizationProvider.translate('settings'),
                        style: AppTextStyles.getResponsivePageTitle(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        localizationProvider.translate('customize_experience'),
                        style: AppTextStyles.getResponsiveBodyText(context).copyWith(
                          color: context.colors.textSubtle,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalXl,

                // Theme Settings
                BaseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette,
                            color: context.colors.primary,
                            size: ResponsiveUtils.getIconSize(context, 24),
                          ),
                          AppSpacing.horizontalMd,
                          Text(
                            localizationProvider.translate('theme'),
                            style: AppTextStyles.cardTitle,
                          ),
                        ],
                      ),
                      AppSpacing.verticalLg,
                      AppToggle(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                        label: localizationProvider.translate('dark_mode'),
                        description: localizationProvider.translate('switch_themes'),
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalLg,

                // Language Settings
                BaseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.language,
                            color: context.colors.primary,
                            size: ResponsiveUtils.getIconSize(context, 24),
                          ),
                          AppSpacing.horizontalMd,
                          Text(
                            localizationProvider.translate('language'),
                            style: AppTextStyles.cardTitle,
                          ),
                        ],
                      ),
                      AppSpacing.verticalLg,
                      Text(
                        '${localizationProvider.translate('current_language')}: ${localizationProvider.currentLanguage.toUpperCase()}',
                        style: AppTextStyles.bodyText.copyWith(
                          color: context.colors.textSubtle,
                        ),
                      ),
                      AppSpacing.verticalMd,
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          _buildLanguageChip('en', 'English', localizationProvider),
                          _buildLanguageChip('fr', 'Français', localizationProvider),
                          _buildLanguageChip('ar', 'العربية', localizationProvider),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSpacing.verticalLg,

                // Account Settings
                BaseCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            color: context.colors.destructive,
                            size: ResponsiveUtils.getIconSize(context, 24),
                          ),
                          AppSpacing.horizontalMd,
                          Text(
                            localizationProvider.translate('account'),
                            style: AppTextStyles.cardTitle,
                          ),
                        ],
                      ),
                      AppSpacing.verticalLg,
                      SizedBox(
                        width: double.infinity,
                        child: DestructiveButton(
                          text: localizationProvider.translate('logout'),
                          leadingIcon: Icons.logout,
                          onPressed: () => _showLogoutConfirmation(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String code, String name, LocalizationProvider provider) {
    final isSelected = provider.currentLanguage == code;
    return FilterChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          await provider.setLanguage(code);
        }
      },
      selectedColor: context.colors.primary.withValues(alpha: 0.2),
      checkmarkColor: context.colors.primary,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final localizationProvider = context.read<LocalizationProvider>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localizationProvider.translate('logout')),
          content: Text(localizationProvider.translate('logout_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(localizationProvider.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(localizationProvider.translate('logout')),
            ),
          ],
        );
      },
    );
  }
}
