import 'package:supabase_flutter/supabase_flutter.dart';

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
    print('🔍 [SupabaseSupplierLoadBackend] fetchMyLoads() called');
    print('   supplierId: $supplierId');
    print('   filters: $filters');
    print('   page: $page');
    print('   pageSize: $pageSize');

    if (_client == null) {
      print('❌ [SupabaseSupplierLoadBackend] Client is null');
      return const [];
    }

    print('   Calling RPC: get_supplier_loads_list');
    print('   Parameters: p_supplier_id=$supplierId, p_status_filter=${filters.hasStatuses ? filters.statuses : null}, p_search_query=${filters.hasSearchQuery ? filters.searchQuery!.trim() : null}, p_limit=$pageSize, p_offset=${(page - 1) * pageSize}');

    try {
      final response = await _client.rpc(
        'get_supplier_loads_list',
        params: <String, dynamic>{
          'p_supplier_id': supplierId,
          'p_status_filter': filters.hasStatuses ? filters.statuses : null,
          'p_search_query': filters.hasSearchQuery ? filters.searchQuery!.trim() : null,
          'p_limit': pageSize,
          'p_offset': (page - 1) * pageSize,
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
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_supplier_booking_requests',
      params: {'p_load_id': loadId},
    );

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    }
    return [];
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
