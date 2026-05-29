import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_locale_providers.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/providers/tts_audio_language_provider.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/status_components.dart';
import '../../shell/presentation/shell_components.dart';
import '../data/notification_repository.dart';
import '../data/notification_route_resolver.dart';
import '../data/notification_tts_service.dart';
import '../providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final state = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final highPriorityUnreadCount = state.notifications
        .where((item) => !item.isRead && item.priority == AppNotificationPriority.high)
        .length;
    final languageCode = ref.watch(appLocaleProvider).locale.languageCode;
    final ttsSummary = _notificationsTtsSummary(
      context: context,
      languageCode: languageCode,
      unreadCount: unreadCount,
      highPriorityUnreadCount: highPriorityUnreadCount,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonNotificationsLabel),
        actions: [
          const TtsActionButton(),
          if (state.notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: TextButton(
                onPressed: unreadCount == 0
                    ? null
                    : () async {
                        final result = await ref.read(notificationsProvider.notifier).markAllRead();
                        if (!context.mounted || result.isFailure) {
                          if (!context.mounted || result.failureOrNull == null) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            AppSnackbar.build(
                              context: context,
                              message: _notificationsMarkAllReadFailureMessage(context),
                              variant: AppSnackbarVariant.error,
                            ),
                          );
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          AppSnackbar.build(
                            context: context,
                            message: l10n.notificationsMarkedAllReadSuccess,
                            variant: AppSnackbarVariant.success,
                          ),
                        );
                      },
                child: Text(l10n.notificationsMarkAllRead),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          _NotificationsBody(
            state: state,
            unreadCount: unreadCount,
            highPriorityUnreadCount: highPriorityUnreadCount,
          ),
          TtsScreenSummaryEffect(
            summary: ttsSummary,
            screenKey: AppRoutes.notificationsPath,
          ),
        ],
      ),
    );
  }
}

String _notificationsMarkAllReadFailureMessage(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return l10n.notificationsMarkAllReadFailureMessage;
}

