import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../services/localization_service.dart';
import 'animations.dart';

/// A reusable loading display component
class LoadingDisplay extends StatelessWidget {
  final String? message;
  final String? messageTranslationKey;
  final double? size;
  final Color? color;
  final bool showMessage;

  const LoadingDisplay({
    super.key,
    this.message,
    this.messageTranslationKey,
    this.size = 40,
    this.color,
    this.showMessage = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayMessage = messageTranslationKey != null
        ? LocalizationService().translate(messageTranslationKey!)
        : message ?? 'Loading...';

    return Semantics(
      label: 'Loading indicator',
      hint: displayMessage,
      liveRegion: true,
      child: Center(
        child: FadeInAnimation(
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PulseAnimation(
                duration: const Duration(milliseconds: 1500),
                scaleFactor: 1.1,
                child: SizedBox(
                  height: size,
                  width: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color ?? Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (showMessage) ...[
                SizedBox(height: context.itemSpacing),
                FadeInAnimation(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    displayMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
