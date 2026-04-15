import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_locale_providers.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../notifications/data/push_runtime_service.dart';
import 'shell_account_helpers.dart';
import 'shell_components.dart';

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
                  value: localizedRoleTypeLabel(l10n, profile!.roleType),
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
                          message: settingsTtsSummary(
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
                  message: pushRuntimeIssuesMessage(l10n, runtimeIssues),
                  action: OutlineButton(
                    label: l10n.settingsPushRefreshStatus,
                    onPressed: refreshStatus,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              InfoRow(label: l10n.settingsPushStatusLabel, value: pushStatusLabel(snapshot.status, l10n)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                pushStatusGuidance(snapshot.status, l10n),
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
        error: (error, _) {
          AppLogger.error('Permission snapshot error', scope: 'push', error: error);
          return WarningBlock(
            title: l10n.settingsPushStatusUnavailableTitle,
            message: l10n.settingsPushStatusUnavailableMessage,
            action: OutlineButton(
              label: l10n.settingsPushRefreshStatus,
              onPressed: refreshStatus,
            ),
          );
        },
      ),
    );
  }
}
