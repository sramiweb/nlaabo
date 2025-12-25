import 'dart:convert';
import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';
import '../models/match.dart';
import '../models/team.dart';
import 'error_handler.dart';

/// Optimized cache service with performance improvements and error handling
class CacheService {
  static const String _citiesCacheKey = 'cached_cities';
  static const String _userStatsCacheKey = 'cached_user_stats';
  static const String _teamsCacheKey = 'cached_teams';
  static const String _matchesCacheKey = 'cached_matches';
  static const String _homeScreenDataCacheKey = 'cached_home_screen_data';
  static const String _ownersCacheKey = 'cached_owners';
  static const String _ownerErrorsCacheKey = 'cached_owner_errors';

  static const Duration _citiesCacheDuration = Duration(hours: 24);
  static const Duration _userStatsCacheDuration = Duration(minutes: 30);
  static const Duration _teamsCacheDuration = Duration(hours: 2);
  static const Duration _matchesCacheDuration = Duration(minutes: 15);
  static const Duration _homeScreenCacheDuration = Duration(minutes: 5);
  static const Duration _ownersCacheDuration = Duration(hours: 6);
  static const Duration _ownerErrorsCacheDuration = Duration(minutes: 30);

  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late final DefaultCacheManager _imageCacheManager;
  SharedPreferences? _prefs;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, Timer> _refreshTimers = {};

  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _imageCacheManager = DefaultCacheManager();
      await _cleanupExpiredCache();
    } catch (e) {
      ErrorHandler.logError(e, null, 'CacheService.initialize');
    }
  }

  // Memory cache for frequently accessed data
  T? _getFromMemoryCache<T>(String key) {
    final cached = _memoryCache[key];
    if (cached != null && cached['expiry'] != null) {
      if (DateTime.now().isBefore(cached['expiry'])) {
        return cached['data'] as T;
      } else {
        _memoryCache.remove(key);
      }
    }
    return null;
  }

  void _setMemoryCache<T>(String key, T data, Duration duration) {
    _memoryCache[key] = {
      'data': data,
      'expiry': DateTime.now().add(duration),
    };
  }

  // Image caching with error handling
  DefaultCacheManager get imageCacheManager => _imageCacheManager;

  Future<FileInfo?> getCachedImage(String url) async {
    return ErrorHandler.withFallback(
      () => _imageCacheManager.getFileFromCache(url),
      null,
      context: 'CacheService.getCachedImage',
    );
  }

  Future<FileInfo?> downloadAndCacheImage(String url) async {
    return ErrorHandler.withFallback(
      () => _imageCacheManager.downloadFile(url),
      null,
      context: 'CacheService.downloadAndCacheImage',
    );
  }

  Future<void> clearImageCache() async {
    return ErrorHandler.withErrorHandling(
      () => _imageCacheManager.emptyCache(),
      context: 'CacheService.clearImageCache',
      rethrowOnError: false,
    );
  }

  // Optimized persistent cache methods
  Future<void> _setCacheData(String key, dynamic data, DateTime expiry) async {
    if (_prefs == null) return;

    return ErrorHandler.withErrorHandling(
      () async {
        final cacheData = {'data': data, 'expiry': expiry.toIso8601String()};
        await _prefs!.setString(key, jsonEncode(cacheData));

        // Also set in memory cache for faster access
        _setMemoryCache(key, data, expiry.difference(DateTime.now()));
      },
      context: 'CacheService._setCacheData',
      rethrowOnError: false,
    );
  }

  Map<String, dynamic>? _getCacheData(String key) {
    // Try memory cache first
    final memoryData = _getFromMemoryCache<Map<String, dynamic>>(key);
    if (memoryData != null) return memoryData;

    if (_prefs == null) return null;

    try {
      final cachedString = _prefs!.getString(key);
      if (cachedString == null) return null;

      final cacheData = jsonDecode(cachedString);
      final expiry = DateTime.parse(cacheData['expiry']);

      if (DateTime.now().isAfter(expiry)) {
        _prefs!.remove(key);
        return null;
      }

      // Cache in memory for faster future access
      final data = cacheData['data'];
      _setMemoryCache(key, data, expiry.difference(DateTime.now()));
      return data;
    } catch (e) {
      ErrorHandler.logError(e, null, 'CacheService._getCacheData');
      return null;
    }
  }

  // Cities caching with performance optimization
  Future<void> cacheCities(List<City> cities) async {
    final expiry = DateTime.now().add(_citiesCacheDuration);
    await _setCacheData(
      _citiesCacheKey,
      cities.map((c) => c.toJson()).toList(),
      expiry,
    );
  }

  List<City>? getCachedCities() {
    final data = _getCacheData(_citiesCacheKey);
    if (data == null) return null;

    try {
      return (data as List).map((json) => City.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError(e, null, 'CacheService.getCachedCities');
      return null;
    }
  }

  // User stats caching with shorter TTL for real-time data
  Future<void> cacheUserStats(Map<String, dynamic> stats) async {
    final expiry = DateTime.now().add(_userStatsCacheDuration);
    await _setCacheData(_userStatsCacheKey, stats, expiry);
  }

  Map<String, dynamic>? getCachedUserStats() {
    return _getCacheData(_userStatsCacheKey);
  }

  // Teams caching with background refresh
  Future<void> cacheTeams(List<Team> teams) async {
    final expiry = DateTime.now().add(_teamsCacheDuration);
    await _setCacheData(
      _teamsCacheKey,
      teams.map((t) => t.toJson()).toList(),
      expiry,
    );
  }

  List<Team>? getCachedTeams() {
    final data = _getCacheData(_teamsCacheKey);
    if (data == null) return null;

    try {
      return (data as List).map((json) => Team.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError(e, null, 'CacheService.getCachedTeams');
      return null;
    }
  }

  // Matches caching for better performance
  Future<void> cacheMatches(List<Map<String, dynamic>> matches) async {
    final expiry = DateTime.now().add(_matchesCacheDuration);
    await _setCacheData(_matchesCacheKey, matches, expiry);
  }

  List<Map<String, dynamic>>? getCachedMatches() {
    return _getCacheData(_matchesCacheKey) as List<Map<String, dynamic>>?;
  }

  // Smart cache invalidation with background refresh
  Future<void> invalidateCitiesCache() async {
    await _removeCache(_citiesCacheKey);
  }

  Future<void> invalidateUserStatsCache() async {
    await _removeCache(_userStatsCacheKey);
  }

  Future<void> invalidateTeamsCache() async {
    await _removeCache(_teamsCacheKey);
  }

  Future<void> invalidateMatchesCache() async {
    await _removeCache(_matchesCacheKey);
  }

  Future<void> _removeCache(String key) async {
    _memoryCache.remove(key);
    _refreshTimers[key]?.cancel();
    _refreshTimers.remove(key);

    if (_prefs != null) {
      await ErrorHandler.withErrorHandling(
        () => _prefs!.remove(key),
        context: 'CacheService._removeCache',
        rethrowOnError: false,
      );
    }
  }

  // Background refresh with debouncing
  Future<void> refreshCriticalData(
      Future<void> Function() refreshCallback) async {
    const refreshKey = 'critical_data_refresh';

    // Cancel existing timer
    _refreshTimers[refreshKey]?.cancel();

    // Debounce refresh calls
    _refreshTimers[refreshKey] = Timer(const Duration(seconds: 2), () async {
      await ErrorHandler.withErrorHandling(
        refreshCallback,
        context: 'CacheService.refreshCriticalData',
        rethrowOnError: false,
      );
      _refreshTimers.remove(refreshKey);
    });
  }

  // Batch cache operations for better performance
  Future<void> batchCacheUpdate({
    List<City>? cities,
    List<Team>? teams,
    Map<String, dynamic>? userStats,
    List<Map<String, dynamic>>? matches,
  }) async {
    final futures = <Future>[];

    if (cities != null) futures.add(cacheCities(cities));
    if (teams != null) futures.add(cacheTeams(teams));
    if (userStats != null) futures.add(cacheUserStats(userStats));
    if (matches != null) futures.add(cacheMatches(matches));

    await Future.wait(futures);
  }

  // Cache warming with priority
  Future<void> warmCache({
    Future<List<City>> Function()? fetchCities,
    Future<List<Team>> Function()? fetchTeams,
    Future<Map<String, dynamic>> Function()? fetchUserStats,
  }) async {
    final futures = <Future>[];

    // High priority: user stats (needed immediately)
    if (fetchUserStats != null && getCachedUserStats() == null) {
      futures.add(
        ErrorHandler.withErrorHandling(
          () async {
            final stats = await fetchUserStats();
            await cacheUserStats(stats);
          },
          context: 'CacheService.warmCache.userStats',
          rethrowOnError: false,
        ),
      );
    }

    // Medium priority: teams (frequently accessed)
    if (fetchTeams != null && getCachedTeams() == null) {
      futures.add(
        ErrorHandler.withErrorHandling(
          () async {
            final teams = await fetchTeams();
            await cacheTeams(teams);
          },
          context: 'CacheService.warmCache.teams',
          rethrowOnError: false,
        ),
      );
    }

    // Low priority: cities (rarely change)
    if (fetchCities != null && getCachedCities() == null) {
      futures.add(
        ErrorHandler.withErrorHandling(
          () async {
            final cities = await fetchCities();
            await cacheCities(cities);
          },
          context: 'CacheService.warmCache.cities',
          rethrowOnError: false,
        ),
      );
    }

    await Future.wait(futures);
  }

  // Cache maintenance and cleanup
  Future<void> _cleanupExpiredCache() async {
    if (_prefs == null) return;

    await ErrorHandler.withErrorHandling(
      () async {
        final keys = _prefs!
            .getKeys()
            .where((key) => key.startsWith('cached_'))
            .toList();

        for (final key in keys) {
          final cachedString = _prefs!.getString(key);
          if (cachedString != null) {
            try {
              final cacheData = jsonDecode(cachedString);
              final expiry = DateTime.parse(cacheData['expiry']);
              if (DateTime.now().isAfter(expiry)) {
                await _prefs!.remove(key);
              }
            } catch (e) {
              await _prefs!.remove(key);
            }
          }
        }
      },
      context: 'CacheService._cleanupExpiredCache',
      rethrowOnError: false,
    );
  }

  Future<void> invalidateAllCaches() async {
    _memoryCache.clear();
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();

    if (_prefs != null) {
      await ErrorHandler.withErrorHandling(
        () async {
          final keys = _prefs!
              .getKeys()
              .where((key) => key.startsWith('cached_'))
              .toList();
          for (final key in keys) {
            await _prefs!.remove(key);
          }
        },
        context: 'CacheService.invalidateAllCaches',
        rethrowOnError: false,
      );
    }

    await clearImageCache();
  }

  // Cache statistics for monitoring
  Future<Map<String, dynamic>> getCacheStats() async {
    if (_prefs == null) return {'size': 0, 'entries': 0, 'memoryEntries': 0};

    return ErrorHandler.withFallback(
      () async {
        final keys = _prefs!
            .getKeys()
            .where((key) => key.startsWith('cached_'))
            .toList();

        int size = 0;
        int validEntries = 0;

        for (final key in keys) {
          final value = _prefs!.getString(key);
          if (value != null) {
            size += value.length * 2; // Rough estimate in bytes

            try {
              final cacheData = jsonDecode(value);
              final expiry = DateTime.parse(cacheData['expiry']);
              if (DateTime.now().isBefore(expiry)) {
                validEntries++;
              }
            } catch (e) {
              // Invalid entry
            }
          }
        }

        return {
          'size': size,
          'entries': validEntries,
          'memoryEntries': _memoryCache.length,
          'totalKeys': keys.length,
        };
      },
      {'size': 0, 'entries': 0, 'memoryEntries': 0},
      context: 'CacheService.getCacheStats',
    );
  }

  // Offline support with fallbacks
  Future<List<City>> getCitiesWithOfflineSupport() async {
    final cached = getCachedCities();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }
    throw NetworkError('No cached cities available offline');
  }

  Future<Map<String, dynamic>> getUserStatsWithOfflineSupport() async {
    final cached = getCachedUserStats();
    return cached ??
        {'matches_joined': 0, 'matches_created': 0, 'teams_owned': 0};
  }

  // Home screen data caching for matches and teams combined
  Future<void> cacheHomeScreenData({
    required List<Match> matches,
    required List<Team> teams,
  }) async {
    final expiry = DateTime.now().add(_homeScreenCacheDuration);
    await _setCacheData(
      _homeScreenDataCacheKey,
      {
        'matches': matches.map((m) => m.toJson()).toList(),
        'teams': teams.map((t) => t.toJson()).toList(),
      },
      expiry,
    );
  }

  Map<String, dynamic>? getCachedHomeScreenData() {
    return _getCacheData(_homeScreenDataCacheKey);
  }

  Future<void> invalidateHomeScreenCache() async {
    await _removeCache(_homeScreenDataCacheKey);
  }

  // Owner data caching with error state handling
  Future<void> cacheOwner(
      String ownerId, Map<String, dynamic> ownerData) async {
    final expiry = DateTime.now().add(_ownersCacheDuration);
    final ownersCache = _getCacheData(_ownersCacheKey) ?? <String, dynamic>{};

    ownersCache[ownerId] = {
      'data': ownerData,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _setCacheData(_ownersCacheKey, ownersCache, expiry);
  }

  Map<String, dynamic>? getCachedOwner(String ownerId) {
    final ownersCache = _getCacheData(_ownersCacheKey);
    if (ownersCache == null) return null;

    final ownerEntry = ownersCache[ownerId] as Map<String, dynamic>?;
    if (ownerEntry == null) return null;

    // Check if owner data is still valid (within cache duration)
    final cachedAt = DateTime.parse(ownerEntry['cachedAt'] as String);
    if (DateTime.now().difference(cachedAt) > _ownersCacheDuration) {
      // Remove expired entry
      ownersCache.remove(ownerId);
      _setCacheData(_ownersCacheKey, ownersCache,
          DateTime.now().add(_ownersCacheDuration));
      return null;
    }

    return ownerEntry['data'] as Map<String, dynamic>;
  }

  Future<void> cacheOwnerError(String ownerId, String errorMessage) async {
    final expiry = DateTime.now().add(_ownerErrorsCacheDuration);
    final errorsCache =
        _getCacheData(_ownerErrorsCacheKey) ?? <String, dynamic>{};

    errorsCache[ownerId] = {
      'error': errorMessage,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await _setCacheData(_ownerErrorsCacheKey, errorsCache, expiry);
  }

  String? getCachedOwnerError(String ownerId) {
    final errorsCache = _getCacheData(_ownerErrorsCacheKey);
    if (errorsCache == null) return null;

    final errorEntry = errorsCache[ownerId] as Map<String, dynamic>?;
    if (errorEntry == null) return null;

    // Check if error is still valid (within error cache duration)
    final cachedAt = DateTime.parse(errorEntry['cachedAt'] as String);
    if (DateTime.now().difference(cachedAt) > _ownerErrorsCacheDuration) {
      // Remove expired error entry
      errorsCache.remove(ownerId);
      _setCacheData(_ownerErrorsCacheKey, errorsCache,
          DateTime.now().add(_ownerErrorsCacheDuration));
      return null;
    }

    return errorEntry['error'] as String;
  }

  Future<void> invalidateOwnerCache(String ownerId) async {
    final ownersCache = _getCacheData(_ownersCacheKey);
    if (ownersCache != null) {
      ownersCache.remove(ownerId);
      await _setCacheData(_ownersCacheKey, ownersCache,
          DateTime.now().add(_ownersCacheDuration));
    }

    final errorsCache = _getCacheData(_ownerErrorsCacheKey);
    if (errorsCache != null) {
      errorsCache.remove(ownerId);
      await _setCacheData(_ownerErrorsCacheKey, errorsCache,
          DateTime.now().add(_ownerErrorsCacheDuration));
    }
  }

  Future<void> invalidateAllOwnerCaches() async {
    await _removeCache(_ownersCacheKey);
    await _removeCache(_ownerErrorsCacheKey);
  }

  void dispose() {
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();
    _memoryCache.clear();
  }
}
