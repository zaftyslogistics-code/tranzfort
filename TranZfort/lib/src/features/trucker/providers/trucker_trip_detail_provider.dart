import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/trucker_trip_repository.dart';

class TruckerTripDetailState {
  final String tripId;
  final TruckerTripDetail? detail;
  final bool isLoading;
  final AppFailure? failure;

  const TruckerTripDetailState({
    required this.tripId,
    required this.detail,
    required this.isLoading,
    required this.failure,
  });

  factory TruckerTripDetailState.initial(String tripId) {
    return TruckerTripDetailState(
      tripId: tripId,
      detail: null,
      isLoading: true,
      failure: null,
    );
  }

  TruckerTripDetailState copyWith({
    TruckerTripDetail? detail,
    bool? clearDetail,
    bool? isLoading,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return TruckerTripDetailState(
      tripId: tripId,
      detail: clearDetail == true ? null : detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class TruckerTripDetailController extends StateNotifier<TruckerTripDetailState> {
  final TruckerTripsRepository _repository;

  TruckerTripDetailController(this._repository, String tripId)
      : super(TruckerTripDetailState.initial(tripId)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    
    // Add minimum loading duration to prevent flickering
    final startTime = DateTime.now();

    final result = await _repository.fetchTripDetail(state.tripId);
    await result.when(
      success: (detail) async {
        state = state.copyWith(detail: detail, isLoading: false, clearFailure: true);
      },
      failure: (failure) async {
        // Ensure minimum loading duration to prevent UI flicker
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 300) {
          await Future.delayed(Duration(milliseconds: 300 - elapsed));
        }
        state = state.copyWith(isLoading: false, failure: failure, clearDetail: true);
      },
    );
  }
}

final truckerTripDetailProvider = StateNotifierProvider.autoDispose
    .family<TruckerTripDetailController, TruckerTripDetailState, String>((ref, tripId) {
  return TruckerTripDetailController(ref.watch(truckerTripsRepositoryProvider), tripId);
});
