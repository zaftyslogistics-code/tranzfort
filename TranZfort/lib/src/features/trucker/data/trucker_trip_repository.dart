import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/models/domain_statuses.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/map_readers.dart';
import 'trucker_trip_repository_models.dart';
import 'trucker_trip_repository_backend.dart';

export 'trucker_trip_repository_models.dart';
export 'trucker_trip_repository_backend.dart';

class TruckerTripsRepository {
  final TruckerTripsBackend _backend;
  final String? Function() _currentUserId;

  static const Map<TripStage, TripStage> nextStageByCurrentStage = <TripStage, TripStage>{
    TripStage.assigned: TripStage.pickupPending,
    TripStage.pickupPending: TripStage.pickedUp,
    TripStage.pickedUp: TripStage.inTransit,
    TripStage.inTransit: TripStage.delivered,
  };

  static const List<TripStage> activeTripStages = <TripStage>[
    TripStage.assigned,
    TripStage.pickupPending,
    TripStage.pickedUp,
    TripStage.inTransit,
    TripStage.delivered,
    TripStage.proofSubmitted,
    TripStage.disputed,
  ];

  static const List<TripStage> completedTripStages = <TripStage>[
    TripStage.completed,
    TripStage.cancelled,
  ];

  static List<String> get activeStages =>
      activeTripStages.map((stage) => stage.toDatabaseValue()).toList(growable: false);

  static List<String> get completedStages =>
      completedTripStages.map((stage) => stage.toDatabaseValue()).toList(growable: false);

  const TruckerTripsRepository(this._backend, this._currentUserId);

  static String? nextStageFor(String currentStage) {
    final stage = TripStage.fromDatabase(currentStage);
    final nextStage = stage == null ? null : nextStageByCurrentStage[stage];
    return nextStage?.toDatabaseValue();
  }

