import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostLoadState', () {
    test('copyWith updates route and load fields', () {
      final initial = PostLoadState();
      final updated = initial.copyWith(
        originCity: 'Mumbai',
        destinationCity: 'Pune',
        material: 'Steel',
        weightTonnes: 18,
        price: 50000,
        requiredTruckType: 'open',
        requiredTyres: const [10],
        trucksNeeded: 2,
        distanceKm: 145,
        durationHours: 3,
        tollEstimate: 1200,
      );

      expect(updated.originCity, 'Mumbai');
      expect(updated.destinationCity, 'Pune');
      expect(updated.material, 'Steel');
      expect(updated.weightTonnes, 18);
      expect(updated.price, 50000);
      expect(updated.requiredTruckType, 'open');
      expect(updated.requiredTyres, const [10]);
      expect(updated.trucksNeeded, 2);
      expect(updated.distanceKm, 145);
      expect(updated.durationHours, 3);
      expect(updated.tollEstimate, 1200);
    });

    test('copyWith can reset error by passing null', () {
      final initial = PostLoadState();

      final withError = initial.copyWith(error: 'network');
      expect(withError.error, 'network');

      final updated = withError.copyWith(
        material: 'Steel',
        weightTonnes: 24,
        requiredTyres: const [10, 12],
        advancePercentage: 70,
      );

      expect(updated.material, 'Steel');
      expect(updated.weightTonnes, 24);
      expect(updated.requiredTyres, const [10, 12]);
      expect(updated.advancePercentage, 70);
      expect(updated.error, isNull);

      final restored = updated.copyWith(error: 'validation');
      expect(restored.error, 'validation');
    });
  });
}
