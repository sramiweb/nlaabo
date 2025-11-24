import 'package:flutter/material.dart';
import '../services/localization_service.dart';

/// Navigation item model
class NavigationItem {
  final String id;
  final String labelKey;
  final String? mobileLabelKey;
  final IconData icon;
  final String route;

  const NavigationItem({
    required this.id,
    required this.labelKey,
    this.mobileLabelKey,
    required this.icon,
    required this.route,
  });
  
  String get label => LocalizationService().translate(labelKey);
  String get mobileLabel => LocalizationService().translate(mobileLabelKey ?? labelKey);
}

/// Navigation provider for managing navigation state across desktop and mobile
class NavigationProvider with ChangeNotifier {
  static const List<NavigationItem> navigationItems = [
    NavigationItem(
      id: 'home',
      labelKey: 'home',
      icon: Icons.home_outlined,
      route: '/home',
    ),
    NavigationItem(
      id: 'matches',
      labelKey: 'matches',
      icon: Icons.sports_soccer_outlined,
      route: '/matches',
    ),
    NavigationItem(
      id: 'teams',
      labelKey: 'teams',
      icon: Icons.group_outlined,
      route: '/teams',
    ),
    NavigationItem(
      id: 'match_history',
      labelKey: 'match_history',
      mobileLabelKey: 'match_history',
      icon: Icons.history_outlined,
      route: '/match-history',
    ),
    NavigationItem(
      id: 'search',
      labelKey: 'advanced_search',
      mobileLabelKey: 'advanced_search',
      icon: Icons.search_outlined,
      route: '/search',
    ),
    NavigationItem(
      id: 'profile',
      labelKey: 'profile',
      icon: Icons.person_outlined,
      route: '/profile',
    ),
    NavigationItem(
      id: 'notifications',
      labelKey: 'notifications',
      mobileLabelKey: 'notifications_short',
      icon: Icons.notifications_outlined,
      route: '/notifications',
    ),
    NavigationItem(
      id: 'settings',
      labelKey: 'settings',
      icon: Icons.settings_outlined,
      route: '/settings',
    ),
  ];

  String _currentRoute = '/home';
  bool _isSidebarCollapsed = false;

  String get currentRoute => _currentRoute;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  NavigationItem? get currentItem => navigationItems
      .where((item) => item.route == _currentRoute)
      .cast<NavigationItem?>()
      .firstWhere((_) => true, orElse: () => null);

  bool isItemActive(String route) => _currentRoute == route;

  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    if (_isSidebarCollapsed != collapsed) {
      _isSidebarCollapsed = collapsed;
      notifyListeners();
    }
  }

  /// Navigate to a specific item by ID
  void navigateToItem(String itemId) {
    final item = navigationItems.firstWhere(
      (item) => item.id == itemId,
      orElse: () => navigationItems.first,
    );
    setCurrentRoute(item.route);
  }

  /// Get navigation item by route
  NavigationItem? getItemByRoute(String route) {
    return navigationItems
        .where((item) => item.route == route)
        .cast<NavigationItem?>()
        .firstWhere((_) => true, orElse: () => null);
  }
}
