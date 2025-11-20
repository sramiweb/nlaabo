import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/cache_service.dart';

/// Enum for image quality levels based on device capabilities
enum ImageQuality {
  low,    // For low-end devices or slow connections
  medium, // Default quality for most devices
  high,   // For high-end devices with fast connections
}

/// Configuration for progressive loading stages
class ProgressiveStage {
  final double scale;
  final int quality;
  final Duration delay;

  const ProgressiveStage({
    required this.scale,
    required this.quality,
    required this.delay,
  });
}

/// Optimized image loader with progressive loading, WebP preference, adaptive quality, and memory management
class OptimizedImageLoader {
  static const List<ProgressiveStage> _progressiveStages = [
    ProgressiveStage(scale: 0.1, quality: 20, delay: Duration(milliseconds: 100)),
    ProgressiveStage(scale: 0.25, quality: 40, delay: Duration(milliseconds: 200)),
    ProgressiveStage(scale: 0.5, quality: 60, delay: Duration(milliseconds: 300)),
    ProgressiveStage(scale: 1.0, quality: 85, delay: Duration.zero),
  ];

  final CacheService _cacheService = CacheService();

  // Memory management
  static const int _maxMemoryCacheSize = 50 * 1024 * 1024; // 50MB
  final Map<String, Completer<ui.Image?>> _loadingImages = {};
  final Map<String, ui.Image?> _memoryCache = {};
  int _currentMemoryUsage = 0;

  // Device capability detection
  late final ImageQuality _deviceQuality;
  late final bool _supportsWebP;
  late final bool _isSlowConnection;

  OptimizedImageLoader() {
    _initializeDeviceCapabilities();
  }

  void _initializeDeviceCapabilities() {
    // Detect device quality based on platform and memory
    if (kIsWeb) {
      // For web, use screen size and connection to determine quality
      _deviceQuality = _getWebDeviceQuality();
      _supportsWebP = true;
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Check device memory for quality determination
      final deviceMemory = _getDeviceMemory();
      if (deviceMemory < 2) {
        _deviceQuality = ImageQuality.low;
      } else if (deviceMemory < 4) {
        _deviceQuality = ImageQuality.medium;
      } else {
        _deviceQuality = ImageQuality.high;
      }
      _supportsWebP = true;
    } else {
      _deviceQuality = ImageQuality.medium;
      _supportsWebP = false;
    }

    // Detect connection speed (simplified)
    _isSlowConnection = false; // Would need connectivity service integration
  }

  ImageQuality _getWebDeviceQuality() {
    // For web, we can't easily detect memory, so use screen size as proxy
    // This is a simplified approach - in production, you might want to use
    // navigator.deviceMemory or other web APIs if available
    try {
      // Use a default medium quality for web, but could be enhanced
      // with more sophisticated detection
      return ImageQuality.medium;
    } catch (e) {
      return ImageQuality.medium;
    }
  }

  int _getDeviceMemory() {
    // Simplified memory detection - in real implementation would use device_info_plus
    return 4; // Assume 4GB for now
  }

  /// Main method to load an optimized image
  Future<ui.Image?> loadImage(
    String imageUrl, {
    double? width,
    double? height,
    ImageQuality? quality,
    bool enableProgressive = true,
    bool preferWebP = true,
  }) async {
    final cacheKey = _generateCacheKey(imageUrl, width, height, quality ?? _deviceQuality);

    // Check memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    // Check if already loading
    if (_loadingImages.containsKey(cacheKey)) {
      return _loadingImages[cacheKey]!.future;
    }

    final completer = Completer<ui.Image?>();
    _loadingImages[cacheKey] = completer;

    try {
      ui.Image? image;

      if (enableProgressive && _shouldUseProgressive(imageUrl)) {
        image = await _loadProgressively(imageUrl, width, height, quality ?? _deviceQuality);
      } else {
        image = await _loadOptimizedImage(imageUrl, width, height, quality ?? _deviceQuality, preferWebP);
      }

      // Cache in memory if not too large
      if (image != null && _shouldCacheInMemory(image)) {
        _memoryCache[cacheKey] = image;
        _currentMemoryUsage += _estimateImageSize(image);
        _cleanupMemoryCacheIfNeeded();
      }

      completer.complete(image);
      return image;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _loadingImages.remove(cacheKey);
    }
  }

  /// Progressive loading implementation
  Future<ui.Image?> _loadProgressively(
    String imageUrl,
    double? width,
    double? height,
    ImageQuality quality,
  ) async {
    ui.Image? finalImage;

    for (final stage in _progressiveStages) {
      try {
        final optimizedUrl = _getOptimizedUrl(imageUrl, width, height, quality, stage);
        final image = await _downloadAndDecodeImage(optimizedUrl);

        if (image != null) {
          finalImage = image;

          // For intermediate stages, we could emit partial results
          // This would require a stream-based API

          // Wait for the specified delay before next stage
          if (stage.delay > Duration.zero) {
            await Future.delayed(stage.delay);
          }
        }
      } catch (e) {
        // Continue to next stage if current fails
        continue;
      }
    }

    return finalImage;
  }

