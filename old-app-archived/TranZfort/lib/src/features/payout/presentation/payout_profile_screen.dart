import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/solid_header.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/payout_profile_provider.dart';

class PayoutProfileScreen extends ConsumerWidget {
  const PayoutProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutAsync = ref.watch(payoutProfileProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPayoutProfileTitle)),
      body: payoutAsync.when(
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: EmptyStateView(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.payoutNoProfileTitle,
                  subtitle: l10n.payoutNoProfileSubtitle,
                ),
              ),
            );
          }

          final status = (profile['status'] ?? '-').toString();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              SolidHeader(
                title: l10n.settingsPayoutProfileTitle,
                subtitle: l10n.settingsPayoutProfileSubtitle,
                icon: Icons.account_balance_wallet_outlined,
                trailing: _buildStatusBadge(context, status),
              ),
              const SizedBox(height: AppSpacing.md),
              _PayoutSectionCard(
                child: Column(
                  children: [
                    _PayoutInfoRow(
                      label: l10n.payoutAccountHolderLabel,
                      value: '${profile['account_holder_name'] ?? '-'}',
                    ),
                    _PayoutInfoRow(
                      label: l10n.payoutAccountLast4Label,
                      value: '•••• ${profile['account_number_last4'] ?? '-'}',
                    ),
                    _PayoutInfoRow(
                      label: l10n.payoutIfscLabel,
                      value: '${profile['ifsc_code'] ?? '-'}',
                    ),
                    _PayoutInfoRow(
                      label: l10n.payoutStatusLabel,
                      value: status,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.payoutLoadError)),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized == 'active' || normalized == 'verified') {
      return StatusBadge(
        label: status.toUpperCase(),
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      );
    }
    if (normalized == 'pending' || normalized == 'under_review') {
      return StatusBadge(
        label: status.toUpperCase(),
        backgroundColor: AppColors.warningTint,
        textColor: AppColors.warning,
      );
    }
    if (normalized == 'rejected' || normalized == 'disabled') {
      return StatusBadge(
        label: status.toUpperCase(),
        backgroundColor: AppColors.errorTint,
        textColor: AppColors.error,
      );
    }
    return StatusBadge.neutral(status.toUpperCase());
  }
}

class _PayoutSectionCard extends StatelessWidget {
  final Widget child;

  const _PayoutSectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: child,
    );
  }
}

class _PayoutInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _PayoutInfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: emphasize ? AppColors.primary : AppColors.onSurface,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
