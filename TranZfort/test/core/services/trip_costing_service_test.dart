import 'package:flutter_test/flutter_test.dart';

import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/services/trip_costing_service.dart';

void main() {
  group('TripCostingService', () {
    final service = TripCostingService();

    test('returns estimate when distance is available', () {
      final result = service.estimate(
        distanceKm: 600,
        loadWeightTonnes: 20,
        payloadKg: 10000,
        emptyMileageKmpl: 4,
        loadedMileageKmpl: 2.5,
        axleCount: 3,
        dieselPricePerLitre: 92,
      );

      expect(result, isA<Success<TripCostEstimate>>());
      final estimate = (result as Success<TripCostEstimate>).data;
      expect(estimate.totalCost, greaterThan(0));
      expect(estimate.dieselCost, greaterThan(0));
      expect(estimate.tollCost, greaterThan(0));
      expect(estimate.estimatedMileage, inInclusiveRange(2.5, 4.0));
    });

    test('returns validation failure when distance is unavailable', () {
      final result = service.estimate(
        distanceKm: null,
        loadWeightTonnes: 20,
        payloadKg: 10000,
        emptyMileageKmpl: 4,
        loadedMileageKmpl: 2.5,
        axleCount: 2,
      );

      expect(result, isA<Failure<TripCostEstimate>>());
      final failure = result as Failure<TripCostEstimate>;
      expect(failure.debugMessage, contains('Distance unavailable'));
    });

    test('falls back to default diesel and mileage inputs', () {
      final result = service.estimate(
        distanceKm: 120,
        loadWeightTonnes: null,
        payloadKg: null,
        emptyMileageKmpl: null,
        loadedMileageKmpl: null,
        axleCount: 2,
        dieselPricePerLitre: null,
      );

      expect(result, isA<Success<TripCostEstimate>>());
      final estimate = (result as Success<TripCostEstimate>).data;
      expect(estimate.totalCost, greaterThan(0));
      expect(estimate.estimatedMileage, 2.5);
    });
  });
}
