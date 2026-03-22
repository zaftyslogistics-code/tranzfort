import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';

class _FakeTripsBackend implements TruckerTripsBackend {
  List<Map<String, dynamic>> rows = const <Map<String, dynamic>>[];
  Map<String, dynamic>? detailRow;
  Map<String, dynamic>? ratingRow;
  Map<String, dynamic>? lrUploadRow;
  Object? error;
  String? advancedTripId;
  String? advancedStage;
  double? advancedGpsLat;
  double? advancedGpsLng;
  String? uploadedTripId;
  String? uploadedPodPath;
  String? uploadedLrPath;
  String? uploadedStandaloneLrTripId;
  String? submittedRatingLoadId;
  int? submittedRatingScore;
  String? submittedRatingComment;

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String truckerId, required List<String> stages}) async {
    if (error != null) {
      throw error!;
    }
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String truckerId, required String tripId}) async {
    if (error != null) {
      throw error!;
    }
    return detailRow;
  }

  @override
  Future<void> advanceTripStage({
    required String tripId,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  }) async {
    if (error != null) {
      throw error!;
    }
    advancedTripId = tripId;
    advancedStage = newStage;
    advancedGpsLat = gpsLat;
    advancedGpsLng = gpsLng;
  }

  @override
  Future<Map<String, dynamic>?> uploadTripLr({
    required String tripId,
    required String lrPath,
  }) async {
    if (error != null) {
      throw error!;
    }
    uploadedStandaloneLrTripId = tripId;
    uploadedLrPath = lrPath;
    return lrUploadRow ?? <String, dynamic>{'id': tripId};
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({
    required String reviewerId,
    required String loadId,
  }) async {
    if (error != null) {
      throw error!;
    }
    return ratingRow;
  }

  @override
  Future<void> submitRating({
    required String loadId,
    required int score,
    String? comment,
  }) async {
    if (error != null) {
      throw error!;
    }
    submittedRatingLoadId = loadId;
    submittedRatingScore = score;
    submittedRatingComment = comment;
    ratingRow = {
      'id': 'rating-1',
      'score': score,
      'comment': comment,
      'created_at': '2026-03-10T13:00:00.000Z',
    };
  }

  @override
  Future<void> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  }) async {
    if (error != null) {
      throw error!;
    }
    uploadedTripId = tripId;
    uploadedPodPath = podPath;
    uploadedLrPath = lrPath;
    advancedGpsLat = gpsLat;
    advancedGpsLng = gpsLng;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => {
        'id': supplierId,
        'company_name': 'Amit Logistics',
      };

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => {
        'id': supplierId,
        'full_name': 'Amit Supplier',
        'verification_status': 'verified',
      };

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;
}

