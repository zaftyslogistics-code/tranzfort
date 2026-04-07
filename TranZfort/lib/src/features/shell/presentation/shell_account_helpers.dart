import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../notifications/data/push_runtime_service.dart';

String localizedTrustSafetyStatus(AppLocalizations l10n, String value) {
  switch (value.trim().toLowerCase()) {
    case 'warned':
      return l10n.supportTrustStatusWarned;
    case 'restricted':
      return l10n.supportTrustStatusRestricted;
    case 'suspended':
      return l10n.supportTrustStatusSuspended;
    case 'banned':
      return l10n.supportTrustStatusBanned;
    case 'normal':
    case '':
      return l10n.supportTrustStatusNormal;
    default:
      return l10n.supportTrustStatusUnknown;
  }
}

String localizedAccountState(AppLocalizations l10n, String value) {
  switch (value.trim().toLowerCase()) {
    case 'deactivated_pending_cleanup':
      return l10n.accountStateDeactivatedPendingCleanup;
    case 'restricted':
      return l10n.accountStateRestricted;
    case 'active':
    case '':
      return l10n.accountStateActive;
    default:
      return l10n.accountStateUnknown;
  }
}

String localizedRoleTypeLabel(AppLocalizations l10n, String? roleType) {
  switch ((roleType ?? '').trim().toLowerCase()) {
    case 'supplier':
      return l10n.accountRoleSupplier;
    case 'trucker':
      return l10n.accountRoleTrucker;
    case 'unknown':
      return l10n.accountRoleUnknown;
    default:
      return (roleType ?? '').trim();
  }
}

String pushStatusLabel(PushPermissionStatus status, AppLocalizations l10n) {
  return switch (status) {
    PushPermissionStatus.authorized => l10n.settingsPushStatusAllowed,
    PushPermissionStatus.provisional => l10n.settingsPushStatusAllowedQuietly,
    PushPermissionStatus.denied => l10n.settingsPushStatusBlocked,
    PushPermissionStatus.notDetermined => l10n.settingsPushStatusNotRequested,
    PushPermissionStatus.unavailable => l10n.settingsPushStatusUnavailable,
  };
}

String pushStatusGuidance(PushPermissionStatus status, AppLocalizations l10n) {
  return switch (status) {
    PushPermissionStatus.authorized => l10n.settingsPushGuidanceAllowed,
    PushPermissionStatus.provisional => l10n.settingsPushGuidanceAllowedQuietly,
    PushPermissionStatus.denied => l10n.settingsPushGuidanceBlocked,
    PushPermissionStatus.notDetermined => l10n.settingsPushGuidanceNotRequested,
    PushPermissionStatus.unavailable => l10n.settingsPushGuidanceUnavailable,
  };
}

String pushRuntimeIssuesMessage(AppLocalizations l10n, Set<PushRuntimeIssue> issues) {
  final segments = <String>[];
  if (issues.contains(PushRuntimeIssue.permissionRequestFailed)) {
    segments.add(l10n.pushIssuePermissionRequestFailed);
  }
  if (issues.contains(PushRuntimeIssue.localNotificationsInitFailed)) {
    segments.add(l10n.pushIssueLocalInitFailed);
  }
  if (issues.contains(PushRuntimeIssue.localNotificationDisplayFailed)) {
    segments.add(l10n.pushIssueDisplayFailed);
  }
  if (issues.contains(PushRuntimeIssue.tokenSyncFailed)) {
    segments.add(l10n.pushIssueTokenSyncFailed);
  }
  return segments.join(' ');
}

String settingsTtsSummary({
  required BuildContext context,
  required String languageCode,
  required String selectedLanguageCode,
  required String? roleType,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final selectedLanguageLabel = selectedLanguageCode == 'hi'
      ? l10n.settingsLanguageHindi
      : l10n.settingsLanguageEnglish;
  final normalizedRoleType = localizedRoleTypeLabel(l10n, roleType);
  final roleSentence = normalizedRoleType.isEmpty
      ? ''
      : (languageCode == 'hi'
            ? ' ${l10n.settingsRoleContextLabel}${l10n.settingsRoleSentenceHi(normalizedRoleType)}'
            : ' ${l10n.settingsRoleContextLabel}${l10n.settingsRoleSentenceEn(normalizedRoleType)}');
  return l10n.settingsTtsSummary(selectedLanguageLabel, roleSentence);
}

String profileTtsSummary({
  required BuildContext context,
  required String languageCode,
  required String roleLabel,
  required dynamic profile,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final trustStatus = localizedTrustSafetyStatus(l10n, profile?.trustSafetyStatus ?? 'normal');
  final deletionStatus = localizedAccountState(l10n, profile?.accountDeletionStatus ?? 'active');
  return l10n.profileTtsSummary(roleLabel, trustStatus, deletionStatus);
}
