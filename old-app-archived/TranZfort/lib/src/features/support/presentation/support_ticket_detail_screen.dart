import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/user_support_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ist_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/user_support_providers.dart';

class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply(AppLocalizations l10n) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportReplyRequired)),
      );
      return;
    }

    final success = await ref.read(userSupportActionProvider.notifier).sendReply(
          ticketId: widget.ticketId,
          text: text,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportReplyFailed)),
      );
      return;
    }

    _replyController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.supportReplySent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(supportTicketDetailProvider(widget.ticketId));
    final actionState = ref.watch(userSupportActionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supportTicketDetailTitle),
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return EmptyStateView(
              icon: Icons.support_outlined,
              title: l10n.supportTicketNotFoundTitle,
              subtitle: l10n.supportTicketNotFoundSubtitle,
            );
          }

          final ticket = detail.ticket;
          final canReply = ticket.status != UserSupportTicketStatus.resolved;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPaddingV),
            children: [
              _SupportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${l10n.supportTicketIdLabel}: ${ticket.id}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _MetaPill(
                          label: _statusLabel(l10n, ticket.status),
                          textColor: _statusColor(ticket.status),
                          backgroundColor:
                              _statusColor(ticket.status).withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaPill(
                          label: _categoryLabel(l10n, ticket.category),
                          textColor: AppColors.primary,
                          backgroundColor: AppColors.primaryMuted,
                        ),
                        _MetaPill(
                          label: _priorityLabel(l10n, ticket.priority),
                          textColor: _priorityColor(ticket.priority),
                          backgroundColor: _priorityColor(ticket.priority)
                              .withValues(alpha: 0.12),
                        ),
                        if (ticket.createdAt != null)
                          _MetaPill(
                            label:
                                '${l10n.supportCreatedLabel}: ${IstTime.formatDayMonth(ticket.createdAt!)}',
                            textColor: AppColors.textSecondary,
                            backgroundColor: AppColors.neutralLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.supportDescriptionLabel,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      detail.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (ticket.resolutionNotes.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.supportResolutionNotesTitle,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ticket.resolutionNotes,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader(title: l10n.supportConversationTitle),
              const SizedBox(height: AppSpacing.sm),
              if (detail.messages.isEmpty)
                _SupportCard(
                  child: Text(
                    l10n.supportNoMessagesYet,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                )
              else
                ...detail.messages.map(
                  (message) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MessageBubble(message: message),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              _SupportCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      canReply
                          ? l10n.supportReplySectionTitle
                          : l10n.supportTicketResolvedReplyClosed,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _replyController,
                      minLines: 3,
                      maxLines: 5,
                      enabled: canReply && !actionState.isLoading,
                      decoration: InputDecoration(
                        hintText: l10n.supportReplyHint,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (canReply)
                      PrimaryButton(
                        label: l10n.supportSendReplyAction,
                        isLoading: actionState.isLoading,
                        onPressed: actionState.isLoading
                            ? null
                            : () => _sendReply(l10n),
                      )
                    else
                      OutlineButton(
                        label: l10n.supportResolvedTicketReadOnlyAction,
                        onPressed: null,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              uiSafeErrorText(
                context,
                error,
                fallback: l10n.supportLoadError,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, UserSupportTicketStatus status) {
    switch (status) {
      case UserSupportTicketStatus.inProgress:
        return l10n.supportStatusInProgress;
      case UserSupportTicketStatus.resolved:
        return l10n.supportStatusResolved;
      case UserSupportTicketStatus.open:
        return l10n.supportStatusOpen;
    }
  }

  String _categoryLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'booking_issue':
        return l10n.supportCategoryBookingIssue;
      case 'trip_issue':
        return l10n.supportCategoryTripIssue;
      case 'payment_payout':
        return l10n.supportCategoryPaymentPayout;
      case 'verification':
        return l10n.supportCategoryVerification;
      case 'account_access':
        return l10n.supportCategoryAccountAccess;
      case 'other':
        return l10n.supportCategoryOther;
      case 'technical_bug':
      default:
        return l10n.supportCategoryTechnicalBug;
    }
  }

  Color _statusColor(UserSupportTicketStatus status) {
    switch (status) {
      case UserSupportTicketStatus.inProgress:
        return AppColors.brandOrange;
      case UserSupportTicketStatus.resolved:
        return AppColors.success;
      case UserSupportTicketStatus.open:
        return AppColors.primary;
    }
  }

  String _priorityLabel(AppLocalizations l10n, UserSupportTicketPriority priority) {
    switch (priority) {
      case UserSupportTicketPriority.low:
        return l10n.supportPriorityLow;
      case UserSupportTicketPriority.high:
        return l10n.supportPriorityHigh;
      case UserSupportTicketPriority.urgent:
        return l10n.supportPriorityUrgent;
      case UserSupportTicketPriority.medium:
        return l10n.supportPriorityMedium;
    }
  }

  Color _priorityColor(UserSupportTicketPriority priority) {
    switch (priority) {
      case UserSupportTicketPriority.low:
        return AppColors.textSecondary;
      case UserSupportTicketPriority.high:
        return AppColors.brandOrange;
      case UserSupportTicketPriority.urgent:
        return AppColors.error;
      case UserSupportTicketPriority.medium:
        return AppColors.primary;
    }
  }
}

class _SupportCard extends StatelessWidget {
  final Widget child;

  const _SupportCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: child,
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _MetaPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final UserSupportTicketMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderRole == 'user';
    final bgColor = isUser ? AppColors.primaryMuted : AppColors.surface;
    final borderColor = isUser ? AppColors.primary : AppColors.neutralLight;
    final title = isUser
        ? AppLocalizations.of(context).supportYouLabel
        : AppLocalizations.of(context).supportSupportTeamLabel;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isUser ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(message.content),
              if (message.createdAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${IstTime.formatDayMonth(message.createdAt!)} · ${IstTime.formatTime(message.createdAt!)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
