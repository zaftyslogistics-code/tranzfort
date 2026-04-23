import 'dart:async';

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
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../providers/auth_providers.dart';

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
                Text(
                  AppLocalizations.of(context).onboardingGateTimeoutMessage,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: AppLocalizations.of(context).onboardingGateRetryAction,
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
                  child: Text(AppLocalizations.of(context).onboardingGateBackToSignInAction),
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
  AppUserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
  }

  bool _hasUnsavedChanges() {
    return _selectedRole != null;
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Selection?'),
        content: const Text('You have selected a role. Do you want to discard it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
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

    final result = await ref.read(onboardingControllerProvider.notifier).updateRoleSelection(selectedRole);

    if (result.isFailure) {
      if (!mounted) {
        return;
      }
      final failure = result.failureOrNull;
      AppSnackbar.show(
        context: context,
        message: failure is BusinessRuleFailure && failure.message == OnboardingController.roleWorkspaceFailureCode
            ? l10n.onboardingRoleWorkspaceFailure
            : l10n.onboardingRoleSaveFailure,
        variant: AppSnackbarVariant.error,
      );
      return;
    }

    if (!mounted) {
      return;
    }
    context.go(AppRoutes.onboardingProfilePath);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final onboardingState = ref.watch(onboardingControllerProvider);
    final ttsSummary = '${l10n.onboardingChooseRoleTitle}. ${l10n.onboardingRoleQuestion}. ${l10n.onboardingRoleSubtitle}';
    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (_hasUnsavedChanges()) {
          final navigator = Navigator.of(context);
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            // Clear selection when discarding changes
            setState(() => _selectedRole = null);
            // Navigate back
            navigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.onboardingChooseRoleTitle),
          actions: const [
            TtsActionButton(),
            LanguageToggleAction(),
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
                  isLoading: onboardingState.isSubmitting,
                ),
                  ],
                ),
              ),
              TtsScreenSummaryEffect(
                summary: ttsSummary,
                screenKey: AppRoutes.onboardingRolePath,
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
