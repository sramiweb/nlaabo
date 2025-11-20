import 'package:flutter/material.dart';
import 'cached_image.dart';
import 'package:flutter/gestures.dart';

/// A lazy loading image widget that only loads when visible in viewport
/// Enhanced with IntersectionObserver-like behavior for better performance
class LazyImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Duration cacheDuration;
  final double preloadMargin; // How far outside viewport to start loading

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheDuration = const Duration(days: 7),
    this.preloadMargin = 50.0, // Start loading 50px before entering viewport
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isVisible = false;
  bool _hasBeenVisible = false; // Once loaded, keep loaded
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted || _hasBeenVisible) return; // Don't check if already loaded

    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Enhanced visibility check with preload margin
    final isVisible =
        position.dy < screenSize.height + widget.preloadMargin &&
        position.dy + renderBox.size.height > -widget.preloadMargin &&
        position.dx < screenSize.width + widget.preloadMargin &&
        position.dx + renderBox.size.width > -widget.preloadMargin;

    if (isVisible && !_isVisible) {
      setState(() {
        _isVisible = true;
        _hasBeenVisible = true; // Mark as loaded, don't unload
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: SizedBox(
        key: _key,
        width: widget.width,
        height: widget.height,
        child: _isVisible
            ? CachedImage(
                imageUrl: widget.imageUrl,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
                placeholder: widget.placeholder,
                errorWidget: widget.errorWidget,
                borderRadius: widget.borderRadius,
                cacheDuration: widget.cacheDuration,
              )
            : widget.placeholder ??
                  Container(
                    width: widget.width,
                    height: widget.height,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey, size: 24),
                    ),
                  ),
      ),
    );
  }
}

/// A lazy loading list view that only renders visible items with performance optimizations
class LazyListView extends StatefulWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final double estimatedItemHeight; // For better performance calculation

  const LazyListView({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.estimatedItemHeight = 100.0, // Default estimated height
  });

  @override
  State<LazyListView> createState() => _LazyListViewState();
}

class _LazyListViewState extends State<LazyListView> {
  final Set<int> _visibleIndices = {};
  final ScrollController _scrollController = ScrollController();
  double _lastScrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initialize visible indices
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateVisibleIndices();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Throttle scroll updates for performance
    final currentOffset = _scrollController.offset;
    if ((currentOffset - _lastScrollOffset).abs() > widget.estimatedItemHeight / 2) {
      _lastScrollOffset = currentOffset;
      _calculateVisibleIndices();
    }
  }

  void _calculateVisibleIndices() {
    if (!mounted) return;

    final screenSize = MediaQuery.of(context).size;
    final viewportHeight = widget.scrollDirection == Axis.vertical
        ? screenSize.height
        : screenSize.width;

    // Calculate visible range with buffer for smoother scrolling
    const bufferItems = 2; // Load 2 extra items above and below viewport
    final startIndex = (_scrollController.offset / widget.estimatedItemHeight)
        .floor() - bufferItems;
    final endIndex = startIndex +
        (viewportHeight / widget.estimatedItemHeight).ceil() +
        (bufferItems * 2);

    final clampedStartIndex = startIndex.clamp(0, widget.children.length);
    final clampedEndIndex = endIndex.clamp(0, widget.children.length);

    setState(() {
      _visibleIndices.clear();
      for (int i = clampedStartIndex; i < clampedEndIndex; i++) {
        _visibleIndices.add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: widget.key,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      controller: widget.controller ?? _scrollController,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      padding: widget.padding,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      cacheExtent: widget.cacheExtent,
      semanticChildCount: widget.semanticChildCount,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      itemCount: widget.children.length,
      itemBuilder: (context, index) {
        // Only build visible items for performance
        if (_visibleIndices.contains(index)) {
          return widget.children[index];
        }
        // Return sized placeholder for non-visible items
        return SizedBox(
          height: widget.estimatedItemHeight,
          child: Container(color: Colors.transparent),
        );
      },
    );
  }
}
