import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class TripGpsPoint {
  final double latitude;
  final double longitude;

  const TripGpsPoint({
    required this.latitude,
    required this.longitude,
  });
}

class TripGpsCaptureService {
  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _getCurrentPosition;

  TripGpsCaptureService({
    Future<bool> Function()? isLocationServiceEnabledFn,
    Future<LocationPermission> Function()? checkPermissionFn,
    Future<LocationPermission> Function()? requestPermissionFn,
    Future<Position> Function()? getCurrentPositionFn,
  })  : _isLocationServiceEnabled = isLocationServiceEnabledFn ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermissionFn ?? Geolocator.checkPermission,
        _requestPermission = requestPermissionFn ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPositionFn ?? _defaultGetCurrentPosition;

  Future<TripGpsPoint?> captureBestEffort() async {
    try {
      final servicesEnabled = await _isLocationServiceEnabled();
      if (!servicesEnabled) {
        return null;
      }

      var permission = await _checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await _getCurrentPosition();
      return TripGpsPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<Position> _defaultGetCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }
}

final tripGpsCaptureServiceProvider = Provider<TripGpsCaptureService>((ref) {
  return TripGpsCaptureService();
});
