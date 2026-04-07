import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/services/maps_launcher_service.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  test('buildDirectionsUri returns null when origin coordinates are missing', () {
    final service = MapsLauncherService();

    final uri = service.buildDirectionsUri(
      originLat: null,
      originLng: 72.8777,
      destinationLat: 18.5204,
      destinationLng: 73.8567,
      destinationLabel: 'Pune',
    );

    expect(
      uri.toString(),
      'https://www.google.com/maps/search/?api=1&query=18.5204%2C73.8567',
    );
  });

  test('buildDirectionsUri uses destination coordinates when available', () {
    final service = MapsLauncherService();

    final uri = service.buildDirectionsUri(
      originLat: 19.076,
      originLng: 72.8777,
      destinationLat: 18.5204,
      destinationLng: 73.8567,
      destinationLabel: 'Pune',
    );

    expect(
      uri.toString(),
      'https://www.google.com/maps/dir/?api=1&origin=19.076,72.8777&destination=18.5204%2C73.8567',
    );
  });

  test('buildDirectionsUri falls back to destination label when destination coordinates are unavailable', () {
    final service = MapsLauncherService();

    final uri = service.buildDirectionsUri(
      originLat: 19.076,
      originLng: 72.8777,
      destinationLat: null,
      destinationLng: null,
      destinationLabel: 'Pune Station',
    );

    expect(
      uri.toString(),
      'https://www.google.com/maps/dir/?api=1&origin=19.076,72.8777&destination=Pune%20Station',
    );
  });

  test('launchDirectionsUri falls back to platform default when external launch returns false', () async {
    final launches = <LaunchMode>[];
    final service = MapsLauncherService(
      launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async {
        launches.add(mode);
        return mode == LaunchMode.platformDefault;
      },
    );

    final launched = await service.launchDirectionsUri(Uri.parse('https://example.test/maps'));

    expect(launched, isTrue);
    expect(launches, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
  });

  test('launchDirectionsUri returns false when both launch attempts fail', () async {
    final service = MapsLauncherService(
      launchUrlFn: (uri, {mode = LaunchMode.platformDefault}) async => false,
    );

    final launched = await service.launchDirectionsUri(Uri.parse('https://example.test/maps'));

    expect(launched, isFalse);
  });
}
