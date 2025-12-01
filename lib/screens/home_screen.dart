import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../services/localization_service.dart';
import '../utils/app_logger.dart';
import '../constants/translation_keys.dart';
import '../widgets/match_card.dart';
import '../widgets/team_card.dart';
import '../widgets/fade_in_animation.dart';
import '../widgets/optimized_filter_bar.dart';
import '../design_system/components/buttons/primary_button.dart';
import '../design_system/components/buttons/secondary_button.dart';
import '../design_system/components/forms/app_text_field.dart';
import '../design_system/components/cards/base_card.dart';
import '../design_system/colors/app_colors_extensions.dart';
import '../design_system/typography/app_text_styles.dart';
import '../design_system/spacing/app_spacing.dart';
import '../utils/responsive_utils.dart';
import '../utils/responsive_text_utils.dart';
import '../constants/responsive_constants.dart';
import '../utils/error_message_formatter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = context.read<HomeProvider>();
      final authProvider = context.read<AuthProvider>();

      homeProvider.loadData();
      homeProvider.checkUserTeamMembership(authProvider.user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<HomeProvider, (bool, String?, bool)>(
      selector: (context, provider) => (provider.isLoading, provider.errorMessage, provider.isUserInTeam),
      builder: (context, data, child) {
        final provider = context.read<HomeProvider>();
        final (isLoading, errorMessage, isUserInTeam) = data;
        
        if (errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.showError(errorMessage);
            }
          });
        }

        return Column(
          children: [
            OptimizedFilterBar(
              location: null,
              category: LocalizationService().translate('home'),
              onRefresh: () => provider.loadData(),
              onHome: () => context.go('/'),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: isLoading
                    ? _buildLoadingState(context)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchField(context, provider),
                    SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
                    _buildQuickActionButtons(context, provider),
                    SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm2')),
                    if (provider.searchQuery.isNotEmpty)
                      _buildSearchResults(context, provider)
                    else ...{
                      _buildSectionHeader(
                        context,
                        LocalizationService().translate(TranslationKeys.featuredMatches),
                        () => context.go('/matches'),
                      ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                      _buildFeaturedMatches(context, provider),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'lg')),
                      _buildSectionHeader(
                        context,
                        LocalizationService().translate(TranslationKeys.featuredTeams),
                        () => context.go('/teams'),
                      ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                      _buildFeaturedTeams(context, provider),
                    },
                        ],
                      ),
                    ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchField(BuildContext context, HomeProvider provider) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: ResponsiveUtils.getMaxContentWidth(context),
        ),
        child: AppTextField(
          controller: provider.searchController,
          hintText: LocalizationService().translate(TranslationKeys.searchHint),
          prefixIcon: Icon(Icons.search, size: ResponsiveUtils.getIconSize(context, 20)),
          suffixIcon: provider.searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: ResponsiveUtils.getIconSize(context, 18)),
                  onPressed: () => provider.clearSearchController(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 44.0,
                    minHeight: 44.0,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, HomeProvider provider) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: ResponsiveUtils.getButtonHeight(context),
                      child: SecondaryButton(
                        text: LocalizationService().translate(TranslationKeys.createTeam),
                        leadingIcon: Icons.group_add,
                        onPressed: () => context.go('/create-team'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (provider.isUserInTeam)
                    Expanded(
                      child: SizedBox(
                        height: ResponsiveUtils.getButtonHeight(context),
                        child: PrimaryButton(
                          text: LocalizationService().translate(TranslationKeys.createMatch),
                          leadingIcon: Icons.add,
                          onPressed: () => context.go('/create-match'),
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveUtils.getButtonHeight(context),
                    child: SecondaryButton(
                      text: LocalizationService().translate(TranslationKeys.createTeam),
                      leadingIcon: Icons.group_add,
                      onPressed: () => context.go('/create-team'),
                    ),
                  ),
                  if (provider.isUserInTeam) ...{
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveUtils.getButtonHeight(context),
                      child: PrimaryButton(
                        text: LocalizationService().translate(TranslationKeys.createMatch),
                        leadingIcon: Icons.add,
                        onPressed: () => context.go('/create-match'),
                      ),
                    ),
                  },
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onViewAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: ResponsiveTextUtils.getScaledTextStyle(context, AppTextStyles.sectionTitle),
          ),
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(88, 48),
            ),
            child: Text(LocalizationService().translate(TranslationKeys.viewAll), style: ResponsiveTextUtils.getResponsiveTextStyle(context, 'labelSmall')),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedMatches(BuildContext context, HomeProvider provider) {
    if (provider.featuredMatches.isEmpty) {
      return _buildEmptyState(
        context,
        LocalizationService().translate(TranslationKeys.noFeaturedMatchesAvailable),
        isMatches: true,
      );
    }

    return FadeInAnimation(
      delay: const Duration(milliseconds: 200),
      child: SizedBox(
        height: context.getCardHeight(isMatchCard: true),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
          itemCount: provider.featuredMatches.length,
          itemBuilder: (context, index) {
            final match = provider.featuredMatches[index];
            return Padding(
              padding: EdgeInsetsDirectional.only(end: ResponsiveUtils.getItemSpacing(context)),
              child: FadeInAnimation(
                delay: Duration(milliseconds: 100 * index),
                child: SizedBox(
                  width: ResponsiveUtils.getCardWidth(context),
                  child: MatchCard(key: ValueKey(match.id), match: match),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedTeams(BuildContext context, HomeProvider provider) {
    if (provider.featuredTeams.isEmpty) {
      return _buildEmptyState(
        context,
        LocalizationService().translate(TranslationKeys.noFeaturedTeamsAvailable),
        isMatches: false,
      );
    }

    return FadeInAnimation(
      delay: const Duration(milliseconds: 400),
      child: SizedBox(
        height: context.getCardHeight(isMatchCard: false),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
          itemCount: provider.featuredTeams.length,
          itemBuilder: (context, index) {
            final team = provider.featuredTeams[index];
            return Padding(
              padding: EdgeInsetsDirectional.only(end: ResponsiveUtils.getItemSpacing(context)),
              child: FadeInAnimation(
                delay: Duration(milliseconds: 100 * index),
                child: SizedBox(
                  width: ResponsiveUtils.getCardWidth(context),
                  child: TeamCard(
                    key: ValueKey(team.id),
                    team: team,
                    onTap: () => context.push('/teams/${team.id}'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, HomeProvider provider) {
    final hasSearchResults = provider.featuredMatches.isNotEmpty || provider.featuredTeams.isNotEmpty;

    if (!hasSearchResults) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService().translate(TranslationKeys.searchResultsFor),
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: 8),
          _buildSearchEmptyState(context, provider),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${LocalizationService().translate(TranslationKeys.searchResultsFor)} "${provider.searchQuery}"',
          style: AppTextStyles.sectionTitle,
        ),
        const SizedBox(height: 8),
        if (provider.featuredMatches.isNotEmpty) ...{
          Text(
            LocalizationService().translate(TranslationKeys.matches),
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: context.getCardHeight(isMatchCard: true),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
              itemCount: provider.featuredMatches.length,
              itemBuilder: (context, index) {
                final match = provider.featuredMatches[index];
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: ResponsiveUtils.getItemSpacing(context)),
                  child: FadeInAnimation(
                    delay: Duration(milliseconds: 100 * index),
                    child: SizedBox(
                      width: ResponsiveUtils.getCardWidth(context),
                      child: MatchCard(key: ValueKey(match.id), match: match),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        },
        if (provider.featuredTeams.isNotEmpty) ...{
          Text(
            LocalizationService().translate(TranslationKeys.teams),
            style: AppTextStyles.cardTitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: context.getCardHeight(isMatchCard: false),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.sm),
              itemCount: provider.featuredTeams.length,
              itemBuilder: (context, index) {
                final team = provider.featuredTeams[index];
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: ResponsiveUtils.getItemSpacing(context)),
                  child: FadeInAnimation(
                    delay: Duration(milliseconds: 100 * index),
                    child: SizedBox(
                      width: ResponsiveUtils.getCardWidth(context),
                      child: TeamCard(
                        key: ValueKey(team.id),
                        team: team,
                        onTap: () => context.push('/teams/${team.id}'),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        },
      ],
    );
  }

  Widget _buildSearchEmptyState(BuildContext context, HomeProvider provider) {
    return BaseCard(
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: ResponsiveUtils.getIconSize(context, 48),
            color: context.colors.textSubtle,
          ),
          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
          Text(
            LocalizationService().translate(TranslationKeys.noResultsFound),
            style: AppTextStyles.cardTitle.copyWith(
              color: context.colors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
          Text(
            LocalizationService().translate(TranslationKeys.exploreAll),
            style: AppTextStyles.bodyText.copyWith(
              color: context.colors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message, {bool isMatches = true}) {
    return BaseCard(
      child: Column(
        children: [
          Icon(
            isMatches ? Icons.sports_soccer : Icons.group,
            size: ResponsiveUtils.getIconSize(context, 48),
            color: context.colors.textSubtle,
          ),
          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
          Text(
            message,
            style: AppTextStyles.cardTitle.copyWith(
              color: context.colors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
          Text(
            isMatches
                ? LocalizationService().translate(TranslationKeys.setUpNewMatch)
                : LocalizationService().translate(TranslationKeys.createTeam),
            style: AppTextStyles.bodyText.copyWith(
              color: context.colors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'md')),
          PrimaryButton(
            text: isMatches
                ? LocalizationService().translate(TranslationKeys.createMatch)
                : LocalizationService().translate(TranslationKeys.createTeam),
            onPressed: () => context.go(isMatches ? '/create-match' : '/create-team'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPaddingInsets,
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
              border: Border.all(color: context.colors.border),
            ),
          ),
          AppSpacing.verticalLg,
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    border: Border.all(color: context.colors.border),
                  ),
                ),
              ),
              AppSpacing.horizontalLg,
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                    border: Border.all(color: context.colors.border),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.verticalXxl,
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
