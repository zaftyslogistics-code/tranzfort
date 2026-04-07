import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('verification type mappings', () {
    test('verificationTypeFromPath maps known values and rejects unknown', () {
      expect(
        verificationTypeFromPath('supplier'),
        VerificationEntityType.supplier,
      );
      expect(
        verificationTypeFromPath('trucker'),
        VerificationEntityType.trucker,
      );
      expect(verificationTypeFromPath('truck'), VerificationEntityType.truck);
      expect(verificationTypeFromPath('invalid'), isNull);
    });

    test('verificationTypePath returns stable route values', () {
      expect(verificationTypePath(VerificationEntityType.supplier), 'supplier');
      expect(verificationTypePath(VerificationEntityType.trucker), 'trucker');
      expect(verificationTypePath(VerificationEntityType.truck), 'truck');
    });

    test('verificationTypeLabel returns human-readable labels', () {
      expect(verificationTypeLabel(VerificationEntityType.supplier), 'Supplier');
      expect(verificationTypeLabel(VerificationEntityType.trucker), 'Trucker');
      expect(verificationTypeLabel(VerificationEntityType.truck), 'Truck');
    });
  });

  group('verification queue/detail models', () {
    test('VerificationQueueItem slaHoursRemaining uses 24h baseline', () {
      final item = VerificationQueueItem(
        id: 'q-1',
        type: VerificationEntityType.supplier,
        primaryLabel: 'Supplier 1',
        secondaryLabel: '9999999999',
        submittedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      );

      expect(item.slaHoursRemaining, closeTo(22, 0.2));
    });

    test('VerificationQueueItem slaHoursRemaining is zero when submittedAt is null', () {
      const item = VerificationQueueItem(
        id: 'q-2',
        type: VerificationEntityType.truck,
        primaryLabel: 'MH12AB1234',
        secondaryLabel: 'open | 10 tyres',
        submittedAt: null,
      );

      expect(item.slaHoursRemaining, 0);
    });

    test('VerificationQueues defaults to empty lists', () {
      const queues = VerificationQueues();
      expect(queues.suppliers, isEmpty);
      expect(queues.truckers, isEmpty);
      expect(queues.trucks, isEmpty);
    });
  });
}
