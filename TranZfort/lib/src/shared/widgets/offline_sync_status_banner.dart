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
    final failedCountAsync = ref.watch(failedMutationCountProvider);

    return pendingCountAsync.when(
      data: (pendingCount) {
        return failedCountAsync.when(
          data: (failedCount) {
            final totalCount = pendingCount + failedCount;
            
            if (dismissed || totalCount == 0) {
              return const SizedBox.shrink();
            }

            // Show banner if there are pending or failed mutations
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
                                Text(
                                  pendingCount > 0
                                      ? 'Syncing $pendingCount operation${pendingCount == 1 ? '' : 's'}'
                                      : 'Sync complete',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (failedCount > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '$failedCount operation${failedCount == 1 ? '' : 's'} failed',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.red.shade700,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (failedCount > 0)
                            TextButton.icon(
                              onPressed: dismiss,
                              icon: const Icon(Icons.close, size: 20),
                              label: const Text(''),
                            ),
                          if (pendingCount > 0)
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
  }

  void dismiss() {
    setState(() {
      dismissed = true;
    });
    _animationController.reverse();
  }
}
