import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../notifications/data/push_runtime_service.dart';

String localizedTrustSafetyStatus(AppLocalizations l10n, String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return l10n.supportTrustStatusValue('normal');
  }
  return l10n.supportTrustStatusValue(normalized);
}

String localizedAccountState(AppLocalizations l10n, String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return l10n.accountStateValue('active');
  }
  return l10n.accountStateValue(normalized);
}

String localizedRoleTypeLabel(AppLocalizations l10n, String? roleType) {
  final normalized = (roleType ?? '').trim().toLowerCase();
  return l10n.accountRoleValue(normalized.isEmpty ? 'unknown' : normalized);
}

String _pushStatusName(PushPermissionStatus status) {
  return switch (status) {
    PushPermissionStatus.authorized => 'allowed',
    PushPermissionStatus.provisional => 'allowed_quietly',
    PushPermissionStatus.denied => 'blocked',
    PushPermissionStatus.notDetermined => 'not_requested',
    PushPermissionStatus.unavailable => 'unavailable',
  };
}

String pushStatusLabel(PushPermissionStatus status, AppLocalizations l10n) {
  return l10n.settingsPushStatusValue(_pushStatusName(status));
}

String pushStatusGuidance(PushPermissionStatus status, AppLocalizations l10n) {
  return l10n.settingsPushGuidanceValue(_pushStatusName(status));
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
