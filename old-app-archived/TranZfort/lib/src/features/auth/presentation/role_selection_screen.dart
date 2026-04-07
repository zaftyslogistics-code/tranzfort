import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      ref
          .read(ttsServiceProvider)
          .speak(l10n.roleTtsPrompt);
    });
  }

  Future<void> _saveRole() async {
    if (_selectedRole == null) return;

    final result = await ref
        .read(authRoleSetupProvider.notifier)
        .submitRole(_selectedRole!);

    if (mounted) {
      switch (result) {
        case Success():
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
      AppFailureType.auth => l10n.roleErrorAuth,
      AppFailureType.conflict => l10n.roleErrorConflict,
      AppFailureType.validation => l10n.roleErrorValidation,
      _ => l10n.roleErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleSetupState = ref.watch(authRoleSetupProvider);

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
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.heroCardRadius),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.primary,
                        size: AppSpacing.iconLg,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.roleTitle,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.roleSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildRoleCard(
                context,
                title: l10n.roleSupplierTitle,
                subtitle: l10n.roleSupplierSubtitle,
                icon: Icons.inventory_2_outlined,
                role: 'supplier',
              ),
              const SizedBox(height: AppSpacing.md),
              _buildRoleCard(
                context,
                title: l10n.roleTruckerTitle,
                subtitle: l10n.roleTruckerSubtitle,
                icon: Icons.local_shipping_outlined,
                role: 'trucker',
              ),
              const SizedBox(height: AppSpacing.xl),
              GradientButton(
                label: l10n.roleCompleteSetup,
                onPressed: _selectedRole != null && !roleSetupState.isSubmitting
                    ? _saveRole
                    : null,
                isLoading: roleSetupState.isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String role,
  }) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: isSelected
            ? AppColors.surfaceLevel1
            : AppColors.surfaceGlass,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.neutralLight,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.heroCardRadius),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surfaceLevel1,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderDefault,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: AppSpacing.iconXl,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? AppColors.onSurface
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: AppSpacing.iconLg,
              ),
          ],
        ),
      ),
    );
  }
}
