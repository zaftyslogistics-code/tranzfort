import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mutation_queue.dart';
import '../services/mutation_queue_database.dart';

/// Provider for the MutationQueueDatabase singleton.
final mutationQueueDatabaseProvider = Provider<MutationQueueDatabase>((ref) {
  return MutationQueueDatabase();
});

/// Provider for the pending mutation count.
final pendingMutationCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getPendingCount();
});

/// Provider for the failed mutation count.
final failedMutationCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getFailedCount();
});

/// Provider for the retrying mutation count.
final retryingMutationCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(mutationQueueDatabaseProvider);
  return db.getRetryingCount();
});

/// Provider for the exhausted mutation count.
final exhaustedMutationCountProvider = FutureProvider<int>((ref) async {
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

/// Provider for all pending mutations for a user.
final userPendingMutationsProvider = FutureProvider<List<QueuedMutation>>((ref) async {
  // TODO: Get current userId from auth state
  // For now, return empty list as we need auth integration
  return <QueuedMutation>[];
});
