import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/result.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../auth/providers/auth_providers.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(supabaseClientProvider));
});

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) return const [];

  final result = await ref.watch(notificationRepositoryProvider).getNotifications(user.id);
  return switch (result) {
    Success(data: final data) => data,
    Failure() => const <Map<String, dynamic>>[],
  };
});

class NotificationActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationActionNotifier(this._ref) : super(const AsyncData(null));

  Future<void> markRead(String notificationId) async {
    state = const AsyncLoading();
    final result = await _ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(notificationsProvider);
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to mark read', StackTrace.current);
    }
  }

  Future<void> markAllRead() async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await _ref.read(notificationRepositoryProvider).markAllAsRead(user.id);

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(notificationsProvider);
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to mark all read', StackTrace.current);
    }
  }
}

final notificationActionProvider = StateNotifierProvider<NotificationActionNotifier, AsyncValue<void>>((ref) {
  return NotificationActionNotifier(ref);
});
