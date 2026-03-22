import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/supplier_trip_repository.dart';

enum SupplierTripsTab {
  active,
  completed,
}

class SupplierTripsState {
  final SupplierTripsTab selectedTab;
  final List<SupplierTrip> trips;
  final bool isLoading;
  final AppFailure? failure;

  const SupplierTripsState({
    required this.selectedTab,
    required this.trips,
    required this.isLoading,
    required this.failure,
  });

  factory SupplierTripsState.initial() {
    return const SupplierTripsState(
      selectedTab: SupplierTripsTab.active,
      trips: <SupplierTrip>[],
      isLoading: true,
      failure: null,
    );
  }

  SupplierTripsState copyWith({
    SupplierTripsTab? selectedTab,
    List<SupplierTrip>? trips,
    bool? isLoading,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return SupplierTripsState(
      selectedTab: selectedTab ?? this.selectedTab,
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class SupplierTripsController extends StateNotifier<SupplierTripsState> {
  final SupplierTripsRepository _repository;

  SupplierTripsController(this._repository) : super(SupplierTripsState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final stages = state.selectedTab == SupplierTripsTab.active
        ? SupplierTripsRepository.activeStages
        : SupplierTripsRepository.completedStages;
    final result = await _repository.fetchTrips(stages);
    result.when(
      success: (value) {
        state = state.copyWith(trips: value, isLoading: false, clearFailure: true);
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
      },
    );
  }

  Future<void> selectTab(SupplierTripsTab tab) async {
    if (tab == state.selectedTab) {
      return;
    }
    state = state.copyWith(selectedTab: tab);
    await load();
  }
}

final supplierTripsProvider = StateNotifierProvider.autoDispose<SupplierTripsController, SupplierTripsState>((ref) {
  return SupplierTripsController(ref.watch(supplierTripsRepositoryProvider));
});
