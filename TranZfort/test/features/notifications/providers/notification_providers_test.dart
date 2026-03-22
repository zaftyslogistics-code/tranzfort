import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/notifications/data/notification_repository.dart';
import 'package:tranzfort/src/features/notifications/providers/notification_providers.dart';

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
  Future<int> fetchUnreadCount({required String userId}) async => unreadCount;

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

AppNotification _notification(
  String id, {
  bool isRead = false,
  DateTime? createdAt,
}) {
  return AppNotification(
    id: id,
    type: AppNotificationType.bookingUpdate,
    priority: AppNotificationPriority.medium,
    titleText: 'Booking update',
    bodyText: 'Latest workflow update',
    relatedLoadId: 'load-1',
    relatedTripId: 'trip-1',
    relatedCaseId: null,
    actionRouteHint: '/trip-detail/trip-1',
    isRead: isRead,
    readAt: isRead ? DateTime(2026, 3, 10, 10) : null,
    createdAt: createdAt ?? DateTime(2026, 3, 10, 9),
  );
}

Map<String, dynamic> _notificationRow(
  String id, {
  bool isRead = false,
  String createdAt = '2026-03-10T09:00:00.000Z',
}) {
  return {
    'id': id,
    'notification_type': 'booking_update',
    'notification_priority': 'medium',
    'title_text': 'Booking update',
    'body_text': 'Latest workflow update',
    'related_load_id': 'load-1',
    'related_trip_id': 'trip-1',
    'related_case_id': null,
    'action_route_hint': '/trip-detail/trip-1',
    'is_read': isRead,
    'read_at': isRead ? '2026-03-10T10:00:00.000Z' : null,
    'created_at': createdAt,
  };
}

void main() {
  test('notifications provider loads initial notifications and merges realtime updates', () async {
    final backend = _FakeNotificationBackend()
      ..notificationRows = [_notificationRow('notification-1')];
    final repository = NotificationRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(notificationsProvider, (_, _) {});
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await backend.streamController.close();
    });

    await Future<void>.delayed(Duration.zero);

    expect(container.read(notificationsProvider).notifications, hasLength(1));
    expect(container.read(unreadNotificationCountProvider), 1);

    backend.streamController.add([
      _notificationRow('notification-2', createdAt: '2026-03-10T10:00:00.000Z'),
      _notificationRow('notification-1'),
    ]);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(notificationsProvider);
    expect(state.notifications.first.id, 'notification-2');
    expect(container.read(unreadNotificationCountProvider), 2);
  });

  test('notifications provider preserves paged older notifications when realtime updates arrive', () async {
    final backend = _FakeNotificationBackend()
      ..notificationRows = List.generate(
        21,
        (index) {
          final itemNumber = 21 - index;
          final hour = itemNumber.toString().padLeft(2, '0');
          return _notificationRow(
            'notification-$itemNumber',
            createdAt: '2026-03-10T$hour:00:00.000Z',
          );
        },
      );
    final repository = NotificationRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(notificationsProvider, (_, _) {});
    addTearDown(() async {
      subscription.close();
      container.dispose();
      await backend.streamController.close();
    });

    await Future<void>.delayed(Duration.zero);
    expect(container.read(notificationsProvider).notifications, hasLength(20));

    await container.read(notificationsProvider.notifier).loadMore();
    expect(container.read(notificationsProvider).notifications, hasLength(21));
    expect(container.read(notificationsProvider).notifications.last.id, 'notification-1');

    backend.streamController.add([
      _notificationRow('notification-22', createdAt: '2026-03-10T22:00:00.000Z'),
      for (var itemNumber = 21; itemNumber >= 2; itemNumber--)
        _notificationRow(
          'notification-$itemNumber',
          createdAt: '2026-03-10T${itemNumber.toString().padLeft(2, '0')}:00:00.000Z',
        ),
    ]);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(notificationsProvider);
    expect(state.notifications.first.id, 'notification-22');
    expect(state.notifications.any((item) => item.id == 'notification-1'), isTrue);
    expect(state.notifications, hasLength(22));
  });

  test('notifications provider marks one notification read', () async {
    final backend = _FakeNotificationBackend()
      ..notificationRows = [_notificationRow('notification-1')];
    final repository = NotificationRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await backend.streamController.close();
    });

    await Future<void>.delayed(Duration.zero);
    final result = await container.read(notificationsProvider.notifier).markRead('notification-1');

    expect(result.isSuccess, isTrue);
    expect(backend.markedNotificationId, 'notification-1');
    expect(container.read(notificationsProvider).notifications.first.isRead, isTrue);
    expect(container.read(unreadNotificationCountProvider), 0);
  });

  test('notifications provider marks all notifications read', () async {
    final backend = _FakeNotificationBackend()
      ..notificationRows = [
        _notificationRow('notification-1'),
        _notificationRow('notification-2'),
      ];
    final repository = NotificationRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await backend.streamController.close();
    });

    await Future<void>.delayed(Duration.zero);
    final result = await container.read(notificationsProvider.notifier).markAllRead();

    expect(result.isSuccess, isTrue);
    expect(backend.markAllCalled, isTrue);
    expect(container.read(unreadNotificationCountProvider), 0);
    expect(container.read(notificationsProvider).notifications.every((item) => item.isRead), isTrue);
  });

  test('unread notification count provider derives count from loaded state', () {
    final container = ProviderContainer(
      overrides: [
        notificationsProvider.overrideWith(
          (ref) => _TestNotificationsController(
            NotificationsState.initial().copyWith(
              isLoading: false,
              notifications: [
                _notification('notification-1', isRead: false),
                _notification('notification-2', isRead: true),
                _notification('notification-3', isRead: false),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(unreadNotificationCountProvider), 2);
  });

  test('notifications provider surfaces mark-read failures', () async {
    final backend = _FakeNotificationBackend()
      ..notificationRows = [_notificationRow('notification-1')]
      ..error = const PostgrestException(message: 'Unable to mark read');
    final repository = NotificationRepository(backend, () => 'user-1');
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await backend.streamController.close();
    });

    await Future<void>.delayed(Duration.zero);

    final result = await container.read(notificationsProvider.notifier).markRead('notification-1');

    expect(result.failureOrNull, isA<ServerFailure>());
    expect(container.read(notificationsProvider).failure, isA<ServerFailure>());
  });
}

class _TestNotificationsController extends NotificationsController {
  _TestNotificationsController(NotificationsState state)
      : super(NotificationRepository(_NoopNotificationBackend(), () => 'user-1')) {
    this.state = state;
  }
}

class _NoopNotificationBackend implements NotificationBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchNotifications({required String userId, int limit = 20, DateTime? before}) async =>
      const <Map<String, dynamic>>[];

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications({required String userId}) =>
      const Stream<List<Map<String, dynamic>>>.empty();

  @override
  Future<int> fetchUnreadCount({required String userId}) async => 0;

  @override
  Future<void> markNotificationRead({required String notificationId}) async {}

  @override
  Future<void> markAllNotificationsRead() async {}
}
