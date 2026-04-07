import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';

class _FakeSupplierLoadBackend implements SupplierLoadBackend {
  Object? error;
  Map<String, dynamic>? createdParams;
  String createLoadResult = 'load-1';
  List<Map<String, dynamic>> myLoads = const [];
  Map<String, dynamic>? loadDetail;
  List<Map<String, dynamic>> bookingRequests = const [];
  List<Map<String, dynamic>> linkedTrips = const [];
  String? cancelledLoadId;
  String? closedLoadId;
  String? approvedBookingId;
  String? rejectedBookingId;
  String? rejectedBookingReason;

  @override
  Future<String> createLoad(Map<String, dynamic> params) async {
    if (error != null) {
      throw error!;
    }
    createdParams = params;
    return createLoadResult;
  }

  @override
  Future<void> cancelLoad(String loadId) async {
    if (error != null) {
      throw error!;
    }
    cancelledLoadId = loadId;
  }

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {
    if (error != null) {
      throw error!;
    }
    closedLoadId = loadId;
  }

  @override
  Future<String> approveBookingRequest(String bookingId) async {
    if (error != null) {
      throw error!;
    }
    approvedBookingId = bookingId;
    return 'trip-1';
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({required String supplierId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return loadDetail;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({required String supplierId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return bookingRequests;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({required String supplierId, required String loadId}) async {
    if (error != null) {
      throw error!;
    }
    return linkedTrips;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({
    required String supplierId,
    required LoadFilters filters,
    required int page,
    required int pageSize,
  }) async {
    if (error != null) {
      throw error!;
    }
    return myLoads;
  }

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {
    if (error != null) {
      throw error!;
    }
    rejectedBookingId = bookingId;
    rejectedBookingReason = reason;
  }
}

CreateLoadDto _sampleCreateLoadDto() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  return CreateLoadDto(
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    originLat: 19.95,
    originLng: 79.29,
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
    destinationLat: 19.07,
    destinationLng: 72.87,
    routeDistanceKm: 820,
    routeDurationMinutes: 840,
    routePolyline: 'encoded',
    routeSnapshotSource: 'google',
    material: 'Coal',
    weightTonnes: 22,
    requiredBodyType: 'open',
    requiredTyres: const [10, 12],
    trucksNeeded: 2,
    priceAmount: 54000,
    priceType: 'per_ton',
    advancePercentage: 20,
    pickupDate: tomorrow,
  );
}

void main() {
  group('Supplier load models', () {
    test('LoadListItemDto maps backend payload to domain', () {
      final dto = LoadListItemDto.fromMap({
        'id': 'load-1',
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'material': 'Coal',
        'weight_tonnes': 22,
        'trucks_needed': 2,
        'trucks_booked': 1,
        'price_amount': 54000,
        'price_type': 'negotiable',
        'pickup_date': '2026-03-10',
        'status': 'active',
        'required_body_type': 'open',
        'required_tyres': [10, 12],
        'is_super_load': false,
        'super_status': 'none',
        'published_at': '2026-03-08T12:00:00.000Z',
      });

      final load = dto.toDomain();

      expect(load.id, 'load-1');
      expect(load.requiredTyres, [10, 12]);
      expect(load.status, 'active');
    });

    test('LoadDetailDto maps backend payload to detail domain', () {
      final dto = LoadDetailDto.fromMap({
        'id': 'load-1',
        'origin_label': 'Chandrapur, Maharashtra',
        'origin_city': 'Chandrapur',
        'origin_state': 'Maharashtra',
        'origin_lat': 19.95,
        'origin_lng': 79.29,
        'destination_label': 'Mumbai, Maharashtra',
        'destination_city': 'Mumbai',
        'destination_state': 'Maharashtra',
        'destination_lat': 19.07,
        'destination_lng': 72.87,
        'route_distance_km': 820,
        'route_duration_minutes': 840,
        'route_polyline': 'encoded',
        'route_snapshot_source': 'google',
        'material': 'Coal',
        'weight_tonnes': 22,
        'required_body_type': 'open',
        'required_tyres': [10, 12],
        'trucks_needed': 2,
        'trucks_booked': 1,
        'price_amount': 54000,
        'price_type': 'negotiable',
        'pickup_date': '2026-03-10',
        'status': 'active',
        'is_super_load': false,
        'super_status': 'none',
        'assigned_trucker_id': null,
        'assigned_truck_id': null,
        'published_at': '2026-03-08T12:00:00.000Z',
        'created_at': '2026-03-08T12:00:00.000Z',
        'updated_at': '2026-03-08T13:00:00.000Z',
      });

      final detail = dto.toDomain();

      expect(detail.summary.material, 'Coal');
      expect(detail.routeDistanceKm, 820);
      expect(detail.originCity, 'Chandrapur');
      expect(detail.parentLoadId, isNull);
    });

    test('LoadBookingRequest and LinkedTrip map backend payloads', () {
      final booking = LoadBookingRequest.fromMap({
        'id': 'booking-1',
        'load_id': 'load-1',
        'trucker_id': 'trucker-1',
        'truck_id': 'truck-1',
        'status': 'submitted',
        'decision_reason': null,
        'created_at': '2026-03-08T12:00:00.000Z',
        'decided_at': null,
        'trucker_name': 'Ravi Trucker',
        'trucker_verification_status': 'verified',
        'trucker_rating': 4.8,
        'truck_number': 'MH12AB1234',
        'truck_body_type': 'Open',
        'truck_tyres': 12,
        'truck_model_label': 'Tata 407',
      });
      final trip = LinkedTrip.fromMap({
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
          'origin_label': 'Chandrapur',
          'destination_label': 'Mumbai',
          'material': 'Coal',
        },
      });

      expect(booking.isSubmitted, isTrue);
      expect(booking.displayTruckerName, 'Ravi Trucker');
      expect(booking.displayTruckLabel, 'MH12AB1234 - Tata 407');
      expect(trip.routeLabel, 'Chandrapur > Mumbai');
      expect(trip.proofStatus, 'Proof pending');
    });
  });

  group('SupplierLoadRepository', () {
    test('createLoad validates payload and sends rpc params', () async {
      final backend = _FakeSupplierLoadBackend();
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final result = await repository.createLoad(_sampleCreateLoadDto());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 'load-1');
      expect(backend.createdParams?['p_material'], 'Coal');
      expect(backend.createdParams?['p_trucks_needed'], 2);
      expect(backend.createdParams?['p_price_type'], 'negotiable');
    });

    test('createLoad accepts legacy negotiable price type for compatibility', () async {
      final backend = _FakeSupplierLoadBackend();
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');
      final dto = CreateLoadDto(
        originLabel: _sampleCreateLoadDto().originLabel,
        originCity: _sampleCreateLoadDto().originCity,
        originState: _sampleCreateLoadDto().originState,
        originLat: _sampleCreateLoadDto().originLat,
        originLng: _sampleCreateLoadDto().originLng,
        destinationLabel: _sampleCreateLoadDto().destinationLabel,
        destinationCity: _sampleCreateLoadDto().destinationCity,
        destinationState: _sampleCreateLoadDto().destinationState,
        destinationLat: _sampleCreateLoadDto().destinationLat,
        destinationLng: _sampleCreateLoadDto().destinationLng,
        routeDistanceKm: _sampleCreateLoadDto().routeDistanceKm,
        routeDurationMinutes: _sampleCreateLoadDto().routeDurationMinutes,
        routePolyline: _sampleCreateLoadDto().routePolyline,
        routeSnapshotSource: _sampleCreateLoadDto().routeSnapshotSource,
        material: _sampleCreateLoadDto().material,
        weightTonnes: _sampleCreateLoadDto().weightTonnes,
        requiredBodyType: _sampleCreateLoadDto().requiredBodyType,
        requiredTyres: _sampleCreateLoadDto().requiredTyres,
        trucksNeeded: _sampleCreateLoadDto().trucksNeeded,
        priceAmount: _sampleCreateLoadDto().priceAmount,
        priceType: 'negotiable',
        advancePercentage: _sampleCreateLoadDto().advancePercentage,
        pickupDate: _sampleCreateLoadDto().pickupDate,
      );

      final result = await repository.createLoad(dto);

      expect(result.isSuccess, isTrue);
      expect(backend.createdParams?['p_price_type'], 'negotiable');
    });

    test('createLoad rejects invalid payloads', () async {
      final dto = CreateLoadDto(
        originLabel: '',
        originCity: '',
        originState: null,
        originLat: null,
        originLng: null,
        destinationLabel: '',
        destinationCity: '',
        destinationState: null,
        destinationLat: null,
        destinationLng: null,
        routeDistanceKm: null,
        routeDurationMinutes: null,
        routePolyline: null,
        routeSnapshotSource: null,
        material: '',
        weightTonnes: 0,
        requiredBodyType: null,
        requiredTyres: null,
        trucksNeeded: 0,
        priceAmount: 0,
        priceType: 'bad',
        advancePercentage: 101,
        pickupDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      final repository = SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1');

      final result = await repository.createLoad(dto);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('getMyLoads maps rows to domain loads', () async {
      final backend = _FakeSupplierLoadBackend()
        ..myLoads = [
          {
            'id': 'load-1',
            'origin_label': 'Chandrapur, Maharashtra',
            'destination_label': 'Mumbai, Maharashtra',
            'material': 'Coal',
            'weight_tonnes': 22,
            'trucks_needed': 2,
            'trucks_booked': 1,
            'price_amount': 54000,
            'price_type': 'negotiable',
            'pickup_date': '2026-03-10',
            'status': 'active',
            'required_body_type': 'open',
            'required_tyres': [10, 12],
            'is_super_load': false,
            'super_status': 'none',
            'published_at': '2026-03-08T12:00:00.000Z',
          },
        ];
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final result = await repository.getMyLoads(const LoadFilters(statuses: ['active']));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, hasLength(1));
      expect(result.valueOrNull?.first.material, 'Coal');
    });

    test('getLoadDetail returns notFound when missing', () async {
      final repository = SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1');

      final result = await repository.getLoadDetail('load-404');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('cancelLoad and closeFilledOutsideApp pass through success', () async {
      final backend = _FakeSupplierLoadBackend();
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final cancelResult = await repository.cancelLoad('load-1');
      final closeResult = await repository.closeFilledOutsideApp('load-2');

      expect(cancelResult.isSuccess, isTrue);
      expect(closeResult.isSuccess, isTrue);
      expect(backend.cancelledLoadId, 'load-1');
      expect(backend.closedLoadId, 'load-2');
    });

    test('getBookingRequests and getLinkedTrips map related detail data', () async {
      final backend = _FakeSupplierLoadBackend()
        ..bookingRequests = [
          {
            'id': 'booking-1',
            'load_id': 'load-1',
            'trucker_id': 'trucker-1',
            'truck_id': 'truck-1',
            'status': 'submitted',
            'decision_reason': null,
            'created_at': '2026-03-08T12:00:00.000Z',
            'decided_at': null,
            'trucker_name': 'Ravi Trucker',
            'trucker_verification_status': 'verified',
            'trucker_rating': 4.8,
            'truck_number': 'MH12AB1234',
            'truck_body_type': 'Open',
            'truck_tyres': 12,
            'truck_model_label': 'Tata 407',
          },
        ]
        ..linkedTrips = [
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
              'origin_label': 'Chandrapur',
              'destination_label': 'Mumbai',
              'material': 'Coal',
            },
          },
        ];
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final bookingsResult = await repository.getBookingRequests('load-1');
      final tripsResult = await repository.getLinkedTrips('load-1');

      expect(bookingsResult.isSuccess, isTrue);
      expect(bookingsResult.valueOrNull, hasLength(1));
      expect(bookingsResult.valueOrNull?.first.status, 'submitted');
      expect(bookingsResult.valueOrNull?.first.truckerName, 'Ravi Trucker');
      expect(bookingsResult.valueOrNull?.first.truckNumber, 'MH12AB1234');
      expect(tripsResult.isSuccess, isTrue);
      expect(tripsResult.valueOrNull, hasLength(1));
      expect(tripsResult.valueOrNull?.first.stage, 'assigned');
    });

    test('approveBookingRequest and rejectBookingRequest pass through success', () async {
      final backend = _FakeSupplierLoadBackend();
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final approveResult = await repository.approveBookingRequest('booking-1');
      final rejectResult = await repository.rejectBookingRequest('booking-2', reason: 'Truck timing does not match pickup window');

      expect(approveResult.isSuccess, isTrue);
      expect(approveResult.valueOrNull, 'trip-1');
      expect(rejectResult.isSuccess, isTrue);
      expect(backend.approvedBookingId, 'booking-1');
      expect(backend.rejectedBookingId, 'booking-2');
      expect(backend.rejectedBookingReason, 'Truck timing does not match pickup window');
    });

    test('maps network and business-rule errors', () async {
      final backend = _FakeSupplierLoadBackend()
        ..error = const SocketException('offline');
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final networkResult = await repository.getMyLoads(const LoadFilters());
      expect(networkResult.failureOrNull, isA<NetworkFailure>());

      backend.error = Exception('Load cannot be cancelled in current state');
      final businessResult = await repository.cancelLoad('load-1');
      expect(businessResult.failureOrNull, isA<ServerFailure>());
    });

    test('maps permission errors', () async {
      final backend = _FakeSupplierLoadBackend()
        ..error = const PostgrestException(message: 'forbidden', code: '42501');
      final repository = SupplierLoadRepository(backend, () => 'supplier-1');

      final result = await repository.getLoadDetail('load-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
