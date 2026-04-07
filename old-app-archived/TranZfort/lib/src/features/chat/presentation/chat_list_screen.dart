import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/fade_content_switcher.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();
    final isSupplier = role == 'supplier';
    final inboxCount = ref.watch(chatInboxProvider).valueOrNull?.length ?? 0;
    final unreadCounts = ref.watch(unreadCountsProvider).valueOrNull ??
        const <String, int>{};

    return Scaffold(
      drawer: AppDrawer(role: isSupplier ? 'supplier' : 'trucker'),
      appBar: AppBar(
        title: Text(l10n.messagesTitle),
        actions: [AppBarUtilityActions(ttsPreviewText: l10n.chatInboxTts)],
      ),
      body: Column(
        children: [
          TtsAnnounce(text: l10n.chatInboxScreenTtsContextCount(inboxCount)),
          Expanded(
            child: isSupplier
                ? _SupplierInbox(unreadCounts: unreadCounts)
                : _TruckerInbox(unreadCounts: unreadCounts),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentRole: isSupplier ? 'supplier' : 'trucker',
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xxs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SupplierLoadConversationsScreen extends StatelessWidget {
  final Map<String, dynamic> load;
  final List<Map<String, dynamic>> conversations;
  final Map<String, int> unreadCounts;

  const _SupplierLoadConversationsScreen({
    required this.load,
    required this.conversations,
    required this.unreadCounts,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
        ),
      ),
      body: ListView.separated(
        addAutomaticKeepAlives: false,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
          AppSpacing.screenPaddingH,
          AppSpacing.safeBottomPadding(context),
        ),
        itemCount: conversations.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.cardGap),
        itemBuilder: (context, index) {
          final conv = conversations[index];
          final truckerName =
              conv['trucker']?['profiles']?['full_name']?.toString() ??
              l10n.chatTruckerFallbackName;
          final lastMsg = (conv['last_message_text'] ?? '').toString();
          final lastMsgAt = DateTime.tryParse(
            (conv['last_message_at'] ?? '').toString(),
          );

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: const BorderSide(color: AppColors.neutralLight),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.cardPadding,
                vertical: AppSpacing.xs,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.brandTealLight.withValues(
                  alpha: 0.25,
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                truckerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                lastMsg.isEmpty ? l10n.chatTapToOpenConversation : lastMsg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMsgAt != null)
                    Text(
                      IstTime.formatTime(lastMsgAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral,
                          ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  if ((unreadCounts[(conv['id'] ?? '').toString()] ?? 0) > 0)
                    _UnreadBadge(
                      count: unreadCounts[(conv['id'] ?? '').toString()] ?? 0,
                    )
                  else
                    const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                ],
              ),
              onTap: () => context.push('/chat/${conv['id']}'),
            ),
          );
        },
      ),
    );
  }
}

class _SupplierInbox extends ConsumerWidget {
  final Map<String, int> unreadCounts;

  const _SupplierInbox({required this.unreadCounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(chatInboxProvider);

    final content = conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: l10n.chatNoMessagesTitle,
            subtitle: l10n.chatSupplierInboxSubtitle,
          );
        }

