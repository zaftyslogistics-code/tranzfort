import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/ist_time.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/profile_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/utils/ui_error_text.dart';
import '../providers/user_profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final profileRole = (profileAsync.value?['user_role_type'] ?? 'trucker')
        .toString();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: AppDrawer(
        role: profileRole == 'supplier' ? 'supplier' : 'trucker',
      ),
      appBar: AppBar(
        title: Text(l10n.appDrawerProfileTitle),
        actions: [AppBarUtilityActions(ttsPreviewText: l10n.profileScreenTts)],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(l10n.profileNotFound));
          }

          final name =
              (profile['full_name'] ?? l10n.profileDefaultUserName).toString();
          final mobile = (profile['mobile'] ?? '-').toString();
          final role = (profile['user_role_type'] ?? 'user').toString();
          final verification = (profile['verification_status'] ?? 'unverified')
              .toString();
          final isSupplier = role == 'supplier';
          final dlExpiryDate = DateTime.tryParse(
            (profile['dl_expiry_date'] ?? '').toString(),
          );
          final dlExpiryDays = dlExpiryDate == null
              ? null
              : IstTime.toIst(dlExpiryDate)
                    .difference(IstTime.nowIst())
                    .inDays;

          return ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.screenPaddingV,
              AppSpacing.screenPaddingH,
              AppSpacing.safeBottomPadding(context),
            ),
            children: [
              TtsAnnounce(text: l10n.profileScreenTts),
              ProfileCard(
                name: name,
                roleLabel: role.toUpperCase(),
                verified: verification == 'verified',
                verifiedLabel: l10n.profileVerifiedChip,
                unverifiedLabel: l10n.profileVerificationChip(verification),
                subtitle: mobile,
              ),
              const SizedBox(height: AppSpacing.md),
              if (role == 'trucker' && dlExpiryDays != null && dlExpiryDays <= 30)
                _ProfileSectionCard(
                  title: l10n.profileDocumentExpiryTitle,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      dlExpiryDays <= 0
                          ? l10n.profileDlExpiredWarning
                          : l10n.profileDlExpiryWarningDays(dlExpiryDays),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (role == 'trucker' && dlExpiryDays != null && dlExpiryDays <= 30)
                const SizedBox(height: AppSpacing.md),
              _ProfileSectionCard(
                title: l10n.profileQuickActionsTitle,
                child: Column(
                  children: [
                    _ProfileActionTile(
                      title: isSupplier
                          ? l10n.profileSupplierVerificationAction
                          : l10n.profileTruckerVerificationAction,
                      subtitle: l10n.profileVerificationActionSubtitle,
                      icon: Icons.verified_user_outlined,
                      onTap: () => context.push(
                        isSupplier
                            ? '/verification/supplier'
                            : '/verification/trucker',
                      ),
                    ),
                    if (isSupplier) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _ProfileActionTile(
                        title: l10n.settingsPayoutProfileTitle,
                        subtitle: l10n.settingsPayoutProfileSubtitle,
                        icon: Icons.account_balance_wallet_outlined,
                        onTap: () => context.push('/payout-profile'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    _ProfileActionTile(
                      title: l10n.settingsTitle,
                      subtitle: l10n.profileSettingsActionSubtitle,
                      icon: Icons.settings_outlined,
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileSectionCard(
                title: l10n.profileSummaryTitle,
                child: Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        label: l10n.profileRoleLabel,
                        value: role.toUpperCase(),
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        label: l10n.profileStatusLabel,
                        value: verification.toUpperCase(),
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        label: l10n.profileMobileLabel,
                        value: mobile == '-' ? l10n.profileValueNa : l10n.profileValueSet,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ProfileSectionCard(
                title: l10n.profileIdentityDetailsTitle,
                child: Column(
                  children: [
                    _ProfileInfoRow(label: l10n.profileFullNameLabel, value: name),
                    _ProfileInfoRow(label: l10n.profileMobileLabel, value: mobile),
                    _ProfileInfoRow(label: l10n.profileRoleLabel, value: role),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          l10n.profileVerificationLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        StatusBadge.fromVerificationStatus(
                          context,
                          verification,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(uiSafeErrorText(context, e, fallback: l10n.profileLoadError)),
        ),
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ProfileSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      leading: Container(
        width: AppSpacing.tileLeadingSize,
        height: AppSpacing.tileLeadingSize,
        decoration: BoxDecoration(
          color: AppColors.brandTealLight,
          borderRadius: BorderRadius.circular(AppSpacing.tileLeadingRadius),
        ),
        child: Icon(icon, color: AppColors.primary, size: AppSpacing.iconMd),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.neutral),
      onTap: onTap,
    );
  }
}
