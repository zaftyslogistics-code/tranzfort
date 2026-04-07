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
import '../../communication/data/chat_repository.dart';
import '../../communication/providers/chat_providers.dart';
import 'shell_components.dart';

class ShellMessagesScreen extends ConsumerStatefulWidget {
  const ShellMessagesScreen({super.key});

  @override
  ConsumerState<ShellMessagesScreen> createState() => _ShellMessagesScreenState();
}

class _ShellMessagesScreenState extends ConsumerState<ShellMessagesScreen> {
  final Set<String> _expandedLoadIds = <String>{};

  void _toggleLoadGroup(String loadId) {
    setState(() {
      if (_expandedLoadIds.contains(loadId)) {
        _expandedLoadIds.remove(loadId);
      } else {
        _expandedLoadIds.add(loadId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final authState = ref.watch(currentAuthStateProvider);
    final inboxState = ref.watch(inboxProvider);
    final isSupplier = authState.role == AppUserRole.supplier;

    return ShellScrollView(
      children: [
        HeroActionCard(
          title: l10n.shellMessagesTitle,
          subtitle: isSupplier
              ? l10n.shellMessagesSupplierSubtitle
              : l10n.shellMessagesTruckerSubtitle,
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              StatusBadge(
                label: isSupplier ? l10n.shellMessagesSupplierGroupedInbox : l10n.shellMessagesTruckerFlatInbox,
                icon: Icons.chat_bubble_outline,
              ),
              StatusBadge(
                label: l10n.shellMessagesUnreadThreads(
                  inboxState.conversations.where((conversation) => conversation.hasUnread).length,
                ),
                icon: Icons.mark_chat_unread_outlined,
                palette: const StatusPalette(
                  foreground: AppColors.info,
                  background: AppColors.infoBg,
                ),
              ),
            ],
          ),
        ),
        if (inboxState.isLoading)
          const LoadingShimmer(height: 96, itemCount: 3)
        else if (inboxState.failure != null)
          WarningBlock(
            title: l10n.shellMessagesLoadFailureTitle,
            message: l10n.shellMessagesLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetry,
              onPressed: () => ref.read(inboxProvider.notifier).load(),
            ),
          )
        else if (inboxState.conversations.isEmpty)
          EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: l10n.shellMessagesEmptyTitle,
            subtitle: isSupplier
                ? l10n.shellMessagesSupplierEmptySubtitle
                : l10n.shellMessagesTruckerEmptySubtitle,
            actionLabel: isSupplier ? l10n.supplierTripsEmptyActiveAction : l10n.truckerTripsEmptyActiveAction,
            onAction: () => context.go(isSupplier ? AppRoutes.myLoadsPath : AppRoutes.findLoadsPath),
          )
        else if (isSupplier)
          _SupplierMessagesInbox(
            groups: _groupSupplierConversations(inboxState.conversations),
            expandedLoadIds: _expandedLoadIds,
            onToggleLoadGroup: _toggleLoadGroup,
          )
        else
          _TruckerMessagesInbox(conversations: inboxState.conversations),
      ],
    );
  }
}

class _SupplierMessagesInbox extends StatelessWidget {
  final List<_SupplierConversationGroup> groups;
  final Set<String> expandedLoadIds;
  final ValueChanged<String> onToggleLoadGroup;

