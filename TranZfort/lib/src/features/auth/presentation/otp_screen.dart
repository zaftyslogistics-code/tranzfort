import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(ttsServiceProvider)
          .speak('Aapke phone par bheja gaya 6-ank ka OTP daalein.');
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    final result = await ref
        .read(authOtpVerificationProvider.notifier)
        .verifyOtp(widget.phone, otp);

    if (mounted) {
      switch (result) {
        case Success():
          // GoRouter redirect handles routing based on profile completeness
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
      AppFailureType.auth => 'Invalid OTP. Please try again.',
      AppFailureType.validation => 'Please enter a valid 6-digit OTP.',
      _ => 'Could not verify OTP. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authOtpVerificationProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit code sent to\n${widget.phone}',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Verify',
                onPressed: state.isVerifying ? null : _verifyOtp,
                isLoading: state.isVerifying,
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  // TODO: Implement Resend logic
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('OTP Resent')));
                },
                child: const Text('Resend Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
