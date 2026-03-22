import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/contextual_tts_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../data/auth_repository.dart';

class OnboardingGateScreen extends ConsumerStatefulWidget {
  const OnboardingGateScreen({super.key});

  @override
  ConsumerState<OnboardingGateScreen> createState() => _OnboardingGateScreenState();
}

class _OnboardingGateScreenState extends ConsumerState<OnboardingGateScreen> {
  bool _timedOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authStateProvider);
    final authState = ref.watch(currentAuthStateProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    final isLoading = (authState.hasSession && !authState.isResolved) ||
        profileAsync.isLoading ||
        authStateAsync.isLoading;

    if (isLoading && !_timedOut) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_timedOut) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_disabled_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Loading is taking longer than expected.\nलोडिंग में सामान्य से अधिक समय लग रहा है।',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Retry / पुनः प्रयास करें',
                  onPressed: () {
                    ref.invalidate(authStateProvider);
                    ref.invalidate(currentProfileProvider);
                    setState(() => _timedOut = false);
                    _timer?.cancel();
                    _timer = Timer(const Duration(seconds: 8), () {
                      if (mounted) {
                        setState(() => _timedOut = true);
                      }
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go(AppRoutes.authPath),
                  child: const Text('Back to sign in / साइन इन पर वापस जाएं'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  late final ContextualTtsService _contextualTtsService;
  AppUserRole? _selectedRole;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contextualTtsService = ref.read(contextualTtsServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakPrompt());
  }

  Future<void> _speakPrompt() async {
    await _contextualTtsService.speakSummary(
          languageCode: 'hi',
          message: AppLocalizations.of(context).authTtsOnboardingRolePrompt,
        );
  }

  Future<void> _continue() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final selectedRole = _selectedRole;
    if (selectedRole == null) {
      AppSnackbar.show(
        context: context,
        message: l10n.onboardingSelectRoleError,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.updateRoleSelection(selectedRole);
    if (result.isSuccess) {
      final extensionResult = await repository.provisionRoleExtension(selectedRole);
      if (extensionResult.isFailure) {
        if (!mounted) {
          return;
        }
        setState(() => _isSubmitting = false);
        AppSnackbar.show(
          context: context,
          message: l10n.onboardingRoleWorkspaceFailure,
          variant: AppSnackbarVariant.error,
        );
        return;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (result.isFailure) {
      AppSnackbar.show(
        context: context,
        message: l10n.onboardingRoleSaveFailure,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    ref.invalidate(authStateProvider);
    await ref.read(authStateProvider.future);
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.onboardingProfilePath);
  }

  @override
  void dispose() {
    unawaited(_contextualTtsService.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingChooseRoleTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.onboardingRoleQuestion,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(l10n.onboardingRoleSubtitle),
              const SizedBox(height: 24),
              _RoleCard(
                title: l10n.onboardingSupplierTitle,
                subtitle: l10n.onboardingSupplierSubtitle,
                icon: Icons.inventory_2_outlined,
                selected: _selectedRole == AppUserRole.supplier,
                onTap: () => setState(() => _selectedRole = AppUserRole.supplier),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                title: l10n.onboardingTruckerTitle,
                subtitle: l10n.onboardingTruckerSubtitle,
                icon: Icons.local_shipping_outlined,
                selected: _selectedRole == AppUserRole.trucker,
                onTap: () => setState(() => _selectedRole = AppUserRole.trucker),
              ),
              const Spacer(),
              PrimaryButton(
                label: l10n.onboardingContinue,
                onPressed: _continue,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends ConsumerState<ProfileCompletionScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _initialized = false;
  bool _isSubmitting = false;

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
    setState(() => _isSubmitting = true);
    final updateResult = await ref.read(authRepositoryProvider).updateProfile(
          fullName: _nameController.text,
          mobile: _mobileController.text,
        );
    if (updateResult.isSuccess) {
      await ref.read(authRepositoryProvider).recordTermsAcceptance();
    }

    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);

    if (updateResult.isFailure) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      AppSnackbar.show(
        context: context,
        message: l10n.onboardingProfileSaveFailure,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    ref.invalidate(authStateProvider);
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingCompleteProfileTitle)),
      body: SafeArea(
        child: Padding(
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
              Text(l10n.onboardingTermsAcceptance),
              const Spacer(),
              PrimaryButton(
                label: l10n.onboardingSaveAndContinue,
                onPressed: _submit,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
          ),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked),
            ],
          ),
        ),
      ),
    );
  }
}