  Future<Result<List<TruckerTrip>>> fetchTrips(List<String> stages) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<TruckerTrip>>(UnauthorizedFailure());
    }

    try {
      final rows = await _backend.fetchTrips(truckerId: userId, stages: stages);
      return Success<List<TruckerTrip>>(
        rows.map(_mapTrip).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<TruckerTrip>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<TruckerTripDetail>> fetchTripDetail(String tripId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerTripDetail>(UnauthorizedFailure());
    }

    if (tripId.trim().isEmpty) {
      return const Failure<TruckerTripDetail>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }

    try {
      // Use consolidated RPC to fetch trip + supplier + dispute in single call
      final result = await _backend.fetchTripDetailWithSupplier(
        truckerId: userId,
        tripId: tripId.trim(),
      );

      if (result == null) {
        return const Failure<TruckerTripDetail>(NotFoundFailure());
      }

      final tripData = result['trip'] as Map<String, dynamic>?;
      final supplierProfile = result['supplier_profile'] as Map<String, dynamic>?;
      final supplierExtension = result['supplier_extension'] as Map<String, dynamic>?;
      final disputeSummary = result['dispute_summary'] as Map<String, dynamic>?;

      if (tripData == null || supplierProfile == null) {
        return const Failure<TruckerTripDetail>(NotFoundFailure());
      }

      return Success<TruckerTripDetail>(
        _mapTripDetail(
          tripData,
          supplierProfile,
          supplierExtension,
          disputeSummary,
        ),
      );
    } catch (error, stackTrace) {
      return Failure<TruckerTripDetail>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> advanceTripStage({
    required String tripId,
    required String currentStage,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedTripId = tripId.trim();
    if (normalizedTripId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }

    final expectedNextStage = nextStageFor(currentStage);
    if (expectedNextStage == null) {
      return const Failure<String>(
        BusinessRuleFailure(
          message: 'This trip can no longer be advanced from its current stage.',
        ),
      );
    }

    if (newStage.trim() != expectedNextStage) {
      return const Failure<String>(
        BusinessRuleFailure(
          message: 'This action is no longer available for the current trip stage.',
        ),
      );
    }

    try {
      await _backend.advanceTripStage(
        tripId: normalizedTripId,
        newStage: expectedNextStage,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
      );
      return Success<String>(expectedNextStage);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> uploadTripLr({
    required String tripId,
    required String currentStage,
    required String lrPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedTripId = tripId.trim();
    final normalizedLrPath = lrPath.trim();
    final normalizedStage = currentStage.trim();
    if (normalizedTripId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }
    if (normalizedLrPath.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'LR image is required',
          fieldErrors: {'lr_path': 'LR image is required'},
        ),
      );
    }
    if (normalizedStage != 'pickup_pending' && normalizedStage != 'picked_up') {
      return const Failure<String>(
        BusinessRuleFailure(
          message: 'LR upload is only available while pickup confirmation is in progress.',
        ),
      );
    }

    try {
      final row = await _backend.uploadTripLr(
        tripId: normalizedTripId,
        lrPath: normalizedLrPath,
      );
      if (row == null) {
        return const Failure<String>(
          BusinessRuleFailure(
            message: 'LR upload is no longer available for this trip state.',
          ),
        );
      }
      return const Success<String>('lr_uploaded');
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedTripId = tripId.trim();
    final normalizedPodPath = podPath.trim();
    if (normalizedTripId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }
    if (normalizedPodPath.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'POD image is required',
          fieldErrors: {'pod_path': 'POD image is required'},
        ),
      );
    }

    try {
      await _backend.uploadTripProof(
        tripId: normalizedTripId,
        podPath: normalizedPodPath,
        lrPath: lrPath,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
      );
      return const Success<String>('proof_submitted');
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<TruckerTripRating?>> fetchOwnRating(String loadId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerTripRating?>(UnauthorizedFailure());
    }

    final normalizedLoadId = loadId.trim();
    if (normalizedLoadId.isEmpty) {
      return const Failure<TruckerTripRating?>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'load_id': 'Load id is required'},
        ),
      );
    }

    try {
      final row = await _backend.fetchOwnRating(
        reviewerId: userId,
        loadId: normalizedLoadId,
      );
      if (row == null) {
        return const Success<TruckerTripRating?>(null);
      }
      return Success<TruckerTripRating?>(_mapRating(row));
    } catch (error, stackTrace) {
      return Failure<TruckerTripRating?>(_mapError(error, stackTrace));
    }
  }

  Future<Result<TruckerTripRating>> submitRating({
    required String loadId,
    required int score,
    String? comment,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerTripRating>(UnauthorizedFailure());
    }

    final normalizedLoadId = loadId.trim();
    if (normalizedLoadId.isEmpty) {
      return const Failure<TruckerTripRating>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'load_id': 'Load id is required'},
        ),
      );
    }
    if (score < 1 || score > 5) {
      return const Failure<TruckerTripRating>(
        ValidationFailure(
          message: 'Select a rating between 1 and 5 stars',
          fieldErrors: {'score': 'Select a rating between 1 and 5 stars'},
        ),
      );
    }

    try {
      await _backend.submitRating(
        loadId: normalizedLoadId,
        score: score,
        comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      );
      final ratingResult = await fetchOwnRating(normalizedLoadId);
      if (ratingResult.isFailure || ratingResult.valueOrNull == null) {
        return Failure<TruckerTripRating>(
          ratingResult.failureOrNull ?? const UnknownFailure(),
        );
      }
      return Success<TruckerTripRating>(ratingResult.valueOrNull!);
    } catch (error, stackTrace) {
      return Failure<TruckerTripRating>(_mapError(error, stackTrace));
    }
  }

  TruckerTrip _mapTrip(Map<String, dynamic> map) {
    final snapshot = map['load_snapshot_summary'];
    final snapshotMap = snapshot is Map<String, dynamic> ? snapshot : <String, dynamic>{};
    final loadMap = map['loads'] is Map<String, dynamic> ? map['loads'] as Map<String, dynamic> : <String, dynamic>{};
    final truckMap = map['trucks'] is Map<String, dynamic> ? map['trucks'] as Map<String, dynamic> : <String, dynamic>{};
    final origin = (snapshotMap['origin_label'] ?? loadMap['origin_label'] ?? 'Load').toString();
    final destination = (snapshotMap['destination_label'] ?? loadMap['destination_label'] ?? '').toString();
    final material = (snapshotMap['material'] ?? loadMap['material'] ?? 'Material pending').toString();

    return TruckerTrip(
      id: (map['id'] ?? '').toString(),
      loadId: (map['load_id'] ?? '').toString(),
      routeLabel: destination.isEmpty ? origin : '$origin > $destination',
      originLabel: origin,
      destinationLabel: destination.isEmpty ? null : destination,
      originLat: readDoubleNullable(loadMap['origin_lat']),
      originLng: readDoubleNullable(loadMap['origin_lng']),
      destinationLat: readDoubleNullable(loadMap['destination_lat']),
      destinationLng: readDoubleNullable(loadMap['destination_lng']),
      material: material,
      stage: (map['stage'] ?? 'assigned').toString(),
      truckId: (map['truck_id'] ?? '').toString(),
      truckNumber: (truckMap['truck_number'] ?? 'Truck pending').toString(),
      assignedAt: DateTime.parse((map['assigned_at'] ?? '').toString()),
      deliveredAt: readDate(map['delivered_at']),
      podUploadedAt: readDate(map['pod_uploaded_at']),
      completedAt: readDate(map['completed_at']),
      hasLrProof: ((map['lr_document_path'] ?? '').toString()).trim().isNotEmpty,
      hasPodProof: ((map['pod_document_path'] ?? '').toString()).trim().isNotEmpty,
    );
  }

  TruckerTripRating _mapRating(Map<String, dynamic> map) {
    return TruckerTripRating(
      id: (map['id'] ?? '').toString(),
      score: _readIntNullable(map['score']) ?? 0,
      comment: nullableString(map['comment']),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
    );
  }

  TruckerTripDetail _mapTripDetail(
    Map<String, dynamic> map,
    Map<String, dynamic> supplierProfile,
    Map<String, dynamic>? supplierExtension,
    Map<String, dynamic>? disputeSummary,
  ) {
    final snapshot = map['load_snapshot_summary'];
    final snapshotMap = snapshot is Map<String, dynamic> ? snapshot : <String, dynamic>{};
    final loadMap = map['loads'] is Map<String, dynamic> ? map['loads'] as Map<String, dynamic> : <String, dynamic>{};
    final truckMap = map['trucks'] is Map<String, dynamic> ? map['trucks'] as Map<String, dynamic> : <String, dynamic>{};
    final originLabel = (snapshotMap['origin_label'] ?? loadMap['origin_label'] ?? 'Load').toString();
    final destinationLabel = (snapshotMap['destination_label'] ?? loadMap['destination_label'] ?? '').toString();
    final material = (snapshotMap['material'] ?? loadMap['material'] ?? 'Material pending').toString();

    return TruckerTripDetail(
      id: (map['id'] ?? '').toString(),
      loadId: (map['load_id'] ?? '').toString(),
      truckerId: (map['trucker_id'] ?? '').toString(),
      supplierId: (map['supplier_id'] ?? '').toString(),
      stage: (map['stage'] ?? 'assigned').toString(),
      routeLabel: destinationLabel.isEmpty ? originLabel : '$originLabel > $destinationLabel',
      material: material,
      truckId: (map['truck_id'] ?? '').toString(),
      truckNumber: (truckMap['truck_number'] ?? 'Truck pending').toString(),
      truckBodyType: nullableString(truckMap['body_type']),
      truckTyres: _readIntNullable(truckMap['tyres']),
      originLabel: originLabel,
      destinationLabel: destinationLabel,
      originCity: nullableString(loadMap['origin_city']),
      originState: nullableString(loadMap['origin_state']),
      originLat: readDoubleNullable(loadMap['origin_lat']),
      originLng: readDoubleNullable(loadMap['origin_lng']),
      destinationCity: nullableString(loadMap['destination_city']),
      destinationState: nullableString(loadMap['destination_state']),
      destinationLat: readDoubleNullable(loadMap['destination_lat']),
      destinationLng: readDoubleNullable(loadMap['destination_lng']),
      routeDistanceKm: readDouble(loadMap['route_distance_km']),
      routeDurationMinutes: _readIntNullable(loadMap['route_duration_minutes']),
      routeSnapshotSource: nullableString(loadMap['route_snapshot_source']),
      pickupDate: readDate(loadMap['pickup_date']),
      assignedAt: DateTime.parse((map['assigned_at'] ?? '').toString()),
      startedAt: readDate(map['started_at']),
      deliveredAt: readDate(map['delivered_at']),
      podUploadedAt: readDate(map['pod_uploaded_at']),
      completedAt: readDate(map['completed_at']),
      hasLrProof: ((map['lr_document_path'] ?? '').toString()).trim().isNotEmpty,
      hasPodProof: ((map['pod_document_path'] ?? '').toString()).trim().isNotEmpty,
      disputeSummary: disputeSummary == null
          ? null
          : TruckerTripDisputeSummary(
              category: (disputeSummary['category'] ?? 'trip_dispute').toString(),
              status: (disputeSummary['status'] ?? 'open').toString(),
              updatedAt: DateTime.parse((disputeSummary['updated_at'] ?? '').toString()),
            ),
      supplier: TruckerTripSupplierSummary(
        id: (supplierProfile['id'] ?? '').toString(),
        fullName: (supplierProfile['full_name'] ?? 'Supplier').toString(),
        companyName: nullableString(supplierExtension?['company_name']),
        mobile: nullableString(supplierProfile['mobile']),
        verificationStatus: (supplierProfile['verification_status'] ?? 'unverified').toString(),
      ),
    );
  }

  int? _readIntNullable(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      return _mapPostgrestFailure(error);
    }
    return mapSupabaseError(error, stackTrace);
  }

  AppFailure _mapPostgrestFailure(PostgrestException error) {
    final normalizedMessage = error.message.trim().toLowerCase();
    if (error.code == '42501' || normalizedMessage.contains('not your trip')) {
      return PermissionFailure(debugInfo: error.details?.toString());
    }
    if (error.code == '23505') {
      return const BusinessRuleFailure(message: 'You have already rated this trip.');
    }
    if (normalizedMessage.contains('trip not found') || error.code == 'PGRST116') {
      return NotFoundFailure(debugInfo: error.details?.toString());
    }
    if (normalizedMessage.contains('invalid stage transition')) {
      return const BusinessRuleFailure(
        message: 'This action is no longer available for the current trip stage.',
      );
    }
    if (normalizedMessage.contains('no completed trip found for rating')) {
      return const BusinessRuleFailure(
        message: 'Rating is available after the trip is completed.',
      );
    }
    if (normalizedMessage.contains('trip must be in delivered stage to upload proof')) {
      return const BusinessRuleFailure(
        message: 'Proof can only be uploaded after delivery is recorded.',
      );
    }

    return ServerFailure(debugInfo: error.details?.toString());
  }

  // Private helpers removed - using shared map_readers.dart helpers
}

final truckerTripsRepositoryProvider = Provider<TruckerTripsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerTripsRepository(
    SupabaseTruckerTripsBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
