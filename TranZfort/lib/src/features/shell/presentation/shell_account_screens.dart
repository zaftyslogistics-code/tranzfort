import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_locale_providers.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/status_components.dart';
import '../../auth/data/auth_repository.dart';
import '../../notifications/data/push_runtime_service.dart';
import 'shell_components.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut(BuildContext context) async {
    if (_isSigningOut) {
      return;
    }

    final router = GoRouter.of(context);

    setState(() {
      _isSigningOut = true;
    });

    final result = await ref.read(authRepositoryProvider).signOutAndClearLocalState();
    if (!mounted) {
      return;
    }

    setState(() {
      _isSigningOut = false;
    });

    if (result.isFailure) {
      if (context.mounted) {
        AppSnackbar.show(
          context: context,
          message: _signOutFailureMessage(),
          variant: AppSnackbarVariant.error,
        );
      }
      return;
    }

    ref.invalidate(authStateProvider);
    ref.invalidate(currentAuthStateProvider);
    ref.invalidate(profileCompletenessProvider);
    router.go(AppRoutes.authPath);
  }

  String _signOutFailureMessage() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return l10n.accountSignOutFailureMessage;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final authState = ref.watch(currentAuthStateProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final verificationPath = authState.role == AppUserRole.supplier
        ? AppRoutes.supplierVerificationPath
        : AppRoutes.truckerVerificationPath;
    final roleLabel = switch (authState.role) {
      AppUserRole.supplier => l10n.accountRoleSupplier,
      AppUserRole.trucker => l10n.accountRoleTrucker,
      AppUserRole.unknown => l10n.accountRoleUnknown,
    };

    return ShellScrollView(
      children: [
        SectionCard(
          title: l10n.accountStatusTitle,
          child: Column(
            children: [
              InfoRow(
                label: l10n.accountProfileStatusLabel,
                value: authState.isProfileComplete ? l10n.accountProfileStatusComplete : l10n.accountProfileStatusNeedsAttention,
              ),
              InfoRow(
                label: l10n.profileRoleLabel,
                value: roleLabel,
              ),
              InfoRow(
                label: l10n.accountAccountStateLabel,
                value: authState.isDeactivated
                    ? l10n.accountStateDeactivatedPendingCleanup
                    : authState.isBanned
                        ? l10n.accountStateRestricted
                        : l10n.accountStateActive,
              ),
              if (profile != null) ...[
                const SizedBox(height: AppSpacing.md),
                _TrustSafetyStatusSummary(
                  trustSafetyStatus: profile.trustSafetyStatus,
                  trustSafetyReasonSummary: profile.trustSafetyReasonSummary,
                  onOpenSupport: () => context.go(AppRoutes.supportPath),
                ),
              ],
            ],
          ),
        ),
        if (profileAsync.isLoading)
          const LoadingShimmer(height: 96, itemCount: 1)
        else if (profileAsync.hasError)
          WarningBlock(
            title: l10n.accountLoadFailureTitle,
            message: l10n.accountLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetry,
              onPressed: () => ref.refresh(authStateProvider),
            ),
          ),
        SectionCard(
          title: l10n.accountManageTitle,
          child: Column(
            children: [
              NavListTile(
                icon: Icons.person_outline,
                label: l10n.navProfile,
                onTap: () => context.go(AppRoutes.profilePath),
              ),
              NavListTile(
                icon: Icons.verified_user_outlined,
                label: l10n.accountVerificationLabel,
                onTap: () => context.go(verificationPath),
              ),
              if (authState.role == AppUserRole.trucker)
                NavListTile(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.accountFleetLabel,
                  onTap: () => context.go(AppRoutes.fleetPath),
                ),
              NavListTile(
                icon: Icons.settings_outlined,
                label: l10n.accountSettingsLabel,
                onTap: () => context.go(AppRoutes.settingsPath),
              ),
              NavListTile(
                icon: Icons.support_agent_outlined,
                label: l10n.navSupport,
                onTap: () => context.go(AppRoutes.supportPath),
              ),
              NavListTile(
                icon: Icons.delete_outline,
                label: l10n.navDeleteAccount,
                onTap: () => context.go(AppRoutes.deleteAccountPath),
              ),
            ],
          ),
        ),
        SectionCard(
          title: l10n.accountSessionTitle,
          child: Column(
            children: [
              InfoRow(
                label: l10n.accountSignedInAsLabel,
                value: profile?.email ?? l10n.accountCurrentAuthenticatedSession,
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: l10n.accountSignOutAction,
                  isLoading: _isSigningOut,
                  onPressed: _isSigningOut ? null : () => _signOut(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final languageCode = ref.watch(appLocaleProvider).locale.languageCode;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final roleLabel = switch (authState.role) {
      AppUserRole.supplier => l10n.accountRoleSupplier,
      AppUserRole.trucker => l10n.accountRoleTrucker,
      AppUserRole.unknown => l10n.accountRoleUnknown,
    };

    return DetailPageScaffold(
      title: l10n.profileTitle,
      children: [
        if (profileAsync.isLoading)
          const LoadingShimmer(height: 96, itemCount: 2)
        else if (profileAsync.hasError)
          WarningBlock(
            title: l10n.profileLoadFailureTitle,
            message: l10n.profileLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetry,
              onPressed: () => ref.refresh(authStateProvider),
            ),
          )
        else ...[
          SectionCard(
            title: l10n.profileSummaryTitle,
            child: Column(
              children: [
                InfoRow(label: l10n.profileNameLabel, value: profile?.fullName.trim().isNotEmpty == true ? profile!.fullName : l10n.profileValueNotSet),
                InfoRow(label: l10n.profilePhoneLabel, value: (profile?.mobile ?? '').trim().isNotEmpty ? profile!.mobile! : l10n.profileValueNotProvided),
                InfoRow(label: l10n.profileEmailLabel, value: (profile?.email ?? '').trim().isNotEmpty ? profile!.email! : l10n.profileValueNotProvided),
                InfoRow(label: l10n.profileRoleLabel, value: roleLabel),
              ],
            ),
          ),
          SectionCard(
            title: l10n.profileReadinessTitle,
            child: Column(
              children: [
                InfoRow(
                  label: l10n.profileCompletenessLabel,
                  value: authState.isProfileComplete ? l10n.profileCompletenessComplete : l10n.profileCompletenessNeedsUpdates,
                ),
                InfoRow(
                  label: l10n.profileDeletionStatusLabel,
                  value: _localizedAccountState(l10n, profile?.accountDeletionStatus ?? 'active'),
                ),
                if (profile != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _TrustSafetyStatusSummary(
                    trustSafetyStatus: profile.trustSafetyStatus,
                    trustSafetyReasonSummary: profile.trustSafetyReasonSummary,
                    onOpenSupport: () => context.go(AppRoutes.supportPath),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlineButton(
                    label: l10n.commonHearSummary,
                    onPressed: () async {
                      final outcome = await ref.read(contextualTtsServiceProvider).speakSummary(
                            languageCode: languageCode,
                            message: _profileTtsSummary(
                              context: context,
                              languageCode: languageCode,
                              roleLabel: roleLabel,
                              profile: profile,
                            ),
                          );
                      if (!context.mounted || outcome == ContextualTtsOutcome.spoken || outcome == ContextualTtsOutcome.skipped) {
                        return;
                      }
                      AppSnackbar.show(
                        context: context,
                        message: outcome == ContextualTtsOutcome.muted ? l10n.commonVoiceMuted : l10n.commonVoiceUnavailable,
                        variant: outcome == ContextualTtsOutcome.muted ? AppSnackbarVariant.info : AppSnackbarVariant.error,
                      );
                    },
                  ),
                ),
                if (authState.role == AppUserRole.trucker) ...[
                  const SizedBox(height: AppSpacing.md),
                  NavListTile(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.profileOpenFleetReadiness,
                    onTap: () => context.go(AppRoutes.fleetPath),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                NavListTile(
                  icon: Icons.delete_outline,
                  label: l10n.profileRequestAccountDeletion,
                  onTap: () => context.go(AppRoutes.deleteAccountPath),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final localeState = ref.watch(appLocaleProvider);
    final localeController = ref.read(appLocaleProvider.notifier);

    return DetailPageScaffold(
      title: l10n.settingsTitle,
      children: [
        SectionCard(
          title: l10n.settingsPreferencesTitle,
          child: Column(
            children: [
              AppDropdown<String>(
                label: l10n.settingsLanguageLabel,
                value: localeState.locale.languageCode,
                helperText: localeState.isSaving ? l10n.settingsLanguageSaving : l10n.settingsLanguageHelper,
                items: <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(
                    value: 'en',
                    child: Text(l10n.settingsLanguageEnglish),
                  ),
                  DropdownMenuItem<String>(
                    value: 'hi',
                    child: Text(l10n.settingsLanguageHindi),
                  ),
                ],
                onChanged: localeState.isSaving
                    ? null
                    : (value) async {
                        if (value == null) {
                          return;
                        }
                        final result = await localeController.setLanguage(value);
                        if (!context.mounted) {
                          return;
                        }
                        AppSnackbar.show(
                          context: context,
                          message: result.isSuccess
                              ? (value == 'hi' ? l10n.settingsLanguageSavedHindi : l10n.settingsLanguageSavedEnglish)
                              : l10n.settingsLanguageSaveFailed,
                          variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                        );
                        if (result.isSuccess) {
                          ref.invalidate(authStateProvider);
                        }
                      },
              ),
              if ((profile?.roleType ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoRow(
                  label: l10n.settingsRoleContextLabel,
                  value: _localizedRoleTypeLabel(l10n, profile!.roleType),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: l10n.commonHearSummary,
                  onPressed: () async {
                    final outcome = await ref.read(contextualTtsServiceProvider).speakSummary(
                          languageCode: localeState.locale.languageCode,
                          message: _settingsTtsSummary(
                            context: context,
                            languageCode: localeState.locale.languageCode,
                            selectedLanguageCode: localeState.locale.languageCode,
                            roleType: profile?.roleType,
                          ),
                        );
                    if (!context.mounted || outcome == ContextualTtsOutcome.spoken || outcome == ContextualTtsOutcome.skipped) {
                      return;
                    }
                    AppSnackbar.show(
                      context: context,
                      message: outcome == ContextualTtsOutcome.muted ? l10n.commonVoiceMuted : l10n.commonVoiceUnavailable,
                      variant: outcome == ContextualTtsOutcome.muted ? AppSnackbarVariant.info : AppSnackbarVariant.error,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              InfoRow(label: l10n.settingsVoiceAssistanceLabel, value: l10n.settingsVoiceAssistanceValue),
              InfoRow(label: l10n.settingsNotificationsLabel, value: l10n.settingsNotificationsValue),
            ],
          ),
        ),
        const _PushNotificationSettingsCard(),
        SectionCard(
          title: l10n.settingsConnectedSurfacesTitle,
          child: Column(
            children: [
              NavListTile(
                icon: Icons.person_outline,
                label: l10n.navProfile,
                onTap: () => context.go(AppRoutes.profilePath),
              ),
              NavListTile(
                icon: Icons.notifications_outlined,
                label: l10n.navNotifications,
                onTap: () => context.go(AppRoutes.notificationsPath),
              ),
              NavListTile(
                icon: Icons.support_agent_outlined,
                label: l10n.navSupport,
                onTap: () => context.go(AppRoutes.supportPath),
              ),
              NavListTile(
                icon: Icons.delete_outline,
                label: l10n.navDeleteAccount,
                onTap: () => context.go(AppRoutes.deleteAccountPath),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PushNotificationSettingsCard extends ConsumerWidget {
  const _PushNotificationSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final snapshotAsync = ref.watch(pushPermissionSnapshotProvider);
    final runtimeIssues = ref.watch(pushRuntimeIssuesProvider);

    void setPushRuntimeIssue(PushRuntimeIssue issue, bool hasIssue) {
      final next = <PushRuntimeIssue>{...ref.read(pushRuntimeIssuesProvider)};
      if (hasIssue) {
        next.add(issue);
      } else {
        next.remove(issue);
      }
      ref.read(pushRuntimeIssuesProvider.notifier).state = next;
    }

    Future<void> refreshStatus() async {
      ref.read(pushPermissionRefreshProvider.notifier).state++;
    }

    Future<void> requestPermission() async {
      final ok = await ref.read(pushRuntimeServiceProvider).requestPermission();
      setPushRuntimeIssue(PushRuntimeIssue.permissionRequestFailed, !ok);
      await refreshStatus();
    }

    return SectionCard(
      title: l10n.settingsPushNotificationsTitle,
      child: snapshotAsync.when(
        data: (snapshot) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (runtimeIssues.isNotEmpty) ...[
                WarningBlock(
                  title: l10n.settingsPushStatusUnavailableTitle,
                  message: _pushRuntimeIssuesMessage(l10n, runtimeIssues),
                  action: OutlineButton(
                    label: l10n.settingsPushRefreshStatus,
                    onPressed: refreshStatus,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              InfoRow(label: l10n.settingsPushStatusLabel, value: _pushStatusLabel(snapshot.status, l10n)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _pushStatusGuidance(snapshot.status, l10n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (snapshot.canPromptAgain)
                    Expanded(
                      child: PrimaryButton(
                        label: l10n.settingsPushRequestPermission,
                        onPressed: requestPermission,
                      ),
                    ),
                  if (snapshot.canPromptAgain) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlineButton(
                      label: l10n.settingsPushRefreshStatus,
                      onPressed: refreshStatus,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        loading: () => const LoadingShimmer(height: 104, itemCount: 1),
        error: (_, _) => WarningBlock(
          title: l10n.settingsPushStatusUnavailableTitle,
          message: l10n.settingsPushStatusUnavailableMessage,
          action: OutlineButton(
            label: l10n.settingsPushRefreshStatus,
            onPressed: refreshStatus,
          ),
        ),
      ),
    );
  }
}

class _TrustSafetyStatusSummary extends StatelessWidget {
  final String trustSafetyStatus;
  final String? trustSafetyReasonSummary;
  final VoidCallback onOpenSupport;

  const _TrustSafetyStatusSummary({
    required this.trustSafetyStatus,
    required this.trustSafetyReasonSummary,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final normalized = trustSafetyStatus.trim().toLowerCase();
    final displayLabel = _localizedTrustSafetyStatus(l10n, normalized);

    if (normalized == 'warned') {
      return WarningBlock(
        title: l10n.trustSafetyWarningTitle,
        message: l10n.trustSafetyWarningMessage,
        action: OutlineButton(
          label: l10n.trustSafetyOpenSupport,
          onPressed: onOpenSupport,
        ),
      );
    }

    if (normalized == 'restricted') {
      return WarningBlock(
        title: l10n.trustSafetyRestrictionTitle,
        message: _enforcementMessage(
          l10n: l10n,
          displayLabel: displayLabel,
          fallback: l10n.trustSafetyRestrictionFallback,
        ),
        action: OutlineButton(
          label: l10n.trustSafetyOpenSupport,
          onPressed: onOpenSupport,
        ),
      );
    }

    if (normalized == 'suspended') {
      return WarningBlock(
        title: l10n.trustSafetySuspensionTitle,
        message: _enforcementMessage(
          l10n: l10n,
          displayLabel: displayLabel,
          fallback: l10n.trustSafetySuspensionFallback,
        ),
        action: OutlineButton(
          label: l10n.trustSafetyOpenSupport,
          onPressed: onOpenSupport,
        ),
      );
    }

    if (normalized == 'banned') {
      return WarningBlock(
        title: l10n.trustSafetyBanTitle,
        message: _enforcementMessage(
          l10n: l10n,
          displayLabel: displayLabel,
          fallback: l10n.trustSafetyBanFallback,
        ),
        action: OutlineButton(
          label: l10n.trustSafetyOpenSupport,
          onPressed: onOpenSupport,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InfoRow(
                label: l10n.trustSafetyLabel,
                value: displayLabel,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            StatusBadge(
              label: displayLabel,
              icon: Icons.verified_user_outlined,
              palette: _trustSafetyPalette(normalized),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.trustSafetyHealthyMessageLine1,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.trustSafetyHealthyMessageLine2,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _enforcementMessage({
    required AppLocalizations l10n,
    required String displayLabel,
    required String fallback,
  }) {
    final reasonSummary = trustSafetyReasonSummary?.trim();
    if (reasonSummary == null || reasonSummary.isEmpty) {
      return l10n.trustSafetyCurrentStatus(displayLabel, fallback);
    }
    return l10n.trustSafetyCurrentStatusWithReason(displayLabel, reasonSummary, fallback);
  }

  StatusPalette _trustSafetyPalette(String value) {
    return switch (value) {
      'warned' => const StatusPalette(
          foreground: AppColors.warning,
          background: AppColors.warningBg,
        ),
      'restricted' || 'suspended' || 'banned' => const StatusPalette(
          foreground: AppColors.error,
          background: AppColors.errorBg,
        ),
      _ => const StatusPalette(
          foreground: AppColors.success,
          background: AppColors.successBg,
        ),
    };
  }
}

String _pushStatusLabel(PushPermissionStatus status, AppLocalizations l10n) {
  return switch (status) {
    PushPermissionStatus.authorized => l10n.settingsPushStatusAllowed,
    PushPermissionStatus.provisional => l10n.settingsPushStatusAllowedQuietly,
    PushPermissionStatus.denied => l10n.settingsPushStatusBlocked,
    PushPermissionStatus.notDetermined => l10n.settingsPushStatusNotRequested,
    PushPermissionStatus.unavailable => l10n.settingsPushStatusUnavailable,
  };
}

String _pushStatusGuidance(PushPermissionStatus status, AppLocalizations l10n) {
  return switch (status) {
    PushPermissionStatus.authorized => l10n.settingsPushGuidanceAllowed,
    PushPermissionStatus.provisional => l10n.settingsPushGuidanceAllowedQuietly,
    PushPermissionStatus.denied => l10n.settingsPushGuidanceBlocked,
    PushPermissionStatus.notDetermined => l10n.settingsPushGuidanceNotRequested,
    PushPermissionStatus.unavailable => l10n.settingsPushGuidanceUnavailable,
  };
}

String _settingsTtsSummary({
  required BuildContext context,
  required String languageCode,
  required String selectedLanguageCode,
  required String? roleType,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final selectedLanguageLabel = selectedLanguageCode == 'hi'
      ? l10n.settingsLanguageHindi
      : l10n.settingsLanguageEnglish;
  final normalizedRoleType = _localizedRoleTypeLabel(l10n, roleType);
  final roleSentence = normalizedRoleType.isEmpty
      ? ''
      : (languageCode == 'hi'
            ? ' ${l10n.settingsRoleContextLabel}${l10n.settingsRoleSentenceHi(normalizedRoleType)}'
            : ' ${l10n.settingsRoleContextLabel}${l10n.settingsRoleSentenceEn(normalizedRoleType)}');
  return l10n.settingsTtsSummary(selectedLanguageLabel, roleSentence);
}

String _localizedRoleTypeLabel(AppLocalizations l10n, String? roleType) {
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

String _pushRuntimeIssuesMessage(AppLocalizations l10n, Set<PushRuntimeIssue> issues) {
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

String _profileTtsSummary({
  required BuildContext context,
  required String languageCode,
  required String roleLabel,
  required UserProfile? profile,
}) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final trustStatus = _localizedTrustSafetyStatus(l10n, profile?.trustSafetyStatus ?? 'normal');
  final deletionStatus = _localizedAccountState(l10n, profile?.accountDeletionStatus ?? 'active');
  return l10n.profileTtsSummary(roleLabel, trustStatus, deletionStatus);
}

String _localizedTrustSafetyStatus(AppLocalizations l10n, String value) {
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

String _localizedAccountState(AppLocalizations l10n, String value) {
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
