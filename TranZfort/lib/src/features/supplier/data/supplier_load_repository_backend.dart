import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logger/app_logger.dart';
import 'supplier_load_models.dart';

abstract class SupplierLoadBackend {
  Future<String> createLoad(Map<String, dynamic> params);

  Future<List<Map<String, dynamic>>> fetchMyLoads({
    required String supplierId,
    required LoadFilters filters,
    required int page,
    required int pageSize,
  });

  Future<Map<String, dynamic>?> fetchLoadDetail({
    required String supplierId,
    required String loadId,
  });

  Future<List<Map<String, dynamic>>> fetchBookingRequests({
    required String supplierId,
    required String loadId,
  });

  Future<List<Map<String, dynamic>>> fetchLinkedTrips({
    required String supplierId,
    required String loadId,
  });

  Future<void> cancelLoad(String loadId);

  Future<void> closeLoadFilledOutsideApp(String loadId);

  Future<String> approveBookingRequest(String bookingId);

  Future<void> rejectBookingRequest(String bookingId, {String? reason});
}

class SupabaseSupplierLoadBackend implements SupplierLoadBackend {
  final SupabaseClient? _client;

  const SupabaseSupplierLoadBackend(this._client);

  @override
  Future<String> createLoad(Map<String, dynamic> params) async {
    if (_client == null) {
      throw const AuthException('Supplier session is not available');
    }

    final response = await _client.rpc('create_load', params: params);
    return response.toString();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({
    required String supplierId,
    required LoadFilters filters,
    required int page,
    required int pageSize,
  }) async {
    if (_client == null) {
      return const [];
    }

    dynamic query = _client
        .from('loads')
        .select(
          'id, origin_label, destination_label, material, weight_tonnes, trucks_needed, trucks_booked, price_amount, price_type, pickup_date, status, required_body_type, required_tyres, is_super_load, super_status, published_at',
        )
        .eq('supplier_id', supplierId);

    // Apply filters before order() to stay on PostgrestFilterBuilder
    if (filters.hasStatuses) {
      query = query.inFilter('status', filters.statuses);
    }

    if (filters.hasSearchQuery) {
      final queryValue = filters.searchQuery!.trim();
      query = query.or(
        'material.ilike.%$queryValue%,origin_city.ilike.%$queryValue%,destination_city.ilike.%$queryValue%,origin_label.ilike.%$queryValue%,destination_label.ilike.%$queryValue%',
      );
    }

    // Apply order and pagination after filters
    query = query.order('pickup_date', ascending: false);

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final response = await query.range(from, to);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({
    required String supplierId,
    required String loadId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('loads')
        .select(
          'id, parent_load_id, origin_label, origin_city, origin_state, origin_lat, origin_lng, destination_label, destination_city, destination_state, destination_lat, destination_lng, route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source, material, weight_tonnes, required_body_type, required_tyres, trucks_needed, trucks_booked, price_amount, price_type, advance_percentage, pickup_date, status, is_super_load, super_status, assigned_trucker_id, assigned_truck_id, published_at, created_at, updated_at',
        )
        .eq('supplier_id', supplierId)
        .eq('id', loadId)
        .maybeSingle();

    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({
    required String supplierId,
    required String loadId,
  }) async {
    AppLogger.info('🔍 [fetchBookingRequests] Starting - supplierId: $supplierId, loadId: $loadId');
    
    if (_client == null) {
      AppLogger.error('❌ [fetchBookingRequests] Client is null');
      throw const AuthException('Session unavailable');
    }

    try {
      AppLogger.info('📞 [fetchBookingRequests] Calling RPC get_supplier_booking_requests');
      AppLogger.info('   Parameters: p_load_id=$loadId');
      
      final response = await _client.rpc(
        'get_supplier_booking_requests',
        params: {'p_load_id': loadId},
      );
      
      AppLogger.info('📊 [fetchBookingRequests] RPC returned response type: ${response.runtimeType}');
      
      if (response is List) {
        AppLogger.info('✅ [fetchBookingRequests] RPC returned ${response.length} rows');
        return List<Map<String, dynamic>>.from(response);
      } else {
        AppLogger.warning('⚠️  [fetchBookingRequests] RPC returned non-list response: $response');
        return [];
      }
    } catch (error, stackTrace) {
      AppLogger.error('❌ [fetchBookingRequests] ERROR: $error');
      AppLogger.error('   Error type: ${error.runtimeType}');
      AppLogger.error('   Stack trace: $stackTrace');
      
      // Try to get more details from PostgrestException if available
      if (error.toString().contains('column') || error.toString().contains('does not exist')) {
        AppLogger.error('   🔍 This appears to be a database column error');
      }
      
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({
    required String supplierId,
    required String loadId,
  }) async {
    AppLogger.info('🔍 [fetchLinkedTrips] Starting - supplierId: $supplierId, loadId: $loadId');
    
    if (_client == null) {
      AppLogger.error('❌ [fetchLinkedTrips] Client is null');
      throw const AuthException('Session unavailable');
    }

    try {
      final relatedLoads = await _client
          .from('loads')
          .select('id, parent_load_id')
          .eq('supplier_id', supplierId)
          .or('id.eq.$loadId,parent_load_id.eq.$loadId');
      
      AppLogger.info('📊 [fetchLinkedTrips] Related loads query returned: ${relatedLoads.length} rows');

      final relatedLoadIds = relatedLoads
          .whereType<Map<String, dynamic>>()
          .map((row) => (row['id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);

      AppLogger.info('📋 [fetchLinkedTrips] Related load IDs: $relatedLoadIds');

      if (relatedLoadIds.isEmpty) {
        AppLogger.warning('⚠️  [fetchLinkedTrips] No related loads found, returning empty');
        return const <Map<String, dynamic>>[];
      }

      AppLogger.info('🔎 [fetchLinkedTrips] Querying trips table...');
      final response = await _client
          .from('trips')
          .select(
            'id, load_id, trucker_id, truck_id, stage, assigned_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, loads(id, parent_load_id, origin_label, destination_label, material)',
          )
          .eq('supplier_id', supplierId)
          .inFilter('load_id', relatedLoadIds)
          .order('assigned_at', ascending: false);

      AppLogger.info('✅ [fetchLinkedTrips] Trips query returned: ${response.length} rows');
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    } catch (error, stackTrace) {
      AppLogger.error('❌ [fetchLinkedTrips] ERROR: $error');
      AppLogger.error('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> cancelLoad(String loadId) async {
    if (_client == null) {
      throw const AuthException('Supplier session is not available');
    }

    await _client.rpc('cancel_load', params: {'p_load_id': loadId});
  }

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {
    if (_client == null) {
      throw const AuthException('Supplier session is not available');
    }

    await _client.rpc('close_load_filled_outside_app', params: {'p_load_id': loadId});
  }

  @override
  Future<String> approveBookingRequest(String bookingId) async {
    if (_client == null) {
      throw const AuthException('Supplier session is not available');
    }

    final response = await _client.rpc('approve_booking_request', params: {'p_booking_id': bookingId});
    return response.toString();
  }

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {
    if (_client == null) {
      throw const AuthException('Supplier session is not available');
    }

    await _client.rpc(
      'reject_booking_request',
      params: {'p_booking_id': bookingId, 'p_reason': reason},
    );
  }
}
