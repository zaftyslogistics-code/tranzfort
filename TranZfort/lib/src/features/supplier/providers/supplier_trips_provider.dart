import 'dart:async';

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
  static const Duration _minLoadingDuration = Duration(milliseconds: 300);
  static const Duration _errorDebounceDuration = Duration(milliseconds: 300);

  final SupplierTripsRepository _repository;
  Timer? _errorDebounceTimer;

  SupplierTripsController(this._repository) : super(SupplierTripsState.initial()) {
    load();
  }

  void _scheduleErrorDisplay(AppFailure failure) {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = Timer(_errorDebounceDuration, () {
      if (state.trips.isEmpty && !state.isLoading) {
        state = state.copyWith(failure: failure);
      }
    });
  }

  void _cancelErrorDisplay() {
    _errorDebounceTimer?.cancel();
    _errorDebounceTimer = null;
  }

  Future<void> _ensureMinLoadingDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < _minLoadingDuration) {
      await Future.delayed(_minLoadingDuration - elapsed);
    }
  }

  Future<void> load() async {
    _cancelErrorDisplay();
    state = state.copyWith(isLoading: true, clearFailure: true);
    final startTime = DateTime.now();
    final stages = state.selectedTab == SupplierTripsTab.active
        ? SupplierTripsRepository.activeStages
        : SupplierTripsRepository.completedStages;
    final result = await _repository.fetchTrips(stages);
    await result.when(
      success: (value) async {
        _cancelErrorDisplay();
        await _ensureMinLoadingDuration(startTime);
        state = state.copyWith(trips: value, isLoading: false, clearFailure: true);
      },
      failure: (failure) async {
        await _ensureMinLoadingDuration(startTime);
        _scheduleErrorDisplay(failure);
        state = state.copyWith(isLoading: false);
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

  @override
  void dispose() {
    _errorDebounceTimer?.cancel();
    super.dispose();
  }
}

final supplierTripsProvider = StateNotifierProvider.autoDispose<SupplierTripsController, SupplierTripsState>((ref) {
  return SupplierTripsController(ref.watch(supplierTripsRepositoryProvider));
});
