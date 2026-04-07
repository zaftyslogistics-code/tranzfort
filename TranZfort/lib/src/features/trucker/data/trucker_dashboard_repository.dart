import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

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
  });

  bool get hasApprovedTruck => approvedTrucks > 0;
  bool get hasTruckLifecycleAttention => pendingTrucks > 0 || rejectedTrucks > 0 || pendingReapprovalTrucks > 0;
}

abstract class TruckerDashboardBackend {
  Future<int> countBookingRequestsByStatuses(String truckerId, List<String> statuses);

  Future<int> countTripsByStages(String truckerId, List<String> stages);

  Future<int> countTrucksByStatuses(String truckerId, List<String> statuses);
}

class SupabaseTruckerDashboardBackend implements TruckerDashboardBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerDashboardBackend(this._client);

  @override
  Future<int> countBookingRequestsByStatuses(String truckerId, List<String> statuses) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('booking_requests')
        .select('id')
        .eq('trucker_id', truckerId)
        .inFilter('status', statuses);

    return response.length;
  }

  @override
  Future<int> countTripsByStages(String truckerId, List<String> stages) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('trips')
        .select('id')
        .eq('trucker_id', truckerId)
        .inFilter('stage', stages);

    return response.length;
  }

  @override
  Future<int> countTrucksByStatuses(String truckerId, List<String> statuses) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    var query = _client.from('trucks').select('id').eq('owner_id', truckerId);
    if (statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }

    final response = await query;
    return response.length;
  }
}

class TruckerDashboardRepository {
  final TruckerDashboardBackend _backend;
  final String? Function() _currentUserId;

  static const List<String> activeBidStatuses = ['submitted'];
  static const List<String> upcomingTripStages = [
    'assigned',
    'pickup_pending',
    'picked_up',
  ];

  const TruckerDashboardRepository(this._backend, this._currentUserId);

  Future<Result<TruckerDashboardStats>> fetchDashboardStats() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerDashboardStats>(UnauthorizedFailure());
    }

    try {
      final results = await Future.wait([
        _backend.countBookingRequestsByStatuses(userId, activeBidStatuses),
        _backend.countTripsByStages(userId, upcomingTripStages),
        _backend.countTripsByStages(userId, const ['in_transit']),
        _backend.countTripsByStages(userId, const ['completed']),
        _backend.countTrucksByStatuses(userId, const <String>[]),
        _backend.countTrucksByStatuses(userId, const ['verified']),
        _backend.countTrucksByStatuses(userId, const ['pending']),
        _backend.countTrucksByStatuses(userId, const ['rejected']),
        _backend.countTrucksByStatuses(userId, const ['edited_pending_reapproval']),
      ]);

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
