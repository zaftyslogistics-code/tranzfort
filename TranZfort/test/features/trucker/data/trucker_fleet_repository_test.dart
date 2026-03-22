import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_fleet_repository.dart';

class _FleetBackend implements TruckerFleetBackend {
  List<Map<String, dynamic>> trucks = <Map<String, dynamic>>[];
  Map<String, dynamic>? createdValues;
  Map<String, dynamic>? updatedValues;
  String? updatedTruckId;
  String? updatedOwnerId;

  @override
  Future<Map<String, dynamic>> createTruck(Map<String, dynamic> values) async {
    createdValues = values;
    return {'id': 'truck-new'};
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTrucks(String ownerId) async {
    return trucks;
  }

  @override
  Future<void> updateTruck({required String ownerId, required String truckId, required Map<String, dynamic> values}) async {
    updatedOwnerId = ownerId;
    updatedTruckId = truckId;
    updatedValues = values;
  }
}

void main() {
  group('TruckerFleetRepository', () {
    test('getMyTrucks maps review feedback and sorts newest first', () async {
      final backend = _FleetBackend()
        ..trucks = [
          {
            'id': 'truck-older',
            'truck_model_id': null,
            'truck_number': 'MH12AB1111',
            'body_type': 'Open',
            'tyres': 12,
            'capacity_tonnes': 25,
            'rc_document_path': 'owner/truck-older/rc/rc.jpg',
            'status': 'verified',
            'rejection_reason': null,
            'verification_feedback_json': null,
            'verified_at': '2026-03-10T10:00:00.000Z',
            'created_at': '2026-03-10T09:00:00.000Z',
            'updated_at': '2026-03-10T10:00:00.000Z',
            'truck_models': {
              'make': 'Tata',
              'model': 'Ace Gold',
            },
          },
          {
            'id': 'truck-newer',
            'truck_model_id': null,
            'truck_number': 'MH12AB2222',
            'body_type': 'Container',
            'tyres': 14,
            'capacity_tonnes': 30,
            'rc_document_path': 'owner/truck-newer/rc/rc.jpg',
            'status': 'rejected',
            'rejection_reason': 'RC image is blurred',
            'verification_feedback_json': {
              'summary': 'RC image is blurred',
              'next_step': 'Upload a clearer RC image and resubmit this truck.',
            },
            'verified_at': null,
            'created_at': '2026-03-10T11:00:00.000Z',
            'updated_at': '2026-03-10T12:00:00.000Z',
            'truck_models': {
              'make': 'Ashok Leyland',
              'model': 'Dost+',
            },
          },
        ];
      final repository = TruckerFleetRepository(backend, () => 'trucker-1');

      final result = await repository.getMyTrucks();

      expect(result.isSuccess, isTrue);
      final trucks = result.valueOrNull!;
      expect(trucks, hasLength(2));
      expect(trucks.first.id, 'truck-newer');
      expect(trucks.first.status, TruckerFleetTruckStatus.rejected);
      expect(trucks.first.reviewFeedback.summary, 'RC image is blurred');
      expect(trucks.first.reviewFeedback.nextStep, 'Upload a clearer RC image and resubmit this truck.');
      expect(trucks.first.modelLabel, 'Ashok Leyland Dost+');
    });

    test('updateTruck moves verified truck to edited pending reapproval', () async {
      final backend = _FleetBackend();
      final repository = TruckerFleetRepository(backend, () => 'trucker-1');
      final truck = TruckerFleetTruck(
        id: 'truck-1',
        truckModelId: null,
        truckNumber: 'MH12AB1234',
        bodyType: 'Open',
        tyres: 12,
        capacityTonnes: 25,
        rcDocumentPath: 'owner/truck-1/rc/rc.jpg',
        status: TruckerFleetTruckStatus.verified,
        rejectionReason: null,
        reviewFeedback: const TruckerFleetReviewFeedback(summary: null, nextStep: null),
        modelLabel: 'Tata Ace',
        verifiedAt: DateTime.parse('2026-03-10T10:00:00.000Z'),
        createdAt: DateTime.parse('2026-03-10T09:00:00.000Z'),
        updatedAt: DateTime.parse('2026-03-10T10:00:00.000Z'),
      );

      final result = await repository.updateTruck(
        existingTruck: truck,
        truckNumber: 'mh12ab9999',
        bodyType: 'Container',
        tyres: 14,
        capacityTonnes: 28,
        rcDocumentPath: 'owner/truck-1/rc/rc-updated.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(backend.updatedOwnerId, 'trucker-1');
      expect(backend.updatedTruckId, 'truck-1');
      expect(backend.updatedValues?['truck_number'], 'MH12AB9999');
      expect(backend.updatedValues?['status'], 'edited_pending_reapproval');
      expect(backend.updatedValues?['rejection_reason'], isNull);
      expect(backend.updatedValues?['verification_feedback_json'], isNull);
    });

    test('updateTruck resubmits rejected truck to pending review', () async {
      final backend = _FleetBackend();
      final repository = TruckerFleetRepository(backend, () => 'trucker-1');
      final truck = TruckerFleetTruck(
        id: 'truck-2',
        truckModelId: null,
        truckNumber: 'MH12AB7777',
        bodyType: 'Trailer',
        tyres: 18,
        capacityTonnes: 34,
        rcDocumentPath: 'owner/truck-2/rc/rc.jpg',
        status: TruckerFleetTruckStatus.rejected,
        rejectionReason: 'RC expired',
        reviewFeedback: const TruckerFleetReviewFeedback(summary: 'RC expired', nextStep: 'Upload the renewed RC.'),
        modelLabel: null,
        verifiedAt: null,
        createdAt: DateTime.parse('2026-03-10T08:00:00.000Z'),
        updatedAt: DateTime.parse('2026-03-10T09:00:00.000Z'),
      );

      final result = await repository.updateTruck(
        existingTruck: truck,
        truckNumber: 'MH12AB7777',
        bodyType: 'Trailer',
        tyres: 18,
        capacityTonnes: 34,
        rcDocumentPath: 'owner/truck-2/rc/rc-renewed.jpg',
      );

      expect(result.isSuccess, isTrue);
      expect(backend.updatedValues?['status'], 'pending');
      expect(backend.updatedValues?['verified_at'], isNull);
    });
  });
}
