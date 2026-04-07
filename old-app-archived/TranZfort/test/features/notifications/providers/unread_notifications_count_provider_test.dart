import 'package:app/src/features/notifications/providers/notifications_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unreadNotificationsCountProvider', () {
    test('counts only notifications where is_read is not true', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith((ref) async => [
                {'id': 'n1', 'is_read': false},
                {'id': 'n2', 'is_read': true},
                {'id': 'n3'},
              ]),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(unreadNotificationsCountProvider.future);
      expect(count, 2);
    });

    test('returns zero when notification list is empty', () async {
      final container = ProviderContainer(
        overrides: [
          notificationsProvider.overrideWith((ref) async => const []),
        ],
      );
      addTearDown(container.dispose);

      final count = await container.read(unreadNotificationsCountProvider.future);
      expect(count, 0);
    });
  });
}
