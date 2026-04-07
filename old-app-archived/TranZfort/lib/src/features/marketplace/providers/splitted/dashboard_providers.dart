import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/providers/auth_providers.dart';
import '../../../trips/providers/trips_providers.dart';
import 'find_loads_providers.dart';

class SupplierDashboardData {
  final int activeLoadsCount;
  final int pendingBookingsCount;
  final int inTransitTripsCount;
  final int completedTripsCount;
  final List<Map<String, dynamic>> needsActionBookings;
  final List<Map<String, dynamic>> recentLoads;

  const SupplierDashboardData({
    required this.activeLoadsCount,
    required this.pendingBookingsCount,
    required this.inTransitTripsCount,
    required this.completedTripsCount,
    required this.needsActionBookings,
    required this.recentLoads,
  });
}

final supplierDashboardProvider = FutureProvider.autoDispose<SupplierDashboardData>((ref) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Fetch active loads and completed loads
  final activeLoads = await ref.watch(myLoadsProvider(false).future);
  final completedLoads = await ref.watch(myLoadsProvider(true).future);
  
  int activeCount = 0;
  int pendingCount = 0;
  int inTransitCount = 0;
  int completedCount = 0;
  
  final List<Map<String, dynamic>> needsAction = [];
  final List<Map<String, dynamic>> recent = [];

  for (final load in activeLoads) {
    final status = (load['status'] ?? '').toString();
    activeCount++;
    
    if (status == 'pending_approval') {
      pendingCount++;
      needsAction.add(load);
    } else if (status == 'in_transit') {
      inTransitCount++;
    }
    
    // Add to recent if it's active
    if (recent.length < 5) {
      recent.add(load);
    }
  }
  
  for (final _ in completedLoads) {
    completedCount++;
  }

  return SupplierDashboardData(
    activeLoadsCount: activeCount,
    pendingBookingsCount: pendingCount,
    inTransitTripsCount: inTransitCount,
    completedTripsCount: completedCount,
    needsActionBookings: needsAction,
    recentLoads: recent,
  );
});

class TruckerDashboardData {
  final int activeBidsCount;
  final int upcomingTripsCount;
  final int inTransitTripsCount;
  final int completedTripsCount;
  final List<Map<String, dynamic>> upcomingTripsList;
  final List<Map<String, dynamic>> pendingBidsList;

  const TruckerDashboardData({
    required this.activeBidsCount,
    required this.upcomingTripsCount,
    required this.inTransitTripsCount,
    required this.completedTripsCount,
    required this.upcomingTripsList,
    required this.pendingBidsList,
  });
}

final truckerDashboardProvider = FutureProvider.autoDispose<TruckerDashboardData>((ref) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) {
    throw Exception('User not authenticated');
  }

  // Truckers see their trips
  final activeTrips = await ref.watch(myTripsProvider(false).future);
  final completedTrips = await ref.watch(myTripsProvider(true).future);
  
  int activeBids = 0;
  int upcomingTrips = 0;
  int inTransitTrips = 0;
  int completedTripsCount = completedTrips.length;
  
  final List<Map<String, dynamic>> upcomingList = [];
  final List<Map<String, dynamic>> pendingList = [];

  for (final trip in activeTrips) {
    final stage = (trip['stage'] ?? '').toString();
    
    if (stage == 'pending_approval') {
      activeBids++;
      pendingList.add(trip);
    } else if (stage == 'at_pickup' || stage == 'booked') {
      upcomingTrips++;
      upcomingList.add(trip);
    } else if (stage == 'in_transit') {
      inTransitTrips++;
    }
  }

  return TruckerDashboardData(
    activeBidsCount: activeBids,
    upcomingTripsCount: upcomingTrips,
    inTransitTripsCount: inTransitTrips,
    completedTripsCount: completedTripsCount,
    upcomingTripsList: upcomingList,
    pendingBidsList: pendingList,
  );
});
