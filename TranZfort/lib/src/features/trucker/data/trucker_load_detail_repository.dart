import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/route_snapshot_service.dart';
import 'trucker_marketplace_repository.dart';

class TruckerApprovedTruck {
  final String id;
  final String truckNumber;
  final String bodyType;
  final int tyres;
  final double capacityTonnes;
  final int? axles;
  final int? payloadKg;
  final double? mileageEmptyKmpl;
  final double? mileageLoadedKmpl;

  const TruckerApprovedTruck({
    required this.id,
    required this.truckNumber,
    required this.bodyType,
    required this.tyres,
    required this.capacityTonnes,
    required this.axles,
    required this.payloadKg,
    required this.mileageEmptyKmpl,
    required this.mileageLoadedKmpl,
  });

  factory TruckerApprovedTruck.fromMap(Map<String, dynamic> map) {
    final model = map['truck_models'] is Map<String, dynamic>
        ? map['truck_models'] as Map<String, dynamic>
        : <String, dynamic>{};
    return TruckerApprovedTruck(
      id: (map['id'] ?? '').toString(),
      truckNumber: (map['truck_number'] ?? '').toString(),
      bodyType: (map['body_type'] ?? '').toString(),
      tyres: _readInt(map['tyres']),
      capacityTonnes: _readDouble(map['capacity_tonnes']) ?? 0,
      axles: _readIntNullable(model['axles']),
      payloadKg: _readIntNullable(model['payload_kg']),
      mileageEmptyKmpl: _readDouble(model['mileage_empty_kmpl']),
      mileageLoadedKmpl: _readDouble(model['mileage_loaded_kmpl']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  static int? _readIntNullable(Object? value) {
    if (value == null) {
      return null;
    }
    return _readInt(value);
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '').toString());
  }
}

class TruckerSupplierSummary {
  final String id;
  final String fullName;
  final String? companyName;
  final String verificationStatus;

  const TruckerSupplierSummary({
    required this.id,
    required this.fullName,
    required this.companyName,
    required this.verificationStatus,
  });
}

class TruckerBookingRequestSummary {
  final String id;
  final String truckId;
  final String status;
  final String? decisionReason;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const TruckerBookingRequestSummary({
    required this.id,
    required this.truckId,
    required this.status,
    required this.decisionReason,
    required this.createdAt,
    required this.decidedAt,
  });

  bool get isSubmitted => status == 'submitted';

  factory TruckerBookingRequestSummary.fromMap(Map<String, dynamic> map) {
    return TruckerBookingRequestSummary(
      id: (map['id'] ?? '').toString(),
      truckId: (map['truck_id'] ?? '').toString(),
      status: (map['status'] ?? 'submitted').toString(),
      decisionReason: _nullableString(map['decision_reason']),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
      decidedAt: _readDateTime(map['decided_at']),
    );
  }

  static String? _nullableString(Object? value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }
}

class TruckerLoadDetail {
  final MarketplaceLoadItem summary;
  final String supplierId;
  final TruckerSupplierSummary supplier;
  final String originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final double? routeDistanceKm;
  final int? routeDurationMinutes;
  final String? routePolyline;
  final String? routeSnapshotSource;
  final String? parentLoadId;
  final String? assignedTruckerId;
  final String? assignedTruckId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TruckerBookingRequestSummary? latestBookingRequest;

  const TruckerLoadDetail({
    required this.summary,
    required this.supplierId,
    required this.supplier,
    required this.originCity,
    required this.originState,
    required this.originLat,
    required this.originLng,
    required this.destinationCity,
    required this.destinationState,
    required this.destinationLat,
    required this.destinationLng,
    required this.routeDistanceKm,
    required this.routeDurationMinutes,
    required this.routePolyline,
    required this.routeSnapshotSource,
    required this.parentLoadId,
    required this.assignedTruckerId,
    required this.assignedTruckId,
    required this.createdAt,
    required this.updatedAt,
    required this.latestBookingRequest,
  });

