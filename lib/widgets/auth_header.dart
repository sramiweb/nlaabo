import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../services/localization_service.dart';

/// A reusable header component for authentication screens
class AuthHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? titleTranslationKey;
  final String? subtitleTranslationKey;
  final IconData icon;
  final Color? iconColor;
  final double? iconSize;

  const AuthHeader({
    super.key,
    this.title = '',
    this.subtitle,
    this.titleTranslationKey,
    this.subtitleTranslationKey,
    this.icon = Icons.person,
    this.iconColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = titleTranslationKey != null
        ? LocalizationService().translate(titleTranslationKey!)
        : title;

    final displaySubtitle = subtitleTranslationKey != null
        ? LocalizationService().translate(subtitleTranslationKey!)
        : subtitle;

    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize ?? (context.isMobile ? 50 : 60),
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: context.itemSpacing * 2),
          Text(
            displayTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: context.isMobile ? 24 : 28,
            ),
            textAlign: TextAlign.center,
          ),
          if (displaySubtitle != null) ...[
            SizedBox(height: context.itemSpacing * 0.5),
            Text(
              displaySubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: context.isMobile ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
