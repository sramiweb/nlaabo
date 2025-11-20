import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../services/cache_service.dart';
import '../utils/responsive_utils.dart';

/// A widget that displays cached images with proper error handling and loading states
class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool showLoadingIndicator;
  final Duration? cacheDuration;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.showLoadingIndicator = true,
    this.cacheDuration,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  late final CacheService _cacheService;
  FileInfo? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _cacheService = CacheService();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations if needed
    super.dispose();
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Try to get from cache first
      _cachedFile = await _cacheService.getCachedImage(widget.imageUrl);

      // If not in cache or cache is expired, download and cache
      if (_cachedFile == null ||
          (_cachedFile!.validTill.isBefore(DateTime.now()))) {
        _cachedFile = await _cacheService.downloadAndCacheImage(
          widget.imageUrl,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultPlaceholder();
    }

    if (_isLoading && widget.showLoadingIndicator) {
      return widget.placeholder ?? _buildLoadingPlaceholder();
    }

    if (_cachedFile != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.file(
          _cachedFile!.file,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildDefaultPlaceholder();
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image.network(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.placeholder ?? _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildDefaultPlaceholder();
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveWidth = widget.width ?? constraints.maxWidth;
        final responsiveHeight = widget.height ?? constraints.maxHeight;
        final indicatorSize = ResponsiveUtils.getIconSize(context, 24);

        return Container(
          width: responsiveWidth > 0 ? responsiveWidth : null,
          height: responsiveHeight > 0 ? responsiveHeight : null,
          constraints: BoxConstraints(
            minWidth: ResponsiveUtils.getIconSize(context, 40),
            minHeight: ResponsiveUtils.getIconSize(context, 40),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[200]!,
                Colors.grey[100]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: widget.borderRadius,
          ),
          child: Center(
            child: SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveWidth = widget.width ?? constraints.maxWidth;
        final responsiveHeight = widget.height ?? constraints.maxHeight;
        final iconSize = responsiveWidth > 0 && responsiveHeight > 0
            ? (responsiveWidth + responsiveHeight) / 8
            : ResponsiveUtils.getIconSize(context, 24);

        return Container(
          width: responsiveWidth > 0 ? responsiveWidth : null,
          height: responsiveHeight > 0 ? responsiveHeight : null,
          constraints: BoxConstraints(
            minWidth: ResponsiveUtils.getIconSize(context, 40),
            minHeight: ResponsiveUtils.getIconSize(context, 40),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey[200]!,
                Colors.grey[100]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: widget.borderRadius,
          ),
          child: Icon(
            Icons.image,
            color: Colors.grey[400],
            size: iconSize,
          ),
        );
      },
    );
  }
}

/// A circular cached image widget for profile pictures
class CachedCircleImage extends StatelessWidget {
  final String imageUrl;
  final double? radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedCircleImage({
    super.key,
    required this.imageUrl,
    this.radius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveRadius = radius ?? _getResponsiveRadius(context);
    final diameter = responsiveRadius * 2;

    return CachedImage(
      imageUrl: imageUrl,
      width: diameter,
      height: diameter,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(responsiveRadius),
      placeholder:
          placeholder ??
          CircleAvatar(
            radius: responsiveRadius,
            backgroundColor: Colors.grey[200],
            child: const CircularProgressIndicator(),
          ),
      errorWidget:
          errorWidget ??
          CircleAvatar(
            radius: responsiveRadius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: responsiveRadius * 0.8, color: Colors.grey),
          ),
    );
  }

  double _getResponsiveRadius(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 16.0; // Small mobile: compact avatars
      case ScreenSize.smallMobile:
        return 18.0; // Small mobile: slightly larger
      case ScreenSize.largeMobile:
        return 20.0; // Large mobile: standard size
      case ScreenSize.tablet:
        return 24.0; // Tablet: larger avatars
      case ScreenSize.smallDesktop:
        return 28.0; // Small desktop: generous size
      case ScreenSize.desktop:
        return 32.0; // Desktop: large avatars
      case ScreenSize.ultraWide:
        return 36.0; // Ultra-wide: spacious avatars
    }
  }
}
