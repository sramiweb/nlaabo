import 'package:flutter/material.dart';

class WebImageLoader {
  static Widget loadOptimizedImage(String url, {BoxFit? fit}) {
    // Use optimized loading for all platforms, with enhanced web features
    return Image.network(
      url,
      fit: fit ?? BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.broken_image, size: 48);
      },
    );
  }
}
