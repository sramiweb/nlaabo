import 'package:flutter/material.dart';

/// Utility class for building common widget patterns to reduce tree complexity
class WidgetBuilders {
  /// Build a loading skeleton for cards
  static Widget buildCardSkeleton(BuildContext context, {double height = 200}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  /// Build empty state with icon and message
  static Widget buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }

  /// Build filter chip row
  static Widget buildFilterChips(
    BuildContext context, {
    required List<String> labels,
    required List<VoidCallback> onTaps,
    required List<IconData> icons,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(
          labels.length,
          (i) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(labels[i]),
              avatar: Icon(icons[i], size: 18),
              onSelected: (_) => onTaps[i](),
            ),
          ),
        ),
      ),
    );
  }

  /// Build horizontal scrollable list
  static Widget buildHorizontalList(
    BuildContext context, {
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    double? height,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16),
  }) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    );
  }

  /// Build section header with view all button
  static Widget buildSectionHeader(
    BuildContext context, {
    required String title,
    VoidCallback? onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text('View All', style: Theme.of(context).textTheme.labelMedium),
            ),
        ],
      ),
    );
  }

  /// Build loading state with shimmer effect
  static Widget buildLoadingState(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildCardSkeleton(context, height: 56),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: buildCardSkeleton(context, height: 48)),
              const SizedBox(width: 16),
              Expanded(child: buildCardSkeleton(context, height: 48)),
            ],
          ),
          const SizedBox(height: 32),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  /// Build grid view with responsive columns
  static Widget buildResponsiveGrid(
    BuildContext context, {
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required double childAspectRatio,
    double spacing = 16,
  }) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 3 : width > 800 ? 2 : 1;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
