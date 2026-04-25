import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../auth/data/auth_repository.dart';
import '../../shell/presentation/shell_components.dart';
import '../data/support_repository.dart';
import 'support_compose_widgets.dart';
import '../providers/support_providers.dart';

part 'support_screen_list_sections.dart';
part 'support_screen_detail_sections.dart';

class SupportScreen extends ConsumerStatefulWidget {
  final String? initialSelectedTicketId;

  const SupportScreen({
    super.key,
    this.initialSelectedTicketId,
  });

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

String _localizedSupportTrustStatus(AppLocalizations l10n, String? status) {
  final trimmed = (status ?? '').trim().toLowerCase();
  if (trimmed.isEmpty) {
    return _supportTrustStatusLoading(l10n);
  }
  return l10n.supportTrustStatusValue(trimmed);
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(currentAuthStateProvider);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final ticketsState = ref.watch(supportTicketsProvider);
    final selectedTicketState = ref.watch(supportSelectedTicketIdProvider);
    final initialSelectedTicketId = widget.initialSelectedTicketId?.trim();
    final preferredSelectedTicketId =
        selectedTicketState != null && selectedTicketState.trim().isNotEmpty ? selectedTicketState.trim() : initialSelectedTicketId;
    final isSupplier = authState.role == AppUserRole.supplier;
    final knownTicketIds = ticketsState.tickets.map((ticket) => ticket.id).toSet();
    final selectedTicketId = (preferredSelectedTicketId != null &&
            (preferredSelectedTicketId == initialSelectedTicketId || knownTicketIds.contains(preferredSelectedTicketId)))
        ? preferredSelectedTicketId
        : (ticketsState.tickets.isNotEmpty ? ticketsState.tickets.first.id : null);
    final selectedDetailAsync = selectedTicketId == null
        ? null
        : ref.watch(supportTicketDetailProvider(selectedTicketId));

    return DetailPageScaffold(
      title: l10n.supportScreenTitle,
      children: [
        HeroActionCard(
          title: l10n.supportHeroTitle,
          subtitle: isSupplier
              ? l10n.supportHeroSubtitleSupplier
              : l10n.supportHeroSubtitleTrucker,
          useDarkTheme: true,
          primaryAction: GradientButton(
            label: l10n.supportCreateTicketAction,
            onPressed: () => context.push(AppRoutes.createSupportTicketPath),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  StatusBadge(
                    label: ticketsState.tickets.isEmpty
                        ? l10n.supportNoActiveTickets
                        : l10n.supportActiveTicketCount(
                            ticketsState.tickets.length,
                            ticketsState.tickets.length == 1 ? '' : 's',
                          ),
                    icon: Icons.support_agent_outlined,
                  ),
                  if (profile != null)
                    StatusBadge(
                      label: l10n.supportTrustBadge(_localizedSupportTrustStatus(l10n, profile.trustSafetyStatus)),
                      icon: Icons.verified_user_outlined,
                      palette: _trustPalette(profile),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.supportIntroMessage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        SectionCard(
          title: l10n.supportTicketSummaryTitle,
          child: Column(
            children: [
              InfoRow(
                label: l10n.supportEscalationPathLabel,
                value: isSupplier
                    ? l10n.supportEscalationPathSupplier
                    : l10n.supportEscalationPathTrucker,
              ),
              const SizedBox(height: AppSpacing.md),
              InfoRow(
                label: l10n.supportCurrentTrustStatusLabel,
                value: profile == null
                    ? _supportTrustStatusLoading(l10n)
                    : _localizedSupportTrustStatus(l10n, profile.trustSafetyStatus),
              ),
            ],
          ),
        ),
        SectionCard(
          title: l10n.supportMyTicketsTitle,
          child: _SupportTicketListSection(
            state: ticketsState,
            selectedTicketId: selectedTicketId,
            onRetry: () => ref.read(supportTicketsProvider.notifier).load(),
            onLoadMore: () => ref.read(supportTicketsProvider.notifier).loadMore(),
            onCreateTicket: () => context.push(AppRoutes.createSupportTicketPath),
            onSelect: (ticketId) {
              ref.read(supportSelectedTicketIdProvider.notifier).state = ticketId;
            },
          ),
        ),
        SectionCard(
          title: l10n.supportSelectedTicketAndReplyTitle,
          child: _SupportTicketDetailSection(
            selectedTicketId: selectedTicketId,
            detailAsync: selectedDetailAsync,
          ),
        ),
      ],
    );
  }

  StatusPalette _trustPalette(UserProfile profile) {
    final trustStatus = profile.trustSafetyStatus.trim().toLowerCase();
    return switch (trustStatus) {
      'warned' => const StatusPalette(
          foreground: AppColors.warning,
          background: AppColors.warningBg,
        ),
      'restricted' || 'suspended' || 'banned' => const StatusPalette(
          foreground: AppColors.error,
          background: AppColors.errorBg,
        ),
      _ => const StatusPalette(
          foreground: AppColors.success,
          background: AppColors.successBg,
        ),
    };
  }
}

StatusPalette _ticketStatusPalette(SupportTicketStatus status) {
  return switch (status) {
    SupportTicketStatus.open => const StatusPalette(
        foreground: AppColors.warning,
        background: AppColors.warningBg,
      ),
    SupportTicketStatus.inProgress => const StatusPalette(
        foreground: AppColors.info,
        background: AppColors.infoBg,
      ),
    SupportTicketStatus.waitingForUser => const StatusPalette(
        foreground: AppColors.secondary,
        background: AppColors.neutralBg,
      ),
    SupportTicketStatus.resolved || SupportTicketStatus.closed => const StatusPalette(
        foreground: AppColors.success,
        background: AppColors.successBg,
      ),
    SupportTicketStatus.unknown => const StatusPalette(
        foreground: AppColors.textSecondary,
        background: AppColors.neutralBg,
      ),
  };
}

String _ticketStatusLabel(SupportTicketStatus status, AppLocalizations l10n) {
  final statusValue = switch (status) {
    SupportTicketStatus.open => 'open',
    SupportTicketStatus.inProgress => 'in_progress',
    SupportTicketStatus.waitingForUser => 'waiting_for_you',
    SupportTicketStatus.resolved => 'resolved',
    SupportTicketStatus.closed => 'closed',
    SupportTicketStatus.unknown => 'unknown',
  };
  return l10n.supportTicketStatusValue(statusValue);
}

String _ticketPriorityLabel(SupportTicketPriority priority, AppLocalizations l10n) {
  final priorityValue = switch (priority) {
    SupportTicketPriority.low => 'low',
    SupportTicketPriority.medium => 'medium',
    SupportTicketPriority.high => 'high',
    SupportTicketPriority.urgent => 'urgent',
    SupportTicketPriority.unknown => 'not_set',
  };
  return l10n.supportTicketPriorityValue(priorityValue);
}

String _workflowStatusGuidance(SupportTicketStatus status, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.open => l10n.supportWorkflowGuidanceOpen,
    SupportTicketStatus.inProgress => l10n.supportWorkflowGuidanceInProgress,
    SupportTicketStatus.waitingForUser => l10n.supportWorkflowGuidanceWaitingForUser,
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportWorkflowGuidanceResolved,
    SupportTicketStatus.unknown => l10n.supportWorkflowGuidanceUnknown,
  };
}

String _disputeBannerTitle(SupportTicketStatus status, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.commonDisputeReviewClosedTitle,
    SupportTicketStatus.waitingForUser => l10n.supportDisputeBannerTitleWaiting,
    _ => l10n.supportDisputeBannerTitleInProgress,
  };
}

String _disputeBannerMessage(SupportTicket ticket, AppLocalizations l10n) {
  final category = _disputeCategoryLabel(ticket.category, l10n);
  return switch (ticket.status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportDisputeBannerMessageClosed(category),
    SupportTicketStatus.waitingForUser => l10n.supportDisputeBannerMessageWaiting(category),
    _ => l10n.supportDisputeBannerMessageInProgress(category),
  };
}

String _evidenceVisibilitySummary(SupportTicketStatus status, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportEvidenceVisibilitySummaryClosed,
    _ => l10n.supportEvidenceVisibilitySummaryInProgress,
  };
}

