import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../auth/data/auth_repository.dart';

class DeleteAccountState {
  final bool isSubmitting;
  final AppFailure? failure;
  final AccountDeletionRequestOutcome? outcome;

  const DeleteAccountState({
    required this.isSubmitting,
    required this.failure,
    required this.outcome,
  });

  factory DeleteAccountState.initial() {
    return const DeleteAccountState(
      isSubmitting: false,
      failure: null,
      outcome: null,
    );
  }

  DeleteAccountState copyWith({
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    AccountDeletionRequestOutcome? outcome,
    bool? clearOutcome,
  }) {
    return DeleteAccountState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      outcome: clearOutcome == true ? null : outcome ?? this.outcome,
    );
  }
}

class DeleteAccountController extends StateNotifier<DeleteAccountState> {
  final AuthRepository _repository;

  DeleteAccountController(this._repository) : super(DeleteAccountState.initial());

  Future<Result<AccountDeletionRequestOutcome>> submit() async {
    if (state.isSubmitting) {
      return const Failure<AccountDeletionRequestOutcome>(
        BusinessRuleFailure(message: 'Account deletion request is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearOutcome: true,
    );

    final result = await _repository.requestAccountDeletion();
    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      outcome: result.valueOrNull,
    );
    return result;
  }

  Future<Result<AccountDeletionRequestOutcome>> cancelDeletion() async {
    if (state.isSubmitting) {
      return const Failure<AccountDeletionRequestOutcome>(
        BusinessRuleFailure(message: 'Account deletion request is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearOutcome: true,
    );

    final result = await _repository.cancelAccountDeletion();
    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      outcome: result.valueOrNull,
    );
    return result;
  }
}

final deleteAccountProvider =
    StateNotifierProvider.autoDispose<DeleteAccountController, DeleteAccountState>((ref) {
  return DeleteAccountController(ref.watch(authRepositoryProvider));
});
