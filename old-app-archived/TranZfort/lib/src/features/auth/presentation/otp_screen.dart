import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/services/tts_service.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  String _failureMessage(AppFailureType type, AppLocalizations l10n) {
    return switch (type) {
      AppFailureType.network => l10n.authErrorNetwork,
      AppFailureType.auth => l10n.phoneSaveErrorAuth,
      AppFailureType.validation => l10n.phoneSaveErrorValidation,
      AppFailureType.conflict => l10n.phoneSaveErrorConflict,
      _ => l10n.phoneSaveErrorAuth,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      ref
          .read(ttsServiceProvider)
          .speak(l10n.otpTtsPrompt);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final l10n = AppLocalizations.of(context);
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.phoneSaveErrorValidation)),
      );
      return;
    }

    final result = await ref
        .read(authOtpVerificationProvider.notifier)
        .verifyOtp(widget.phone, otp);

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.otpVerify)),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/role-selection');
        }
        break;
      case Failure(type: final type):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(type, l10n))),
        );
        break;
    }
  }

  Future<void> _resendOtp() async {
    final l10n = AppLocalizations.of(context);
    final result = await ref
        .read(authEntryProvider.notifier)
        .sendOtp(widget.phone);

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.otpResendCode)),
        );
        break;
      case Failure(type: final type):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_failureMessage(type, l10n))),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otpState = ref.watch(authOtpVerificationProvider);
    final authEntryState = ref.watch(authEntryProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.otpVerify,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: AppSpacing.xl,
                        letterSpacing: AppSpacing.sm,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.inputBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                          borderSide: const BorderSide(color: AppColors.borderDefault),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: l10n.otpVerify,
                      onPressed: otpState.isVerifying ? null : _verifyOtp,
                      isLoading: otpState.isVerifying,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          AppSpacing.minTouchTarget,
                        ),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: authEntryState.isLoading ? null : _resendOtp,
                      child: Text(l10n.otpResendCode),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
