import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_user_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_user_management_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      body: usersAsync.when(
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text('User management', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Search suppliers and truckers, review their verification state, and open the first detail view from the current admin shell.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => ref.read(adminUsersProvider.notifier).updateSearch(value),
              decoration: const InputDecoration(
                labelText: 'Search users',
                hintText: 'Name, user id, mobile, email, role, or state',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AdminUserFilter.values.map((filter) {
                final selected = filter == state.query.filter;
                return ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected,
                  onSelected: (_) => ref.read(adminUsersProvider.notifier).updateFilter(filter),
                );
              }).toList(growable: false),
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
                          child: Text('Users', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => ref.read(adminUsersProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.items.isEmpty)
                      Text(
                        'No users matched the current search or filter.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
                      )
                    else
                      ...state.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: item.isBanned ? AdminColors.errorBg : AdminColors.raisedSurface,
                            child: Icon(
                              item.role == 'supplier' ? Icons.inventory_2_outlined : Icons.local_shipping_outlined,
                              color: item.isBanned ? AdminColors.error : AdminColors.accentTeal,
                            ),
                          ),
                          title: Text(item.fullName.isEmpty ? 'Unnamed user' : item.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_roleLabel(item.role)} • ${_verificationLabel(item.verificationStatus)} • ${item.mobile.isEmpty ? item.email : item.mobile}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User ${item.id.isEmpty ? '-' : item.id}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Joined ${_dateLabel(item.createdAt)} • Last login ${_dateLabel(item.lastLoginAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.isBanned && item.banReason.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Ban reason: ${item.banReason.trim()}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.error),
                                ),
                              ],
                            ],
                          ),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.isBanned ? 'Banned' : '${item.activityCount} activity',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: item.isBanned ? AdminColors.error : AdminColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () => context.go(AdminRoutes.userDetailPathFor(item.id)),
                        ),
                      ),
                    if (state.hasMore) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: state.isLoading ? null : () => ref.read(adminUsersProvider.notifier).loadNextPage(),
                          child: Text(state.isLoading ? 'Loading…' : 'Load more'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 36, color: AdminColors.error),
                const SizedBox(height: 12),
                const Text('Unable to load users right now.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(adminUsersProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _filterLabel(AdminUserFilter filter) {
  return switch (filter) {
    AdminUserFilter.all => 'All',
    AdminUserFilter.supplier => 'Suppliers',
    AdminUserFilter.trucker => 'Truckers',
    AdminUserFilter.banned => 'Banned',
  };
}

String _roleLabel(String role) {
  return switch (role.trim().toLowerCase()) {
    'supplier' => 'Supplier',
    'trucker' => 'Trucker',
    _ => 'User',
  };
}

String _verificationLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Unknown verification';
  }
  return normalized.replaceAll('_', ' ');
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final minutes = value.minute.toString().padLeft(2, '0');
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} ${value.hour.toString().padLeft(2, '0')}:$minutes';
}
