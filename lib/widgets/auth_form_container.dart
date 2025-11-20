import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// A reusable container for authentication forms
class AuthFormContainer extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final bool isLargeScreen;

  const AuthFormContainer({
    super.key,
    required this.children,
    this.padding,
    this.maxWidth,
    this.isLargeScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaPadding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight - safeAreaPadding.top - safeAreaPadding.bottom;
    final responsiveMaxWidth = maxWidth ?? ResponsiveUtils.getFormFieldWidth(context);

    return SingleChildScrollView(
      padding: padding ?? context.responsivePadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: availableHeight,
          maxWidth: responsiveMaxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
