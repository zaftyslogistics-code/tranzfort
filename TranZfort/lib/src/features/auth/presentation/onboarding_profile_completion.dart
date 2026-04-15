import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../providers/auth_providers.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _initialized = false;
  bool _termsAccepted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final profileAsync = ref.read(currentProfileProvider);
    if (profileAsync.isLoading) {
      return;
    }

    final profile = profileAsync.valueOrNull;
    _nameController.text = profile?.fullName ?? '';
    _mobileController.text = profile?.mobile ?? '';
    _initialized = true;
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final updateResult = await ref.read(onboardingControllerProvider.notifier).updateProfile(
          fullName: _nameController.text,
          mobile: _mobileController.text,
          termsAccepted: _termsAccepted,
        );

    if (!mounted) {
      return;
    }

    if (updateResult.isFailure) {
      final failure = updateResult.failureOrNull;
      AppSnackbar.show(
        context: context,
        message: failure is BusinessRuleFailure && failure.message == OnboardingController.termsAcceptanceRequiredCode
            ? l10n.onboardingTermsAcceptance
            : l10n.onboardingProfileSaveFailure,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    final refreshedAuthState = await ref.read(authStateProvider.future);
    if (!mounted) {
      return;
    }

    if (refreshedAuthState.role == AppUserRole.supplier) {
      context.go(AppRoutes.supplierDashboardPath);
    } else {
      context.go(AppRoutes.truckerDashboardPath);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final onboardingState = ref.watch(onboardingControllerProvider);
    final ttsSummary = '${l10n.onboardingCompleteProfileTitle}. ${l10n.onboardingCompleteProfileHeading}. ${l10n.onboardingCompleteProfileSubtitle}';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingCompleteProfileTitle),
        actions: [
          TtsActionButton(fallbackSummary: ttsSummary),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text(
                l10n.onboardingCompleteProfileHeading,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.onboardingCompleteProfileSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameController,
                label: l10n.onboardingFullNameLabel,
                hintText: l10n.onboardingFullNameHint,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _mobileController,
                label: l10n.onboardingMobileLabel,
                hintText: profile?.mobile?.isNotEmpty == true ? profile!.mobile : '+91XXXXXXXXXX',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                      child: Text(l10n.onboardingTermsAcceptance),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.onboardingSaveAndContinue,
                onPressed: _submit,
                isLoading: onboardingState.isSubmitting,
              ),
                ],
              ),
            ),
            TtsScreenSummaryEffect(
              summary: ttsSummary,
              screenKey: AppRoutes.onboardingProfilePath,
            ),
          ],
        ),
      ),
    );
  }
}
