import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/trucker/data/trip_gps_capture_service.dart';
import 'package:tranzfort/src/features/trucker/data/trip_proof_upload_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_trip_action_provider.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_trip_detail_provider.dart';

class _ActionBackend implements TruckerTripsBackend {
  String stage;
  String? advancedTripId;
  String? advancedStage;
  double? advancedGpsLat;
  double? advancedGpsLng;
  String? uploadedTripId;
  String? uploadedPodPath;
  String? uploadedLrPath;
  String? uploadedStandaloneLrTripId;
  Object? error;

  _ActionBackend({this.stage = 'assigned'});

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
    stage = newStage;
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
    advancedGpsLat = gpsLat;
    advancedGpsLng = gpsLng;
    stage = 'proof_submitted';
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
    return <String, dynamic>{'id': tripId};
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required String truckerId,
    required String tripId,
  }) async {
    return {
      'id': tripId,
      'load_id': 'load-1',
      'supplier_id': 'supplier-1',
      'truck_id': 'truck-1',
      'stage': stage,
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'started_at': stage == 'in_transit' || stage == 'delivered' || stage == 'proof_submitted'
          ? '2026-03-09T08:00:00.000Z'
          : null,
      'delivered_at': stage == 'delivered' || stage == 'proof_submitted'
          ? '2026-03-10T10:00:00.000Z'
          : null,
      'pod_uploaded_at': stage == 'proof_submitted' ? '2026-03-10T11:00:00.000Z' : null,
      'completed_at': null,
      'lr_document_path': uploadedLrPath,
      'pod_document_path': stage == 'proof_submitted' ? uploadedPodPath : null,
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
  Future<List<Map<String, dynamic>>> fetchTrips({
    required String truckerId,
    required List<String> stages,
  }) async {
    return const <Map<String, dynamic>>[];
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
        'mobile': '+919876543210',
        'verification_status': 'verified',
      };

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;
}

class _FakeTripProofUploadService extends TripProofUploadService {
  final Result<String?> podResult;
  final Result<String?> lrResult;

  _FakeTripProofUploadService({
    required this.podResult,
    required this.lrResult,
  }) : super(null);

  @override
  Future<Result<String?>> pickCompressAndUploadPod({
    required String tripId,
    required ImageSource source,
  }) async {
    return podResult;
  }

  @override
  Future<Result<String?>> pickCompressAndUploadLr({
    required String tripId,
    required ImageSource source,
  }) async {
    return lrResult;
  }
}

TripGpsCaptureService _noGpsService() {
  return TripGpsCaptureService(
    isLocationServiceEnabledFn: () async => false,
    checkPermissionFn: () async => throw StateError('unused'),
    requestPermissionFn: () async => throw StateError('unused'),
    getCurrentPositionFn: () async => throw StateError('unused'),
  );
}

ProviderContainer _buildContainer({
  required _ActionBackend backend,
  required Result<String?> podUploadResult,
  required Result<String?> lrUploadResult,
}) {
  return ProviderContainer(
    overrides: [
      truckerTripsRepositoryProvider.overrideWithValue(
        TruckerTripsRepository(backend, () => 'trucker-1'),
      ),
      tripGpsCaptureServiceProvider.overrideWithValue(_noGpsService()),
      tripProofUploadServiceProvider.overrideWithValue(
        _FakeTripProofUploadService(
          podResult: podUploadResult,
          lrResult: lrUploadResult,
        ),
      ),
    ],
  );
}

void main() {
  test('trucker trip action provider advances stage and refreshes trip detail', () async {
    final backend = _ActionBackend(stage: 'assigned');
    final container = _buildContainer(
      backend: backend,
      podUploadResult: const Success<String?>(null),
      lrUploadResult: const Success<String?>(null),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(truckerTripActionProvider('trip-1').notifier)
        .advanceFromCurrentStage('assigned');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'pickup_pending');
    expect(backend.advancedTripId, 'trip-1');
    expect(backend.advancedStage, 'pickup_pending');
    expect(backend.advancedGpsLat, isNull);
    expect(container.read(truckerTripActionProvider('trip-1')).isSubmitting, isFalse);
    expect(container.read(truckerTripDetailProvider('trip-1')).detail?.stage, 'pickup_pending');
  });

  test('trucker trip action provider surfaces repository failures', () async {
    final backend = _ActionBackend(stage: 'assigned')
      ..error = const PostgrestException(message: 'Invalid stage transition from assigned to delivered');
    final container = _buildContainer(
      backend: backend,
      podUploadResult: const Success<String?>(null),
      lrUploadResult: const Success<String?>(null),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(truckerTripActionProvider('trip-1').notifier)
        .advanceFromCurrentStage('assigned');

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(container.read(truckerTripActionProvider('trip-1')).failure, isA<BusinessRuleFailure>());
    expect(container.read(truckerTripActionProvider('trip-1')).isSubmitting, isFalse);
  });

  test('trucker trip action provider uploads pod proof and refreshes trip detail', () async {
    final backend = _ActionBackend(stage: 'delivered');
    final container = _buildContainer(
      backend: backend,
      podUploadResult: const Success<String?>('trip-1/pod.jpg'),
      lrUploadResult: const Success<String?>(null),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(truckerTripActionProvider('trip-1').notifier)
        .uploadPodProof(ImageSource.gallery);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isTrue);
    expect(backend.uploadedTripId, 'trip-1');
    expect(backend.uploadedPodPath, 'trip-1/pod.jpg');
    expect(container.read(truckerTripDetailProvider('trip-1')).detail?.stage, 'proof_submitted');
  });

  test('trucker trip action provider treats cancelled proof pick as non-error', () async {
    final backend = _ActionBackend(stage: 'delivered');
    final container = _buildContainer(
      backend: backend,
      podUploadResult: const Success<String?>(null),
      lrUploadResult: const Success<String?>(null),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(truckerTripActionProvider('trip-1').notifier)
        .uploadPodProof(ImageSource.camera);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isFalse);
    expect(backend.uploadedTripId, isNull);
    expect(container.read(truckerTripActionProvider('trip-1')).failure, isNull);
  });

  test('trucker trip action provider surfaces proof upload service failure', () async {
    final backend = _ActionBackend(stage: 'delivered');
    final container = _buildContainer(
      backend: backend,
      podUploadResult: const Failure<String?>(
        BusinessRuleFailure(message: 'We could not prepare the POD image. Please try another photo.'),
      ),
      lrUploadResult: const Success<String?>(null),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(truckerTripActionProvider('trip-1').notifier)
        .uploadPodProof(ImageSource.gallery);

    expect(result.failureOrNull, isA<BusinessRuleFailure>());
    expect(backend.uploadedTripId, isNull);
    expect(container.read(truckerTripActionProvider('trip-1')).isSubmitting, isFalse);
  });

  test('trucker trip action provider uploads lr proof and refreshes trip detail', () async {
    final backend = _ActionBackend(stage: 'pickup_pending');
    final container = _buildContainer(
      backend: backend,
      podUploadResult: const Success<String?>(null),
      lrUploadResult: const Success<String?>('trip-1/lr.jpg'),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(truckerTripActionProvider('trip-1').notifier)
        .uploadLrProof(currentStage: 'pickup_pending', source: ImageSource.gallery);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isTrue);
    expect(backend.uploadedStandaloneLrTripId, 'trip-1');
    expect(backend.uploadedLrPath, 'trip-1/lr.jpg');
    expect(container.read(truckerTripDetailProvider('trip-1')).detail?.hasLrProof, isTrue);
  });
}
