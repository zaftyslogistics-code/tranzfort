import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/supplier_load_models.dart';
import '../data/supplier_load_repository.dart';

class LoadDetailState {
  final String loadId;
  final LoadDetail? detail;
  final List<LoadBookingRequest> bookingRequests;
  final List<LinkedTrip> linkedTrips;
  final bool isLoading;
  final bool isCancelling;
  final bool isClosingFilledOutsideApp;
  final String? approvingBookingId;
  final String? rejectingBookingId;
  final AppFailure? failure;
  final AppFailure? actionFailure;

  const LoadDetailState({
    required this.loadId,
    required this.detail,
    required this.bookingRequests,
    required this.linkedTrips,
    required this.isLoading,
    required this.isCancelling,
    required this.isClosingFilledOutsideApp,
    required this.approvingBookingId,
    required this.rejectingBookingId,
    required this.failure,
    required this.actionFailure,
  });

  factory LoadDetailState.initial(String loadId) {
    return LoadDetailState(
      loadId: loadId,
      detail: null,
      bookingRequests: const <LoadBookingRequest>[],
      linkedTrips: const <LinkedTrip>[],
      isLoading: true,
      isCancelling: false,
      isClosingFilledOutsideApp: false,
      approvingBookingId: null,
      rejectingBookingId: null,
      failure: null,
      actionFailure: null,
    );
  }

  LoadDetailState copyWith({
    LoadDetail? detail,
    bool? clearDetail,
    List<LoadBookingRequest>? bookingRequests,
    List<LinkedTrip>? linkedTrips,
    bool? isLoading,
    bool? isCancelling,
    bool? isClosingFilledOutsideApp,
    String? approvingBookingId,
    bool? clearApprovingBookingId,
    String? rejectingBookingId,
    bool? clearRejectingBookingId,
    AppFailure? failure,
    bool? clearFailure,
    AppFailure? actionFailure,
    bool? clearActionFailure,
  }) {
    return LoadDetailState(
      loadId: loadId,
      detail: clearDetail == true ? null : detail ?? this.detail,
      bookingRequests: bookingRequests ?? this.bookingRequests,
      linkedTrips: linkedTrips ?? this.linkedTrips,
      isLoading: isLoading ?? this.isLoading,
      isCancelling: isCancelling ?? this.isCancelling,
      isClosingFilledOutsideApp: isClosingFilledOutsideApp ?? this.isClosingFilledOutsideApp,
      approvingBookingId: clearApprovingBookingId == true
          ? null
          : approvingBookingId ?? this.approvingBookingId,
      rejectingBookingId: clearRejectingBookingId == true
          ? null
          : rejectingBookingId ?? this.rejectingBookingId,
      failure: clearFailure == true ? null : failure ?? this.failure,
      actionFailure: clearActionFailure == true ? null : actionFailure ?? this.actionFailure,
    );
  }
}

class LoadDetailController extends StateNotifier<LoadDetailState> {
  final SupplierLoadRepository _repository;

