import 'package:flutter/material.dart';
import '../models/team.dart';
import '../widgets/cached_image.dart';
import '../services/localization_service.dart';
import '../constants/responsive_constants.dart';
import '../design_system/typography/app_text_styles.dart';
import '../utils/responsive_utils.dart';

class TeamCard extends StatelessWidget {
  final Team team;
  final Map<String, dynamic>? ownerInfo;
  final int? memberCount;
  final VoidCallback onTap;
  final bool isOwnerLoading;
  final VoidCallback? onRetry;

  const TeamCard({
    super.key,
    required this.team,
    this.ownerInfo,
    this.memberCount,
    required this.onTap,
    this.isOwnerLoading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: team.isRecruiting ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: ResponsiveConstants.getResponsivePadding(context, 'xs'),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (!isRTL) ...[
                                Container(
                                  padding: ResponsiveConstants.getResponsivePadding(context, 'xs'),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: team.logo != null && team.logo!.isNotEmpty
                                      ? CachedImage(
                                          imageUrl: team.logo!,
                                          width: 22,
                                          height: 22,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(8),
                                          errorWidget: Icon(Icons.groups, color: Theme.of(context).colorScheme.primary, size: 22),
                                        )
                                      : Icon(Icons.groups, color: Theme.of(context).colorScheme.primary, size: ResponsiveUtils.getIconSize(context, 22)),
                                ),
                                SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                              ],
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                  maxLines: 2,
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
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: team.logo != null && team.logo!.isNotEmpty
                                      ? CachedImage(
                                          imageUrl: team.logo!,
                                          width: 22,
                                          height: 22,
                                          fit: BoxFit.cover,
                                          borderRadius: BorderRadius.circular(8),
                                          errorWidget: Icon(Icons.groups, color: Theme.of(context).colorScheme.primary, size: 22),
                                        )
                                      : Icon(Icons.groups, color: Theme.of(context).colorScheme.primary, size: ResponsiveUtils.getIconSize(context, 22)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ownerInfo != null
                                  ? _buildInfoRow(context, Icons.person, ownerInfo!['name'] ?? LocalizationService().translate('not_specified'), Colors.blue.shade400)
                                  : _buildInfoRow(context, Icons.person, LocalizationService().translate('not_specified'), Colors.blue.shade400),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                                _buildInfoRow(context, Icons.location_on, team.location ?? LocalizationService().translate('not_specified'), Colors.red.shade400),
                                SizedBox(height: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                                _buildInfoRow(context, Icons.people, '${memberCount ?? 0} / ${team.maxPlayers}', Colors.green.shade400),
                              ],
                            ),
                          ),
                          SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'sm')),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: ResponsiveConstants.getResponsiveSpacing(context, 'sm'), vertical: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
                            decoration: BoxDecoration(
                              color: team.isRecruiting ? Colors.green : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              team.isRecruiting ? LocalizationService().translate('recruiting') : LocalizationService().translate('closed'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, Color iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: ResponsiveUtils.getIconSize(context, 13), color: iconColor),
        SizedBox(width: ResponsiveConstants.getResponsiveSpacing(context, 'xs')),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
