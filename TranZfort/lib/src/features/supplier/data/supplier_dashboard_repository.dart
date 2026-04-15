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

    // Response is a single row with columns: active_loads, pending_bookings, etc.
    final row = response as Map<String, dynamic>;
    return [
      (row['active_loads'] as num).toInt(),
      (row['pending_bookings'] as num).toInt(),
      (row['in_transit_trips'] as num).toInt(),
      (row['completed_trips'] as num).toInt(),
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
