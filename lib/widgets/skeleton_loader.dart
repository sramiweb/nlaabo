import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../utils/design_system.dart';

/// A skeleton loader widget that mimics the structure of content while loading
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(BorderRadiusSystem.small),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton for match cards
class MatchCardSkeleton extends StatelessWidget {
  const MatchCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveUtils.getCardWidth(context, maxWidth: 320.0);
    final padding = context.isMobile ? 12.0 : 16.0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusSystem.large),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and status row
              Row(
                children: [
                  SkeletonLoader(
                    width: 36,
                    height: 36,
                    borderRadius: BorderRadius.circular(BorderRadiusSystem.small),
                  ),
                  const Spacer(),
                  SkeletonLoader(
                    width: 60,
                    height: 20,
                    borderRadius: BorderRadius.circular(BorderRadiusSystem.medium),
                  ),
                ],
              ),
              SizedBox(height: context.itemSpacing),

              // Title
              SkeletonLoader(
                width: cardWidth * 0.8,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: context.itemSpacing * 0.5),

              // Location row
              Row(
                children: [
                  SkeletonLoader(
                    width: 16,
                    height: 16,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(width: 4),
                  SkeletonLoader(
                    width: cardWidth * 0.6,
                    height: 14,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
              SizedBox(height: context.itemSpacing * 0.25),

              // Date row
              Row(
                children: [
                  SkeletonLoader(
                    width: 16,
                    height: 16,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(width: 4),
                  SkeletonLoader(
                    width: cardWidth * 0.5,
                    height: 14,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),

              const Spacer(),

              // Players count
              Row(
                children: [
                  SkeletonLoader(
                    width: 16,
                    height: 16,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(width: 4),
                  SkeletonLoader(
                    width: cardWidth * 0.4,
                    height: 14,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for team cards
class TeamCardSkeleton extends StatelessWidget {
  const TeamCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cardWidth = ResponsiveUtils.getCardWidth(context, maxWidth: 280.0);
    final padding = context.isMobile ? 12.0 : 16.0;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusSystem.large),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and recruiting status row
              Row(
                children: [
                  SkeletonLoader(
                    width: 36,
                    height: 36,
                    borderRadius: BorderRadius.circular(BorderRadiusSystem.small),
                  ),
                  const Spacer(),
                  SkeletonLoader(
                    width: 70,
                    height: 18,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ],
              ),
              SizedBox(height: context.itemSpacing),

              // Team name
              Center(
                child: SkeletonLoader(
                  width: cardWidth * 0.7,
                  height: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(height: context.itemSpacing * 0.5),

              // Location row
              Row(
                children: [
                  SkeletonLoader(
                    width: 16,
                    height: 16,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(width: 4),
                  SkeletonLoader(
                    width: cardWidth * 0.6,
                    height: 14,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),

              const Spacer(),

              // Max players
              Row(
                children: [
                  SkeletonLoader(
                    width: 16,
                    height: 16,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(width: 4),
                  SkeletonLoader(
                    width: cardWidth * 0.5,
                    height: 14,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a list of items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context) itemBuilder;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;

  const SkeletonList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: scrollDirection,
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemBuilder(context),
    );
  }
}
