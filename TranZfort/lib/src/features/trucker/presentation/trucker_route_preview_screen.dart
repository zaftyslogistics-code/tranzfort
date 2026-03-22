import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/services/maps_launcher_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';

class TruckerRoutePreviewArgs {
  final String routeLabel;
  final String destinationLabel;
  final double originLat;
  final double originLng;
  final double destinationLat;
  final double destinationLng;

  const TruckerRoutePreviewArgs({
    required this.routeLabel,
    required this.destinationLabel,
    required this.originLat,
    required this.originLng,
    required this.destinationLat,
    required this.destinationLng,
  });
}

class TruckerRoutePreviewScreen extends StatelessWidget {
  final TruckerRoutePreviewArgs args;
  final MapsLauncherService mapsLauncher;

  const TruckerRoutePreviewScreen({
    super.key,
    required this.args,
    required this.mapsLauncher,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final origin = LatLng(args.originLat, args.originLng);
    final destination = LatLng(args.destinationLat, args.destinationLng);
    final bounds = LatLngBounds.fromPoints(<LatLng>[origin, destination]);
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: args.originLat,
      originLng: args.originLng,
      destinationLat: args.destinationLat,
      destinationLng: args.destinationLng,
      destinationLabel: args.destinationLabel,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.truckerLoadDetailRoutePriceSummaryTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                args.routeLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(AppSpacing.lg),
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
                            points: <LatLng>[origin, destination],
                            strokeWidth: 4,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: origin,
                            width: 28,
                            height: 28,
                            child: const Icon(Icons.location_on, color: AppColors.success, size: 26),
                          ),
                          Marker(
                            point: destination,
                            width: 28,
                            height: 28,
                            child: const Icon(Icons.location_on, color: AppColors.error, size: 26),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (mapsUri != null)
                PrimaryButton(
                  label: l10n.truckerLoadDetailOpenInGoogleMapsAction,
                  onPressed: () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri);
                  },
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlineButton(
                label: l10n.truckerTripsTitle,
                onPressed: () => context.go(AppRoutes.tripsPath),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
