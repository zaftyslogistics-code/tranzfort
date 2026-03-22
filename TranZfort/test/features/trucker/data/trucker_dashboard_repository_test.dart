import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_dashboard_repository.dart';

class _FakeTruckerDashboardBackend implements TruckerDashboardBackend {
  int activeBids = 0;
  int upcomingTrips = 0;
  int inTransitTrips = 0;
  int completedTrips = 0;
  int totalTrucks = 0;
  int approvedTrucks = 0;
  int pendingTrucks = 0;
  int rejectedTrucks = 0;
  int pendingReapprovalTrucks = 0;
  Object? error;

  @override
  Future<int> countBookingRequestsByStatuses(String truckerId, List<String> statuses) async {
    if (error != null) {
      throw error!;
    }
    return activeBids;
  }

  @override
  Future<int> countTripsByStages(String truckerId, List<String> stages) async {
    if (error != null) {
      throw error!;
    }
    if (stages.contains('completed')) {
      return completedTrips;
    }
    if (stages.contains('in_transit')) {
      return inTransitTrips;
    }
    return upcomingTrips;
  }

  @override
  Future<int> countTrucksByStatuses(String truckerId, List<String> statuses) async {
    if (error != null) {
      throw error!;
    }
    if (statuses.contains('verified')) {
      return approvedTrucks;
    }
    if (statuses.contains('pending')) {
      return pendingTrucks;
    }
    if (statuses.contains('rejected')) {
      return rejectedTrucks;
    }
    if (statuses.contains('edited_pending_reapproval')) {
      return pendingReapprovalTrucks;
    }
    return totalTrucks;
  }
}

void main() {
  group('TruckerDashboardRepository', () {
    test('returns dashboard stats from backend counts', () async {
      final backend = _FakeTruckerDashboardBackend()
        ..activeBids = 5
        ..upcomingTrips = 2
        ..inTransitTrips = 1
        ..completedTrips = 11
        ..totalTrucks = 3
        ..approvedTrucks = 1
        ..pendingTrucks = 1
        ..rejectedTrucks = 1
        ..pendingReapprovalTrucks = 1;
      final repository = TruckerDashboardRepository(backend, () => 'trucker-1');

      final result = await repository.fetchDashboardStats();

      expect(result.isSuccess, isTrue);
      final stats = result.valueOrNull;
      expect(stats?.activeBids, 5);
      expect(stats?.upcomingTrips, 2);
      expect(stats?.inTransitTrips, 1);
      expect(stats?.completedTrips, 11);
      expect(stats?.approvedTrucks, 1);
      expect(stats?.pendingTrucks, 1);
      expect(stats?.rejectedTrucks, 1);
      expect(stats?.pendingReapprovalTrucks, 1);
    });

    test('returns unauthorized when there is no trucker session', () async {
      final repository = TruckerDashboardRepository(
        _FakeTruckerDashboardBackend(),
        () => null,
      );

      final result = await repository.fetchDashboardStats();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('maps network errors', () async {
      final backend = _FakeTruckerDashboardBackend()
        ..error = const SocketException('offline');
      final repository = TruckerDashboardRepository(backend, () => 'trucker-1');

      final result = await repository.fetchDashboardStats();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps permission errors', () async {
      final backend = _FakeTruckerDashboardBackend()
        ..error = const PostgrestException(
          message: 'forbidden',
          code: '42501',
        );
      final repository = TruckerDashboardRepository(backend, () => 'trucker-1');

      final result = await repository.fetchDashboardStats();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
