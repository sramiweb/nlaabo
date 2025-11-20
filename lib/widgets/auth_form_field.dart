import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/design_system.dart';
import '../services/localization_service.dart';

/// A reusable form field component for authentication screens
class AuthFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? translationKey;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const AuthFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.translationKey,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final displayLabel = translationKey != null
        ? LocalizationService().translate(translationKey!)
        : labelText;

    final displayHint = hintText ?? (translationKey != null ? LocalizationService().translate('enter_$translationKey') : null);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (displayLabel != null) ...[
            Text(
              displayLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: context.isMobile ? 16 : 18,
              ),
            ),
            const SizedBox(height: DesignSystem.spacingXs),
          ],
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: displayHint,
              prefixIcon: prefixIcon != null
                  ? Icon(
                      prefixIcon,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    )
                  : null,
              suffixIcon: suffixIcon,
            ),
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            enabled: enabled,
            textInputAction: textInputAction,
            onFieldSubmitted: onFieldSubmitted,
          ),
        ],
      ),
    );
  }
}
