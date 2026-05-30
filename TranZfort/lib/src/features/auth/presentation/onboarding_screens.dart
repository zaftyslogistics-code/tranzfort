import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/tts_utterance_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/tts_card_speaker_button.dart';
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
                  label: AppLocalizations.of(context).commonRetryAction,
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
                  child: Text(AppLocalizations.of(context).commonBackToSignInAction),
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

    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.onboardingDiscardRoleTitle),
        content: Text(l10n.onboardingDiscardRoleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonDiscardAction),
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
    final ttsL10n = TtsLocalizations.of(context);
    final ttsSummary = limitTtsSentences(ttsL10n.ttsOnboardingChooseRole);
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
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.onboardingRoleQuestion,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.onboardingRoleSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _RoleCard(
                      title: l10n.onboardingTruckerTitle,
                      subtitle: l10n.onboardingTruckerSubtitle,
                      icon: Icons.local_shipping_outlined,
                      accent: AppColors.primary,
                      ttsMessage: ttsL10n.ttsOnboardingFindLoadsCard,
                      selected: _selectedRole == AppUserRole.trucker,
                      onTap: () => setState(() => _selectedRole = AppUserRole.trucker),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _RoleCard(
                      title: l10n.onboardingSupplierTitle,
                      subtitle: l10n.onboardingSupplierSubtitle,
                      icon: Icons.inventory_2_outlined,
                      accent: AppColors.secondary,
                      ttsMessage: ttsL10n.ttsOnboardingPostLoadCard,
                      selected: _selectedRole == AppUserRole.supplier,
                      onTap: () => setState(() => _selectedRole = AppUserRole.supplier),
                    ),
                    const Spacer(),
                    GradientButton(
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

class _RoleCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String ttsMessage;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.ttsMessage,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardRadius = BorderRadius.circular(AppRadius.card);

    return Semantics(
      button: true,
      selected: selected,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardRadius,
          child: BrandGradientBorder(
            borderRadius: cardRadius,
            innerColor: AppColors.cardSurface,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.iconChip),
                    ),
                    child: Icon(icon, size: 28, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                        ),
                      ],
                    ),
                  ),
                  TtsCardSpeakerButton(
                    message: ttsMessage,
                    onDarkSurface: false,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    selected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: selected ? accent : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
