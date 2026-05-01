import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';

class _FakeTripsBackend implements SupplierTripsBackend {
  List<Map<String, dynamic>> rows = const <Map<String, dynamic>>[];
  Map<String, dynamic>? detailRow;
  Map<String, dynamic>? ratingRow;
  Object? error;
  String? cancelledTripId;
  String? confirmedTripId;
  String? disputedTripId;
  String? disputeCategory;
  String? disputeReason;
  String? disputeAttachmentPath;
  String? submittedRatingLoadId;
  int? submittedRatingScore;
  String? submittedRatingComment;

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages, int limit = 15, int offset = 0}) async {
    if (error != null) {
      throw error!;
    }
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async {
    if (error != null) {
      throw error!;
    }
    return detailRow;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetailConsolidated({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => {
        'id': truckerId,
        'full_name': 'Ravi Trucker',
        'verification_status': 'verified',
      };

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
  Future<String?> createProofSignedUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> cancelTrip(String tripId) async {
    if (error != null) {
      throw error!;
    }
    cancelledTripId = tripId;
  }

  @override
  Future<void> confirmTripDelivery(String tripId) async {
    if (error != null) {
      throw error!;
    }
    confirmedTripId = tripId;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;

  @override
  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async {
    if (error != null) {
      throw error!;
    }
    disputedTripId = tripId;
    disputeCategory = category;
    disputeReason = reason;
    disputeAttachmentPath = attachmentPath;
    return 'support-ticket-1';
  }
}

void main() {
  test('supplier trips repository maps trip rows', () async {
    final backend = _FakeTripsBackend()
      ..rows = [
        {
          'id': 'trip-1',
          'load_id': 'load-1',
          'trucker_id': 'trucker-1',
          'truck_id': 'truck-1',
          'stage': 'in_transit',
          'assigned_at': '2026-03-08T12:00:00.000Z',
          'delivered_at': null,
          'pod_uploaded_at': null,
          'completed_at': null,
          'lr_document_path': 'proof/lr.pdf',
          'pod_document_path': null,
          'load_snapshot_summary': {
            'origin_label': 'Chandrapur, Maharashtra',
            'destination_label': 'Mumbai, Maharashtra',
            'material': 'Coal',
          },
        },
      ];
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.fetchTrips(SupplierTripsRepository.activeStages);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.routeLabel, 'Chandrapur, Maharashtra > Mumbai, Maharashtra');
    expect(result.valueOrNull!.first.proofStatus, 'LR uploaded');
  });

  test('supplier trips repository maps trip detail rows', () async {
    final backend = _FakeTripsBackend()
      ..detailRow = {
        'id': 'trip-1',
        'load_id': 'load-1',
        'trucker_id': 'trucker-1',
        'truck_id': 'truck-1',
        'stage': 'proof_submitted',
        'assigned_at': '2026-03-08T12:00:00.000Z',
        'delivered_at': '2026-03-10T10:00:00.000Z',
        'pod_uploaded_at': '2026-03-10T11:00:00.000Z',
        'completed_at': null,
        'lr_document_path': 'trip-1/lr.jpg',
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
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.fetchTripDetail('trip-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.routeLabel, 'Chandrapur, Maharashtra > Mumbai, Maharashtra');
    expect(result.valueOrNull?.podSignedUrl, 'https://example.com/trip-1/pod.jpg');
    expect(result.valueOrNull?.trucker.fullName, 'Ravi Trucker');
    expect(result.valueOrNull?.truckNumber, 'MH12AB1234');
  });

  test('supplier trips repository confirms trip delivery', () async {
    final backend = _FakeTripsBackend();
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.confirmTripDelivery('trip-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'completed');
    expect(backend.confirmedTripId, 'trip-1');
  });

  test('supplier trips repository cancels trip', () async {
    final backend = _FakeTripsBackend();
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.cancelTrip('trip-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'cancelled');
    expect(backend.cancelledTripId, 'trip-1');
  });

  test('supplier trips repository raises trip dispute', () async {
    final backend = _FakeTripsBackend();
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.raiseTripDispute(
      tripId: 'trip-1',
      category: 'document_mismatch',
      reason: 'POD image is unclear and unloading evidence does not match this trip.',
      attachmentPath: 'supplier-1/trip_dispute/evidence_1.jpg',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'support-ticket-1');
    expect(backend.disputedTripId, 'trip-1');
    expect(backend.disputeCategory, 'document_mismatch');
    expect(backend.disputeReason, contains('POD image is unclear'));
    expect(backend.disputeAttachmentPath, 'supplier-1/trip_dispute/evidence_1.jpg');
  });

  test('supplier trips repository fetches own rating', () async {
    final backend = _FakeTripsBackend()
      ..ratingRow = {
        'id': 'rating-1',
        'score': 5,
        'comment': 'Reliable trucker',
        'created_at': '2026-03-10T13:00:00.000Z',
      };
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.fetchOwnRating('load-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.score, 5);
    expect(result.valueOrNull?.comment, 'Reliable trucker');
  });

  test('supplier trips repository submits rating', () async {
    final backend = _FakeTripsBackend();
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.submitRating(
      loadId: 'load-1',
      score: 4,
      comment: 'Smooth coordination',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull?.score, 4);
    expect(backend.submittedRatingLoadId, 'load-1');
    expect(backend.submittedRatingScore, 4);
    expect(backend.submittedRatingComment, 'Smooth coordination');
  });

  test('supplier trips repository maps network failure', () async {
    final backend = _FakeTripsBackend()..error = const SocketException('offline');
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.fetchTrips(SupplierTripsRepository.activeStages);

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('supplier trips repository maps permission failure', () async {
    final backend = _FakeTripsBackend()..error = const PostgrestException(message: 'forbidden', code: '42501');
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');

    final result = await repository.fetchTrips(SupplierTripsRepository.activeStages);

    expect(result.failureOrNull, isA<PermissionFailure>());
  });
}
