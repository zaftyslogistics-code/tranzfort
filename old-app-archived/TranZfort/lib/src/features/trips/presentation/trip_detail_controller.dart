import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../shared/utils/map_navigation_utils.dart';

class TripDetailController {
  final WidgetRef ref;
  final BuildContext context;

  TripDetailController({
    required this.ref,
    required this.context,
  });

  Future<void> openNavigation(Map<String, dynamic> load) async {
    final l10n = AppLocalizations.of(context);
    final destination = CoordinateUtils.parseLatLngFromMap(
      load,
      latKey: 'dest_lat',
      lngKey: 'dest_lng',
    );
    if (destination == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tripNavigationUnavailable)),
        );
      }
      return;
    }

    await openGoogleMapsNavigation(
      context: context,
      lat: destination.lat,
      lng: destination.lng,
    );
  }

  Future<void> triggerSos(String tripId) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.tripEmergencySosAction),
            ],
          ),
          content: Text(l10n.tripEmergencySosPreparing),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.tripCancelAction),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.tripConfirmAction),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final sosUrl = Uri.parse('tel:112');
    if (await canLaunchUrl(sosUrl)) {
      await launchUrl(sosUrl);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tripEmergencySosLaunchFailed)),
        );
      }
    }
  }

  Future<void> pickAndShowImage({
    required ImageSource source,
    required String title,
  }) async {
    final file = await ImagePickerUtil.pickAndCompressImage(
      context: context,
      source: source,
      quality: 85,
    );
    
    if (file == null) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final materialL10n = MaterialLocalizations.of(context);
        return AlertDialog(
          title: Text(title),
          content: Image.file(file),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(materialL10n.closeButtonLabel),
            ),
          ],
        );
      },
    );
  }
}
