import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/app_state_providers.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/providers/notification_providers.dart';

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
    final shouldProtectBack = _shouldProtectBackButton(widget.currentLocation, tabs);
    final unreadNotificationCount = ref.watch(shellUnreadNotificationCountProvider).valueOrNull ?? 0;

    // Determine if back should be allowed
    final canPop = !shouldProtectBack || (_lastBackPressed != null && DateTime.now().difference(_lastBackPressed!) < const Duration(seconds: 2));

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

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
                content: Text('Press back again to exit'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          // If pressed within 2 seconds, canPop will be true and the system will handle exit
        }
      },
      child: Scaffold(
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
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: IconButton(
                          tooltip: l10n.commonProfileLabel,
                          onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                          icon: _AvatarCircle(avatarUrl: avatarUrl, radius: 16),
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
            widget.child,
            if (topLevel)
              TtsScreenSummaryEffect(
                summary: currentTab.title,
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
                _AvatarCircle(avatarUrl: avatarUrl, radius: 28, fallbackIcon: Icons.local_shipping_outlined),
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

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final IconData? fallbackIcon;

  const _AvatarCircle({
    required this.avatarUrl,
    required this.radius,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final iconSize = radius * 1.125;
    final fallback = _AvatarFallback(
      radius: radius,
      iconSize: iconSize,
      icon: fallbackIcon ?? Icons.person_outline,
    );

    if (url == null || url.isEmpty) {
      return fallback;
    }

    if (!url.startsWith('http')) {
      return FutureBuilder<String?>(
        future: _createSignedUrl(url),
        builder: (context, snapshot) {
          final resolvedUrl = snapshot.data;
          if (resolvedUrl == null || resolvedUrl.isEmpty) {
            return fallback;
          }
          return _AvatarImage(url: resolvedUrl, radius: radius, fallback: fallback);
        },
      );
    }

    return _AvatarImage(url: url, radius: radius, fallback: fallback);
  }

  Future<String?> _createSignedUrl(String path) async {
    try {
      final client = Supabase.instance.client;
      return await client.storage.from('verification-documents').createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }
}

class _AvatarImage extends StatelessWidget {
  final String url;
  final double radius;
  final Widget fallback;

  const _AvatarImage({
    required this.url,
    required this.radius,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final double radius;
  final double iconSize;
  final IconData icon;

  const _AvatarFallback({
    required this.radius,
    required this.iconSize,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: AppColors.primary,
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