  RouteSnapshot? get routeSnapshot {
    if (routeDistanceKm == null || routeDurationMinutes == null) {
      return null;
    }
    return RouteSnapshot.fromStoredFields(
      distanceKm: routeDistanceKm,
      durationMinutes: routeDurationMinutes,
      source: routeSnapshotSource,
      polyline: routePolyline,
    );
  }
}

bool truckMatchesLoad(TruckerApprovedTruck truck, MarketplaceLoadItem load) {
  final requiredBodyType = load.requiredBodyType?.trim().toLowerCase();
  final normalizedBodyType = truck.bodyType.trim().toLowerCase();
  final bodyMatches = requiredBodyType == null || requiredBodyType.isEmpty || normalizedBodyType == requiredBodyType;
  final tyreMatches = load.requiredTyres.isEmpty || load.requiredTyres.contains(truck.tyres);
  final capacityMatches = truck.capacityTonnes >= load.weightTonnes;
  return bodyMatches && tyreMatches && capacityMatches;
}

abstract class TruckerLoadDetailBackend {
  Future<Map<String, dynamic>?> fetchLoadDetail(String loadId);

  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId);

  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId);

  Future<List<Map<String, dynamic>>> fetchApprovedTrucks(String truckerId);

  Future<List<Map<String, dynamic>>> fetchBookingRequests(String truckerId, String loadId);

  Future<String> submitBookingRequest(
    String loadId,
    String truckId, {
    double? bookingGpsLat,
    double? bookingGpsLng,
  });
}

