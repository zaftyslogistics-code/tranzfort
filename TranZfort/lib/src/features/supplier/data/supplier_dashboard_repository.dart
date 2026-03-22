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
  Future<int> countLoadsByStatuses(String supplierId, List<String> statuses);

  Future<int> countPendingBookings(String supplierId);

  Future<int> countTripsByStages(String supplierId, List<String> stages);
}

class SupabaseSupplierDashboardBackend implements SupplierDashboardBackend {
  final SupabaseClient? _client;

  const SupabaseSupplierDashboardBackend(this._client);

  @override
  Future<int> countLoadsByStatuses(String supplierId, List<String> statuses) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('loads')
        .select('id')
        .eq('supplier_id', supplierId)
        .inFilter('status', statuses);

    return response.length;
  }

  @override
  Future<int> countPendingBookings(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('booking_requests')
        .select('id, loads!inner(supplier_id)')
        .eq('status', 'submitted')
        .eq('loads.supplier_id', supplierId);

    return response.length;
  }

  @override
  Future<int> countTripsByStages(String supplierId, List<String> stages) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('trips')
        .select('id')
        .eq('supplier_id', supplierId)
        .inFilter('stage', stages);

    return response.length;
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
      final activeLoads = await _backend.countLoadsByStatuses(userId, activeLoadStatuses);
      final pendingBookings = await _backend.countPendingBookings(userId);
      final inTransitTrips = await _backend.countTripsByStages(userId, const ['in_transit']);
      final completedTrips = await _backend.countTripsByStages(userId, const ['completed']);

      return Success<SupplierDashboardStats>(
        SupplierDashboardStats(
          activeLoads: activeLoads,
          pendingBookings: pendingBookings,
          inTransitTrips: inTransitTrips,
          completedTrips: completedTrips,
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
