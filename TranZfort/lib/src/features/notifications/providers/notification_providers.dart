import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/notification_repository.dart';

class NotificationsState {
  final bool isLoading;
  final bool hasResolvedInitialLoad;
  final bool isLoadingMore;
  final bool hasMore;
  final List<AppNotification> notifications;
  final AppFailure? failure;

  const NotificationsState({
    required this.isLoading,
    required this.hasResolvedInitialLoad,
    required this.isLoadingMore,
    required this.hasMore,
    required this.notifications,
    required this.failure,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      isLoading: true,
      hasResolvedInitialLoad: false,
      isLoadingMore: false,
      hasMore: true,
      notifications: <AppNotification>[],
      failure: null,
    );
  }

  NotificationsState copyWith({
    bool? isLoading,
    bool? hasResolvedInitialLoad,
    bool? isLoadingMore,
    bool? hasMore,
    List<AppNotification>? notifications,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      hasResolvedInitialLoad: hasResolvedInitialLoad ?? this.hasResolvedInitialLoad,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      notifications: notifications ?? this.notifications,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class NotificationsController extends StateNotifier<NotificationsState> {
  static const int _pageSize = 20;
  static const Duration _minLoadingDuration = Duration(milliseconds: 300);
  static const Duration _errorDebounceDuration = Duration(milliseconds: 500);

  final NotificationRepository _repository;
  StreamSubscription<Result<List<AppNotification>>>? _subscription;
  Timer? _errorDebounceTimer;
  bool _initialFetchCompleted = false;
  bool _awaitingStreamAfterEmptyLoad = false;

  NotificationsController(
    this._repository, {
    bool startWatch = true,
  }) : super(NotificationsState.initial()) {
    if (startWatch) {
      _start();
    }
  }

  void _scheduleErrorDisplay(AppFailure failure) {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = Timer(_errorDebounceDuration, () {
      if (!mounted) {
        return;
      }
      if (state.notifications.isEmpty) {
        state = state.copyWith(
          failure: failure,
          isLoading: false,
          hasResolvedInitialLoad: true,
        );
      }
    });
  }

  void _cancelErrorDisplay() {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = null;
  }

  void _resolveWithNotifications(List<AppNotification> notifications) {
    _awaitingStreamAfterEmptyLoad = false;
    _cancelErrorDisplay();
    state = state.copyWith(
      isLoading: false,
      hasResolvedInitialLoad: true,
      notifications: notifications,
      hasMore: notifications.length >= _pageSize,
      clearFailure: true,
    );
  }

  Future<void> _ensureMinLoadingDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minLoadingDuration) {
      await Future.delayed(_minLoadingDuration - elapsed);
    }
  }

  Future<void> _start() async {
    _subscription = _repository.watchNotifications().listen(_handleStreamResult);
    await load();
  }

  void _handleStreamResult(Result<List<AppNotification>> result) {
    result.when(
      success: (notifications) {
        final merged = _mergeNotifications(
          incoming: notifications,
          existing: state.notifications,
        );
        if (!state.hasResolvedInitialLoad) {
          final canResolveFromStream = merged.isNotEmpty ||
              (_initialFetchCompleted && _awaitingStreamAfterEmptyLoad);
          if (canResolveFromStream) {
            _resolveWithNotifications(merged);
          }
          return;
        }
        _cancelErrorDisplay();
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          notifications: merged,
          hasMore: state.hasMore || notifications.length >= _pageSize,
          clearFailure: true,
        );
      },
      failure: (failure) {
        if (state.hasResolvedInitialLoad && state.notifications.isNotEmpty) {
          return;
        }
        _scheduleErrorDisplay(failure);
      },
    );
  }

  Future<void> load() async {
    _cancelErrorDisplay();
    _initialFetchCompleted = false;
    _awaitingStreamAfterEmptyLoad = false;
    state = state.copyWith(
      isLoading: true,
      hasResolvedInitialLoad: false,
      clearFailure: true,
    );
    final startTime = DateTime.now();

    final result = await _repository.getNotifications(limit: _pageSize);
    await result.when(
      success: (notifications) async {
        _initialFetchCompleted = true;
        await _ensureMinLoadingDuration(startTime);
        if (notifications.isNotEmpty) {
          _resolveWithNotifications(notifications);
          return;
        }
        // Empty fetch may race the realtime stream; wait for stream before empty UI.
        _awaitingStreamAfterEmptyLoad = true;
        state = state.copyWith(
          isLoading: true,
          hasResolvedInitialLoad: false,
          notifications: notifications,
          hasMore: false,
          clearFailure: true,
        );
      },
      failure: (failure) async {
        _initialFetchCompleted = true;
        await _ensureMinLoadingDuration(startTime);
        _scheduleErrorDisplay(failure);
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
    _errorDebounceTimer?.cancel();
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
