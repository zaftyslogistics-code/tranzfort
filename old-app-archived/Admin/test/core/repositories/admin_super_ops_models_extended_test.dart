import 'package:admin/src/core/repositories/splitted/super_ops_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('super ops summary/detail models', () {
    test('SuperOpsLoadSummary stores route + status metadata', () {
      final item = SuperOpsLoadSummary(
        id: 'load-1',
        routeLabel: 'Mumbai -> Pune',
        material: 'Steel',
        weightTonnes: 15,
        price: 32000,
        requiredTruckType: 'open_body',
        trucksNeeded: 2,
        trucksBooked: 1,
        supplierName: 'Supplier One',
        status: 'active',
        superStatus: 'processing',
        pickupDate: DateTime(2026, 2, 28),
        createdAt: DateTime(2026, 2, 27),
      );

      expect(item.id, 'load-1');
      expect(item.routeLabel, contains('Mumbai'));
      expect(item.trucksNeeded, 2);
      expect(item.trucksBooked, 1);
      expect(item.superStatus, 'processing');
    });

    test('SuperOpsLoadDetail stores nested supplier/payout/assignment models', () {
      final detail = SuperOpsLoadDetail(
        id: 'load-1',
        routeLabel: 'Mumbai -> Pune',
        originLat: 19.0760,
        originLng: 72.8777,
        material: 'Steel',
        weightTonnes: 20,
        price: 45000,
        priceType: 'fixed',
        advancePercentage: 30,
        pickupDate: DateTime(2026, 2, 28),
        requiredTruckType: 'container',
        requiredTyres: const [10, 12],
        trucksNeeded: 3,
        trucksBooked: 2,
        status: 'in_transit',
        superStatus: 'pod_uploaded',
        podPhotoUrl: 'https://example.com/pod.jpg',
        lrPhotoUrl: 'https://example.com/lr.jpg',
        createdAt: DateTime(2026, 2, 27),
        supplier: const SuperOpsSupplierInfo(
          id: 'supplier-1',
          fullName: 'Supplier One',
          companyName: 'S1 Logistics',
          mobile: '9999999999',
          email: 's1@example.com',
          verificationStatus: 'verified',
          gstNumber: 'GST123',
        ),
        payout: const SuperOpsPayoutInfo(
          accountHolderName: 'Supplier One',
          accountNumberLast4: '1234',
          ifscCode: 'SBIN0001',
          bankName: 'SBI',
          status: 'verified',
        ),
        assignments: const [
          SuperOpsAssignmentSummary(
            childLoadId: 'child-1',
            truckerId: 'trucker-1',
            truckerName: 'Trucker One',
            truckId: 'truck-1',
            truckNumber: 'MH12AB1234',
          ),
        ],
      );

      expect(detail.requiredTyres, contains(10));
      expect(detail.supplier.companyName, 'S1 Logistics');
      expect(detail.payout.bankName, 'SBI');
      expect(detail.assignments.single.truckNumber, 'MH12AB1234');
    });
  });

  group('super ops candidate/option models', () {
    test('DispatchTruckerCandidate stores truck options', () {
      const candidate = DispatchTruckerCandidate(
        truckerId: 'trucker-1',
        truckerName: 'Trucker One',
        mobile: '9999999999',
        rating: 4.8,
        completedTrips: 140,
        superTruckerStatus: 'eligible',
        lastKnownLat: 18.5204,
        lastKnownLng: 73.8567,
        distanceKm: 7.2,
        trucks: [
          DispatchTruckOption(
            id: 'truck-1',
            truckNumber: 'MH12AB1234',
            bodyType: 'open_body',
            tyres: 10,
          ),
        ],
      );

      expect(candidate.rating, greaterThan(4));
      expect(candidate.trucks.single.truckNumber, 'MH12AB1234');
    });

    test('SuperOpsSupplierOption stores supplier display metadata', () {
      const option = SuperOpsSupplierOption(
        supplierId: 'supplier-1',
        supplierName: 'Supplier One',
        mobile: '9999999999',
        companyName: 'S1 Logistics',
      );

      expect(option.supplierId, 'supplier-1');
      expect(option.companyName, contains('Logistics'));
    });
  });
}
