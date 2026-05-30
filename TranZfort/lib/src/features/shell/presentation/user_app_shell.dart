import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_state_providers.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../core/widgets/tts_stop_on_route_change.dart';
import '../../../shared/widgets/avatar_widget.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../communication/providers/chat_providers.dart';
import '../../supplier/providers/supplier_providers.dart';
import '../../trucker/providers/find_loads_provider.dart';
import '../../trucker/providers/trucker_providers.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/find_loads_tab_tts_builder.dart';

class UserAppShell extends ConsumerStatefulWidget {
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
  ConsumerState<UserAppShell> createState() => _UserAppShellState();
}

class _UserAppShellState extends ConsumerState<UserAppShell> {
  DateTime? _lastBackPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final tabs = _tabsForRole(widget.role, l10n);
    final currentIndex = _resolveIndex(widget.currentLocation, tabs);
    final currentTab = tabs[currentIndex];
    final topLevel = _isTopLevel(widget.currentLocation, tabs);
    final tabTtsSummary = _tabTtsSummary(
      context: context,
      role: widget.role,
      currentTab: currentTab,
      fallback: currentTab.title,
    );
    final shouldProtectBack = _shouldProtectBackButton(widget.currentLocation, tabs);
    final unreadNotificationCount = ref.watch(shellUnreadNotificationCountProvider).valueOrNull ?? 0;

