import 'package:flutter/material.dart';

/// Consolidated loading state management utility
class LoadingStateManager {
  /// Build loading indicator
  static Widget buildLoadingIndicator({
    double size = 50,
    Color? color,
    double strokeWidth = 3,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? Colors.blue),
      ),
    );
  }

  /// Build loading overlay
  static Widget buildLoadingOverlay({
    required bool isLoading,
    required Widget child,
    Color backgroundColor = const Color(0x80000000),
  }) {
    if (!isLoading) return child;
    
    return Stack(
      children: [
        child,
        Container(
          color: backgroundColor,
          child: Center(
            child: buildLoadingIndicator(),
          ),
        ),
      ],
    );
  }

  /// Build loading button state
  static Widget buildLoadingButton({
    required bool isLoading,
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
    BorderRadius? borderRadius,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Build loading skeleton
  static Widget buildLoadingSkeleton({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double height = 100,
    BorderRadius? borderRadius,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
        child: itemBuilder(context, index),
      ),
    );
  }

  /// Build loading state with message
  static Widget buildLoadingWithMessage({
    required String message,
    double iconSize = 48,
    Color? iconColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildLoadingIndicator(size: iconSize),
        const SizedBox(height: 16),
        Text(message),
      ],
    );
  }

  /// Build conditional loading widget
  static Widget buildConditional({
    required bool isLoading,
    required Widget loadingWidget,
    required Widget child,
  }) {
    return isLoading ? loadingWidget : child;
  }

  /// Build loading state for list
  static Widget buildLoadingList({
    required int itemCount,
    double itemHeight = 80,
    BorderRadius? borderRadius,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Build loading state for grid
  static Widget buildLoadingGrid({
    required int itemCount,
    required int crossAxisCount,
    double itemHeight = 150,
    BorderRadius? borderRadius,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.all(8),
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Check if should show loading
  static bool shouldShowLoading(bool isLoading, bool isEmpty) {
    return isLoading && isEmpty;
  }

  /// Check if should show content
  static bool shouldShowContent(bool isLoading, bool isEmpty) {
    return !isLoading && !isEmpty;
  }

  /// Check if should show empty state
  static bool shouldShowEmpty(bool isLoading, bool isEmpty) {
    return !isLoading && isEmpty;
  }
}
