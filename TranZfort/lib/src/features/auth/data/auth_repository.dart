import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/validators.dart';
import 'auth_error_mapper.dart';
import 'auth_models.dart';
import 'auth_repository_profile_ops.dart';

export 'auth_models.dart';
export 'auth_repository_profile_ops.dart';

class AuthRepository {
  final SupabaseClient? _client;
  final GoogleSignIn _googleSignIn;
  final String _googleWebClientId;

  AuthRepository(
    this._client, {
    String googleWebClientId = '',
    GoogleSignIn? googleSignIn,
  }) : _googleWebClientId = googleWebClientId.trim(),
       _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: googleWebClientId.trim(),
            );

  Future<Result<void>> signInWithGoogle() async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    if (_googleWebClientId.isEmpty) {
      return const Failure<void>(
        BusinessRuleFailure(
          message: 'Google sign-in is not configured. Set GOOGLE_WEB_CLIENT_ID in the app environment and retry.',
        ),
      );
    }

    try {
      await _clearGoogleSession();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure<void>(
          ValidationFailure(
            message: 'Google sign in was cancelled. Please try again.',
          ),
        );
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) {
        return const Failure<void>(
          ValidationFailure(
            message: 'Unable to fetch Google sign-in token. Please try again.',
          ),
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> signOutAndClearLocalState() async {
    final clearPushTokenResult = await clearPushToken();
    if (clearPushTokenResult.isFailure) {
      return clearPushTokenResult;
    }

    final signOutResult = await signOut();
    if (signOutResult.isFailure) {
      return signOutResult;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      final hasSeenSplash = preferences.getBool('has_seen_splash');
      await preferences.clear();
      if (hasSeenSplash != null) {
        await preferences.setBool('has_seen_splash', hasSeenSplash);
      }

      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter a valid email address',
          fieldErrors: {'email': 'Valid email is required'},
        ),
      );
    }

    if (!_isValidPassword(password)) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter a password with at least 8 characters',
          fieldErrors: {'password': 'Minimum 8 characters required'},
        ),
      );
    }

    try {
      await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter a valid email address',
          fieldErrors: {'email': 'Valid email is required'},
        ),
      );
    }

    if (!_isValidPassword(password)) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter a password with at least 8 characters',
          fieldErrors: {'password': 'Minimum 8 characters required'},
        ),
      );
    }

    try {
      await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> resetPasswordForEmail({required String email}) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter a valid email address',
          fieldErrors: {'email': 'Valid email is required'},
        ),
      );
    }

    try {
      await _client.auth.resetPasswordForEmail(normalizedEmail);
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<Result<void>> resendSignUpVerificationEmail({required String email}) async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      return const Failure<void>(
        ValidationFailure(
          message: 'Enter a valid email address',
          fieldErrors: {'email': 'Valid email is required'},
        ),
      );
    }

    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: normalizedEmail,
      );
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  AuthProfileRepository get profileOps => AuthProfileRepository(_client);

  Future<Result<UserProfile?>> getCurrentProfile() => profileOps.getCurrentProfile();

  Stream<UserProfile?> watchCurrentProfile() => profileOps.watchCurrentProfile();

  Future<Result<void>> updateRoleSelection(AppUserRole role) => profileOps.updateRoleSelection(role);

  Future<Result<void>> provisionRoleExtension(AppUserRole role) => profileOps.provisionRoleExtension(role);

  Future<Result<void>> updateProfile({
    required String fullName,
    required String mobile,
    String? city,
    String? state,
    double? latitude,
    double? longitude,
  }) =>
      profileOps.updateProfile(
        fullName: fullName,
        mobile: mobile,
        city: city,
        state: state,
        latitude: latitude,
        longitude: longitude,
      );

  Future<Result<void>> updatePreferredLanguage(String languageCode) => profileOps.updatePreferredLanguage(languageCode);

  Future<Result<void>> recordTermsAcceptance() => profileOps.recordTermsAcceptance();

  Future<Result<AccountDeletionRequestOutcome>> requestAccountDeletion() => profileOps.requestAccountDeletion();

  Future<Result<AccountDeletionRequestOutcome>> cancelAccountDeletion() => profileOps.cancelAccountDeletion();

  Future<Result<void>> signOut() async {
    if (_client == null) {
      return const Success<void>(null);
    }

    try {
      await _client.auth.signOut();
      await _clearGoogleSession();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Future<void> _clearGoogleSession() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        try {
          await _googleSignIn.disconnect();
        } catch (e) {
          AppLogger.warning('Google disconnect failed, trying signOut', scope: 'auth', error: e);
          await _googleSignIn.signOut();
        }
      } else {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      AppLogger.warning('Google sign-out failed', scope: 'auth', error: e);
    }
  }

  String? _normalizeEmail(String raw) {
    return Validators.validateEmail(raw);
  }

  bool _isValidPassword(String raw) {
    return Validators.isValidPassword(raw);
  }

  Future<Result<void>> clearPushToken() async {
    if (_client == null) {
      return const Success<void>(null);
    }

    final user = _client.auth.currentUser;
    if (user == null) {
      return const Success<void>(null);
    }

    try {
      await _client.rpc('set_push_token', params: {'p_token': null});
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(mapAuthError(error, stackTrace));
    }
  }

  Result<Session?> getCurrentSession() {
    if (_client == null) {
      return const Success<Session?>(null);
    }

    try {
      return Success<Session?>(_client.auth.currentSession);
    } catch (error, stackTrace) {
      return Failure<Session?>(mapAuthError(error, stackTrace));
    }
  }

  Stream<AuthState> onAuthStateChange() {
    if (_client == null) {
      return const Stream<AuthState>.empty();
    }

    return _client.auth.onAuthStateChange;
  }

}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final appConfig = ref.watch(appConfigProvider);
  return AuthRepository(
    client,
    googleWebClientId: appConfig.supabaseConfig.googleWebClientId,
  );
});
