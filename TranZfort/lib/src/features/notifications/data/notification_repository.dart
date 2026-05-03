import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart' as flutterNotifications;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/map_readers.dart';

// SDN-011: Error codes for localization (UI should map these to AppLocalizations)
class NotificationErrorCodes {
  static const String notificationIdRequired = 'notification.notification_id_required';
}

enum AppNotificationType {
  verificationUpdate,
  bookingUpdate,
  tripUpdate,
  proofUpdate,
  superLoadUpdate,
  messageReceived,
  supportUpdate,
  disputeUpdate,
  accountUpdate,
  systemNotice,
  loadExpiryWarning,
}

extension AppNotificationTypeX on AppNotificationType {
  static AppNotificationType fromDatabase(String value) {
    return switch (value.trim().toLowerCase()) {
      'verification_update' => AppNotificationType.verificationUpdate,
      'booking_update' => AppNotificationType.bookingUpdate,
      'trip_update' => AppNotificationType.tripUpdate,
      'proof_update' => AppNotificationType.proofUpdate,
      'super_load_update' => AppNotificationType.superLoadUpdate,
      'message_received' => AppNotificationType.messageReceived,
      'support_update' => AppNotificationType.supportUpdate,
      'dispute_update' => AppNotificationType.disputeUpdate,
      'account_update' => AppNotificationType.accountUpdate,
      'load_expiry_warning' => AppNotificationType.loadExpiryWarning,
      _ => AppNotificationType.systemNotice,
    };
  }
}

enum AppNotificationPriority {
  low,
  medium,
  high,
  urgent,
}

extension AppNotificationPriorityX on AppNotificationPriority {
  static AppNotificationPriority fromDatabase(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return AppNotificationPriority.low;
      case 'high':
        return AppNotificationPriority.high;
      case 'urgent':
        return AppNotificationPriority.urgent;
      case 'normal':
      case 'medium':
      default:
        return AppNotificationPriority.medium;
    }
  }

  /// Whether this priority should bypass quiet-hours suppression.
  bool get bypassesQuietHours => this == AppNotificationPriority.urgent;

  /// Android [Importance] mapping for foreground push display.
  flutterNotifications.Importance get flutterImportance {
    return switch (this) {
      AppNotificationPriority.urgent => flutterNotifications.Importance.max,
      AppNotificationPriority.high => flutterNotifications.Importance.high,
      AppNotificationPriority.low => flutterNotifications.Importance.low,
      _ => flutterNotifications.Importance.defaultImportance,
    };
  }

  /// Android [Priority] mapping for foreground push display.
  flutterNotifications.Priority get flutterPriority {
    return switch (this) {
      AppNotificationPriority.urgent => flutterNotifications.Priority.max,
      AppNotificationPriority.high => flutterNotifications.Priority.high,
      AppNotificationPriority.low => flutterNotifications.Priority.low,
      _ => flutterNotifications.Priority.defaultPriority,
    };
  }
}

class NotificationDto {
  final String id;
  final AppNotificationType type;
  final AppNotificationPriority priority;
  final String? titleText;
  final String? bodyText;
  final String? relatedLoadId;
  final String? relatedTripId;
  final String? relatedCaseId;
  final String? actionRouteHint;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationDto({
    required this.id,
    required this.type,
    required this.priority,
    required this.titleText,
    required this.bodyText,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.relatedCaseId,
    required this.actionRouteHint,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  factory NotificationDto.fromMap(Map<String, dynamic> map) {
    return NotificationDto(
      id: (map['id'] ?? '').toString(),
      type: AppNotificationTypeX.fromDatabase((map['notification_type'] ?? 'system_notice').toString()),
      priority: AppNotificationPriorityX.fromDatabase((map['notification_priority'] ?? 'medium').toString()),
      titleText: nullableString(map['title_text']),
      bodyText: nullableString(map['body_text']),
      relatedLoadId: nullableString(map['related_load_id']),
      relatedTripId: nullableString(map['related_trip_id']),
      relatedCaseId: nullableString(map['related_case_id']),
      actionRouteHint: nullableString(map['action_route_hint']),
      isRead: map['is_read'] == true,
      readAt: readDate(map['read_at']),
      createdAt: readDate(map['created_at']) ?? DateTime.now(),
    );
  }

  AppNotification toDomain() {
    return AppNotification(
      id: id,
      type: type,
      priority: priority,
      titleText: titleText,
      bodyText: bodyText,
      relatedLoadId: relatedLoadId,
      relatedTripId: relatedTripId,
      relatedCaseId: relatedCaseId,
      actionRouteHint: actionRouteHint,
      isRead: isRead,
      readAt: readAt,
      createdAt: createdAt,
    );
  }
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final AppNotificationPriority priority;
  final String? titleText;
  final String? bodyText;
  final String? relatedLoadId;
  final String? relatedTripId;
  final String? relatedCaseId;
  final String? actionRouteHint;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.priority,
    required this.titleText,
    required this.bodyText,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.relatedCaseId,
    required this.actionRouteHint,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    AppNotificationType? type,
    AppNotificationPriority? priority,
    String? titleText,
    String? bodyText,
    String? relatedLoadId,
    String? relatedTripId,
    String? relatedCaseId,
    String? actionRouteHint,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      titleText: titleText ?? this.titleText,
      bodyText: bodyText ?? this.bodyText,
      relatedLoadId: relatedLoadId ?? this.relatedLoadId,
      relatedTripId: relatedTripId ?? this.relatedTripId,
      relatedCaseId: relatedCaseId ?? this.relatedCaseId,
      actionRouteHint: actionRouteHint ?? this.actionRouteHint,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

abstract class NotificationBackend {
  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String userId,
    int limit = 30,
    DateTime? before,
  });

  Stream<List<Map<String, dynamic>>> watchNotifications({required String userId});

  Future<int> fetchUnreadCount({required String userId});

  Future<void> markNotificationRead({required String notificationId});

  Future<void> markAllNotificationsRead();
}

class SupabaseNotificationBackend implements NotificationBackend {
  final SupabaseClient? _client;

