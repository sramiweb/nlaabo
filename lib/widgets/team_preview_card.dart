import 'package:flutter/material.dart';
import '../models/team.dart';
import '../utils/responsive_utils.dart';
import '../utils/accessibility_utils.dart';
import 'cached_image.dart';
import '../utils/color_extensions.dart';

/// Constants for TeamPreviewCard widget to avoid hardcoded values
class TeamPreviewCardConstants {
  static const double cardHeight = 80.0;
  static const double cardWidth = 200.0;
  static const double logoSize = 32.0;
  static const double cardBorderRadius = 12.0;
  static const double padding = 12.0;
  static const double iconSize = 16.0;
  static const double mobileFontSize = 12.0;
  static const double desktopFontSize = 14.0;
  static const double teamNameMaxLines = 1;
  static const double locationMaxLines = 1;
  static const double iconSpacing = 4.0;
  static const double alphaSecondary = 0.1;
  static const double alphaOnSurface = 0.6;
  static const double alphaOnSurfaceText = 0.7;
}

class TeamPreviewCard extends StatelessWidget {
  final Team team;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showSelectionIndicator;

  const TeamPreviewCard({
    super.key,
    required this.team,
    this.isSelected = false,
    this.onTap,
    this.showSelectionIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveUtils.getCardWidth(context,
        maxWidth: TeamPreviewCardConstants.cardWidth);
    final iconSize =
        ResponsiveUtils.getIconSize(context, TeamPreviewCardConstants.iconSize);

    final teamName = team.name;
    final location = team.location;
    final logo = team.logo;

    final semanticLabel =
        AccessibilityUtils.getSemanticLabel('team_preview', teamName);
    final semanticHint =
        isSelected ? 'Team selected for match' : 'Tap to select team for match';

    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: onTap != null,
      selected: isSelected,
      enabled: true,
      child: Card(
        elevation: isSelected ? 6 : 2,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(TeamPreviewCardConstants.cardBorderRadius),
          side: isSelected
              ? BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(TeamPreviewCardConstants.cardBorderRadius),
          child: Container(
            width: cardWidth,
            height: TeamPreviewCardConstants.cardHeight,
            padding: const EdgeInsets.all(TeamPreviewCardConstants.padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  TeamPreviewCardConstants.cardBorderRadius),
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacitySafe(TeamPreviewCardConstants.alphaSecondary)
                  : null,
            ),
            child: Row(
              children: [
                // Team logo
                Semantics(
                  label: 'Team logo',
                  child: logo != null && logo.isNotEmpty
                      ? CachedImage(
                          imageUrl: logo,
                          width: TeamPreviewCardConstants.logoSize,
                          height: TeamPreviewCardConstants.logoSize,
                          borderRadius: BorderRadius.circular(
                              TeamPreviewCardConstants.cardBorderRadius),
                          placeholder: Container(
                            width: TeamPreviewCardConstants.logoSize,
                            height: TeamPreviewCardConstants.logoSize,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacitySafe(
                                      TeamPreviewCardConstants.alphaSecondary),
                              borderRadius: BorderRadius.circular(
                                  TeamPreviewCardConstants.cardBorderRadius),
                            ),
                            child: Icon(
                              Icons.groups,
                              color: Theme.of(context).colorScheme.secondary,
                              size: iconSize,
                            ),
                          ),
                        )
                      : Container(
                          width: TeamPreviewCardConstants.logoSize,
                          height: TeamPreviewCardConstants.logoSize,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacitySafe(
                                    TeamPreviewCardConstants.alphaSecondary),
                            borderRadius: BorderRadius.circular(
                                TeamPreviewCardConstants.cardBorderRadius),
                          ),
                          child: Icon(
                            Icons.groups,
                            color: Theme.of(context).colorScheme.secondary,
                            size: iconSize,
                          ),
                        ),
                ),
                const SizedBox(width: TeamPreviewCardConstants.iconSpacing * 2),

                // Team info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Team name
                      Text(
                        teamName,
                        style: AccessibilityUtils.getAccessibleTextStyle(
                          context: context,
                          baseStyle: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: context.isMobile
                                    ? TeamPreviewCardConstants.mobileFontSize
                                    : TeamPreviewCardConstants.desktopFontSize,
                              ),
                        ),
                        maxLines:
                            TeamPreviewCardConstants.teamNameMaxLines.toInt(),
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Location
                      if (location != null && location.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: iconSize * 0.8,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacitySafe(
                                      TeamPreviewCardConstants.alphaOnSurface),
                            ),
                            const SizedBox(
                                width: TeamPreviewCardConstants.iconSpacing),
                            Expanded(
                              child: Text(
                                location,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacitySafe(
                                              TeamPreviewCardConstants
                                                  .alphaOnSurfaceText),
                                      fontSize: context.isMobile
                                          ? TeamPreviewCardConstants
                                                  .mobileFontSize *
                                              0.9
                                          : TeamPreviewCardConstants
                                                  .desktopFontSize *
                                              0.9,
                                    ),
                                maxLines: TeamPreviewCardConstants
                                    .locationMaxLines
                                    .toInt(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Selection indicator
                if (showSelectionIndicator)
                  Container(
                    width: TeamPreviewCardConstants.iconSize,
                    height: TeamPreviewCardConstants.iconSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacitySafe(
                                    TeamPreviewCardConstants.alphaOnSurface),
                        width: 1.5,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: iconSize * 0.8,
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
