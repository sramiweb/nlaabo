import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom intent for callback actions
class CallbackIntent extends Intent {
  final VoidCallback callback;

  const CallbackIntent(this.callback);
}

/// A widget that provides global keyboard shortcuts for the application
class KeyboardShortcuts extends StatefulWidget {
  final Widget child;
  final Map<ShortcutActivator, VoidCallback> shortcuts;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    this.shortcuts = const {},
  });

  @override
  State<KeyboardShortcuts> createState() => _KeyboardShortcutsState();
}

class _KeyboardShortcutsState extends State<KeyboardShortcuts> {
  late Map<ShortcutActivator, Intent> _shortcutMap;

  @override
  void initState() {
    super.initState();
    _updateShortcutMap();
  }

  @override
  void didUpdateWidget(KeyboardShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shortcuts != oldWidget.shortcuts) {
      _updateShortcutMap();
    }
  }

  void _updateShortcutMap() {
    _shortcutMap = {};
    widget.shortcuts.forEach((activator, callback) {
      _shortcutMap[activator] = CallbackIntent(callback);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _shortcutMap,
      child: Actions(
        actions: {
          CallbackIntent: CallbackAction<CallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: widget.child,
      ),
    );
  }
}

/// Common keyboard shortcuts for the application
class AppShortcuts {
  static const createTeam = SingleActivator(LogicalKeyboardKey.keyT, control: true);
  static const createMatch = SingleActivator(LogicalKeyboardKey.keyM, control: true);
  static const search = SingleActivator(LogicalKeyboardKey.keyF, control: true);
  static const refresh = SingleActivator(LogicalKeyboardKey.f5);
  static const goHome = SingleActivator(LogicalKeyboardKey.home);
  static const goBack = SingleActivator(LogicalKeyboardKey.escape);
  static const navigateNext = SingleActivator(LogicalKeyboardKey.tab);
  static const navigatePrevious = SingleActivator(LogicalKeyboardKey.tab, shift: true);
  static const activate = SingleActivator(LogicalKeyboardKey.enter);
}

/// Extension to add keyboard shortcuts to BuildContext
extension KeyboardShortcutExtensions on BuildContext {
  /// Show a snackbar with keyboard shortcut hints
  void showKeyboardHints() {
    ScaffoldMessenger.of(this).showSnackBar(
      const SnackBar(
        content: Text(
          'Keyboard shortcuts: Ctrl+T (Create Team), Ctrl+M (Create Match), '
          'Ctrl+F (Search), F5 (Refresh), Tab (Navigate), Enter (Activate)',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }
}

/// A widget that displays keyboard shortcut hints
class KeyboardShortcutHints extends StatelessWidget {
  const KeyboardShortcutHints({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Keyboard shortcuts help',
      hint: 'Tap to show available keyboard shortcuts',
      child: IconButton(
        icon: const Icon(Icons.keyboard),
        onPressed: () => context.showKeyboardHints(),
        tooltip: 'Show keyboard shortcuts',
      ),
    );
  }
}
