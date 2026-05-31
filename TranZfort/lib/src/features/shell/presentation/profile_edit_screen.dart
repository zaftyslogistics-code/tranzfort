import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../features/auth/data/auth_repository_profile_ops.dart';
import '../../../features/auth/providers/auth_providers.dart' show authStateProvider;
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';

String _profileEditFailureMessage(AppLocalizations l10n, AppFailure? failure) {
  if (failure is ValidationFailure &&
      failure.message == AuthProfileErrorCodes.nameTooShort) {
    return l10n.onboardingProfileSaveFailure;
  }
  if (failure is ValidationFailure &&
      failure.message == AuthProfileErrorCodes.mobileRequired) {
    return l10n.onboardingProfileSaveFailure;
  }
  if (failure is ServerFailure && failure.message.trim().isNotEmpty) {
    return failure.message;
  }
  return l10n.profileEditFailure;
}

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null && ref.read(currentProfileProvider).isLoading) {
      return;
    }

    _nameController.text = profile?.fullName ?? '';
    _mobileController.text = profile?.mobile ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    final result = await ref.read(authRepositoryProvider).updateProfileDetails(
          fullName: _nameController.text,
          mobile: _mobileController.text,
        );

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);

    if (result.isFailure) {
      AppSnackbar.show(
        context: context,
        message: _profileEditFailureMessage(l10n, result.failureOrNull),
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    ref.invalidate(authStateProvider);
    ref.invalidate(currentProfileProvider);

    AppSnackbar.show(
      context: context,
      message: l10n.profileEditSuccess,
      variant: AppSnackbarVariant.success,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: SafeArea(
        child: profileAsync.isLoading && !_initialized
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.profileEditSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      controller: _nameController,
                      hintText: l10n.onboardingFullNameHint,
                      label: l10n.onboardingFullNameLabel,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      controller: _mobileController,
                      hintText: '+91XXXXXXXXXX',
                      label: l10n.onboardingMobileLabel,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: l10n.profileSaveChangesAction,
                      onPressed: _isSaving ? null : _save,
                      isLoading: _isSaving,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
