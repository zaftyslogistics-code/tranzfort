import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../auth/data/auth_repository.dart';
import '../../communication/providers/chat_providers.dart';
import '../../notifications/providers/notification_providers.dart';

class UserAppShell extends ConsumerWidget {
  final String currentLocation;
  final AppUserRole role;
  final Widget child;

  const UserAppShell({
    super.key,
    required this.currentLocation,
    required this.role,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final tabs = _tabsForRole(role, l10n);
    final currentIndex = _resolveIndex(currentLocation, tabs);
    final currentTab = tabs[currentIndex];
    final topLevel = _isTopLevel(currentLocation, tabs);
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      appBar: topLevel
          ? AppBar(
              title: Text(currentTab.title),
              actions: [
                IconButton(
                  tooltip: l10n.supplierQuickActionNotifications,
                  onPressed: () => context.go(AppRoutes.notificationsPath),
                  icon: _ShellUtilityBadgeIcon(
                    icon: Icons.notifications_none_outlined,
                    count: unreadNotificationCount,
                  ),
                ),
                Builder(
                  builder: (scaffoldContext) {
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: IconButton(
                        tooltip: l10n.navProfile,
                        onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                        icon: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.subtleSurface,
                          child: Icon(
                            Icons.person_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      drawer: UserAppDrawer(role: role),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(tabs[index].route),
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon),
                label: tab.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  List<_ShellTab> _tabsForRole(AppUserRole role, AppLocalizations l10n) {
    if (role == AppUserRole.supplier) {
      return [
        _ShellTab(
          route: AppRoutes.supplierDashboardPath,
          label: l10n.shellTabHome,
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          title: l10n.shellTitleSupplierDashboard,
        ),
        _ShellTab(
          route: AppRoutes.myLoadsPath,
          label: l10n.shellTabLoads,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          title: l10n.shellTitleMyLoads,
        ),
        _ShellTab(
          route: AppRoutes.supplierTripsPath,
          label: l10n.shellTabTrips,
          icon: Icons.alt_route_outlined,
          activeIcon: Icons.alt_route,
          title: l10n.shellQuickActionTrips,
        ),
      ];
    }

    return [
      _ShellTab(
        route: AppRoutes.truckerDashboardPath,
        label: l10n.shellTabHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        title: l10n.shellDashboardTitle,
      ),
      _ShellTab(
        route: AppRoutes.findLoadsPath,
        label: l10n.shellTabFind,
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        title: l10n.shellTitleFindLoads,
      ),
      _ShellTab(
        route: AppRoutes.tripsPath,
        label: l10n.shellTabTrips,
        icon: Icons.alt_route_outlined,
        activeIcon: Icons.alt_route,
        title: l10n.shellQuickActionTrips,
      ),
    ];
  }

  bool _isTopLevel(String location, List<_ShellTab> tabs) {
    return tabs.any((tab) => tab.route == location);
  }

  int _resolveIndex(String location, List<_ShellTab> tabs) {
    final index = tabs.indexWhere((tab) => location == tab.route);
    if (index != -1) {
      return index;
    }

    if (role == AppUserRole.supplier && location == AppRoutes.postLoadPath) {
      return 1;
    }

    return 0;
  }
}

class UserAppDrawer extends ConsumerWidget {
  final AppUserRole role;

  const UserAppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: UserAppDrawerContent(role: role),
    );
  }
}

class UserAppDrawerContent extends ConsumerWidget {
  final AppUserRole role;

  const UserAppDrawerContent({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dashboardRoute = role == AppUserRole.supplier
        ? AppRoutes.supplierDashboardPath
        : AppRoutes.truckerDashboardPath;
    final roleLabel = role == AppUserRole.supplier
        ? l10n.shellDrawerSupplierWorkspace
        : l10n.shellDrawerTruckerWorkspace;
    final unreadConversationCount = ref.watch(inboxProvider).conversations.where((conversation) => conversation.hasUnread).length;
    final unreadNotificationCount = ref.watch(unreadNotificationCountProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              gradient: AppColors.heroCta,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'TranZfort',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  roleLabel,
                  style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                DrawerNavItem(
                  icon: Icons.dashboard_outlined,
                  label: l10n.shellDrawerDashboard,
                  onTap: () => _go(context, dashboardRoute),
                ),
                if (role == AppUserRole.supplier)
                  DrawerNavItem(
                    icon: Icons.add_box_outlined,
                    label: l10n.supplierDashboardPostLoadAction,
                    onTap: () => _go(context, AppRoutes.postLoadPath),
                  ),
                if (role == AppUserRole.trucker)
                  DrawerNavItem(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.shellDrawerFleet,
                    onTap: () => _go(context, AppRoutes.fleetPath),
                  ),
                DrawerNavItem(
                  icon: Icons.verified_user_outlined,
                  label: l10n.verificationTitle,
                  onTap: () => _go(context, AppRoutes.verificationPath),
                ),
                DrawerNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.shellDrawerMessages,
                  badgeCount: unreadConversationCount,
                  onTap: () => _go(context, AppRoutes.messagesPath),
                ),
                DrawerNavItem(
                  icon: Icons.notifications_none_outlined,
                  label: l10n.navNotifications,
                  badgeCount: unreadNotificationCount,
                  onTap: () => _go(context, AppRoutes.notificationsPath),
                ),
                DrawerNavItem(
                  icon: Icons.support_agent_outlined,
                  label: l10n.shellDrawerSupport,
                  onTap: () => _go(context, AppRoutes.supportPath),
                ),
                DrawerNavItem(
                  icon: Icons.person_outline,
                  label: l10n.shellDrawerProfile,
                  onTap: () => _go(context, AppRoutes.profilePath),
                ),
                DrawerNavItem(
                  icon: Icons.settings_outlined,
                  label: l10n.settingsTitle,
                  onTap: () => _go(context, AppRoutes.settingsPath),
                ),
                DrawerNavItem(
                  icon: Icons.translate_outlined,
                  label: l10n.shellDrawerLanguage,
                  onTap: () => _go(context, AppRoutes.settingsPath),
                ),
                DrawerNavItem(
                  icon: Icons.logout,
                  label: l10n.shellDrawerSignOut,
                  onTap: () => _signOut(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();

    final result = await ref.read(authRepositoryProvider).signOutAndClearLocalState();
    if (!context.mounted) {
      return;
    }

    if (result.isFailure) {
      final l10n = AppLocalizations.of(context);
      AppSnackbar.show(
        context: context,
        message: l10n.shellSignOutFailureMessage,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    ref.invalidate(authStateProvider);
    ref.invalidate(currentAuthStateProvider);
    ref.invalidate(profileCompletenessProvider);
    context.go(AppRoutes.authPath);
  }

}

class DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const DrawerNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 24,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: badgeCount > 0 ? ShellCountBadge(count: badgeCount) : null,
      onTap: onTap,
    );
  }
}

class _ShellUtilityBadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _ShellUtilityBadgeIcon({
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: ShellCountBadge(count: count, compact: true),
          ),
      ],
    );
  }
}

class ShellCountBadge extends StatelessWidget {
  final int count;
  final bool compact;

  const ShellCountBadge({
    super.key,
    required this.count,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 18 : 22,
        minHeight: compact ? 18 : 22,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 9 : 10,
            ),
      ),
    );
  }
}

class _ShellTab {
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String title;

  const _ShellTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.title,
  });
}
