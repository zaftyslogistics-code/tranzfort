import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_operational_case_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_operational_case_providers.dart';

class AdminOperationalCaseQueueScreen extends ConsumerWidget {
  const AdminOperationalCaseQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(adminOperationalCaseQueueProvider);
    final actionState = ref.watch(adminOperationalCaseActionProvider);

    return Scaffold(
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AdminColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading operational case queue',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(adminOperationalCaseQueueProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (state) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Text(
              'Operational case queue',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Review queued operational and dispute cases using the existing claim and release admin contracts.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => ref.read(adminOperationalCaseQueueProvider.notifier).updateSearch(value),
              decoration: const InputDecoration(
                labelText: 'Search operational cases',
                hintText: 'Case id, type, queue, business object, waiting/resolution, or admin',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.all,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.all),
                ),
                _FilterChip(
                  label: 'Queued (${state.counts.queued})',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.queued,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.queued),
                ),
                _FilterChip(
                  label: 'Claimed (${state.counts.claimed})',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.claimed,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.claimed),
                ),
                _FilterChip(
                  label: 'In Review (${state.counts.inReview})',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.inReview,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.inReview),
                ),
                _FilterChip(
                  label: 'Waiting (${state.counts.waiting})',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.waiting,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.waiting),
                ),
                _FilterChip(
                  label: 'Escalated (${state.counts.escalated})',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.escalated,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.escalated),
                ),
                _FilterChip(
                  label: 'Closed (${state.counts.closed})',
                  selected: state.query.statusFilter == OperationalCaseStatusFilter.closed,
                  onSelected: () => ref.read(adminOperationalCaseQueueProvider.notifier).updateStatusFilter(OperationalCaseStatusFilter.closed),
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
                          child: Text('Cases', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => ref.read(adminOperationalCaseQueueProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (state.items.isEmpty)
                      const Text('No operational cases matched the current queue filter.')
                    else
                      ...state.items.map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.rule_folder_outlined),
                          title: Text(item.businessLabel),
                          onTap: () => context.go(AdminRoutes.operationalCaseDetailPathFor(item.id)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_titleCaseWords(item.caseType)),
                              const SizedBox(height: 4),
                              Text(
                                'Queue ${item.queueClassification.isEmpty ? '-' : _titleCaseWords(item.queueClassification)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_titleCaseWords(item.status)} • ${item.claimedByLabel.isEmpty ? 'Unclaimed' : 'Claimed by ${item.claimedByLabel}'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.claimedByAdminUserId.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.claimedByLabel.isEmpty
                                      ? 'Claimed admin ${item.claimedByAdminUserId}'
                                      : 'Claimed admin ${item.claimedByLabel} • ${item.claimedByAdminUserId}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                              if (item.escalatedToLabel.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Escalated to ${item.escalatedToLabel}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                              if (item.escalatedToAdminUserId.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.escalatedToLabel.isEmpty
                                      ? 'Escalated admin ${item.escalatedToAdminUserId}'
                                      : 'Escalated admin ${item.escalatedToLabel} • ${item.escalatedToAdminUserId}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                'Case ${item.id.isEmpty ? '-' : item.id}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_titleCaseWords(item.primaryObjectType)} ${item.primaryObjectId.isEmpty ? '-' : item.primaryObjectId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              if (item.waitingReason.isNotEmpty)
                                Text(
                                  item.waitingReason,
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
                                _caseTimelineLabel(item),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(_dateLabel(item.updatedAt), style: Theme.of(context).textTheme.labelMedium),
                                  if (item.primaryObjectType == 'load' && item.primaryObjectId.isNotEmpty)
                                    OutlinedButton(
                                      key: ValueKey('ops-queue-open-load-${item.id}'),
                                      onPressed: () => context.go(AdminRoutes.loadDetailPathFor(item.primaryObjectId)),
                                      child: const Text('Open related load'),
                                    ),
                                  if (item.status == 'queued')
                                    OutlinedButton(
                                      key: ValueKey('claim-${item.id}'),
                                      onPressed: actionState.isLoading ? null : () => _claimCase(context, ref, item.id),
                                      child: const Text('Claim'),
                                    )
                                  else if (item.status == 'claimed')
                                    OutlinedButton(
                                      key: ValueKey('release-${item.id}'),
                                      onPressed: actionState.isLoading ? null : () => _releaseCase(context, ref, item.id),
                                      child: const Text('Release'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (state.hasMore) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: state.isLoading ? null : () => ref.read(adminOperationalCaseQueueProvider.notifier).loadNextPage(),
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
      ),
    );
  }

  Future<void> _claimCase(BuildContext context, WidgetRef ref, String caseId) async {
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).claimCase(caseId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case claimed.' : 'Could not claim this operational case right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not claim this operational case: ${error.toString()}')));
    }
  }

  Future<void> _releaseCase(BuildContext context, WidgetRef ref, String caseId) async {
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).releaseCase(caseId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case released back to queue.' : 'Could not release this operational case right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not release this operational case: ${error.toString()}')));
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected());
  }
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

String _caseTimelineLabel(AdminOperationalCaseItem item) {
  if (item.resolvedAt != null) {
    return 'Created ${_dateTimeLabel(item.createdAt)} • Resolved ${_dateTimeLabel(item.resolvedAt)}';
  }
  return 'Created ${_dateTimeLabel(item.createdAt)} • Updated ${_dateTimeLabel(item.updatedAt)}';
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
