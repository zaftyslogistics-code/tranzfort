import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../utils/load_pricing.dart';

class FindLoadsMapView extends StatelessWidget {
  final List<Map<String, dynamic>> loads;

  const FindLoadsMapView({super.key, required this.loads});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final markers = <Marker>[];
    final points = <LatLng>[];

    for (final load in loads) {
      final parsed = CoordinateUtils.parseLatLngFromMap(
        load,
        latKey: 'origin_lat',
        lngKey: 'origin_lng',
      );
      if (parsed == null) {
        continue;
      }
      final point = LatLng(parsed.lat, parsed.lng);
      points.add(point);
      markers.add(
        Marker(
          point: point,
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () async {
              await showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) {
                  final origin = (load['origin_city'] ?? '-').toString();
                  final destination = (load['dest_city'] ?? '-').toString();
                  final material =
                      (load['material'] ?? l10n.findLoadsAnyMaterial)
                          .toString();
                  final price = _priceSummary(load);
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$origin → $destination',
                            style: Theme.of(sheetContext).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMuted,
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.xs,
                                  ),
                                ),
                                child: Text(
                                  material,
                                  style: Theme.of(sheetContext)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              if (price != '₹-')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(
                                      AppSpacing.xs,
                                    ),
                                  ),
                                  child: Text(
                                    price,
                                    style: Theme.of(sheetContext)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                context.push('/load-detail/${load['id']}');
                              },
                              child: Text(l10n.loadDetailTitle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(20.5937, 78.9629),
        initialZoom: 5,
        minZoom: 3,
        maxZoom: 18,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tranzfort.app',
        ),
        if (points.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points,
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  String _priceSummary(Map<String, dynamic> load) {
    final price = LoadPricing.priceValue(load['price']);
    if (price == null) {
      return '₹-';
    }
    final formatted = price.truncateToDouble() == price
        ? '₹${price.toStringAsFixed(0)}'
        : '₹${price.toStringAsFixed(1)}';
    if (LoadPricing.isPerTon(load['price_type'])) {
      return '$formatted/T';
    }
    return formatted;
  }
}
