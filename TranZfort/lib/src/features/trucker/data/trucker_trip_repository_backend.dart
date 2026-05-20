import 'package:supabase_flutter/supabase_flutter.dart';

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
    print('🔍 [SupabaseTruckerTripsBackend] fetchTrips() called');
    print('   truckerId: $truckerId');
    print('   stages: $stages');
    print('   limit: $limit');
    print('   offset: $offset');

    if (_client == null) {
      print('❌ [SupabaseTruckerTripsBackend] Client is null');
      throw const AuthException('Session unavailable');
    }

    print('   Calling RPC: get_trucker_trips');
    print('   Parameters: p_trucker_id=$truckerId, p_stage_filter=${stages.isEmpty ? null : stages}, p_limit=$limit, p_offset=$offset');

    try {
      final response = await _client.rpc(
        'get_trucker_trips',
        params: <String, dynamic>{
          'p_trucker_id': truckerId,
          'p_stage_filter': stages.isEmpty ? null : stages,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      print('   RPC response type: ${response.runtimeType}');
      print('   RPC response: $response');

      if (response is List) {
        print('   ✅ RPC returned List with ${response.length} items');
        if (response.isNotEmpty) {
          print('   First item type: ${response.first.runtimeType}');
          if (response.first is Map) {
            print('   First item keys: ${(response.first as Map).keys.toList()}');
          }
        }
        return List<Map<String, dynamic>>.from(response);
      } else {
        print('   ⚠️  RPC returned non-List type: ${response.runtimeType}');
        print('   Response value: $response');
        return const <Map<String, dynamic>>[];
      }
    } catch (error, stackTrace) {
      print('   ❌ RPC call failed: $error');
      print('   Error type: ${error.runtimeType}');
      print('   Stack trace: $stackTrace');
      rethrow;
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
      params: <String, dynamic>{'p_profile_id': supplierId},
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
    if (response is List && response.isNotEmpty && response.first is Map<String, dynamic>) {
      return response.first as Map<String, dynamic>;
    }
    if (response is Map<String, dynamic>) {
      return response;
    }
    return null;
  }
}
