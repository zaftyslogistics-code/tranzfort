import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/rpc_response_parser.dart';
import '../../../core/utils/type_safety.dart';
import 'trucker_trip_repository_models.dart';

class SupabaseTruckerTripsBackend implements TruckerTripsBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerTripsBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({
    required String truckerId,
    required List<String> stages,
    int limit = 15,
    int offset = 0,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    // P3.4.1 — list trips via SECURITY DEFINER RPC (no direct trips table read).
    final filteredStages = stages
        .map((stage) => stage.trim().toLowerCase())
        .where((stage) => stage.isNotEmpty && stage != 'pod_uploaded')
        .toList(growable: false);

    final response = await _client.rpc(
      'get_trucker_trips',
      params: <String, dynamic>{
        'p_trucker_id': truckerId,
        'p_stage_filter': filteredStages.isEmpty ? null : filteredStages,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return parseRpcJsonbRowList(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required String truckerId,
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_trip_detail',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_trucker_id': truckerId,
      },
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetailWithSupplier({
    required String truckerId,
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_trip_detail_with_supplier',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_trucker_id': truckerId,
      },
    );

    if (response == null) {
      return null;
    }

    // RPC returns JSONB, parse if needed
    if (response is Map<String, dynamic>) {
      return response;
    }

    return null;
  }

  @override
  Future<void> advanceTripStage({
    required String tripId,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    await _client.rpc(
      'advance_trip_stage',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_new_stage': newStage,
        'p_gps_lat': gpsLat,
        'p_gps_lng': gpsLng,
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> uploadTripLr({
    required String tripId,
    required String lrPath,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'update_trip_lr',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_lr_document_path': lrPath,
      },
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<void> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    await _client.rpc(
      'upload_trip_proof',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_pod_path': podPath,
        'p_lr_path': lrPath,
        'p_gps_lat': gpsLat,
        'p_gps_lng': gpsLng,
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({
    required String reviewerId,
    required String loadId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_own_rating',
      params: <String, dynamic>{
        'p_reviewer_id': reviewerId,
        'p_load_id': loadId,
      },
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<void> submitRating({
    required String loadId,
    required int score,
    String? comment,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    await _client.rpc(
      'submit_rating',
      params: <String, dynamic>{
        'p_load_id': loadId,
        'p_score': score,
        'p_comment': comment,
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_public_profile',
      params: <String, dynamic>{'p_user_id': supplierId},
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_supplier_extension',
      params: <String, dynamic>{'p_supplier_id': supplierId},
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_trip_dispute_summary',
      params: <String, dynamic>{'p_trip_id': tripId},
    );
    final rows = parseRpcJsonbRowList(response);
    if (rows.isNotEmpty) {
      return rows.first;
    }
    return safeMap(response);
  }
}
