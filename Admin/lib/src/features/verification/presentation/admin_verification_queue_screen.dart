import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_verification_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_verification_providers.dart';

class AdminVerificationQueueScreen extends ConsumerWidget {
  const AdminVerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(adminVerificationQueueProvider);

    return Scaffold(
      body: queueAsync.when(
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Verification queue',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Review supplier, trucker, and truck verification submissions ordered by SLA urgency or newest submission time using the current `verification_cases` authority surface.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => ref.read(adminVerificationQueueProvider.notifier).updateSearch(value),
              decoration: const InputDecoration(
                labelText: 'Search verification cases',
                hintText: 'Case id, subject id/type, name, contact, status, or assigned admin',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TabChip(
                  label: 'Suppliers (${state.counts.suppliers})',
                  selected: state.query.tab == VerificationQueueTab.suppliers,
                  onSelected: () => ref.read(adminVerificationQueueProvider.notifier).updateTab(VerificationQueueTab.suppliers),
                ),
                _TabChip(
                  label: 'Truckers (${state.counts.truckers})',
                  selected: state.query.tab == VerificationQueueTab.truckers,
                  onSelected: () => ref.read(adminVerificationQueueProvider.notifier).updateTab(VerificationQueueTab.truckers),
                ),
                _TabChip(
                  label: 'Trucks (${state.counts.trucks})',
                  selected: state.query.tab == VerificationQueueTab.trucks,
                  onSelected: () => ref.read(adminVerificationQueueProvider.notifier).updateTab(VerificationQueueTab.trucks),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SortChip(
                  label: 'SLA urgency',
                  selected: state.query.sort == VerificationQueueSort.slaUrgency,
                  onSelected: () => ref.read(adminVerificationQueueProvider.notifier).updateSort(VerificationQueueSort.slaUrgency),
                ),
                _SortChip(
                  label: 'Newest',
                  selected: state.query.sort == VerificationQueueSort.newest,
                  onSelected: () => ref.read(adminVerificationQueueProvider.notifier).updateSort(VerificationQueueSort.newest),
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
                          child: Text(
                            'Cases',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => ref.read(adminVerificationQueueProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.items.isEmpty)
                      const Text('No verification cases matched the current queue filter.')
                    else
                      ...state.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            item.subjectType == 'truck'
                                ? Icons.local_shipping_outlined
                                : (item.reviewType == 'profile_photo_update'
                                    ? Icons.photo_camera_back_outlined
                                    : Icons.verified_user_outlined),
                          ),
                          title: Text(item.displayName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.secondaryLabel.isNotEmpty) Text(item.secondaryLabel),
                              if (item.contactLabel.isNotEmpty)
                                Text(
                                  item.contactLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                '${_statusLabel(item.caseStatus)} • ${item.reviewType == 'profile_photo_update' ? 'Photo update' : 'Full verification'} • ${item.isClaimed ? 'Claimed' : 'Unclaimed'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.assignedAdminUserId.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.assignedAdminLabel.isEmpty
                                      ? 'Assigned admin ${item.assignedAdminUserId}'
                                      : 'Assigned admin ${item.assignedAdminLabel} • ${item.assignedAdminUserId}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Case ${item.caseId.isEmpty ? '-' : item.caseId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Subject ${item.subjectId.isEmpty ? '-' : item.subjectId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Submitted ${_dateTimeLabel(item.submittedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.profileLinkId.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  key: ValueKey('verification-queue-open-subject-${item.caseId}'),
                                  onPressed: () => context.go(AdminRoutes.userDetailPathFor(item.profileLinkId)),
                                  child: Text(item.profileLinkLabel.isEmpty ? 'Open profile' : item.profileLinkLabel),
                                ),
                              ],
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(item.slaLabel, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _slaColor(item.slaPriority))),
                              const SizedBox(height: 4),
                              Text(_dateLabel(item.submittedAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                            ],
                          ),
                          onTap: () => context.go(AdminRoutes.verificationDetailPathFor(item.caseId)),
                        ),
                      ),
                    if (state.hasMore) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: state.isLoading ? null : () => ref.read(adminVerificationQueueProvider.notifier).loadNextPage(),
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
                const Text('Unable to load the verification queue right now.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(adminVerificationQueueProvider),
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

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _SortChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

String _statusLabel(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Unknown';
  }
  return normalized.replaceAll('_', ' ');
}

Color _slaColor(int priority) {
  return switch (priority) {
    3 => AdminColors.error,
    2 => AdminColors.warning,
    1 => AdminColors.success,
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
