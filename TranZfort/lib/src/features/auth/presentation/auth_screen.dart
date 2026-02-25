import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../core/theme/app_colors.dart';
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
      ref
          .read(ttsServiceProvider)
          .speak('Google se continue karein ya phone number se.');
    });
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await ref.read(authEntryProvider.notifier).continueWithGoogle();

    if (mounted) {
      switch (result) {
        case Success():
          // Profile completeness gate in router will navigate automatically.
          break;
        case Failure(type: final type):
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_failureMessage(type))));
          break;
      }
    }
  }

  String _failureMessage(AppFailureType type) {
    return switch (type) {
      AppFailureType.network => 'Please check your internet connection.',
      AppFailureType.auth => 'Authentication failed. Please try again.',
      AppFailureType.conflict =>
        'This account is already registered. Try signing in.',
      AppFailureType.validation => 'Please review the entered details.',
      _ => 'Something went wrong. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final authEntryState = ref.watch(authEntryProvider);
    final isLoading = authEntryState.isLoading;
    final session = ref.watch(authSessionProvider).value?.session;
    final profile = ref.watch(userProfileProvider).value;
    final requiresPhoneCapture =
        session != null && ((profile?['mobile'] as String?)?.isEmpty ?? true);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                requiresPhoneCapture
                    ? 'One more step to continue'
                    : 'Namaste! Welcome to TranZfort',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                requiresPhoneCapture
                    ? 'Google sign-in done. Complete phone verification to continue.'
                    : 'India ka trusted load matching platform',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.neutral),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              PrimaryButton(
                label: 'Continue with Google',
                onPressed: isLoading || requiresPhoneCapture
                    ? null
                    : _handleGoogleSignIn,
                isLoading: isLoading,
              ),

              const SizedBox(height: 16),

              OutlineButton(
                label: 'Continue with Phone',
                onPressed: isLoading
                    ? null
                    : () {
                        context.push('/auth/phone-entry');
                      },
              ),

              const SizedBox(height: 32),
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
