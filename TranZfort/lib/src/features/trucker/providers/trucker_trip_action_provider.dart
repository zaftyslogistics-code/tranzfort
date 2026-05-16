import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/lifecycle_status_constants.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/models/domain_statuses.dart';
import '../data/trip_gps_capture_service.dart';
import '../data/trip_proof_upload_service.dart';
import '../data/trucker_trip_repository.dart';
import 'trucker_trip_detail_provider.dart';

// T-006: Error codes for localization (UI should map these to AppLocalizations)
class TruckerTripActionErrorCodes {
  static const String actionAlreadyInProgress = 'trucker.trip_action_already_in_progress';
  static const String cannotAdvanceFromCurrentStage = 'trucker.trip_cannot_advance_from_current_stage';
  static const String podUploadOnlyAfterDelivery = 'trucker.trip_pod_upload_only_after_delivery';
  static const String lrUploadOnlyDuringPickup = 'trucker.trip_lr_upload_only_during_pickup';
}

class TruckerTripActionState {
  final bool isSubmitting;
  final String? pendingStage;
  final AppFailure? failure;

  const TruckerTripActionState({
    required this.isSubmitting,
    required this.pendingStage,
    required this.failure,
  });

  factory TruckerTripActionState.initial() {
    return const TruckerTripActionState(
      isSubmitting: false,
      pendingStage: null,
      failure: null,
    );
  }

  TruckerTripActionState copyWith({
    bool? isSubmitting,
    String? pendingStage,
    bool? clearPendingStage,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return TruckerTripActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingStage: clearPendingStage == true ? null : pendingStage ?? this.pendingStage,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class TruckerTripActionController extends StateNotifier<TruckerTripActionState> {
  final Ref _ref;
  final TruckerTripsRepository _repository;
  final TripGpsCaptureService _gpsCaptureService;
  final TripProofUploadService _proofUploadService;
  final String _tripId;

  TruckerTripActionController(
    this._ref,
    this._repository,
    this._gpsCaptureService,
    this._proofUploadService,
    this._tripId,
  ) : super(TruckerTripActionState.initial());

  Future<Result<String>> advanceFromCurrentStage(String currentStage) async {
    if (state.isSubmitting) {
      return const Failure<String>(
        BusinessRuleFailure(message: TruckerTripActionErrorCodes.actionAlreadyInProgress),
      );
    }

    final nextStage = TruckerTripsRepository.nextStageFor(currentStage);
    if (nextStage == null) {
      const failure = BusinessRuleFailure(
        message: TruckerTripActionErrorCodes.cannotAdvanceFromCurrentStage,
      );
      state = state.copyWith(failure: failure, clearFailure: false);
      return const Failure<String>(failure);
    }

    state = state.copyWith(
      isSubmitting: true,
      pendingStage: nextStage,
      clearPendingStage: false,
      clearFailure: true,
    );

    final gpsPoint = _requiresGps(nextStage) ? await _gpsCaptureService.captureBestEffort() : null;
    final result = await _repository.advanceTripStage(
      tripId: _tripId,
      currentStage: currentStage,
      newStage: nextStage,
      gpsLat: gpsPoint?.latitude,
      gpsLng: gpsPoint?.longitude,
    );

    if (result.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        failure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(
      isSubmitting: false,
      clearPendingStage: true,
      clearFailure: true,
    );
    await _ref.read(truckerTripDetailProvider(_tripId).notifier).load();
    return result;
  }

  Future<Result<bool>> uploadPodProof({
    required String currentStage,
    required ImageSource source,
  }) async {
    if (state.isSubmitting) {
      return const Failure<bool>(
        BusinessRuleFailure(message: TruckerTripActionErrorCodes.actionAlreadyInProgress),
      );
    }

    if (currentStage != 'delivered') {
      const failure = BusinessRuleFailure(
        message: TruckerTripActionErrorCodes.podUploadOnlyAfterDelivery,
      );
      state = state.copyWith(failure: failure, clearFailure: false);
      return const Failure<bool>(failure);
    }

    state = state.copyWith(
      isSubmitting: true,
      pendingStage: TripStage.proofSubmitted.toDatabaseValue(),
      clearPendingStage: false,
      clearFailure: true,
    );

    final uploadResult = await _proofUploadService.pickCompressAndUploadPod(
      tripId: _tripId,
      source: source,
    );
    if (uploadResult.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        failure: uploadResult.failureOrNull,
      );
      return Failure<bool>(uploadResult.failureOrNull!);
    }

    final podPath = uploadResult.valueOrNull;
    if (podPath == null) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        clearFailure: true,
      );
      return const Success<bool>(false);
    }

    final gpsPoint = await _gpsCaptureService.captureBestEffort();
    final result = await _repository.uploadTripProof(
      tripId: _tripId,
      podPath: podPath,
      gpsLat: gpsPoint?.latitude,
      gpsLng: gpsPoint?.longitude,
    );
    if (result.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        failure: result.failureOrNull,
      );
      return Failure<bool>(result.failureOrNull!);
    }

    state = state.copyWith(
      isSubmitting: false,
      clearPendingStage: true,
      clearFailure: true,
    );
    await _ref.read(truckerTripDetailProvider(_tripId).notifier).load();
    return const Success<bool>(true);
  }

