import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/solid_header.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();

    return Scaffold(
      drawer: AppDrawer(role: role == 'supplier' ? 'supplier' : 'trucker'),
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: [
          AppBarUtilityActions(ttsPreviewText: l10n.settingsTtsPreviewText),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPaddingH,
          AppSpacing.screenPaddingV,
          AppSpacing.screenPaddingH,
          AppSpacing.safeBottomPadding(context),
        ),
        children: [
          TtsAnnounce(text: l10n.settingsScreenTtsContext),
          SolidHeader(
            title: l10n.settingsHeroTitle,
            subtitle: l10n.settingsHeroSubtitle,
            icon: Icons.settings_outlined,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsSectionCard(
            title: l10n.settingsGeneralSection,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.languageLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.settingsLanguageSubtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                DropdownButton<String>(
                  value: settings.language,
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                    DropdownMenuItem(value: 'hi', child: Text(l10n.languageHindi)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).setLanguage(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsSectionCard(
            title: l10n.settingsVoiceNotificationsSection,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsTtsMuteTitle),
                  subtitle: Text(l10n.settingsTtsMuteSubtitle),
                  value: settings.ttsMuted,
                  onChanged: (val) =>
                      ref.read(settingsProvider.notifier).toggleTts(val),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsTtsSpeedLabel),
                  subtitle: Text(
                    l10n.settingsTtsSpeedValue(settings.ttsSpeed.toStringAsFixed(1)),
                  ),
                ),
                Slider(
                  value: settings.ttsSpeed,
                  min: 0.3,
                  max: 0.8,
                  divisions: 5,
                  onChanged: settings.ttsMuted
                      ? null
                      : (val) =>
                            ref.read(settingsProvider.notifier).setTtsSpeed(val),
                ),
                const SizedBox(height: AppSpacing.xs),
                DropdownButtonFormField<String>(
                  initialValue: settings.ttsLanguageMode,
                  decoration: InputDecoration(
                    labelText: l10n.settingsTtsLanguageLabel,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'auto',
                      child: Text(l10n.settingsTtsLanguageAuto),
                    ),
                    DropdownMenuItem(
                      value: 'hi',
                      child: Text(l10n.languageHindi),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.languageEnglish),
                    ),
                  ],
                  onChanged: settings.ttsMuted
                      ? null
                      : (val) {
                          if (val != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .setTtsLanguageMode(val);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: settings.ttsMuted
                        ? null
                        : () {
                            ref
                                .read(ttsServiceProvider)
                                .previewVoice(l10n.settingsTtsPreviewText);
                          },
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: Text(l10n.settingsTtsPreviewAction),
                  ),
                ),
                const Divider(height: AppSpacing.lg),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsPushNotificationsTitle),
                  subtitle: Text(l10n.settingsPushNotificationsSubtitle),
                  value: settings.pushEnabled,
                  onChanged: (val) =>
                      ref.read(settingsProvider.notifier).togglePush(val),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsSectionCard(
            title: l10n.settingsAccountSupportSection,
            child: Column(
              children: [
                _SettingsTile(
                  title: l10n.settingsMyProfileTitle,
                  subtitle: l10n.settingsMyProfileSubtitle,
                  icon: Icons.person_outline,
                  onTap: () => context.push('/profile'),
                ),
                if (role == 'supplier') ...[
                  const SizedBox(height: AppSpacing.xs),
                  _SettingsTile(
                    title: l10n.settingsPayoutProfileTitle,
                    subtitle: l10n.settingsPayoutProfileSubtitle,
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => context.push('/payout-profile'),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                _SettingsTile(
                  title: l10n.settingsHelpSupportTitle,
                  subtitle: l10n.settingsHelpSupportSubtitle,
                  icon: Icons.support_agent_outlined,
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SettingsTile(
                  title: l10n.settingsAppVersionTitle,
                  subtitle: '${l10n.settingsCurrentBuildPrefix}: 1.0.0',
                  icon: Icons.info_outline,
                  trailing: Text(
                    '1.0.0',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsSectionCard(
            title: l10n.settingsDangerZone,
            borderColor: AppColors.error.withValues(alpha: 0.25),
            backgroundColor: AppColors.errorTint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsDeleteAccountTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.settingsDeleteAccountSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: AppSpacing.md),
                OutlineButton(
                  label: l10n.settingsDeleteAccountAction,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(l10n.settingsDeleteAccountDialogTitle),
                        content: Text(l10n.settingsDeleteAccountDialogContent),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(l10n.tripCancelAction),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: Text(l10n.settingsDeleteAction),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      final success = await ref
                          .read(settingsProvider.notifier)
                          .deleteAccount();
                      if (success && context.mounted) {
                        context.go('/auth');
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.settingsDeleteAccountFailed),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: l10n.settingsSignOutAction,
            onPressed: () async {
              await ref.read(settingsProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentRole: role == 'supplier' ? 'supplier' : 'trucker',
      ),
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;

  const _SettingsSectionCard({
    required this.title,
    required this.child,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: borderColor ?? AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_SectionTitle(title), child],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
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
      trailing:
          trailing ?? const Icon(Icons.chevron_right, color: AppColors.neutral),
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
