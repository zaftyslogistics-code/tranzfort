import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/services/route_snapshot_service.dart';

void main() {
  test('fromStoredFields preserves stored route snapshot values', () {
    final snapshot = RouteSnapshot.fromStoredFields(
      distanceKm: 820,
      durationMinutes: 840,
      source: 'osrm',
      polyline: 'encoded',
    );

    expect(snapshot.distanceKm, 820);
    expect(snapshot.durationMinutes, 840);
    expect(snapshot.source, 'osrm');
    expect(snapshot.polyline, 'encoded');
  });

  test('fromStoredFields normalizes missing stored route snapshot values safely', () {
    final snapshot = RouteSnapshot.fromStoredFields(
      distanceKm: null,
      durationMinutes: null,
      source: null,
      polyline: null,
    );

    expect(snapshot.distanceKm, 0);
    expect(snapshot.durationMinutes, 0);
    expect(snapshot.source, '');
    expect(snapshot.polyline, isNull);
  });
}
