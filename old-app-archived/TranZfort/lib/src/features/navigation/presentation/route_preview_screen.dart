import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/utils/map_navigation_utils.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../providers/route_preview_provider.dart';

class RoutePreviewScreen extends ConsumerWidget {
  final String loadId;

  const RoutePreviewScreen({super.key, required this.loadId});

  Future<void> _openGoogleMaps(
    BuildContext context,
    double lat,
    double lng,
  ) async {
    await openGoogleMapsNavigation(context: context, lat: lat, lng: lng);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final routeAsync = ref.watch(routePreviewProvider(loadId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routePreviewTitle)),
      body: routeAsync.when(
        data: (data) {
          if (data == null) {
            return Center(child: Text(l10n.routePreviewDetailsUnavailable));
          }

          // Calculate a bounding box for the map to fit both points
          final bounds = LatLngBounds.fromPoints([
            data.origin,
            data.destination,
          ]);

          return Stack(
            children: [
              TtsAnnounce(
                text: l10n.routePreviewScreenTtsContext(
                  '${data.origin.latitude.toStringAsFixed(4)}, ${data.origin.longitude.toStringAsFixed(4)}',
                  '${data.destination.latitude.toStringAsFixed(4)}, ${data.destination.longitude.toStringAsFixed(4)}',
                ),
              ),
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(
                      AppSpacing.mapViewportPadding,
                    ),
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tranzfort.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: data.polyline,
                        strokeWidth: 4.0,
                        color: data.isFallback
                            ? Colors.grey
                            : AppColors.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: data.origin,
                        width: AppSpacing.mapMarkerSize,
                        height: AppSpacing.mapMarkerSize,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: AppSpacing.mapMarkerSize,
                        ),
                      ),
                      Marker(
                        point: data.destination,
                        width: AppSpacing.mapMarkerSize,
                        height: AppSpacing.mapMarkerSize,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: AppSpacing.mapMarkerSize,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (data.isFallback)
                Positioned(
                  top: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryAmber.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                    ),
                    child: Text(
                      l10n.routePreviewFallbackWarning,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Positioned(
                bottom: AppSpacing.floatingCtaInset + 64,
                left: AppSpacing.floatingCtaInset,
                right: AppSpacing.floatingCtaInset,
                child: _RouteInfoOverlay(data: data),
              ),
              Positioned(
                bottom: AppSpacing.floatingCtaInset,
                left: AppSpacing.floatingCtaInset,
                right: AppSpacing.floatingCtaInset,
                child: PrimaryButton(
                  label: l10n.routePreviewStartNavigation,
                  onPressed: () => _openGoogleMaps(
                    context,
                    data.destination.latitude,
                    data.destination.longitude,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => SkeletonLoader.list(
          count: 2,
          itemHeight: 140,
        ),
        error: (e, _) => Center(
          child: Text(
            uiSafeErrorText(context, e, fallback: l10n.routePreviewLoadError),
          ),
        ),
      ),
    );
  }
}

class _RouteInfoOverlay extends StatelessWidget {
  final RoutePreviewData data;

  const _RouteInfoOverlay({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final distanceKm = data.distanceMeters == null
        ? null
        : data.distanceMeters!.toDouble() / 1000;
    final durationMinutes = data.durationSeconds == null
        ? null
        : (data.durationSeconds! / 60).round();

    if (distanceKm == null || durationMinutes == null) {
      return const SizedBox.shrink();
    }

    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    final durationLabel = hours > 0 ? '~${hours}h ${mins}m' : '~${mins}m';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Text(
        '📍 ${distanceKm.toStringAsFixed(0)} km · ⏱ $durationLabel${data.tollEstimate == null ? '' : ' · ${l10n.loadDetailTripCostTolls}: ₹${data.tollEstimate!.toStringAsFixed(0)}'}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
