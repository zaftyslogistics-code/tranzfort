import 'package:geolocator/geolocator.dart';

class CapturedLocation {
  final double lat;
  final double lng;

  const CapturedLocation({required this.lat, required this.lng});
}

class LocationService {
  const LocationService();

  Future<CapturedLocation?> captureCurrentLocation() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    );
    final position = await Geolocator.getCurrentPosition(
      locationSettings: settings,
    );

    return CapturedLocation(lat: position.latitude, lng: position.longitude);
  }
}
