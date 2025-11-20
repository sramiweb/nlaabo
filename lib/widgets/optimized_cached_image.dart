import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../utils/optimized_image_loader.dart';

/// Widget that uses OptimizedImageLoader for enhanced image loading
class OptimizedCachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableProgressive;
  final bool preferWebP;
  final ImageQuality? quality;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableProgressive = true,
    this.preferWebP = true,
    this.quality,
  });

  @override
  State<OptimizedCachedImage> createState() => _OptimizedCachedImageState();
}

class _OptimizedCachedImageState extends State<OptimizedCachedImage> {
  final OptimizedImageLoader _imageLoader = OptimizedImageLoader();
  ImageProvider? _imageProvider;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(OptimizedCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.quality != widget.quality) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _imageProvider = null;
    });

    try {
      final image = await _imageLoader.loadImage(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        quality: widget.quality,
        enableProgressive: widget.enableProgressive,
        preferWebP: widget.preferWebP,
      );

      if (mounted && image != null) {
        setState(() {
          _imageProvider = _createImageProvider(image);
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
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

  ImageProvider _createImageProvider(ui.Image image) {
    // For now, fall back to network image since converting ui.Image to ImageProvider
    // requires more complex implementation. In a full implementation, you might:
    // 1. Save the ui.Image to a temporary file and use FileImage
    // 2. Use a custom ImageProvider implementation
    // 3. Convert to bytes and use MemoryImage
    return NetworkImage(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: widget.borderRadius,
            ),
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
    }

    if (_isLoading || _imageProvider == null) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: widget.borderRadius,
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: Image(
        image: _imageProvider!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: widget.borderRadius,
                ),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}

/// Circular optimized cached image widget for profile pictures
class OptimizedCircleImage extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableProgressive;
  final bool preferWebP;
  final ImageQuality? quality;

  const OptimizedCircleImage({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.placeholder,
    this.errorWidget,
    this.enableProgressive = true,
    this.preferWebP = true,
    this.quality,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedCachedImage(
      imageUrl: imageUrl,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(radius),
      enableProgressive: enableProgressive,
      preferWebP: preferWebP,
      quality: quality,
      placeholder: placeholder ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[200],
            child: const CircularProgressIndicator(),
          ),
      errorWidget: errorWidget ??
          CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: radius * 0.8, color: Colors.grey),
          ),
    );
  }
}
