part of 'trucker_load_detail_screen.dart';

class _DetailFactChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailFactChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.subtleSurface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartConversationButton extends ConsumerStatefulWidget {
  final String supplierId;
  final String? truckerId;
  final String loadId;
  final String? blockedReason;

  const _StartConversationButton({
    required this.supplierId,
    required this.truckerId,
    required this.loadId,
    required this.blockedReason,
  });

  @override
  ConsumerState<_StartConversationButton> createState() => _StartConversationButtonState();
}

class _StartConversationButtonState extends ConsumerState<_StartConversationButton> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final truckerId = (widget.truckerId ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlineButton(
          label: l10n.truckerChatSupplierAction,
          isLoading: _isStarting,
          onPressed: truckerId.isEmpty || _isStarting || widget.blockedReason != null
              ? null
              : () async {
                  setState(() {
                    _isStarting = true;
                  });
                  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
                        supplierId: widget.supplierId,
                        truckerId: truckerId,
                        loadId: widget.loadId,
                      );
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _isStarting = false;
                  });
                  result.when(
                    success: (conversationId) {
                      context.push('${AppRoutes.chatPath}/$conversationId');
                    },
                    failure: (failure) {
                      AppSnackbar.show(
                        context: context,
                        message: l10n.truckerLoadChatStartFailureMessage,
                        variant: AppSnackbarVariant.error,
                      );
                    },
                  );
                },
        ),
        if ((widget.blockedReason ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.truckerChatLockedLabel(widget.blockedReason!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _TruckerLoadDetailFailureBlock extends StatelessWidget {
  final AppFailure failure;
  final VoidCallback onRetry;

  const _TruckerLoadDetailFailureBlock({
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (failure is NotFoundFailure) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: l10n.truckerLoadDetailLoadNotFoundTitle,
        subtitle: l10n.truckerLoadDetailLoadNotFoundSubtitle,
        actionLabel: l10n.truckerLoadDetailBackToFindLoadsAction,
        onAction: () => context.go(AppRoutes.findLoadsPath),
      );
    }

    return WarningBlock(
      title: l10n.truckerLoadDetailLoadFailureTitle,
      message: l10n.truckerLoadDetailLoadFailureMessage,
      action: OutlineButton(label: l10n.commonRetry, onPressed: onRetry),
    );
  }
}

/// Phase 5: Premium dark earnings card with big profit headline + cost breakdown grid.
class _EarningsEstimateCard extends StatelessWidget {
  final TripCostEstimate tripCost;

  const _EarningsEstimateCard({required this.tripCost});

  @override
  Widget build(BuildContext context) {
    final profitColor = tripCost.isProfitable ? AppColors.primaryOnDark : AppColors.error;
    final profitBg = tripCost.isProfitable
        ? AppColors.primaryOnDark.withValues(alpha: 0.15)
        : AppColors.error.withValues(alpha: 0.18);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.inkSurface, AppColors.inkMid, AppColors.inkDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadows.elevation3,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryOnDark.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.iconChip),
                ),
                child: Icon(
                  Icons.insights_outlined,
                  color: AppColors.primaryOnDark,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TRIP EARNINGS ESTIMATE',
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.primaryOnDark,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tripCost.distanceKm.toStringAsFixed(0)} km · @ ${tripCost.mileageUsed.toStringAsFixed(1)} km/L · ₹${tripCost.dieselPricePerLitre.toStringAsFixed(0)}/L',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.inkTextSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Total Fare (Load Value) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryOnDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: AppColors.primaryOnDark.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL FARE (LOAD VALUE)',
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.primaryOnDark,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${_fmt(tripCost.totalLoadValue)}',
                      style: AppTypography.displayHero.copyWith(
                        color: AppColors.primaryOnDark,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${tripCost.distanceKm.toStringAsFixed(0)} km trip',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.inkTextSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Total Expense ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.inkBorder.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL EXPENSE',
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.inkTextSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '₹${_fmt(tripCost.totalExpense)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.inkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Net Profit / Loss Hero ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: profitBg,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: profitColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      tripCost.isProfitable ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: profitColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tripCost.isProfitable ? 'ESTIMATED NET PROFIT' : 'ESTIMATED NET LOSS',
                      style: AppTypography.labelMicro.copyWith(
                        color: profitColor,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_fmt(tripCost.netProfit.abs())}',
                  style: AppTypography.displayHero.copyWith(
                    color: profitColor,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tripCost.isProfitable
                      ? 'After all expenses deducted from total fare'
                      : 'Expenses exceed total fare',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkTextSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // ── Breakdown Grid (2 columns) ──
          Text(
            'COST BREAKDOWN',
            style: AppTypography.labelMicro.copyWith(
              color: AppColors.inkTextMuted,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _CostBreakdownTile(
                  icon: Icons.local_gas_station_outlined,
                  label: 'DIESEL',
                  value: '₹${_fmt(tripCost.dieselCost)}',
                  accent: AppColors.primaryOnDark,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CostBreakdownTile(
                  icon: Icons.toll_outlined,
                  label: 'TOLL (₹11/km)',
                  value: '₹${_fmt(tripCost.tollCost)}',
                  accent: AppColors.secondaryOnDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _CostBreakdownTile(
                  icon: Icons.person_outline,
                  label: 'DRIVER (₹5/km)',
                  value: '₹${_fmt(tripCost.driverCost)}',
                  accent: AppColors.info,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _CostBreakdownTile(
                  icon: Icons.build_outlined,
                  label: 'MISC (₹2/km)',
                  value: '₹${_fmt(tripCost.miscCost)}',
                  accent: AppColors.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Total expense row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.inkDeep,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.inkBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: AppColors.inkTextSecondary),
                const SizedBox(width: 8),
                Text(
                  'TOTAL EXPENSE',
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.inkTextSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${_fmt(tripCost.totalExpense)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.inkTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Footnote
          Row(
            children: [
              Icon(Icons.info_outline, size: 12, color: AppColors.inkTextMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Estimates assume ₹11/km toll, ₹5/km driver, ₹2/km misc. Actual costs vary.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkTextMuted,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(amount % 100000 == 0 ? 0 : 2)}L';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }
    return amount.toStringAsFixed(0);
  }
}

class _CostBreakdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _CostBreakdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.inkDeep,
        borderRadius: BorderRadius.circular(AppRadius.iconChip),
        border: Border.all(color: AppColors.inkBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.inkTextMuted,
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.inkTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

void _startChat(BuildContext context, WidgetRef ref, String loadId, TruckerLoadDetail detail) async {
  final l10n = AppLocalizations.of(context);
  final profile = ref.read(truckerProfileProvider).valueOrNull;
  final truckerId = profile?.id ?? '';
  if (truckerId.isEmpty) {
    AppSnackbar.show(
      context: context,
      message: l10n.truckerLoadDetailVerificationRequiredMessage,
      variant: AppSnackbarVariant.info,
    );
    return;
  }
  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
        supplierId: detail.supplierId,
        truckerId: truckerId,
        loadId: loadId,
      );
  if (!context.mounted) {
    return;
  }
  result.when(
    success: (conversationId) {
      context.push('${AppRoutes.chatPath}/$conversationId');
    },
    failure: (_) {
      AppSnackbar.show(
        context: context,
        message: l10n.truckerLoadChatStartFailureMessage,
        variant: AppSnackbarVariant.error,
      );
    },
  );
}
