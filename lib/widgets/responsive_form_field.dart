import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/design_system.dart';

/// Enum for form field variants
enum FormFieldVariant {
  /// Standard text input field
  text,

  /// Email input field
  email,

  /// Password input field with visibility toggle
  password,

  /// Search input field with search icon
  search,

  /// Multi-line text area
  textarea,
}

/// A comprehensive form field widget that implements the FootConnect design system
/// with proper heights (48-52px), styling, focus states, and responsive behavior.
class FootConnectFormField extends StatefulWidget {
  /// The controller for the text field
  final TextEditingController? controller;

  /// The hint text to display
  final String? hintText;

  /// The label text
  final String? labelText;

  /// The error text to display
  final String? errorText;

  /// The helper text to display
  final String? helperText;

  /// The prefix icon
  final IconData? prefixIcon;

  /// The suffix icon
  final IconData? suffixIcon;

  /// The variant of the form field
  final FormFieldVariant variant;

  /// Whether the field is required
  final bool required;

  /// Whether the field is read-only
  final bool readOnly;

  /// Whether the field is enabled
  final bool enabled;

  /// The keyboard type
  final TextInputType? keyboardType;

  /// The text input action
  final TextInputAction? textInputAction;

  /// The maximum length of the input
  final int? maxLength;

  /// The maximum number of lines (for textarea)
  final int? maxLines;

  /// The minimum number of lines (for textarea)
  final int? minLines;

  /// The validator function
  final String? Function(String?)? validator;

  /// The callback when text changes
  final void Function(String)? onChanged;

  /// The callback when field is submitted
  final void Function(String)? onSubmitted;

  /// The callback when field is tapped
  final void Function()? onTap;

  /// Custom width override
  final double? width;

  /// Custom height override
  final double? height;

  const FootConnectFormField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.variant = FormFieldVariant.text,
    this.required = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<FootConnectFormField> createState() => _FootConnectFormFieldState();
}

