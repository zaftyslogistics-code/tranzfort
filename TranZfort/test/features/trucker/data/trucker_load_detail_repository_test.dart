import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';

class _FakeTruckerLoadDetailBackend implements TruckerLoadDetailBackend {
  Map<String, dynamic>? loadRow;
  Map<String, dynamic>? supplierProfile;
  Map<String, dynamic>? supplierExtension;
  List<Map<String, dynamic>> approvedTruckRows = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> bookingRows = const <Map<String, dynamic>>[];
  Object? submitError;
  double? lastBookingGpsLat;
  double? lastBookingGpsLng;

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail(String loadId) async => loadRow;

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => supplierExtension;

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => supplierProfile;

  @override
  Future<List<Map<String, dynamic>>> fetchApprovedTrucks(String truckerId) async => approvedTruckRows;

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests(String truckerId, String loadId) async => bookingRows;

  @override
  Future<String> submitBookingRequest(
    String loadId,
    String truckId, {
    double? bookingGpsLat,
    double? bookingGpsLng,
  }) async {
    if (submitError != null) {
      throw submitError!;
    }
    lastBookingGpsLat = bookingGpsLat;
    lastBookingGpsLng = bookingGpsLng;
    return 'booking-1';
  }
}

Map<String, dynamic> _loadRow({String status = 'active'}) {
  return {
    'id': 'load-1',
    'supplier_id': 'supplier-1',
    'parent_load_id': null,
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
    'route_polyline': null,
    'route_snapshot_source': 'osrm',
    'material': 'Coal',
    'weight_tonnes': 22,
    'required_body_type': 'Open',
    'required_tyres': [10, 12],
    'trucks_needed': 2,
    'trucks_booked': 1,
    'price_amount': 54000,
    'price_type': 'negotiable',
    'advance_percentage': 30,
    'pickup_date': '2026-03-12',
    'status': status,
    'is_super_load': true,
    'super_status': 'active',
    'assigned_trucker_id': null,
    'assigned_truck_id': null,
    'published_at': '2026-03-08T12:00:00.000Z',
    'created_at': '2026-03-08T12:00:00.000Z',
    'updated_at': '2026-03-08T13:00:00.000Z',
  };
}

void main() {
  group('TruckerLoadDetailRepository', () {
    test('maps trucker-visible load detail and supplier summary', () async {
      final backend = _FakeTruckerLoadDetailBackend()
        ..loadRow = _loadRow()
        ..supplierProfile = {
          'id': 'supplier-1',
          'full_name': 'Amit Supplier',
          'verification_status': 'verified',
        }
        ..supplierExtension = {
          'id': 'supplier-1',
          'company_name': 'Amit Logistics',
        }
        ..bookingRows = [
          {
            'id': 'booking-9',
            'truck_id': 'truck-1',
            'status': 'submitted',
            'decision_reason': null,
            'created_at': '2026-03-08T15:00:00.000Z',
            'decided_at': null,
          },
        ]
        ..approvedTruckRows = [
          {
            'id': 'truck-1',
            'truck_number': 'MH12AB1234',
            'body_type': 'Open',
            'tyres': 12,
            'capacity_tonnes': 25,
            'truck_models': {
              'axles': 4,
              'payload_kg': 25000,
              'mileage_empty_kmpl': 5.0,
              'mileage_loaded_kmpl': 3.0,
            },
          },
        ];
      final repository = TruckerLoadDetailRepository(backend, () => 'trucker-1');

      final detailResult = await repository.fetchLoadDetail('load-1');
      final trucksResult = await repository.fetchApprovedTrucks();

      expect(detailResult.isSuccess, isTrue);
      expect(detailResult.valueOrNull?.supplier.companyName, 'Amit Logistics');
      expect(detailResult.valueOrNull?.latestBookingRequest?.status, 'submitted');
      expect(trucksResult.isSuccess, isTrue);
      expect(trucksResult.valueOrNull, hasLength(1));
      expect(trucksResult.valueOrNull?.first.bodyType, 'Open');
      expect(truckMatchesLoad(trucksResult.valueOrNull!.first, detailResult.valueOrNull!.summary), isTrue);
    });

    test('prefers profile photo path when avatar_url is missing', () async {
      final backend = _FakeTruckerLoadDetailBackend()
        ..loadRow = {
          ..._loadRow(),
          'supplier_avatar_url': null,
          'supplier_photo_path': 'profiles/supplier-1/photo.jpg',
        }
        ..supplierProfile = {
          'id': 'supplier-1',
          'full_name': 'Amit Supplier',
          'verification_status': 'verified',
          'profile_photo_document_path': 'profiles/supplier-1/photo.jpg',
        }
        ..supplierExtension = {
          'id': 'supplier-1',
          'company_name': 'Amit Logistics',
        };
      final repository = TruckerLoadDetailRepository(backend, () => 'trucker-1');

      final result = await repository.fetchLoadDetail('load-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.supplier.avatarUrl, 'profiles/supplier-1/photo.jpg');
    });

    test('returns not found for non-visible status', () async {
      final backend = _FakeTruckerLoadDetailBackend()
        ..loadRow = _loadRow(status: 'draft')
        ..supplierProfile = {
          'id': 'supplier-1',
          'full_name': 'Amit Supplier',
          'verification_status': 'verified',
        };
      final repository = TruckerLoadDetailRepository(backend, () => 'trucker-1');

      final result = await repository.fetchLoadDetail('load-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('maps booking conflict failure', () async {
      final backend = _FakeTruckerLoadDetailBackend()
        ..submitError = const PostgrestException(message: 'Already booked this load');
      final repository = TruckerLoadDetailRepository(backend, () => 'trucker-1');

      final result = await repository.submitBookingRequest('load-1', 'truck-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ConflictFailure>());
    });

    test('passes booking gps coordinates when provided', () async {
      final backend = _FakeTruckerLoadDetailBackend();
      final repository = TruckerLoadDetailRepository(backend, () => 'trucker-1');

      final result = await repository.submitBookingRequest(
        'load-1',
        'truck-1',
        bookingGpsLat: 19.95,
        bookingGpsLng: 79.30,
      );

      expect(result.isSuccess, isTrue);
      expect(backend.lastBookingGpsLat, 19.95);
      expect(backend.lastBookingGpsLng, 79.30);
    });
  });
}
