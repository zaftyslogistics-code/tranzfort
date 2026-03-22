import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trip_costing_service.dart';

void main() {
  group('TripCostingService', () {
    const service = TripCostingService();

    test('returns null when distance is unavailable', () {
      final estimate = service.estimate(
        distanceKm: null,
        loadWeightTonnes: 20,
        dieselPricePerLitre: 92.5,
      );

      expect(estimate, isNull);
    });

    test('uses fallback defaults when truck data is unavailable', () {
      final estimate = service.estimate(
        distanceKm: 600,
        loadWeightTonnes: 20,
        dieselPricePerLitre: null,
      );

      expect(estimate, isNotNull);
      expect(estimate?.dieselPricePerLitre, 90);
      expect(estimate?.mileageUsed, 2.5);
      expect(estimate?.tollPlazas, 10);
      expect(estimate?.totalCost, greaterThan(0));
    });

    test('interpolates mileage when truck model data is available', () {
      final estimate = service.estimate(
        distanceKm: 300,
        loadWeightTonnes: 10,
        dieselPricePerLitre: 92,
        mileageEmptyKmpl: 6,
        mileageLoadedKmpl: 3,
        payloadKg: 20000,
        axles: 4,
      );

      expect(estimate, isNotNull);
      expect(estimate!.mileageUsed, closeTo(4.5, 0.001));
      expect(estimate.tollCost, 1400);
      expect(estimate.compactLabel, startsWith('⛽ Est. Cost: ₹'));
    });
  });
}
