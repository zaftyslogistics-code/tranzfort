import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/providers/app_state_providers.dart';

class NotificationPreferences {
  final bool pushEnabled;
  final bool tripUpdatesEnabled;
  final bool chatMessagesEnabled;
  final bool loadBookingEnabled;
  final bool loadStatusUpdatesEnabled;
  final bool systemNotificationsEnabled;

  const NotificationPreferences({
    required this.pushEnabled,
    required this.tripUpdatesEnabled,
    required this.chatMessagesEnabled,
    required this.loadBookingEnabled,
    required this.loadStatusUpdatesEnabled,
    required this.systemNotificationsEnabled,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    bool readFlag(String key, {bool defaultValue = true}) {
      final value = map[key];
      if (value is bool) {
        return value;
      }
      if (value == null) {
        return defaultValue;
      }
      return value.toString().toLowerCase() == 'true';
    }

    return NotificationPreferences(
      pushEnabled: readFlag('push_enabled'),
      tripUpdatesEnabled: readFlag('trip_updates_enabled'),
      chatMessagesEnabled: readFlag('chat_messages_enabled'),
      loadBookingEnabled: readFlag('load_booking_enabled'),
      loadStatusUpdatesEnabled: readFlag('load_status_updates_enabled'),
      systemNotificationsEnabled: readFlag('system_notifications_enabled'),
    );
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? tripUpdatesEnabled,
    bool? chatMessagesEnabled,
    bool? loadBookingEnabled,
    bool? loadStatusUpdatesEnabled,
    bool? systemNotificationsEnabled,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      tripUpdatesEnabled: tripUpdatesEnabled ?? this.tripUpdatesEnabled,
      chatMessagesEnabled: chatMessagesEnabled ?? this.chatMessagesEnabled,
      loadBookingEnabled: loadBookingEnabled ?? this.loadBookingEnabled,
      loadStatusUpdatesEnabled: loadStatusUpdatesEnabled ?? this.loadStatusUpdatesEnabled,
      systemNotificationsEnabled: systemNotificationsEnabled ?? this.systemNotificationsEnabled,
    );
  }
}

class NotificationPreferencesRepository {
  final SupabaseClient? _client;
  final String? Function() _currentUserId;

  const NotificationPreferencesRepository(this._client, this._currentUserId);

  Future<Result<NotificationPreferences>> fetch() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<NotificationPreferences>(UnauthorizedFailure());
    }

    final client = _client;
    if (client == null) {
      return const Failure<NotificationPreferences>(UnauthorizedFailure());
    }

    try {
      final response = await client.rpc(
        'get_notification_preferences',
        params: <String, dynamic>{'p_user_id': userId},
      );
      final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return Success<NotificationPreferences>(NotificationPreferences.fromMap(map));
    } catch (error, stackTrace) {
      return Failure<NotificationPreferences>(mapSupabaseError(error, stackTrace));
    }
  }

  Future<Result<NotificationPreferences>> update({
    bool? pushEnabled,
    bool? tripUpdatesEnabled,
    bool? chatMessagesEnabled,
    bool? loadBookingEnabled,
    bool? loadStatusUpdatesEnabled,
    bool? systemNotificationsEnabled,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<NotificationPreferences>(UnauthorizedFailure());
    }

    final client = _client;
    if (client == null) {
      return const Failure<NotificationPreferences>(UnauthorizedFailure());
    }

    try {
      final response = await client.rpc(
        'update_notification_preferences',
        params: <String, dynamic>{
          'p_user_id': userId,
          ...<String, dynamic>{
            if (pushEnabled != null) 'p_push_enabled': pushEnabled,
            if (tripUpdatesEnabled != null) 'p_trip_updates_enabled': tripUpdatesEnabled,
            if (chatMessagesEnabled != null) 'p_chat_messages_enabled': chatMessagesEnabled,
            if (loadBookingEnabled != null) 'p_load_booking_enabled': loadBookingEnabled,
            if (loadStatusUpdatesEnabled != null) 'p_load_status_updates_enabled': loadStatusUpdatesEnabled,
            if (systemNotificationsEnabled != null) 'p_system_notifications_enabled': systemNotificationsEnabled,
          },
        },
      );
      final map = response is Map<String, dynamic> ? response : <String, dynamic>{};
      return Success<NotificationPreferences>(NotificationPreferences.fromMap(map));
    } catch (error, stackTrace) {
      return Failure<NotificationPreferences>(mapSupabaseError(error, stackTrace));
    }
  }
}

final notificationPreferencesRepositoryProvider = Provider<NotificationPreferencesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationPreferencesRepository(
    client,
    () => client?.auth.currentUser?.id,
  );
});
