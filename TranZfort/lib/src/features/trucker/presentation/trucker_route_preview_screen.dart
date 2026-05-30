import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/services/maps_launcher_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../shell/presentation/shell_components.dart';

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
    final mapsUri = mapsLauncher.buildDirectionsUri(
      originLat: args.originLat,
      originLng: args.originLng,
      destinationLat: args.destinationLat,
      destinationLng: args.destinationLng,
      destinationLabel: args.destinationLabel,
    );

    return DetailPageScaffold(
      title: l10n.truckerLoadDetailRoutePriceSummaryTitle,
      children: [
        Text(
          args.routeLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (mapsUri != null)
          OutlineButton(
            label: l10n.commonOpenInGoogleMapsAction,
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
    );
  }
}
