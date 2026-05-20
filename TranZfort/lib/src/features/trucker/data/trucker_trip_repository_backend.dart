import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/lifecycle_status_constants.dart';
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

    var query = _client
        .from('trips')
        .select(
          'id, load_id, truck_id, stage, assigned_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, load_snapshot_summary, loads(origin_label, origin_lat, origin_lng, destination_label, destination_lat, destination_lng, material), trucks(truck_number)',
        )
        .eq('trucker_id', truckerId)
        .inFilter('stage', stages);

    if (limit > 0) {
      query = query.limit(limit);
    }
    if (offset > 0) {
      query = query.range(offset, offset + limit - 1);
    }

    final response = await query;
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    } else {
      return const <Map<String, dynamic>>[];
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({
    required String truckerId,
    required String tripId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('trips')
        .select(
          'id, load_id, supplier_id, truck_id, stage, assigned_at, started_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, load_snapshot_summary, loads(origin_label, origin_city, origin_state, origin_lat, origin_lng, destination_label, destination_city, destination_state, destination_lat, destination_lng, route_distance_km, route_duration_minutes, route_snapshot_source, material, pickup_date), trucks(truck_number, body_type, tyres)',
        )
        .eq('trucker_id', truckerId)
        .eq('id', tripId)
        .maybeSingle();

    return response;
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

    return _client
        .from('trips')
        .update(<String, dynamic>{
          'lr_document_path': lrPath,
        })
        .eq('id', tripId)
        .inFilter('stage', TripStages.allowsLrUpload)
        .select('id')
        .maybeSingle();
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

    final response = await _client
        .from('profiles')
        .select('id, full_name, verification_status, mobile')
        .eq('id', supplierId)
        .maybeSingle();

    return response;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('suppliers')
        .select('id, company_name')
        .eq('id', supplierId)
        .maybeSingle();

    return response;
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
    } else if (response is Map<String, dynamic>) {
      return response;
    } else {
      return null;
    }
  }
}
