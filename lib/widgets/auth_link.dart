import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// A reusable link component for authentication screens (signup/login links)
class AuthLink extends StatelessWidget {
  final String text;
  final String linkText;
  final String? textTranslationKey;
  final String? linkTranslationKey;
  final VoidCallback? onPressed;
  final TextStyle? textStyle;
  final TextStyle? linkStyle;
  final MainAxisAlignment alignment;

  const AuthLink({
    super.key,
    this.text = '',
    this.linkText = '',
    this.textTranslationKey,
    this.linkTranslationKey,
    this.onPressed,
    this.textStyle,
    this.linkStyle,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = textTranslationKey != null
        ? LocalizationService().translate(textTranslationKey!)
        : text;

    final displayLinkText = linkTranslationKey != null
        ? LocalizationService().translate(linkTranslationKey!)
        : linkText;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          displayText,
          style: textStyle ?? TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(
            displayLinkText,
            style: linkStyle ?? TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
