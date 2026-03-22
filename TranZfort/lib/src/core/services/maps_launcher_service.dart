import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef MapsLaunchUrlFn = Future<bool> Function(Uri uri, {LaunchMode mode});

class MapsLauncherService {
  final MapsLaunchUrlFn _launchUrl;

  MapsLauncherService({MapsLaunchUrlFn? launchUrlFn})
      : _launchUrl = launchUrlFn ?? ((uri, {mode = LaunchMode.platformDefault}) => launchUrl(uri, mode: mode));

  Uri? buildDirectionsUri({
    required double? originLat,
    required double? originLng,
    required double? destinationLat,
    required double? destinationLng,
    required String destinationLabel,
  }) {
    final destination = destinationLat != null && destinationLng != null
        ? '$destinationLat,$destinationLng'
        : destinationLabel.trim();
    if (destination.isEmpty) {
      return null;
    }
    if (originLat == null || originLng == null) {
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(destination)}',
      );
    }
    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=${Uri.encodeComponent(destination)}',
    );
  }

  Future<bool> launchDirectionsUri(Uri uri) async {
    try {
      final launchedExternally = await _launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launchedExternally) {
        return true;
      }
    } catch (_) {}

    try {
      return await _launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      return false;
    }
  }
}

final mapsLauncherServiceProvider = Provider<MapsLauncherService>((ref) {
  return MapsLauncherService();
});
