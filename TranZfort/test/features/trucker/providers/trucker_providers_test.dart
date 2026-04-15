import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_dashboard_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_profile_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_providers.dart';

class _ProviderTruckerProfileBackend implements TruckerProfileBackend {
  final TruckerProfile? profile;
  final Object? error;

  _ProviderTruckerProfileBackend({this.profile, this.error});

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (error != null) {
      throw error!;
    }
    if (profile == null) {
      return null;
    }
    return {
      'id': profile!.id,
      'full_name': profile!.fullName,
      'mobile': profile!.mobile,
      'email': profile!.email,
      'verification_status': profile!.verificationStatus,
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerExtension(String userId) async {
    if (error != null) {
      throw error!;
    }
    if (profile == null) {
      return null;
    }
    return {
      'dl_number': profile!.dlNumber,
      'rating': profile!.rating,
      'total_trips': profile!.totalTrips,
      'completed_trips': profile!.completedTrips,
    };
  }

  @override
  Future<int> countTrucksByStatuses(String userId, List<String> statuses) async {
    if (error != null) {
      throw error!;
    }
    if (profile == null) {
      return 0;
    }
    if (statuses.contains('verified')) {
      return profile!.approvedTrucks;
    }
    return profile!.totalTrucks;
  }

  @override
  Future<void> updateTruckerExtension(String userId, Map<String, dynamic> values) async {}
}

class _ProviderTruckerDashboardBackend implements TruckerDashboardBackend {
  final TruckerDashboardStats? stats;
  final Object? error;

  _ProviderTruckerDashboardBackend({this.stats, this.error});

  @override
  Future<List<int>> fetchDashboardStats(String truckerId) async {
    if (error != null) {
      throw error!;
    }
    return [
      stats?.activeBids ?? 0,
      stats?.upcomingTrips ?? 0,
      stats?.inTransitTrips ?? 0,
      stats?.completedTrips ?? 0,
      stats?.totalTrucks ?? 0,
      stats?.approvedTrucks ?? 0,
      stats?.pendingTrucks ?? 0,
      stats?.rejectedTrucks ?? 0,
      stats?.pendingReapprovalTrucks ?? 0,
    ];
  }
}

void main() {
  group('trucker providers', () {
    test('truckerProfileProvider resolves success state', () async {
      final container = ProviderContainer(
        overrides: [
          truckerProfileRepositoryProvider.overrideWithValue(
            TruckerProfileRepository(
              _ProviderTruckerProfileBackend(
                profile: const TruckerProfile(
                  id: 'trucker-1',
                  fullName: 'Ravi Trucker',
                  mobile: '+919999999999',
                  email: 'ravi@example.com',
                  verificationStatus: 'pending',
                  dlNumber: 'DL-0099',
                  rating: 4.8,
                  totalTrips: 20,
                  completedTrips: 18,
                  totalTrucks: 2,
                  approvedTrucks: 1,
                ),
              ),
              () => 'trucker-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(truckerProfileProvider.future);

      expect(profile?.dlNumber, 'DL-0099');
      expect(profile?.approvedTrucks, 1);
    });

    test('truckerProfileProvider surfaces app failure as async error', () async {
      final container = ProviderContainer(
        overrides: [
          truckerProfileRepositoryProvider.overrideWithValue(
            TruckerProfileRepository(
              _ProviderTruckerProfileBackend(error: const PermissionFailure()),
              () => 'trucker-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(truckerProfileProvider.future),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('truckerDashboardProvider resolves success state', () async {
      final container = ProviderContainer(
        overrides: [
          truckerDashboardRepositoryProvider.overrideWithValue(
            TruckerDashboardRepository(
              _ProviderTruckerDashboardBackend(
                stats: const TruckerDashboardStats(
                  activeBids: 4,
                  upcomingTrips: 2,
                  inTransitTrips: 1,
                  completedTrips: 9,
                  totalTrucks: 3,
                  approvedTrucks: 1,
                  pendingTrucks: 1,
                  rejectedTrucks: 1,
                  pendingReapprovalTrucks: 0,
                ),
              ),
              () => 'trucker-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(truckerDashboardProvider.future);

      expect(stats.activeBids, 4);
      expect(stats.completedTrips, 9);
    });

    test('truckerDashboardProvider surfaces async error state', () async {
      final container = ProviderContainer(
        overrides: [
          truckerDashboardRepositoryProvider.overrideWithValue(
            TruckerDashboardRepository(
              _ProviderTruckerDashboardBackend(error: const NetworkFailure()),
              () => 'trucker-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(truckerDashboardProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
