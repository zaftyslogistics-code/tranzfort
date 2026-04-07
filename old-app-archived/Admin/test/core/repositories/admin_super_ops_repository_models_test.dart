import 'package:admin/src/core/repositories/splitted/super_ops_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('super ops tab mappings', () {
    test('superOpsTabStatus maps each tab to expected DB status', () {
      expect(superOpsTabStatus(SuperOpsTab.requests), 'pending_approval');
      expect(superOpsTabStatus(SuperOpsTab.dispatch), 'processing');
      expect(superOpsTabStatus(SuperOpsTab.podReview), 'pod_review');
      expect(superOpsTabStatus(SuperOpsTab.completed), 'completed');
    });
  });

  group('super ops query/models', () {
    test('SuperOpsQueueQuery equality/hc are stable', () {
      const a = SuperOpsQueueQuery(tab: SuperOpsTab.dispatch, search: 'mumbai');
      const b = SuperOpsQueueQuery(tab: SuperOpsTab.dispatch, search: 'mumbai');
      const c = SuperOpsQueueQuery(tab: SuperOpsTab.requests, search: 'mumbai');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('SuperOpsQueueCounts has zero defaults', () {
      const counts = SuperOpsQueueCounts();
      expect(counts.requests, 0);
      expect(counts.dispatch, 0);
      expect(counts.podReview, 0);
      expect(counts.completed, 0);
    });

    test('SuperOpsPostLoadPayload stores payload fields', () {
      final payload = SuperOpsPostLoadPayload(
        supplierId: 'supplier-1',
        originCity: 'Mumbai',
        originState: 'MH',
        destCity: 'Pune',
        destState: 'MH',
        material: 'Steel',
        weightTonnes: 24,
        requiredTruckType: 'open',
        trucksNeeded: 2,
        price: 64000,
        priceType: 'negotiable',
        advancePercentage: 70,
        pickupDate: DateTime(2026, 2, 28),
      );

      expect(payload.supplierId, 'supplier-1');
      expect(payload.originCity, 'Mumbai');
      expect(payload.destCity, 'Pune');
      expect(payload.trucksNeeded, 2);
      expect(payload.advancePercentage, 70);
    });
  });
}