  Future<Result<bool>> uploadLrProof({
    required String currentStage,
    required ImageSource source,
  }) async {
    if (state.isSubmitting) {
      return const Failure<bool>(
        BusinessRuleFailure(message: TruckerTripActionErrorCodes.actionAlreadyInProgress),
      );
    }

    if (!TripStages.allowsLrUpload.contains(currentStage)) {
      const failure = BusinessRuleFailure(
        message: TruckerTripActionErrorCodes.lrUploadOnlyDuringPickup,
      );
      state = state.copyWith(failure: failure, clearFailure: false);
      return const Failure<bool>(failure);
    }

    state = state.copyWith(
      isSubmitting: true,
      pendingStage: TripStage.pickupPending.toDatabaseValue(),
      clearPendingStage: false,
      clearFailure: true,
    );

    final uploadResult = await _proofUploadService.pickCompressAndUploadLr(
      tripId: _tripId,
      source: source,
    );
    if (uploadResult.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        failure: uploadResult.failureOrNull,
      );
      return Failure<bool>(uploadResult.failureOrNull!);
    }

    final lrPath = uploadResult.valueOrNull;
    if (lrPath == null) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        clearFailure: true,
      );
      return const Success<bool>(false);
    }

    final result = await _repository.uploadTripLr(
      tripId: _tripId,
      currentStage: currentStage,
      lrPath: lrPath,
    );
    if (result.isFailure) {
      state = state.copyWith(
        isSubmitting: false,
        clearPendingStage: true,
        failure: result.failureOrNull,
      );
      return Failure<bool>(result.failureOrNull!);
    }

    state = state.copyWith(
      isSubmitting: false,
      clearPendingStage: true,
      clearFailure: true,
    );
    await _ref.read(truckerTripDetailProvider(_tripId).notifier).load();
    return const Success<bool>(true);
  }

  bool _requiresGps(String stage) {
    final currentStage = TripStage.fromDatabase(stage);
    return currentStage == TripStage.pickupPending ||
        currentStage == TripStage.pickedUp ||
        currentStage == TripStage.delivered;
  }
}

final truckerTripActionProvider = StateNotifierProvider.autoDispose
    .family<TruckerTripActionController, TruckerTripActionState, String>((ref, tripId) {
  return TruckerTripActionController(
    ref,
    ref.watch(truckerTripsRepositoryProvider),
    ref.watch(tripGpsCaptureServiceProvider),
    ref.watch(tripProofUploadServiceProvider),
    tripId,
  );
});
