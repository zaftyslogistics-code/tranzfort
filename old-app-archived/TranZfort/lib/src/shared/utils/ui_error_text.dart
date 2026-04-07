import 'package:flutter/widgets.dart';

import '../../core/error/app_failure.dart';
import '../../l10n/app_localizations.dart';

String uiSafeErrorText(
  BuildContext context,
  Object error, {
  String? fallback,
}) {
  final l10n = AppLocalizations.of(context);
  final failure = classifyError(error);

  return switch (failure) {
    AppFailureType.network => l10n.authErrorNetwork,
    AppFailureType.auth => l10n.authErrorAuthFailed,
    AppFailureType.validation => l10n.authErrorValidation,
    AppFailureType.conflict => l10n.authErrorConflict,
    AppFailureType.forbidden ||
    AppFailureType.notFound ||
    AppFailureType.serverError ||
    AppFailureType.unknown => fallback ?? l10n.authErrorGeneric,
  };
}
