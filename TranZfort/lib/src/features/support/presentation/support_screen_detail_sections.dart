part of 'support_screen.dart';

class _SupportTicketDetailSection extends StatelessWidget {
  final String? selectedTicketId;
  final AsyncValue<SupportTicketDetail>? detailAsync;

  const _SupportTicketDetailSection({
    required this.selectedTicketId,
    required this.detailAsync,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (selectedTicketId == null || detailAsync == null) {
      return EmptyStateView(
        icon: Icons.support_outlined,
        title: l10n.supportSelectTicketTitle,
        subtitle: l10n.supportSelectTicketSubtitle,
      );
    }
    final resolvedDetailAsync = detailAsync!;
    if (resolvedDetailAsync.isLoading) {
      return const LoadingShimmer(height: 110, itemCount: 2);
    }
    if (resolvedDetailAsync.hasError) {
      return WarningBlock(
        title: l10n.supportDetailUnavailableTitle,
        message: l10n.supportDetailUnavailableMessage,
      );
    }

    final detail = resolvedDetailAsync.valueOrNull;
    if (detail == null) {
      return EmptyStateView(
        icon: Icons.support_outlined,
        title: l10n.supportTicketUnavailableTitle,
        subtitle: l10n.supportTicketUnavailableSubtitle,
      );
    }
    final latestVisibleMessage = detail.messages.isEmpty ? null : detail.messages.last;
    final hasVisibleAttachments = detail.messages.any((message) => message.hasAttachment);

    return Column(
      children: [
        StandardListCard(
          accent: _ticketStatusPalette(detail.ticket.status).foreground,
          title: _supportTicketTitle(detail.ticket, l10n),
          subtitle: _supportOpenedAt(_formatDateTime(context, detail.ticket.createdAt), l10n),
          trailing: StatusChip(label: _ticketStatusLabel(detail.ticket.status, l10n)),
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isDisputeTicket(detail.ticket)) ...[
                Text(
                  _supportDisputeCategoryLabel(_disputeCategoryLabel(detail.ticket.category, l10n), l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(_supportTicketIdValue(detail.ticket.id, l10n), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _supportPriorityValue(_ticketPriorityLabel(detail.ticket.priority, l10n), l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _supportLastUpdatedValue(_formatDateTime(context, detail.ticket.updatedAt), l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (detail.ticket.relatedTripId != null)
                ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(_supportRelatedTripValue(detail.ticket.relatedTripId!, l10n), style: Theme.of(context).textTheme.bodySmall),
                ],
              if (detail.ticket.relatedLoadId != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(_supportRelatedLoadValue(detail.ticket.relatedLoadId!, l10n), style: Theme.of(context).textTheme.bodySmall),
              ],
              if (detail.ticket.relatedTripId != null || detail.ticket.relatedLoadId != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (detail.ticket.relatedTripId != null)
                      TextActionButton(
                        key: const ValueKey('support-open-related-trip-button'),
                        label: _supportOpenRelatedTripAction(l10n),
                        onPressed: () => context.go('${AppRoutes.tripDetailPath}/${detail.ticket.relatedTripId}'),
                      ),
                    if (detail.ticket.relatedLoadId != null)
                      TextActionButton(
                        key: const ValueKey('support-open-related-load-button'),
                        label: _supportOpenRelatedLoadAction(l10n),
                        onPressed: () => context.go('${AppRoutes.loadDetailPath}/${detail.ticket.relatedLoadId}'),
                      ),
                  ],
                ),
              ],
              if ((detail.ticket.resolutionSummary ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _supportResolutionValue(detail.ticket.resolutionSummary!, l10n),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (_isDisputeTicket(detail.ticket)) ...[
          const SizedBox(height: AppSpacing.md),
          WarningBlock(
            title: _disputeBannerTitle(detail.ticket.status, l10n),
            message: _disputeBannerMessage(detail.ticket, l10n),
          ),
          const SizedBox(height: AppSpacing.md),
          DetailSectionCard(
            title: _supportEvidenceVisibilityTitle(l10n),
            children: [
              Text(
                _evidenceVisibilitySummary(detail.ticket.status, l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _restrictedEvidenceMessage(detail.ticket.status, l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _additionalProofGuidance(detail.ticket.status, l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        DetailSectionCard(
          title: _supportVisibleThreadSummaryTitle(l10n),
          children: [
            Text(
              _supportVisibleRepliesCount(detail.messages.length, l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              latestVisibleMessage == null
                  ? _supportLastVisibleUpdateNone(l10n)
                  : _supportLastVisibleUpdate(_formatDateTime(context, latestVisibleMessage.createdAt), l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              latestVisibleMessage == null
                  ? _supportLatestVisibleSenderNone(l10n)
                  : _supportLatestVisibleSender(_messageSenderLabel(latestVisibleMessage, l10n), l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasVisibleAttachments
                  ? _supportVisibleAttachmentSummaryPresent(l10n)
                  : _supportVisibleAttachmentSummaryAbsent(l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (detail.messages.isEmpty)
          EmptyStateView(
            icon: Icons.forum_outlined,
            title: _supportNoVisibleThreadTitle(l10n),
            subtitle: _emptyThreadSubtitle(detail.ticket.status, l10n),
          )
        else
          Column(
            children: [
              for (var index = 0; index < detail.messages.length; index++) ...[
                _SupportMessageCard(
                  message: detail.messages[index],
                  ticketStatus: detail.ticket.status,
                  isDisputeTicket: _isDisputeTicket(detail.ticket),
                ),
                if (index != detail.messages.length - 1) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        DetailSectionCard(
          title: _supportCurrentWorkflowTitle(l10n),
          children: [
            Text(
              _workflowStatusGuidance(detail.ticket.status, l10n),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (detail.ticket.isResolved && (detail.ticket.resolutionSummary ?? '').trim().isNotEmpty) ...[
          DetailSectionCard(
            title: _supportResolutionOutcomeTitle(l10n),
            children: [
              if (detail.ticket.resolvedAt != null) ...[
                Text(
                  _supportResolvedOn(_formatDateTime(context, detail.ticket.resolvedAt!), l10n),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                detail.ticket.resolutionSummary!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (detail.ticket.status == SupportTicketStatus.waitingForUser) ...[
          WarningBlock(
            title: _supportWaitingForReplyTitle(l10n),
            message: _supportWaitingForReplyMessage(l10n),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (!detail.ticket.isResolved) ...[
          DetailSectionCard(
            title: _supportReplyGuidanceTitle(l10n),
            children: [
              Text(
                _replyGuidancePrimary(detail.ticket, l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _replyGuidanceSecondary(detail.ticket, l10n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (detail.ticket.isResolved)
          WarningBlock(
            title: _supportRepliesClosedTitle(l10n),
            message: _supportRepliesClosedMessage(l10n),
          )
        else
          SupportReplyComposer(ticketId: detail.ticket.id),
      ],
    );
  }
}

class _SupportMessageCard extends StatelessWidget {
  final SupportTicketMessage message;
  final SupportTicketStatus ticketStatus;
  final bool isDisputeTicket;

  const _SupportMessageCard({
    required this.message,
    required this.ticketStatus,
    required this.isDisputeTicket,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSupport = message.senderType == SupportMessageSenderType.support;
    return StandardListCard(
      accent: isSupport ? AppColors.primary : AppColors.secondary,
      title: isSupport ? _supportSupportTeamLabel(l10n) : _supportYouLabel(l10n),
      subtitle: _formatDateTime(context, message.createdAt),
      trailing: StatusChip(label: isSupport ? _supportReplyStatusReply(l10n) : _supportReplyStatusSubmitted(l10n)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (message.messageBody ?? '').trim().isEmpty ? _supportNoMessageTextProvided(l10n) : message.messageBody!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (message.hasAttachment) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _attachmentVisibilityMessage(ticketStatus, isDisputeTicket, l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _attachmentGuidanceMessage(ticketStatus, isDisputeTicket, l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
