import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../utils/responsive_utils.dart';
import 'required_field_indicator.dart';

/// A wrapper widget that provides consistent form field styling with
/// required field indicators and validation support.
class FormFieldWrapper extends StatelessWidget {
  /// The form field widget to wrap (TextFormField, DropdownButtonFormField, etc.)
  final Widget child;

  /// The label text for the form field
  final String? labelText;

  /// Whether this field is required (shows red asterisk)
  final bool required;

  /// Error text to display below the field
  final String? errorText;

  /// Helper text to display below the field
  final String? helperText;

  /// Additional padding around the wrapper
  final EdgeInsetsGeometry? padding;

  /// Custom maximum width (uses responsive defaults if null)
  final double? maxWidth;

  /// Whether to center the form field horizontally
  final bool centered;

  /// Semantic label for accessibility
  final String? semanticLabel;

  const FormFieldWrapper({
    super.key,
    required this.child,
    this.labelText,
    this.required = false,
    this.errorText,
    this.helperText,
    this.padding,
    this.maxWidth,
    this.centered = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? ResponsiveUtils.getFormFieldWidth(context);
    final effectivePadding = padding ?? const EdgeInsets.only(bottom: DesignSystem.fieldSpacing);

    // Build the label with required indicator if needed
    Widget? labelWidget;
    if (labelText != null) {
      labelWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelText!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: errorText != null
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (required) ...[
            const SizedBox(width: DesignSystem.spacingXs),
            const RequiredFieldIndicator(),
          ],
        ],
      );
    }

    // Build the helper/error text
    Widget? helperErrorWidget;
    if (errorText != null || helperText != null) {
      helperErrorWidget = Text(
        errorText ?? helperText!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: errorText != null
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Build the main content
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelWidget != null) ...[
          labelWidget,
          const SizedBox(height: DesignSystem.spacingXs),
        ],
        Container(
          constraints: BoxConstraints(
            maxWidth: effectiveMaxWidth,
          ),
          child: child,
        ),
        if (helperErrorWidget != null) ...[
          const SizedBox(height: DesignSystem.spacingXs),
          helperErrorWidget,
        ],
      ],
    );

    // Apply padding
    content = Padding(
      padding: effectivePadding,
      child: content,
    );

    // Apply centering if requested
    if (centered) {
      content = Center(
        child: content,
      );
    }

    // Apply semantic information
    if (semanticLabel != null) {
      content = Semantics(
        label: semanticLabel,
        child: content,
      );
    }

    return content;
  }
}

/// Extension method to easily wrap form fields with FormFieldWrapper
extension FormFieldWrapperExtension on Widget {
  /// Wrap this form field with FormFieldWrapper for consistent styling
  Widget withFormFieldWrapper({
    String? labelText,
    bool required = false,
    String? errorText,
    String? helperText,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
    bool centered = false,
    String? semanticLabel,
  }) {
    return FormFieldWrapper(
      labelText: labelText,
      required: required,
      errorText: errorText,
      helperText: helperText,
      padding: padding,
      maxWidth: maxWidth,
      centered: centered,
      semanticLabel: semanticLabel,
      child: this,
    );
  }
}