class SupabaseTruckerLoadDetailBackend implements TruckerLoadDetailBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerLoadDetailBackend(this._client);

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail(String loadId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('loads')
        .select(
          'id, supplier_id, parent_load_id, origin_label, origin_city, origin_state, origin_lat, origin_lng, destination_label, destination_city, destination_state, destination_lat, destination_lng, route_distance_km, route_duration_minutes, route_polyline, route_snapshot_source, material, weight_tonnes, required_body_type, required_tyres, trucks_needed, trucks_booked, price_amount, price_type, advance_percentage, pickup_date, status, is_super_load, super_status, assigned_trucker_id, assigned_truck_id, published_at, created_at, updated_at',
        )
        .eq('id', loadId)
        .maybeSingle();

    return response;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('profiles')
        .select('id, full_name, verification_status')
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
  Future<List<Map<String, dynamic>>> fetchApprovedTrucks(String truckerId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('trucks')
        .select('id, truck_number, body_type, tyres, capacity_tonnes, truck_models(axles, payload_kg, mileage_empty_kmpl, mileage_loaded_kmpl)')
        .eq('owner_id', truckerId)
        .eq('status', 'verified')
        .order('truck_number');

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests(String truckerId, String loadId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('booking_requests')
        .select('id, truck_id, status, decision_reason, created_at, decided_at')
        .eq('trucker_id', truckerId)
        .eq('load_id', loadId)
        .order('created_at', ascending: false)
        .limit(1);

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  @override
  Future<String> submitBookingRequest(
    String loadId,
    String truckId, {
    double? bookingGpsLat,
    double? bookingGpsLng,
  }) async {
    if (_client == null) {
      throw const AuthException('Trucker session is not available');
    }

    final response = await _client.rpc('submit_booking_request', params: {
      'p_load_id': loadId,
      'p_truck_id': truckId,
      'p_booking_gps_lat': bookingGpsLat,
      'p_booking_gps_lng': bookingGpsLng,
    });
    return response.toString();
  }
}

class TruckerLoadDetailRepository {
  final TruckerLoadDetailBackend _backend;
  final String? Function() _currentUserId;

  const TruckerLoadDetailRepository(this._backend, this._currentUserId);

  Future<Result<TruckerLoadDetail>> fetchLoadDetail(String loadId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerLoadDetail>(UnauthorizedFailure());
    }

    if (loadId.trim().isEmpty) {
      return const Failure<TruckerLoadDetail>(
        ValidationFailure(
          message: 'Load id is required',
          fieldErrors: {'id': 'Load id is required'},
        ),
      );
    }

    try {
      final loadRow = await _backend.fetchLoadDetail(loadId.trim());
      if (loadRow == null) {
        return const Failure<TruckerLoadDetail>(NotFoundFailure());
      }

      final status = (loadRow['status'] ?? '').toString();
      if (!_isVisibleStatus(status)) {
        return const Failure<TruckerLoadDetail>(NotFoundFailure());
      }

      final supplierId = (loadRow['supplier_id'] ?? '').toString();
      final supplierProfile = await _backend.fetchSupplierProfile(supplierId);
      final supplierExtension = await _backend.fetchSupplierExtension(supplierId);
      final bookingRows = await _backend.fetchBookingRequests(userId, loadId.trim());

      if (supplierProfile == null) {
        return const Failure<TruckerLoadDetail>(NotFoundFailure());
      }

      return Success<TruckerLoadDetail>(
        TruckerLoadDetail(
          summary: MarketplaceLoadItem.fromMap(loadRow),
          supplierId: supplierId,
          supplier: TruckerSupplierSummary(
            id: supplierId,
            fullName: (supplierProfile['full_name'] ?? 'Supplier').toString(),
            companyName: _nullableString(supplierExtension?['company_name']),
            verificationStatus: (supplierProfile['verification_status'] ?? 'unverified').toString(),
          ),
          originCity: (loadRow['origin_city'] ?? '').toString(),
          originState: _nullableString(loadRow['origin_state']),
          originLat: _readDouble(loadRow['origin_lat']),
          originLng: _readDouble(loadRow['origin_lng']),
          destinationCity: (loadRow['destination_city'] ?? '').toString(),
          destinationState: _nullableString(loadRow['destination_state']),
          destinationLat: _readDouble(loadRow['destination_lat']),
          destinationLng: _readDouble(loadRow['destination_lng']),
          routeDistanceKm: _readDouble(loadRow['route_distance_km']),
          routeDurationMinutes: _readIntNullable(loadRow['route_duration_minutes']),
          routePolyline: _nullableString(loadRow['route_polyline']),
          routeSnapshotSource: _nullableString(loadRow['route_snapshot_source']),
          parentLoadId: _nullableString(loadRow['parent_load_id']),
          assignedTruckerId: _nullableString(loadRow['assigned_trucker_id']),
          assignedTruckId: _nullableString(loadRow['assigned_truck_id']),
          createdAt: DateTime.parse((loadRow['created_at'] ?? '').toString()),
          updatedAt: DateTime.parse((loadRow['updated_at'] ?? '').toString()),
          latestBookingRequest: bookingRows.isEmpty ? null : TruckerBookingRequestSummary.fromMap(bookingRows.first),
        ),
      );
    } catch (error, stackTrace) {
      return Failure<TruckerLoadDetail>(_mapError(error, stackTrace));
    }
  }

  Future<Result<List<TruckerApprovedTruck>>> fetchApprovedTrucks() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<List<TruckerApprovedTruck>>(UnauthorizedFailure());
    }

    try {
      final rows = await _backend.fetchApprovedTrucks(userId);
      return Success<List<TruckerApprovedTruck>>(
        rows.map(TruckerApprovedTruck.fromMap).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<TruckerApprovedTruck>>(_mapError(error, stackTrace));
    }
  }

  Future<Result<String>> submitBookingRequest(
    String loadId,
    String truckId, {
    double? bookingGpsLat,
    double? bookingGpsLng,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<String>(UnauthorizedFailure());
    }

    if (loadId.trim().isEmpty || truckId.trim().isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          message: 'Load and truck are required',
          fieldErrors: {
            'load_id': 'Load is required',
            'truck_id': 'Truck is required',
          },
        ),
      );
    }

    try {
      final bookingId = await _backend.submitBookingRequest(
        loadId.trim(),
        truckId.trim(),
        bookingGpsLat: bookingGpsLat,
        bookingGpsLng: bookingGpsLng,
      );
      return Success<String>(bookingId);
    } catch (error, stackTrace) {
      return Failure<String>(_mapError(error, stackTrace));
    }
  }

  bool _isVisibleStatus(String status) {
    return switch (status) {
      'active' || 'assigned_partial' || 'assigned_full' => true,
      _ => false,
    };
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is PostgrestException) {
      final normalized = error.message.trim().toLowerCase();
      if (normalized.contains('already booked')) {
        return const ConflictFailure(message: 'You already submitted a booking request for this load');
      }
      if (normalized.contains('truck not verified') || normalized.contains('trucker not verified')) {
        return BusinessRuleFailure(message: error.message.trim(), debugInfo: error.details?.toString());
      }
      if (normalized.contains('load not available') || normalized.contains('fully booked')) {
        return BusinessRuleFailure(message: error.message.trim(), debugInfo: error.details?.toString());
      }
    }
    return mapSupabaseError(error, stackTrace);
  }

  static double? _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '').toString());
  }

  static int? _readIntNullable(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }

  static String? _nullableString(Object? value) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? null : raw;
  }
}

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  final raw = value.toString();
  if (raw.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

final truckerLoadDetailRepositoryProvider = Provider<TruckerLoadDetailRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerLoadDetailRepository(
    SupabaseTruckerLoadDetailBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
