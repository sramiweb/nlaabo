import 'package:flutter/material.dart';

/// A utility class to track widget rebuilds for performance monitoring
class RebuildTracker {
  static final Map<String, int> _rebuildCounts = {};
  static final Map<String, DateTime> _lastRebuildTimes = {};

  /// Track a rebuild for a specific widget
  static void trackRebuild(String widgetName) {
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
    _lastRebuildTimes[widgetName] = DateTime.now();
  }

  /// Get rebuild count for a specific widget
  static int getRebuildCount(String widgetName) {
    return _rebuildCounts[widgetName] ?? 0;
  }

  /// Get all rebuild statistics
  static Map<String, dynamic> getRebuildStats() {
    return {
      'counts': Map.from(_rebuildCounts),
      'lastRebuildTimes': Map.from(_lastRebuildTimes),
      'totalRebuilds': _rebuildCounts.values.fold(0, (sum, count) => sum + count),
    };
  }

  /// Reset all tracking data
  static void reset() {
    _rebuildCounts.clear();
    _lastRebuildTimes.clear();
  }

  /// Print rebuild statistics to console (for debugging)
  static void printStats() {
    final stats = getRebuildStats();
    debugPrint('=== Rebuild Statistics ===');
    debugPrint('Total rebuilds: ${stats['totalRebuilds']}');
    stats['counts'].forEach((widget, count) {
      final lastTime = stats['lastRebuildTimes'][widget];
      debugPrint('$widget: $count rebuilds (last: $lastTime)');
    });
  }
}

/// A mixin that can be added to widgets to track rebuilds
mixin RebuildTrackerMixin<T extends StatefulWidget> on State<T> {
  late final String _widgetName;

  @override
  void initState() {
    super.initState();
    _widgetName = T.toString();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    RebuildTracker.trackRebuild(_widgetName);
  }
}

/// A widget that tracks its own rebuilds
class RebuildTrackedWidget extends StatefulWidget {
  final Widget child;
  final String? name;

  const RebuildTrackedWidget({
    super.key,
    required this.child,
    this.name,
  });

  @override
  State<RebuildTrackedWidget> createState() => _RebuildTrackedWidgetState();
}

class _RebuildTrackedWidgetState extends State<RebuildTrackedWidget> {
  late final String _widgetName;

  @override
  void initState() {
    super.initState();
    _widgetName = widget.name ?? 'RebuildTrackedWidget';
  }

  @override
  void didUpdateWidget(RebuildTrackedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    RebuildTracker.trackRebuild(_widgetName);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to easily wrap widgets with rebuild tracking
extension RebuildTrackingExtension on Widget {
  Widget trackRebuilds([String? name]) {
    return RebuildTrackedWidget(
      name: name,
      child: this,
    );
  }
}