String _restrictedEvidenceMessage(SupportTicketStatus status, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportRestrictedEvidenceMessageClosed,
    _ => l10n.supportRestrictedEvidenceMessageInProgress,
  };
}

String _additionalProofGuidance(SupportTicketStatus status, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportAdditionalProofGuidanceClosed,
    _ => l10n.supportAdditionalProofGuidanceInProgress,
  };
}

String _attachmentVisibilityMessage(SupportTicketStatus status, bool isDisputeTicket, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportAttachmentVisibilityMessageClosed,
    _ => l10n.supportAttachmentVisibilityMessageInProgress,
  };
}

String _attachmentGuidanceMessage(SupportTicketStatus status, bool isDisputeTicket, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportAttachmentGuidanceMessageClosed,
    _ => l10n.supportAttachmentGuidanceMessageInProgress,
  };
}

String _messageSenderLabel(SupportTicketMessage message, AppLocalizations l10n) {
  return message.senderType == SupportMessageSenderType.support ? l10n.supportSupportTeamLabel : l10n.supportYouLabel;
}

String _emptyThreadSubtitle(SupportTicketStatus status, AppLocalizations l10n) {
  return switch (status) {
    SupportTicketStatus.open => l10n.supportEmptyThreadSubtitleOpen,
    SupportTicketStatus.inProgress => l10n.supportEmptyThreadSubtitleInProgress,
    SupportTicketStatus.waitingForUser => l10n.supportEmptyThreadSubtitleWaiting,
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportEmptyThreadSubtitleResolved,
    SupportTicketStatus.unknown => l10n.supportEmptyThreadSubtitleUnknown,
  };
}

