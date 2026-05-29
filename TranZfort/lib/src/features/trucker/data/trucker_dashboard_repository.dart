import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/type_safety.dart';

class TruckerDashboardStats {
  final int activeBids;
  final int upcomingTrips;
  final int inTransitTrips;
  final int completedTrips;
  final int totalTrucks;
  final int approvedTrucks;
  final int pendingTrucks;
  final int rejectedTrucks;
  final int pendingReapprovalTrucks;
  final DateTime? lastRefreshedAt;

  const TruckerDashboardStats({
    required this.activeBids,
    required this.upcomingTrips,
    required this.inTransitTrips,
    required this.completedTrips,
    required this.totalTrucks,
    required this.approvedTrucks,
    required this.pendingTrucks,
    required this.rejectedTrucks,
    required this.pendingReapprovalTrucks,
    this.lastRefreshedAt,
  });

  bool get hasApprovedTruck => approvedTrucks > 0;
  bool get hasTruckLifecycleAttention => pendingTrucks > 0 || rejectedTrucks > 0 || pendingReapprovalTrucks > 0;
  bool get isFresh => lastRefreshedAt != null &&
      DateTime.now().difference(lastRefreshedAt!).inMinutes < 5;
}

abstract class TruckerDashboardBackend {
  /// Fetches all dashboard stats in a single RPC call
  /// Returns: [activeBids, upcomingTrips, inTransitTrips, completedTrips,
  ///           totalTrucks, approvedTrucks, pendingTrucks, rejectedTrucks, pendingApprovalTrucks]
  Future<List<int>> fetchDashboardStats(String truckerId);
}

class SupabaseTruckerDashboardBackend implements TruckerDashboardBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerDashboardBackend(this._client);

  @override
  Future<List<int>> fetchDashboardStats(String truckerId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_trucker_dashboard_stats',
      params: {'p_trucker_id': truckerId},
    );

    final row = safeMap(response) ?? (response is String ? safeMap(jsonDecode(response)) : null);
    if (row == null || row.isEmpty) {
      throw const ServerFailure(message: 'Unexpected dashboard response format');
    }

    return [
      (row['active_bids'] as num?)?.toInt() ?? 0,
      (row['upcoming_trips'] as num?)?.toInt() ?? 0,
      (row['in_transit_trips'] as num?)?.toInt() ?? 0,
      (row['completed_trips'] as num?)?.toInt() ?? 0,
      (row['total_trucks'] as num?)?.toInt() ?? 0,
      (row['approved_trucks'] as num?)?.toInt() ?? 0,
      (row['pending_trucks'] as num?)?.toInt() ?? 0,
      (row['rejected_trucks'] as num?)?.toInt() ?? 0,
      (row['pending_approval_trucks'] as num?)?.toInt() ?? 0,
    ];
  }
}

class TruckerDashboardRepository {
  final TruckerDashboardBackend _backend;
  final String? Function() _currentUserId;

  const TruckerDashboardRepository(this._backend, this._currentUserId);

  Future<Result<TruckerDashboardStats>> fetchDashboardStats() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerDashboardStats>(UnauthorizedFailure());
    }

    try {
      final results = await _backend.fetchDashboardStats(userId);

      return Success<TruckerDashboardStats>(
        TruckerDashboardStats(
          activeBids: results[0],
          upcomingTrips: results[1],
          inTransitTrips: results[2],
          completedTrips: results[3],
          totalTrucks: results[4],
          approvedTrucks: results[5],
          pendingTrucks: results[6],
          rejectedTrucks: results[7],
          pendingReapprovalTrucks: results[8],
          lastRefreshedAt: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      return Failure<TruckerDashboardStats>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);
}

final truckerDashboardRepositoryProvider = Provider<TruckerDashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerDashboardRepository(
    SupabaseTruckerDashboardBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
