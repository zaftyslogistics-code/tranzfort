import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mutation_queue.dart';
import '../services/mutation_queue_database.dart';
import 'app_state_providers.dart';

/// Provider for the MutationQueueDatabase singleton.
final mutationQueueDatabaseProvider = Provider<MutationQueueDatabase>((ref) {
  return MutationQueueDatabase();
});

/// Bump to refresh mutation queue list and counts.
final mutationQueueRefreshProvider = StateProvider<int>((ref) => 0);

void bumpMutationQueueRefresh(WidgetRef ref) {
  ref.read(mutationQueueRefreshProvider.notifier).state++;
  ref.invalidate(pendingMutationCountProvider);
  ref.invalidate(retryingMutationCountProvider);
  ref.invalidate(failedMutationCountProvider);
  ref.invalidate(exhaustedMutationCountProvider);
  ref.invalidate(activeMutationQueueProvider);
}

/// Provider for the pending mutation count.
final pendingMutationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(mutationQueueRefreshProvider);
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getPendingCount();
});

/// Provider for the failed mutation count.
final failedMutationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(mutationQueueRefreshProvider);
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getFailedCount();
});

/// Provider for the retrying mutation count.
final retryingMutationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(mutationQueueRefreshProvider);
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getRetryingCount();
});

/// Provider for the exhausted mutation count.
final exhaustedMutationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(mutationQueueRefreshProvider);
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getExhaustedCount();
});

/// Notifier class for syncing state.
class SyncingStateNotifier extends StateNotifier<bool> {
  SyncingStateNotifier() : super(false);

  void setSyncing(bool syncing) {
    state = syncing;
  }
}

/// Provider for the syncing state.
final isSyncingProvider = StateNotifierProvider<SyncingStateNotifier, bool>((ref) {
  return SyncingStateNotifier();
});

/// Non-completed mutations for the signed-in user (newest first).
final activeMutationQueueProvider = FutureProvider<List<QueuedMutation>>((ref) async {
  ref.watch(mutationQueueRefreshProvider);
  final userId = ref.watch(currentAuthStateProvider).profile?.id;
  if (userId == null || userId.isEmpty) {
    return const <QueuedMutation>[];
  }

  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getActiveMutations(userId: userId);
});
