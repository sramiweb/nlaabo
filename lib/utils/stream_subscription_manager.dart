import 'dart:async';
import 'package:flutter/material.dart';

/// Manages stream subscriptions with automatic cleanup
class StreamSubscriptionManager {
  final List<StreamSubscription> _subscriptions = [];
  bool _disposed = false;

  /// Listen to a stream with automatic error and completion handling
  StreamSubscription<T> listen<T>(
    Stream<T> stream, {
    required void Function(T) onData,
    void Function(dynamic)? onError,
    void Function()? onDone,
    bool cancelOnError = false,
  }) {
    if (_disposed) throw StateError('Manager disposed');

    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    _subscriptions.add(subscription);
    return subscription;
  }

  /// Listen to a stream with reconnection logic
  StreamSubscription<T> listenWithReconnect<T>(
    Stream<T> Function() streamFactory, {
    required void Function(T) onData,
    void Function(dynamic)? onError,
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
  }) {
    int reconnectAttempts = 0;

    StreamSubscription<T>? subscription;

    void setupSubscription() {
      if (_disposed) return;

      subscription = listen(
        streamFactory(),
        onData: onData,
        onError: (error) {
          onError?.call(error);
          if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            Future.delayed(reconnectDelay, setupSubscription);
          }
        },
        onDone: () {
          if (reconnectAttempts < maxReconnectAttempts) {
            reconnectAttempts++;
            Future.delayed(reconnectDelay, setupSubscription);
          }
        },
      );
    }

    setupSubscription();
    return subscription!;
  }

  /// Cancel all subscriptions
  Future<void> cancelAll() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Dispose manager and cleanup
  Future<void> dispose() async {
    _disposed = true;
    await cancelAll();
  }
}
