import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
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
        .eq('supplier_id', supplierId)
        .order('pickup_date', ascending: false);

    if (filters.hasStatuses) {
      query = query.inFilter('status', filters.statuses);
    }

    if (filters.hasSearchQuery) {
      final queryValue = filters.searchQuery!.trim();
      query = query.or(
        'material.ilike.%$queryValue%,origin_city.ilike.%$queryValue%,destination_city.ilike.%$queryValue%,origin_label.ilike.%$queryValue%,destination_label.ilike.%$queryValue%',
      );
    }

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
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_supplier_booking_requests',
      params: {'p_load_id': loadId},
    );

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({
    required String supplierId,
    required String loadId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final relatedLoads = await _client
        .from('loads')
        .select('id, parent_load_id')
        .eq('supplier_id', supplierId)
        .or('id.eq.$loadId,parent_load_id.eq.$loadId');

    final relatedLoadIds = relatedLoads
        .whereType<Map<String, dynamic>>()
        .map((row) => (row['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    if (relatedLoadIds.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final response = await _client
        .from('trips')
        .select(
          'id, load_id, trucker_id, truck_id, stage, assigned_at, delivered_at, pod_uploaded_at, completed_at, lr_document_path, pod_document_path, loads(id, parent_load_id, origin_label, destination_label, material)',
        )
        .eq('supplier_id', supplierId)
        .inFilter('load_id', relatedLoadIds)
        .order('assigned_at', ascending: false);

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
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

class SupplierLoadRepository {
  final SupplierLoadBackend _backend;
  final String? Function() _currentUserId;
  final int _pageSize;

  const SupplierLoadRepository(
    this._backend,
    this._currentUserId, {
    int pageSize = 20,
  }) : _pageSize = pageSize;

  Future<Result<String>> createLoad(CreateLoadDto dto) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    final validationFailure = _validateCreateLoad(dto);
    if (validationFailure != null) {
      return Failure<String>(validationFailure);
    }

    try {
      final loadId = await _backend.createLoad(dto.toRpcParams());
      return Success<String>(loadId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<Load>>> getMyLoads(
    LoadFilters filters, {
    int page = 1,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<Load>>(UnauthorizedFailure());
    }

    if (page < 1) {
      return const Failure<List<Load>>(
        ValidationFailure(
          message: 'Page must be at least 1',
          fieldErrors: {'page': 'Invalid page'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchMyLoads(
        supplierId: userId,
        filters: filters,
        page: page,
        pageSize: _pageSize,
      );
      final loads = rows
          .map(LoadListItemDto.fromMap)
          .map((dto) => dto.toDomain())
          .toList(growable: false);
      return Success<List<Load>>(loads);
    } catch (error, stackTrace) {
      return Failure<List<Load>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<LoadDetail>> getLoadDetail(String id) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<LoadDetail>(UnauthorizedFailure());
    }

    if (id.trim().isEmpty) {
      return const Failure<LoadDetail>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      final row = await _backend.fetchLoadDetail(supplierId: userId, loadId: id.trim());
      if (row == null) {
        return const Failure<LoadDetail>(NotFoundFailure());
      }

      return Success<LoadDetail>(LoadDetailDto.fromMap(row).toDomain());
    } catch (error, stackTrace) {
      return Failure<LoadDetail>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<LoadBookingRequest>>> getBookingRequests(String loadId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<LoadBookingRequest>>(UnauthorizedFailure());
    }

    if (loadId.trim().isEmpty) {
      return const Failure<List<LoadBookingRequest>>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchBookingRequests(
        supplierId: userId,
        loadId: loadId.trim(),
      );
      final bookings = rows
          .map(LoadBookingRequest.fromMap)
          .toList(growable: false);
      return Success<List<LoadBookingRequest>>(bookings);
    } catch (error, stackTrace) {
      return Failure<List<LoadBookingRequest>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<LinkedTrip>>> getLinkedTrips(String loadId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<LinkedTrip>>(UnauthorizedFailure());
    }

    if (loadId.trim().isEmpty) {
      return const Failure<List<LinkedTrip>>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      final rows = await _backend.fetchLinkedTrips(
        supplierId: userId,
        loadId: loadId.trim(),
      );
      final trips = rows
          .map(LinkedTrip.fromMap)
          .toList(growable: false);
      return Success<List<LinkedTrip>>(trips);
    } catch (error, stackTrace) {
      return Failure<List<LinkedTrip>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> cancelLoad(String id) async {
    return _mutateLoad(
      id: id,
      action: (loadId) => _backend.cancelLoad(loadId),
    );
  }

  Future<Result<void>> closeFilledOutsideApp(String id) async {
    return _mutateLoad(
      id: id,
      action: (loadId) => _backend.closeLoadFilledOutsideApp(loadId),
    );
  }

  Future<Result<String>> approveBookingRequest(String bookingId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    if (bookingId.trim().isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Booking id is required',
          fieldErrors: {'booking_id': 'Booking id is required'},
        ),
      );
    }

    try {
      final tripId = await _backend.approveBookingRequest(bookingId.trim());
      return Success<String>(tripId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> rejectBookingRequest(String bookingId, {String? reason}) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    if (bookingId.trim().isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Booking id is required',
          fieldErrors: {'booking_id': 'Booking id is required'},
        ),
      );
    }

    try {
      await _backend.rejectBookingRequest(bookingId.trim(), reason: reason?.trim());
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> _mutateLoad({
    required String id,
    required Future<void> Function(String loadId) action,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    if (id.trim().isEmpty) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      await action(id.trim());
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  ValidationFailure? _validateCreateLoad(CreateLoadDto dto) {
    if (dto.originLabel.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter an origin location',
        fieldErrors: {'origin_label': 'Origin is required'},
      );
    }

    if (dto.originCity.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter an origin city',
        fieldErrors: {'origin_city': 'Origin city is required'},
      );
    }

    if (dto.destinationLabel.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter a destination location',
        fieldErrors: {'destination_label': 'Destination is required'},
      );
    }

    if (dto.destinationCity.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter a destination city',
        fieldErrors: {'destination_city': 'Destination city is required'},
      );
    }

    if (dto.material.trim().isEmpty) {
      return const ValidationFailure(
        message: 'Enter a material type',
        fieldErrors: {'material': 'Material is required'},
      );
    }

    if (dto.weightTonnes <= 0) {
      return const ValidationFailure(
        message: 'Enter a valid weight',
        fieldErrors: {'weight_tonnes': 'Weight must be positive'},
      );
    }

    if (dto.trucksNeeded < 1) {
      return const ValidationFailure(
        message: 'Enter how many trucks you need',
        fieldErrors: {'trucks_needed': 'Trucks needed must be at least 1'},
      );
    }

    if (dto.priceAmount <= 0) {
      return const ValidationFailure(
        message: 'Enter a valid rate amount',
        fieldErrors: {'price_amount': 'Price amount must be positive'},
      );
    }

    if (dto.priceType != 'fixed' && dto.priceType != 'per_ton') {
      return const ValidationFailure(
        message: 'Select a valid price type',
        fieldErrors: {'price_type': 'Price type must be fixed or per_ton'},
      );
    }

    if (dto.advancePercentage != null && (dto.advancePercentage! < 0 || dto.advancePercentage! > 100)) {
      return const ValidationFailure(
        message: 'Advance percentage must stay between 0 and 100',
        fieldErrors: {'advance_percentage': 'Advance percentage is invalid'},
      );
    }

    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedPickupDate = DateTime(dto.pickupDate.year, dto.pickupDate.month, dto.pickupDate.day);
    if (normalizedPickupDate.isBefore(normalizedToday)) {
      return const ValidationFailure(
        message: 'Pickup date must be today or later',
        fieldErrors: {'pickup_date': 'Pickup date cannot be in the past'},
      );
    }

    return null;
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final message = error.message.trim();
      final normalized = message.toLowerCase();
      if (normalized.contains('cannot be cancelled') ||
          normalized.contains('cannot be closed') ||
          normalized.contains('booking not in submitted state') ||
          normalized.contains('already booked') ||
          normalized.contains('not available') ||
          normalized.contains('not a supplier')) {
        return BusinessRuleFailure(message: message, debugInfo: error.details?.toString());
      }
    }
    return mapSupabaseError(error, stackTrace);
  }

}

final supplierLoadRepositoryProvider = Provider<SupplierLoadRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierLoadRepository(
    SupabaseSupplierLoadBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