String _notificationsTtsSummary({
  required BuildContext context,
  required String languageCode,
  required int unreadCount,
  required int highPriorityUnreadCount,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  return l10n.notificationsTtsSummary(unreadCount, highPriorityUnreadCount);
}

class _NotificationsBody extends ConsumerWidget {
  final NotificationsState state;
  final int unreadCount;
  final int highPriorityUnreadCount;

  const _NotificationsBody({
    required this.state,
    required this.unreadCount,
    required this.highPriorityUnreadCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final languageCode = ref.watch(appLocaleProvider).locale.languageCode;
    if (!state.hasResolvedInitialLoad || state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingShimmer(height: 96, itemCount: 4),
      );
    }

    if (state.failure != null && state.notifications.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: WarningBlock(
          title: l10n.notificationsLoadFailureTitle,
          message: _notificationsFailureMessage(context),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      final role = ref.watch(currentAuthStateProvider).role;
      final isSupplier = role == AppUserRole.supplier;
      return EmptyStateView(
        icon: Icons.notifications_none_outlined,
        title: l10n.notificationsEmptyTitle,
        subtitle: l10n.notificationsEmptySubtitle,
        actionLabel: isSupplier ? l10n.commonOpenMyLoadsAction : l10n.truckerTripsEmptyActiveAction,
        onAction: () => context.go(isSupplier ? AppRoutes.myLoadsPath : AppRoutes.findLoadsPath),
      );
    }

    final groupedNotifications = _groupNotifications(context, state.notifications, l10n);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.bottomNavSafe + AppSpacing.xl,
      ),
      children: [
        SectionCard(
          title: l10n.notificationsOverviewTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  StatusBadge(
                    label: l10n.notificationsUnreadCountLabel(unreadCount),
                    icon: Icons.notifications_active_outlined,
                    palette: unreadCount == 0
                        ? const StatusPalette(
                            foreground: AppColors.neutral,
                            background: AppColors.neutralBg,
                          )
                        : const StatusPalette(
                            foreground: AppColors.info,
                            background: AppColors.infoBg,
                          ),
                  ),
                  StatusBadge(
                    label: l10n.notificationsHighPriorityCountLabel(highPriorityUnreadCount),
                    icon: Icons.priority_high_outlined,
                    palette: highPriorityUnreadCount == 0
                        ? const StatusPalette(
                            foreground: AppColors.neutral,
                            background: AppColors.neutralBg,
                          )
                        : const StatusPalette(
                            foreground: AppColors.warning,
                            background: AppColors.warningBg,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: l10n.commonHearSummary,
                  onPressed: () async {
                    final outcome = await ref.read(contextualTtsServiceProvider).speakSummary(
                          languageCode: languageCode,
                          message: _notificationsTtsSummary(
                            context: context,
                            languageCode: languageCode,
                            unreadCount: unreadCount,
                            highPriorityUnreadCount: highPriorityUnreadCount,
                          ),
                        );
                    if (!context.mounted || outcome == ContextualTtsOutcome.spoken || outcome == ContextualTtsOutcome.skipped) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      AppSnackbar.build(
                        context: context,
                        message: outcome == ContextualTtsOutcome.muted ? l10n.commonVoiceMuted : l10n.commonVoiceUnavailable,
                        variant: outcome == ContextualTtsOutcome.muted ? AppSnackbarVariant.info : AppSnackbarVariant.error,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        for (final group in groupedNotifications) ...[
          SectionCard(
            title: group.label,
            child: Column(
              children: [
                for (var index = 0; index < group.notifications.length; index++) ...[
                  _NotificationRow(notification: group.notifications[index]),
                  if (index != group.notifications.length - 1)
                    const Divider(height: AppSpacing.xl),
                ],
              ],
            ),
          ),
          if (group != groupedNotifications.last) const SizedBox(height: AppSpacing.sectionGap),
        ],
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: OutlineButton(
              label: l10n.commonLoadMoreAction,
              onPressed: () => ref.read(notificationsProvider.notifier).loadMore(),
            ),
          ),
      ],
    );
  }

  String _notificationsFailureMessage(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.notificationsLoadFailureMessage;
  }
}

class _NotificationRow extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationRow({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final role = ref.watch(currentAuthStateProvider).role;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: !notification.isRead || notification.priority == AppNotificationPriority.high
          ? FontWeight.w700
          : FontWeight.w600,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () async {
        if (!notification.isRead) {
          await ref.read(notificationsProvider.notifier).markRead(notification.id);
        }

        await ref.read(notificationTtsServiceProvider).speakNotificationOpen(
          notification: notification,
          role: role,
          audioLanguageCode: ref.read(ttsAudioLanguageProvider),
        );

        if (!context.mounted) {
          return;
        }

        context.push(resolveNotificationRoute(notification, role));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBackground(notification),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(notification.type), color: _iconForeground(notification), size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          notification.titleText ?? _fallbackTitle(notification.type, l10n),
                          style: titleStyle,
                        ),
                      ),
                      if (notification.priority == AppNotificationPriority.high)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.notificationsPriorityHighLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notification.bodyText ?? l10n.notificationsBodyFallback,
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _formatNotificationTimestamp(context, notification.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationGroup {
  final String label;
  final List<AppNotification> notifications;

  const _NotificationGroup({
    required this.label,
    required this.notifications,
  });
}

List<_NotificationGroup> _groupNotifications(
  BuildContext context,
  List<AppNotification> notifications,
  AppLocalizations l10n,
) {
  final now = DateTime.now();
  final Map<String, List<AppNotification>> grouped = <String, List<AppNotification>>{};
  final List<String> order = <String>[];

  for (final notification in notifications) {
    final localDate = notification.createdAt.toLocal();
    final label = _groupLabel(context, localDate, now, l10n);
    if (!grouped.containsKey(label)) {
      grouped[label] = <AppNotification>[];
      order.add(label);
    }
    grouped[label]!.add(notification);
  }

  return order
      .map(
        (label) => _NotificationGroup(
          label: label,
          notifications: grouped[label]!,
        ),
      )
      .toList(growable: false);
}

String _groupLabel(BuildContext context, DateTime date, DateTime now, AppLocalizations l10n) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;
  if (diff == 0) {
    return l10n.notificationsGroupToday;
  }
  if (diff == 1) {
    return l10n.notificationsGroupYesterday;
  }
  return MaterialLocalizations.of(context).formatMediumDate(date);
}

String _formatNotificationTimestamp(BuildContext context, DateTime date) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(date.toLocal()),
    alwaysUse24HourFormat: MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );
}

String _fallbackTitle(AppNotificationType type, AppLocalizations l10n) {
  final typeValue = switch (type) {
    AppNotificationType.verificationUpdate => 'verification_update',
    AppNotificationType.bookingUpdate => 'booking_update',
    AppNotificationType.tripUpdate => 'trip_update',
    AppNotificationType.proofUpdate => 'proof_update',
    AppNotificationType.superLoadUpdate => 'super_load_update',
    AppNotificationType.messageReceived => 'message_received',
    AppNotificationType.supportUpdate => 'support_update',
    AppNotificationType.disputeUpdate => 'dispute_update',
    AppNotificationType.accountUpdate => 'account_update',
    AppNotificationType.systemNotice => 'system_notice',
    AppNotificationType.loadExpiryWarning => 'load_expiry_warning',
  };
  return l10n.notificationFallbackValue(typeValue);
}

IconData _iconFor(AppNotificationType type) {
  return switch (type) {
    AppNotificationType.verificationUpdate => Icons.verified_outlined,
    AppNotificationType.bookingUpdate => Icons.assignment_turned_in_outlined,
    AppNotificationType.tripUpdate => Icons.alt_route_outlined,
    AppNotificationType.proofUpdate => Icons.fact_check_outlined,
    AppNotificationType.superLoadUpdate => Icons.workspace_premium_outlined,
    AppNotificationType.messageReceived => Icons.chat_bubble_outline,
    AppNotificationType.supportUpdate => Icons.support_agent_outlined,
    AppNotificationType.disputeUpdate => Icons.gavel_outlined,
    AppNotificationType.accountUpdate => Icons.manage_accounts_outlined,
    AppNotificationType.systemNotice => Icons.notifications_outlined,
    AppNotificationType.loadExpiryWarning => Icons.schedule_outlined,
  };
}

Color _iconForeground(AppNotification notification) {
  if (notification.priority == AppNotificationPriority.high) {
    return AppColors.warning;
  }
  if (!notification.isRead) {
    return AppColors.info;
  }
  return AppColors.primary;
}

Color _iconBackground(AppNotification notification) {
  if (notification.priority == AppNotificationPriority.high) {
    return AppColors.warningBg;
  }
  if (!notification.isRead) {
    return AppColors.infoBg;
  }
  return AppColors.neutralBg;
}
