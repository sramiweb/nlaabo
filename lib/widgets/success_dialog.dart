import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/design_system.dart';
import '../services/localization_service.dart';

/// A reusable success feedback component for form submissions
class SuccessDialog extends StatelessWidget {
  final String? message;
  final String? title;
  final String? messageTranslationKey;
  final String? titleTranslationKey;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onContinue;
  final String? continueText;
  final String? continueTranslationKey;
  final bool showContinueButton;
  final Duration autoDismissDuration;

  const SuccessDialog({
    super.key,
    this.message,
    this.title,
    this.messageTranslationKey,
    this.titleTranslationKey,
    this.icon = Icons.check_circle,
    this.iconColor,
    this.onContinue,
    this.continueText,
    this.continueTranslationKey,
    this.showContinueButton = true,
    this.autoDismissDuration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = titleTranslationKey != null
        ? LocalizationService().translate(titleTranslationKey!)
        : title ?? 'Success';

    final displayMessage = messageTranslationKey != null
        ? LocalizationService().translate(messageTranslationKey!)
        : message ?? 'Operation completed successfully';

    final displayContinueText = continueTranslationKey != null
        ? LocalizationService().translate(continueTranslationKey!)
        : continueText ?? 'Continue';

    // Auto-dismiss after specified duration if no action button
    if (!showContinueButton && autoDismissDuration != Duration.zero) {
      Future.delayed(autoDismissDuration, () {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.borderRadius),
      ),
      child: Padding(
        padding: context.responsivePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Icon(
              icon,
              size: 72,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: context.itemSpacing),

            // Title
            Text(
              displayTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.itemSpacing * 0.5),

            // Message
            Text(
              displayMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),

            // Continue button
            if (showContinueButton) ...[
              SizedBox(height: context.itemSpacing * 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onContinue ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BorderRadiusSystem.medium),
                    ),
                  ),
                  child: Text(displayContinueText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show the success dialog as a modal
  static Future<void> show(
    BuildContext context, {
    String? message,
    String? title,
    String? messageTranslationKey,
    String? titleTranslationKey,
    IconData icon = Icons.check_circle,
    Color? iconColor,
    VoidCallback? onContinue,
    String? continueText,
    String? continueTranslationKey,
    bool showContinueButton = true,
    Duration autoDismissDuration = const Duration(seconds: 3),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !showContinueButton, // Only dismissible if no action button
      builder: (context) => SuccessDialog(
        message: message,
        title: title,
        messageTranslationKey: messageTranslationKey,
        titleTranslationKey: titleTranslationKey,
        icon: icon,
        iconColor: iconColor,
        onContinue: onContinue,
        continueText: continueText,
        continueTranslationKey: continueTranslationKey,
        showContinueButton: showContinueButton,
        autoDismissDuration: autoDismissDuration,
      ),
    );
  }
}
