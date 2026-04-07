import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final String currentRole;

  const BottomNavBar({super.key, required this.currentRole});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = currentRole == 'supplier'
        ? _supplierItems(l10n)
        : _truckerItems(l10n);
    final currentPath = GoRouterState.of(context).matchedLocation;
    final currentIndex = _activeIndex(items, currentPath);

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEFF2), width: 1.0)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryMuted,
        onDestinationSelected: (index) {
          final route = items[index].route;
          if (route != currentPath) {
            context.go(route);
          }
        },
        destinations: [
          for (final item in items)
            NavigationDestination(
              icon: Icon(item.icon, color: AppColors.textTertiary),
              selectedIcon: Icon(item.activeIcon, color: AppColors.brandTeal),
              label: item.label,
            ),
        ],
      ),
    );
  }

  int _activeIndex(List<_NavItem> items, String currentPath) {
    final normalized = _normalizePath(currentPath);
    for (var i = 0; i < items.length; i++) {
      if (_normalizePath(items[i].route) == normalized) {
        return i;
      }
    }

    if (currentRole == 'supplier') {
      if (normalized.startsWith('/load-detail') ||
          normalized.startsWith('/my-loads')) {
        return 0;
      }
      if (normalized.startsWith('/post-load')) return 1;
      if (normalized.startsWith('/chat') || normalized == '/messages') return 2;
      return 3;
    }

    if (normalized == '/trucker-dashboard' ||
        normalized.startsWith('/trip-detail') ||
        normalized == '/my-trips') {
      return 0;
    }
    if (normalized.startsWith('/find-loads')) {
      return 1;
    }
    if (normalized == '/my-fleet' || normalized == '/my-fleet/add') return 2;
    if (normalized.startsWith('/chat') || normalized == '/messages') return 3;
    return 0;
  }

  String _normalizePath(String path) {
    if (path == '/my-fleet/add') return '/my-fleet';
    return path;
  }

  List<_NavItem> _supplierItems(AppLocalizations l10n) => [
    _NavItem(
      l10n.myLoadsTitle,
      Icons.inventory_2_outlined,
      Icons.inventory_2,
      '/my-loads',
    ),
    _NavItem(
      l10n.postLoadAction,
      Icons.add_circle_outline,
      Icons.add_circle,
      '/post-load',
    ),
    _NavItem(
      l10n.messagesTitle,
      Icons.chat_bubble_outline,
      Icons.chat_bubble,
      '/messages',
    ),
    _NavItem(
      l10n.settingsTitle,
      Icons.settings_outlined,
      Icons.settings,
      '/settings',
    ),
  ];

  List<_NavItem> _truckerItems(AppLocalizations l10n) => [
    _NavItem(
      l10n.appDrawerHome,
      Icons.home_outlined,
      Icons.home,
      '/trucker-dashboard',
    ),
    _NavItem(
      l10n.findLoadsAction,
      Icons.search_outlined,
      Icons.search,
      '/find-loads',
    ),
    _NavItem(
      l10n.myFleetTitle,
      Icons.local_shipping_outlined,
      Icons.local_shipping,
      '/my-fleet',
    ),
    _NavItem(
      l10n.messagesTitle,
      Icons.chat_bubble_outline,
      Icons.chat_bubble,
      '/messages',
    ),
  ];
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem(this.label, this.icon, this.activeIcon, this.route);
}
