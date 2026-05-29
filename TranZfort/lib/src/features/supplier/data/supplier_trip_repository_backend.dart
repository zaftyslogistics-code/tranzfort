import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/rpc_response_parser.dart';
import '../../../core/utils/type_safety.dart';
import 'supplier_trip_repository_models.dart';

class SupabaseSupplierTripsBackend implements SupplierTripsBackend {
  final SupabaseClient? _client;

  const SupabaseSupplierTripsBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({
    required String supplierId,
    required List<String> stages,
    int limit = 15,
    int offset = 0,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final filteredStages = stages
        .map((stage) => stage.trim().toLowerCase())
        .where((stage) => stage.isNotEmpty && stage != 'pod_uploaded')
        .toList(growable: false);

    final response = await _client.rpc(
      'get_supplier_trips',
      params: <String, dynamic>{
        'p_supplier_id': supplierId,
        'p_stage_filter': filteredStages.isEmpty ? null : filteredStages,
        'p_limit': limit,
        'p_offset': offset,
      },
    );

    return parseRpcJsonbRowList(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required String supplierId,
    required String tripId,
  }) async {
    final consolidated = await fetchTripDetailConsolidated(
      supplierId: supplierId,
      tripId: tripId,
    );
    return safeMap(consolidated?['trip']);
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetailConsolidated({
    required String supplierId,
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final result = await _client.rpc(
      'get_supplier_trip_detail',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_supplier_id': supplierId,
      },
    );

    if (result is Map<String, dynamic> && result.isNotEmpty) {
      return result;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_public_profile',
      params: <String, dynamic>{'p_user_id': truckerId},
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
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
      return;
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
  Future<String?> createProofSignedUrl(String path) async {
    if (_client == null || path.trim().isEmpty) {
      return null;
    }

    return _client.storage.from('trip-proof-documents').createSignedUrl(path, 3600);
  }

  @override
  Future<void> confirmTripDelivery(String tripId) async {
    if (_client == null) {
      return;
    }

    await _client.rpc('confirm_trip_delivery', params: <String, dynamic>{'p_trip_id': tripId});
  }

  @override
  Future<void> cancelTrip(String tripId) async {
    if (_client == null) {
      return;
    }

    await _client.rpc('cancel_trip', params: <String, dynamic>{'p_trip_id': tripId});
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

  @override
  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async {
    if (_client == null) {
      return '';
    }

    final response = await _client.rpc(
      'raise_trip_dispute',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_category': category,
        'p_reason': reason,
        'p_attachment_path': attachmentPath,
      },
    );
    return (response ?? '').toString();
  }
}
