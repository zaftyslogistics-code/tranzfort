import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/notification_repository.dart';

class NotificationsState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final List<AppNotification> notifications;
  final AppFailure? failure;

  const NotificationsState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.notifications,
    required this.failure,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      notifications: <AppNotification>[],
      failure: null,
    );
  }

  NotificationsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    List<AppNotification>? notifications,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      notifications: notifications ?? this.notifications,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  static const int _pageSize = 20;

  final NotificationRepository _repository;
  StreamSubscription<Result<List<AppNotification>>>? _subscription;
  DateTime? _loadStartTime;

  NotificationsController(this._repository) : super(NotificationsState.initial()) {
    _start();
  }

  Future<void> _start() async {
    _loadStartTime = DateTime.now();
    await load();
    _subscription = _repository.watchNotifications().listen((result) {
      result.when(
        success: (notifications) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            notifications: _mergeNotifications(
              incoming: notifications,
              existing: state.notifications,
            ),
            hasMore: state.hasMore || notifications.length >= _pageSize,
            clearFailure: true,
          );
        },
        failure: (failure) async {
          // Ensure minimum loading duration to prevent UI flicker
          if (_loadStartTime != null) {
            final elapsed = DateTime.now().difference(_loadStartTime!).inMilliseconds;
            if (elapsed < 300) {
              await Future.delayed(Duration(milliseconds: 300 - elapsed));
            }
          }
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            failure: failure,
          );
        },
      );
    });
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    
    // Add minimum loading duration to prevent flickering
    final startTime = DateTime.now();

    final result = await _repository.getNotifications(limit: _pageSize);
    await result.when(
      success: (notifications) async {
        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          hasMore: notifications.length >= _pageSize,
          clearFailure: true,
        );
      },
      failure: (failure) async {
        // Ensure minimum loading duration to prevent UI flicker
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 300) {
          await Future.delayed(Duration(milliseconds: 300 - elapsed));
        }
        state = state.copyWith(
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore || state.notifications.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    final lastCreatedAt = state.notifications.last.createdAt;
    final result = await _repository.getNotifications(
      limit: _pageSize,
      before: lastCreatedAt,
    );
    result.when(
      success: (notifications) {
        state = state.copyWith(
          isLoadingMore: false,
          notifications: _mergeNotifications(
            incoming: notifications,
            existing: state.notifications,
          ),
          hasMore: notifications.length >= _pageSize,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(
          isLoadingMore: false,
          failure: failure,
        );
      },
    );
  }

  Future<Result<void>> markRead(String notificationId) async {
    final result = await _repository.markRead(notificationId);
    if (result.isFailure) {
      state = state.copyWith(failure: result.failureOrNull);
      return result;
    }

    state = state.copyWith(
      notifications: state.notifications
          .map(
            (notification) => notification.id == notificationId
                ? notification.copyWith(isRead: true, readAt: notification.readAt ?? DateTime.now())
                : notification,
          )
          .toList(growable: false),
      clearFailure: true,
    );
    return result;
  }

  Future<Result<void>> markAllRead() async {
    final result = await _repository.markAllRead();
    if (result.isFailure) {
      state = state.copyWith(failure: result.failureOrNull);
      return result;
    }

    final readAt = DateTime.now();
    state = state.copyWith(
      notifications: state.notifications
          .map(
            (notification) => notification.isRead
                ? notification
                : AppNotification(
                    id: notification.id,
                    type: notification.type,
                    priority: notification.priority,
                    titleText: notification.titleText,
                    bodyText: notification.bodyText,
                    relatedLoadId: notification.relatedLoadId,
                    relatedTripId: notification.relatedTripId,
                    relatedCaseId: notification.relatedCaseId,
                    actionRouteHint: notification.actionRouteHint,
                    isRead: true,
                    readAt: readAt,
                    createdAt: notification.createdAt,
                  ),
          )
          .toList(growable: false),
      clearFailure: true,
    );
    return result;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<AppNotification> _mergeNotifications({
    required List<AppNotification> incoming,
    required List<AppNotification> existing,
  }) {
    final mergedById = <String, AppNotification>{
      for (final notification in existing) notification.id: notification,
    };
    for (final notification in incoming) {
      mergedById[notification.id] = notification;
    }
    final merged = mergedById.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return merged;
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  ref.onDispose(() {
    // Optional cleanup if needed
  });
  return NotificationsController(ref.watch(notificationRepositoryProvider));
});

final shellUnreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) async* {
  final repository = ref.watch(notificationRepositoryProvider);
  final initial = await repository.getUnreadCount();
  yield initial.valueOrNull ?? 0;

  await for (final result in repository.watchUnreadCount()) {
    yield result.valueOrNull ?? 0;
  }
});

final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final state = ref.watch(notificationsProvider);
  return state.notifications.where((notification) => !notification.isRead).length;
});
