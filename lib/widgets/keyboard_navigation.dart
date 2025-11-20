import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart' as semantics;

/// A widget that provides keyboard navigation support for focus management
class KeyboardNavigationWrapper extends StatefulWidget {
  final Widget child;
  final FocusNode? initialFocus;
  final bool enableArrowNavigation;
  final bool enableTabNavigation;
  final VoidCallback? onEscapePressed;
  final VoidCallback? onEnterPressed;

  const KeyboardNavigationWrapper({
    super.key,
    required this.child,
    this.initialFocus,
    this.enableArrowNavigation = true,
    this.enableTabNavigation = true,
    this.onEscapePressed,
    this.onEnterPressed,
  });

  @override
  State<KeyboardNavigationWrapper> createState() => _KeyboardNavigationWrapperState();
}

class _KeyboardNavigationWrapperState extends State<KeyboardNavigationWrapper> {
  late FocusNode _focusNode;
  final Map<LogicalKeyboardKey, VoidCallback?> _keyHandlers = {};

  @override
  void initState() {
    super.initState();
    _focusNode = widget.initialFocus ?? FocusNode();
    _setupKeyHandlers();
  }

  @override
  void didUpdateWidget(KeyboardNavigationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFocus != oldWidget.initialFocus) {
      _focusNode = widget.initialFocus ?? FocusNode();
    }
    _setupKeyHandlers();
  }

  void _setupKeyHandlers() {
    _keyHandlers.clear();
    _keyHandlers[LogicalKeyboardKey.escape] = widget.onEscapePressed;
    _keyHandlers[LogicalKeyboardKey.enter] = widget.onEnterPressed;
    _keyHandlers[LogicalKeyboardKey.numpadEnter] = widget.onEnterPressed;
  }

  @override
  void dispose() {
    if (widget.initialFocus == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final handler = _keyHandlers[event.logicalKey];
      if (handler != null) {
        handler();
        return;
      }

      if (widget.enableArrowNavigation) {
        _handleArrowNavigation(event);
      }
    }
  }

  void _handleArrowNavigation(KeyEvent event) {
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus == null) return;

    FocusNode? nextFocus;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        nextFocus = _findFocusableWidget(currentFocus, TraversalDirection.up);
        break;
      case LogicalKeyboardKey.arrowDown:
        nextFocus = _findFocusableWidget(currentFocus, TraversalDirection.down);
        break;
      case LogicalKeyboardKey.arrowLeft:
        nextFocus = _findFocusableWidget(currentFocus, TraversalDirection.left);
        break;
      case LogicalKeyboardKey.arrowRight:
        nextFocus = _findFocusableWidget(currentFocus, TraversalDirection.right);
        break;
    }

    if (nextFocus != null) {
      nextFocus.requestFocus();
    }
  }

  FocusNode? _findFocusableWidget(FocusNode current, TraversalDirection direction) {
    // This is a simplified implementation
    // In a real app, you'd want more sophisticated focus traversal
    final context = current.context;
    if (context == null) return null;

    // Find the nearest FocusableActionDetector or Focus widget
    FocusNode? nextNode;

    void visit(Element element) {
      if (nextNode != null) return;

      final widget = element.widget;
      if (widget is Focus && widget.focusNode != current) {
        nextNode = widget.focusNode;
        return;
      }

      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return nextNode;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: widget.enableArrowNavigation || _keyHandlers.isNotEmpty
          ? (node, event) {
              _handleKeyEvent(event);
              return KeyEventResult.handled;
            }
          : null,
      child: widget.child,
    );
  }
}

/// A focusable widget that provides keyboard navigation support
class FocusableWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onEnterPressed;
  final VoidCallback? onSpacePressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool skipTraversal;
  final String? semanticLabel;
  final String? semanticHint;

  const FocusableWidget({
    super.key,
    required this.child,
    this.onPressed,
    this.onEnterPressed,
    this.onSpacePressed,
    this.autofocus = false,
    this.focusNode,
    this.skipTraversal = false,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FocusableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        widget.onEnterPressed?.call();
        widget.onPressed?.call();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        widget.onSpacePressed?.call();
        widget.onPressed?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      button: widget.onPressed != null,
      enabled: widget.onPressed != null,
      focused: _isFocused,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        skipTraversal: widget.skipTraversal,
        onKeyEvent: (node, event) {
          _handleKeyEvent(event);
          return KeyEventResult.handled;
        },
        child: widget.child,
      ),
    );
  }
}

/// A widget that manages focus order for a group of widgets
class FocusGroup extends StatefulWidget {
  final List<Widget> children;
  final Axis direction;
  final bool loop;
  final FocusNode? groupFocusNode;

  const FocusGroup({
    super.key,
    required this.children,
    this.direction = Axis.vertical,
    this.loop = false,
    this.groupFocusNode,
  });

  @override
  State<FocusGroup> createState() => _FocusGroupState();
}

class _FocusGroupState extends State<FocusGroup> {
  late List<FocusNode> _focusNodes;
  late FocusNode _groupFocusNode;

