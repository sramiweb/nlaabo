import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';
import '../providers/navigation_provider.dart';
import '../design_system/components/navigation/desktop_sidebar.dart';
import '../design_system/components/navigation/mobile_bottom_nav.dart';
import '../utils/responsive_utils.dart';

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {


  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final localizationProvider = context.watch<LocalizationProvider>();
    final currentRoute = GoRouterState.of(context).uri.path;

    return ChangeNotifierProvider(
      create: (_) {
        final provider = NavigationProvider();
        provider.setCurrentRoute(currentRoute);
        return provider;
      },
      child: Directionality(
        textDirection: localizationProvider.textDirection,
        child: SafeArea(
          child: Scaffold(
            body: isDesktop
                ? Row(
                    children: [
                      const DesktopSidebar(),
                      Expanded(child: widget.child),
                    ],
                  )
                : widget.child,
            bottomNavigationBar: isDesktop ? null : const MobileBottomNav(),
          ),
        ),
      ),
    );
  }




  
}
