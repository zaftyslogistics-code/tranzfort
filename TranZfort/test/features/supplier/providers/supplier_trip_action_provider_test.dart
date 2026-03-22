import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trip_action_provider.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trip_detail_provider.dart';

class _ActionBackend implements SupplierTripsBackend {
  String stage = 'proof_submitted';
  String? cancelledTripId;
  String? confirmedTripId;
  String? disputedTripId;
  String? disputeCategory;
  String? disputeReason;
  String? disputeAttachmentPath;
  Object? error;

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async {
    return {
      'id': tripId,
      'load_id': 'load-1',
      'trucker_id': 'trucker-1',
      'truck_id': 'truck-1',
      'stage': stage,
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'delivered_at': '2026-03-10T10:00:00.000Z',
      'pod_uploaded_at': '2026-03-10T11:00:00.000Z',
      'completed_at': stage == 'completed' ? '2026-03-10T12:00:00.000Z' : null,
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
        'verification_status': 'verified',
      };

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> cancelTrip(String tripId) async {
    if (error != null) {
      throw error!;
    }
    cancelledTripId = tripId;
    stage = 'cancelled';
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;

  @override
  Future<void> confirmTripDelivery(String tripId) async {
    if (error != null) {
      throw error!;
    }
    confirmedTripId = tripId;
    stage = 'completed';
  }

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
    stage = 'disputed';
    return 'support-ticket-1';
  }
}

void main() {
  test('supplier trip action provider cancels trip and refreshes detail', () async {
    final backend = _ActionBackend()
      ..stage = 'in_transit';
    final container = ProviderContainer(
      overrides: [
        supplierTripsRepositoryProvider.overrideWithValue(
          SupplierTripsRepository(backend, () => 'supplier-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(supplierTripActionProvider('trip-1').notifier).cancelTrip();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'cancelled');
    expect(backend.cancelledTripId, 'trip-1');
    expect(container.read(supplierTripDetailProvider('trip-1')).detail?.stage, 'cancelled');
  });

  test('supplier trip action provider confirms delivery and refreshes detail', () async {
    final backend = _ActionBackend();
    final container = ProviderContainer(
      overrides: [
        supplierTripsRepositoryProvider.overrideWithValue(
          SupplierTripsRepository(backend, () => 'supplier-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(supplierTripActionProvider('trip-1').notifier).confirmDelivery();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'completed');
    expect(backend.confirmedTripId, 'trip-1');
    expect(container.read(supplierTripDetailProvider('trip-1')).detail?.stage, 'completed');
  });

  test('supplier trip action provider surfaces repository failures', () async {
    final backend = _ActionBackend()
      ..error = const PostgrestException(message: 'Trip not in proof_submitted stage');
    final container = ProviderContainer(
      overrides: [
        supplierTripsRepositoryProvider.overrideWithValue(
          SupplierTripsRepository(backend, () => 'supplier-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(supplierTripActionProvider('trip-1').notifier).confirmDelivery();

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(container.read(supplierTripActionProvider('trip-1')).isSubmitting, isFalse);
  });

  test('supplier trip action provider raises dispute and refreshes detail', () async {
    final backend = _ActionBackend();
    final container = ProviderContainer(
      overrides: [
        supplierTripsRepositoryProvider.overrideWithValue(
          SupplierTripsRepository(backend, () => 'supplier-1'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(supplierTripActionProvider('trip-1').notifier).raiseDispute(
          category: 'document_mismatch',
          reason: 'POD image is unclear and unloading proof does not match quantity.',
          attachmentPath: 'supplier-1/trip_dispute/evidence_1.jpg',
        );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'support-ticket-1');
    expect(backend.disputedTripId, 'trip-1');
    expect(backend.disputeCategory, 'document_mismatch');
    expect(backend.disputeReason, contains('POD image is unclear'));
    expect(backend.disputeAttachmentPath, 'supplier-1/trip_dispute/evidence_1.jpg');
    expect(container.read(supplierTripDetailProvider('trip-1')).detail?.stage, 'disputed');
  });
}
