import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_operational_case_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_operational_case_providers.dart';

class AdminOperationalCaseDetailScreen extends ConsumerStatefulWidget {
  final String caseId;

  const AdminOperationalCaseDetailScreen({super.key, required this.caseId});

  @override
  ConsumerState<AdminOperationalCaseDetailScreen> createState() => _AdminOperationalCaseDetailScreenState();
}

class _AdminOperationalCaseDetailScreenState extends ConsumerState<AdminOperationalCaseDetailScreen> {
  final _summaryController = TextEditingController();
  final _noteController = TextEditingController();
  final _resolutionController = TextEditingController();
  final _escalationReasonController = TextEditingController();
  String? _selectedEscalationTargetId;

  @override
  void dispose() {
    _summaryController.dispose();
    _noteController.dispose();
    _resolutionController.dispose();
    _escalationReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminOperationalCaseDetailProvider(widget.caseId));
    final actionState = ref.watch(adminOperationalCaseActionProvider);
    final escalationTargetsAsync = ref.watch(adminOperationalEscalationTargetsProvider);

    return detailAsync.when(
      data: (detail) {
        if (detail == null) {
          return const Center(child: Text('Operational case not found.'));
        }
        final item = detail.item;
        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.businessLabel, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(label: _titleCaseWords(item.status), color: AdminColors.warning),
                        _MetaPill(label: _titleCaseWords(item.caseType), color: AdminColors.accentTeal),
                        _MetaPill(
                          label: item.claimedByLabel.isEmpty ? 'UNCLAIMED' : 'CLAIMED',
                          color: item.claimedByLabel.isEmpty ? AdminColors.textSecondary : AdminColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Case id', value: item.id.isEmpty ? '-' : item.id),
                    _DetailRow(label: 'Queue', value: item.queueClassification.isEmpty ? '-' : _titleCaseWords(item.queueClassification)),
                    _DetailRow(
                      label: 'Primary object',
                      value: '${item.primaryObjectType.isEmpty ? '-' : item.primaryObjectType} • ${item.primaryObjectId.isEmpty ? '-' : item.primaryObjectId}',
                    ),
                    _DetailRow(
                      label: 'Claimed by',
                      value: item.claimedByAdminUserId.isEmpty
                          ? '-'
                          : (item.claimedByLabel.isEmpty
                              ? item.claimedByAdminUserId
                              : '${item.claimedByLabel} • ${item.claimedByAdminUserId}'),
                    ),
                    _DetailRow(
                      label: 'Escalated to',
                      value: item.escalatedToAdminUserId.isEmpty
                          ? '-'
                          : (item.escalatedToLabel.isEmpty
                              ? item.escalatedToAdminUserId
                              : '${item.escalatedToLabel} • ${item.escalatedToAdminUserId}'),
                    ),
                    _DetailRow(label: 'Waiting reason', value: item.waitingReason.isEmpty ? '-' : item.waitingReason),
                    _DetailRow(label: 'Resolution summary', value: item.resolutionSummary.isEmpty ? '-' : item.resolutionSummary),
                    _DetailRow(label: 'Created', value: _dateTimeLabel(item.createdAt)),
                    _DetailRow(label: 'Updated', value: _dateTimeLabel(item.updatedAt)),
                    _DetailRow(label: 'Resolved', value: _dateTimeLabel(item.resolvedAt)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Case context',
              child: Column(
                children: detail.contextMetadata.entries
                    .map((entry) => _DetailRow(label: entry.key, value: entry.value.isEmpty ? '-' : entry.value))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Linked object context',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...detail.linkedObjectMetadata.entries
                      .map((entry) => _DetailRow(label: entry.key, value: entry.value.isEmpty ? '-' : entry.value)),
                  if ((detail.linkedObjectMetadata['Trip id'] ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Trip context is visible on this operational case, but a dedicated admin trip-detail route is not available in the current shell yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                    ),
                  if ((detail.linkedObjectMetadata['Load id'] ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('ops-open-related-load-button'),
                      onPressed: () => context.go(
                        AdminRoutes.loadDetailPathFor((detail.linkedObjectMetadata['Load id'] ?? '').trim()),
                      ),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Open related load'),
                    ),
                  ],
                  if ((detail.linkedObjectMetadata['Supplier id'] ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('ops-open-supplier-button'),
                      onPressed: () => context.go(
                        AdminRoutes.userDetailPathFor((detail.linkedObjectMetadata['Supplier id'] ?? '').trim()),
                      ),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Open supplier'),
                    ),
                  ],
                  if ((detail.linkedObjectMetadata['Trucker id'] ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('ops-open-trucker-button'),
                      onPressed: () => context.go(
                        AdminRoutes.userDetailPathFor((detail.linkedObjectMetadata['Trucker id'] ?? '').trim()),
                      ),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Open trucker'),
                    ),
                  ] else if ((detail.linkedObjectMetadata['Assigned trucker id'] ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      key: const ValueKey('ops-open-trucker-button'),
                      onPressed: () => context.go(
                        AdminRoutes.userDetailPathFor((detail.linkedObjectMetadata['Assigned trucker id'] ?? '').trim()),
                      ),
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Open trucker'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Timeline',
              child: detail.events.isEmpty
                  ? const Text('No operational case history is available yet.')
                  : Column(
                      children: detail.events
                          .map(
                            (event) => ListTile(
                              key: ValueKey('ops-event-${event.id}'),
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.history_toggle_off_outlined),
                              title: Text(_titleCaseWords(event.eventType)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(event.summary.isEmpty ? '-' : event.summary),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Event ${event.id.isEmpty ? '-' : event.id}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Created ${_dateTimeLabel(event.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                  ),
                                  if (event.internalNote.isNotEmpty)
                                    Text(
                                      'Internal note ${event.internalNote}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                    ),
                                ],
                              ),
                              trailing: Text(_dateTimeLabel(event.createdAt), style: Theme.of(context).textTheme.labelMedium),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Current lifecycle contract',
              child: Text(
                'Claim, release, waiting transitions, review transitions, resolve/reject, and super-admin escalation are live on this operational case surface. Waiting transitions require a summary or internal note, and resolve/reject actions require a resolution summary. Related trip context is currently read-only here until a dedicated admin trip-detail route lands.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            _DetailSectionCard(
              title: 'Lifecycle actions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('ops-summary-field'),
                    controller: _summaryController,
                    decoration: const InputDecoration(
                      labelText: 'Action summary',
                      hintText: 'Short summary for the transition or review update',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('ops-note-field'),
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Internal note',
                      hintText: 'Internal context for waiting transitions',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (item.claimedByAdminUserId.isEmpty)
                        OutlinedButton(
                          key: const ValueKey('ops-claim-button'),
                          onPressed: actionState.isLoading ? null : _claim,
                          child: const Text('Claim case'),
                        )
                      else
                        OutlinedButton(
                          key: const ValueKey('ops-release-button'),
                          onPressed: actionState.isLoading ? null : _release,
                          child: const Text('Release claim'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        key: const ValueKey('ops-transition-review-button'),
                        onPressed: actionState.isLoading ? null : () => _transition(OperationalCaseTransitionTarget.inReview),
                        child: const Text('Move to Review'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('ops-transition-user-button'),
                        onPressed: actionState.isLoading ? null : () => _transition(OperationalCaseTransitionTarget.waitingForUser),
                        child: const Text('Wait for User'),
                      ),
                      OutlinedButton(
                        key: const ValueKey('ops-transition-external-button'),
                        onPressed: actionState.isLoading ? null : () => _transition(OperationalCaseTransitionTarget.waitingForExternal),
                        child: const Text('Wait for External'),
                      ),
                      if (item.status == 'resolved' || item.status == 'rejected')
                        OutlinedButton(
                          key: const ValueKey('ops-transition-close-button'),
                          onPressed: actionState.isLoading ? null : () => _transition(OperationalCaseTransitionTarget.closed),
                          child: const Text('Close case'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('ops-resolution-field'),
                    controller: _resolutionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Resolution summary',
                      hintText: 'Required for resolve or reject actions',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        key: const ValueKey('ops-resolve-button'),
                        onPressed: actionState.isLoading ? null : () => _resolve(OperationalCaseResolutionTarget.resolved),
                        style: FilledButton.styleFrom(backgroundColor: AdminColors.success),
                        child: const Text('Resolve'),
                      ),
                      FilledButton(
                        key: const ValueKey('ops-reject-button'),
                        onPressed: actionState.isLoading ? null : () => _resolve(OperationalCaseResolutionTarget.rejected),
                        style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  escalationTargetsAsync.when(
                    data: (targets) {
                      if (targets.isEmpty) {
                        return const Text('No active super admin escalation targets are available right now.');
                      }
                      _selectedEscalationTargetId ??= targets.first.id;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            key: const ValueKey('ops-escalation-target-field'),
                            initialValue: targets.any((target) => target.id == _selectedEscalationTargetId)
                                ? _selectedEscalationTargetId
                                : targets.first.id,
                            decoration: const InputDecoration(labelText: 'Escalate to super admin'),
                            items: targets
                                .map(
                                  (target) => DropdownMenuItem<String>(
                                    value: target.id,
                                    child: Text(target.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: actionState.isLoading
                                ? null
                                : (value) {
                                    setState(() {
                                      _selectedEscalationTargetId = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const ValueKey('ops-escalation-reason-field'),
                            controller: _escalationReasonController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Escalation reason',
                              hintText: 'Optional reason for the super admin handoff',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const ValueKey('ops-escalate-button'),
                            onPressed: actionState.isLoading ? null : _escalate,
                            child: const Text('Escalate'),
                          ),
                        ],
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stackTrace) => const Text('Unable to load escalation targets right now.'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AdminColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading operational case detail',
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
                onPressed: () => ref.invalidate(adminOperationalCaseDetailProvider(widget.caseId)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _transition(OperationalCaseTransitionTarget target) async {
    final summary = _summaryController.text.trim();
    final internalNote = _noteController.text.trim();
    if (
        (target == OperationalCaseTransitionTarget.waitingForUser ||
                target == OperationalCaseTransitionTarget.waitingForExternal) &&
            summary.isEmpty &&
            internalNote.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter a summary or internal note before moving this case into a waiting state.')),
        );
      return;
    }
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).transitionCase(
            caseId: widget.caseId,
            target: target,
            summary: summary,
            internalNote: internalNote,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case updated.' : 'Could not update this operational case right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseDetailProvider(widget.caseId));
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not update this operational case: ${error.toString()}')));
    }
  }

  Future<void> _resolve(OperationalCaseResolutionTarget target) async {
    final summary = _resolutionController.text.trim();
    if (summary.length < 5) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enter at least 5 characters before resolving or rejecting a case.')));
      return;
    }
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).resolveCase(
            caseId: widget.caseId,
            target: target,
            summary: summary,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case decision saved.' : 'Could not save this operational case decision right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseDetailProvider(widget.caseId));
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not save this operational case decision: ${error.toString()}')));
    }
  }

  Future<void> _escalate() async {
    final targetId = (_selectedEscalationTargetId ?? '').trim();
    if (targetId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Select a super admin target before escalating this case.')));
      return;
    }
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).escalateCase(
            caseId: widget.caseId,
            targetAdminUserId: targetId,
            reason: _escalationReasonController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case escalated successfully.' : 'Could not escalate this operational case right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseDetailProvider(widget.caseId));
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not escalate this operational case: ${error.toString()}')));
    }
  }

  Future<void> _claim() async {
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).claimCase(widget.caseId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case claimed successfully.' : 'Could not claim this operational case right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseDetailProvider(widget.caseId));
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not claim this operational case: ${error.toString()}')));
    }
  }

  Future<void> _release() async {
    try {
      final ok = await ref.read(adminOperationalCaseActionProvider.notifier).releaseCase(widget.caseId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(ok ? 'Operational case released successfully.' : 'Could not release this operational case right now.')));
      if (ok) {
        ref.invalidate(adminOperationalCaseDetailProvider(widget.caseId));
        ref.invalidate(adminOperationalCaseQueueProvider);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Could not release this operational case: ${error.toString()}')));
    }
  }
}

class _DetailSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
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