  LoadDetailController(this._repository, String loadId) : super(LoadDetailState.initial(loadId)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    
    // Debug log: Start loading
    debugPrint('🔍 [LoadDetail] Loading details for loadId: ${state.loadId}');
    
    final detailResult = await _repository.getLoadDetail(state.loadId);
    if (detailResult.isFailure) {
      debugPrint('❌ [LoadDetail] getLoadDetail FAILED: ${detailResult.failureOrNull}');
      debugPrint('   Failure type: ${detailResult.failureOrNull.runtimeType}');
      debugPrint('   Failure message: ${detailResult.failureOrNull.toString()}');
      state = state.copyWith(
        isLoading: false,
        failure: detailResult.failureOrNull,
      );
      return;
    }
    debugPrint('✅ [LoadDetail] getLoadDetail SUCCESS');

    final bookingsResult = await _repository.getBookingRequests(state.loadId);
    if (bookingsResult.isFailure) {
      debugPrint('❌ [LoadDetail] getBookingRequests FAILED: ${bookingsResult.failureOrNull}');
      debugPrint('   Failure type: ${bookingsResult.failureOrNull.runtimeType}');
      debugPrint('   Failure message: ${bookingsResult.failureOrNull.toString()}');
      state = state.copyWith(
        isLoading: false,
        detail: detailResult.valueOrNull,
        failure: bookingsResult.failureOrNull,
      );
      return;
    }
    debugPrint('✅ [LoadDetail] getBookingRequests SUCCESS: ${bookingsResult.valueOrNull?.length} bookings');

    final linkedTripsResult = await _repository.getLinkedTrips(state.loadId);
    linkedTripsResult.when(
      success: (linkedTrips) {
        debugPrint('✅ [LoadDetail] getLinkedTrips SUCCESS: ${linkedTrips.length} trips');
        state = state.copyWith(
          detail: detailResult.valueOrNull,
          bookingRequests: bookingsResult.valueOrNull ?? const <LoadBookingRequest>[],
          linkedTrips: linkedTrips,
          isLoading: false,
          clearFailure: true,
        );
      },
      failure: (failure) {
        debugPrint('❌ [LoadDetail] getLinkedTrips FAILED: $failure');
        debugPrint('   Failure type: ${failure.runtimeType}');
        debugPrint('   Failure message: ${failure.toString()}');
        state = state.copyWith(
          isLoading: false,
          detail: detailResult.valueOrNull,
          bookingRequests: bookingsResult.valueOrNull ?? const <LoadBookingRequest>[],
          failure: failure,
        );
      },
    );
    
    debugPrint('🎉 [LoadDetail] Load complete - Failure: ${state.failure}');
  }

  Future<Result<void>> cancelLoad() async {
    if (state.isCancelling) {
      return const Failure<void>(BusinessRuleFailure(message: 'Cancellation is already in progress'));
    }

    state = state.copyWith(isCancelling: true, clearActionFailure: true);
    final result = await _repository.cancelLoad(state.loadId);
    if (result.isFailure) {
      state = state.copyWith(isCancelling: false, actionFailure: result.failureOrNull);
      return result;
    }

    state = state.copyWith(isCancelling: false, clearActionFailure: true);
    await load();
    return result;
  }

  Future<Result<void>> closeFilledOutsideApp() async {
    if (state.isClosingFilledOutsideApp) {
      return const Failure<void>(BusinessRuleFailure(message: 'Close action is already in progress'));
    }

    state = state.copyWith(isClosingFilledOutsideApp: true, clearActionFailure: true);
    final result = await _repository.closeFilledOutsideApp(state.loadId);
    if (result.isFailure) {
      state = state.copyWith(isClosingFilledOutsideApp: false, actionFailure: result.failureOrNull);
      return result;
    }

    state = state.copyWith(isClosingFilledOutsideApp: false, clearActionFailure: true);
    await load();
    return result;
  }

  Future<Result<String>> approveBookingRequest(String bookingId) async {
    if (state.approvingBookingId != null || state.rejectingBookingId != null) {
      return const Failure<String>(BusinessRuleFailure(message: 'Another booking action is already in progress'));
    }

    state = state.copyWith(
      approvingBookingId: bookingId,
      clearApprovingBookingId: false,
      clearActionFailure: true,
    );
    final result = await _repository.approveBookingRequest(bookingId);
    if (result.isFailure) {
      state = state.copyWith(
        clearApprovingBookingId: true,
        actionFailure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(clearApprovingBookingId: true, clearActionFailure: true);
    await load();
    return result;
  }

  Future<Result<void>> rejectBookingRequest(String bookingId, {String? reason}) async {
    if (state.approvingBookingId != null || state.rejectingBookingId != null) {
      return const Failure<void>(BusinessRuleFailure(message: 'Another booking action is already in progress'));
    }

    state = state.copyWith(
      rejectingBookingId: bookingId,
      clearRejectingBookingId: false,
      clearActionFailure: true,
    );
    final result = await _repository.rejectBookingRequest(bookingId, reason: reason);
    if (result.isFailure) {
      state = state.copyWith(
        clearRejectingBookingId: true,
        actionFailure: result.failureOrNull,
      );
      return result;
    }

    state = state.copyWith(clearRejectingBookingId: true, clearActionFailure: true);
    await load();
    return result;
  }
}

final loadDetailProvider = StateNotifierProvider.autoDispose.family<LoadDetailController, LoadDetailState, String>((ref, loadId) {
  return LoadDetailController(ref.watch(supplierLoadRepositoryProvider), loadId);
});