  @override
  void initState() {
    super.initState();
    _groupFocusNode = widget.groupFocusNode ?? FocusNode();
    _focusNodes = List.generate(
      widget.children.length,
      (index) => FocusNode(),
    );
  }

  @override
  void didUpdateWidget(FocusGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.children.length != oldWidget.children.length) {
      // Dispose old focus nodes
      for (final node in _focusNodes) {
        node.dispose();
      }
      // Create new ones
      _focusNodes = List.generate(
        widget.children.length,
        (index) => FocusNode(),
      );
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    if (widget.groupFocusNode == null) {
      _groupFocusNode.dispose();
    }
    super.dispose();
  }

  void _handleTraversal(FocusNode currentNode, TraversalDirection direction) {
    final currentIndex = _focusNodes.indexOf(currentNode);
    if (currentIndex == -1) return;

    int nextIndex;
    switch (direction) {
      case TraversalDirection.up:
      case TraversalDirection.left:
        nextIndex = currentIndex - 1;
        break;
      case TraversalDirection.down:
      case TraversalDirection.right:
        nextIndex = currentIndex + 1;
        break;
      default:
        return;
    }

    if (widget.loop) {
      if (nextIndex < 0) {
        nextIndex = _focusNodes.length - 1;
      } else if (nextIndex >= _focusNodes.length) {
        nextIndex = 0;
      }
    } else {
      if (nextIndex < 0 || nextIndex >= _focusNodes.length) {
        return;
      }
    }

    _focusNodes[nextIndex].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _groupFocusNode,
      child: widget.direction == Axis.vertical
          ? Column(
              children: List.generate(
                widget.children.length,
                (index) => Focus(
                  focusNode: _focusNodes[index],
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _handleTraversal(node, TraversalDirection.up);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _handleTraversal(node, TraversalDirection.down);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: widget.children[index],
                ),
              ),
            )
          : Row(
              children: List.generate(
                widget.children.length,
                (index) => Focus(
                  focusNode: _focusNodes[index],
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        _handleTraversal(node, TraversalDirection.left);
                        return KeyEventResult.handled;
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        _handleTraversal(node, TraversalDirection.right);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: widget.children[index],
                ),
              ),
            ),
    );
  }
}

/// Extension methods for easier keyboard navigation setup
extension KeyboardNavigationExtensions on Widget {
  /// Wraps the widget with keyboard navigation support
  Widget withKeyboardNavigation({
    FocusNode? initialFocus,
    bool enableArrowNavigation = true,
    bool enableTabNavigation = true,
    VoidCallback? onEscapePressed,
    VoidCallback? onEnterPressed,
  }) {
    return KeyboardNavigationWrapper(
      initialFocus: initialFocus,
      enableArrowNavigation: enableArrowNavigation,
      enableTabNavigation: enableTabNavigation,
      onEscapePressed: onEscapePressed,
      onEnterPressed: onEnterPressed,
      child: this,
    );
  }

  /// Makes the widget focusable with keyboard support
  Widget focusable({
    VoidCallback? onPressed,
    VoidCallback? onEnterPressed,
    VoidCallback? onSpacePressed,
    bool autofocus = false,
    FocusNode? focusNode,
    bool skipTraversal = false,
    String? semanticLabel,
    String? semanticHint,
  }) {
    return FocusableWidget(
      onPressed: onPressed,
      onEnterPressed: onEnterPressed,
      onSpacePressed: onSpacePressed,
      autofocus: autofocus,
      focusNode: focusNode,
      skipTraversal: skipTraversal,
      semanticLabel: semanticLabel,
      semanticHint: semanticHint,
      child: this,
    );
  }
}

/// A widget that provides skip links for accessibility
class SkipLinks extends StatelessWidget {
  final List<SkipLink> links;

  const SkipLinks({
    super.key,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -40, // Hidden initially
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: links.map((link) {
          return Focus(
            onFocusChange: (hasFocus) {
              // Animate into view when focused
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: link.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(link.label),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Data class for skip links
class SkipLink {
  final String label;
  final VoidCallback onPressed;

  const SkipLink({
    required this.label,
    required this.onPressed,
  });
}

/// A widget that announces content changes to screen readers
class ScreenReaderAnnouncer extends StatefulWidget {
  final String message;
  final bool announce;
  final Duration delay;

  const ScreenReaderAnnouncer({
    super.key,
    required this.message,
    this.announce = true,
    this.delay = Duration.zero,
  });

  @override
  State<ScreenReaderAnnouncer> createState() => _ScreenReaderAnnouncerState();
}

class _ScreenReaderAnnouncerState extends State<ScreenReaderAnnouncer> {
  @override
  void didUpdateWidget(ScreenReaderAnnouncer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.announce && widget.message != oldWidget.message) {
      _announceMessage();
    }
  }

  void _announceMessage() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }
    if (mounted) {
      // Use SemanticsService to announce to screen readers
      // Note: This is a Flutter internal API that may change
      // In production, consider using platform-specific accessibility APIs
      semantics.SemanticsService.announce(widget.message, TextDirection.ltr);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
