import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/route_preview_provider.dart';

class RoutePreviewScreen extends ConsumerWidget {
  final String loadId;

  const RoutePreviewScreen({super.key, required this.loadId});

  Future<void> _openGoogleMaps(BuildContext context, double lat, double lng) async {
    final url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeAsync = ref.watch(routePreviewProvider(loadId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Preview'),
      ),
      body: routeAsync.when(
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Route details not available.'));
          }

          // Calculate a bounding box for the map to fit both points
          final bounds = LatLngBounds.fromPoints([data.origin, data.destination]);

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(50),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tranzfort.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: data.polyline,
                        strokeWidth: 4.0,
                        color: data.isFallback ? Colors.grey : AppColors.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: data.origin,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
                      ),
                      Marker(
                        point: data.destination,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
              if (data.isFallback)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAmber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Showing direct line. Real route calculation failed.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _openGoogleMaps(
                    context, 
                    data.destination.latitude, 
                    data.destination.longitude,
                  ),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start Navigation in Google Maps'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading route: $e')),
      ),
    );
  }
}
