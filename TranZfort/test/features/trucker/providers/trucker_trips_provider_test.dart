import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_trips_provider.dart';

class _FakeTripsBackend implements TruckerTripsBackend {
  final Map<String, List<Map<String, dynamic>>> rowsByStageKey;
  Object? error;

  _FakeTripsBackend(this.rowsByStageKey);

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String truckerId, required List<String> stages}) async {
    if (error != null) {
      throw error!;
    }
    return rowsByStageKey[stages.join('|')] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String truckerId, required String tripId}) async => null;

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
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;
}

Map<String, dynamic> _tripRow(String id, String stage) {
  return {
    'id': id,
    'load_id': 'load-$id',
    'truck_id': 'truck-$id',
    'stage': stage,
    'assigned_at': '2026-03-08T12:00:00.000Z',
    'delivered_at': stage == 'completed' ? '2026-03-10T10:00:00.000Z' : null,
    'pod_uploaded_at': stage == 'completed' ? '2026-03-10T11:00:00.000Z' : null,
    'completed_at': stage == 'completed' ? '2026-03-10T12:00:00.000Z' : null,
    'lr_document_path': null,
    'pod_document_path': stage == 'completed' ? 'proof/pod.pdf' : null,
    'load_snapshot_summary': {
      'origin_label': 'Chandrapur, Maharashtra',
      'destination_label': 'Mumbai, Maharashtra',
      'material': 'Coal',
    },
    'trucks': {
      'truck_number': 'MH12AB1234',
    },
  };
}

void main() {
  test('trucker trips provider loads active trips initially', () async {
    final controller = TruckerTripsController(
      TruckerTripsRepository(
        _FakeTripsBackend({
          TruckerTripsRepository.activeStages.join('|'): [_tripRow('1', 'in_transit')],
        }),
        () => 'trucker-1',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.selectedTab, TruckerTripsTab.active);
    expect(controller.state.trips, hasLength(1));
    expect(controller.state.trips.first.stage, 'in_transit');
  });

  test('trucker trips provider switches to completed tab', () async {
    final controller = TruckerTripsController(
      TruckerTripsRepository(
        _FakeTripsBackend({
          TruckerTripsRepository.activeStages.join('|'): [_tripRow('1', 'in_transit')],
          TruckerTripsRepository.completedStages.join('|'): [_tripRow('2', 'completed')],
        }),
        () => 'trucker-1',
      ),
    );

    await Future<void>.delayed(Duration.zero);
    await controller.selectTab(TruckerTripsTab.completed);

    expect(controller.state.selectedTab, TruckerTripsTab.completed);
    expect(controller.state.trips, hasLength(1));
    expect(controller.state.trips.first.stage, 'completed');
  });

  test('trucker trips provider surfaces failures', () async {
    final backend = _FakeTripsBackend({})..error = Exception('boom');
    final controller = TruckerTripsController(
      TruckerTripsRepository(backend, () => 'trucker-1'),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.failure, isA<ServerFailure>());
    expect(controller.state.isLoading, isFalse);
  });
}
