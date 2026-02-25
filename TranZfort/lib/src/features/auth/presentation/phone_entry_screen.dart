import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../shared/widgets/primary_button.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';
    final result = await ref.read(authEntryProvider.notifier).sendOtp(formattedPhone);

    if (!mounted) {
      return;
    }

    switch (result) {
      case Success():
        context.push('/otp', extra: formattedPhone);
        break;
      case Failure(type: final type):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_failureMessage(type))));
        break;
    }
  }

  String _failureMessage(AppFailureType type) {
    return switch (type) {
      AppFailureType.network => 'Please check your internet connection.',
      AppFailureType.auth => 'Could not send OTP. Please try again.',
      AppFailureType.validation => 'Please enter a valid mobile number.',
      _ => 'Could not send OTP. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final authEntryState = ref.watch(authEntryProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'Enter your mobile number',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We will send a 6-digit OTP to verify your number.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Continue',
                onPressed: authEntryState.isLoading ? null : _sendOtp,
                isLoading: authEntryState.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
