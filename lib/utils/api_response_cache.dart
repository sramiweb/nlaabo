import 'dart:async';
import 'package:flutter/foundation.dart';

/// Cache entry with TTL support
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration ttl;

  CacheEntry(this.data, {this.ttl = const Duration(minutes: 5)})
      : createdAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;
}

/// Centralized API response caching utility
class ApiResponseCache {
  static final ApiResponseCache _instance = ApiResponseCache._internal();

  factory ApiResponseCache() => _instance;

  ApiResponseCache._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Map<String, Timer> _timers = {};

  /// Cache a response with optional TTL
  void cache<T>(
    String key,
    T data, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    _cache[key] = CacheEntry(data, ttl: ttl);
    _scheduleExpiration(key, ttl);
  }

  /// Get cached response if not expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      invalidate(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      invalidate(key);
      return false;
    }
    return true;
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Invalidate all cache entries matching pattern
  void invalidatePattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    for (final key in keysToRemove) {
      invalidate(key);
    }
  }

  /// Clear all cache
  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _cache.clear();
    _timers.clear();
  }

  /// Schedule automatic expiration
  void _scheduleExpiration(String key, Duration ttl) {
    _timers[key]?.cancel();
    _timers[key] = Timer(ttl, () => invalidate(key));
  }

  /// Get cache size
  int get size => _cache.length;

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int expiredCount = 0;
    for (final entry in _cache.values) {
      if (entry.isExpired) expiredCount++;
    }
    return {
      'total': _cache.length,
      'expired': expiredCount,
      'active': _cache.length - expiredCount,
    };
  }
}

/// Mixin for API methods to support caching
mixin CacheableMixin {
  final _cache = ApiResponseCache();

  /// Execute operation with caching
  Future<T> withCache<T>(
    String cacheKey,
    Future<T> Function() operation, {
    Duration ttl = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    // Return cached value if available and not forcing refresh
    if (!forceRefresh) {
      final cached = _cache.get<T>(cacheKey);
      if (cached != null) return cached;
    }

    // Execute operation
    final result = await operation();

    // Cache result
    _cache.cache(cacheKey, result, ttl: ttl);

    return result;
  }

  /// Invalidate cache for key
  void invalidateCache(String key) => _cache.invalidate(key);

  /// Invalidate cache matching pattern
  void invalidateCachePattern(String pattern) => _cache.invalidatePattern(pattern);

  /// Clear all cache
  void clearCache() => _cache.clear();
}

/// Helper for common cache key patterns
class CacheKeys {
  static String user(String userId) => 'user:$userId';
  static String team(String teamId) => 'team:$teamId';
  static String match(String matchId) => 'match:$matchId';
  static String teams({int? limit, int? offset}) =>
      'teams:limit=${limit ?? "all"}:offset=${offset ?? 0}';
  static String matches({int? limit, int? offset}) =>
      'matches:limit=${limit ?? "all"}:offset=${offset ?? 0}';
  static String userTeams(String userId) => 'user_teams:$userId';
  static String teamMembers(String teamId) => 'team_members:$teamId';
  static String matchPlayers(String matchId) => 'match_players:$matchId';
  static String cities() => 'cities:all';
  static String userStats(String userId) => 'user_stats:$userId';
  static String notifications(String userId) => 'notifications:$userId';
}

/// Cache invalidation strategy
class CacheInvalidationStrategy {
  /// Invalidate related caches when user data changes
  static void onUserUpdate(String userId) {
    final cache = ApiResponseCache();
    cache.invalidate(CacheKeys.user(userId));
    cache.invalidate(CacheKeys.userStats(userId));
    cache.invalidatePattern('user_teams:$userId');
  }

  /// Invalidate related caches when team data changes
  static void onTeamUpdate(String teamId) {
    final cache = ApiResponseCache();
    cache.invalidate(CacheKeys.team(teamId));
    cache.invalidatePattern('team_members:$teamId');
    cache.invalidatePattern('teams:');
  }

  /// Invalidate related caches when match data changes
  static void onMatchUpdate(String matchId) {
    final cache = ApiResponseCache();
    cache.invalidate(CacheKeys.match(matchId));
    cache.invalidatePattern('match_players:$matchId');
    cache.invalidatePattern('matches:');
  }

  /// Invalidate all caches (full refresh)
  static void invalidateAll() {
    ApiResponseCache().clear();
  }
}
