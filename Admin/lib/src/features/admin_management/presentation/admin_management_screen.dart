import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_management_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_management_providers.dart';

class AdminManagementScreen extends ConsumerWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managementAsync = ref.watch(adminManagementProvider);

    return Scaffold(
      body: managementAsync.when(
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Admin management',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Review active and inactive admin accounts from the live `admin_users` table. Invite and deactivate actions stay deferred until a dedicated backend contract is available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => ref.read(adminManagementProvider.notifier).updateSearch(value),
              decoration: const InputDecoration(
                labelText: 'Search admins',
                hintText: 'Name or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AdminManagementFilter.values.map((filter) {
                final selected = filter == state.query.filter;
                return ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected,
                  onSelected: (_) => ref.read(adminManagementProvider.notifier).updateFilter(filter),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryCard(label: 'Total admins', value: state.summary.totalCount.toString()),
                _SummaryCard(label: 'Active', value: state.summary.activeCount.toString()),
                _SummaryCard(label: 'Inactive', value: state.summary.inactiveCount.toString()),
                _SummaryCard(label: 'Super admins', value: state.summary.superAdminCount.toString()),
                _SummaryCard(label: 'Ops admins', value: state.summary.opsAdminCount.toString()),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Admins',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => ref.read(adminManagementProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.items.isEmpty)
                      const Text('No admin accounts matched the current filter.')
                    else
                      ...state.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.isActive ? AdminColors.raisedSurface : AdminColors.errorBg,
                            child: Icon(
                              Icons.admin_panel_settings_outlined,
                              color: item.isActive ? AdminColors.accentTeal : AdminColors.error,
                            ),
                          ),
                          title: Text(item.fullName.isEmpty ? 'Unnamed admin' : item.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.email.isEmpty ? '-' : item.email),
                              const SizedBox(height: 4),
                              Text(
                                'Admin id ${item.id.isEmpty ? '-' : item.id}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Auth user id ${item.authUserId.isEmpty ? '-' : item.authUserId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_roleLabel(item.role)} • ${item.isActive ? 'Active' : 'Inactive'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.createdBy.isEmpty
                                    ? 'Created in current admin identity table'
                                    : 'Created by ${item.createdBy}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created ${_dateLabel(item.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StatusPill(
                                label: _roleLabel(item.role),
                                color: item.role == 'super_admin' ? AdminColors.warning : AdminColors.accentTeal,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.isActive ? 'Active' : 'Inactive',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: item.isActive ? AdminColors.success : AdminColors.error,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next follow-through'),
                    SizedBox(height: 8),
                    Text('Invite and deactivate actions remain intentionally deferred until dedicated backend contracts and protection rules are available.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('Unable to load admin management right now.')),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminColors.raisedSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _filterLabel(AdminManagementFilter filter) {
  return switch (filter) {
    AdminManagementFilter.all => 'All admins',
    AdminManagementFilter.superAdmins => 'Super admins',
    AdminManagementFilter.opsAdmins => 'Ops admins',
    AdminManagementFilter.inactive => 'Inactive',
  };
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final minutes = value.minute.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:$minutes';
}

String _roleLabel(String role) {
  return switch (role.trim().toLowerCase()) {
    'super_admin' => 'Super admin',
    'ops_admin' => 'Ops admin',
    _ => 'Unknown',
  };
}
