import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/services/mutation_queue_processor.dart';
import 'package:tranzfort/src/core/services/mutation_queue_database.dart';
import 'package:tranzfort/src/core/models/mutation_queue.dart';

void main() {
  group('MutationQueueProcessor - Retry Delay Sequence', () {
    late MutationQueueProcessor processor;

    setUp(() {
      // Create processor with actual database singleton and fake executor
      // We only need it to test calculateBackoffDelay
      processor = MutationQueueProcessor(
        database: MutationQueueDatabase(),
        executor: _FakeExecutor(),
      );
    });

    tearDown(() {
      processor.dispose();
    });

    test('retry count 0 should return base delay (1s)', () {
      final delay = processor.calculateBackoffDelay(0);
      expect(delay.inSeconds, greaterThanOrEqualTo(0.9));
      expect(delay.inSeconds, lessThanOrEqualTo(1.1));
    });

    test('retry count 1 should return ~2s with jitter', () {
      final delay = processor.calculateBackoffDelay(1);
      // With 10% jitter, should be between 1.8s and 2.2s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(1800));
      expect(delay.inMilliseconds, lessThanOrEqualTo(2200));
    });

    test('retry count 2 should return ~4s with jitter', () {
      final delay = processor.calculateBackoffDelay(2);
      // With 10% jitter, should be between 3.6s and 4.4s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(3600));
      expect(delay.inMilliseconds, lessThanOrEqualTo(4400));
    });

    test('retry count 5 should return ~32s with jitter', () {
      final delay = processor.calculateBackoffDelay(5);
      // With 10% jitter, should be between 28.8s and 35.2s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(28800));
      expect(delay.inMilliseconds, lessThanOrEqualTo(35200));
    });

    test('retry count 6 should be clamped to max delay (60s) with jitter', () {
      final delay = processor.calculateBackoffDelay(6);
      // Should be clamped to max delay (60s) with jitter
      // With 10% jitter, should be between 54s and 60s
      expect(delay.inMilliseconds, greaterThanOrEqualTo(54000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(60000));
    });

    test('retry count 10 should be clamped to max delay (60s) with jitter', () {
      final delay = processor.calculateBackoffDelay(10);
      // Should be clamped to max delay (60s) with jitter
      expect(delay.inMilliseconds, greaterThanOrEqualTo(54000));
      expect(delay.inMilliseconds, lessThanOrEqualTo(60000));
    });

    test('delay increases exponentially with retry count', () {
      final delay0 = processor.calculateBackoffDelay(0);
      final delay1 = processor.calculateBackoffDelay(1);
      final delay2 = processor.calculateBackoffDelay(2);
      final delay3 = processor.calculateBackoffDelay(3);

      // Each retry should approximately double the delay
      expect(delay1.inMilliseconds, greaterThan(delay0.inMilliseconds));
      expect(delay2.inMilliseconds, greaterThan(delay1.inMilliseconds));
      expect(delay3.inMilliseconds, greaterThan(delay2.inMilliseconds));
    });

    test('jitter adds randomness to prevent thundering-herd', () {
      // Generate multiple delays for the same retry count
      final delays = List.generate(10, (i) => processor.calculateBackoffDelay(3));

      // Not all delays should be exactly the same
      final uniqueDelays = delays.toSet();
      expect(uniqueDelays.length, greaterThan(1));

      // All delays should be within reasonable bounds
      for (final delay in delays) {
        expect(delay.inMilliseconds, greaterThanOrEqualTo(7200)); // 8s * 0.9
        expect(delay.inMilliseconds, lessThanOrEqualTo(8800)); // 8s * 1.1
      }
    });
  });
}

// Test double for executor only
class _FakeExecutor implements MutationExecutor {
  @override
  Future<MutationExecutionResult> execute(QueuedMutation mutation) async {
    return MutationExecutionResult.success();
  }
}