  /// Load optimized image with WebP preference and adaptive quality
  Future<ui.Image?> _loadOptimizedImage(
    String imageUrl,
    double? width,
    double? height,
    ImageQuality quality,
    bool preferWebP,
  ) async {
    // Try WebP first if preferred and supported
    if (preferWebP && _supportsWebP && _shouldUseWebP(imageUrl)) {
      final webpUrl = _convertToWebPUrl(imageUrl);
      try {
        final image = await _downloadAndDecodeImage(webpUrl);
        if (image != null) return image;
      } catch (e) {
        // Fall back to original format
      }
    }

    // Load with adaptive quality
    final optimizedUrl = _getOptimizedUrl(imageUrl, width, height, quality);
    return await _downloadAndDecodeImage(optimizedUrl);
  }

  /// Download and decode image with caching
  Future<ui.Image?> _downloadAndDecodeImage(String url) async {
    try {
      // Check cache first
      final cachedFile = await _cacheService.getCachedImage(url);
      if (cachedFile != null) {
        final bytes = await cachedFile.file.readAsBytes();
        return await _decodeImageFromBytes(bytes);
      }

      // Download with timeout and retry logic
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        // Cache the downloaded image
        await _cacheService.downloadAndCacheImage(url);

        return await _decodeImageFromBytes(response.bodyBytes);
      }
    } catch (e) {
      // Handle network errors, timeouts, etc.
      debugPrint('Failed to load image: $url, error: $e');
    }

    return null;
  }

  /// Decode image from bytes with memory management
  Future<ui.Image?> _decodeImageFromBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Failed to decode image: $e');
      return null;
    }
  }

  /// Generate optimized URL based on quality and dimensions
  String _getOptimizedUrl(
    String originalUrl,
    double? width,
    double? height,
    ImageQuality quality, [
    ProgressiveStage? stage,
  ]) {
    final params = <String, String>{};

    // Add dimensions if specified
    if (width != null) params['w'] = width.round().toString();
    if (height != null) params['h'] = height.round().toString();

    // Add quality parameter
    final qualityValue = _getQualityValue(quality, stage);
    params['q'] = qualityValue.toString();

    // Add format preference
    if (_supportsWebP) {
      params['f'] = 'webp';
    }

    // For progressive stages, add scale parameter
    if (stage != null) {
      params['s'] = stage.scale.toString();
    }

    // Check if URL already has query parameters
    final separator = originalUrl.contains('?') ? '&' : '?';
    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');

    return '$originalUrl$separator$queryString';
  }

  /// Convert URL to WebP format
  String _convertToWebPUrl(String url) {
    // This would depend on the image service being used
    // For example, if using Cloudinary, Imgix, or similar
    return url.replaceAll('.jpg', '.webp').replaceAll('.jpeg', '.webp').replaceAll('.png', '.webp');
  }

  /// Get quality value based on device capabilities and progressive stage
  int _getQualityValue(ImageQuality quality, [ProgressiveStage? stage]) {
    if (stage != null) {
      return stage.quality;
    }

    switch (quality) {
      case ImageQuality.low:
        return _isSlowConnection ? 60 : 70;
      case ImageQuality.medium:
        return 80;
      case ImageQuality.high:
        return 90;
    }
  }

  /// Determine if progressive loading should be used
  bool _shouldUseProgressive(String imageUrl) {
    // Use progressive loading for large images or slow connections
    return !_isSlowConnection && _isLargeImage(imageUrl);
  }

  /// Determine if WebP should be used
  bool _shouldUseWebP(String imageUrl) {
    // Use WebP for supported formats and when beneficial
    return _supportsWebP && !_isAnimatedGif(imageUrl);
  }

  /// Check if image is likely to be large
  bool _isLargeImage(String imageUrl) {
    // This could be enhanced with image metadata or URL patterns
    return true; // Assume progressive loading for all images for now
  }

  /// Check if image is an animated GIF
  bool _isAnimatedGif(String imageUrl) {
    return imageUrl.toLowerCase().contains('.gif');
  }

  /// Generate cache key for memory caching
  String _generateCacheKey(String url, double? width, double? height, ImageQuality quality) {
    return '$url-${width?.round()}-${height?.round()}-${quality.name}';
  }

  /// Determine if image should be cached in memory
  bool _shouldCacheInMemory(ui.Image image) {
    final estimatedSize = _estimateImageSize(image);
    return estimatedSize < _maxMemoryCacheSize * 0.1; // Max 10% of cache for single image
  }

  /// Estimate image size in bytes
  int _estimateImageSize(ui.Image image) {
    // Rough estimation: 4 bytes per pixel (RGBA)
    return image.width * image.height * 4;
  }

  /// Cleanup memory cache when limit exceeded
  void _cleanupMemoryCacheIfNeeded() {
    if (_currentMemoryUsage <= _maxMemoryCacheSize) return;

    // Remove oldest entries (simplified LRU)
    final entriesToRemove = <String>[];
    var freedMemory = 0;

    for (final entry in _memoryCache.entries) {
      if (entry.value != null) {
        final size = _estimateImageSize(entry.value!);
        entriesToRemove.add(entry.key);
        freedMemory += size;

        if (_currentMemoryUsage - freedMemory <= _maxMemoryCacheSize * 0.8) {
          break;
        }
      }
    }

    for (final key in entriesToRemove) {
      final image = _memoryCache.remove(key);
      if (image != null) {
        _currentMemoryUsage -= _estimateImageSize(image);
      }
    }
  }

  /// Clear memory cache
  void clearMemoryCache() {
    _memoryCache.clear();
    _currentMemoryUsage = 0;
  }

  /// Get current memory usage
  int get currentMemoryUsage => _currentMemoryUsage;

  /// Get memory cache size limit
  int get maxMemoryCacheSize => _maxMemoryCacheSize;
}
