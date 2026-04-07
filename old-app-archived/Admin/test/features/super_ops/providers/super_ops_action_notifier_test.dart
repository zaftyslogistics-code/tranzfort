import 'package:admin/src/core/repositories/admin_super_ops_repository.dart';
import 'package:admin/src/core/repositories/splitted/super_ops_models.dart';
import 'package:admin/src/features/super_ops/providers/super_ops_detail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminSuperOpsRepository extends Mock
    implements AdminSuperOpsRepository {}

void main() {
  group('SuperOpsActionNotifier', () {
    setUpAll(() {
      registerFallbackValue(
        SuperOpsPostLoadPayload(
          supplierId: 'supplier-1',
          originCity: 'Mumbai',
          originState: 'MH',
          destCity: 'Pune',
          destState: 'MH',
          material: 'Steel',
          weightTonnes: 12,
          requiredTruckType: 'open_body',
          trucksNeeded: 1,
          price: 15000,
          priceType: 'fixed',
          advancePercentage: 20,
          pickupDate: DateTime(2026, 2, 27),
        ),
      );
    });
    test('acceptRequest success returns true', () async {
      final repository = MockAdminSuperOpsRepository();
      when(() => repository.acceptRequest('load-1'))
          .thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          adminSuperOpsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(superOpsActionProvider.notifier);
      final ok = await notifier.acceptRequest('load-1');

      expect(ok, isTrue);
      expect(container.read(superOpsActionProvider), isA<AsyncData<void>>());
    });

    test('forceAssign failure returns false', () async {
      final repository = MockAdminSuperOpsRepository();
      when(
        () => repository.forceAssign(
          loadId: 'load-1',
          truckerId: 'trucker-1',
          truckId: 'truck-1',
        ),
      ).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [
          adminSuperOpsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(superOpsActionProvider.notifier);
      final ok = await notifier.forceAssign(
        loadId: 'load-1',
        truckerId: 'trucker-1',
        truckId: 'truck-1',
      );

      expect(ok, isFalse);
      expect(container.read(superOpsActionProvider), isA<AsyncData<void>>());
    });

    test('confirmPayout success returns true', () async {
      final repository = MockAdminSuperOpsRepository();
      when(() => repository.confirmPayout('load-1'))
          .thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          adminSuperOpsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(superOpsActionProvider.notifier);
      final ok = await notifier.confirmPayout('load-1');

      expect(ok, isTrue);
      expect(container.read(superOpsActionProvider), isA<AsyncData<void>>());
    });

    test('postOnBehalf failure returns false', () async {
      final repository = MockAdminSuperOpsRepository();
      when(() => repository.postLoadOnBehalf(any()))
          .thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [
          adminSuperOpsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(superOpsActionProvider.notifier);
      final ok = await notifier.postOnBehalf(
        SuperOpsPostLoadPayload(
          supplierId: 'supplier-1',
          originCity: 'Mumbai',
          originState: 'MH',
          destCity: 'Pune',
          destState: 'MH',
          material: 'Steel',
          weightTonnes: 12,
          requiredTruckType: 'open_body',
          trucksNeeded: 1,
          price: 15000,
          priceType: 'fixed',
          advancePercentage: 20,
          pickupDate: DateTime(2026, 2, 27),
        ),
      );

      expect(ok, isFalse);
      expect(container.read(superOpsActionProvider), isA<AsyncData<void>>());
    });
  });
}
