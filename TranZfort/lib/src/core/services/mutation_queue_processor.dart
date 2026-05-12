import 'dart:async';
import 'dart:math' as math;

import 'dart:math' show Random;

import '../models/mutation_queue.dart';
import '../services/mutation_queue_database.dart';
import '../services/mutation_queue_sanitizer.dart';

/// Service for processing queued mutations when connectivity is restored.
/// Implements exponential backoff for retry logic.
class MutationQueueProcessor {
  final MutationQueueDatabase _database;
  final MutationExecutor _executor;

  // Backoff configuration
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 60);
  static const int _backoffMultiplier = 2;
  static const double _jitterFactor = 0.1; // 10% jitter

  final Random _random = Random();

  bool _isProcessing = false;
  final StreamController<MutationProcessingEvent> _eventController =
      StreamController<MutationProcessingEvent>.broadcast();

  MutationQueueProcessor({
    required MutationQueueDatabase database,
    required MutationExecutor executor,
  })  : _database = database,
        _executor = executor;

  /// Stream of processing events for UI updates.
  Stream<MutationProcessingEvent> get events => _eventController.stream;

  /// Whether the processor is currently processing mutations.
  bool get isProcessing => _isProcessing;

  /// Start processing pending mutations.
  /// Returns when all pending mutations have been processed.
  Future<void> processQueue() async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;
    _eventController.add(const MutationProcessingEventStarted());

    try {
      while (true) {
        final pending = await _database.getPending();
        if (pending.isEmpty) {
          break;
        }

        for (final mutation in pending) {
          // Skip completed mutations (shouldn't normally be in getPending, but safe-guard)
          if (mutation.status == MutationStatus.completed) {
            await _database.delete(mutation.id);
            continue;
          }

          // Skip exhausted failed mutations
          if (mutation.status == MutationStatus.failed && mutation.isExhausted) {
            _eventController.add(
              MutationProcessingEventSkipped(
                mutationId: mutation.id,
                reason: 'ERR_EXHAUSTED',
              ),
            );
            continue;
          }

          // For failed mutations that can be retried, transition to retrying first
          if (mutation.status == MutationStatus.failed) {
            final retrying = mutation.forRetry();
            await _database.updateStatus(mutation.id, MutationStatus.retrying);
            await _database.incrementRetryCount(mutation.id);
            await _processMutation(retrying);
          } else {
            await _processMutation(mutation);
          }
        }

        // Small delay between batches to avoid overwhelming the network
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _eventController.add(const MutationProcessingEventCompleted());
    } catch (error, _) {
      _eventController.add(
        MutationProcessingEventError(
          error: MutationQueueSanitizer.sanitizeError(error.toString()),
          stackTrace: '', // Never persist stack traces
        ),
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single mutation with retry logic.
  Future<void> _processMutation(QueuedMutation mutation) async {
    _eventController.add(
      MutationProcessingEventProcessing(mutationId: mutation.id),
    );

    try {
      final result = await _executor.execute(mutation);

      if (result.success) {
        await _database.delete(mutation.id);
        _eventController.add(
          MutationProcessingEventSuccess(mutationId: mutation.id),
        );
      } else {
        // Update retry count and status
        await _database.incrementRetryCount(mutation.id);
        await _database.setLastError(mutation.id, MutationQueueSanitizer.sanitizeError(result.error ?? 'ERR_UNKNOWN'));

        if (mutation.isExhausted) {
          await _database.updateStatus(mutation.id, MutationStatus.failed);
          _eventController.add(
            MutationProcessingEventFailed(
              mutationId: mutation.id,
              error: MutationQueueSanitizer.sanitizeError(result.error ?? 'ERR_UNKNOWN'),
              exhausted: true,
            ),
          );
        } else {
          // Calculate backoff delay
          final delay = calculateBackoffDelay(mutation.retryCount);
          await Future.delayed(delay);
          await _database.updateStatus(mutation.id, MutationStatus.retrying);
          _eventController.add(
            MutationProcessingEventRetryScheduled(
              mutationId: mutation.id,
              delay: delay,
            ),
          );
        }
      }
    } catch (error) {
      await _database.incrementRetryCount(mutation.id);
      await _database.setLastError(mutation.id, MutationQueueSanitizer.sanitizeError(error.toString()));

      if (mutation.isExhausted) {
        await _database.updateStatus(mutation.id, MutationStatus.failed);
        _eventController.add(
          MutationProcessingEventFailed(
            mutationId: mutation.id,
            error: MutationQueueSanitizer.sanitizeError(error.toString()),
            exhausted: true,
          ),
        );
      } else {
        final delay = calculateBackoffDelay(mutation.retryCount);
        await Future.delayed(delay);
        await _database.updateStatus(mutation.id, MutationStatus.retrying);
        _eventController.add(
          MutationProcessingEventRetryScheduled(
            mutationId: mutation.id,
            delay: delay,
          ),
        );
      }
    }
  }

  /// Calculate exponential backoff delay based on retry count with jitter.
  /// Package-private for testing.
  Duration calculateBackoffDelay(int retryCount) {
    final delayMs = _baseDelay.inMilliseconds *
        math.pow(_backoffMultiplier, retryCount).toInt().clamp(1, 60);
    final clampedMs = delayMs.clamp(
      _baseDelay.inMilliseconds,
      _maxDelay.inMilliseconds,
    );
    
    // Add jitter to avoid thundering-herd behavior
    final jitterMs = (clampedMs * _jitterFactor * (_random.nextDouble() * 2 - 1)).toInt();
    final finalMs = (clampedMs + jitterMs).clamp(
      _baseDelay.inMilliseconds,
      _maxDelay.inMilliseconds,
    );
    
    return Duration(milliseconds: finalMs);
  }

  /// Enqueue a new mutation for processing.
  Future<void> enqueue(QueuedMutation mutation) async {
    await _database.enqueue(mutation);
    _eventController.add(
      MutationProcessingEventEnqueued(mutationId: mutation.id),
    );

    // If not currently processing, start processing
    if (!_isProcessing) {
      unawaited(processQueue());
    }
  }

  /// Cancel current processing.
  void cancel() {
    _isProcessing = false;
    _eventController.add(const MutationProcessingEventCancelled());
  }

  /// Clean up completed mutations older than specified duration.
  Future<void> cleanupCompleted({Duration olderThan = const Duration(days: 7)}) async {
    // This would require adding a timestamp filter to deleteCompleted
    // For now, just delete all completed
    await _database.deleteCompleted();
  }

  /// Dispose resources.
  void dispose() {
    _eventController.close();
  }
}

/// Result of executing a mutation.
class MutationExecutionResult {
  final bool success;
  final String? error;

  const MutationExecutionResult({
    required this.success,
    this.error,
  });

  factory MutationExecutionResult.success() {
    return const MutationExecutionResult(success: true);
  }

  factory MutationExecutionResult.failure(String error) {
    return MutationExecutionResult(
      success: false,
      error: error,
    );
  }
}

/// Interface for executing mutations.
/// Implementations will call the actual RPCs/APIs.
abstract class MutationExecutor {
  Future<MutationExecutionResult> execute(QueuedMutation mutation);
}

/// Events emitted during mutation processing.
sealed class MutationProcessingEvent {
  const MutationProcessingEvent();
}

class MutationProcessingEventStarted extends MutationProcessingEvent {
  const MutationProcessingEventStarted();
}

class MutationProcessingEventCompleted extends MutationProcessingEvent {
  const MutationProcessingEventCompleted();
}

class MutationProcessingEventProcessing extends MutationProcessingEvent {
  final String mutationId;

  const MutationProcessingEventProcessing({required this.mutationId});
}

class MutationProcessingEventSuccess extends MutationProcessingEvent {
  final String mutationId;

  const MutationProcessingEventSuccess({required this.mutationId});
}

class MutationProcessingEventFailed extends MutationProcessingEvent {
  final String mutationId;
  final String error;
  final bool exhausted;

  const MutationProcessingEventFailed({
    required this.mutationId,
    required this.error,
    required this.exhausted,
  });
}

class MutationProcessingEventRetryScheduled extends MutationProcessingEvent {
  final String mutationId;
  final Duration delay;

  const MutationProcessingEventRetryScheduled({
    required this.mutationId,
    required this.delay,
  });
}

class MutationProcessingEventSkipped extends MutationProcessingEvent {
  final String mutationId;
  final String reason;

  const MutationProcessingEventSkipped({
    required this.mutationId,
    required this.reason,
  });
}

class MutationProcessingEventEnqueued extends MutationProcessingEvent {
  final String mutationId;

  const MutationProcessingEventEnqueued({required this.mutationId});
}

class MutationProcessingEventError extends MutationProcessingEvent {
  final String error;
  final String stackTrace;

  const MutationProcessingEventError({
    required this.error,
    required this.stackTrace,
  });
}

class MutationProcessingEventCancelled extends MutationProcessingEvent {
  const MutationProcessingEventCancelled();
}
