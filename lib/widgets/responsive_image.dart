import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../design_system/typography/app_text_styles.dart';

/// A responsive image widget that adapts to different screen sizes
class ResponsiveImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableFadeIn;

  const ResponsiveImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.enableFadeIn = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveWidth = width ?? _getResponsiveWidth(context);
    final responsiveHeight = height ?? _getResponsiveHeight(context);

    return Container(
      width: responsiveWidth,
      height: responsiveHeight,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(context.borderRadius),
      ),
      child: Image.network(
        imageUrl,
        width: responsiveWidth,
        height: responsiveHeight,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildErrorWidget(context);
        },
      ),
    );
  }

  double _getResponsiveWidth(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 120.0; // Small mobile: compact images
      case ScreenSize.smallMobile:
        return 140.0; // Small mobile: slightly larger
      case ScreenSize.largeMobile:
        return 160.0; // Large mobile: standard size
      case ScreenSize.tablet:
        return 200.0; // Tablet: larger images
      case ScreenSize.smallDesktop:
        return 240.0; // Small desktop: generous size
      case ScreenSize.desktop:
        return 280.0; // Desktop: large images
      case ScreenSize.ultraWide:
        return 320.0; // Ultra-wide: spacious images
    }
  }

  double _getResponsiveHeight(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 90.0; // Small mobile: compact height
      case ScreenSize.smallMobile:
        return 105.0; // Small mobile: slightly taller
      case ScreenSize.largeMobile:
        return 120.0; // Large mobile: standard height
      case ScreenSize.tablet:
        return 150.0; // Tablet: taller images
      case ScreenSize.smallDesktop:
        return 180.0; // Small desktop: generous height
      case ScreenSize.desktop:
        return 210.0; // Desktop: large height
      case ScreenSize.ultraWide:
        return 240.0; // Ultra-wide: spacious height
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: context.iconSize,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Icon(
          Icons.broken_image,
          color: Theme.of(context).colorScheme.error,
          size: context.iconSize,
        ),
      ),
    );
  }
}

/// A responsive avatar widget
class ResponsiveAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double? radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ResponsiveAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveRadius = radius ?? _getResponsiveRadius(context);

    if (imageUrl != null) {
      return CircleAvatar(
        radius: responsiveRadius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      );
    }

    return CircleAvatar(
      radius: responsiveRadius,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
      child: Text(
        initials ?? '?',
        style: AppTextStyles.getResponsiveLabelText(context).copyWith(
          color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
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

/// A responsive hero image widget for banners/headers
class ResponsiveHeroImage extends StatelessWidget {
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final double? height;
  final Widget? overlay;
  final bool enableGradient;

  const ResponsiveHeroImage({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.height,
    this.overlay,
    this.enableGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveHeight = height ?? _getResponsiveHeight(context);

    return Container(
      height: responsiveHeight,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: enableGradient ? BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ) : null,
        child: overlay ?? _buildDefaultOverlay(context),
      ),
    );
  }

  double _getResponsiveHeight(BuildContext context) {
    final screenSize = ResponsiveUtils.getScreenSize(context);

    switch (screenSize) {
      case ScreenSize.extraSmallMobile:
        return 180.0; // Small mobile: compact hero
      case ScreenSize.smallMobile:
        return 200.0; // Small mobile: slightly taller
      case ScreenSize.largeMobile:
        return 220.0; // Large mobile: standard height
      case ScreenSize.tablet:
        return 280.0; // Tablet: larger hero
      case ScreenSize.smallDesktop:
        return 320.0; // Small desktop: generous height
      case ScreenSize.desktop:
        return 360.0; // Desktop: large hero
      case ScreenSize.ultraWide:
        return 400.0; // Ultra-wide: spacious hero
    }
  }

  Widget _buildDefaultOverlay(BuildContext context) {
    if (title == null && subtitle == null) return const SizedBox.shrink();

    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title!,
              style: AppTextStyles.getResponsivePageTitle(context).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: AppTextStyles.getResponsiveBodyText(context).copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
