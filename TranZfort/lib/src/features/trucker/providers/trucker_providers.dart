import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/trucker_dashboard_repository.dart';
import '../data/trucker_marketplace_repository.dart';
import '../data/trucker_profile_repository.dart';
import '../data/trucker_trip_repository.dart';

final truckerProfileProvider = FutureProvider<TruckerProfile?>((ref) async {
  final result = await ref.watch(truckerProfileRepositoryProvider).fetchCurrentTruckerProfile();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

final truckerDashboardProvider = FutureProvider<TruckerDashboardStats>((ref) async {
  final result = await ref.watch(truckerDashboardRepositoryProvider).fetchDashboardStats();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

int _truckerDashboardTripPriority(String stage) {
  return switch (stage.trim().toLowerCase()) {
    'in_transit' => 0,
    'picked_up' => 1,
    'pickup_pending' => 2,
    'assigned' => 3,
    'delivered' => 4,
    'proof_submitted' => 5,
    'disputed' => 6,
    _ => 7,
  };
}

final truckerNextTripProvider = FutureProvider<TruckerTrip?>((ref) async {
  final result = await ref.watch(truckerTripsRepositoryProvider).fetchTrips(
        TruckerTripsRepository.activeStages,
        limit: 8,
      );
  final trips = result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
  if (trips.isEmpty) {
    return null;
  }

  final sorted = List<TruckerTrip>.from(trips)
    ..sort((a, b) {
      final priorityCompare =
          _truckerDashboardTripPriority(a.stage).compareTo(_truckerDashboardTripPriority(b.stage));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.assignedAt.compareTo(b.assignedAt);
    });
  return sorted.first;
});

final truckerDashboardNearbyLoadsProvider = FutureProvider<List<MarketplaceLoadItem>>((ref) async {
  const filters = MarketplaceSearchFilters();
  final result = await ref.watch(truckerMarketplaceRepositoryProvider).searchLoads(
        filters,
        page: 1,
        pageSize: 3,
      );
  return result.when(
    success: (value) => value.items,
    failure: (failure) => throw failure,
  );
});

AppFailure? truckerAsyncFailure(AsyncValue<Object?> value) {
  final error = value.asError?.error;
  if (error is AppFailure) {
    return error;
  }

  return null;
}
