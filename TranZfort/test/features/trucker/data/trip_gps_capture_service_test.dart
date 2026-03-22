import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tranzfort/src/features/trucker/data/trip_gps_capture_service.dart';

void main() {
  test('trip gps capture service returns point when permission is granted', () async {
    final service = TripGpsCaptureService(
      isLocationServiceEnabledFn: () async => true,
      checkPermissionFn: () async => LocationPermission.whileInUse,
      requestPermissionFn: () async => LocationPermission.whileInUse,
      getCurrentPositionFn: () async => Position(
        longitude: 79.30,
        latitude: 19.95,
        timestamp: DateTime(2026, 3, 9, 10),
        accuracy: 8,
        altitude: 0,
        altitudeAccuracy: 1,
        heading: 0,
        headingAccuracy: 1,
        speed: 0,
        speedAccuracy: 1,
      ),
    );

    final point = await service.captureBestEffort();

    expect(point, isNotNull);
    expect(point?.latitude, 19.95);
    expect(point?.longitude, 79.30);
  });

  test('trip gps capture service returns null when permission stays denied', () async {
    final service = TripGpsCaptureService(
      isLocationServiceEnabledFn: () async => true,
      checkPermissionFn: () async => LocationPermission.denied,
      requestPermissionFn: () async => LocationPermission.denied,
      getCurrentPositionFn: () async => throw StateError('should not be called'),
    );

    final point = await service.captureBestEffort();

    expect(point, isNull);
  });
}
