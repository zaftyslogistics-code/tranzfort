import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../core/theme/app_colors.dart';
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
      ref
          .read(ttsServiceProvider)
          .speak('Aap supplier hain ya trucker? Chunein.');
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
          ).showSnackBar(SnackBar(content: Text(_failureMessage(type))));
          break;
      }
    }
  }

  String _failureMessage(AppFailureType type) {
    return switch (type) {
      AppFailureType.network => 'Please check your internet connection.',
      AppFailureType.auth => 'Your session expired. Please sign in again.',
      AppFailureType.conflict => 'Role setup was already completed.',
      AppFailureType.validation => 'Please choose a valid role.',
      _ => 'Could not save role. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final roleSetupState = ref.watch(authRoleSetupProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                'How will you use TranZfort?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your role to get started.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              _buildRoleCard(
                context,
                title: 'I am a Supplier / Consignor',
                subtitle: 'I want to post loads and find trucks',
                icon: Icons.inventory_2_outlined,
                role: 'supplier',
              ),

              const SizedBox(height: 16),

              _buildRoleCard(
                context,
                title: 'I am a Trucker / Transporter',
                subtitle: 'I want to find loads and manage my fleet',
                icon: Icons.local_shipping_outlined,
                role: 'trucker',
              ),

              const Spacer(),

              PrimaryButton(
                label: 'Complete Setup',
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.neutralLight,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
