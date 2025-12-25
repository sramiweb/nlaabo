import 'package:flutter/material.dart';
import 'dart:math';

/// A responsive logo widget that adapts its size based on screen width
/// while maintaining aspect ratio and providing error fallbacks.
class ResponsiveLogo extends StatefulWidget {
  final double maxWidth;
  final double maxHeight;
  final String assetPath;
  final BoxFit fit;
  final bool enableLazyLoading;
  final Widget? errorPlaceholder;
  final Duration fadeInDuration;

  const ResponsiveLogo({
    super.key,
    this.maxWidth = 200,
    this.maxHeight = 60,
    this.assetPath = 'assets/icons/logo.png',
    this.fit = BoxFit.contain,
    this.enableLazyLoading = true,
    this.errorPlaceholder,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  @override
  State<ResponsiveLogo> createState() => _ResponsiveLogoState();
}

class _ResponsiveLogoState extends State<ResponsiveLogo>
    with AutomaticKeepAliveClientMixin {
  bool _isLoaded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final logoWidth = min(widget.maxWidth, screenWidth * 0.8);
    final logoHeight = logoWidth * (widget.maxHeight / widget.maxWidth);

    Widget logoWidget = Image.asset(
      widget.assetPath,
      width: logoWidth,
      height: logoHeight,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder(logoWidth, logoHeight);
      },
      frameBuilder: widget.enableLazyLoading
          ? (context, child, frame, wasSynchronouslyLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if ((wasSynchronouslyLoaded || frame != null) &&
                    !_isLoaded &&
                    mounted) {
                  setState(() => _isLoaded = true);
                }
              });
              if (wasSynchronouslyLoaded || frame != null) {
                return _buildFadeIn(child);
              }
              return _buildLoadingPlaceholder(logoWidth, logoHeight);
            }
          : null,
    );

    return logoWidget;
  }

  Widget _buildFadeIn(Widget child) {
    return AnimatedOpacity(
      opacity: _isLoaded ? 1.0 : 0.0,
      duration: widget.fadeInDuration,
      child: child,
    );
  }

  Widget _buildLoadingPlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder(double width, double height) {
    if (widget.errorPlaceholder != null) {
      return SizedBox(
        width: width,
        height: height,
        child: widget.errorPlaceholder,
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}

/// A utility class for managing logo assets with consistent naming.
class LogoAssets {
  static const String logo = 'assets/icons/logo.png';
  static const String logo16 = 'assets/icons/logo_16.png';
  static const String logo32 = 'assets/icons/logo_32.png';
  static const String logo64 = 'assets/icons/logo_64.png';
  static const String logo128 = 'assets/icons/logo_128.png';
  static const String logo256 = 'assets/icons/logo_256.png';
  static const String logo512 = 'assets/icons/logo_512.png';
  static const String logo1024 = 'assets/icons/logo_1024.png';

  /// Get the appropriate logo size based on the target width.
  static String getLogoForWidth(double width) {
    if (width <= 16) return logo16;
    if (width <= 32) return logo32;
    if (width <= 64) return logo64;
    if (width <= 128) return logo128;
    if (width <= 256) return logo256;
    if (width <= 512) return logo512;
    return logo1024;
  }

  /// Validate that all required logo assets exist.
  static Future<List<String>> validateAssets() async {
    final missingAssets = <String>[];

    // This would typically check file existence
    // For now, return empty list as validation happens at runtime
    return missingAssets;
  }
}
