import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/mutation_queue_provider.dart';
import '../../core/providers/mutation_queue_processor_provider.dart';

/// A banner widget that shows sync status for offline operations.
/// Displays pending and failed mutation counts with retry functionality.
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

  @override
  Widget build(BuildContext context) {
    final pendingCountAsync = ref.watch(pendingMutationCountProvider);
    final retryingCountAsync = ref.watch(retryingMutationCountProvider);
    final failedCountAsync = ref.watch(failedMutationCountProvider);
    final exhaustedCountAsync = ref.watch(exhaustedMutationCountProvider);

    return pendingCountAsync.when(
      data: (pendingCount) {
        return retryingCountAsync.when(
          data: (retryingCount) {
            return failedCountAsync.when(
              data: (failedCount) {
                return exhaustedCountAsync.when(
                  data: (exhaustedCount) {
                    final totalCount = pendingCount + retryingCount + failedCount + exhaustedCount;
                    
                    if (dismissed || totalCount == 0) {
                      return const SizedBox.shrink();
                    }

                    // Show banner if there are any mutations
                    _animationController.forward();

                    return SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Material(
                          color: totalCount > 0
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
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
                                        // Show pending count
                                        if (pendingCount > 0)
                                          Text(
                                            '$pendingCount pending',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        // Show retrying count
                                        if (retryingCount > 0)
                                          Text(
                                            '$retryingCount retrying',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        // Show failed (non-exhausted) count
                                        if (failedCount > exhaustedCount)
                                          Text(
                                            '${failedCount - exhaustedCount} failed',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.orange.shade700,
                                                ),
                                          ),
                                        // Show exhausted count
                                        if (exhaustedCount > 0)
                                          Text(
                                            '$exhaustedCount exhausted (max retries)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Colors.red.shade700,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: dismiss,
                                    icon: const Icon(Icons.close, size: 20),
                                    label: const Text(''),
                                  ),
                                  if (totalCount > 0)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final processor = ref.read(mutationQueueProcessorProvider);
                                        ref.read(isSyncingProvider.notifier).setSyncing(true);
                                        processor.processQueue().whenComplete(() {
                                          if (mounted) {
                                            ref.read(isSyncingProvider.notifier).setSyncing(false);
                                          }
                                        });
                                      },
                                      icon: ref.watch(isSyncingProvider)
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.refresh, size: 18),
                                      label: const Text('Retry'),
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
                  error: (context, error) => const SizedBox.shrink(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (context, error) => const SizedBox.shrink(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (context, error) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (context, error) => const SizedBox.shrink(),
    );
  }

  void dismiss() {
    setState(() {
      dismissed = true;
    });
    _animationController.reverse();
  }
}