        // Group conversations by load for the supplier
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final conv in conversations) {
          final loadId = (conv['load_id'] ?? '').toString();
          grouped.putIfAbsent(loadId, () => []).add(conv);
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(chatInboxProvider.future),
          child: ListView.builder(
            addAutomaticKeepAlives: false,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.screenPaddingV,
              AppSpacing.screenPaddingH,
              AppSpacing.safeBottomPadding(context),
            ),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final loadId = grouped.keys.elementAt(index);
              final loadConvs = grouped[loadId]!;
              final firstConv = loadConvs.first;
              final load = firstConv['load'] as Map<String, dynamic>? ?? {};

              final latestMessageAt = loadConvs
                  .map(
                    (c) => DateTime.tryParse(
                      (c['last_message_at'] ?? '').toString(),
                    ),
                  )
                  .where((d) => d != null)
                  .cast<DateTime>()
                  .fold<DateTime?>(
                    null,
                    (prev, curr) =>
                        (prev == null || curr.isAfter(prev)) ? curr : prev,
                  );

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSpacing.cardGap),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: const BorderSide(color: AppColors.neutralLight),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: () {
                    if (loadConvs.length == 1) {
                      context.push('/chat/${loadConvs.first['id']}');
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _SupplierLoadConversationsScreen(
                            load: load,
                            conversations: loadConvs,
                            unreadCounts: unreadCounts,
                          ),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMuted,
                            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          ),
                          child: Text(
                            '${load['material'] ?? '-'}: ${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${loadConvs.length} ${l10n.chatConversationsSuffix}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            if (latestMessageAt != null)
                              Text(
                                _formatTime(latestMessageAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.neutral,
                                    ),
                              ),
                            const SizedBox(width: AppSpacing.xs),
                            if (_totalUnreadForLoad(loadConvs) > 0)
                              _UnreadBadge(count: _totalUnreadForLoad(loadConvs))
                            else
                              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => SkeletonLoader.list(
        count: 4,
        itemHeight: 96,
      ),
      error: (e, _) => Center(child: Text(l10n.chatFailedLoadMessages)),
    );

    return FadeContentSwitcher(
      child: KeyedSubtree(
        key: ValueKey('supplier-inbox-${conversationsAsync.isLoading}-${conversationsAsync.hasError}'),
        child: content,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = IstTime.age(time);
    if (diff.inDays == 0) {
      return IstTime.formatTime(time);
    }
    return IstTime.formatMonthDay(time);
  }

  int _totalUnreadForLoad(List<Map<String, dynamic>> conversations) {
    var total = 0;
    for (final conv in conversations) {
      total += unreadCounts[(conv['id'] ?? '').toString()] ?? 0;
    }
    return total;
  }
}

class _TruckerInbox extends ConsumerWidget {
  final Map<String, int> unreadCounts;

  const _TruckerInbox({required this.unreadCounts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(chatInboxProvider);

    final content = conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: l10n.chatNoMessagesTitle,
            subtitle: l10n.chatTruckerInboxSubtitle,
            cta: SizedBox(
              width: 220,
              child: FilledButton(
                onPressed: () => context.push('/find-loads'),
                child: Text(l10n.findLoadsAction),
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.refresh(chatInboxProvider.future),
          child: ListView.separated(
            addAutomaticKeepAlives: false,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.screenPaddingV,
              AppSpacing.screenPaddingH,
              AppSpacing.safeBottomPadding(context),
            ),
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.cardGap),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final load = conv['load'] as Map<String, dynamic>? ?? {};
              final supplierName =
                  conv['supplier']?['profiles']?['full_name'] ??
                  l10n.chatSupplierFallbackName;

              final lastMsg = (conv['last_message_text'] ?? '').toString();
              final lastMsgAt = DateTime.tryParse(
                (conv['last_message_at'] ?? '').toString(),
              );

              return Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: const BorderSide(color: AppColors.neutralLight),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  tileColor: AppColors.surface,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandTealLight.withValues(
                      alpha: 0.2,
                    ),
                    child: const Icon(Icons.business, color: AppColors.primary),
                  ),
                  title: Text(
                    supplierName.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        '${load['origin_city']} → ${load['dest_city']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lastMsg.isEmpty ? l10n.chatTapToViewConversation : lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (lastMsgAt != null)
                        Text(
                          _formatTime(lastMsgAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((unreadCounts[(conv['id'] ?? '').toString()] ?? 0) > 0)
                            _UnreadBadge(
                              count: unreadCounts[(conv['id'] ?? '').toString()] ?? 0,
                            ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => context.push('/chat/${conv['id']}'),
                ),
              );
            },
          ),
        );
      },
      loading: () => SkeletonLoader.list(
        count: 4,
        itemHeight: 96,
      ),
      error: (e, _) => Center(child: Text(l10n.chatFailedLoadMessages)),
    );

    return FadeContentSwitcher(
      child: KeyedSubtree(
        key: ValueKey(
          'trucker-inbox-${conversationsAsync.isLoading}-${conversationsAsync.hasError}',
        ),
        child: content,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = IstTime.age(time);
    if (diff.inDays == 0) {
      return IstTime.formatTime(time);
    }
    return IstTime.formatMonthDay(time);
  }
}
