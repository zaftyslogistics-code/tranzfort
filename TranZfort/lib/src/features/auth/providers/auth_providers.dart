import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  final config = ref.watch(supabaseConfiguredProvider);
  if (!config) {
    throw Exception('Supabase is not configured yet');
  }
  return Supabase.instance.client;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    // The Web Client ID is used as the serverClientId to obtain the idToken
    serverClientId:
        '87956220473-fo2gcntk9p05ttp0shb8bta7997emm8l.apps.googleusercontent.com',
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(googleSignInProvider),
  );
});

final authSessionProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) return null;

  final response = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select('user_role_type')
      .eq('id', user.id)
      .single();

  return response['user_role_type'] as String?;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) return null;

  final response = await ref
      .watch(supabaseClientProvider)
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();

  return response;
});

class AuthEntryState {
  final bool isLoading;
  final AppFailureType? lastError;

  const AuthEntryState({this.isLoading = false, this.lastError});

  AuthEntryState copyWith({
    bool? isLoading,
    AppFailureType? lastError,
    bool clearError = false,
  }) {
    return AuthEntryState(
      isLoading: isLoading ?? this.isLoading,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class AuthEntryNotifier extends StateNotifier<AuthEntryState> {
  final Ref _ref;

  AuthEntryNotifier(this._ref) : super(const AuthEntryState());

  Future<Result<void>> continueWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _ref.read(authRepositoryProvider).signInWithGoogle();
    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return const Success(null);
      case Failure(type: final type, debugMessage: final message):
        state = state.copyWith(isLoading: false, lastError: type);
        return Failure(type, debugMessage: message);
    }
  }

  Future<Result<void>> sendOtp(String formattedPhone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _ref.read(authRepositoryProvider).sendOtp(formattedPhone);
    switch (result) {
      case Success():
        state = state.copyWith(isLoading: false, clearError: true);
        return const Success(null);
      case Failure(type: final type, debugMessage: final message):
        state = state.copyWith(isLoading: false, lastError: type);
        return Failure(type, debugMessage: message);
    }
  }
}

final authEntryProvider =
    StateNotifierProvider<AuthEntryNotifier, AuthEntryState>((ref) {
      return AuthEntryNotifier(ref);
    });

class OtpVerificationState {
  final bool isVerifying;
  final AppFailureType? lastError;

  const OtpVerificationState({this.isVerifying = false, this.lastError});

  OtpVerificationState copyWith({
    bool? isVerifying,
    AppFailureType? lastError,
    bool clearError = false,
  }) {
    return OtpVerificationState(
      isVerifying: isVerifying ?? this.isVerifying,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class OtpVerificationNotifier extends StateNotifier<OtpVerificationState> {
  final Ref _ref;

  OtpVerificationNotifier(this._ref) : super(const OtpVerificationState());

  Future<Result<void>> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    final result = await _ref.read(authRepositoryProvider).verifyOtp(phone, otp);
    switch (result) {
      case Success():
        state = state.copyWith(isVerifying: false, clearError: true);
        return const Success(null);
      case Failure(type: final type, debugMessage: final message):
        state = state.copyWith(isVerifying: false, lastError: type);
        return Failure(type, debugMessage: message);
    }
  }
}

final authOtpVerificationProvider = StateNotifierProvider<OtpVerificationNotifier,
    OtpVerificationState>((ref) {
  return OtpVerificationNotifier(ref);
});

class RoleSetupState {
  final bool isSubmitting;
  final AppFailureType? lastError;

  const RoleSetupState({this.isSubmitting = false, this.lastError});

  RoleSetupState copyWith({
    bool? isSubmitting,
    AppFailureType? lastError,
    bool clearError = false,
  }) {
    return RoleSetupState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class RoleSetupNotifier extends StateNotifier<RoleSetupState> {
  final Ref _ref;

  RoleSetupNotifier(this._ref) : super(const RoleSetupState());

  Future<Result<void>> submitRole(String role) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final user = _ref.read(supabaseClientProvider).auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isSubmitting: false,
          lastError: AppFailureType.auth,
        );
        return const Failure(AppFailureType.auth);
      }

      await _ref
          .read(supabaseClientProvider)
          .from('profiles')
          .update({
            'user_role_type': role,
            'privacy_consent_at': DateTime.now().toIso8601String(),
            'privacy_consent_version': '1.0',
          })
          .eq('id', user.id);

      await _ref.read(supabaseClientProvider).from('user_consents').insert({
        'profile_id': user.id,
        'consent_type': 'terms_and_privacy',
        'consent_version': '1.0',
      });

      if (role == 'supplier') {
        await _ref.read(supabaseClientProvider).from('suppliers').insert({
          'id': user.id,
        });
      } else if (role == 'trucker') {
        await _ref.read(supabaseClientProvider).from('truckers').insert({
          'id': user.id,
        });
      }

      _ref.invalidate(userProfileProvider);
      _ref.invalidate(userRoleProvider);

      state = state.copyWith(isSubmitting: false, clearError: true);
      return const Success(null);
    } catch (e) {
      final type = classifyError(e);
      state = state.copyWith(isSubmitting: false, lastError: type);
      return Failure(type, debugMessage: e.toString());
    }
  }
}

final authRoleSetupProvider =
    StateNotifierProvider<RoleSetupNotifier, RoleSetupState>((ref) {
      return RoleSetupNotifier(ref);
    });
