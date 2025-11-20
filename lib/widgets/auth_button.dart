import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../services/localization_service.dart';

/// A reusable button component for authentication screens
class AuthButton extends StatelessWidget {
  final String text;
  final String? translationKey;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Widget? leadingIcon;
  final Widget? trailingIcon;

  const AuthButton({
    super.key,
    this.text = '',
    this.translationKey,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 4,
    this.padding,
    this.borderRadius,
    this.leadingIcon,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final displayText = translationKey != null
        ? LocalizationService().translate(translationKey!)
        : text;

    final effectiveBackgroundColor = backgroundColor ??
        Theme.of(context).colorScheme.primary;

    final effectiveForegroundColor = foregroundColor ??
        Theme.of(context).colorScheme.onPrimary;

    final isButtonDisabled = isDisabled || isLoading || onPressed == null;

    return SizedBox(
      width: double.infinity,
      height: context.buttonHeight,
      child: ElevatedButton(
        onPressed: isButtonDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isButtonDisabled
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12)
              : effectiveBackgroundColor,
          foregroundColor: isButtonDisabled
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
              : effectiveForegroundColor,
          elevation: elevation,
          shadowColor: effectiveBackgroundColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveForegroundColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon!,
                    const SizedBox(width: 8),
                  ],
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: context.isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    trailingIcon!,
                  ],
                ],
              ),
      ),
    );
  }
}
