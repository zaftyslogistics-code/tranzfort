part of 'support_screen.dart';

class _SupportTicketListSection extends StatelessWidget {
  final SupportTicketsState state;
  final String? selectedTicketId;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final VoidCallback onCreateTicket;
  final ValueChanged<String> onSelect;

  const _SupportTicketListSection({
    required this.state,
    required this.selectedTicketId,
    required this.onRetry,
    required this.onLoadMore,
    required this.onCreateTicket,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (state.isLoading) {
      return const LoadingShimmer(height: 92, itemCount: 2);
    }
    if (state.failure != null) {
      return WarningBlock(
        title: l10n.supportTicketsUnavailableTitle,
        message: _loadFailureMessage(context),
        action: OutlineButton(
          label: l10n.commonRetry,
          onPressed: onRetry,
        ),
      );
    }
    if (state.tickets.isEmpty) {
      return EmptyStateView(
        icon: Icons.support_agent_outlined,
        title: l10n.supportNoTicketsTitle,
        subtitle: l10n.supportNoTicketsSubtitle,
        actionLabel: l10n.supportCreateTicketAction,
        onAction: onCreateTicket,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < state.tickets.length; index++) ...[
          _SupportTicketListCard(
            ticket: state.tickets[index],
            isSelected: state.tickets[index].id == selectedTicketId,
            onTap: () => onSelect(state.tickets[index].id),
          ),
          if (index != state.tickets.length - 1) const SizedBox(height: AppSpacing.md),
        ],
        if (state.hasMore) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlineButton(
              label: state.isLoadingMore ? l10n.supportLoadingOlderTickets : l10n.supportLoadOlderTickets,
              onPressed: state.isLoadingMore ? null : onLoadMore,
            ),
          ),
        ],
      ],
    );
  }

  String _loadFailureMessage(BuildContext context) {
    return AppLocalizations.of(context).supportTicketsLoadFailureMessage;
  }
}

class _SupportTicketListCard extends StatelessWidget {
  final SupportTicket ticket;
  final bool isSelected;
  final VoidCallback onTap;

  const _SupportTicketListCard({
    required this.ticket,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StandardListCard(
      accent: isSelected ? AppColors.primary : _ticketStatusPalette(ticket.status).foreground,
      title: _supportTicketTitle(ticket, l10n),
      subtitle: _supportUpdatedAt(_formatDateTime(context, ticket.updatedAt), l10n),
      trailing: StatusChip(label: _ticketStatusLabel(ticket.status, l10n)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isDisputeTicket(ticket)) ...[
            Text(
              _supportDisputeCategoryLabel(_disputeCategoryLabel(ticket.category, l10n), l10n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            ticket.relatedTripId == null
                ? _supportTicketReference(l10n)
                : _supportTripReference(l10n),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (ticket.relatedTripId != null || ticket.relatedLoadId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (ticket.relatedTripId != null)
                  TextActionButton(
                    key: ValueKey('support-list-open-trip-${ticket.id}'),
                    label: l10n.supportOpenTripAction,
                    onPressed: () => context.push('${AppRoutes.tripDetailPath}/${ticket.relatedTripId}'),
                  ),
                if (ticket.relatedLoadId != null)
                  TextActionButton(
                    key: ValueKey('support-list-open-load-${ticket.id}'),
                    label: l10n.supportOpenLoadAction,
                    onPressed: () => context.push('${AppRoutes.loadDetailPath}/${ticket.relatedLoadId}'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          TextActionButton(
            label: isSelected ? l10n.supportViewingThisTicket : l10n.supportOpenTicketAction,
            onPressed: isSelected ? null : onTap,
          ),
        ],
      ),
    );
  }
}
