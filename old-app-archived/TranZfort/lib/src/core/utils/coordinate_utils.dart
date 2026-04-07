import 'package:latlong2/latlong.dart';

class CoordinateUtils {
  const CoordinateUtils._();

  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static ({double lat, double lng})? parseLatLng(
    dynamic latValue,
    dynamic lngValue,
  ) {
    final lat = parseDouble(latValue);
    final lng = parseDouble(lngValue);
    if (lat == null || lng == null) return null;
    return (lat: lat, lng: lng);
  }

  static ({double lat, double lng})? parseLatLngFromMap(
    Map<String, dynamic> source, {
    required String latKey,
    required String lngKey,
  }) {
    return parseLatLng(source[latKey], source[lngKey]);
  }

  static LatLng? toLatLng(
    dynamic latValue,
    dynamic lngValue,
  ) {
    final parsed = parseLatLng(latValue, lngValue);
    if (parsed == null) return null;
    return LatLng(parsed.lat, parsed.lng);
  }

  static LatLng? toLatLngFromMap(
    Map<String, dynamic> source, {
    required String latKey,
    required String lngKey,
  }) {
    final parsed = parseLatLngFromMap(source, latKey: latKey, lngKey: lngKey);
    if (parsed == null) return null;
    return LatLng(parsed.lat, parsed.lng);
  }
}
