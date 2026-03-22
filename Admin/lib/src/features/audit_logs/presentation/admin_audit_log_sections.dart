part of 'admin_audit_log_screen.dart';

class _AdminAuditLogContent extends StatelessWidget {
  final AdminAuditLogState state;
  final WidgetRef ref;
  final Future<void> Function(BuildContext context, AdminAuditLogEntry entry) onOpenDetail;

  const _AdminAuditLogContent({
    required this.state,
    required this.ref,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text(
          'Audit logs',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Inspect internal admin events, trust-safety actions, verification outcomes, and operational audit trails from the live `audit_logs` table.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => ref.read(adminAuditLogProvider.notifier).updateSearch(value),
          decoration: const InputDecoration(
            labelText: 'Search audit logs',
            hintText: 'Action, summary, actor admin, or object id',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: state.query.actorType.isEmpty ? '' : state.query.actorType,
                decoration: const InputDecoration(labelText: 'Actor type'),
                items: _auditActorTypeOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(_auditActorTypeLabel(option)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => ref.read(adminAuditLogProvider.notifier).updateActorType(value ?? ''),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: state.query.targetObjectType.isEmpty ? '' : state.query.targetObjectType,
                decoration: const InputDecoration(labelText: 'Object type'),
                items: _auditTargetObjectTypeOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option,
                        child: Text(_auditTargetObjectTypeLabel(option)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) => ref.read(adminAuditLogProvider.notifier).updateTargetObjectType(value ?? ''),
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('audit-log-start-date-button'),
              onPressed: () => _pickStartDate(context, ref, state.query),
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                state.query.startDate == null ? 'Start date' : 'Start ${_dateOnlyLabel(state.query.startDate)}',
              ),
            ),
            OutlinedButton.icon(
              key: const ValueKey('audit-log-end-date-button'),
              onPressed: () => _pickEndDate(context, ref, state.query),
              icon: const Icon(Icons.event_outlined),
              label: Text(
                state.query.endDate == null ? 'End date' : 'End ${_dateOnlyLabel(state.query.endDate)}',
              ),
            ),
            if (state.query.startDate != null || state.query.endDate != null)
              TextButton(
                key: const ValueKey('audit-log-clear-dates-button'),
                onPressed: () => ref.read(adminAuditLogProvider.notifier).updateDateRange(
                      startDate: null,
                      endDate: null,
                    ),
                child: const Text('Clear dates'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AdminAuditLogFilter.values.map((filter) {
            final selected = filter == state.query.filter;
            return ChoiceChip(
              label: Text(_filterLabel(filter)),
              selected: selected,
              onSelected: (_) => ref.read(adminAuditLogProvider.notifier).updateFilter(filter),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(label: 'Total logs', value: state.summary.totalCount.toString()),
            _SummaryCard(label: 'Internal', value: state.summary.internalCount.toString()),
            _SummaryCard(label: 'User actions', value: state.summary.userActionCount.toString()),
            _SummaryCard(label: 'Admin actions', value: state.summary.adminActionCount.toString()),
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
                        'Events',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => ref.read(adminAuditLogProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.items.isEmpty)
                  const Text('No audit logs matched the current filter.')
                else
                  ...state.items.map(
                    (entry) => ListTile(
                      key: ValueKey('audit-log-entry-${entry.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history_toggle_off_outlined),
                      title: Text(_actionLabel(entry.actionType)),
                      onTap: () => onOpenDetail(context, entry),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.summary.isEmpty
                                ? '${entry.targetObjectType} • ${entry.targetObjectId.isEmpty ? '-' : entry.targetObjectId}'
                                : entry.summary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actor type ${entry.actorType.isEmpty ? '-' : entry.actorType} • Visibility ${entry.visibilityClass.isEmpty ? 'visible' : entry.visibilityClass} • Target ${entry.targetObjectType.isEmpty ? '-' : entry.targetObjectType}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Audit ${entry.id.isEmpty ? '-' : entry.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Actor ${entry.actorAdminUserId.isEmpty ? '-' : (entry.actorAdminLabel.isEmpty ? entry.actorAdminUserId : '${entry.actorAdminLabel} • ${entry.actorAdminUserId}')}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Target ${entry.targetObjectType.isEmpty ? '-' : entry.targetObjectType} • ${entry.targetObjectId.isEmpty ? '-' : entry.targetObjectId}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created ${_dateLabel(entry.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                          if (entry.secondaryObjectId.isNotEmpty || entry.secondaryObjectType.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Secondary ${entry.secondaryObjectType.isEmpty ? '-' : entry.secondaryObjectType} • ${entry.secondaryObjectId.isEmpty ? '-' : entry.secondaryObjectId}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          ],
                          if (_auditEntryDetailPath(entry) case final detailPath?) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: ValueKey('audit-open-related-${entry.id}'),
                              onPressed: () => context.go(detailPath),
                              child: const Text('Open related item'),
                            ),
                          ],
                          if (_auditSecondaryEntryDetailPath(entry) case final secondaryDetailPath?) ...[
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: ValueKey('audit-open-secondary-${entry.id}'),
                              onPressed: () => context.go(secondaryDetailPath),
                              child: const Text('Open secondary item'),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        _dateLabel(entry.createdAt),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                if (state.hasMore) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: state.isLoading ? null : () => ref.read(adminAuditLogProvider.notifier).loadNextPage(),
                      child: Text(state.isLoading ? 'Loading…' : 'Load more'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const List<String> _auditActorTypeOptions = <String>[
  '',
  'admin',
  'user',
  'system',
];

const List<String> _auditTargetObjectTypeOptions = <String>[
  '',
  'profile',
  'support_ticket',
  'verification_case',
  'operational_case',
  'load',
  'admin_user',
];

String _auditActorTypeLabel(String value) {
  return switch (value) {
    '' => 'All actor types',
    'admin' => 'Admin',
    'user' => 'User',
    'system' => 'System',
    _ => value,
  };
}

String _auditTargetObjectTypeLabel(String value) {
  return switch (value) {
    '' => 'All object types',
    'profile' => 'Profile',
    'support_ticket' => 'Support ticket',
    'verification_case' => 'Verification case',
    'operational_case' => 'Operational case',
    'load' => 'Load',
    'admin_user' => 'Admin user',
    _ => value,
  };
}

String? _auditEntryDetailPath(AdminAuditLogEntry entry) {
  final objectType = entry.targetObjectType.trim().toLowerCase();
  final objectId = entry.targetObjectId.trim();
  if (objectId.isEmpty) {
    return null;
  }
  return switch (objectType) {
    'profile' => AdminRoutes.userDetailPathFor(objectId),
    'support_ticket' => AdminRoutes.supportDetailPathFor(objectId),
    'verification_case' => AdminRoutes.verificationDetailPathFor(objectId),
    'operational_case' => AdminRoutes.operationalCaseDetailPathFor(objectId),
    'load' => AdminRoutes.loadDetailPathFor(objectId),
    _ => null,
  };
}

String? _auditSecondaryEntryDetailPath(AdminAuditLogEntry entry) {
  final objectType = entry.secondaryObjectType.trim().toLowerCase();
  final objectId = entry.secondaryObjectId.trim();
  if (objectId.isEmpty) {
    return null;
  }
  return switch (objectType) {
    'profile' => AdminRoutes.userDetailPathFor(objectId),
    'support_ticket' => AdminRoutes.supportDetailPathFor(objectId),
    'verification_case' => AdminRoutes.verificationDetailPathFor(objectId),
    'operational_case' => AdminRoutes.operationalCaseDetailPathFor(objectId),
    'load' => AdminRoutes.loadDetailPathFor(objectId),
    _ => null,
  };
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
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _filterLabel(AdminAuditLogFilter filter) {
  return switch (filter) {
    AdminAuditLogFilter.all => 'All logs',
    AdminAuditLogFilter.userActions => 'User actions',
    AdminAuditLogFilter.adminActions => 'Admin actions',
    AdminAuditLogFilter.internalOnly => 'Internal only',
  };
}

String _actionLabel(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Audit event';
  }
  return normalized.replaceAll('_', ' ');
}

String _dateLabel(DateTime? value) {
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

String _dateOnlyLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
