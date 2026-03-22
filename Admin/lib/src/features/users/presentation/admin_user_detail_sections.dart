part of 'admin_user_detail_screen.dart';

class _AdminUserDetailContent extends StatelessWidget {
  final AdminUserDetail detail;
  final AdminUserActionState actionState;
  final TextEditingController reasonController;
  final Future<void> Function(VerificationDocument document) onOpenDocumentPreview;
  final Future<void> Function({required AdminUserListItem profile}) onToggleBan;
  final void Function(String path) onOpenPath;

  const _AdminUserDetailContent({
    required this.detail,
    required this.actionState,
    required this.reasonController,
    required this.onOpenDocumentPreview,
    required this.onToggleBan,
    required this.onOpenPath,
  });

  @override
  Widget build(BuildContext context) {
    final profile = detail.profile;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: profile.isBanned ? AdminColors.errorBg : AdminColors.raisedSurface,
                  child: Icon(
                    profile.role == 'supplier' ? Icons.inventory_2_outlined : Icons.local_shipping_outlined,
                    color: profile.isBanned ? AdminColors.error : AdminColors.accentTeal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName.isEmpty ? 'Unnamed user' : profile.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'User ${profile.id.isEmpty ? '-' : profile.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text('${profile.mobile.isEmpty ? '-' : profile.mobile} • ${profile.email.isEmpty ? '-' : profile.email}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(label: profile.role.toUpperCase(), color: AdminColors.accentTeal),
                          _MetaPill(label: profile.verificationStatus.isEmpty ? 'UNKNOWN' : profile.verificationStatus.toUpperCase(), color: AdminColors.warning),
                          if (profile.isBanned) _MetaPill(label: 'BANNED', color: AdminColors.error),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Profile summary',
          child: Column(
            children: [
              _DetailRow(label: 'Created', value: _dateLabel(profile.createdAt)),
              _DetailRow(label: 'Last login', value: _dateLabel(profile.lastLoginAt)),
              _DetailRow(label: 'Activity count', value: profile.activityCount.toString()),
              _DetailRow(label: 'Ban reason', value: profile.banReason.isEmpty ? '-' : profile.banReason),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Role-specific metadata',
          child: detail.roleMetadata.isEmpty
              ? const Text('No role-specific metadata is available yet.')
              : Column(
                  children: detail.roleMetadata.entries
                      .map((entry) => _DetailRow(label: entry.key, value: entry.value.isEmpty ? '-' : entry.value))
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Stats overview',
          child: detail.stats.isEmpty
              ? const Text('No richer stats are available for this user yet.')
              : Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: detail.stats.entries
                      .map(
                        (entry) => SizedBox(
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
                                  entry.value,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        if (detail.verificationRejectionReason.isNotEmpty ||
            detail.verificationFeedbackSummary.isNotEmpty ||
            detail.verificationFeedbackNextStep.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DetailSectionCard(
            title: 'Verification feedback',
            child: Column(
              children: [
                if (detail.verificationRejectionReason.isNotEmpty)
                  _DetailRow(label: 'Rejection reason', value: detail.verificationRejectionReason),
                if (detail.verificationFeedbackSummary.isNotEmpty)
                  _DetailRow(label: 'Summary', value: detail.verificationFeedbackSummary),
                if (detail.verificationFeedbackNextStep.isNotEmpty)
                  _DetailRow(label: 'Next step', value: detail.verificationFeedbackNextStep),
              ],
            ),
          ),
        ],
        if (detail.latestVerificationCase != null) ...[
          const SizedBox(height: 16),
          _DetailSectionCard(
            title: 'Latest verification case',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (detail.latestVerificationCase!.id.isNotEmpty)
                  _DetailRow(label: 'Case id', value: detail.latestVerificationCase!.id),
                _DetailRow(label: 'Status', value: _titleCaseWords(detail.latestVerificationCase!.status)),
                if (detail.latestVerificationCase!.decisionSummary.isNotEmpty)
                  _DetailRow(label: 'Decision', value: detail.latestVerificationCase!.decisionSummary),
                if (detail.latestVerificationCase!.reviewFeedbackSummary.isNotEmpty)
                  _DetailRow(label: 'Review summary', value: detail.latestVerificationCase!.reviewFeedbackSummary),
                if (detail.latestVerificationCase!.reviewFeedbackNextStep.isNotEmpty)
                  _DetailRow(label: 'Next step', value: detail.latestVerificationCase!.reviewFeedbackNextStep),
                _DetailRow(label: 'Last reviewed', value: _dateLabel(detail.latestVerificationCase!.lastReviewedAt)),
                if (detail.latestVerificationCase!.id.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    key: const ValueKey('admin-user-open-verification-case-button'),
                    onPressed: () => onOpenPath(AdminRoutes.verificationDetailPathFor(detail.latestVerificationCase!.id)),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open verification case'),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Verification documents',
          child: Column(
            children: detail.documents
                .map(
                  (document) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined),
                    title: Text(document.label),
                    subtitle: Text(document.signedUrl.isEmpty ? 'Document uploaded but preview is unavailable right now.' : document.path),
                    trailing: document.signedUrl.isEmpty
                        ? null
                        : TextButton(
                            onPressed: () => onOpenDocumentPreview(document),
                            child: const Text('View document'),
                          ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        if (detail.fleetTrucks.isNotEmpty) ...[
          const SizedBox(height: 16),
          _DetailSectionCard(
            title: 'Fleet',
            child: Column(
              children: detail.fleetTrucks
                  .map(
                    (truck) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.local_shipping_outlined),
                      title: Text(truck.truckNumber.isEmpty ? 'Unnamed truck' : truck.truckNumber),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${truck.modelLabel.isEmpty ? truck.bodyType : truck.modelLabel} • ${truck.tyres} tyres • ${truck.capacityTonnes.isEmpty ? '-' : '${truck.capacityTonnes}T'}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Truck ${truck.id.isEmpty ? '-' : truck.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                          ),
                          if (truck.verificationCaseId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Verification case ${truck.verificationCaseId}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          ],
                          if (truck.verifiedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Verified ${_dateLabel(truck.verifiedAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          ],
                          if (truck.rejectionReason.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Reason: ${truck.rejectionReason}'),
                          ],
                          if (truck.feedbackSummary.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Feedback: ${truck.feedbackSummary}'),
                          ],
                          if (truck.feedbackNextStep.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Next step: ${truck.feedbackNextStep}'),
                          ],
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_titleCaseWords(truck.status), style: Theme.of(context).textTheme.labelMedium),
                          if (truck.verificationCaseStatus.isNotEmpty)
                            Text(
                              _titleCaseWords(truck.verificationCaseStatus),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                          if (truck.verifiedAt != null)
                            Text(_dateLabel(truck.verifiedAt), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                        ],
                      ),
                      onTap: truck.verificationCaseId.isEmpty
                          ? null
                          : () => onOpenPath(AdminRoutes.verificationDetailPathFor(truck.verificationCaseId)),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Recent activity',
          child: detail.recentItems.isEmpty
              ? const Text('No recent activity found.')
              : Column(
                  children: detail.recentItems
                      .map(
                        (item) {
                          final detailPath = _recentActivityDetailPath(profile.role, item.id);
                          return ListTile(
                            key: ValueKey('admin-user-recent-activity-${item.id}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.status),
                                const SizedBox(height: 4),
                                Text(
                                  'Activity ${item.id.isEmpty ? '-' : item.id}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Created ${_dateLabel(item.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_dateLabel(item.createdAt), style: Theme.of(context).textTheme.labelMedium),
                                if (detailPath != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.open_in_new, size: 18),
                                ],
                              ],
                            ),
                            onTap: detailPath == null ? null : () => onOpenPath(detailPath),
                          );
                        },
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Audit history',
          child: detail.auditEntries.isEmpty
              ? const Text('No audit history is available for this user yet.')
              : Column(
                  children: detail.auditEntries
                      .map(
                        (entry) {
                          final detailPath = _auditEntryDetailPath(entry);
                          return ListTile(
                            key: ValueKey('admin-user-audit-entry-${entry.id}'),
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.history_toggle_off_outlined),
                            title: Text(_auditActionLabel(entry.actionType)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.summary.isEmpty ? '${entry.targetObjectType} • ${entry.targetObjectId}' : entry.summary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Audit ${entry.id.isEmpty ? '-' : entry.id}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.targetObjectType.isEmpty ? '-' : entry.targetObjectType} • ${entry.targetObjectId.isEmpty ? '-' : entry.targetObjectId}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Created ${_dateLabel(entry.createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _dateLabel(entry.createdAt),
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                if (detailPath != null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.open_in_new, size: 18),
                                ],
                              ],
                            ),
                            onTap: detailPath == null ? null : () => onOpenPath(detailPath),
                          );
                        },
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: profile.isBanned ? 'Unban account' : 'Ban account',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: profile.isBanned ? 'Optional unban note' : 'Ban reason',
                  hintText: profile.isBanned
                      ? 'Add a note before restoring access'
                      : 'Explain why this account should be banned',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('admin-user-ban-toggle-button'),
                onPressed: actionState.isLoading ? null : () => onToggleBan(profile: profile),
                style: FilledButton.styleFrom(
                  backgroundColor: profile.isBanned ? AdminColors.success : AdminColors.error,
                ),
                child: actionState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(profile.isBanned ? 'Unban account' : 'Ban account'),
              ),
            ],
          ),
        ),
      ],
    );
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

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _auditActionLabel(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return 'Audit event';
  }
  return normalized.replaceAll('_', ' ');
}

String? _auditEntryDetailPath(AdminAuditEntry entry) {
  final objectType = entry.targetObjectType.trim().toLowerCase();
  final objectId = entry.targetObjectId.trim();
  if (objectId.isEmpty) {
    return null;
  }
  return switch (objectType) {
    'support_ticket' => AdminRoutes.supportDetailPathFor(objectId),
    'verification_case' => AdminRoutes.verificationDetailPathFor(objectId),
    'load' => AdminRoutes.loadDetailPathFor(objectId),
    _ => null,
  };
}

String? _recentActivityDetailPath(String role, String itemId) {
  final normalizedRole = role.trim().toLowerCase();
  final normalizedId = itemId.trim();
  if (normalizedId.isEmpty) {
    return null;
  }
  return switch (normalizedRole) {
    'supplier' => AdminRoutes.loadDetailPathFor(normalizedId),
    'trucker' => null,
    _ => null,
  };
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
