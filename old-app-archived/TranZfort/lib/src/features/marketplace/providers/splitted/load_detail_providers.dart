import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/coordinate_utils.dart';
import '../../../../core/error/result.dart';
import 'dashboard_providers.dart';
import 'find_loads_providers.dart';
import 'shared_providers.dart';

final loadDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  loadId,
) async {
  final loadResult = await ref
      .watch(loadRepositoryProvider)
      .getLoadDetail(loadId);
  final load = switch (loadResult) {
    Success(data: final data) => data,
    Failure() => <String, dynamic>{},
  };

  if (load.isEmpty) {
    return const <String, dynamic>{};
  }

  final parentId = (load['parent_load_id'] ?? load['id']).toString();
  final childrenResult = await ref
      .watch(loadRepositoryProvider)
      .getChildLoads(parentId);
  final children = switch (childrenResult) {
    Success(data: final data) => data,
    Failure() => <Map<String, dynamic>>[],
  };

  final dieselPriceResult = await ref
      .watch(loadRepositoryProvider)
      .getDieselPrice((load['origin_state'] ?? '').toString());
  final dieselPrice = switch (dieselPriceResult) {
    Success(data: final data) => data,
    Failure() => 90.0,
  };

  final tripCostResult = ref
      .read(tripCostingServiceProvider)
      .estimate(
        distanceKm: CoordinateUtils.parseDouble(load['distance_km']),
        loadWeightTonnes: CoordinateUtils.parseDouble(load['weight_tonnes']),
        payloadKg: 10000,
        emptyMileageKmpl: 4.0,
        loadedMileageKmpl: 2.5,
        axleCount: 2,
        dieselPricePerLitre: dieselPrice,
      );
  final tripCost = switch (tripCostResult) {
    Success(data: final estimate) => {
      'diesel': estimate.dieselCost,
      'toll': estimate.tollCost,
      'total': estimate.totalCost,
      'mileage': estimate.estimatedMileage,
    },
    Failure() => <String, dynamic>{},
  };

  return {
    'load': load,
    'children': children,
    'diesel_price': dieselPrice,
    'trip_cost': tripCost,
  };
});

class LoadDetailActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  LoadDetailActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> approveBooking(String childLoadId, String parentLoadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .approveBooking(childLoadId);
    
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(loadDetailProvider(parentLoadId));
        _ref.invalidate(myLoadsProvider(false));
        _ref.invalidate(myLoadsProvider(true));
        _ref.invalidate(supplierDashboardProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to approve booking', StackTrace.current);
        return false;
    }
  }

  Future<bool> rejectBooking(String childLoadId, String parentLoadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .rejectBooking(childLoadId);
    
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(loadDetailProvider(parentLoadId));
        _ref.invalidate(myLoadsProvider(false));
        _ref.invalidate(myLoadsProvider(true));
        _ref.invalidate(supplierDashboardProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to reject booking', StackTrace.current);
        return false;
    }
  }

  Future<bool> confirmDelivery(String childLoadId, String parentLoadId) async {
    state = const AsyncLoading();
    final result = await _ref
        .read(loadRepositoryProvider)
        .confirmDeliveryForChildLoad(childLoadId);
    
    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(loadDetailProvider(parentLoadId));
        _ref.invalidate(myLoadsProvider(false));
        _ref.invalidate(myLoadsProvider(true));
        _ref.invalidate(supplierDashboardProvider);
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to confirm delivery', StackTrace.current);
        return false;
    }
  }
}

final loadDetailActionProvider =
    StateNotifierProvider<LoadDetailActionNotifier, AsyncValue<void>>((ref) {
      return LoadDetailActionNotifier(ref);
    });
