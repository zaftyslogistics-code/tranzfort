import 'package:flutter/material.dart';

import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/trip_route_label_parser.dart';
import 'marketplace/marketplace_route_line.dart';

/// Route line for trip detail heroes when structured cities are available.
class TripRouteHeader extends StatelessWidget {
  final String routeLabel;
  final String? originLabel;
  final String? destinationLabel;
  final String? originCity;
  final String? originState;
  final String? destinationCity;
  final String? destinationState;

  const TripRouteHeader({
    super.key,
    required this.routeLabel,
    this.originLabel,
    this.destinationLabel,
    this.originCity,
    this.originState,
    this.destinationCity,
    this.destinationState,
  });

  @override
  Widget build(BuildContext context) {
    final onDark = true;
    final endpoints = _resolveEndpoints();
    if (endpoints == null) {
      return Text(
        routeLabel,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppDecorations.marketplaceCardTextPrimary(onDarkSurface: onDark),
              fontWeight: FontWeight.w700,
            ),
      );
    }

    return MarketplaceRouteLine(
      originCity: endpoints.originCity,
      originState: endpoints.originState,
      destinationCity: endpoints.destinationCity,
      destinationState: endpoints.destinationState,
      onDarkSurface: onDark,
    );
  }

  TripRouteEndpoints? _resolveEndpoints() {
    if ((originCity ?? '').trim().isNotEmpty && (destinationCity ?? '').trim().isNotEmpty) {
      return TripRouteEndpoints(
        originCity: originCity!.trim(),
        originState: (originState ?? '').trim(),
        destinationCity: destinationCity!.trim(),
        destinationState: (destinationState ?? '').trim(),
      );
    }
    final fromLabels = tripRouteFromLabels(
      originLabel: originLabel ?? '',
      destinationLabel: destinationLabel ?? '',
    );
    return fromLabels ?? parseTripRouteLabel(routeLabel);
  }
}
