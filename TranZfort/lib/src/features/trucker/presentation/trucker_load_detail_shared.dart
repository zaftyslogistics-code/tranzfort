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
