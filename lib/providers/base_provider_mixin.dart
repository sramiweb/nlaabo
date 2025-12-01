import 'package:flutter/material.dart';

/// Mixin providing common provider functionality to reduce code duplication
mixin BaseProviderMixin on ChangeNotifier {
  bool _disposed = false;
  String? _error;
  bool _isLoading = false;

  bool get disposed => _disposed;
  String? get error => _error;
  bool get isLoading => _isLoading;

  /// Set loading state and notify listeners
  void setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error and notify listeners
  void setError(String? error) {
    if (_disposed) return;
    _error = error;
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    if (_disposed) return;
    _error = null;
    notifyListeners();
  }

  /// Execute async operation with loading/error handling
  Future<T> executeAsync<T>(
    Future<T> Function() operation, {
    bool setLoadingState = true,
  }) async {
    if (_disposed) throw StateError('Provider disposed');

    if (setLoadingState) setLoading(true);
    try {
      final result = await operation();
      clearError();
      return result;
    } catch (e) {
      setError(e.toString());
      rethrow;
    } finally {
      if (setLoadingState) setLoading(false);
    }
  }

  /// Remove duplicates from list by ID
  List<T> removeDuplicates<T>(List<T> items, String Function(T) getId) {
    final seen = <String>{};
    return items.where((item) {
      final id = getId(item);
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  /// Handle stream error with reconnection logic
  void handleStreamError(
    dynamic error,
    Future<void> Function() reconnect, {
    Duration reconnectDelay = const Duration(seconds: 3),
  }) {
    if (_disposed) return;
    setError('Connection lost. Attempting to reconnect...');
    Future.delayed(reconnectDelay, () {
      if (!_disposed) reconnect();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