class _FootConnectFormFieldState extends State<FootConnectFormField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _borderAnimation;
  late FocusNode _focusNode;
  bool _obscureText = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: FootConnectAnimations.standardDuration,
      vsync: this,
    );
    _borderAnimation = Tween<double>(
      begin: 1.5,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: FootConnectAnimations.materialCurve,
    ));

    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void didUpdateWidget(FootConnectFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = widget.height ?? _getFieldHeight(context);
    final effectiveWidth = widget.width ?? _getFieldWidth(context);

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.labelText != null) _buildLabel(context),
          AnimatedBuilder(
            animation: _borderAnimation,
            builder: (context, child) {
              return Container(
                decoration: _getFieldDecoration(context),
                child: _buildTextField(context),
              );
            },
          ),
          if (widget.helperText != null && !_hasError)
            _buildHelperText(context),
          if (_hasError) _buildErrorText(context),
        ],
      ),
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            widget.labelText!,
            style: FootConnectTypography.bodyRegularStyle.copyWith(
              color: FootConnectColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.required)
            Text(
              ' *',
              style: FootConnectTypography.bodyRegularStyle.copyWith(
                color: FootConnectColors.errorRed,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final isPasswordField = widget.variant == FormFieldVariant.password;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: isPasswordField ? _obscureText : false,
      keyboardType: _getKeyboardType(),
      textInputAction: widget.textInputAction,
      maxLength: widget.maxLength,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      style: FootConnectTypography.bodyRegularStyle.copyWith(
        color: FootConnectColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: FootConnectTypography.bodyRegularStyle.copyWith(
          color: FootConnectColors.textTertiary,
        ),
        prefixIcon: _buildPrefixIcon(),
        suffixIcon: _buildSuffixIcon(),
        border: InputBorder.none,
        contentPadding: _getContentPadding(),
        counterText: '', // Hide character counter
      ),
    );
  }

  Widget? _buildPrefixIcon() {
    if (widget.variant == FormFieldVariant.search) {
      return const Icon(
        Icons.search,
        color: FootConnectColors.neutralGray,
        size: 20.0,
      );
    }
    if (widget.prefixIcon != null) {
      return Icon(
        widget.prefixIcon,
        color: FootConnectColors.neutralGray,
        size: 20.0,
      );
    }
    return null;
  }

  Widget? _buildSuffixIcon() {
    if (widget.variant == FormFieldVariant.password) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: FootConnectColors.neutralGray,
          size: 20.0,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        tooltip: 'Toggle password visibility',
      );
    }
    if (widget.suffixIcon != null) {
      return Icon(
        widget.suffixIcon,
        color: FootConnectColors.neutralGray,
        size: 20.0,
      );
    }
    return null;
  }

  Widget _buildHelperText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        widget.helperText!,
        style: FootConnectTypography.bodySmallStyle.copyWith(
          color: FootConnectColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildErrorText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        widget.errorText!,
        style: FootConnectTypography.bodySmallStyle.copyWith(
          color: FootConnectColors.errorRed,
        ),
      ),
    );
  }

  BoxDecoration _getFieldDecoration(BuildContext context) {
    final borderColor = _getBorderColor();
    final borderWidth = _focusNode.hasFocus ? _borderAnimation.value : 1.5;

    return BoxDecoration(
      color: widget.enabled
          ? FootConnectColors.backgroundPrimary
          : FootConnectColors.backgroundTertiary,
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(FootConnectBorderRadius.input),
      boxShadow: _focusNode.hasFocus && !_hasError
          ? [
              BoxShadow(
                color: FootConnectColors.primaryBlue.withValues(alpha: 0.1),
                offset: const Offset(0, 0),
                blurRadius: 4.0,
              ),
            ]
          : null,
    );
  }

  Color _getBorderColor() {
    if (_hasError) {
      return FootConnectColors.errorRed;
    }
    if (_focusNode.hasFocus) {
      return FootConnectColors.primaryBlue;
    }
    return FootConnectColors.neutralGray.withValues(alpha: 0.3);
  }

  EdgeInsets _getContentPadding() {
    final hasPrefix =
        widget.prefixIcon != null || widget.variant == FormFieldVariant.search;
    final hasSuffix = widget.suffixIcon != null ||
        widget.variant == FormFieldVariant.password;

    // Reduced padding for more compact design
    return EdgeInsets.only(
      left: hasPrefix ? 10.0 : 14.0,
      right: hasSuffix ? 10.0 : 14.0,
      top: 10.0,
      bottom: 10.0,
    );
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) {
      return widget.keyboardType!;
    }

    switch (widget.variant) {
      case FormFieldVariant.email:
        return TextInputType.emailAddress;
      case FormFieldVariant.textarea:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  double _getFieldHeight(BuildContext context) {
    if (widget.height != null) return widget.height!;

    final screenSize = ResponsiveUtils.getScreenSize(context);
    double baseHeight;

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        baseHeight = 44.0; // Mobile: 44px
        break;
      case ScreenSize.tablet:
        baseHeight = 46.0; // Tablet: 46px
        break;
      case ScreenSize.smallDesktop:
      case ScreenSize.desktop:
      case ScreenSize.ultraWide:
        baseHeight = 48.0; // Desktop: 48px
        break;
    }

    // Adjust for multi-line fields
    if ((widget.maxLines ?? 1) > 1) {
      return baseHeight +
          ((widget.maxLines! - 1) *
              16.0); // Reduced line height for compactness
    }

    return baseHeight;
  }

  double _getFieldWidth(BuildContext context) {
    if (widget.width != null) return widget.width!;

    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        return double.infinity;
      case ScreenSize.tablet:
        return 350.0;
      case ScreenSize.smallDesktop:
        return 450.0;
      case ScreenSize.desktop:
        return 480.0;
      case ScreenSize.ultraWide:
        return 500.0;
    }
  }
}

/// Legacy wrapper for backward compatibility
/// TODO: Gradually migrate to FootConnectFormField
class ResponsiveFormField extends StatelessWidget {
  final Widget child;
  final bool centered;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveFormField({
    super.key,
    required this.child,
    this.centered = false,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth =
        maxWidth ?? ResponsiveUtils.getFormFieldWidth(context);
    final effectivePadding = padding ?? EdgeInsets.zero;

    Widget constrainedChild = Container(
      constraints: BoxConstraints(
        maxWidth: effectiveMaxWidth,
      ),
      child: child,
    );

    // Apply padding if provided
    if (effectivePadding != EdgeInsets.zero) {
      constrainedChild = Padding(
        padding: effectivePadding,
        child: constrainedChild,
      );
    }

    // Center the form field if requested
    if (centered) {
      constrainedChild = Center(
        child: constrainedChild,
      );
    }

    return constrainedChild;
  }
}

/// Extension method to easily wrap any widget with responsive form field constraints
extension ResponsiveFormFieldExtension on Widget {
  /// Wrap this widget with responsive form field constraints
  Widget asResponsiveFormField({
    bool centered = false,
    double? maxWidth,
    EdgeInsetsGeometry? padding,
  }) {
    return ResponsiveFormField(
      centered: centered,
      maxWidth: maxWidth,
      padding: padding,
      child: this,
    );
  }
}
