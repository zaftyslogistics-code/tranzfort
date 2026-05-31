import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../shell/presentation/shell_components.dart';
import '../providers/notification_preferences_provider.dart';

class NotificationPreferencesSettingsCard extends ConsumerWidget {
  const NotificationPreferencesSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final preferencesAsync = ref.watch(notificationPreferencesProvider);

    return SectionCard(
      title: l10n.settingsNotificationCategoriesTitle,
      child: preferencesAsync.when(
        data: (preferences) {
          Future<void> toggle(
            bool value,
            Future<void> Function(bool) setter,
          ) async {
            try {
              await setter(value);
            } catch (error) {
              if (!context.mounted) {
                return;
              }
              final message = error is AppFailure
                  ? error.message
                  : l10n.settingsNotificationPreferencesFailure;
              AppSnackbar.show(
                context: context,
                message: message,
                variant: AppSnackbarVariant.error,
              );
            }
          }

          return Column(
            children: [
              _PreferenceSwitchTile(
                label: l10n.settingsNotificationCategoryPush,
                value: preferences.pushEnabled,
                onChanged: (value) => toggle(value, ref.read(notificationPreferencesProvider.notifier).setPushEnabled),
              ),
              _PreferenceSwitchTile(
                label: l10n.settingsNotificationCategoryTrip,
                value: preferences.tripUpdatesEnabled,
                onChanged: (value) =>
                    toggle(value, ref.read(notificationPreferencesProvider.notifier).setTripUpdatesEnabled),
              ),
              _PreferenceSwitchTile(
                label: l10n.settingsNotificationCategoryChat,
                value: preferences.chatMessagesEnabled,
                onChanged: (value) =>
                    toggle(value, ref.read(notificationPreferencesProvider.notifier).setChatMessagesEnabled),
              ),
              _PreferenceSwitchTile(
                label: l10n.settingsNotificationCategoryBooking,
                value: preferences.loadBookingEnabled,
                onChanged: (value) =>
                    toggle(value, ref.read(notificationPreferencesProvider.notifier).setLoadBookingEnabled),
              ),
              _PreferenceSwitchTile(
                label: l10n.settingsNotificationCategoryLoadStatus,
                value: preferences.loadStatusUpdatesEnabled,
                onChanged: (value) => toggle(
                  value,
                  ref.read(notificationPreferencesProvider.notifier).setLoadStatusUpdatesEnabled,
                ),
              ),
              _PreferenceSwitchTile(
                label: l10n.settingsNotificationCategorySystem,
                value: preferences.systemNotificationsEnabled,
                onChanged: (value) => toggle(
                  value,
                  ref.read(notificationPreferencesProvider.notifier).setSystemNotificationsEnabled,
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingShimmer(height: 220, itemCount: 1),
        error: (error, _) => WarningBlock(
          title: l10n.settingsNotificationCategoriesTitle,
          message: l10n.settingsNotificationPreferencesFailure,
          action: OutlineButton(
            label: l10n.commonRetryAction,
            onPressed: () => ref.invalidate(notificationPreferencesProvider),
          ),
        ),
      ),
    );
  }
}

class _PreferenceSwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
