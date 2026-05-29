import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/providers/app_state_providers.dart';
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
  static const Duration _minLoadingDuration = Duration(milliseconds: 300);
  static const Duration _errorDebounceDuration = Duration(milliseconds: 300);

  final TruckerTripsRepository _repository;
  Timer? _errorDebounceTimer;

  TruckerTripsController(this._repository, {bool autoLoad = true}) : super(TruckerTripsState.initial()) {
    if (autoLoad) {
      load();
    }
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
    final stages = state.selectedTab == TruckerTripsTab.active
        ? TruckerTripsRepository.activeStages
        : TruckerTripsRepository.completedStages;
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

  Future<void> selectTab(TruckerTripsTab tab) async {
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

typedef _TruckerTripsAuthGate = ({bool isResolved, bool hasSession, String? userId});

final _truckerTripsAuthGateProvider = Provider<_TruckerTripsAuthGate>((ref) {
  final auth = ref.watch(currentAuthStateProvider);
  final userId = ref.watch(supabaseClientProvider)?.auth.currentUser?.id;
  return (isResolved: auth.isResolved, hasSession: auth.hasSession, userId: userId);
});

bool _truckerTripsCanFetch(_TruckerTripsAuthGate gate) {
  return gate.isResolved && gate.hasSession && gate.userId != null;
}

final truckerTripsProvider = StateNotifierProvider.autoDispose<TruckerTripsController, TruckerTripsState>((ref) {
  final repository = ref.watch(truckerTripsRepositoryProvider);
  final gate = ref.watch(_truckerTripsAuthGateProvider);
  final canFetch = _truckerTripsCanFetch(gate);
  final controller = TruckerTripsController(repository, autoLoad: canFetch);

  ref.listen<_TruckerTripsAuthGate>(_truckerTripsAuthGateProvider, (previous, next) {
    final wasReady = previous != null && _truckerTripsCanFetch(previous);
    final isReady = _truckerTripsCanFetch(next);
    if (!isReady || wasReady) {
      return;
    }
    if (controller.state.trips.isEmpty) {
      unawaited(controller.load());
    }
  });

  return controller;
});
