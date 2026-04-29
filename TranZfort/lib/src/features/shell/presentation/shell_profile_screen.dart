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
import '../../../shared/widgets/status_components.dart';
import 'shell_account_helpers.dart';
import 'shell_components.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentAuthStateProvider);
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;
    final languageCode = ref.watch(appLocaleProvider).locale.languageCode;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final roleLabel = l10n.accountRoleValue(
      switch (authState.role) {
        AppUserRole.supplier => 'supplier',
        AppUserRole.trucker => 'trucker',
        AppUserRole.unknown => 'other',
      },
    );

    return DetailPageScaffold(
      title: l10n.commonProfileLabel,
      children: [
        if (profileAsync.isLoading)
          const LoadingShimmer(height: 96, itemCount: 2)
        else if (profileAsync.hasError)
          WarningBlock(
            title: l10n.profileLoadFailureTitle,
            message: l10n.profileLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetryAction,
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
                // Location display - removed as city/state fields no longer exist in UserProfile
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
                  value: localizedAccountState(l10n, profile?.accountDeletionStatus ?? 'active'),
                ),
                if (profile != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  TrustSafetyStatusSummary(
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
                            message: profileTtsSummary(
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

class TrustSafetyStatusSummary extends StatelessWidget {
  final String trustSafetyStatus;
  final String? trustSafetyReasonSummary;
  final VoidCallback onOpenSupport;

  const TrustSafetyStatusSummary({
    super.key,
    required this.trustSafetyStatus,
    required this.trustSafetyReasonSummary,
    required this.onOpenSupport,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final normalized = trustSafetyStatus.trim().toLowerCase();
    final displayLabel = localizedTrustSafetyStatus(l10n, normalized);

    if (normalized == 'warned') {
      return WarningBlock(
        title: l10n.trustSafetyWarningTitle,
        message: l10n.trustSafetyWarningMessage,
        action: OutlineButton(
          label: l10n.commonOpenSupportAction,
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
          label: l10n.commonOpenSupportAction,
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
          label: l10n.commonOpenSupportAction,
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
          label: l10n.commonOpenSupportAction,
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