  const _SupplierMessagesInbox({
    required this.groups,
    required this.expandedLoadIds,
    required this.onToggleLoadGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          _SupplierConversationGroupCard(
            group: groups[index],
            isExpanded: expandedLoadIds.contains(groups[index].loadId),
            onToggle: () => onToggleLoadGroup(groups[index].loadId),
          ),
          if (index != groups.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SupplierConversationGroupCard extends StatelessWidget {
  final _SupplierConversationGroup group;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SupplierConversationGroupCard({
    required this.group,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final unreadCount = group.conversations.where((conversation) => conversation.hasUnread).length;
    final latestConversation = group.conversations.first;

    return StandardListCard(
      accent: unreadCount > 0 ? AppColors.info : AppColors.neutral,
      title: group.routeLabel,
      subtitle: l10n.shellMessagesActiveConversations(
        group.conversations.length,
        _localizedMessagePreview(l10n, latestConversation),
      ),
      trailing: StatusChip(
        label: unreadCount > 0 ? l10n.shellMessagesUnreadStatus : l10n.shellMessagesReadStatus,
        showDot: unreadCount > 0,
      ),
      onTap: onToggle,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isExpanded
                      ? l10n.shellMessagesHideTruckerConversations
                      : l10n.shellMessagesLatestBy(
                          latestConversation.truckerName,
                          _formatInboxTimestamp(context, latestConversation.lastMessageAt ?? latestConversation.createdAt),
                        ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < group.conversations.length; index++) ...[
              _SupplierConversationRow(conversation: group.conversations[index]),
              if (index != group.conversations.length - 1) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _SupplierConversationRow extends StatelessWidget {
  final ConversationPreview conversation;

  const _SupplierConversationRow({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.go('${AppRoutes.chatPath}/${conversation.id}'),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      conversation.truckerName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (conversation.hasUnread)
                    StatusChip(
                      label: l10n.shellMessagesUnreadStatus,
                      palette: const StatusPalette(
                        foreground: AppColors.info,
                        background: AppColors.infoBg,
                      ),
                    )
                  else
                    StatusChip(label: l10n.shellMessagesReadStatus, showDot: false),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(_localizedMessagePreview(AppLocalizations.of(context), conversation)),
              if ((conversation.truckDisplayLabel ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  conversation.truckDisplayLabel!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if ((conversation.bookingStatusLabel ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                StatusChip(label: _localizedShellBookingStatus(l10n, conversation.bookingStatusLabel!)),
              ],
              const SizedBox(height: AppSpacing.xs),
              Text(
                _formatInboxTimestamp(context, conversation.lastMessageAt ?? conversation.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TruckerMessagesInbox extends StatelessWidget {
  final List<ConversationPreview> conversations;

  const _TruckerMessagesInbox({required this.conversations});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < conversations.length; index++) ...[
          _TruckerConversationCard(conversation: conversations[index]),
          if (index != conversations.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _TruckerConversationCard extends StatelessWidget {
  final ConversationPreview conversation;

  const _TruckerConversationCard({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final supplierLabel = (conversation.supplierCompanyName ?? '').trim().isNotEmpty
        ? '${conversation.supplierName} - ${conversation.supplierCompanyName}'
        : conversation.supplierName;

    return StandardListCard(
      accent: conversation.hasUnread ? AppColors.info : AppColors.neutral,
      title: supplierLabel,
      subtitle: '${conversation.routeLabel} - ${_localizedMessagePreview(l10n, conversation)}',
      trailing: StatusChip(
        label: conversation.hasUnread ? l10n.shellMessagesUnreadStatus : l10n.shellMessagesReadStatus,
        showDot: conversation.hasUnread,
      ),
      onTap: () => context.go('${AppRoutes.chatPath}/${conversation.id}'),
      footer: Text(
        _formatInboxTimestamp(context, conversation.lastMessageAt ?? conversation.createdAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _SupplierConversationGroup {
  final String loadId;
  final String routeLabel;
  final List<ConversationPreview> conversations;

  const _SupplierConversationGroup({
    required this.loadId,
    required this.routeLabel,
    required this.conversations,
  });
}

List<_SupplierConversationGroup> _groupSupplierConversations(List<ConversationPreview> conversations) {
  final grouped = <String, List<ConversationPreview>>{};
  for (final conversation in conversations) {
    grouped.putIfAbsent(conversation.loadId, () => <ConversationPreview>[]).add(conversation);
  }

  final groups = grouped.entries.map((entry) {
    final sortedConversations = List<ConversationPreview>.from(entry.value)
      ..sort((a, b) {
        final aTime = a.lastMessageAt ?? a.createdAt;
        final bTime = b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    return _SupplierConversationGroup(
      loadId: entry.key,
      routeLabel: sortedConversations.first.routeLabel,
      conversations: sortedConversations,
    );
  }).toList(growable: false)
    ..sort((a, b) {
      final aTime = a.conversations.first.lastMessageAt ?? a.conversations.first.createdAt;
      final bTime = b.conversations.first.lastMessageAt ?? b.conversations.first.createdAt;
      return bTime.compareTo(aTime);
    });

  return groups;
}

String _localizedShellBookingStatus(AppLocalizations l10n, String value) {
  switch (value.trim().toLowerCase()) {
    case 'submitted':
      return l10n.shellMessagesBookingStatusSubmitted;
    case 'approved':
      return l10n.shellMessagesBookingStatusApproved;
    case 'rejected':
      return l10n.shellMessagesBookingStatusRejected;
    case 'pending':
      return l10n.shellMessagesBookingStatusPending;
    default:
      return l10n.shellMessagesBookingStatusUnknown;
  }
}

String _localizedMessagePreview(AppLocalizations l10n, ConversationPreview conversation) {
  final type = conversation.latestMessageTypeHint;
  final text = conversation.latestMessagePreview;
  if (type == null || type == ChatMessageType.text) {
    return text;
  }
  return switch (type) {
    ChatMessageType.voice => l10n.chatPreviewVoice,
    ChatMessageType.location => l10n.chatPreviewLocation,
    ChatMessageType.document => l10n.chatPreviewDocument,
    ChatMessageType.mapCard => l10n.chatPreviewMapCard,
    ChatMessageType.truckCard => l10n.chatPreviewTruckCard,
    ChatMessageType.system => l10n.chatPreviewSystem,
    ChatMessageType.text => text,
  };
}

String _formatInboxTimestamp(BuildContext context, DateTime value) {
  final material = MaterialLocalizations.of(context);
  final dateLabel = material.formatShortDate(value);
  final timeLabel = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(value),
    alwaysUse24HourFormat: true,
  );
  return '$dateLabel - $timeLabel';
}
