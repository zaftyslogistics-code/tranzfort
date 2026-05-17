import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../data/supplier_trip_repository.dart';

class SupplierTripDetailState {
  final SupplierTripDetail? detail;
  final bool isLoading;
  final AppFailure? failure;

  const SupplierTripDetailState({
    required this.detail,
    required this.isLoading,
    required this.failure,
  });

  factory SupplierTripDetailState.initial() {
    return const SupplierTripDetailState(
      detail: null,
      isLoading: true,
      failure: null,
    );
  }

  SupplierTripDetailState copyWith({
    SupplierTripDetail? detail,
    bool? clearDetail,
    bool? isLoading,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return SupplierTripDetailState(
      detail: clearDetail == true ? null : detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class SupplierTripDetailController extends StateNotifier<SupplierTripDetailState> {
  final SupplierTripsRepository _repository;
  final String _tripId;

  SupplierTripDetailController(this._repository, this._tripId)
      : super(SupplierTripDetailState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    
    // Add minimum loading duration to prevent flickering
    final startTime = DateTime.now();

    final result = await _repository.fetchTripDetail(_tripId);
    await result.when(
      success: (detail) async {
        state = state.copyWith(
          detail: detail,
          isLoading: false,
          clearFailure: true,
        );
      },
      failure: (failure) async {
        // Ensure minimum loading duration to prevent UI flicker
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 300) {
          await Future.delayed(Duration(milliseconds: 300 - elapsed));
        }
        state = state.copyWith(
          isLoading: false,
          failure: failure,
          clearDetail: true,
        );
      },
    );
  }
}

final supplierTripDetailProvider = StateNotifierProvider
    .family<SupplierTripDetailController, SupplierTripDetailState, String>((ref, tripId) {
  ref.onDispose(() {
    // Optional cleanup if needed
  });
  return SupplierTripDetailController(ref.watch(supplierTripsRepositoryProvider), tripId);
});
