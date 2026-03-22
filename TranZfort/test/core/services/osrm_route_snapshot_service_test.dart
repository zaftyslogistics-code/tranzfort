import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/services/osrm_route_snapshot_service.dart';

void main() {
  test('returns null when coordinates are incomplete', () async {
    final service = OsrmRouteSnapshotService();

    final snapshot = await service.fetchDrivingRouteSnapshot(
      originLat: 19.95,
      originLng: null,
      destinationLat: 19.07,
      destinationLng: 72.87,
    );

    expect(snapshot, isNull);
  });

  test('parses route distance and duration from OSRM payload', () async {
    Uri? capturedUri;
    final service = OsrmRouteSnapshotService(
      getJsonFn: (uri) async {
        capturedUri = uri;
        return <String, dynamic>{
          'routes': [
            <String, dynamic>{
              'distance': 820000,
              'duration': 46800,
            },
          ],
        };
      },
    );

    final snapshot = await service.fetchDrivingRouteSnapshot(
      originLat: 19.95,
      originLng: 79.30,
      destinationLat: 19.07,
      destinationLng: 72.87,
    );

    expect(capturedUri.toString(), 'http://router.project-osrm.org/route/v1/driving/79.3,19.95;72.87,19.07?overview=false');
    expect(snapshot?.distanceKm, 820);
    expect(snapshot?.durationMinutes, 780);
    expect(snapshot?.source, 'osrm');
  });

  test('returns null when OSRM payload lacks route metrics', () async {
    final service = OsrmRouteSnapshotService(
      getJsonFn: (_) async => <String, dynamic>{
        'routes': [
          <String, dynamic>{'distance': null, 'duration': 60},
        ],
      },
    );

    final snapshot = await service.fetchDrivingRouteSnapshot(
      originLat: 19.95,
      originLng: 79.30,
      destinationLat: 19.07,
      destinationLng: 72.87,
    );

    expect(snapshot, isNull);
  });
}
