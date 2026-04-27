import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

class SupplierDashboardStats {
  final int activeLoads;
  final int pendingBookings;
  final int inTransitTrips;
  final int completedTrips;

  const SupplierDashboardStats({
    required this.activeLoads,
    required this.pendingBookings,
    required this.inTransitTrips,
    required this.completedTrips,
  });
}

abstract class SupplierDashboardBackend {
  /// Fetches all dashboard stats in a single RPC call
  /// Returns: [activeLoads, pendingBookings, inTransitTrips, completedTrips]
  Future<List<int>> fetchDashboardStats(String supplierId);
}

class SupabaseSupplierDashboardBackend implements SupplierDashboardBackend {
  final SupabaseClient? _client;

  const SupabaseSupplierDashboardBackend(this._client);

  @override
  Future<List<int>> fetchDashboardStats(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_supplier_dashboard_stats',
      params: {'p_supplier_id': supplierId},
    );

    // Defensive parsing: support Map, JSON string, and null-safe count reads
    Map<String, dynamic> row;
    if (response is Map<String, dynamic>) {
      row = response;
    } else if (response is String) {
      final decoded = jsonDecode(response);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Expected Map from JSON string, got ${decoded.runtimeType}');
      }
      row = decoded;
    } else if (response is Map) {
      row = Map<String, dynamic>.from(response);
    } else {
      throw FormatException('Unexpected RPC response type: ${response.runtimeType}');
    }

    int safeCount(String key) {
      final value = row[key];
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return [
      safeCount('active_loads'),
      safeCount('pending_bookings'),
      safeCount('in_transit_trips'),
      safeCount('completed_trips'),
    ];
  }
}

class SupplierDashboardRepository {
  final SupplierDashboardBackend _backend;
  final String? Function() _currentUserId;

  static const List<String> activeLoadStatuses = [
    'active',
    'assigned_partial',
    'assigned_full',
    'in_transit',
  ];

  const SupplierDashboardRepository(this._backend, this._currentUserId);

  Future<Result<SupplierDashboardStats>> fetchDashboardStats() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<SupplierDashboardStats>(UnauthorizedFailure());
    }

    try {
      final results = await _backend.fetchDashboardStats(userId);

      return Success<SupplierDashboardStats>(
        SupplierDashboardStats(
          activeLoads: results[0],
          pendingBookings: results[1],
          inTransitTrips: results[2],
          completedTrips: results[3],
        ),
      );
    } catch (error, stackTrace) {
      return Failure<SupplierDashboardStats>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);
}

final supplierDashboardRepositoryProvider = Provider<SupplierDashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupplierDashboardRepository(
    SupabaseSupplierDashboardBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
