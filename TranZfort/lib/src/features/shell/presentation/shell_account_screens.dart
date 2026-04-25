import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../auth/data/auth_repository.dart';
import 'shell_components.dart';
import 'shell_profile_screen.dart';

export 'shell_account_helpers.dart';
export 'shell_profile_screen.dart';
export 'shell_settings_screen.dart';

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
    final roleLabel = l10n.accountRoleValue(
      switch (authState.role) {
        AppUserRole.supplier => 'supplier',
        AppUserRole.trucker => 'trucker',
        AppUserRole.unknown => 'other',
      },
    );

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
                value: l10n.accountStateValue(
                  authState.isDeactivated
                      ? 'deactivated_pending_cleanup'
                      : authState.isBanned
                          ? 'restricted'
                          : 'active',
                ),
              ),
              if (profile != null) ...[
                const SizedBox(height: AppSpacing.md),
                TrustSafetyStatusSummary(
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
              label: l10n.commonRetryAction,
              onPressed: () => ref.refresh(authStateProvider),
            ),
          ),
        SectionCard(
          title: l10n.accountManageTitle,
          child: Column(
            children: [
              NavListTile(
                icon: Icons.person_outline,
                label: l10n.commonProfileLabel,
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
                  label: l10n.commonFleetLabel,
                  onTap: () => context.go(AppRoutes.fleetPath),
                ),
              NavListTile(
                icon: Icons.settings_outlined,
                label: l10n.accountSettingsLabel,
                onTap: () => context.go(AppRoutes.settingsPath),
              ),
              NavListTile(
                icon: Icons.support_agent_outlined,
                label: l10n.commonSupportLabel,
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
                  label: l10n.commonSignOutAction,
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

