import 'package:flutter/material.dart';
import 'responsive_utils.dart';

class OrientationHelper {
  /// Build layout that adapts to orientation
  static Widget buildAdaptiveLayout({
    required BuildContext context,
    required Widget portraitLayout,
    required Widget landscapeLayout,
  }) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape && context.isMobile) {
          return landscapeLayout;
        }
        return portraitLayout;
      },
    );
  }

  /// Get responsive columns for landscape
  static int getLandscapeColumns(BuildContext context) {
    if (context.isMobile) return 2;
    if (context.isTablet) return 3;
    return 4;
  }

  /// Get responsive padding for landscape
  static EdgeInsets getLandscapePadding(BuildContext context) {
    final basePadding = ResponsiveUtils.getResponsivePadding(context);
    if (ResponsiveUtils.isLandscape(context) && context.isMobile) {
      return EdgeInsets.symmetric(
        horizontal: basePadding.left * 0.5,
        vertical: basePadding.top * 0.75,
      );
    }
    return basePadding;
  }

  /// Check if should use compact layout
  static bool shouldUseCompactLayout(BuildContext context) {
    return ResponsiveUtils.isLandscape(context) && context.isMobile;
  }

  /// Get responsive form field layout
  static Widget buildFormFieldLayout({
    required BuildContext context,
    required List<Widget> fields,
  }) {
    if (shouldUseCompactLayout(context) && fields.length >= 2) {
      // Landscape: 2-column layout
      final rows = <Widget>[];
      for (var i = 0; i < fields.length; i += 2) {
        if (i + 1 < fields.length) {
          rows.add(
            Row(
              children: [
                Expanded(child: fields[i]),
                const SizedBox(width: 12),
                Expanded(child: fields[i + 1]),
              ],
            ),
          );
        } else {
          rows.add(fields[i]);
        }
        if (i + 2 < fields.length) {
          rows.add(const SizedBox(height: 10));
        }
      }
      return Column(children: rows);
    }
    
    // Portrait: Standard vertical layout
    final children = <Widget>[];
    for (var i = 0; i < fields.length; i++) {
      children.add(fields[i]);
      if (i < fields.length - 1) {
        children.add(const SizedBox(height: 10));
      }
    }
    return Column(children: children);
  }
}
