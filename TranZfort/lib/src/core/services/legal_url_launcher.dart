import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/feedback_components.dart';

Future<void> launchLegalUrl(BuildContext context, AppLocalizations l10n, Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || launched) {
    return;
  }
  AppSnackbar.show(
    context: context,
    message: l10n.settingsLegalLinkFailed,
    variant: AppSnackbarVariant.error,
  );
}
