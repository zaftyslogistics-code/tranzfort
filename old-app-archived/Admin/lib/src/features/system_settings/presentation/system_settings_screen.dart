import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  bool _enableNotifications = true;
  bool _enableAuditLogging = true;
  bool _requireVerification = true;
  bool _autoAssignTrips = false;
  bool _enableDebugMode = false;

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentAdminRoleProvider);

    if (!adminHasAccess(role, {AdminRole.superAdmin})) {
      return Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/system-settings'),
        appBar: AppBar(title: const Text('System settings')),
        body: const Center(
          child: Text('Only Super Admins can access system settings.'),
        ),
      );
    }

    return Scaffold(
      drawer: const AdminNavigationDrawer(currentRoute: '/system-settings'),
      appBar: AppBar(title: const Text('System settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.cardPadding,
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.pagePadding,
        ),
        children: [
          const AdminBrandHeader(
            title: 'System settings',
            subtitle: 'Configure platform-wide controls and admin defaults',
            icon: Icons.settings_outlined,
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Card(
            color: AdminColors.warningTint,
            child: Padding(
              padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AdminColors.secondary),
                  const SizedBox(width: AdminDesignTokens.gapSm),
                  Expanded(
                    child: Text(
                      'These settings currently act as local UI controls only. Changes are not persisted and do not update live platform behavior yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AdminColors.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Text(
            'Platform operations',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminColors.textSecondary,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: _SettingsIcon(
                icon: Icons.notifications_outlined,
                color: AdminColors.brandOrange,
              ),
              title: const Text('Enable notifications'),
              subtitle: const Text('Send push and email notifications to users'),
              value: _enableNotifications,
              onChanged: (value) => setState(() => _enableNotifications = value),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: _SettingsIcon(
                icon: Icons.fact_check_outlined,
                color: AdminColors.brandTeal,
              ),
              title: const Text('Enable audit logging'),
              subtitle: const Text('Record admin actions for security and traceability'),
              value: _enableAuditLogging,
              onChanged: (value) => setState(() => _enableAuditLogging = value),
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: _SettingsIcon(
                icon: Icons.verified_user_outlined,
                color: AdminColors.primary,
              ),
              title: const Text('Require verification'),
              subtitle: const Text('Require KYC before users can access sensitive platform actions'),
              value: _requireVerification,
              onChanged: (value) => setState(() => _requireVerification = value),
            ),
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Text(
            'Dispatch and automation',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminColors.textSecondary,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: _SettingsIcon(
                icon: Icons.local_shipping_outlined,
                color: AdminColors.info,
              ),
              title: const Text('Auto-assign trips'),
              subtitle: const Text('Automatically suggest matching truckers for loads'),
              value: _autoAssignTrips,
              onChanged: (value) => setState(() => _autoAssignTrips = value),
            ),
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Text(
            'Developer options',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminColors.textSecondary,
            ),
          ),
          Card(
            child: SwitchListTile(
              secondary: _SettingsIcon(
                icon: Icons.bug_report_outlined,
                color: AdminColors.error,
              ),
              title: const Text('Debug mode'),
              subtitle: const Text('Enable verbose diagnostics and development logging'),
              value: _enableDebugMode,
              onChanged: (value) => setState(() => _enableDebugMode = value),
            ),
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Text(
            'System info',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AdminColors.textSecondary,
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
              child: Column(
                children: [
                  _InfoRow(label: 'Version', value: '1.1.0'),
                  const SizedBox(height: AdminDesignTokens.gapSm),
                  _InfoRow(label: 'Build', value: '20260303'),
                  const SizedBox(height: AdminDesignTokens.gapSm),
                  _InfoRow(label: 'Environment', value: 'Production'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AdminColors.textSecondary)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
