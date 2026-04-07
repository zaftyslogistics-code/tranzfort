import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/notification_repository.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/notifications/providers/notifications_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'token',
    'token_type': 'bearer',
    'user': {'id': 'user-1', 'email': 'user@example.com'},
  });
  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  group('NotificationActionNotifier', () {
    test('markRead sets AsyncData on success', () async {
      final repository = MockNotificationRepository();
      when(() => repository.markAsRead('notification-1'))
          .thenAnswer((_) async => const Success(null));

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationActionProvider.notifier);
      await notifier.markRead('notification-1');

      expect(container.read(notificationActionProvider), isA<AsyncData<void>>());
      verify(() => repository.markAsRead('notification-1')).called(1);
    });

    test('markRead sets AsyncError on failure', () async {
      final repository = MockNotificationRepository();
      when(() => repository.markAsRead('notification-1'))
          .thenAnswer((_) async => Failure(AppFailureType.network));

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationActionProvider.notifier);
      await notifier.markRead('notification-1');

      expect(container.read(notificationActionProvider), isA<AsyncError<void>>());
    });

    test('markAllRead uses authenticated user', () async {
      final repository = MockNotificationRepository();
      when(() => repository.markAllAsRead('user-1'))
          .thenAnswer((_) async => const Success(null));

      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(notificationActionProvider.notifier);
      await notifier.markAllRead();

      expect(container.read(notificationActionProvider), isA<AsyncData<void>>());
      verify(() => repository.markAllAsRead('user-1')).called(1);
    });
  });
}
