import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/load_detail_provider.dart';

class _FakeSupplierLoadBackend implements SupplierLoadBackend {
  Map<String, dynamic>? detailRow;
  List<Map<String, dynamic>> bookingRows = const [];
  List<Map<String, dynamic>> linkedTripRows = const [];
  String? cancelledLoadId;
  String? closedLoadId;
  String? approvedBookingId;
  String? rejectedBookingId;
  String? rejectedBookingReason;
  Object? error;

  @override
  Future<String> createLoad(Map<String, dynamic> params) async => 'load-new';

  @override
  Future<String> approveBookingRequest(String bookingId) async {
    if (error != null) {
      throw error!;
    }
    approvedBookingId = bookingId;
    if (bookingRows.isNotEmpty) {
      bookingRows = bookingRows
          .map((row) => row['id'] == bookingId ? {...row, 'status': 'approved', 'decided_at': '2026-03-08T13:00:00.000Z'} : row)
          .toList(growable: false);
      linkedTripRows = [
        {
          'id': 'trip-1',
          'load_id': 'child-load-1',
          'trucker_id': 'trucker-1',
          'truck_id': 'truck-1',
          'stage': 'assigned',
          'assigned_at': '2026-03-08T13:00:00.000Z',
          'delivered_at': null,
          'pod_uploaded_at': null,
          'completed_at': null,
          'lr_document_path': null,
          'pod_document_path': null,
          'loads': {
            'id': 'child-load-1',
            'parent_load_id': 'load-1',
            'origin_label': 'Ballarpur Yard',
            'destination_label': 'Nhava Sheva Port',
            'material': 'Coal',
          },
        },
      ];
    }
    return 'trip-1';
  }

