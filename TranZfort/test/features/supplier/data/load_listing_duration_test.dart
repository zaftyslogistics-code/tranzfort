import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/supplier/data/load_listing_duration.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';

void main() {
  test('LoadListingDuration maps to RPC enum values', () {
    expect(LoadListingDuration.hours48.rpcValue, '48_hours');
    expect(LoadListingDuration.days7.rpcValue, '7_days');
    expect(LoadListingDuration.days30.rpcValue, '30_days');
  });

  test('CreateLoadDto includes listing duration in RPC params', () {
    final dto = CreateLoadDto(
      originLabel: 'Warehouse',
      originCity: 'Mumbai',
      originState: null,
      originLat: null,
      originLng: null,
      destinationLabel: 'Port',
      destinationCity: 'Chennai',
      destinationState: null,
      destinationLat: null,
      destinationLng: null,
      routeDistanceKm: null,
      routeDurationMinutes: null,
      routePolyline: null,
      routeSnapshotSource: null,
      material: 'steel',
      materialCode: 'steel',
      weightTonnes: 10,
      requiredBodyType: null,
      requiredTyres: null,
      trucksNeeded: 2,
      priceAmount: 5000,
      priceType: 'per_ton',
      advancePercentage: 50,
      pickupDate: DateTime(2026, 6, 15),
      listingDuration: LoadListingDuration.days30,
    );

    expect(dto.toRpcParams()['p_listing_duration'], '30_days');
  });
}