  const SupabaseNotificationBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String userId,
    int limit = 30,
    DateTime? before,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    var query = _client
        .from('notifications')
        .select(
          'id, notification_type, notification_priority, title_text, body_text, related_load_id, related_trip_id, related_case_id, action_route_hint, is_read, read_at, created_at',
        )
        .eq('target_profile_id', userId);

    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }

    final response = await query.order('created_at', ascending: false).limit(limit);
    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications({required String userId}) {
    if (_client == null) {
      return Stream<List<Map<String, dynamic>>>.value(const <Map<String, dynamic>>[]);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: const ['id'])
        .eq('target_profile_id', userId)
        .map((rows) => rows.whereType<Map<String, dynamic>>().toList(growable: false));
  }

  @override
  Future<int> fetchUnreadCount({required String userId}) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('notifications')
        .select('id')
        .eq('target_profile_id', userId)
        .eq('is_read', false);

    return response.length;
  }

  @override
  Future<void> markNotificationRead({required String notificationId}) async {
    if (_client == null) {
      return;
    }

    await _client.rpc(
      'mark_notification_read',
      params: <String, dynamic>{'p_notification_id': notificationId},
    );
  }

  @override
  Future<void> markAllNotificationsRead() async {
    if (_client == null) {
      return;
    }

    await _client.rpc('mark_all_notifications_read');
  }
}

class NotificationRepository {
  final NotificationBackend _backend;
  final String? Function() _currentUserId;

  const NotificationRepository(this._backend, this._currentUserId);

  Future<Result<List<AppNotification>>> getNotifications({
    int limit = 30,
    DateTime? before,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<AppNotification>>(UnauthorizedFailure());
    }

    try {
      final rows = await _backend.fetchNotifications(
        userId: userId,
        limit: limit,
        before: before,
      );
      final notifications = rows
          .whereType<Map<String, dynamic>>()
          .map(NotificationDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Success<List<AppNotification>>(notifications);
    } catch (error, stackTrace) {
      return Failure<List<AppNotification>>(_mapError(error, stackTrace));
    }
  }

  Stream<Result<List<AppNotification>>> watchNotifications() async* {
    final userId = _currentUserId();
    if (userId == null) {
      yield const Failure<List<AppNotification>>(UnauthorizedFailure());
      return;
    }

    await for (final rows in _backend.watchNotifications(userId: userId)) {
      try {
        final notifications = rows
            .whereType<Map<String, dynamic>>()
            .map(NotificationDto.fromMap)
            .map((dto) => dto.toDomain())
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        yield Success<List<AppNotification>>(notifications);
      } catch (error, stackTrace) {
        yield Failure<List<AppNotification>>(_mapError(error, stackTrace));
      }
    }
  }

  Future<Result<int>> getUnreadCount() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<int>(UnauthorizedFailure());
    }

    try {
      final unreadCount = await _backend.fetchUnreadCount(userId: userId);
      return Success<int>(unreadCount);
    } catch (error, stackTrace) {
      return Failure<int>(_mapError(error, stackTrace));
    }
  }

  Stream<Result<int>> watchUnreadCount() async* {
    final userId = _currentUserId();
    if (userId == null) {
      yield const Failure<int>(UnauthorizedFailure());
      return;
    }

    // Compute count directly from stream data to avoid N+1 queries
    await for (final rows in _backend.watchNotifications(userId: userId)) {
      try {
        final unreadCount = rows.where((row) {
          final isRead = row['is_read'] as bool? ?? false;
          return !isRead;
        }).length;
        yield Success<int>(unreadCount);
      } catch (error, stackTrace) {
        yield Failure<int>(_mapError(error, stackTrace));
      }
    }
  }

  Future<Result<void>> markRead(String notificationId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedNotificationId = notificationId.trim();
    if (normalizedNotificationId.isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          // TODO: Map to NotificationErrorCodes.notificationIdRequired in UI layer
          message: 'Notification id is required',
          fieldErrors: {'notification_id': 'Notification id is required'},
        ),
      );
    }

    try {
      await _backend.markNotificationRead(notificationId: normalizedNotificationId);
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> markAllRead() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    try {
      await _backend.markAllNotificationsRead();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return NotificationRepository(
    SupabaseNotificationBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
