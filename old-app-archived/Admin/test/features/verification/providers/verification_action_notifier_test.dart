import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:admin/src/features/verification/providers/verification_detail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminVerificationRepository extends Mock
    implements AdminVerificationRepository {}

void main() {
  group('VerificationActionNotifier', () {
    test('approve returns true and resets state', () async {
      final repository = MockAdminVerificationRepository();
      when(
        () => repository.approve(
          type: VerificationEntityType.supplier,
          id: 'supplier-1',
        ),
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          adminVerificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(verificationActionProvider.notifier);
      final ok = await notifier.approve(
        type: VerificationEntityType.supplier,
        id: 'supplier-1',
      );

      expect(ok, isTrue);
      expect(container.read(verificationActionProvider), isA<AsyncData<void>>());
      verify(
        () => repository.approve(
          type: VerificationEntityType.supplier,
          id: 'supplier-1',
        ),
      ).called(1);
    });

    test('reject returns false on repository failure', () async {
      final repository = MockAdminVerificationRepository();
      when(
        () => repository.reject(
          type: VerificationEntityType.trucker,
          id: 'trucker-1',
          reason: 'docs missing',
        ),
      ).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [
          adminVerificationRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(verificationActionProvider.notifier);
      final ok = await notifier.reject(
        type: VerificationEntityType.trucker,
        id: 'trucker-1',
        reason: 'docs missing',
      );

      expect(ok, isFalse);
      expect(container.read(verificationActionProvider), isA<AsyncData<void>>());
    });
  });
}
