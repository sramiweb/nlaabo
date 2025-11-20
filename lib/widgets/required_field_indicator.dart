import 'package:flutter/material.dart';

/// A widget that displays a red asterisk (*) to indicate required fields.
class RequiredFieldIndicator extends StatelessWidget {
  const RequiredFieldIndicator({super.key});

  /// Static text representation for inline usage
  static const String text = '*';

  @override
  Widget build(BuildContext context) {
    return const Text(
      text,
      style: TextStyle(
        color: Colors.red,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
