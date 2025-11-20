import 'package:flutter/material.dart';

class ResponsiveOrientationBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) portraitBuilder;
  final Widget Function(BuildContext context) landscapeBuilder;

  const ResponsiveOrientationBuilder({
    super.key,
    required this.portraitBuilder,
    required this.landscapeBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.portrait
            ? portraitBuilder(context)
            : landscapeBuilder(context);
      },
    );
  }
}
