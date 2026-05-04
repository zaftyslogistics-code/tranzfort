import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mutation_queue.dart';
import '../providers/app_state_providers.dart';
import '../providers/connectivity_provider.dart';
import '../providers/mutation_queue_provider.dart';
import '../services/mutation_queue_processor.dart';

/// Simple mutation executor that executes mutations via Supabase RPCs.
class SupabaseMutationExecutor implements MutationExecutor {
  final SupabaseClient? client;

  SupabaseMutationExecutor(this.client);

  @override
  Future<MutationExecutionResult> execute(QueuedMutation mutation) async {
    if (client == null) {
      return MutationExecutionResult(
        success: false,
        error: 'No Supabase client available',
      );
    }

    try {
      final payload = mutation.payload;
      switch (mutation.target) {
        case MutationTarget.loadBooking:
          await client!.rpc('submit_booking_request', params: {
            'p_load_id': payload['load_id'],
            'p_truck_id': payload['truck_id'],
            'p_booking_gps_lat': payload['booking_gps_lat'],
            'p_booking_gps_lng': payload['booking_gps_lng'],
          });
          break;

        case MutationTarget.chatSend:
          // Chat messages are sent via realtime or direct insert
          // For now, this is a placeholder - actual implementation depends on chat backend
          await client!.from('messages').insert({
            'conversation_id': payload['conversation_id'],
            'sender_id': mutation.userId,
            'type': payload['type'],
            'text_body': payload['text_body'],
          });
          break;

        case MutationTarget.podProofUpload:
          await client!.rpc('upload_trip_proof', params: {
            'p_trip_id': payload['trip_id'],
            'p_pod_path': payload['pod_path'],
            'p_lr_path': payload['lr_path'],
            'p_gps_lat': payload['gps_lat'],
            'p_gps_lng': payload['gps_lng'],
          });
          break;

        default:
          return MutationExecutionResult(
            success: false,
            error: 'Unsupported mutation target: ${mutation.target}',
          );
      }

      return MutationExecutionResult(success: true);
    } catch (error) {
      return MutationExecutionResult(
        success: false,
        error: error.toString(),
      );
    }
  }
}

/// Provider for the mutation queue processor.
final mutationQueueProcessorProvider = Provider<MutationQueueProcessor>((ref) {
  final database = ref.watch(mutationQueueDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);
  final executor = SupabaseMutationExecutor(client);

  return MutationQueueProcessor(
    database: database,
    executor: executor,
  );
});

/// Provider that watches connectivity and triggers mutation processing when coming online.
final mutationQueueSyncProvider = Provider<void Function()>((ref) {
  final processor = ref.watch(mutationQueueProcessorProvider);
  final connectivity = ref.watch(connectivityProvider);

  // Track previous connectivity state
  bool wasOnline = connectivity.value ?? true;

  // Listen for connectivity changes and process queue when coming online
  final subscription = ref.listen(connectivityProvider, (previous, next) {
    final isOnline = next.value ?? true;
    if (!wasOnline && isOnline) {
      // Came online - process queued mutations
      processor.processQueue();
    }
    wasOnline = isOnline;
  });

  // Return cleanup function
  ref.onDispose(() {
    subscription.close();
  });

  return () {
    // Manual trigger function
    processor.processQueue();
  };
});
