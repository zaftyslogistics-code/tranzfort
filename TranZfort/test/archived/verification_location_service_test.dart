import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tranzfort/src/features/verification/data/verification_location_service.dart';

class _TestAssetBundle extends CachingAssetBundle {
  final String jsonString;

  _TestAssetBundle(this.jsonString);

  @override
  Future<ByteData> load(String key) async {
    final encoded = jsonString.codeUnits;
    return ByteData.sublistView(Uint8List.fromList(encoded));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return jsonString;
  }
}

void main() {
  test('verification location service returns null when location services are disabled', () async {
    final service = VerificationLocationService(
      assetBundle: _TestAssetBundle('[]'),
      isLocationServiceEnabledFn: () async => false,
      checkPermissionFn: () async => LocationPermission.whileInUse,
      requestPermissionFn: () async => LocationPermission.whileInUse,
      getCurrentPositionFn: () async => throw StateError('unused'),
    );

    final result = await service.captureSupplierVerificationLocation();

    expect(result, isNull);
  });

  test('verification location service resolves nearest offline city when google geocode is unavailable', () async {
    final service = VerificationLocationService(
      assetBundle: _TestAssetBundle(
        '[{"name":"Mumbai","state":"Maharashtra","lat":19.0760,"lng":72.8777},{"name":"Nagpur","state":"Maharashtra","lat":21.1458,"lng":79.0882}]',
      ),
      isLocationServiceEnabledFn: () async => true,
      checkPermissionFn: () async => LocationPermission.whileInUse,
      requestPermissionFn: () async => LocationPermission.whileInUse,
      getCurrentPositionFn: () async => Position(
        longitude: 72.878,
        latitude: 19.0762,
        timestamp: DateTime(2026, 3, 10),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );

    final result = await service.captureSupplierVerificationLocation();

    expect(result, isNotNull);
    expect(result?.city, 'Mumbai');
    expect(result?.state, 'Maharashtra');
    expect(result?.source, 'offline_nearest_city');
  });
}
