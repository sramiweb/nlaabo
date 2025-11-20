import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../colors/app_colors_extensions.dart';
import '../../typography/app_text_styles.dart';
import '../../spacing/app_spacing.dart';

/// AppTextField component following the design system specifications
/// - Focus states with border color changes
/// - Proper padding and typography
/// - Error state styling
/// - Label and hint text support
/// - Theme-aware colors
/// - Accessibility features included
/// - Supports validation feedback
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextAlign textAlign;
  final EdgeInsetsGeometry? contentPadding;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textAlign = TextAlign.start,
    this.contentPadding,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with TickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _focusController;
  late Animation<double> _focusAnimation;
  late AnimationController _errorController;
  late Animation<double> _errorAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();

    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _focusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOut,
    ));

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeOut,
    ));

    _focusNode.addListener(_handleFocusChange);

    // Initialize error animation if there's an error
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      _errorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle error state changes
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final hadError = oldWidget.errorText != null && oldWidget.errorText!.isNotEmpty;

    if (hasError && !hadError) {
      _errorController.forward();
    } else if (!hasError && hadError) {
      _errorController.reverse();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  Color _getBorderColor() {
    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      return context.colors.destructive;
    }
    if (_focusNode.hasFocus) {
      return context.colors.primary;
    }
    return context.colors.border;
  }

  @override
  Widget build(BuildContext context) {

    final contentPadding = widget.contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        );

    return Semantics(
      textField: true,
      label: widget.labelText,
      hint: widget.hintText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.labelText != null) ...[
            Text(
              widget.labelText!,
              style: AppTextStyles.labelText.copyWith(
                color: widget.enabled
                    ? context.colors.textPrimary
                    : context.colors.textSubtle,
              ),
            ),
            const SizedBox(height: 8.0),
          ],
          AnimatedBuilder(
            animation: Listenable.merge([_focusAnimation, _errorAnimation]),
            builder: (context, child) {
              final borderColor = _getBorderColor();
              final shadowColor = _focusNode.hasFocus
                  ? context.colors.primary.withValues(alpha: 0.1)
                  : Colors.transparent;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                  boxShadow: [
                    if (_focusAnimation.value > 0)
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 8.0 * _focusAnimation.value,
                        offset: Offset(0, 2.0 * _focusAnimation.value),
                      ),
                  ],
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  maxLength: widget.maxLength,
                  maxLines: widget.maxLines,
                  minLines: widget.minLines,
                  enabled: widget.enabled,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  textCapitalization: widget.textCapitalization,
                  autocorrect: widget.autocorrect,
                  enableSuggestions: widget.enableSuggestions,
                  textAlign: widget.textAlign,
                  style: AppTextStyles.bodyText.copyWith(
                    color: widget.enabled
                        ? context.colors.textPrimary
                        : context.colors.textSubtle,
                  ),
                  decoration: InputDecoration(
                    contentPadding: contentPadding,
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.bodyText.copyWith(
                      color: context.colors.textSubtle,
                    ),
                    prefixIcon: widget.prefixIcon,
                    suffixIcon: widget.suffixIcon,
                    filled: true,
                    fillColor: widget.enabled
                        ? context.colors.surface
                        : context.colors.surface.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      borderSide: BorderSide(
                        color: context.colors.border,
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      borderSide: BorderSide(
                        color: context.colors.primary,
                        width: 2.0,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      borderSide: BorderSide(
                        color: context.colors.destructive,
                        width: 1.0,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
                      borderSide: BorderSide(
                        color: context.colors.destructive,
                        width: 2.0,
                      ),
                    ),
                    errorStyle: AppTextStyles.caption.copyWith(
                      color: context.colors.destructive,
                    ),
                    counterStyle: AppTextStyles.caption.copyWith(
                      color: context.colors.textSubtle,
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.helperText != null && widget.errorText == null) ...[
            const SizedBox(height: 4.0),
            Text(
              widget.helperText!,
              style: AppTextStyles.caption.copyWith(
                color: context.colors.textSubtle,
              ),
            ),
          ],
          if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
            const SizedBox(height: 4.0),
            AnimatedBuilder(
              animation: _errorAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _errorAnimation.value,
                  child: Text(
                    widget.errorText!,
                    style: AppTextStyles.caption.copyWith(
                      color: context.colors.destructive,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}