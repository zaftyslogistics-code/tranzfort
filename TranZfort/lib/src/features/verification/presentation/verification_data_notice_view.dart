import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/legal_url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/legal_consent_checkbox_row.dart';
import '../providers/verification_wizard_provider.dart';

class VerificationDataNoticeView extends ConsumerStatefulWidget {
  const VerificationDataNoticeView({super.key});

  @override
  ConsumerState<VerificationDataNoticeView> createState() => _VerificationDataNoticeViewState();
}

class _VerificationDataNoticeViewState extends ConsumerState<VerificationDataNoticeView> {
  bool _dataProcessingAccepted = false;

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context);
    if (!_dataProcessingAccepted) {
      return;
    }

    final result = await ref.read(verificationWizardProvider.notifier).acknowledgeDataProcessing();
    if (!mounted || result.isSuccess) {
      return;
    }

    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure != null && failure.message.trim().isNotEmpty
              ? failure.message
              : l10n.verificationDataNoticeFailure,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verificationWizardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verificationDataNoticeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.verificationDataNoticeHeading,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.verificationDataNoticeBody,
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.verificationDataNoticeBullets,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const Spacer(),
              LegalConsentCheckboxRow(
                value: _dataProcessingAccepted,
                onChanged: (value) => setState(() => _dataProcessingAccepted = value ?? false),
                label: Text.rich(
                  TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(text: l10n.verificationDataNoticeCheckboxPrefix),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: () => launchLegalUrl(
                            context,
                            l10n,
                            Uri.parse(AppConfig.privacyPolicyUrl),
                          ),
                          child: Text(
                            l10n.settingsPrivacyPolicyLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              decoration: TextDecoration.underline,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: l10n.verificationDataNoticeCheckboxSuffix),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: l10n.verificationDataNoticeContinueAction,
                onPressed: _dataProcessingAccepted && !state.isLoading ? _continue : null,
                isLoading: state.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