String _replyGuidancePrimary(SupportTicket ticket, AppLocalizations l10n) {
  final isDisputeTicket = _isDisputeTicket(ticket);
  return switch (ticket.status) {
    SupportTicketStatus.open => isDisputeTicket
        ? l10n.supportReplyGuidancePrimaryOpenDispute
        : l10n.supportReplyGuidancePrimaryOpenDefault,
    SupportTicketStatus.inProgress => isDisputeTicket
        ? l10n.supportReplyGuidancePrimaryInProgressDispute
        : l10n.supportReplyGuidancePrimaryInProgressDefault,
    SupportTicketStatus.waitingForUser => isDisputeTicket
        ? l10n.supportReplyGuidancePrimaryWaitingDispute
        : l10n.supportReplyGuidancePrimaryWaitingDefault,
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportReplyGuidancePrimaryResolved,
    SupportTicketStatus.unknown => l10n.supportReplyGuidancePrimaryUnknown,
  };
}

String _replyGuidanceSecondary(SupportTicket ticket, AppLocalizations l10n) {
  final isDisputeTicket = _isDisputeTicket(ticket);
  return switch (ticket.status) {
    SupportTicketStatus.open || SupportTicketStatus.inProgress => isDisputeTicket
        ? l10n.supportReplyGuidanceSecondaryOpenInProgressDispute
        : l10n.supportReplyGuidanceSecondaryOpenInProgressDefault,
    SupportTicketStatus.waitingForUser => isDisputeTicket
        ? l10n.supportReplyGuidanceSecondaryWaitingDispute
        : l10n.supportReplyGuidanceSecondaryWaitingDefault,
    SupportTicketStatus.resolved || SupportTicketStatus.closed => l10n.supportReplyGuidanceSecondaryResolved,
    SupportTicketStatus.unknown => l10n.supportReplyGuidanceSecondaryUnknown,
  };
}

