import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'profile_card.dart';

class AppDrawer extends StatelessWidget {
  final String role;

  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSupplier = role == 'supplier';

    return Drawer(
      width: AppSpacing.drawerWidth,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(color: AppColors.primaryMuted),
              child: ProfileCard(
                name: l10n.appDrawerProfileTitle,
                roleLabel: isSupplier
                    ? l10n.appDrawerSupplierWorkspace
                    : l10n.appDrawerTruckerWorkspace,
                verified: true,
                verifiedLabel: l10n.profileVerifiedChip,
                unverifiedLabel: l10n.profileVerificationChip('unverified'),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  if (!isSupplier)
                    _DrawerItem(
                      icon: Icons.dashboard_outlined,
                      label: l10n.appDrawerDashboard,
                      onTap: () => _go(context, '/trucker-dashboard'),
                    ),
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: l10n.appDrawerHome,
                    onTap: () =>
                        _go(context, isSupplier ? '/my-loads' : '/find-loads'),
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline,
                    label: l10n.messagesTitle,
                    onTap: () => _go(context, '/messages'),
                  ),
                  _DrawerItem(
                    icon: Icons.person_outline,
                    label: l10n.appDrawerProfileTitle,
                    onTap: () => _go(context, '/profile'),
                  ),
                  _DrawerItem(
                    icon: Icons.verified_user_outlined,
                    label: l10n.appDrawerVerification,
                    onTap: () => _go(
                      context,
                      isSupplier
                          ? '/verification/supplier'
                          : '/verification/trucker',
                    ),
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_none,
                    label: l10n.appBarNotificationsTooltip,
                    onTap: () => _go(context, '/notifications'),
                  ),
                  _DrawerItem(
                    icon: Icons.smart_toy_outlined,
                    label: l10n.appDrawerBotChat,
                    onTap: () => _go(context, '/bot-chat'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPadding,
                      vertical: AppSpacing.sm,
                    ),
                    child: Divider(color: AppColors.divider),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: l10n.settingsTitle,
                    onTap: () => _go(context, '/settings'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Text(
                      'v1.1.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: AppSpacing.minTouchTarget,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
      ),
      leading: Icon(icon, color: AppColors.onSurface),
      title: Text(label),
      onTap: onTap,
    );
  }
}
