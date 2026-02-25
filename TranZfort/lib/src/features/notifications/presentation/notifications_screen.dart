import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(notificationActionProvider.notifier).markAllRead();
            },
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateView(
              icon: Icons.notifications_none,
              title: 'All caught up!',
              subtitle: 'You have no new notifications.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final isRead = notif['is_read'] == true;
                final createdAt = DateTime.tryParse((notif['created_at'] ?? '').toString());
                
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isRead ? AppColors.neutralLight : AppColors.primaryLight.withValues(alpha: 0.5),
                    ),
                  ),
                  tileColor: isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                  leading: CircleAvatar(
                    backgroundColor: isRead ? AppColors.neutralLight : AppColors.primaryLight.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.notifications,
                      color: isRead ? AppColors.neutral : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    (notif['title'] ?? '').toString(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        (notif['body'] ?? '').toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isRead ? AppColors.neutral : AppColors.onSurface,
                        ),
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _timeAgo(createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    if (!isRead) {
                      ref.read(notificationActionProvider.notifier).markRead(notif['id'].toString());
                    }
                    
                    // Route handling logic based on notification data
                    final data = notif['data'] as Map<String, dynamic>? ?? {};
                    if (data.containsKey('load_id')) {
                      context.push('/load-detail/${data['load_id']}');
                    } else if (data.containsKey('trip_id')) {
                      context.push('/trip-detail/${data['trip_id']}');
                    } else if (data.containsKey('conversation_id')) {
                      context.push('/chat/${data['conversation_id']}');
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load notifications')),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
