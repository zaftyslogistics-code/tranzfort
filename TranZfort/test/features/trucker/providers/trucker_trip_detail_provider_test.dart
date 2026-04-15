import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_trip_detail_provider.dart';

class _DetailBackend implements TruckerTripsBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String truckerId, required List<String> stages}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDetailWithSupplier({required String truckerId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String truckerId, required String tripId}) async {
    return {
      'id': tripId,
      'load_id': 'load-1',
      'supplier_id': 'supplier-1',
      'truck_id': 'truck-1',
      'stage': 'in_transit',
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'started_at': '2026-03-09T08:00:00.000Z',
      'delivered_at': null,
      'pod_uploaded_at': null,
      'completed_at': null,
      'lr_document_path': null,
      'pod_document_path': null,
      'load_snapshot_summary': {
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'material': 'Coal',
      },
      'loads': {
        'origin_label': 'Chandrapur, Maharashtra',
        'origin_city': 'Chandrapur',
        'origin_state': 'Maharashtra',
        'origin_lat': 19.95,
        'origin_lng': 79.30,
        'destination_label': 'Mumbai, Maharashtra',
        'destination_city': 'Mumbai',
        'destination_state': 'Maharashtra',
        'destination_lat': 19.07,
        'destination_lng': 72.87,
        'route_distance_km': 820,
        'route_duration_minutes': 780,
        'route_snapshot_source': 'osrm',
        'material': 'Coal',
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
  Future<void> advanceTripStage({
    required String tripId,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  }) async {}

  @override
  Future<void> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  }) async {}

  @override
  Future<Map<String, dynamic>?> uploadTripLr({
    required String tripId,
    required String lrPath,
  }) async => {'id': tripId};

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => {
        'id': supplierId,
        'company_name': 'Amit Logistics',
      };

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => {
        'id': supplierId,
        'full_name': 'Amit Supplier',
        'mobile': '+919876543210',
        'verification_status': 'verified',
      };

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;
}

void main() {
  test('trucker trip detail provider loads trip detail', () async {
    final controller = TruckerTripDetailController(
      TruckerTripsRepository(_DetailBackend(), () => 'trucker-1'),
      'trip-1',
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.detail, isNotNull);
    expect(controller.state.detail?.id, 'trip-1');
    expect(controller.state.detail?.truckNumber, 'MH12AB1234');
    expect(controller.state.detail?.supplier.fullName, 'Amit Supplier');
  });
}
