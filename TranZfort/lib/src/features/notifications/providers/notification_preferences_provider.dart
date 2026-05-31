import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/notification_preferences_repository.dart';

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesController, NotificationPreferences>(
  NotificationPreferencesController.new,
);

class NotificationPreferencesController extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() async {
    final result = await ref.watch(notificationPreferencesRepositoryProvider).fetch();
    return result.when(
      success: (value) => value,
      failure: (failure) => throw failure,
    );
  }

  Future<void> setPushEnabled(bool value) => _update(pushEnabled: value);

  Future<void> setTripUpdatesEnabled(bool value) => _update(tripUpdatesEnabled: value);

  Future<void> setChatMessagesEnabled(bool value) => _update(chatMessagesEnabled: value);

  Future<void> setLoadBookingEnabled(bool value) => _update(loadBookingEnabled: value);

  Future<void> setLoadStatusUpdatesEnabled(bool value) => _update(loadStatusUpdatesEnabled: value);

  Future<void> setSystemNotificationsEnabled(bool value) => _update(systemNotificationsEnabled: value);

  Future<void> _update({
    bool? pushEnabled,
    bool? tripUpdatesEnabled,
    bool? chatMessagesEnabled,
    bool? loadBookingEnabled,
    bool? loadStatusUpdatesEnabled,
    bool? systemNotificationsEnabled,
  }) async {
    final previous = state;
    final current = previous.valueOrNull;
    if (current == null) {
      return;
    }

    state = AsyncData<NotificationPreferences>(
      current.copyWith(
        pushEnabled: pushEnabled ?? current.pushEnabled,
        tripUpdatesEnabled: tripUpdatesEnabled ?? current.tripUpdatesEnabled,
        chatMessagesEnabled: chatMessagesEnabled ?? current.chatMessagesEnabled,
        loadBookingEnabled: loadBookingEnabled ?? current.loadBookingEnabled,
        loadStatusUpdatesEnabled: loadStatusUpdatesEnabled ?? current.loadStatusUpdatesEnabled,
        systemNotificationsEnabled: systemNotificationsEnabled ?? current.systemNotificationsEnabled,
      ),
    );

    final result = await ref.read(notificationPreferencesRepositoryProvider).update(
          pushEnabled: pushEnabled,
          tripUpdatesEnabled: tripUpdatesEnabled,
          chatMessagesEnabled: chatMessagesEnabled,
          loadBookingEnabled: loadBookingEnabled,
          loadStatusUpdatesEnabled: loadStatusUpdatesEnabled,
          systemNotificationsEnabled: systemNotificationsEnabled,
        );

    result.when(
      success: (value) {
        state = AsyncData<NotificationPreferences>(value);
      },
      failure: (failure) {
        state = previous;
        throw failure;
      },
    );
  }
}

AppFailure? notificationPreferencesFailure(AsyncValue<NotificationPreferences> value) {
  final error = value.asError?.error;
  if (error is AppFailure) {
    return error;
  }
  return null;
}
