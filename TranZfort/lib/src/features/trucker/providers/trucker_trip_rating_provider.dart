import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/trucker_trip_repository.dart';

class TruckerTripRatingState {
  final bool isLoading;
  final bool isSubmitting;
  final int selectedScore;
  final String commentDraft;
  final TruckerTripRating? submittedRating;
  final AppFailure? failure;

  const TruckerTripRatingState({
    required this.isLoading,
    required this.isSubmitting,
    required this.selectedScore,
    required this.commentDraft,
    required this.submittedRating,
    required this.failure,
  });

  factory TruckerTripRatingState.initial() {
    return const TruckerTripRatingState(
      isLoading: true,
      isSubmitting: false,
      selectedScore: 0,
      commentDraft: '',
      submittedRating: null,
      failure: null,
    );
  }

  bool get hasSubmittedRating => submittedRating != null;

  TruckerTripRatingState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    int? selectedScore,
    String? commentDraft,
    TruckerTripRating? submittedRating,
    bool? clearSubmittedRating,
    AppFailure? failure,
    bool? clearFailure,
  }) {
    return TruckerTripRatingState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedScore: selectedScore ?? this.selectedScore,
      commentDraft: commentDraft ?? this.commentDraft,
      submittedRating: clearSubmittedRating == true ? null : submittedRating ?? this.submittedRating,
      failure: clearFailure == true ? null : failure ?? this.failure,
    );
  }
}

class TruckerTripRatingController extends StateNotifier<TruckerTripRatingState> {
  final TruckerTripsRepository _repository;
  final String _loadId;

  TruckerTripRatingController(this._repository, this._loadId)
      : super(TruckerTripRatingState.initial()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.fetchOwnRating(_loadId);
    result.when(
      success: (rating) {
        state = state.copyWith(
          isLoading: false,
          submittedRating: rating,
          selectedScore: rating?.score ?? state.selectedScore,
          commentDraft: rating?.comment ?? state.commentDraft,
          clearFailure: true,
        );
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false, failure: failure);
      },
    );
  }

  void setSelectedScore(int value) {
    state = state.copyWith(selectedScore: value, clearFailure: true);
  }

  void setCommentDraft(String value) {
    state = state.copyWith(commentDraft: value, clearFailure: true);
  }

  Future<Result<TruckerTripRating>> submit() async {
    if (state.isSubmitting) {
      return const Failure<TruckerTripRating>(
        BusinessRuleFailure(message: 'Your rating is already being submitted.'),
      );
    }

    state = state.copyWith(isSubmitting: true, clearFailure: true);
    final result = await _repository.submitRating(
      loadId: _loadId,
      score: state.selectedScore,
      comment: state.commentDraft,
    );
    if (result.isFailure) {
      state = state.copyWith(isSubmitting: false, failure: result.failureOrNull);
      return result;
    }

    state = state.copyWith(
      isSubmitting: false,
      submittedRating: result.valueOrNull,
      selectedScore: result.valueOrNull?.score ?? state.selectedScore,
      commentDraft: result.valueOrNull?.comment ?? state.commentDraft,
      clearFailure: true,
    );
    return result;
  }
}

final truckerTripRatingProvider = StateNotifierProvider.autoDispose
    .family<TruckerTripRatingController, TruckerTripRatingState, String>((ref, loadId) {
  return TruckerTripRatingController(ref.watch(truckerTripsRepositoryProvider), loadId);
});
