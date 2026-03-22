part of 'admin_verification_detail_screen.dart';

class _AdminVerificationDetailContent extends StatelessWidget {
  final AdminVerificationDetail detail;
  final AdminVerificationActionState actionState;
  final TextEditingController rejectionReasonController;
  final TextEditingController feedbackSummaryController;
  final TextEditingController feedbackNextStepController;
  final Map<String, TextEditingController> documentFeedbackControllers;
  final Future<void> Function(VerificationDocument document) onOpenDocumentPreview;
  final Future<void> Function({
    required AdminVerificationDetail detail,
    required VerificationReviewDecision decision,
  }) onSubmitDecision;
  final void Function(String path) onOpenPath;

  const _AdminVerificationDetailContent({
    required this.detail,
    required this.actionState,
    required this.rejectionReasonController,
    required this.feedbackSummaryController,
    required this.feedbackNextStepController,
    required this.documentFeedbackControllers,
    required this.onOpenDocumentPreview,
    required this.onSubmitDecision,
    required this.onOpenPath,
  });

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: AdminColors.raisedSurface,
                  child: Icon(
                    detail.subjectType == 'truck' ? Icons.local_shipping_outlined : Icons.verified_user_outlined,
                    color: AdminColors.accentTeal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.displayName.isEmpty ? 'Verification case' : detail.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(detail.subjectLabel),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(label: _titleCaseWords(detail.caseStatus), color: AdminColors.warning),
                          _MetaPill(label: detail.subjectTypeLabel, color: AdminColors.accentTeal),
                          _MetaPill(label: detail.isClaimed ? 'CLAIMED' : 'UNCLAIMED', color: detail.isClaimed ? AdminColors.success : AdminColors.textSecondary),
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
          title: 'Case summary',
          child: Column(
            children: [
              _DetailRow(label: 'Case id', value: detail.caseId.isEmpty ? '-' : detail.caseId),
              _DetailRow(label: 'Subject id', value: detail.subjectId.isEmpty ? '-' : detail.subjectId),
              _DetailRow(label: 'Subject type', value: detail.subjectTypeLabel.isEmpty ? '-' : detail.subjectTypeLabel),
              _DetailRow(
                label: 'Assigned admin',
                value: detail.assignedAdminUserId.isEmpty
                    ? '-'
                    : (detail.assignedAdminLabel.isEmpty
                        ? detail.assignedAdminUserId
                        : '${detail.assignedAdminLabel} • ${detail.assignedAdminUserId}'),
              ),
              _DetailRow(label: 'Submitted', value: _dateTimeLabel(detail.submittedAt)),
              _DetailRow(label: 'Last reviewed', value: _dateTimeLabel(detail.lastReviewedAt)),
              _DetailRow(label: 'SLA', value: detail.slaLabel),
              _DetailRow(label: 'Decision summary', value: detail.decisionSummary.isEmpty ? '-' : detail.decisionSummary),
              _DetailRow(label: 'Feedback summary', value: detail.reviewFeedbackSummary.isEmpty ? '-' : detail.reviewFeedbackSummary),
              _DetailRow(label: 'Next step', value: detail.reviewFeedbackNextStep.isEmpty ? '-' : detail.reviewFeedbackNextStep),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Subject context',
          child: detail.subjectMetadata.isEmpty
              ? const Text('No subject metadata is available for this verification case yet.')
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...detail.subjectMetadata.entries
                        .map((entry) => _DetailRow(label: entry.key, value: entry.value.isEmpty ? '-' : entry.value)),
                    if (detail.profileLinkId.trim().isNotEmpty)
                      _DetailRow(label: 'Linked profile id', value: detail.profileLinkId),
                    if (detail.profileLinkId.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        key: const ValueKey('verification-open-subject-profile-button'),
                        onPressed: () => onOpenPath(AdminRoutes.userDetailPathFor(detail.profileLinkId)),
                        icon: const Icon(Icons.person_outline),
                        label: Text(detail.profileLinkLabel.isEmpty ? 'Open profile' : detail.profileLinkLabel),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Verification documents',
          child: detail.documents.isEmpty
              ? const Text('No verification documents are available for this case yet.')
              : Column(
                  children: detail.documents
                      .map(
                        (document) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(document.label),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                document.isUploaded
                                    ? (document.signedUrl.isEmpty
                                        ? 'Document uploaded but preview is unavailable right now.'
                                        : document.path)
                                    : 'Document not uploaded yet.',
                              ),
                              if (document.feedbackReason.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Feedback ${document.feedbackReason}'),
                                ),
                            ],
                          ),
                          trailing: !document.isUploaded || document.signedUrl.isEmpty
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
        const SizedBox(height: 16),
        _DetailSectionCard(
          title: 'Review timeline',
          child: detail.events.isEmpty
              ? const Text('No review timeline is available for this case yet.')
              : Column(
                  children: detail.events
                      .map(
                        (event) => ListTile(
                          key: ValueKey('verification-event-${event.id}'),
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
        if (_isReviewable(detail.caseStatus)) ...[
          const SizedBox(height: 16),
          _DetailSectionCard(
            title: 'Review actions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const ValueKey('verification-reject-reason-field'),
                  controller: rejectionReasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Reject reason',
                    hintText: 'Explain what must be corrected before resubmission',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('verification-feedback-summary-field'),
                  controller: feedbackSummaryController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Feedback summary',
                    hintText: 'Summarize the affected documents or issues for the user',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('verification-feedback-next-step-field'),
                  controller: feedbackNextStepController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Next step',
                    hintText: 'Explain exactly what the user should replace or upload before resubmitting',
                  ),
                ),
                if (detail.documents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Document correction guidance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...detail.documents.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        key: ValueKey('verification-document-feedback-${document.backendKey}'),
                        controller: documentFeedbackControllers[document.backendKey],
                        minLines: 1,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: document.label,
                          hintText: 'Optional document-specific correction guidance',
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      key: const ValueKey('verification-approve-button'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => onSubmitDecision(
                                detail: detail,
                                decision: VerificationReviewDecision.approve,
                              ),
                      style: FilledButton.styleFrom(backgroundColor: AdminColors.success),
                      child: actionState.isLoading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Approve'),
                    ),
                    FilledButton(
                      key: const ValueKey('verification-reject-button'),
                      onPressed: actionState.isLoading
                          ? null
                          : () => onSubmitDecision(
                                detail: detail,
                                decision: VerificationReviewDecision.reject,
                              ),
                      style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.raisedSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.textSecondary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current review contract',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.subjectType == 'truck'
                            ? 'This truck review currently supports approve/reject through the live truck verification contract. Packet-level summary remains required, and structured feedback can now capture document-aware correction guidance for truck resubmission. Request-more-details and escalate remain unavailable until dedicated backend authority lands.'
                            : 'This verification review currently supports approve/reject only through the live case review contract. Packet-level summary remains required, and structured feedback is the canonical correction path for document-aware resubmission guidance. Request-more-details and escalate remain unavailable until dedicated backend authority lands.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

bool _isReviewable(String value) {
  return const {'submitted', 'queued', 'in_review', 'waiting_for_resubmission'}.contains(value.trim());
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
