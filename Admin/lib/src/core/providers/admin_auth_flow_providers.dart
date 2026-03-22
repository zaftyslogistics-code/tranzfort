import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/admin_auth_repository.dart';

class AdminLoginState {
  final bool isLoading;
  final AdminSignInFailureReason? failureReason;
  final bool passwordResetSent;

  const AdminLoginState({
    required this.isLoading,
    this.failureReason,
    required this.passwordResetSent,
  });

  factory AdminLoginState.initial() {
    return const AdminLoginState(
      isLoading: false,
      failureReason: null,
      passwordResetSent: false,
    );
  }

  AdminLoginState copyWith({
    bool? isLoading,
    AdminSignInFailureReason? failureReason,
    bool clearFailure = false,
    bool? passwordResetSent,
  }) {
    return AdminLoginState(
      isLoading: isLoading ?? this.isLoading,
      failureReason: clearFailure ? null : (failureReason ?? this.failureReason),
      passwordResetSent: passwordResetSent ?? this.passwordResetSent,
    );
  }
}

class AdminLoginController extends StateNotifier<AdminLoginState> {
  final AdminAuthRepository _repository;

  AdminLoginController(this._repository) : super(AdminLoginState.initial());

  Future<AdminSignInResult> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true, passwordResetSent: false);
    final result = await _repository.signInWithPassword(
      email: email,
      password: password,
    );
    state = state.copyWith(
      isLoading: false,
      failureReason: result.failureReason,
      clearFailure: result.isSuccess,
    );
    return result;
  }

  Future<bool> requestPasswordReset(String email) async {
    state = state.copyWith(isLoading: true, clearFailure: true, passwordResetSent: false);
    final ok = await _repository.requestPasswordReset(email: email);
    state = state.copyWith(
      isLoading: false,
      passwordResetSent: ok,
    );
    return ok;
  }

  void clearStatus() {
    state = state.copyWith(
      clearFailure: true,
      passwordResetSent: false,
    );
  }
}

final adminLoginControllerProvider = StateNotifierProvider<AdminLoginController, AdminLoginState>((ref) {
  return AdminLoginController(ref.watch(adminAuthRepositoryProvider));
});
