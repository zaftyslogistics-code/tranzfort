import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '').toString();
    final isSupplier = role == 'supplier';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: isSupplier ? const _SupplierInbox() : const _TruckerInbox(),
    );
  }
}

class _SupplierInbox extends ConsumerWidget {
  const _SupplierInbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(chatInboxProvider);

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return const EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            subtitle: 'Start a chat by engaging with a load.',
          );
        }

        // Group conversations by load for the supplier
        final Map<String, List<Map<String, dynamic>>> grouped = {};
        for (final conv in conversations) {
          final loadId = (conv['load_id'] ?? '').toString();
          grouped.putIfAbsent(loadId, () => []).add(conv);
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(chatInboxProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.length,
            itemBuilder: (context, index) {
              final loadId = grouped.keys.elementAt(index);
              final loadConvs = grouped[loadId]!;
              final firstConv = loadConvs.first;
              final load = firstConv['load'] as Map<String, dynamic>? ?? {};
              
              final latestMessageAt = loadConvs
                  .map((c) => DateTime.tryParse((c['last_message_at'] ?? '').toString()))
                  .where((d) => d != null)
                  .cast<DateTime>()
                  .fold<DateTime?>(null, (prev, curr) => (prev == null || curr.isAfter(prev)) ? curr : prev);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Navigate to a sub-list of conversations for this load (or directly if only 1)
                    if (loadConvs.length == 1) {
                      context.push('/chat/${loadConvs.first['id']}');
                    } else {
                      // Note: We should actually show a sub-list here for multi-trucker, 
                      // but for Sprint 7 Phase 1 flat navigation is acceptable if we push directly to the first one 
                      // or build a quick sub-sheet. For simplicity, we just route to the first active one.
                      context.push('/chat/${loadConvs.first['id']}');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${load['material'] ?? '-'}: ${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${loadConvs.length} active conversation(s)',
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Failed to load messages')),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.jm().format(time);
    }
    return DateFormat.MMMd().format(time);
  }
}

class _TruckerInbox extends ConsumerWidget {
  const _TruckerInbox();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(chatInboxProvider);

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return const EmptyStateView(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            subtitle: 'Start a chat by booking a load.',
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(chatInboxProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final load = conv['load'] as Map<String, dynamic>? ?? {};
              final supplierName = conv['supplier']?['profiles']?['full_name'] ?? 'Supplier';
              
              final lastMsg = (conv['last_message_text'] ?? '').toString();
              final lastMsgAt = DateTime.tryParse((conv['last_message_at'] ?? '').toString());

              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.neutralLight),
                ),
                tileColor: AppColors.surface,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
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
                    const SizedBox(height: 2),
                    Text(
                      '${load['origin_city']} → ${load['dest_city']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMsg.isEmpty ? 'Tap to view conversation' : lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: lastMsgAt != null
                    ? Text(
                        _formatTime(lastMsgAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral,
                        ),
                      )
                    : null,
                onTap: () => context.push('/chat/${conv['id']}'),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Failed to load messages')),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.jm().format(time);
    }
    return DateFormat.MMMd().format(time);
  }
}
