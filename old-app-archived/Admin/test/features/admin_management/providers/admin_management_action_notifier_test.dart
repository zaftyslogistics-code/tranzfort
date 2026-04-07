import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:admin/src/core/repositories/admin_management_repository.dart';
import 'package:admin/src/features/admin_management/providers/admin_management_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminManagementRepository extends Mock
    implements AdminManagementRepository {}

void main() {
  group('AdminManagementActionNotifier', () {
    test('inviteAdmin success returns ok result', () async {
      final repository = MockAdminManagementRepository();
      when(
        () => repository.inviteAdmin(
          fullName: 'Test Admin',
          email: 'test@example.com',
          role: AdminRole.supportAgent,
        ),
      ).thenAnswer(
        (_) async => const AdminInviteResult(ok: true, message: 'ok'),
      );

      final container = ProviderContainer(
        overrides: [
          adminManagementRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adminManagementActionProvider.notifier);
      final ok = await notifier.inviteAdmin(
        fullName: 'Test Admin',
        email: 'test@example.com',
        role: AdminRole.supportAgent,
      );

      expect(ok.ok, isTrue);
      expect(container.read(adminManagementActionProvider), isA<AsyncData<void>>());
    });

    test('setAdminActive failure returns failed result', () async {
      final repository = MockAdminManagementRepository();
      when(() => repository.setAdminActive(adminId: 'admin-1', isActive: false))
          .thenAnswer((_) async => const AdminActionResult(ok: false, message: 'nope'));

      final container = ProviderContainer(
        overrides: [
          adminManagementRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(adminManagementActionProvider.notifier);
      final ok = await notifier.setAdminActive(
        adminId: 'admin-1',
        isActive: false,
      );

      expect(ok.ok, isFalse);
      expect(container.read(adminManagementActionProvider), isA<AsyncData<void>>());
    });
  });
}
