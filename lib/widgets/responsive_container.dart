import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// A responsive container that adapts its layout based on screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget? mobileChild;
  final Widget? tabletChild;
  final Widget? desktopChild;
  final Widget? ultraWideChild;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final Decoration? decoration;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    this.mobileChild,
    this.tabletChild,
    this.desktopChild,
    this.ultraWideChild,
    this.padding,
    this.constraints,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    final effectivePadding = padding ?? ResponsiveUtils.getResponsivePadding(context);

    Widget? child;
    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
      case ScreenSize.smallMobile:
      case ScreenSize.largeMobile:
        child = mobileChild;
        break;
      case ScreenSize.tablet:
        child = tabletChild ?? mobileChild;
        break;
      case ScreenSize.smallDesktop:
        child = desktopChild ?? tabletChild ?? mobileChild;
        break;
      case ScreenSize.desktop:
        child = desktopChild ?? tabletChild ?? mobileChild;
        break;
      case ScreenSize.ultraWide:
        child = ultraWideChild ?? desktopChild ?? tabletChild ?? mobileChild;
        break;
    }

    return Container(
      padding: effectivePadding,
      constraints: constraints ?? BoxConstraints(
        maxWidth: ResponsiveUtils.getMaxContentWidth(context),
      ),
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }
}

/// A responsive row that adapts to different screen sizes
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = ResponsiveUtils.getItemSpacing(context);
    final effectivePadding = padding ?? ResponsiveUtils.getResponsiveHorizontalPadding(context);

    return Padding(
      padding: effectivePadding,
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children.expand((child) => [
          child,
          if (children.last != child) SizedBox(width: effectiveSpacing),
        ]).toList(),
      ),
    );
  }
}

/// A responsive column that adapts to different screen sizes
class ResponsiveColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = ResponsiveUtils.getItemSpacing(context);
    final effectivePadding = padding ?? ResponsiveUtils.getResponsivePadding(context);

    return Padding(
      padding: effectivePadding,
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children.expand((child) => [
          child,
          if (children.last != child) SizedBox(height: effectiveSpacing),
        ]).toList(),
      ),
    );
  }
}

/// A responsive card that adapts its layout and sizing
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? color;
  final BoxShadow? shadow;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.elevation,
    this.margin,
    this.padding,
    this.borderRadius,
    this.color,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveElevation = elevation ?? context.cardElevation;
    final effectiveMargin = margin ?? EdgeInsets.all(ResponsiveUtils.getItemSpacing(context) / 2);
    final effectivePadding = padding ?? ResponsiveUtils.getResponsivePadding(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(context.borderRadius);

    return Card(
      elevation: effectiveElevation,
      margin: effectiveMargin,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveBorderRadius,
      ),
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );
  }
}

/// A responsive layout builder for complex responsive layouts
class ResponsiveLayoutBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize screenSize) builder;

  const ResponsiveLayoutBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);
    return builder(context, screenSize);
  }
}

/// Extension methods for responsive layout helpers
extension ResponsiveLayoutExtensions on Widget {
  /// Wrap with responsive container
  Widget responsiveContainer({
    EdgeInsetsGeometry? padding,
    BoxConstraints? constraints,
    Decoration? decoration,
    AlignmentGeometry? alignment,
  }) {
    return ResponsiveContainer(
      mobileChild: this,
      padding: padding,
      constraints: constraints,
      decoration: decoration,
      alignment: alignment,
    );
  }

  /// Wrap with responsive card
  Widget responsiveCard({
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? color,
  }) {
    return ResponsiveCard(
      elevation: elevation,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      color: color,
      child: this,
    );
  }
}