import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trip_detail_provider.dart';

class _DetailBackend implements SupplierTripsBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages, int limit = 15, int offset = 0}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async {
    return {
      'id': tripId,
      'load_id': 'load-1',
      'trucker_id': 'trucker-1',
      'truck_id': 'truck-1',
      'stage': 'proof_submitted',
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'delivered_at': '2026-03-10T10:00:00.000Z',
      'pod_uploaded_at': '2026-03-10T11:00:00.000Z',
      'completed_at': null,
      'lr_document_path': null,
      'pod_document_path': 'trip-1/pod.jpg',
      'load_snapshot_summary': {
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'material': 'Coal',
      },
      'loads': {
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'route_distance_km': 820,
        'route_duration_minutes': 780,
        'pickup_date': '2026-03-12',
      },
      'trucks': {
        'truck_number': 'MH12AB1234',
        'body_type': 'Open',
        'tyres': 12,
      },
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => {
        'id': truckerId,
        'full_name': 'Ravi Trucker',
        'mobile': '+919999999999',
        'verification_status': 'verified',
      };

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> cancelTrip(String tripId) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;

  @override
  Future<void> confirmTripDelivery(String tripId) async {}

  @override
  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async => 'support-ticket-1';
}

void main() {
  test('supplier trip detail provider loads trip detail', () async {
    final controller = SupplierTripDetailController(
      SupplierTripsRepository(_DetailBackend(), () => 'supplier-1'),
      'trip-1',
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.detail, isNotNull);
    expect(controller.state.detail?.id, 'trip-1');
    expect(controller.state.detail?.trucker.fullName, 'Ravi Trucker');
    expect(controller.state.detail?.trucker.mobile, '+919999999999');
    expect(controller.state.detail?.podSignedUrl, 'https://example.com/trip-1/pod.jpg');
  });
}
