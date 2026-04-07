import 'package:admin/src/core/repositories/admin_user_management_repository.dart';
import 'package:admin/src/features/users/providers/user_detail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminUserManagementRepository extends Mock
    implements AdminUserManagementRepository {}

void main() {
  group('UserActionNotifier', () {
    test('setBanStatus success returns true and resets state', () async {
      final repository = MockAdminUserManagementRepository();
      when(
        () => repository.setBanStatus(
          userId: 'user-1',
          banned: true,
          reason: 'policy',
        ),
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          adminUserManagementRepositoryProvider
              .overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userActionProvider.notifier);
      final ok = await notifier.setBanStatus(
        userId: 'user-1',
        banned: true,
        reason: 'policy',
      );

      expect(ok, isTrue);
      expect(container.read(userActionProvider), isA<AsyncData<void>>());
      verify(
        () => repository.setBanStatus(
          userId: 'user-1',
          banned: true,
          reason: 'policy',
        ),
      ).called(1);
    });

    test('setBanStatus failure returns false', () async {
      final repository = MockAdminUserManagementRepository();
      when(
        () => repository.setBanStatus(
          userId: 'user-1',
          banned: false,
          reason: null,
        ),
      ).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [
          adminUserManagementRepositoryProvider
              .overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(userActionProvider.notifier);
      final ok = await notifier.setBanStatus(
        userId: 'user-1',
        banned: false,
      );

      expect(ok, isFalse);
      expect(container.read(userActionProvider), isA<AsyncData<void>>());
    });
  });
}
