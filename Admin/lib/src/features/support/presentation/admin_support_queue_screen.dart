import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_support_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_support_providers.dart';

class AdminSupportQueueScreen extends ConsumerWidget {
  const AdminSupportQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(adminSupportQueueProvider);

    return Scaffold(
      body: queueAsync.when(
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Support queue',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Review support tickets with the current ticket and reply contracts already present in the backend.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current queue contract',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Queue browsing, search, open-ticket detail, and visible admin replies are live. Assign-to-me, status changes, priority changes, and resolve actions remain intentionally unavailable until dedicated admin support contracts land.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => ref.read(adminSupportQueueProvider.notifier).updateSearch(value),
              decoration: const InputDecoration(
                labelText: 'Search support tickets',
                hintText: 'Ticket id, owner/user id, role/state, load/trip id, category, status, priority, or resolution',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TabChip(
                  label: 'Open (${state.counts.open})',
                  selected: state.query.tab == SupportQueueTab.open,
                  onSelected: () => ref.read(adminSupportQueueProvider.notifier).updateTab(SupportQueueTab.open),
                ),
                _TabChip(
                  label: 'In Progress (${state.counts.inProgress})',
                  selected: state.query.tab == SupportQueueTab.inProgress,
                  onSelected: () => ref.read(adminSupportQueueProvider.notifier).updateTab(SupportQueueTab.inProgress),
                ),
                _TabChip(
                  label: 'Resolved (${state.counts.resolved})',
                  selected: state.query.tab == SupportQueueTab.resolved,
                  onSelected: () => ref.read(adminSupportQueueProvider.notifier).updateTab(SupportQueueTab.resolved),
                ),
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
                          child: Text('Tickets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => ref.read(adminSupportQueueProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.items.isEmpty)
                      const Text('No support tickets matched the current queue filter.')
                    else
                      ...state.items.map(
                        (item) => ListTile(
                          key: ValueKey('admin-support-queue-item-${item.id}'),
                          contentPadding: EdgeInsets.zero,
                          title: Text('${item.ownerName} • ${item.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_titleCaseWords(item.category)),
                              if (item.ownerContact.isNotEmpty)
                                Text(item.ownerContact, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                'Ticket ${item.id.isEmpty ? '-' : item.id}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'User ${item.ownerProfileId.isEmpty ? '-' : item.ownerProfileId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Load ${item.relatedLoadId.isEmpty ? '-' : item.relatedLoadId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trip ${item.relatedTripId.isEmpty ? '-' : item.relatedTripId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_titleCaseWords(item.ownerRole)} • ${_titleCaseWords(item.ownerVerificationStatus)} • ${item.ownerIsBanned ? 'Banned' : 'Active'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_titleCaseWords(item.status)} • ${_titleCaseWords(item.priority)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.resolutionSummary.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Resolution ${item.resolutionSummary}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                _ticketTimelineLabel(item),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              Text(
                                'Owner joined ${_dateTimeLabel(item.ownerCreatedAt)} • Last login ${_dateTimeLabel(item.ownerLastLoginAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.ownerProfileId.isNotEmpty || item.relatedLoadId.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (item.ownerProfileId.isNotEmpty)
                                      OutlinedButton.icon(
                                        key: ValueKey('admin-support-open-owner-${item.id}'),
                                        onPressed: () => context.go(AdminRoutes.userDetailPathFor(item.ownerProfileId)),
                                        icon: const Icon(Icons.person_outline),
                                        label: const Text('Open user'),
                                      ),
                                    if (item.relatedLoadId.isNotEmpty)
                                      OutlinedButton.icon(
                                        key: ValueKey('admin-support-open-load-${item.id}'),
                                        onPressed: () => context.go(AdminRoutes.loadDetailPathFor(item.relatedLoadId)),
                                        icon: const Icon(Icons.local_shipping_outlined),
                                        label: const Text('Open load'),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Text(
                            _dateLabel(item.updatedAt),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _priorityColor(item.priority)),
                          ),
                          onTap: () => context.go(AdminRoutes.supportDetailPathFor(item.id)),
                        ),
                      ),
                    if (state.hasMore) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: state.isLoading ? null : () => ref.read(adminSupportQueueProvider.notifier).loadNextPage(),
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
                const Text('Unable to load the support queue right now.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(adminSupportQueueProvider),
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

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _TabChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

Color _priorityColor(String value) {
  return switch (value.trim()) {
    'urgent' => AdminColors.error,
    'high' => AdminColors.warning,
    'medium' => AdminColors.accentTeal,
    _ => AdminColors.textSecondary,
  };
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _dateTimeLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _ticketTimelineLabel(AdminSupportTicketItem item) {
  if (item.resolvedAt != null) {
    return 'Opened ${_dateTimeLabel(item.createdAt)} • Resolved ${_dateTimeLabel(item.resolvedAt)}';
  }
  return 'Opened ${_dateTimeLabel(item.createdAt)} • Updated ${_dateTimeLabel(item.updatedAt)}';
}

String _titleCaseWords(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
