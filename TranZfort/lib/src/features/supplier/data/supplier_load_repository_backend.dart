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
      AppLogger.warning('fetchMyLoads: Client is null', scope: 'supplier_load_backend');
      throw const AuthException('Supplier session is not available');
    }

    AppLogger.info('fetchMyLoads: Calling RPC get_supplier_loads_list', scope: 'supplier_load_backend');
    AppLogger.info('  supplierId: $supplierId', scope: 'supplier_load_backend');
    AppLogger.info('  statusFilter: ${(filters.hasStatuses && filters.statuses.isNotEmpty) ? filters.statuses : null}', scope: 'supplier_load_backend');
    AppLogger.info('  searchQuery: ${filters.hasSearchQuery ? filters.searchQuery!.trim() : null}', scope: 'supplier_load_backend');
    AppLogger.info('  limit: $pageSize', scope: 'supplier_load_backend');
    AppLogger.info('  offset: ${(page - 1) * pageSize}', scope: 'supplier_load_backend');

    try {
      final response = await _client.rpc(
        'get_supplier_loads_list',
        params: <String, dynamic>{
          'p_supplier_id': supplierId,
          'p_status_filter': (filters.hasStatuses && filters.statuses.isNotEmpty) ? filters.statuses : null,
          'p_search_query': filters.hasSearchQuery ? filters.searchQuery!.trim() : null,
          'p_limit': pageSize,
          'p_offset': (page - 1) * pageSize,
        },
      );

      AppLogger.info('fetchMyLoads: RPC response type: ${response.runtimeType}', scope: 'supplier_load_backend');

      if (response is List) {
        AppLogger.info('fetchMyLoads: RPC returned ${response.length} rows', scope: 'supplier_load_backend');
        return List<Map<String, dynamic>>.from(response);
      }
      
      AppLogger.warning('fetchMyLoads: RPC returned non-list: ${response.runtimeType}', scope: 'supplier_load_backend');
      return const <Map<String, dynamic>>[];
    } catch (error, stackTrace) {
      AppLogger.error('fetchMyLoads: RPC call failed', scope: 'supplier_load_backend', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({
    required String supplierId,
    required String loadId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_supplier_load_detail',
      params: <String, dynamic>{
        'p_load_id': loadId,
        'p_supplier_id': supplierId,
      },
    );

    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({
    required String supplierId,
    required String loadId,
  }) async {
    AppLogger.info('[fetchBookingRequests] Starting - supplierId: $supplierId, loadId: $loadId');
    
    if (_client == null) {
      AppLogger.error('[fetchBookingRequests] Client is null');
      throw const AuthException('Session unavailable');
    }

    try {
      AppLogger.info('[fetchBookingRequests] Calling RPC get_supplier_booking_requests');
      AppLogger.info('   Parameters: p_load_id=$loadId');
      
      final response = await _client.rpc(
        'get_supplier_booking_requests',
        params: {'p_load_id': loadId},
      );
      
      AppLogger.info('[fetchBookingRequests] RPC returned response type: ${response.runtimeType}');
      
      if (response is List) {
        AppLogger.info('[fetchBookingRequests] RPC returned ${response.length} rows');
        return List<Map<String, dynamic>>.from(response);
      } else {
        AppLogger.warning('[fetchBookingRequests] RPC returned non-list response: $response');
        return [];
      }
    } catch (error, stackTrace) {
      AppLogger.error('[fetchBookingRequests] ERROR: $error');
      AppLogger.error('   Error type: ${error.runtimeType}');
      AppLogger.error('   Stack trace: $stackTrace');
      
      // Try to get more details from PostgrestException if available
      if (error.toString().contains('column') || error.toString().contains('does not exist')) {
        AppLogger.error('   This appears to be a database column error');
      }
      
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({
    required String supplierId,
    required String loadId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_supplier_linked_trips',
      params: <String, dynamic>{
        'p_load_id': loadId,
        'p_supplier_id': supplierId,
      },
    );

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return const <Map<String, dynamic>>[];
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
