import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/user_support_repository.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ist_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/fade_content_switcher.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/solid_header.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/user_support_providers.dart';

class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'technical_bug';

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket(AppLocalizations l10n) async {
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();

    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportSubjectRequired)),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportDescriptionRequired)),
      );
      return;
    }

    final ticketId = await ref.read(userSupportActionProvider.notifier).createTicket(
          subject: subject,
          description: description,
          category: _selectedCategory,
        );

    if (!mounted) {
      return;
    }

    if (ticketId == null || ticketId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.supportCreateFailed)),
      );
      return;
    }

    _subjectController.clear();
    _descriptionController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.supportTicketSubmitted)),
    );
    await ref.read(ttsServiceProvider).speak(l10n.supportTicketSubmitted);
    if (!mounted) {
      return;
    }
    context.push('/support/$ticketId');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ticketsAsync = ref.watch(mySupportTicketsProvider);
    final actionState = ref.watch(userSupportActionProvider);
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();
    final ticketCount = ticketsAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: AppDrawer(role: role == 'supplier' ? 'supplier' : 'trucker'),
      appBar: AppBar(
        title: Text(l10n.settingsHelpSupportTitle),
        actions: [
          AppBarUtilityActions(ttsPreviewText: l10n.supportScreenTtsContext),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mySupportTicketsProvider);
          await ref.read(mySupportTicketsProvider.future);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPaddingH,
            AppSpacing.screenPaddingV,
            AppSpacing.screenPaddingH,
            AppSpacing.safeBottomPadding(context),
          ),
          children: [
            TtsAnnounce(text: l10n.supportScreenTtsContext),
            SolidHeader(
              title: l10n.supportHeroTitle,
              subtitle: l10n.supportHeroSubtitle,
              icon: Icons.support_agent_outlined,
            ),
            const SizedBox(height: AppSpacing.lg),
            _SupportCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.supportCreateTicketTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.supportCategoryLabel,
                    ),
                    items: [
                      _categoryItem(context, 'technical_bug'),
                      _categoryItem(context, 'booking_issue'),
                      _categoryItem(context, 'trip_issue'),
                      _categoryItem(context, 'payment_payout'),
                      _categoryItem(context, 'verification'),
                      _categoryItem(context, 'account_access'),
                      _categoryItem(context, 'other'),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _subjectController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.supportSubjectLabel,
                      hintText: l10n.supportSubjectHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    minLines: 4,
                    decoration: InputDecoration(
                      labelText: l10n.supportDescriptionLabel,
                      hintText: l10n.supportDescriptionHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: l10n.supportSubmitTicketAction,
                    isLoading: actionState.isLoading,
                    onPressed: actionState.isLoading
                        ? null
                        : () => _submitTicket(l10n),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(
              title: l10n.supportMyTicketsTitle,
              trailing: _CountPill(count: ticketCount),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeContentSwitcher(
              child: ticketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return EmptyStateView(
                      key: const ValueKey('support-empty'),
                      icon: Icons.mark_email_unread_outlined,
                      title: l10n.supportEmptyTitle,
                      subtitle: l10n.supportEmptySubtitle,
                    );
                  }

                  return Column(
                    key: const ValueKey('support-list'),
                    children: tickets
                        .map(
                          (ticket) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.cardGap,
                            ),
                            child: _TicketCard(ticket: ticket),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    uiSafeErrorText(
                      context,
                      error,
                      fallback: l10n.supportLoadError,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentRole: role == 'supplier' ? 'supplier' : 'trucker',
      ),
    );
  }

  DropdownMenuItem<String> _categoryItem(BuildContext context, String value) {
    return DropdownMenuItem(
      value: value,
      child: Text(_categoryLabel(AppLocalizations.of(context), value)),
    );
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
}

class _TicketCard extends StatelessWidget {
  final UserSupportTicketListItem ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: () => context.push('/support/${ticket.id}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.neutralLight),
        ),
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
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _categoryLabel(l10n, ticket.category),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _MetaPill(
                  label: _statusLabel(l10n, ticket.status),
                  textColor: _statusColor(ticket.status),
                  backgroundColor: _statusColor(ticket.status).withValues(alpha: 0.12),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(
                  label: _priorityLabel(l10n, ticket.priority),
                  textColor: _priorityColor(ticket.priority),
                  backgroundColor: _priorityColor(ticket.priority).withValues(alpha: 0.12),
                ),
                if (ticket.createdAt != null)
                  _MetaPill(
                    label:
                        '${l10n.supportCreatedLabel}: ${IstTime.formatDayMonth(ticket.createdAt!)}',
                    textColor: AppColors.textSecondary,
                    backgroundColor: AppColors.primaryMuted,
                  ),
                if (ticket.resolvedAt != null)
                  _MetaPill(
                    label:
                        '${l10n.supportResolvedLabel}: ${IstTime.formatDayMonth(ticket.resolvedAt!)}',
                    textColor: AppColors.success,
                    backgroundColor: AppColors.successTint,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${l10n.supportTicketIdLabel}: ${ticket.id.substring(0, 8)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ],
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

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
