import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../services/localization_service.dart';

/// A reusable error display component
class ErrorDisplay extends StatelessWidget {
  final String? message;
  final String? title;
  final String? messageTranslationKey;
  final String? titleTranslationKey;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onRetry;
  final String? retryText;
  final String? retryTranslationKey;
  final bool showRetryButton;

  const ErrorDisplay({
    super.key,
    this.message,
    this.title,
    this.messageTranslationKey,
    this.titleTranslationKey,
    this.icon = Icons.error,
    this.iconColor,
    this.onRetry,
    this.retryText,
    this.retryTranslationKey,
    this.showRetryButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = titleTranslationKey != null
        ? LocalizationService().translate(titleTranslationKey!)
        : title ?? 'Error';

    final displayMessage = messageTranslationKey != null
        ? LocalizationService().translate(messageTranslationKey!)
        : message ?? 'An error occurred';

    final displayRetryText = retryTranslationKey != null
        ? LocalizationService().translate(retryTranslationKey!)
        : retryText ?? 'Retry';

    return Center(
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: iconColor ?? Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: context.itemSpacing),
            Text(
              displayTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.itemSpacing * 0.5),
            Text(
              displayMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetryButton && onRetry != null) ...[
              SizedBox(height: context.itemSpacing * 2),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(displayRetryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
