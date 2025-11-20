import 'package:flutter/material.dart';

/// A widget that provides fade-in animation for content appearance
class FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool animate;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.animate = true,
  });

  @override
  State<FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<FadeInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    if (widget.animate) {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FadeInAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.reset();
        Future.delayed(widget.delay, () {
          if (mounted) {
            _controller.forward();
          }
        });
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A widget that provides staggered fade-in animations for lists
class StaggeredFadeInAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Curve curve;
  final Axis direction;

  const StaggeredFadeInAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 500),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.curve = Curves.easeOut,
    this.direction = Axis.vertical,
  });

  @override
  State<StaggeredFadeInAnimation> createState() => _StaggeredFadeInAnimationState();
}

class _StaggeredFadeInAnimationState extends State<StaggeredFadeInAnimation> {
  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: _buildAnimatedChildren(),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    return List.generate(
      widget.children.length,
      (index) => FadeInAnimation(
        key: ValueKey(index),
        delay: widget.staggerDelay * index,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.children[index],
      ),
    );
  }
}

/// Extension to easily wrap widgets with fade-in animation
extension FadeInExtension on Widget {
  Widget withFadeIn({
    Duration duration = const Duration(milliseconds: 500),
    Duration delay = Duration.zero,
    Curve curve = Curves.easeOut,
    bool animate = true,
  }) {
    return FadeInAnimation(
      duration: duration,
      delay: delay,
      curve: curve,
      animate: animate,
      child: this,
    );
  }
}

/// A widget that animates content changes with fade transitions
class AnimatedContentSwitcher extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedContentSwitcher> createState() => _AnimatedContentSwitcherState();
}

class _AnimatedContentSwitcherState extends State<AnimatedContentSwitcher>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedContentSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}
