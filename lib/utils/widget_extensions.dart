import 'package:flutter/material.dart';

/// Extension methods for common widget operations
extension WidgetExtensions on Widget {
  /// Add padding to a widget
  Widget paddingAll(double value) => Padding(
        padding: EdgeInsets.all(value),
        child: this,
      );

  /// Add symmetric padding to a widget
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) =>
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: this,
      );

  /// Add padding with specific values
  Widget padding({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );

  /// Center a widget
  Widget center() => Center(child: this);

  /// Add margin to a widget
  Widget marginAll(double value) => Container(
        margin: EdgeInsets.all(value),
        child: this,
      );

  /// Add margin with specific values
  Widget margin({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      Container(
        margin: EdgeInsets.only(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        child: this,
      );

  /// Make widget clickable with onTap
  Widget onTap(VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: this,
      );

  /// Add rounded corners to a widget
  Widget rounded(double radius) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: this,
      );

  /// Add shadow to a widget
  Widget shadow({
    Color color = Colors.black26,
    double blurRadius = 4,
    Offset offset = const Offset(0, 2),
  }) =>
      Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: blurRadius,
              offset: offset,
            ),
          ],
        ),
        child: this,
      );

  /// Make widget expandable
  Widget expanded({int flex = 1}) => Expanded(
        flex: flex,
        child: this,
      );

  /// Add background color
  Widget background(Color color) => Container(
        color: color,
        child: this,
      );

  /// Add opacity to widget
  Widget opacity(double opacity) => Opacity(
        opacity: opacity,
        child: this,
      );

  /// Add tooltip
  Widget tooltip(String message) => Tooltip(
        message: message,
        child: this,
      );

  /// Make widget scrollable
  Widget scrollable() => SingleChildScrollView(child: this);

  /// Add safe area
  Widget safeArea() => SafeArea(child: this);
}

/// Extension for Text widgets
extension TextExtensions on Text {
  /// Make text bold
  Text bold() => Text(
        data ?? '',
        style: (style ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: textDirection,
        locale: locale,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );

  /// Set text color
  Text color(Color color) => Text(
        data ?? '',
        style: (style ?? const TextStyle()).copyWith(color: color),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: textDirection,
        locale: locale,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );

  /// Set font size
  Text size(double size) => Text(
        data ?? '',
        style: (style ?? const TextStyle()).copyWith(fontSize: size),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: textDirection,
        locale: locale,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );

  /// Set text alignment
  Text align(TextAlign align) => Text(
        data ?? '',
        style: style,
        textAlign: align,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: textDirection,
        locale: locale,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
}

/// Extension for BuildContext
extension BuildContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Check if device is mobile
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Check if device is desktop
  bool get isDesktop => screenWidth >= 1200;

  /// Show snackbar
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  /// Navigate to route
  void navigateTo(String routeName, {Object? arguments}) {
    Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  /// Navigate and replace
  void navigateReplace(String routeName, {Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(routeName, arguments: arguments);
  }

  /// Go back
  void goBack() {
    Navigator.of(this).pop();
  }
}
