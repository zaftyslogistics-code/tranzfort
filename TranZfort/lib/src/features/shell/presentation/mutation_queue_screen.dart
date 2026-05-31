import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/mutation_queue.dart';
import '../../../core/providers/mutation_queue_processor_provider.dart';
import '../../../core/providers/mutation_queue_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/status_components.dart';
import 'shell_components.dart';

String localizedMutationTargetLabel(AppLocalizations l10n, MutationTarget target) {
  return switch (target) {
    MutationTarget.loadBooking => l10n.mutationQueueTargetLoadBooking,
    MutationTarget.chatSend => l10n.mutationQueueTargetChatSend,
    MutationTarget.podProofUpload => l10n.mutationQueueTargetPodProof,
    MutationTarget.lrProofUpload => l10n.mutationQueueTargetLrProof,
    MutationTarget.profileUpdate => l10n.mutationQueueTargetProfileUpdate,
    MutationTarget.supplierProfileUpdate => l10n.mutationQueueTargetSupplierProfile,
    MutationTarget.disputeRaise => l10n.mutationQueueTargetDispute,
    MutationTarget.reviewSubmit => l10n.mutationQueueTargetReviewSubmit,
    MutationTarget.reviewReply => l10n.mutationQueueTargetReviewReply,
    MutationTarget.notificationMarkRead => l10n.mutationQueueTargetNotificationRead,
    MutationTarget.custom => l10n.mutationQueueTargetCustom,
  };
}

String localizedMutationStatusLabel(AppLocalizations l10n, QueuedMutation mutation) {
  if (mutation.isExhausted) {
    return l10n.mutationQueueStatusExhausted;
  }
  return switch (mutation.status) {
    MutationStatus.pending => l10n.mutationQueueStatusPending,
    MutationStatus.retrying => l10n.mutationQueueStatusRetrying,
    MutationStatus.failed => l10n.mutationQueueStatusFailed,
    MutationStatus.completed => l10n.mutationQueueStatusCompleted,
  };
}

class MutationQueueScreen extends ConsumerWidget {
  const MutationQueueScreen({super.key});

  Future<void> _syncAll(WidgetRef ref) async {
    ref.read(isSyncingProvider.notifier).setSyncing(true);
    try {
      await ref.read(mutationQueueProcessorProvider).processQueue();
    } finally {
      ref.read(isSyncingProvider.notifier).setSyncing(false);
      bumpMutationQueueRefresh(ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queueAsync = ref.watch(activeMutationQueueProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    return DetailPageScaffold(
      title: l10n.mutationQueueScreenTitle,
      children: [
        HeroActionCard(
          title: l10n.mutationQueueScreenTitle,
          subtitle: l10n.mutationQueueScreenSubtitle,
          child: OutlineButton(
            label: l10n.mutationQueueRetryAllAction,
            isLoading: isSyncing,
            onPressed: isSyncing ? null : () => _syncAll(ref),
          ),
        ),
        queueAsync.when(
          data: (mutations) {
            if (mutations.isEmpty) {
              return EmptyStateView(
                icon: Icons.cloud_done_outlined,
                title: l10n.mutationQueueEmptyTitle,
                subtitle: l10n.mutationQueueEmptySubtitle,
              );
            }

            return SectionCard(
              title: l10n.mutationQueueListTitle,
              child: Column(
                children: [
                  for (var index = 0; index < mutations.length; index++) ...[
                    if (index > 0) const SizedBox(height: AppSpacing.md),
                    _MutationQueueListTile(
                      mutation: mutations[index],
                      onDismiss: mutations[index].isExhausted
                          ? () async {
                              await ref.read(mutationQueueDatabaseProvider).delete(mutations[index].id);
                              bumpMutationQueueRefresh(ref);
                            }
                          : null,
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const LoadingShimmer(height: 160, itemCount: 3),
          error: (_, __) => WarningBlock(
            title: l10n.mutationQueueScreenTitle,
            message: l10n.mutationQueueLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetryAction,
              onPressed: () => bumpMutationQueueRefresh(ref),
            ),
          ),
        ),
      ],
    );
  }
}

class _MutationQueueListTile extends StatelessWidget {
  final QueuedMutation mutation;
  final VoidCallback? onDismiss;

  const _MutationQueueListTile({
    required this.mutation,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusLabel = localizedMutationStatusLabel(l10n, mutation);
    final accent = mutation.isExhausted
        ? AppColors.error
        : mutation.status == MutationStatus.failed
            ? AppColors.warning
            : AppColors.info;

    return StandardListCard(
      accent: accent,
      title: localizedMutationTargetLabel(l10n, mutation.target),
      subtitle: mutation.endpoint,
      trailing: StatusChip(label: statusLabel),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.mutationQueueRetryProgress(mutation.retryCount, mutation.maxRetries),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if ((mutation.lastError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              mutation.lastError!.trim(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ],
          if (onDismiss != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlineButton(
                label: l10n.mutationQueueDismissAction,
                onPressed: onDismiss,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
