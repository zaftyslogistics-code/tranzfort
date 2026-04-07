import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ist_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/fade_content_switcher.dart';
import '../../../shared/widgets/solid_header.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final total = ref.read(notificationsProvider).valueOrNull?.length ?? 0;
    final nearEnd = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180;
    if (nearEnd && _visibleCount < total) {
      setState(() {
        _visibleCount = (_visibleCount + _pageSize).clamp(0, total);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: AppDrawer(role: role == 'supplier' ? 'supplier' : 'trucker'),
      appBar: AppBar(
        title: Text(l10n.appBarNotificationsTooltip),
        actions: [
          IconButton(
            onPressed: () {
              ref.read(notificationActionProvider.notifier).markAllRead();
            },
            icon: const Icon(Icons.done_all),
            tooltip: l10n.notificationsMarkAllAsRead,
          ),
          AppBarUtilityActions(ttsPreviewText: l10n.notificationsScreenTts),
        ],
      ),
      body: FadeContentSwitcher(
        child: KeyedSubtree(
          key: ValueKey(
            'notifications-${notificationsAsync.isLoading}-${notificationsAsync.hasError}',
          ),
          child: notificationsAsync.when(
            data: (notifications) {
          final visibleCount = _visibleCount > notifications.length
              ? notifications.length
              : _visibleCount;
          final visibleNotifications = notifications.take(visibleCount).toList();
          final hasMore = visibleCount < notifications.length;
          final unreadCount = notifications
              .where((n) => n['is_read'] != true)
              .length;

          if (notifications.isEmpty) {
            return Column(
              children: [
                TtsAnnounce(
                  text: l10n.notificationsScreenTtsCount(unreadCount),
                ),
                Expanded(
                  child: EmptyStateView(
                    icon: Icons.notifications_none,
                    title: l10n.notificationsAllCaughtUpTitle,
                    subtitle: l10n.notificationsAllCaughtUpSubtitle,
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              setState(() {
                _visibleCount = _pageSize;
              });
              final refreshed = ref.refresh(notificationsProvider.future);
              await refreshed;
            },
            child: ListView.separated(
              addAutomaticKeepAlives: false,
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingH,
                AppSpacing.screenPaddingV,
                AppSpacing.screenPaddingH,
                AppSpacing.safeBottomPadding(context),
              ),
              itemCount: visibleNotifications.length + 1 + (hasMore ? 1 : 0),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Column(
                    children: [
                      TtsAnnounce(
                        text: l10n.notificationsScreenTtsCount(unreadCount),
                      ),
                      SolidHeader(
                        title: l10n.appBarNotificationsTooltip,
                        subtitle: unreadCount > 0
                            ? l10n.notificationsUnreadUpdates(unreadCount)
                            : l10n.notificationsCaughtUpBanner,
                        icon: Icons.notifications_active_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.notificationsRealtimeHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  );
                }

                if (hasMore && index == visibleNotifications.length + 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notif = visibleNotifications[index - 1];
                final isRead = notif['is_read'] == true;
                final data = notif['data'] as Map<String, dynamic>? ?? {};
                final categoryLabel = _categoryLabel(l10n, data);
                final categoryColor = _categoryColor(data);
                final createdAt = DateTime.tryParse(
                  (notif['created_at'] ?? '').toString(),
                );

                return Container(
                  decoration: BoxDecoration(
                    color: isRead
                        ? AppColors.surface
                        : AppColors.brandTealLight.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: isRead
                          ? AppColors.neutralLight
                          : AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    onTap: () {
                      if (!isRead) {
                        ref
                            .read(notificationActionProvider.notifier)
                            .markRead(notif['id'].toString());
                      }

                      if (data.containsKey('load_id')) {
                        context.push('/load-detail/${data['load_id']}');
                      } else if (data.containsKey('trip_id')) {
                        context.push('/trip-detail/${data['trip_id']}');
                      } else if (data.containsKey('conversation_id')) {
                        context.push('/chat/${data['conversation_id']}');
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: isRead
                                ? AppColors.neutralLight
                                : categoryColor.withValues(alpha: 0.14),
                            child: Icon(
                              _categoryIcon(data),
                              color: isRead ? AppColors.neutral : categoryColor,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withValues(alpha: 0.10),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        categoryLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: categoryColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (!isRead)
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (createdAt != null) ...[
                                      if (!isRead)
                                        const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        _timeAgo(createdAt, l10n),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  (notif['title'] ?? '').toString(),
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  (notif['body'] ?? '').toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isRead
                                        ? AppColors.textSecondary
                                        : AppColors.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.chevron_right,
                              color: AppColors.neutral,
                            ),
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
            error: (e, _) => Center(
              child: Text(
                uiSafeErrorText(context, e, fallback: l10n.notificationsLoadError),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime, AppLocalizations l10n) {
    final diff = IstTime.age(dateTime);
    if (diff.inDays > 0) return l10n.notificationsTimeDaysAgo(diff.inDays);
    if (diff.inHours > 0) return l10n.notificationsTimeHoursAgo(diff.inHours);
    if (diff.inMinutes > 0) {
      return l10n.notificationsTimeMinutesAgo(diff.inMinutes);
    }
    return l10n.notificationsTimeJustNow;
  }

  String _categoryLabel(AppLocalizations l10n, Map<String, dynamic> data) {
    if (data.containsKey('trip_id')) {
      return l10n.tripDetailTitle;
    }
    if (data.containsKey('conversation_id')) {
      return l10n.chatTitle;
    }
    if (data.containsKey('load_id')) {
      return l10n.loadDetailTitle;
    }
    return l10n.appBarNotificationsTooltip;
  }

  IconData _categoryIcon(Map<String, dynamic> data) {
    if (data.containsKey('trip_id')) {
      return Icons.local_shipping_outlined;
    }
    if (data.containsKey('conversation_id')) {
      return Icons.chat_bubble_outline;
    }
    if (data.containsKey('load_id')) {
      return Icons.inventory_2_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color _categoryColor(Map<String, dynamic> data) {
    if (data.containsKey('trip_id')) {
      return AppColors.primary;
    }
    if (data.containsKey('conversation_id')) {
      return AppColors.brandOrange;
    }
    if (data.containsKey('load_id')) {
      return AppColors.brandTeal;
    }
    return AppColors.neutral;
  }
}
