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
  final int bidsApproved;
  final int bidsRejected;
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
    this.bidsApproved = 0,
    this.bidsRejected = 0,
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
  bool get hasBookingActivity => activeBids > 0 || bidsApproved > 0 || bidsRejected > 0;
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
      (row['bids_approved'] as num?)?.toInt() ?? 0,
      (row['bids_rejected'] as num?)?.toInt() ?? 0,
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
          bidsApproved: results[1],
          bidsRejected: results[2],
          upcomingTrips: results[3],
          inTransitTrips: results[4],
          completedTrips: results[5],
          totalTrucks: results[6],
          approvedTrucks: results[7],
          pendingTrucks: results[8],
          rejectedTrucks: results[9],
          pendingReapprovalTrucks: results[10],
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
