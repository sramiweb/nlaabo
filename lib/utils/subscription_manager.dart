import 'dart:async';

/// Manages multiple subscriptions for proper cleanup
class SubscriptionManager {
  final List<StreamSubscription> _subscriptions = [];
  bool _disposed = false;

  /// Add a subscription to be managed
  void addSubscription(StreamSubscription subscription) {
    if (_disposed) {
      subscription.cancel();
      return;
    }
    _subscriptions.add(subscription);
  }

  /// Cancel all subscriptions
  Future<void> cancelAll() async {
    if (_disposed) return;
    
    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    _subscriptions.clear();
    _disposed = true;
  }

  /// Get number of active subscriptions
  int get activeSubscriptionCount => _subscriptions.length;

  /// Check if disposed
  bool get isDisposed => _disposed;
}
