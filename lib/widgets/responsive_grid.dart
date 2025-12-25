import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// A responsive grid widget that adapts to different screen sizes
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double childAspectRatio;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio = 1.0,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveUtils.getGridCrossAxisCount(context);

        return GridView.builder(
          padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// A responsive grid view for horizontal scrolling content
class ResponsiveHorizontalGrid extends StatelessWidget {
  final List<Widget> children;
  final double itemWidth;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveHorizontalGrid({
    super.key,
    required this.children,
    required this.itemWidth,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.horizontalListHeight,
      padding:
          padding ?? ResponsiveUtils.getResponsiveHorizontalPadding(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (context, index) => SizedBox(
          width: itemWidth,
          child: children[index],
        ),
      ),
    );
  }
}

/// A responsive masonry-style grid for varying content heights
class ResponsiveMasonryGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveMasonryGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.spacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveCrossAxisCount = ResponsiveUtils.getGridCrossAxisCount(
      context,
      tabletCount: crossAxisCount,
      desktopCount: crossAxisCount + 1,
      ultraWideCount: crossAxisCount + 2,
    );

    return GridView.builder(
      padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsiveCrossAxisCount,
        childAspectRatio: 0.8, // Allow varying heights
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Extension methods for responsive grid layouts
extension ResponsiveGridExtension on List<Widget> {
  /// Convert list to responsive grid
  Widget toResponsiveGrid({
    double childAspectRatio = 1.0,
    double spacing = 16.0,
    EdgeInsetsGeometry? padding,
  }) {
    return ResponsiveGrid(
      childAspectRatio: childAspectRatio,
      spacing: spacing,
      padding: padding,
      children: this,
    );
  }

  /// Convert list to responsive horizontal grid
  Widget toResponsiveHorizontalGrid({
    required double itemWidth,
    double spacing = 16.0,
    EdgeInsetsGeometry? padding,
  }) {
    return ResponsiveHorizontalGrid(
      itemWidth: itemWidth,
      spacing: spacing,
      padding: padding,
      children: this,
    );
  }
}
