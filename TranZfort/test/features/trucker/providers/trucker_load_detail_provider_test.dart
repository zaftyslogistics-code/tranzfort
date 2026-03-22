import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tranzfort/src/features/trucker/data/trip_gps_capture_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_load_detail_provider.dart';

class _MutableTruckerLoadDetailBackend implements TruckerLoadDetailBackend {
  List<Map<String, dynamic>> bookingRows = const <Map<String, dynamic>>[];
  double? lastBookingGpsLat;
  double? lastBookingGpsLng;

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail(String loadId) async {
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
      'status': 'active',
      'is_super_load': true,
      'super_status': 'active',
      'assigned_trucker_id': null,
      'assigned_truck_id': null,
      'published_at': '2026-03-08T12:00:00.000Z',
      'created_at': '2026-03-08T12:00:00.000Z',
      'updated_at': '2026-03-08T13:00:00.000Z',
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => {
        'id': 'supplier-1',
        'company_name': 'Amit Logistics',
      };

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => {
        'id': 'supplier-1',
        'full_name': 'Amit Supplier',
        'verification_status': 'verified',
      };

  @override
  Future<List<Map<String, dynamic>>> fetchApprovedTrucks(String truckerId) async {
    return [
      {
        'id': 'truck-match',
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
      {
        'id': 'truck-other',
        'truck_number': 'MH14XY9876',
        'body_type': 'Trailer',
        'tyres': 10,
        'capacity_tonnes': 18,
        'truck_models': {
          'axles': 4,
          'payload_kg': 18000,
          'mileage_empty_kmpl': 5.0,
          'mileage_loaded_kmpl': 3.2,
        },
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests(String truckerId, String loadId) async => bookingRows;

  @override
  Future<String> submitBookingRequest(
    String loadId,
    String truckId, {
    double? bookingGpsLat,
    double? bookingGpsLng,
  }) async {
    lastBookingGpsLat = bookingGpsLat;
    lastBookingGpsLng = bookingGpsLng;
    bookingRows = [
      {
        'id': 'booking-1',
        'truck_id': truckId,
        'status': 'submitted',
        'decision_reason': null,
        'created_at': '2026-03-08T15:00:00.000Z',
        'decided_at': null,
      },
    ];
    return 'booking-1';
  }
}

TripGpsCaptureService _gpsService() {
  return TripGpsCaptureService(
    isLocationServiceEnabledFn: () async => true,
    checkPermissionFn: () async => LocationPermission.whileInUse,
    requestPermissionFn: () async => LocationPermission.whileInUse,
    getCurrentPositionFn: () async => Position(
      longitude: 79.30,
      latitude: 19.95,
      timestamp: DateTime(2026, 3, 10, 23),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    ),
  );
}

void main() {
  group('TruckerLoadDetailController', () {
    test('loads detail and auto-selects a matching truck', () async {
      final controller = TruckerLoadDetailController(
        TruckerLoadDetailRepository(_MutableTruckerLoadDetailBackend(), () => 'trucker-1'),
        _gpsService(),
        'load-1',
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.detail, isNotNull);
      expect(controller.state.approvedTrucks, hasLength(2));
      expect(controller.state.selectedTruckId, 'truck-match');
    });

    test('submits booking request and refreshes booking status', () async {
      final backend = _MutableTruckerLoadDetailBackend();
      final controller = TruckerLoadDetailController(
        TruckerLoadDetailRepository(backend, () => 'trucker-1'),
        _gpsService(),
        'load-1',
      );

      await Future<void>.delayed(Duration.zero);
      controller.selectTruck('truck-match');
      final result = await controller.submitBookingRequest();

      expect(result.isSuccess, isTrue);
      expect(backend.lastBookingGpsLat, 19.95);
      expect(backend.lastBookingGpsLng, 79.30);
      expect(controller.state.detail?.latestBookingRequest?.status, 'submitted');
      expect(controller.state.detail?.latestBookingRequest?.truckId, 'truck-match');
    });
  });
}
