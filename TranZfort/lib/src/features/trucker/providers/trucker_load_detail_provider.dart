import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/trip_gps_capture_service.dart';
import '../data/trucker_load_detail_repository.dart';

// T-006: Error codes for localization (UI should map these to AppLocalizations)
class TruckerLoadDetailErrorCodes {
  static const String loadDetailUnavailable = 'trucker.load_detail_unavailable';
  static const String bookingAlreadyInProgress = 'trucker.booking_already_in_progress';
  static const String truckRequired = 'trucker.truck_required';
}

class TruckerLoadDetailState {
  final String loadId;
  final TruckerLoadDetail? detail;
  final List<TruckerApprovedTruck> approvedTrucks;
  final bool isLoading;
  final bool isSubmittingBooking;
  final String? selectedTruckId;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  const TruckerLoadDetailState({
    required this.loadId,
    required this.detail,
    required this.approvedTrucks,
    required this.isLoading,
    required this.isSubmittingBooking,
    required this.selectedTruckId,
    required this.failure,
    required this.actionFailure,
  });

  factory TruckerLoadDetailState.initial(String loadId) {
    return TruckerLoadDetailState(
      loadId: loadId,
      detail: null,
      approvedTrucks: const <TruckerApprovedTruck>[],
      isLoading: true,
      isSubmittingBooking: false,
      selectedTruckId: null,
      failure: null,
      actionFailure: null,
    );
  }

  TruckerLoadDetailState copyWith({
    TruckerLoadDetail? detail,
    bool? clearDetail,
    List<TruckerApprovedTruck>? approvedTrucks,
    bool? isLoading,
    bool? isSubmittingBooking,
    String? selectedTruckId,
    bool? clearSelectedTruckId,
    AppFailure? failure,
    bool? clearFailure,
    AppFailure? actionFailure,
    bool? clearActionFailure,
  }) {
    return TruckerLoadDetailState(
      loadId: loadId,
      detail: clearDetail == true ? null : detail ?? this.detail,
      approvedTrucks: approvedTrucks ?? this.approvedTrucks,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingBooking: isSubmittingBooking ?? this.isSubmittingBooking,
      selectedTruckId: clearSelectedTruckId == true ? null : selectedTruckId ?? this.selectedTruckId,
      failure: clearFailure == true ? null : failure ?? this.failure,
      actionFailure: clearActionFailure == true ? null : actionFailure ?? this.actionFailure,
    );
  }
}

class TruckerLoadDetailController extends StateNotifier<TruckerLoadDetailState> {
  final TruckerLoadDetailRepository _repository;
  final TripGpsCaptureService _gpsCaptureService;

  TruckerLoadDetailController(this._repository, this._gpsCaptureService, String loadId)
      : super(TruckerLoadDetailState.initial(loadId)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true, clearActionFailure: true);
    
    // Add minimum loading duration to prevent UI flicker
    final startTime = DateTime.now();
    
    final detailResult = await _repository.fetchLoadDetail(state.loadId);
    if (detailResult.isFailure) {
      // Ensure minimum loading duration to prevent UI flicker
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      if (elapsed < 300) {
        await Future.delayed(Duration(milliseconds: 300 - elapsed));
      }
      state = state.copyWith(isLoading: false, failure: detailResult.failureOrNull, approvedTrucks: const <TruckerApprovedTruck>[]);
      return;
    }

    final trucksResult = await _repository.fetchApprovedTrucks();
    await trucksResult.when(
      success: (trucks) async {
        final detail = detailResult.valueOrNull!;
        final selectedTruckId = _preferredTruckId(trucks, detail);
        // Ensure minimum loading duration to prevent UI flicker
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 300) {
          await Future.delayed(Duration(milliseconds: 300 - elapsed));
        }
        state = state.copyWith(
          detail: detail,
          approvedTrucks: trucks,
          selectedTruckId: selectedTruckId,
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
          detail: detailResult.valueOrNull,
          approvedTrucks: const <TruckerApprovedTruck>[],
          isLoading: false,
          failure: failure,
        );
      },
    );
  }

  void selectTruck(String? truckId) {
    state = state.copyWith(selectedTruckId: truckId, clearActionFailure: true);
  }

  Future<Result<String>> submitBookingRequest() async {
    final detail = state.detail;
    final truckId = state.selectedTruckId;
    if (detail == null) {
      return const Failure<String>(
        // TODO: Map to TruckerLoadDetailErrorCodes.loadDetailUnavailable in UI layer
        NotFoundFailure(message: 'Load detail is unavailable'),
      );
    }
    if (state.isSubmittingBooking) {
      return const Failure<String>(
        // TODO: Map to TruckerLoadDetailErrorCodes.bookingAlreadyInProgress in UI layer
        BusinessRuleFailure(message: 'Booking request is already in progress'),
      );
    }
    if (truckId == null || truckId.isEmpty) {
      return const Failure<String>(
        ValidationFailure(
          // TODO: Map to TruckerLoadDetailErrorCodes.truckRequired in UI layer
          message: 'Select a truck to continue',
          fieldErrors: {'truck_id': 'Truck is required'},
        ),
      );
    }

    state = state.copyWith(isSubmittingBooking: true, clearActionFailure: true);
    final gpsPoint = await _gpsCaptureService.captureBestEffort();
    final result = await _repository.submitBookingRequest(
      detail.summary.id,
      truckId,
      bookingGpsLat: gpsPoint?.latitude,
      bookingGpsLng: gpsPoint?.longitude,
    );
    if (result.isFailure) {
      state = state.copyWith(isSubmittingBooking: false, actionFailure: result.failureOrNull);
      return result;
    }

    state = state.copyWith(isSubmittingBooking: false, clearActionFailure: true);
    await load();
    return result;
  }

  String? _preferredTruckId(List<TruckerApprovedTruck> trucks, TruckerLoadDetail detail) {
    if (trucks.isEmpty) {
      return null;
    }
    for (final truck in trucks) {
      if (truckMatchesLoad(truck, detail.summary)) {
        return truck.id;
      }
    }
    return trucks.first.id;
  }
}

final truckerLoadDetailProvider = StateNotifierProvider.autoDispose
    .family<TruckerLoadDetailController, TruckerLoadDetailState, String>((ref, loadId) {
  return TruckerLoadDetailController(
    ref.watch(truckerLoadDetailRepositoryProvider),
    ref.watch(tripGpsCaptureServiceProvider),
    loadId,
  );
});

final truckerApprovedTrucksProvider = FutureProvider<List<TruckerApprovedTruck>>((ref) async {
  final result = await ref.watch(truckerLoadDetailRepositoryProvider).fetchApprovedTrucks();
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});
