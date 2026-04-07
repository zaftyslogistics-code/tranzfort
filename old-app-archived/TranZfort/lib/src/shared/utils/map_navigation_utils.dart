import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

Future<void> openGoogleMapsRoute({
  required BuildContext context,
  required double originLat,
  required double originLng,
  required double destLat,
  required double destLng,
}) async {
  final l10n = AppLocalizations.of(context);
  final navUri = Uri.parse(
    'google.navigation:q=$destLat,$destLng&mode=d',
  );
  if (await canLaunchUrl(navUri)) {
    await launchUrl(navUri, mode: LaunchMode.externalApplication);
    return;
  }

  final webUri = Uri.parse(
    'https://www.google.com/maps/dir/$originLat,$originLng/$destLat,$destLng',
  );
  if (await canLaunchUrl(webUri)) {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.routePreviewOpenMapsFailed)));
  }
}

Future<void> openGoogleMapsNavigation({
  required BuildContext context,
  required double lat,
  required double lng,
}) async {
  final l10n = AppLocalizations.of(context);
  final navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
  if (await canLaunchUrl(navUri)) {
    await launchUrl(navUri);
    return;
  }

  final webUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );
  if (await canLaunchUrl(webUri)) {
    await launchUrl(webUri);
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.routePreviewOpenMapsFailed)));
  }
}
