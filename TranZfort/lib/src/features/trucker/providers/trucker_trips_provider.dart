import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/trucker_trip_repository.dart';

enum TruckerTripsTab {
  active,
  completed,
}

class TruckerTripsState {
  final TruckerTripsTab selectedTab;
  final List<TruckerTrip> trips;
  final bool isLoading;
  final AppFailure? failure;

  const TruckerTripsState({
    required this.selectedTab,
    required this.trips,
    required this.isLoading,
    required this.failure,
  });

  factory TruckerTripsState.initial() {
    return const TruckerTripsState(
      selectedTab: TruckerTripsTab.active,
      trips: <TruckerTrip>[],
      isLoading: true,
      failure: null,
    );
  }

  TruckerTripsState copyWith({
    TruckerTripsTab? selectedTab,
    List<TruckerTrip>? trips,
    bool? isLoading,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return TruckerTripsState(
      selectedTab: selectedTab ?? this.selectedTab,
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class TruckerTripsController extends StateNotifier<TruckerTripsState> {
  final TruckerTripsRepository _repository;

  TruckerTripsController(this._repository) : super(TruckerTripsState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final stages = state.selectedTab == TruckerTripsTab.active
        ? TruckerTripsRepository.activeStages
        : TruckerTripsRepository.completedStages;
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

  Future<void> selectTab(TruckerTripsTab tab) async {
    if (tab == state.selectedTab) {
      return;
    }
    state = state.copyWith(selectedTab: tab);
    await load();
  }
}

final truckerTripsProvider = StateNotifierProvider.autoDispose<TruckerTripsController, TruckerTripsState>((ref) {
  return TruckerTripsController(ref.watch(truckerTripsRepositoryProvider));
});
