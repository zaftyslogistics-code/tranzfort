import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakAuthPrompt();
    });
  }

  Future<void> _speakAuthPrompt() async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(ttsServiceProvider)
          .speak(l10n.authTtsPromptGoogleOrPhone)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // Non-blocking by design: auth entry should render even if TTS fails.
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await ref
        .read(authEntryProvider.notifier)
        .continueWithGoogle();

    if (mounted) {
      switch (result) {
        case Success():
          // Profile completeness gate in router will navigate automatically.
          break;
        case Failure(type: final type):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_failureMessage(type, context))));
          break;
      }
    }
  }

  String _failureMessage(AppFailureType type, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      AppFailureType.network => l10n.authErrorNetwork,
      AppFailureType.auth => l10n.authErrorAuthFailed,
      AppFailureType.conflict => l10n.authErrorConflict,
      AppFailureType.validation => l10n.authErrorValidation,
      _ => l10n.authErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authEntryState = ref.watch(authEntryProvider);
    final isLoading = authEntryState.isLoading;
    final session = ref.watch(authSessionProvider).value?.session;
    final profile = ref.watch(userProfileProvider).value;
    final requiresPhoneCapture =
        session != null && ((profile?['mobile'] as String?)?.isEmpty ?? true);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingH,
            vertical: AppSpacing.screenPaddingV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.heroCardRadius),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(AppSpacing.heroCardRadius),
                      ),
                      child: Image.asset(
                        'assets/images/splash-screen-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      requiresPhoneCapture
                          ? l10n.authOneFinalStep
                          : l10n.authWelcomeTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      requiresPhoneCapture
                          ? l10n.authGoogleDoneAddMobile
                          : l10n.authWelcomeSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                backgroundColor: AppColors.surface.withValues(alpha: 0.92),
                border: Border.all(color: AppColors.borderDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.authContinueJourney,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.authChooseSignInMethod,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLevel1,
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GoogleSignInButton(
                            isLoading: isLoading,
                            enabled: !requiresPhoneCapture,
                            onPressed: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: AppColors.divider),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.authOr,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: AppColors.divider),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          OutlineButton(
                            label: l10n.authContinueWithPhone,
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.push('/auth/phone-entry');
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.authTermsAgreement,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool enabled;
  final bool isLoading;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.enabled,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isActionEnabled = enabled && !isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: SizedBox(
        height: AppSpacing.buttonHeight,
        child: TextButton(
          onPressed: isActionEnabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/google_logo.png',
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Text(
                          'G',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.authContinueWithGoogle,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.onSurface),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
