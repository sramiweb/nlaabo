import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../design_system/components/buttons/primary_button.dart';
import '../design_system/components/buttons/secondary_button.dart';
import '../design_system/colors/app_colors_theme.dart';
import '../design_system/typography/app_text_styles.dart';
import '../design_system/spacing/app_spacing.dart';
import '../widgets/fade_in_animation.dart';
import '../services/onboarding_service.dart';
import '../providers/localization_provider.dart';
import '../services/localization_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  List<OnboardingPage> _getPages(BuildContext context) {
    final loc = LocalizationService();
    return [
      OnboardingPage(
        icon: Icons.language,
        title: loc.translate('choose_language'),
        description: loc.translate('select_preferred_language'),
        color: AppColorsTheme.of(context).primary,
        isLanguageSelect: true,
      ),
      OnboardingPage(
        icon: Icons.sports_soccer,
        title: loc.translate('organize_matches'),
        description: loc.translate('organize_matches_desc'),
        color: AppColorsTheme.of(context).primary,
      ),
      OnboardingPage(
        icon: Icons.group,
        title: loc.translate('build_teams'),
        description: loc.translate('build_teams_desc'),
        color: AppColorsTheme.of(context).success,
      ),
      OnboardingPage(
        icon: Icons.notifications_active,
        title: loc.translate('stay_updated'),
        description: loc.translate('stay_updated_desc'),
        color: AppColorsTheme.of(context).info,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    final pages = _getPages(context);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    try {
      await OnboardingService.setOnboardingSeen();
      if (mounted) {
        // Navigate to auth landing page after completing onboarding
        context.go('/auth');
      }
    } catch (e) {
      debugPrint('Error saving onboarding completion: $e');
      // Still navigate even if saving fails
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final localizationProvider = context.watch<LocalizationProvider>();
    final languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇲🇦'},
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    ];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: languages.map((lang) {
            final isSelected = localizationProvider.currentLanguage == lang['code'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: InkWell(
                onTap: () => localizationProvider.setLanguage(lang['code']!),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? AppColorsTheme.of(context).primary
                          : AppColorsTheme.of(context).border,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? AppColorsTheme.of(context).primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Text(
                        lang['flag']!,
                        style: const TextStyle(fontSize: 32),
                      ),
                      AppSpacing.horizontalMd,
                      Text(
                        lang['name']!,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? AppColorsTheme.of(context).primary
                              : AppColorsTheme.of(context).textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColorsTheme.of(context).primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, locProvider, child) {
        final pages = _getPages(context);
        
        return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: Padding(
                padding: AppSpacing.screenPaddingInsets,
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    LocalizationService().translate('skip'),
                    style: AppTextStyles.labelText.copyWith(
                      color: AppColorsTheme.of(context).textSubtle,
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return FadeInAnimation(
                    key: ValueKey(index),
                    child: Padding(
                      padding: AppSpacing.screenPaddingInsets,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          // Icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: page.color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              page.icon,
                              size: 64,
                              color: page.color,
                            ),
                          ),

                          AppSpacing.verticalXxl,

                          // Title
                          Text(
                            page.title,
                            style: AppTextStyles.pageTitle,
                            textAlign: TextAlign.center,
                          ),

                          AppSpacing.verticalLg,

                          // Description
                          Text(
                            page.description,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColorsTheme.of(context).textSubtle,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (page.isLanguageSelect) ...[
                            AppSpacing.verticalXxl,
                            _buildLanguageSelector(context),
                          ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom section
            Padding(
              padding: AppSpacing.screenPaddingInsets,
              child: Column(
                children: [
                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColorsTheme.of(context).primary
                              : AppColorsTheme.of(context).border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  AppSpacing.verticalXl,

                  // Buttons
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Row(
                        children: [
                          if (_currentPage > 0) ...[
                            Expanded(
                              child: SecondaryButton(
                                text: LocalizationService().translate('back'),
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                            AppSpacing.horizontalLg,
                          ],
                          Expanded(
                            child: PrimaryButton(
                              text: _currentPage == pages.length - 1
                                  ? LocalizationService().translate('get_started')
                                  : LocalizationService().translate('next'),
                              onPressed: _nextPage,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool isLanguageSelect;

  const OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.isLanguageSelect = false,
  });
}