void main() {
  test('trucker trips repository maps trip rows', () async {
    final backend = _FakeTripsBackend()
      ..rows = [
        {
          'id': 'trip-1',
          'load_id': 'load-1',
          'truck_id': 'truck-1',
          'stage': 'proof_submitted',
          'assigned_at': '2026-03-08T12:00:00.000Z',
          'delivered_at': '2026-03-09T14:00:00.000Z',
          'pod_uploaded_at': '2026-03-09T16:00:00.000Z',
          'completed_at': null,
          'lr_document_path': 'proof/lr.pdf',
          'pod_document_path': 'proof/pod.pdf',
          'load_snapshot_summary': {
            'origin_label': 'Chandrapur, Maharashtra',
            'destination_label': 'Mumbai, Maharashtra',
            'material': 'Coal',
          },
          'trucks': {
            'truck_number': 'MH12AB1234',
          },
        },
      ];
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.fetchTrips(TruckerTripsRepository.activeStages);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.routeLabel, 'Chandrapur, Maharashtra → Mumbai, Maharashtra');
    expect(result.valueOrNull!.first.truckNumber, 'MH12AB1234');
    expect(result.valueOrNull!.first.proofStatus, 'POD uploaded');
  });

  test('trucker trips repository maps trip detail rows', () async {
    final backend = _FakeTripsBackend()
      ..detailRow = {
        'id': 'trip-1',
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
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.fetchTripDetail('trip-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.routeLabel, 'Chandrapur, Maharashtra → Mumbai, Maharashtra');
    expect(result.valueOrNull?.supplier.fullName, 'Amit Supplier');
    expect(result.valueOrNull?.truckBodyType, 'Open');
  });

  test('trucker trips repository advances trip stage with gps payload', () async {
    final backend = _FakeTripsBackend();
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.advanceTripStage(
      tripId: 'trip-1',
      currentStage: 'assigned',
      newStage: 'pickup_pending',
      gpsLat: 19.95,
      gpsLng: 79.30,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'pickup_pending');
    expect(backend.advancedTripId, 'trip-1');
    expect(backend.advancedStage, 'pickup_pending');
    expect(backend.advancedGpsLat, 19.95);
    expect(backend.advancedGpsLng, 79.30);
  });

  test('trucker trips repository uploads lr proof during pickup stages', () async {
    final backend = _FakeTripsBackend();
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.uploadTripLr(
      tripId: 'trip-1',
      currentStage: 'pickup_pending',
      lrPath: 'trip-1/lr.jpg',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'lr_uploaded');
    expect(backend.uploadedStandaloneLrTripId, 'trip-1');
    expect(backend.uploadedLrPath, 'trip-1/lr.jpg');
  });

  test('trucker trips repository rejects invalid requested next stage', () async {
    final backend = _FakeTripsBackend();
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.advanceTripStage(
      tripId: 'trip-1',
      currentStage: 'assigned',
      newStage: 'delivered',
    );

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(backend.advancedTripId, isNull);
  });

  test('trucker trips repository maps invalid stage transition as business rule failure', () async {
    final backend = _FakeTripsBackend()
      ..error = const PostgrestException(message: 'Invalid stage transition from assigned to delivered');
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.advanceTripStage(
      tripId: 'trip-1',
      currentStage: 'assigned',
      newStage: 'pickup_pending',
    );

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
  });

  test('trucker trips repository uploads pod proof', () async {
    final backend = _FakeTripsBackend();
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.uploadTripProof(
      tripId: 'trip-1',
      podPath: 'trip-1/pod.jpg',
      gpsLat: 19.95,
      gpsLng: 79.30,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'proof_submitted');
    expect(backend.uploadedTripId, 'trip-1');
    expect(backend.uploadedPodPath, 'trip-1/pod.jpg');
    expect(backend.advancedGpsLat, 19.95);
    expect(backend.advancedGpsLng, 79.30);
  });

  test('trucker trips repository fetches own rating', () async {
    final backend = _FakeTripsBackend()
      ..ratingRow = {
        'id': 'rating-1',
        'score': 4,
        'comment': 'Smooth unload',
        'created_at': '2026-03-10T13:00:00.000Z',
      };
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.fetchOwnRating('load-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.score, 4);
    expect(result.valueOrNull?.comment, 'Smooth unload');
  });

  test('trucker trips repository submits rating', () async {
    final backend = _FakeTripsBackend();
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.submitRating(
      loadId: 'load-1',
      score: 5,
      comment: 'Very professional supplier',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.score, 5);
    expect(backend.submittedRatingLoadId, 'load-1');
    expect(backend.submittedRatingScore, 5);
    expect(backend.submittedRatingComment, 'Very professional supplier');
  });

  test('trucker trips repository maps network failure', () async {
    final backend = _FakeTripsBackend()..error = const SocketException('offline');
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.fetchTrips(TruckerTripsRepository.activeStages);

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('trucker trips repository maps permission failure', () async {
    final backend = _FakeTripsBackend()..error = const PostgrestException(message: 'forbidden', code: '42501');
    final repository = TruckerTripsRepository(backend, () => 'trucker-1');

    final result = await repository.fetchTrips(TruckerTripsRepository.activeStages);

    expect(result.failureOrNull, isA<PermissionFailure>());
  });
}
