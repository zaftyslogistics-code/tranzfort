import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/notifications/data/notification_repository.dart';

class _FakeNotificationBackend implements NotificationBackend {
  List<Map<String, dynamic>> notificationRows = const <Map<String, dynamic>>[];
  final StreamController<List<Map<String, dynamic>>> streamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  Object? error;
  int unreadCount = 0;
  String? markedNotificationId;
  bool markAllCalled = false;

  @override
  Future<List<Map<String, dynamic>>> fetchNotifications({required String userId, int limit = 20, DateTime? before}) async {
    if (error != null) {
      throw error!;
    }
    var rows = notificationRows;
    if (before != null) {
      rows = rows
          .where(
            (row) => DateTime.parse((row['created_at'] ?? '').toString()).isBefore(before),
          )
          .toList(growable: false);
    }
    return rows.take(limit).toList(growable: false);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications({required String userId}) => streamController.stream;

  @override
  Future<int> fetchUnreadCount({required String userId}) async {
    if (error != null) {
      throw error!;
    }
    return unreadCount;
  }

  @override
  Future<void> markNotificationRead({required String notificationId}) async {
    if (error != null) {
      throw error!;
    }
    markedNotificationId = notificationId;
  }

  @override
  Future<void> markAllNotificationsRead() async {
    if (error != null) {
      throw error!;
    }
    markAllCalled = true;
  }
}

void main() {
  test('notification repository maps notifications', () async {
    final backend = _FakeNotificationBackend()
      ..notificationRows = [
        {
          'id': 'notification-1',
          'notification_type': 'booking_update',
          'notification_priority': 'high',
          'title_text': 'Booking Approved!',
          'body_text': 'Head to pickup for Coal Chandrapur>Mumbai',
          'related_load_id': 'load-1',
          'related_trip_id': 'trip-1',
          'related_case_id': null,
          'action_route_hint': '/trip-detail/trip-1',
          'is_read': false,
          'read_at': null,
          'created_at': '2026-03-10T09:00:00.000Z',
        },
      ];
    final repository = NotificationRepository(backend, () => 'user-1');

    final result = await repository.getNotifications();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.type, AppNotificationType.bookingUpdate);
    expect(result.valueOrNull!.first.priority, AppNotificationPriority.high);
    expect(result.valueOrNull!.first.actionRouteHint, '/trip-detail/trip-1');
    expect(result.valueOrNull!.first.isRead, isFalse);
  });

  test('notification repository marks one notification read', () async {
    final backend = _FakeNotificationBackend();
    final repository = NotificationRepository(backend, () => 'user-1');

    final result = await repository.markRead('notification-1');

    expect(result.isSuccess, isTrue);
    expect(backend.markedNotificationId, 'notification-1');
  });

  test('notification repository marks all notifications read', () async {
    final backend = _FakeNotificationBackend();
    final repository = NotificationRepository(backend, () => 'user-1');

    final result = await repository.markAllRead();

    expect(result.isSuccess, isTrue);
    expect(backend.markAllCalled, isTrue);
  });

  test('notification repository returns unread count', () async {
    final backend = _FakeNotificationBackend()..unreadCount = 3;
    final repository = NotificationRepository(backend, () => 'user-1');

    final result = await repository.getUnreadCount();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 3);
  });

  test('notification repository maps backend errors', () async {
    final backend = _FakeNotificationBackend()
      ..error = const PostgrestException(message: 'permission denied', code: '42501');
    final repository = NotificationRepository(backend, () => 'user-1');

    final result = await repository.markAllRead();

    expect(result.failureOrNull, isA<PermissionFailure>());
  });
}
