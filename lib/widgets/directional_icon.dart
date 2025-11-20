import 'package:flutter/material.dart';

/// A widget that automatically flips directional icons in RTL layout
/// Provides consistent icon behavior across different text directions
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;

  const DirectionalIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final directionality = textDirection ?? Directionality.of(context);
    final isRTL = directionality == TextDirection.rtl;

    // Define icon mappings for RTL flipping
      final Map<IconData, IconData> rtlMappings = {
        Icons.arrow_back: Icons.arrow_forward,
        Icons.arrow_forward: Icons.arrow_back,
        Icons.chevron_left: Icons.chevron_right,
        Icons.chevron_right: Icons.chevron_left,
        Icons.keyboard_arrow_left: Icons.keyboard_arrow_right,
        Icons.keyboard_arrow_right: Icons.keyboard_arrow_left,
        Icons.navigate_before: Icons.navigate_next,
        Icons.navigate_next: Icons.navigate_before,
        Icons.first_page: Icons.last_page,
        Icons.last_page: Icons.first_page,
        Icons.arrow_left: Icons.arrow_right,
        Icons.arrow_right: Icons.arrow_left,
        Icons.chevron_left_rounded: Icons.chevron_right_rounded,
        Icons.chevron_right_rounded: Icons.chevron_left_rounded,
        Icons.keyboard_arrow_left_outlined: Icons.keyboard_arrow_right_outlined,
        Icons.keyboard_arrow_right_outlined: Icons.keyboard_arrow_left_outlined,
        Icons.arrow_back_ios: Icons.arrow_forward_ios,
        Icons.arrow_forward_ios: Icons.arrow_back_ios,
        Icons.arrow_back_ios_new: Icons.arrow_forward_ios,
        // Additional RTL mappings for complete support
        Icons.skip_next: Icons.skip_previous,
        Icons.skip_previous: Icons.skip_next,
        Icons.fast_forward: Icons.fast_rewind,
        Icons.fast_rewind: Icons.fast_forward,
        Icons.rotate_right: Icons.rotate_left,
        Icons.rotate_left: Icons.rotate_right,
        Icons.format_align_left: Icons.format_align_right,
        Icons.format_align_right: Icons.format_align_left,
        Icons.format_textdirection_l_to_r: Icons.format_textdirection_r_to_l,
        Icons.format_textdirection_r_to_l: Icons.format_textdirection_l_to_r,
      };

    final displayIcon = isRTL && rtlMappings.containsKey(icon)
        ? rtlMappings[icon]!
        : icon;

    return Icon(
      displayIcon,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