  @override
  Future<void> cancelLoad(String loadId) async {
    if (error != null) {
      throw error!;
    }
    cancelledLoadId = loadId;
    if (detailRow != null) {
      detailRow = {...detailRow!, 'status': 'cancelled'};
    }
  }

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {
    if (error != null) {
      throw error!;
    }
    closedLoadId = loadId;
    if (detailRow != null) {
      detailRow = {...detailRow!, 'status': 'filled_outside_app'};
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({required String supplierId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return detailRow;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({required String supplierId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return bookingRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({required String supplierId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return linkedTripRows;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({required String supplierId, required LoadFilters filters, required int page, required int pageSize}) async => const <Map<String, dynamic>>[];

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {
    if (error != null) {
      throw error!;
    }
    rejectedBookingId = bookingId;
    rejectedBookingReason = reason;
    bookingRows = bookingRows
        .map((row) => row['id'] == bookingId ? {...row, 'status': 'rejected', 'decision_reason': reason, 'decided_at': '2026-03-08T13:00:00.000Z'} : row)
        .toList(growable: false);
  }
}

Map<String, dynamic> _detailRow(String status) {
  return {
    'id': 'load-1',
    'origin_label': 'Ballarpur Yard',
    'destination_label': 'Nhava Sheva Port',
    'origin_city': 'Chandrapur',
    'origin_state': 'Maharashtra',
    'origin_lat': 19.95,
    'origin_lng': 79.29,
    'destination_city': 'Mumbai',
    'destination_state': 'Maharashtra',
    'destination_lat': 19.07,
    'destination_lng': 72.87,
    'route_distance_km': 820,
    'route_duration_minutes': 840,
    'route_polyline': 'encoded',
    'route_snapshot_source': 'osrm',
    'material': 'Coal',
    'weight_tonnes': 22,
    'trucks_needed': 2,
    'trucks_booked': 1,
    'price_amount': 54000,
    'price_type': 'negotiable',
    'pickup_date': '2026-03-10',
    'status': status,
    'required_body_type': 'Open',
    'required_tyres': [10, 12],
    'is_super_load': false,
    'super_status': 'none',
    'published_at': '2026-03-08T12:00:00.000Z',
    'parent_load_id': null,
    'assigned_trucker_id': null,
    'assigned_truck_id': null,
    'created_at': '2026-03-08T12:00:00.000Z',
    'updated_at': '2026-03-08T12:00:00.000Z',
  };
}

Map<String, dynamic> _bookingRow(String status) {
  return {
    'id': 'booking-1',
    'load_id': 'load-1',
    'trucker_id': 'trucker-1',
    'truck_id': 'truck-1',
    'status': status,
    'decision_reason': null,
    'created_at': '2026-03-08T12:10:00.000Z',
    'decided_at': status == 'submitted' ? null : '2026-03-08T13:00:00.000Z',
    'trucker_name': 'Ravi Trucker',
    'trucker_verification_status': 'verified',
    'trucker_rating': 4.8,
    'truck_number': 'MH12AB1234',
    'truck_body_type': 'Open',
    'truck_tyres': 12,
    'truck_model_label': 'Tata 407',
  };
}

void main() {
  test('load detail provider loads detail on initialization', () async {
    final backend = _FakeSupplierLoadBackend()
      ..detailRow = _detailRow('active')
      ..bookingRows = [_bookingRow('submitted')];
    final controller = LoadDetailController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      'load-1',
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.detail, isNotNull);
    expect(controller.state.detail?.summary.id, 'load-1');
    expect(controller.state.bookingRequests, hasLength(1));
    expect(controller.state.bookingRequests.first.truckerName, 'Ravi Trucker');
    expect(controller.state.bookingRequests.first.truckNumber, 'MH12AB1234');
    expect(controller.state.isLoading, isFalse);
  });

  test('load detail provider cancels and reloads detail', () async {
    final backend = _FakeSupplierLoadBackend()..detailRow = _detailRow('active');
    final controller = LoadDetailController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      'load-1',
    );

    await Future<void>.delayed(Duration.zero);
    final result = await controller.cancelLoad();

    expect(result.isSuccess, isTrue);
    expect(backend.cancelledLoadId, 'load-1');
    expect(controller.state.detail?.summary.status, 'cancelled');
  });

  test('load detail provider closes filled outside app and reloads detail', () async {
    final backend = _FakeSupplierLoadBackend()..detailRow = _detailRow('active');
    final controller = LoadDetailController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      'load-1',
    );

    await Future<void>.delayed(Duration.zero);
    final result = await controller.closeFilledOutsideApp();

    expect(result.isSuccess, isTrue);
    expect(backend.closedLoadId, 'load-1');
    expect(controller.state.detail?.summary.status, 'filled_outside_app');
  });

  test('load detail provider approves booking and reloads linked trips', () async {
    final backend = _FakeSupplierLoadBackend()
      ..detailRow = _detailRow('active')
      ..bookingRows = [_bookingRow('submitted')];
    final controller = LoadDetailController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      'load-1',
    );

    await Future<void>.delayed(Duration.zero);
    final result = await controller.approveBookingRequest('booking-1');

    expect(result.isSuccess, isTrue);
    expect(backend.approvedBookingId, 'booking-1');
    expect(controller.state.linkedTrips, hasLength(1));
    expect(controller.state.bookingRequests.first.status, 'approved');
  });

  test('load detail provider rejects booking and reloads booking state', () async {
    final backend = _FakeSupplierLoadBackend()
      ..detailRow = _detailRow('active')
      ..bookingRows = [_bookingRow('submitted')];
    final controller = LoadDetailController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      'load-1',
    );

    await Future<void>.delayed(Duration.zero);
    final result = await controller.rejectBookingRequest('booking-1', reason: 'Timing mismatch for this shipment');

    expect(result.isSuccess, isTrue);
    expect(backend.rejectedBookingId, 'booking-1');
    expect(backend.rejectedBookingReason, 'Timing mismatch for this shipment');
    expect(controller.state.bookingRequests.first.status, 'rejected');
    expect(controller.state.bookingRequests.first.decisionReason, 'Timing mismatch for this shipment');
    expect(controller.state.bookingRequests.first.truckerName, 'Ravi Trucker');
  });

  test('load detail provider surfaces failure state', () async {
    final backend = _FakeSupplierLoadBackend()..error = Exception('boom');
    final controller = LoadDetailController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      'load-1',
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.failure, isA<ServerFailure>());
    expect(controller.state.detail, isNull);
  });
}
