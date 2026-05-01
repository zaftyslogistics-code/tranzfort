import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trips_provider.dart';

class _FakeTripsBackend implements SupplierTripsBackend {
  final Map<String, List<Map<String, dynamic>>> rowsByStageKey;
  Object? error;

  _FakeTripsBackend(this.rowsByStageKey);

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages, int limit = 15, int offset = 0}) async {
    if (error != null) {
      throw error!;
    }
    return rowsByStageKey[stages.join('|')] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDetailConsolidated({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => null;

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

  Map<String, dynamic> _tripRow(String id, String stage) {
  return {
    'id': id,
    'load_id': 'load-$id',
    'trucker_id': 'trucker-$id',
    'truck_id': 'truck-$id',
    'stage': stage,
    'assigned_at': '2026-03-08T12:00:00.000Z',
    'delivered_at': null,
    'pod_uploaded_at': null,
    'completed_at': stage == 'completed' ? '2026-03-10T12:00:00.000Z' : null,
    'lr_document_path': null,
    'pod_document_path': stage == 'completed' ? 'proof/pod.pdf' : null,
    'load_snapshot_summary': {
      'origin_label': 'Chandrapur, Maharashtra',
      'destination_label': 'Mumbai, Maharashtra',
      'material': 'Coal',
    },
  };
}

void main() {
  test('supplier trips provider loads active trips initially', () async {
    final controller = SupplierTripsController(
      SupplierTripsRepository(
        _FakeTripsBackend({
          SupplierTripsRepository.activeStages.join('|'): [_tripRow('1', 'in_transit')],
        }),
        () => 'supplier-1',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.selectedTab, SupplierTripsTab.active);
    expect(controller.state.trips, hasLength(1));
    expect(controller.state.trips.first.stage, 'in_transit');
  });

  test('supplier trips provider switches to completed tab', () async {
    final controller = SupplierTripsController(
      SupplierTripsRepository(
        _FakeTripsBackend({
          SupplierTripsRepository.activeStages.join('|'): [_tripRow('1', 'in_transit')],
          SupplierTripsRepository.completedStages.join('|'): [_tripRow('2', 'completed')],
        }),
        () => 'supplier-1',
      ),
    );

    await Future<void>.delayed(Duration.zero);
    await controller.selectTab(SupplierTripsTab.completed);

    expect(controller.state.selectedTab, SupplierTripsTab.completed);
    expect(controller.state.trips, hasLength(1));
    expect(controller.state.trips.first.stage, 'completed');
  });

  test('supplier trips provider surfaces failures', () async {
    final backend = _FakeTripsBackend({})..error = Exception('boom');
    final controller = SupplierTripsController(
      SupplierTripsRepository(backend, () => 'supplier-1'),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.failure, isA<ServerFailure>());
    expect(controller.state.isLoading, isFalse);
  });
}
