/// Simple rate limiter for client-side throttling
class RateLimiter {
  final Map<String, DateTime> _lastAttempts = {};
  
  /// Check if an operation can be attempted
  bool canAttempt(String key, Duration cooldown) {
    final last = _lastAttempts[key];
    if (last == null) {
      _lastAttempts[key] = DateTime.now();
      return true;
    }
    
    if (DateTime.now().difference(last) > cooldown) {
      _lastAttempts[key] = DateTime.now();
      return true;
    }
    
    return false;
  }

  /// Get remaining cooldown time
  Duration? getRemainingCooldown(String key, Duration cooldown) {
    final last = _lastAttempts[key];
    if (last == null) return null;
    
    final remaining = cooldown - DateTime.now().difference(last);
    return remaining.isNegative ? null : remaining;
  }

  /// Reset a specific key
  void reset(String key) {
    _lastAttempts.remove(key);
  }

  /// Reset all keys
  void resetAll() {
    _lastAttempts.clear();
  }
}

/// Global rate limiter instance
final globalRateLimiter = RateLimiter();
