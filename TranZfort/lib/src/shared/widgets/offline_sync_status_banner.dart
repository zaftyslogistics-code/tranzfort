import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/providers/mutation_queue_processor_provider.dart';
import '../../core/providers/mutation_queue_provider.dart';
import '../../l10n/app_localizations.dart';

/// Banner showing pending/failed offline mutations with retry and list navigation.
class OfflineSyncStatusBanner extends ConsumerStatefulWidget {
  const OfflineSyncStatusBanner({super.key});

  @override
  ConsumerState<OfflineSyncStatusBanner> createState() => _OfflineSyncBannerState();
}

class _OfflineSyncBannerState extends ConsumerState<OfflineSyncStatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool dismissed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _retryAll() async {
    ref.read(isSyncingProvider.notifier).setSyncing(true);
    try {
      await ref.read(mutationQueueProcessorProvider).processQueue();
    } finally {
      if (mounted) {
        ref.read(isSyncingProvider.notifier).setSyncing(false);
        bumpMutationQueueRefresh(ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pendingCountAsync = ref.watch(pendingMutationCountProvider);
    final retryingCountAsync = ref.watch(retryingMutationCountProvider);
    final failedCountAsync = ref.watch(failedMutationCountProvider);
    final exhaustedCountAsync = ref.watch(exhaustedMutationCountProvider);
    final isSyncing = ref.watch(isSyncingProvider);

    return pendingCountAsync.when(
      data: (pendingCount) {
        return retryingCountAsync.when(
          data: (retryingCount) {
            return failedCountAsync.when(
              data: (failedCount) {
                return exhaustedCountAsync.when(
                  data: (exhaustedCount) {
                    final totalCount = pendingCount + retryingCount + failedCount;

                    if (dismissed || totalCount == 0) {
                      return const SizedBox.shrink();
                    }

                    _animationController.forward();

                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Material(
                          color: Colors.orange.shade100,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.sync_problem, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l10n.mutationQueueBannerSummary(
                                            pendingCount,
                                            retryingCount,
                                            failedCount,
                                            exhaustedCount,
                                          ),
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextButton(
                                          onPressed: () => context.push(AppRoutes.pendingSyncPath),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(l10n.mutationQueueViewListAction),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: dismiss,
                                    icon: const Icon(Icons.close, size: 20),
                                  ),
                                  const SizedBox(width: 4),
                                  ElevatedButton.icon(
                                    onPressed: isSyncing ? null : _retryAll,
                                    icon: isSyncing
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.refresh, size: 18),
                                    label: Text(l10n.mutationQueueRetryAllAction),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void dismiss() {
    setState(() {
      dismissed = true;
    });
    _animationController.reverse();
  }
}