String _formatDateTime(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final localValue = value.toLocal();
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(localValue),
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
  return '${material.formatShortDate(localValue)} - $timeLabel';
}

String _supportTicketTitle(SupportTicket ticket, AppLocalizations l10n) {
  final baseTitle = _supportTicketTitleBase(ticket, l10n);
  if (ticket.priority == SupportTicketPriority.unknown) {
    return baseTitle;
  }
  return l10n.supportTicketTitleWithPriority(
    baseTitle,
    _ticketPriorityLabel(ticket.priority, l10n),
  );
}

String _supportTicketTitleBase(SupportTicket ticket, AppLocalizations l10n) {
  if (_isDisputeTicket(ticket)) {
    return l10n.supportTicketTitleTripDisputeReview;
  }

  return switch (ticket.category.trim().toLowerCase()) {
    'loaded_quantity_mismatch' => l10n.supportTicketTitleLoadedQuantityMismatchReport,
    'unloaded_quantity_mismatch' => l10n.supportTicketTitleUnloadedQuantityMismatchReport,
    'document_mismatch' => l10n.supportTicketTitleDocumentMismatchReport,
    'spam_or_scam' => l10n.supportTicketTitleSpamOrScamReport,
    'abusive_behavior' => l10n.supportTicketTitleAbusiveBehaviorReport,
    'fake_payout_proof' => l10n.supportTicketTitleFakePayoutProofReport,
    'non_payment' => l10n.supportTicketTitleNonPaymentReport,
    'delay_or_no_show' => l10n.supportTicketTitleDelayOrNoShowReport,
    'damage_or_shortage' => l10n.supportTicketTitleDamageOrShortageReport,
    'other' => l10n.supportTicketTitleOtherReport,
    _ => l10n.commonSupportLabel,
  };
}

String _disputeCategoryLabel(String value, AppLocalizations l10n) {
  return switch (value.trim().toLowerCase()) {
    'trip_dispute' => l10n.supportDisputeCategoryTripDispute,
    'loaded_quantity_mismatch' => l10n.supportDisputeCategoryLoadedQuantityMismatch,
    'unloaded_quantity_mismatch' => l10n.supportDisputeCategoryUnloadedQuantityMismatch,
    'document_mismatch' => l10n.supportDisputeCategoryDocumentMismatch,
    'non_payment' => l10n.supportDisputeCategoryNonPayment,
    'fake_payout_proof' => l10n.supportDisputeCategoryFakePayoutProof,
    'delay_or_no_show' => l10n.supportDisputeCategoryDelayOrNoShow,
    'damage_or_shortage' => l10n.supportDisputeCategoryDamageOrShortage,
    'abusive_behavior' => l10n.supportDisputeCategoryAbusiveBehavior,
    'spam_or_scam' => l10n.supportDisputeCategorySpamOrScam,
    'other' => l10n.supportDisputeCategoryOther,
    _ => l10n.commonSupportLabel,
  };
}

String _supportTrustStatusLoading(AppLocalizations l10n) => l10n.supportTrustStatusLoading;

String _supportUpdatedAt(String value, AppLocalizations l10n) => l10n.supportUpdatedAt(value);

String _supportTicketReference(AppLocalizations l10n) => l10n.supportTicketReference;

String _supportTripReference(AppLocalizations l10n) => l10n.supportTripReference;

String _supportOpenedAt(String value, AppLocalizations l10n) => l10n.supportOpenedAt(value);

String _supportDisputeCategoryLabel(String category, AppLocalizations l10n) => l10n.supportDisputeCategoryLabel(category);

String _supportTicketIdValue(AppLocalizations l10n) => l10n.supportTicketIdValue;

String _supportPriorityValue(String priority, AppLocalizations l10n) => l10n.supportPriorityValue(priority);

