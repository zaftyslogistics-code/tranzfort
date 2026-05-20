import 'package:supabase_flutter/supabase_flutter.dart';

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
    print('🔍 [SupabaseSupplierTripsBackend] fetchTrips() called');
    print('   supplierId: $supplierId');
    print('   stages: $stages');
    print('   limit: $limit');
    print('   offset: $offset');

    if (_client == null) {
      print('❌ [SupabaseSupplierTripsBackend] Client is null');
      throw const AuthException('Session unavailable');
    }

    print('   Using DIRECT TABLE READ (not RPC)');
    print('   Table: trips');
    print('   Query: SELECT id, load_id, trucker_id, truck_id, stage, assigned_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, load_snapshot_summary, loads(origin_label, destination_label, material) WHERE supplier_id=$supplierId AND stage IN ($stages) ORDER BY assigned_at DESC LIMIT $limit OFFSET $offset');

    try {
      var query = _client
          .from('trips')
          .select(
            'id, load_id, trucker_id, truck_id, stage, assigned_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, load_snapshot_summary, loads(origin_label, destination_label, material)',
          )
          .eq('supplier_id', supplierId)
          .inFilter('stage', stages)
          .order('assigned_at', ascending: false);

      if (limit > 0) {
        query = query.limit(limit);
      }
      if (offset > 0) {
        query = query.range(offset, offset + limit - 1);
      }

      final response = await query;
      print('   ✅ Query returned ${response.length} rows');
      print('   Response type: ${response.runtimeType}');
      if (response.isNotEmpty) {
        print('   First row type: ${response.first.runtimeType}');
        if (response.first is Map) {
          print('   First row keys: ${(response.first as Map).keys.toList()}');
        }
      }
      final filtered = response.whereType<Map<String, dynamic>>().toList(growable: false);
      print('   ✅ Filtered to ${filtered.length} Map rows');
      return filtered;
    } catch (error, stackTrace) {
      print('   ❌ Query failed: $error');
      print('   Error type: ${error.runtimeType}');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required String supplierId,
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('trips')
        .select(
          'id, load_id, trucker_id, truck_id, stage, assigned_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, load_snapshot_summary, loads(origin_label, destination_label, route_distance_km, route_duration_minutes, pickup_date), trucks(truck_number, body_type, tyres)',
        )
        .eq('supplier_id', supplierId)
        .eq('id', tripId)
        .maybeSingle();

    return response;
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client.from('profiles').select('id, full_name, mobile, verification_status, avatar_url, profile_photo_document_path').eq('id', truckerId).maybeSingle();
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({
    required String reviewerId,
    required String loadId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('ratings')
        .select('id, score, comment, created_at')
        .eq('reviewer_id', reviewerId)
        .eq('load_id', loadId)
        .maybeSingle();
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
  Future<Map<String, dynamic>?> fetchTripDetailConsolidated({
    required String supplierId,
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client.rpc(
      'get_supplier_trip_detail',
      params: <String, dynamic>{
        'p_trip_id': tripId,
        'p_supplier_id': supplierId,
      },
    ) as Map<String, dynamic>?;
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
    if (response is List && response.isNotEmpty && response.first is Map<String, dynamic>) {
      return response.first as Map<String, dynamic>;
    }
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
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
