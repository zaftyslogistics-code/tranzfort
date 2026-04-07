import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../shared/widgets/admin_brand_header.dart';
import '../../../shared/widgets/admin_navigation_drawer.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../providers/admin_management_provider.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  ConsumerState<AdminManagementScreen> createState() =>
      _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  final _inviteFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  AdminRole _inviteRole = AdminRole.opsAdmin;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(currentAdminRoleProvider);
    final adminsAsync = ref.watch(adminAccountsProvider);
    final actionState = ref.watch(adminManagementActionProvider);
    final activeCount = adminsAsync.maybeWhen(
      data: (admins) => admins.where((admin) => admin.isActive).length,
      orElse: () => 0,
    );
    final inactiveCount = adminsAsync.maybeWhen(
      data: (admins) => admins.where((admin) => !admin.isActive).length,
      orElse: () => 0,
    );

    if (!adminHasAccess(role, {AdminRole.superAdmin})) {
      return Scaffold(
        drawer: const AdminNavigationDrawer(currentRoute: '/admin-management'),
        appBar: AppBar(title: const Text('Admin management')),
        body: const Center(
          child: Text('Only Super Admins can access admin management.'),
        ),
      );
    }

    return Scaffold(
      drawer: const AdminNavigationDrawer(currentRoute: '/admin-management'),
      appBar: AppBar(title: const Text('Admin management')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.cardPadding,
          AdminDesignTokens.pagePadding,
          AdminDesignTokens.pagePadding,
        ),
        children: [
          const AdminBrandHeader(
            title: 'Admin access control',
            subtitle:
                'Invite operations/support admins and control account activation',
            icon: Icons.admin_panel_settings_outlined,
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          _GatewayInfoCard(
            activeCount: activeCount,
            inactiveCount: inactiveCount,
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
              child: Form(
                key: _inviteFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionIntro(
                      title: 'Provision downstream access',
                      subtitle:
                          'Use this gateway to invite admins and decide which operational modules become available in their workspace.',
                    ),
                    const SizedBox(height: AdminDesignTokens.sectionGap),
                    Text(
                      'Invite admin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AdminDesignTokens.gapSm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter full name'
                          : null,
                    ),
                    const SizedBox(height: AdminDesignTokens.gapSm),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Enter email';
                        if (!text.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: AdminDesignTokens.gapSm),
                    DropdownButtonFormField<AdminRole>(
                      initialValue: _inviteRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(
                          value: AdminRole.opsAdmin,
                          child: Text('Ops Admin'),
                        ),
                        DropdownMenuItem(
                          value: AdminRole.supportAgent,
                          child: Text('Support Agent'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _inviteRole = value);
                      },
                    ),
                    const SizedBox(height: AdminDesignTokens.sectionGap),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: actionState.isLoading ? null : _invite,
                        icon: const Icon(Icons.person_add_outlined),
                        label: const Text('Send admin invite'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AdminDesignTokens.sectionGap),
          adminsAsync.when(
            data: (admins) {
              if (admins.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Text('No admin accounts are available yet.'),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionIntro(
                    title: 'Admin roster',
                    subtitle:
                        'Review which admins currently have live access. Toggling status here changes whether their downstream admin modules remain available.',
                  ),
                  const SizedBox(height: AdminDesignTokens.gapSm),
                  ...admins.asMap().entries.map((entry) {
                    final admin = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AdminDesignTokens.gapSm),
                      child: Card(
                        child: ListTile(
                          leading: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: admin.isActive ? Colors.green : AdminColors.textTertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          title: Text(admin.fullName),
                          subtitle: Text(
                            '${admin.email} • ${adminRoleLabel(admin.role)}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(admin.isActive ? 'Active' : 'Inactive'),
                              const SizedBox(width: AdminDesignTokens.gapXs),
                              Switch(
                                value: admin.isActive,
                                onChanged: actionState.isLoading
                                    ? null
                                    : (value) => _toggleActive(
                                        adminId: admin.id,
                                        nextState: value,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                child: Text('Unable to load admin accounts.'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _invite() async {
    if (!(_inviteFormKey.currentState?.validate() ?? false)) return;

    final result = await ref
        .read(adminManagementActionProvider.notifier)
        .inviteAdmin(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          role: _inviteRole,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );

    if (result.ok) {
      _nameController.clear();
      _emailController.clear();
      setState(() => _inviteRole = AdminRole.opsAdmin);
    }
  }

  Future<void> _toggleActive({
    required String adminId,
    required bool nextState,
  }) async {
    final result = await ref
        .read(adminManagementActionProvider.notifier)
        .setAdminActive(adminId: adminId, isActive: nextState);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }
}

class _GatewayInfoCard extends StatelessWidget {
  final int activeCount;
  final int inactiveCount;

  const _GatewayInfoCard({
    required this.activeCount,
    required this.inactiveCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminColors.brandTealLightMuted,
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gateway module',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AdminColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AdminDesignTokens.gapXs),
            Text(
              'Admin Management provisions access into downstream queues and tools. Invite and activation decisions made here change which modules appear to other admins.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: AdminDesignTokens.sectionGap),
            Wrap(
              spacing: AdminDesignTokens.gapSm,
              runSpacing: AdminDesignTokens.gapSm,
              children: [
                _AdminPill(
                  text: 'Active admins $activeCount',
                  color: Colors.green,
                  backgroundColor: Colors.green.withValues(alpha: 0.12),
                ),
                _AdminPill(
                  text: 'Inactive admins $inactiveCount',
                  color: AdminColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionIntro({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AdminDesignTokens.gapXs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AdminColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AdminPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;

  const _AdminPill({
    required this.text,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