    // Determine if back should be allowed
    final canPop = !shouldProtectBack || (_lastBackPressed != null && DateTime.now().difference(_lastBackPressed!) < const Duration(seconds: 2));

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_isVerificationRoute(_normalizeRoute(widget.currentLocation))) {
          context.go(AppRoutes.homeForRole(
            widget.role == AppUserRole.supplier ? 'supplier' : 'trucker',
          ));
          return;
        }

        // Handle back button on top-level routes
        if (shouldProtectBack) {
          final now = DateTime.now();
          if (_lastBackPressed == null || now.difference(_lastBackPressed!) >= const Duration(seconds: 2)) {
            // First press - show toast message
            setState(() {
              _lastBackPressed = now;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).shellPressBackAgainToExit),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          // If pressed within 2 seconds, canPop will be true and the system will handle exit
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: topLevel
            ? AppBar(
                title: Text(currentTab.title),
                actions: [
                  IconButton(
                    tooltip: l10n.commonNotificationsLabel,
                    onPressed: () => context.go(AppRoutes.notificationsPath),
                    icon: _ShellUtilityBadgeIcon(
                      icon: Icons.notifications_none_outlined,
                      count: unreadNotificationCount,
                    ),
                  ),
                  const TtsActionButton(),
                  const LanguageToggleAction(),
                  Builder(
                    builder: (scaffoldContext) {
                      final liveProfile = ref.watch(currentProfileProvider).valueOrNull;
                      final authState = ref.watch(currentAuthStateProvider);
                      final avatarUrl = liveProfile?.avatarUrl ?? authState.profile?.avatarUrl;
                      final userId = liveProfile?.id ?? authState.profile?.id;
                      final fullName = liveProfile?.fullName ?? authState.profile?.fullName ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: IconButton(
                          tooltip: l10n.commonProfileLabel,
                          onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                          icon: UserAvatar(
                            avatarUrl: avatarUrl,
                            userId: userId,
                            initials: fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                            radius: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            : null,
        drawer: UserAppDrawer(role: widget.role),
        body: Stack(
          children: [
            TtsStopOnRouteChange(
              routeKey: widget.currentLocation,
              child: widget.child,
            ),
            if (topLevel)
              TtsScreenSummaryEffect(
                summary: tabTtsSummary,
                screenKey: '${widget.role.name}:${currentTab.route}',
              ),
          ],
        ),
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
          associatedRoutes: const <String>[
            AppRoutes.supplierDashboardPath,
            AppRoutes.supplierVerificationPath,
            AppRoutes.verificationPath,
          ],
        ),
        _ShellTab(
          route: AppRoutes.myLoadsPath,
          label: l10n.shellTabLoads,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2,
          title: l10n.shellTitleMyLoads,
          associatedRoutes: const <String>[
            AppRoutes.myLoadsPath,
            AppRoutes.postLoadPath,
            AppRoutes.loadDetailPath,
          ],
        ),
        _ShellTab(
          route: AppRoutes.messagesPath,
          label: l10n.shellMessagesTitle,
          icon: Icons.chat_bubble_outline,
          activeIcon: Icons.chat_bubble,
          title: l10n.shellMessagesTitle,
          associatedRoutes: const <String>[
            AppRoutes.messagesPath,
            AppRoutes.chatPath,
          ],
        ),
        _ShellTab(
          route: AppRoutes.supplierTripsPath,
          label: l10n.commonTripsLabel,
          icon: Icons.alt_route_outlined,
          activeIcon: Icons.alt_route,
          title: l10n.commonTripsLabel,
          associatedRoutes: const <String>[
            AppRoutes.supplierTripsPath,
            AppRoutes.tripDetailPath,
            AppRoutes.raiseDisputePath,
          ],
        ),
      ];
    }

    return [
      _ShellTab(
        route: AppRoutes.truckerDashboardPath,
        label: l10n.shellTabHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        title: l10n.commonDashboardLabel,
        associatedRoutes: const <String>[
          AppRoutes.truckerDashboardPath,
          AppRoutes.truckerVerificationPath,
          AppRoutes.verificationPath,
          AppRoutes.fleetPath,
        ],
      ),
      _ShellTab(
        route: AppRoutes.findLoadsPath,
        label: l10n.shellTabFind,
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        title: l10n.shellTitleFindLoads,
        associatedRoutes: const <String>[
          AppRoutes.findLoadsPath,
          AppRoutes.loadDetailPath,
          AppRoutes.routePreviewPath,
        ],
      ),
      _ShellTab(
        route: AppRoutes.messagesPath,
        label: l10n.shellMessagesTitle,
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        title: l10n.shellMessagesTitle,
        associatedRoutes: const <String>[
          AppRoutes.messagesPath,
          AppRoutes.chatPath,
        ],
      ),
      _ShellTab(
        route: AppRoutes.tripsPath,
        label: l10n.commonTripsLabel,
        icon: Icons.alt_route_outlined,
        activeIcon: Icons.alt_route,
        title: l10n.commonTripsLabel,
        associatedRoutes: const <String>[
          AppRoutes.tripsPath,
          AppRoutes.tripDetailPath,
          AppRoutes.raiseDisputePath,
        ],
      ),
    ];
  }

  bool _isTopLevel(String location, List<_ShellTab> tabs) {
    final normalizedLocation = _normalizeRoute(location);
    return tabs.any((tab) {
      return _normalizeRoute(tab.route) == normalizedLocation;
    });
  }

  bool _shouldProtectBackButton(String location, List<_ShellTab> tabs) {
    final normalizedLocation = _normalizeRoute(location);
    // Check if it's a tab route
    final isTabRoute = tabs.any((tab) {
      return _normalizeRoute(tab.route) == normalizedLocation;
    });
    // Also consider notifications as a top-level route for back button protection
    final isNotifications = normalizedLocation == _normalizeRoute(AppRoutes.notificationsPath);
    return isTabRoute || isNotifications;
  }

  bool _isVerificationRoute(String normalizedLocation) {
    final supplier = _normalizeRoute(AppRoutes.supplierVerificationPath);
    final trucker = _normalizeRoute(AppRoutes.truckerVerificationPath);
    return normalizedLocation == supplier ||
        normalizedLocation == trucker ||
        normalizedLocation.startsWith('$supplier/') ||
        normalizedLocation.startsWith('$trucker/');
  }

  int _resolveIndex(String location, List<_ShellTab> tabs) {
    final normalizedLocation = _normalizeRoute(location);
    final index = tabs.indexWhere((tab) => tab.matchesLocation(normalizedLocation));
    if (index != -1) {
      return index;
    }

    return 0;
  }

  String _normalizeRoute(String location) {
    return location.endsWith('/') && location.length > 1
        ? location.substring(0, location.length - 1)
        : location;
  }

  String _tabTtsSummary({
    required BuildContext context,
    required AppUserRole role,
    required _ShellTab currentTab,
    required String fallback,
  }) {
    final tts = TtsLocalizations.of(context);

    if (role == AppUserRole.trucker && currentTab.route == AppRoutes.findLoadsPath) {
      final findLoadsState = ref.watch(findLoadsProvider);
      if (findLoadsState.isInitialLoading) {
        return fallback;
      }
      return const FindLoadsTabTtsBuilder().build(state: findLoadsState, tts: tts);
    }

    if (role == AppUserRole.trucker && currentTab.route == AppRoutes.truckerDashboardPath) {
      final dashboardState = ref.watch(truckerDashboardProvider).valueOrNull;
      if (dashboardState == null) {
        return fallback;
      }
      return tts.ttsShellTruckerDashboardIntro(
        '${dashboardState.approvedTrucks}',
        '${dashboardState.inTransitTrips}',
      );
    }

    if (role == AppUserRole.supplier && currentTab.route == AppRoutes.supplierDashboardPath) {
      final dashboardState = ref.watch(supplierDashboardProvider).valueOrNull;
      if (dashboardState == null) {
        return fallback;
      }
      return tts.ttsShellSupplierDashboardIntro(
        '${dashboardState.activeLoads}',
        '${dashboardState.pendingBookings}',
      );
    }

    if (currentTab.route == AppRoutes.messagesPath) {
      final unreadCount = ref.watch(unreadConversationCountProvider).valueOrNull ?? 0;
      return tts.ttsShellMessagesIntro('$unreadCount');
    }

    if (currentTab.route == AppRoutes.tripsPath) {
      if (role == AppUserRole.trucker) {
        final dashboardState = ref.watch(truckerDashboardProvider).valueOrNull;
        if (dashboardState == null) {
          return fallback;
        }
        return tts.ttsShellTripsIntro(
          '${dashboardState.upcomingTrips}',
          '${dashboardState.inTransitTrips}',
        );
      }
      final supplierState = ref.watch(supplierDashboardProvider).valueOrNull;
      if (supplierState == null) {
        return fallback;
      }
      return tts.ttsShellTripsIntro(
        '${supplierState.pendingBookings}',
        '${supplierState.inTransitTrips}',
      );
    }

    return fallback;
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
    final liveProfile = ref.watch(currentProfileProvider).valueOrNull;
    final authState = ref.watch(currentAuthStateProvider);
    final avatarUrl = liveProfile?.avatarUrl ?? authState.profile?.avatarUrl;
    final fullName = liveProfile?.fullName ?? authState.profile?.fullName ?? '';
    final userId = liveProfile?.id ?? authState.profile?.id;

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
                UserAvatar(
                  avatarUrl: avatarUrl,
                  userId: userId,
                  initials: fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  radius: 28,
                  fallbackColor: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  fullName.isNotEmpty ? fullName : 'TranZfort',
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
                  label: l10n.commonDashboardLabel,
                  onTap: () => _go(context, dashboardRoute),
                ),
                if (role == AppUserRole.supplier)
                  DrawerNavItem(
                    icon: Icons.add_box_outlined,
                    label: l10n.commonPostLoadAction,
                    onTap: () => _go(context, AppRoutes.postLoadPath),
                  ),
                if (role == AppUserRole.trucker)
                  DrawerNavItem(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.commonFleetLabel,
                    onTap: () => _go(context, AppRoutes.fleetPath),
                  ),
                DrawerNavItem(
                  icon: Icons.verified_user_outlined,
                  label: l10n.verificationTitle,
                  onTap: () => _go(context, AppRoutes.verificationPath),
                ),
                DrawerNavItem(
                  icon: Icons.support_agent_outlined,
                  label: l10n.commonSupportLabel,
                  onTap: () => _go(context, AppRoutes.supportPath),
                ),
                DrawerNavItem(
                  icon: Icons.person_outline,
                  label: l10n.commonProfileLabel,
                  onTap: () => _go(context, AppRoutes.profilePath),
                ),
                DrawerNavItem(
                  icon: Icons.settings_outlined,
                  label: l10n.settingsTitle,
                  onTap: () => _go(context, AppRoutes.settingsPath),
                ),
                DrawerNavItem(
                  icon: Icons.logout,
                  label: l10n.commonSignOutAction,
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
    final router = GoRouter.of(context);

    final result = await ref.read(authRepositoryProvider).signOutAndClearLocalState();
    if (result.isFailure) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(
          context: context,
          message: l10n.shellSignOutFailureMessage,
          variant: AppSnackbarVariant.error,
        );
      }
      return;
    }

    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.invalidate(authStateProvider);
    ref.invalidate(currentAuthStateProvider);
    ref.invalidate(profileCompletenessProvider);
    router.go(AppRoutes.authPath);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      minLeadingWidth: 24,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: badgeCount > 0
          ? SizedBox(
              width: 52,
              child: Align(
                alignment: Alignment.centerRight,
                child: ShellCountBadge(count: badgeCount),
              ),
            )
          : null,
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
  final List<String> associatedRoutes;

  const _ShellTab({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.title,
    this.associatedRoutes = const <String>[],
  });

  bool matchesLocation(String normalizedLocation) {
    for (final associatedRoute in associatedRoutes) {
      final normalizedAssociatedRoute = associatedRoute.endsWith('/') && associatedRoute.length > 1
          ? associatedRoute.substring(0, associatedRoute.length - 1)
          : associatedRoute;
      if (normalizedLocation == normalizedAssociatedRoute || normalizedLocation.startsWith('$normalizedAssociatedRoute/')) {
        return true;
      }
    }
    final normalizedRoute = route.endsWith('/') && route.length > 1
        ? route.substring(0, route.length - 1)
        : route;
    return normalizedLocation == normalizedRoute || normalizedLocation.startsWith('$normalizedRoute/');
  }
}
