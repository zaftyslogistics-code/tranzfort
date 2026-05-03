import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/supplier_trip_repository.dart';
import 'supplier_trip_detail_provider.dart';

// S-004: Error codes for localization (UI should map these to AppLocalizations)
class SupplierTripActionErrorCodes {
  static const String actionAlreadyInProgress = 'supplier.trip_action_already_in_progress';
}

const List<String> supplierTripDisputeCategories = SupplierTripsRepository.disputeCategories;

class SupplierTripActionState {
  final bool isSubmitting;
  final String? pendingStage;
  final AppFailure? failure;

  const SupplierTripActionState({
    required this.isSubmitting,
    required this.pendingStage,
    required this.failure,
  });

  factory SupplierTripActionState.initial() {
    return const SupplierTripActionState(
      isSubmitting: false,
      pendingStage: null,
      failure: null,
    );
  }

  SupplierTripActionState copyWith({
    bool? isSubmitting,
    String? pendingStage,
    bool? clearPendingStage,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return SupplierTripActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pendingStage: clearPendingStage == true ? null : pendingStage ?? this.pendingStage,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class SupplierTripActionController extends StateNotifier<SupplierTripActionState> {
  final Ref _ref;
  final SupplierTripsRepository _repository;
  final String _tripId;

  SupplierTripActionController(this._ref, this._repository, this._tripId)
      : super(SupplierTripActionState.initial());

  Future<Result<String>> cancelTrip() async {
    if (state.isSubmitting) {
      return const Failure<String>(
        // TODO: Map to SupplierTripActionErrorCodes.actionAlreadyInProgress in UI layer
        BusinessRuleFailure(message: 'Another supplier trip action is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      pendingStage: 'cancelled',
      clearPendingStage: false,
      clearFailure: true,
    );

    final result = await _repository.cancelTrip(_tripId);
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
    await _ref.read(supplierTripDetailProvider(_tripId).notifier).load();
    return result;
  }

  Future<Result<String>> confirmDelivery() async {
    if (state.isSubmitting) {
      return const Failure<String>(
        // TODO: Map to SupplierTripActionErrorCodes.actionAlreadyInProgress in UI layer
        BusinessRuleFailure(message: 'Another supplier trip action is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      pendingStage: 'completed',
      clearPendingStage: false,
      clearFailure: true,
    );

    final result = await _repository.confirmTripDelivery(_tripId);
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
    await _ref.read(supplierTripDetailProvider(_tripId).notifier).load();
    return result;
  }

  Future<Result<String>> raiseDispute({
    required String category,
    required String reason,
    String? attachmentPath,
  }) async {
    if (state.isSubmitting) {
      return const Failure<String>(
        // TODO: Map to SupplierTripActionErrorCodes.actionAlreadyInProgress in UI layer
        BusinessRuleFailure(message: 'Another supplier trip action is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      pendingStage: 'disputed',
      clearPendingStage: false,
      clearFailure: true,
    );

    final result = await _repository.raiseTripDispute(
      tripId: _tripId,
      category: category,
      reason: reason,
      attachmentPath: attachmentPath,
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
    await _ref.read(supplierTripDetailProvider(_tripId).notifier).load();
    return result;
  }
}

final supplierTripActionProvider = StateNotifierProvider.autoDispose
    .family<SupplierTripActionController, SupplierTripActionState, String>((ref, tripId) {
  return SupplierTripActionController(ref, ref.watch(supplierTripsRepositoryProvider), tripId);
});
