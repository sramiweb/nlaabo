import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/match.dart';
import '../services/localization_service.dart';
import '../constants/translation_keys.dart';
import '../constants/responsive_constants.dart';
import '../utils/responsive_utils.dart';
import '../design_system/typography/app_text_styles.dart';
import 'fade_in_animation.dart';

String getLocalizedStatus(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return LocalizationService().translate(TranslationKeys.open);
    case 'closed':
      return LocalizationService().translate(TranslationKeys.closed);
    default:
      return status;
  }
}

Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return Colors.green;
    case 'closed':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback? onTap;

  const MatchCard({super.key, required this.match, this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayTitle = _getMatchTitle();
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    return Semantics(
      label: 'Match: $displayTitle',
      hint: 'Tap to view match details and join the game',
      child: FadeInAnimation(
        child: Card(
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap ?? () => context.go('/match/${match.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: getStatusColor(match.status).withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: ResponsiveConstants.getResponsivePadding(context, 'xs'),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (!isRTL) ...[
                            Container(
                              padding: ResponsiveConstants.getResponsivePadding(context, 'xs'),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.sports_soccer,
                                color: Theme.of(context).colorScheme.primary,
                                size: ResponsiveUtils.getIconSize(context, 22),
                              ),
                            ),
                            SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                          ],
                          Expanded(
                            child: Text(
                              displayTitle,
                              style: AppTextStyles.getResponsiveCardTitle(context).copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: context.isMobile ? 12 : 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            ),
                          ),
                          if (isRTL) ...[
                            SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                            Container(
                              padding: ResponsiveConstants.getResponsivePadding(context, 'xs'),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.sports_soccer,
                                color: Theme.of(context).colorScheme.primary,
                                size: ResponsiveUtils.getIconSize(context, 22),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildInfoRow(
                                  context,
                                  Icons.location_on,
                                  match.location,
                                  Colors.red.shade400,
                                ),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                                _buildInfoRow(
                                  context,
                                  Icons.access_time,
                                  match.formattedDate,
                                  Colors.blue.shade400,
                                ),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                                _buildInfoRow(
                                  context,
                                  Icons.people,
                                  '${match.defaultMaxPlayers}',
                                  Colors.green.shade400,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'xs2')),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'sm'),
                              vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs'),
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(match.status),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              getLocalizedStatus(match.status),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.isMobile ? 9 : 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMatchTitle() {
    if (match.team1Name != null && match.team2Name != null) {
      return '${match.team1Name} vs ${match.team2Name}';
    }
    
    if (match.team1Id != null && match.team2Id != null) {
      final team1 = match.team1Name ?? 'Team 1';
      final team2 = match.team2Name ?? 'Team 2';
      return '$team1 vs $team2';
    }
    
    if (match.title != null && match.title!.isNotEmpty) {
      return match.title!;
    }
    
    if (match.teamName != null && match.teamName!.isNotEmpty) {
      return '${match.teamName} Match';
    }
    
    return 'Football Match';
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveUtils.getIconSize(context, 12),
          color: iconColor,
        ),
        SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              fontSize: context.isMobile ? 11 : 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
