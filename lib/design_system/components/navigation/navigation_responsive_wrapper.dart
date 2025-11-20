import 'package:flutter/material.dart';
import 'desktop_sidebar.dart';
import 'mobile_bottom_nav.dart';

/// Responsive navigation wrapper that shows appropriate navigation
/// based on screen size and device type
class NavigationResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const NavigationResponsiveWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine if we're on desktop or mobile based on width
        final isDesktop = constraints.maxWidth >= 768; // Tablet breakpoint

        if (isDesktop) {
          // Desktop layout with sidebar
          return Row(
            children: [
              const DesktopSidebar(),
              Expanded(child: child),
            ],
          );
        } else {
          // Mobile layout with bottom navigation
          return Scaffold(
            body: child,
            bottomNavigationBar: const MobileBottomNav(),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          );
        }
      },
    );
  }
}

/// Navigation-aware scaffold that handles navigation state
class NavigationScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final List<Widget>? persistentFooterButtons;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const NavigationScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.persistentFooterButtons,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          // Desktop: Use standard scaffold with sidebar handled by wrapper
          return Scaffold(
            body: body,
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            persistentFooterButtons: persistentFooterButtons,
            drawer: drawer,
            endDrawer: endDrawer,
            backgroundColor: backgroundColor,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
            extendBody: extendBody,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
          );
        } else {
          // Mobile: Scaffold with bottom navigation
          return Scaffold(
            body: body,
            appBar: appBar,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            persistentFooterButtons: persistentFooterButtons,
            drawer: drawer,
            endDrawer: endDrawer,
            backgroundColor: backgroundColor,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
            extendBody: extendBody,
            extendBodyBehindAppBar: extendBodyBehindAppBar,
            bottomNavigationBar: const MobileBottomNav(),
          );
        }
      },
    );
  }
}

/// Hook widget to listen for navigation changes and update route
class NavigationListener extends StatefulWidget {
  final Widget child;

  const NavigationListener({
    super.key,
    required this.child,
  });

  @override
  State<NavigationListener> createState() => _NavigationListenerState();
}

class _NavigationListenerState extends State<NavigationListener> {
  @override
  void initState() {
    super.initState();
    // Listen for navigation changes and update the route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Route synchronization logic can be added here if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