String _supportLastUpdatedValue(String value, AppLocalizations l10n) => l10n.supportLastUpdatedValue(value);

String _supportRelatedTripValue(AppLocalizations l10n) => l10n.supportRelatedTripValue;

String _supportRelatedLoadValue(AppLocalizations l10n) => l10n.supportRelatedLoadValue;

String _supportOpenRelatedTripAction(AppLocalizations l10n) => l10n.supportOpenRelatedTripAction;

String _supportOpenRelatedLoadAction(AppLocalizations l10n) => l10n.supportOpenRelatedLoadAction;

String _supportResolutionValue(String value, AppLocalizations l10n) => l10n.supportResolutionValue(value);

String _supportEvidenceVisibilityTitle(AppLocalizations l10n) => l10n.supportEvidenceVisibilityTitle;

String _supportVisibleThreadSummaryTitle(AppLocalizations l10n) => l10n.supportVisibleThreadSummaryTitle;

String _supportVisibleRepliesCount(int count, AppLocalizations l10n) => l10n.supportVisibleRepliesCount(count);

String _supportLastVisibleUpdateNone(AppLocalizations l10n) => l10n.supportLastVisibleUpdateNone;

String _supportLastVisibleUpdate(String value, AppLocalizations l10n) => l10n.supportLastVisibleUpdate(value);

String _supportLatestVisibleSenderNone(AppLocalizations l10n) => l10n.supportLatestVisibleSenderNone;

String _supportLatestVisibleSender(String value, AppLocalizations l10n) => l10n.supportLatestVisibleSender(value);

String _supportVisibleAttachmentSummaryPresent(AppLocalizations l10n) => l10n.supportVisibleAttachmentSummaryPresent;

String _supportVisibleAttachmentSummaryAbsent(AppLocalizations l10n) => l10n.supportVisibleAttachmentSummaryAbsent;

String _supportNoVisibleThreadTitle(AppLocalizations l10n) => l10n.supportNoVisibleThreadTitle;

String _supportCurrentWorkflowTitle(AppLocalizations l10n) => l10n.supportCurrentWorkflowTitle;

String _supportResolutionOutcomeTitle(AppLocalizations l10n) => l10n.supportResolutionOutcomeTitle;

String _supportResolvedOn(String value, AppLocalizations l10n) => l10n.supportResolvedOn(value);

String _supportWaitingForReplyTitle(AppLocalizations l10n) => l10n.supportWaitingForReplyTitle;

String _supportWaitingForReplyMessage(AppLocalizations l10n) => l10n.supportWaitingForReplyMessage;

String _supportReplyGuidanceTitle(AppLocalizations l10n) => l10n.supportReplyGuidanceTitle;

String _supportRepliesClosedTitle(AppLocalizations l10n) => l10n.supportRepliesClosedTitle;

String _supportRepliesClosedMessage(AppLocalizations l10n) => l10n.supportRepliesClosedMessage;

String _supportSupportTeamLabel(AppLocalizations l10n) => l10n.supportSupportTeamLabel;

String _supportYouLabel(AppLocalizations l10n) => l10n.supportYouLabel;

String _supportReplyStatusReply(AppLocalizations l10n) => l10n.supportReplyStatusReply;

String _supportReplyStatusSubmitted(AppLocalizations l10n) => l10n.supportReplyStatusSubmitted;

String _supportNoMessageTextProvided(AppLocalizations l10n) => l10n.supportNoMessageTextProvided;

const Set<String> _disputeCategories = <String>{
  'loaded_quantity_mismatch',
  'unloaded_quantity_mismatch',
  'document_mismatch',
  'non_payment',
  'fake_payout_proof',
  'delay_or_no_show',
  'damage_or_shortage',
  'abusive_behavior',
  'spam_or_scam',
  'other',
};

bool _isDisputeTicket(SupportTicket ticket) {
  return ticket.relatedTripId != null && (_disputeCategories.contains(ticket.category) || ticket.category == 'trip_dispute');
}
