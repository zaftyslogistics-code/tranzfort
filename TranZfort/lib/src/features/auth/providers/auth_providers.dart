import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';
import '../data/auth_repository.dart';

class AuthScreenState {
  final bool isLoading;
  final bool isResendingVerification;
  final String? pendingVerificationEmail;
  final bool showCheckEmailState;
  final bool isSignUpMode;
  final bool authRefreshTimedOut;

  const AuthScreenState({
    this.isLoading = false,
    this.isResendingVerification = false,
    this.pendingVerificationEmail,
    this.showCheckEmailState = false,
    this.isSignUpMode = false,
    this.authRefreshTimedOut = false,
  });

  AuthScreenState copyWith({
    bool? isLoading,
    bool? isResendingVerification,
    String? pendingVerificationEmail,
    bool? clearPendingEmail,
    bool? showCheckEmailState,
    bool? isSignUpMode,
    bool? authRefreshTimedOut,
  }) {
    return AuthScreenState(
      isLoading: isLoading ?? this.isLoading,
      isResendingVerification: isResendingVerification ?? this.isResendingVerification,
      pendingVerificationEmail: clearPendingEmail == true ? null : pendingVerificationEmail ?? this.pendingVerificationEmail,
      showCheckEmailState: showCheckEmailState ?? this.showCheckEmailState,
      isSignUpMode: isSignUpMode ?? this.isSignUpMode,
      authRefreshTimedOut: authRefreshTimedOut ?? this.authRefreshTimedOut,
    );
  }
}

class OnboardingState {
  final bool isSubmitting;
  final bool authRefreshTimedOut;

  const OnboardingState({
    this.isSubmitting = false,
    this.authRefreshTimedOut = false,
  });
}

class OnboardingController extends AutoDisposeNotifier<OnboardingState> {
  static const String roleWorkspaceFailureCode = 'onboarding_role_workspace_failure';
  static const String termsAcceptanceRequiredCode = 'onboarding_terms_acceptance_required';

  @override
  OnboardingState build() => const OnboardingState();

  Future<Result<void>> updateRoleSelection(AppUserRole role) async {
    state = const OnboardingState(isSubmitting: true);
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.updateRoleSelection(role);
    
    if (result.isSuccess) {
      final extensionResult = await repository.provisionRoleExtension(role);
      if (extensionResult.isFailure) {
        state = const OnboardingState(isSubmitting: false);
        return const Failure<void>(
          BusinessRuleFailure(message: roleWorkspaceFailureCode),
        );
      }
      final refreshed = await _refreshAuthState();
      if (!refreshed) {
        state = const OnboardingState(isSubmitting: false, authRefreshTimedOut: true);
        return result;
      }
    }
    
    state = const OnboardingState(isSubmitting: false);
    return result;
  }

  Future<Result<void>> updateProfile({
    required String fullName,
    required String mobile,
    required bool termsAccepted,
    double? latitude,
    double? longitude,
  }) async {
    if (!termsAccepted) {
      return Failure<void>(BusinessRuleFailure(message: termsAcceptanceRequiredCode));
    }

    state = const OnboardingState(isSubmitting: true);
    final repository = ref.read(authRepositoryProvider);

    final updateResult = await repository.updateProfile(
      fullName: fullName,
      mobile: mobile,
      latitude: latitude,
      longitude: longitude,
    );
    
    if (updateResult.isSuccess) {
      final refreshed = await _refreshAuthState();
      if (!refreshed) {
        state = const OnboardingState(isSubmitting: false, authRefreshTimedOut: true);
        return updateResult;
      }
    }
    
    state = const OnboardingState(isSubmitting: false);
    return updateResult;
  }

  /// Refreshes auth state with a 4-second timeout.
  /// Returns `true` if the refresh completed, `false` on timeout.
  /// Callers should check the return value and set `authRefreshTimedOut`
  /// in state if the UI needs to warn the user.
  Future<bool> _refreshAuthState() async {
    ref.invalidate(authStateProvider);
    try {
      await ref.read(authStateProvider.future).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      AppLogger.warning('Auth state refresh timed out or failed', scope: 'auth', error: e);
      return false;
    }
  }
}

final onboardingControllerProvider = AutoDisposeNotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
class AuthScreenController extends AutoDisposeNotifier<AuthScreenState> {
  @override
  AuthScreenState build() => const AuthScreenState();

  void setSignUpMode(bool isSignUp) {
    state = state.copyWith(isSignUpMode: isSignUp, showCheckEmailState: false, clearPendingEmail: true);
  }

  void openCheckEmailState(String email) {
    state = state.copyWith(
      isSignUpMode: false,
      showCheckEmailState: true,
      pendingVerificationEmail: email,
    );
  }

  void returnToSignIn() {
    state = state.copyWith(
      isSignUpMode: false,
      showCheckEmailState: false,
    );
  }

  void editEmailForSignUp() {
    state = state.copyWith(
      isSignUpMode: true,
      showCheckEmailState: false,
      clearPendingEmail: true,
    );
  }

  Future<Result<void>> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(authRepositoryProvider).signInWithGoogle();
    state = state.copyWith(isLoading: false);
    
    if (result.isSuccess) {
      final refreshed = await _refreshAuthState();
      if (!refreshed) {
        state = state.copyWith(authRefreshTimedOut: true);
      }
    }
    
    return result;
  }

  Future<Result<void>> signInWithEmail({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(authRepositoryProvider).signInWithPassword(email: email, password: password);
    state = state.copyWith(isLoading: false);
    
    if (result.isSuccess) {
      final refreshed = await _refreshAuthState();
      if (!refreshed) {
        state = state.copyWith(authRefreshTimedOut: true);
      }
    }
    
    return result;
  }

  Future<Result<void>> signUpWithEmail({required String email, required String password}) async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(authRepositoryProvider).signUpWithPassword(email: email, password: password);
    state = state.copyWith(isLoading: false);
    
    if (result.isSuccess) {
      final refreshed = await _refreshAuthState();
      if (!refreshed) {
        state = state.copyWith(authRefreshTimedOut: true);
      }
      final refreshedAuthState = ref.read(currentAuthStateProvider);
      if (!refreshedAuthState.hasSession) {
        openCheckEmailState(email);
      }
    }
    
    return result;
  }

  Future<Result<void>> resetPassword({required String email}) async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(authRepositoryProvider).resetPasswordForEmail(email: email);
    state = state.copyWith(isLoading: false);
    return result;
  }

  Future<Result<void>> resendVerificationEmail({required String email}) async {
    state = state.copyWith(isResendingVerification: true);
    final result = await ref.read(authRepositoryProvider).resendSignUpVerificationEmail(email: email);
    state = state.copyWith(isResendingVerification: false);
    return result;
  }

  /// Refreshes auth state with a 4-second timeout.
  /// Returns `true` if the refresh completed, `false` on timeout.
  /// Callers should check the return value and set `authRefreshTimedOut`
  /// in state if the UI needs to warn the user.
  Future<bool> _refreshAuthState() async {
    ref.invalidate(authStateProvider);
    try {
      await ref.read(authStateProvider.future).timeout(const Duration(seconds: 4));
      return true;
    } catch (e) {
      AppLogger.warning('Auth state refresh timed out or failed', scope: 'auth', error: e);
      return false;
    }
  }
}

final authScreenControllerProvider = AutoDisposeNotifierProvider<AuthScreenController, AuthScreenState>(
  AuthScreenController.new,
);
