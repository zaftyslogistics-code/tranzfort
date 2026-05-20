import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/lifecycle_status_constants.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/date_parser.dart';
import '../../../core/utils/map_readers.dart';
import 'supplier_trip_repository_models.dart';
import 'supplier_trip_repository_backend.dart';

export 'supplier_trip_repository_models.dart';
export 'supplier_trip_repository_backend.dart';

class SupplierTripsRepository {
  final SupplierTripsBackend _backend;
  final String? Function() _currentUserId;

  static const List<String> disputeCategories = <String>[
    'loaded_quantity_mismatch',
    'unloaded_quantity_mismatch',
    'document_mismatch',
    'non_payment',
    'fake_payout_proof',
    'delay_or_no_show',
    'damage_or_shortage',
    'abusive_behavior',
    'spam_or_scam',
    'other',
  ];

  static const List<String> activeStages = TripStages.inProgress;
  static const List<String> completedStages = TripStages.completed;

  const SupplierTripsRepository(this._backend, this._currentUserId);

  Future<Result<List<SupplierTrip>>> fetchTrips(
    List<String> stages, {
    int limit = 15,
    int offset = 0,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<SupplierTrip>>(UnauthorizedFailure());
    }

    try {
      // Filter out 'pod_uploaded' from stages as database enum doesn't support it
      final filteredStages = stages.where((stage) => stage != 'pod_uploaded').toList();
      final rows = await _backend.fetchTrips(
        supplierId: userId,
        stages: filteredStages,
        limit: limit,
        offset: offset,
      );
      return Success<List<SupplierTrip>>(
        rows.map(_mapTrip).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<SupplierTrip>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<SupplierTripRating?>> fetchOwnRating(String loadId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<SupplierTripRating?>(UnauthorizedFailure());
    }

    final normalizedLoadId = loadId.trim();
    if (normalizedLoadId.isEmpty) {
      return const Failure<SupplierTripRating?>(
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
        return const Success<SupplierTripRating?>(null);
      }
      return Success<SupplierTripRating?>(_mapRating(row));
    } catch (error, stackTrace) {
      return Failure<SupplierTripRating?>(_mapError(error, stackTrace));
    }
  }

  Future<Result<SupplierTripRating>> submitRating({
    required String loadId,
    required int score,
    String? comment,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<SupplierTripRating>(UnauthorizedFailure());
    }

    final normalizedLoadId = loadId.trim();
    if (normalizedLoadId.isEmpty) {
      return const Failure<SupplierTripRating>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'load_id': 'Load id is required'},
        ),
      );
    }
    if (score < 1 || score > 5) {
      return const Failure<SupplierTripRating>(
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
        return Failure<SupplierTripRating>(
          ratingResult.failureOrNull ?? const UnknownFailure(),
        );
      }
      return Success<SupplierTripRating>(ratingResult.valueOrNull!);
    } catch (error, stackTrace) {
      return Failure<SupplierTripRating>(_mapError(error, stackTrace));
    }
  }

  Future<Result<SupplierTripDetail>> fetchTripDetail(String tripId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<SupplierTripDetail>(UnauthorizedFailure());
    }

    final normalizedTripId = tripId.trim();
    if (normalizedTripId.isEmpty) {
      return const Failure<SupplierTripDetail>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }

    AppLogger.debug('Fetching trip detail: tripId=$normalizedTripId, supplierId=$userId', scope: 'supplier_trips');

    try {
      final consolidated = await _backend.fetchTripDetailConsolidated(
        supplierId: userId,
        tripId: normalizedTripId,
      );
      if (consolidated == null) {
        AppLogger.warning('Trip detail RPC returned null: tripId=$normalizedTripId', scope: 'supplier_trips');
        return const Failure<SupplierTripDetail>(NotFoundFailure());
      }

      final tripMap = consolidated['trip'] as Map<String, dynamic>?;
      if (tripMap == null) {
        AppLogger.warning('Trip detail missing trip map: tripId=$normalizedTripId', scope: 'supplier_trips');
        return const Failure<SupplierTripDetail>(NotFoundFailure());
      }

      final podPath = (tripMap['pod_document_path'] ?? '').toString().trim();
      final lrPath = (tripMap['lr_document_path'] ?? '').toString().trim();
      final podSignedUrl = podPath.isEmpty ? null : await _backend.createProofSignedUrl(podPath);
      final lrSignedUrl = lrPath.isEmpty ? null : await _backend.createProofSignedUrl(lrPath);

      AppLogger.debug('Trip detail loaded successfully: tripId=$normalizedTripId', scope: 'supplier_trips');

      return Success<SupplierTripDetail>(
        _mapTripDetailConsolidated(
          tripMap,
          consolidated,
          podSignedUrl: podSignedUrl,
          lrSignedUrl: lrSignedUrl,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to fetch trip detail: tripId=$normalizedTripId', scope: 'supplier_trips', error: error, stackTrace: stackTrace);
      return Failure<SupplierTripDetail>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> confirmTripDelivery(String tripId) async {
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

    try {
      await _backend.confirmTripDelivery(normalizedTripId);
      return const Success<String>('completed');
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> cancelTrip(String tripId) async {
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

    try {
      await _backend.cancelTrip(normalizedTripId);
      return const Success<String>('cancelled');
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final normalizedTripId = tripId.trim();
    final normalizedCategory = category.trim().toLowerCase();
    final normalizedReason = reason.trim();
    final normalizedAttachmentPath = attachmentPath?.trim();
    if (normalizedTripId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Trip id is required',
          fieldErrors: {'trip_id': 'Trip id is required'},
        ),
      );
    }
    if (!disputeCategories.contains(normalizedCategory)) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Select a valid dispute category.',
          fieldErrors: {'category': 'Select a valid dispute category.'},
        ),
      );
    }
    if (normalizedReason.length < 10) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Add at least 10 characters explaining the dispute.',
          fieldErrors: {'reason': 'Add at least 10 characters explaining the dispute.'},
        ),
      );
    }

    try {
      final ticketId = await _backend.raiseTripDispute(
        tripId: normalizedTripId,
        category: normalizedCategory,
        reason: normalizedReason,
        attachmentPath: normalizedAttachmentPath == null || normalizedAttachmentPath.isEmpty
            ? null
            : normalizedAttachmentPath,
      );
      return Success<String>(ticketId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  SupplierTrip _mapTrip(Map<String, dynamic> map) {
    final snapshot = map['load_snapshot_summary'];
    final snapshotMap = snapshot is Map<String, dynamic> ? snapshot : <String, dynamic>{};
    final loadMap = map['loads'] is Map<String, dynamic> ? map['loads'] as Map<String, dynamic> : <String, dynamic>{};
    final origin = (snapshotMap['origin_label'] ?? loadMap['origin_label'] ?? 'Load').toString();
    final destination = (snapshotMap['destination_label'] ?? loadMap['destination_label'] ?? '').toString();
    final material = (snapshotMap['material'] ?? loadMap['material'] ?? 'Material pending').toString();

    return SupplierTrip(
      id: (map['id'] ?? '').toString(),
      loadId: (map['load_id'] ?? '').toString(),
      routeLabel: destination.isEmpty ? origin : '$origin > $destination',
      material: material,
      stage: (map['stage'] ?? 'assigned').toString(),
      truckerId: (map['trucker_id'] ?? '').toString(),
      truckId: (map['truck_id'] ?? '').toString(),
      assignedAt: DateTime.tryParse((map['assigned_at'] ?? '').toString()) ?? DateTime.now(),
      deliveredAt: readDate(map['delivered_at']),
      podUploadedAt: readDate(map['pod_uploaded_at']),
      completedAt: readDate(map['completed_at']),
      hasLrProof: ((map['lr_document_path'] ?? '').toString()).trim().isNotEmpty,
      hasPodProof: ((map['pod_document_path'] ?? '').toString()).trim().isNotEmpty,
    );
  }

  SupplierTripDetail _mapTripDetailConsolidated(
    Map<String, dynamic> tripMap,
    Map<String, dynamic> consolidated, {
    required String? podSignedUrl,
    required String? lrSignedUrl,
  }) {
    final loadSnapshot = consolidated['load_snapshot'] is Map<String, dynamic>
        ? consolidated['load_snapshot'] as Map<String, dynamic>
        : <String, dynamic>{};
    final truckMap = consolidated['truck'] is Map<String, dynamic>
        ? consolidated['truck'] as Map<String, dynamic>
        : <String, dynamic>{};
    final truckerProfile = consolidated['trucker_profile'] is Map<String, dynamic>
        ? consolidated['trucker_profile'] as Map<String, dynamic>
        : <String, dynamic>{};
    final disputeSummary = consolidated['dispute_summary'] is Map<String, dynamic>
        ? consolidated['dispute_summary'] as Map<String, dynamic>
        : null;

    final origin = (loadSnapshot['origin_label'] ?? 'Load').toString();
    final destination = (loadSnapshot['destination_label'] ?? '').toString();
    final material = (loadSnapshot['material'] ?? 'Material pending').toString();

    return SupplierTripDetail(
      id: (tripMap['id'] ?? '').toString(),
      loadId: (tripMap['load_id'] ?? '').toString(),
      routeLabel: destination.isEmpty ? origin : '$origin > $destination',
      material: material,
      stage: (tripMap['stage'] ?? 'assigned').toString(),
      truckId: (tripMap['truck_id'] ?? '').toString(),
      truckNumber: (truckMap['truck_number'] ?? 'Truck pending').toString(),
      truckBodyType: truckMap['body_type']?.toString(),
      truckTyres: readInt(truckMap['tyres']),
      assignedAt: DateTime.tryParse((tripMap['assigned_at'] ?? '').toString()) ?? DateTime.now(),
      deliveredAt: readDate(tripMap['delivered_at']),
      podUploadedAt: readDate(tripMap['pod_uploaded_at']),
      completedAt: readDate(tripMap['completed_at']),
      originLabel: origin,
      destinationLabel: destination,
      routeDistanceKm: readDoubleNullable(loadSnapshot['route_distance_km']),
      routeDurationMinutes: readInt(loadSnapshot['route_duration_minutes']),
      pickupDate: readDate(loadSnapshot['pickup_date']),
      lrDocumentPath: nullableString(tripMap['lr_document_path']),
      podDocumentPath: nullableString(tripMap['pod_document_path']),
      lrSignedUrl: lrSignedUrl,
      podSignedUrl: podSignedUrl,
      disputeSummary: disputeSummary == null
          ? null
          : SupplierTripDisputeSummary(
              category: (disputeSummary['category'] ?? 'trip_dispute').toString(),
              status: (disputeSummary['status'] ?? 'open').toString(),
              updatedAt: readDate(disputeSummary['updated_at']) ?? DateTime.now(),
            ),
      trucker: SupplierTripTrucker(
        id: (truckerProfile['id'] ?? '').toString(),
        fullName: (truckerProfile['full_name'] ?? 'Trucker').toString(),
        mobile: nullableString(truckerProfile['mobile']),
        verificationStatus: (truckerProfile['verification_status'] ?? 'unknown').toString(),
        avatarUrl: nullableString(truckerProfile['avatar_url']),
      ),
    );
  }

  SupplierTripRating _mapRating(Map<String, dynamic> row) {
    return SupplierTripRating(
      id: (row['id'] ?? '').toString(),
      score: (row['score'] as num?)?.toInt() ?? 0,
      comment: nullableString(row['comment']),
      createdAt: safeParseDateTime(row['created_at']) ?? DateTime.now(),
    );
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final rawMessage = error.message.trim().toLowerCase();
      if (error.code == '42501' || rawMessage.contains('not your trip')) {
        return PermissionFailure(debugInfo: error.details?.toString());
      }
      if (rawMessage.contains('trip not found')) {
        return NotFoundFailure(debugInfo: error.details?.toString());
      }
      if (rawMessage.contains('trip not in proof_submitted stage')) {
        return const BusinessRuleFailure(
          message: 'This trip is no longer waiting for supplier confirmation. Refresh and try again.',
        );
      }
      if (rawMessage.contains('trip cannot be cancelled')) {
        return const BusinessRuleFailure(
          message: 'This trip can no longer be cancelled from its current stage.',
        );
      }
      if (rawMessage.contains('dispute reason too short')) {
        return const ValidationFailure(
          message: 'Add at least 10 characters explaining the dispute.',
          fieldErrors: {'reason': 'Add at least 10 characters explaining the dispute.'},
        );
      }
      if (rawMessage.contains('no completed trip found for rating')) {
        return const BusinessRuleFailure(
          message: 'This completed trip is not eligible for rating yet. Refresh and try again.',
        );
      }
      if (rawMessage.contains('already rated')) {
        return const BusinessRuleFailure(
          message: 'You have already rated this trip.',
        );
      }
    }
    return mapSupabaseError(error, stackTrace);
  }
}

final supplierTripsRepositoryProvider = Provider<SupplierTripsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierTripsRepository(
    SupabaseSupplierTripsBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
