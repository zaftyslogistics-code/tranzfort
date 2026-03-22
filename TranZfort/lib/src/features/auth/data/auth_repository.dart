import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

part 'auth_models.dart';
part 'auth_repository_profile_ops.dart';

class AuthRepository {
  final SupabaseClient? _client;
  final GoogleSignIn _googleSignIn;

  static String get _webClientId {
    try {
      return dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? Platform.environment['GOOGLE_WEB_CLIENT_ID'] ?? '';
    } catch (_) {
      return Platform.environment['GOOGLE_WEB_CLIENT_ID'] ?? '';
    }
  }

  AuthRepository(
    this._client, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: _webClientId,
            );

  Future<Result<void>> signInWithGoogle() async {
    if (_client == null) {
      return const Failure<void>(UnauthorizedFailure());
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
      return Failure<void>(_mapError(error, stackTrace));
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
      return Failure<void>(_mapError(error, stackTrace));
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
      return Failure<void>(_mapError(error, stackTrace));
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
      return Failure<void>(_mapError(error, stackTrace));
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
      return Failure<void>(_mapError(error, stackTrace));
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
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<Result<UserProfile?>> getCurrentProfile() {
    return AuthRepositoryProfileOps(this).getCurrentProfile();
  }

  Future<Result<void>> updateRoleSelection(AppUserRole role) {
    return AuthRepositoryProfileOps(this).updateRoleSelection(role);
  }

  Future<Result<void>> provisionRoleExtension(AppUserRole role) {
    return AuthRepositoryProfileOps(this).provisionRoleExtension(role);
  }

  Future<Result<void>> updateProfile({
    required String fullName,
    required String mobile,
  }) {
    return AuthRepositoryProfileOps(this).updateProfile(
      fullName: fullName,
      mobile: mobile,
    );
  }

  Future<Result<void>> updatePreferredLanguage(String languageCode) {
    return AuthRepositoryProfileOps(this).updatePreferredLanguage(languageCode);
  }

  Future<Result<void>> recordTermsAcceptance() {
    return AuthRepositoryProfileOps(this).recordTermsAcceptance();
  }

  Future<Result<AccountDeletionRequestOutcome>> requestAccountDeletion() {
    return AuthRepositoryProfileOps(this).requestAccountDeletion();
  }

  Future<Result<AccountDeletionRequestOutcome>> cancelAccountDeletion() {
    return AuthRepositoryProfileOps(this).cancelAccountDeletion();
  }

  Future<Result<void>> signOut() async {
    if (_client == null) {
      return const Success<void>(null);
    }

    try {
      await _client.auth.signOut();
      await _clearGoogleSession();
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Future<void> _clearGoogleSession() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        try {
          await _googleSignIn.disconnect();
        } catch (_) {
          await _googleSignIn.signOut();
        }
      } else {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
  }

  String? _normalizeEmail(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(trimmed)) {
      return null;
    }

    return trimmed.toLowerCase();
  }

  bool _isValidPassword(String raw) {
    return raw.trim().length >= 8;
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
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  Result<Session?> getCurrentSession() {
    if (_client == null) {
      return const Success<Session?>(null);
    }

    try {
      return Success<Session?>(_client.auth.currentSession);
    } catch (error, stackTrace) {
      return Failure<Session?>(_mapError(error, stackTrace));
    }
  }

  Stream<AuthState> onAuthStateChange() {
    if (_client == null) {
      return const Stream<AuthState>.empty();
    }

    return _client.auth.onAuthStateChange;
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) {
    if (error is SocketException || error is TimeoutException) {
      return NetworkFailure(debugInfo: error.toString());
    }

    if (error is AuthException) {
      final message = error.message.trim();
      final normalized = message.toLowerCase();

      if (normalized.contains('session') ||
          normalized.contains('expired') ||
          normalized.contains('refresh token') ||
          normalized.contains('refresh_token_not_found')) {
        return UnauthorizedFailure(message: message, debugInfo: stackTrace.toString());
      }

      if (normalized.contains('email not confirmed') ||
          normalized.contains('email not verified') ||
          normalized.contains('confirm your email') ||
          normalized.contains('email confirmation')) {
        return const BusinessRuleFailure(
          message:
              'Confirm your email before signing in. Open the verification email from TranZfort, finish verification, and then try again.',
        );
      }

      if (normalized.contains('redirect') || normalized.contains('oauth')) {
        return const BusinessRuleFailure(
          message:
              'Google auth redirect failed. Please update Supabase Google provider settings and Android client configuration, then retry.',
        );
      }

      if (normalized.contains('invalid')) {
        return ValidationFailure(
          message: message,
          debugInfo: stackTrace.toString(),
        );
      }

      return UnknownFailure(message: message, debugInfo: stackTrace.toString());
    }

    if (error is PostgrestException) {
      final code = error.code?.trim();
      final message = error.message.trim().isEmpty
          ? 'Something went wrong. Please try again.'
          : error.message.trim();
      final details = error.details?.toString();

      if (code == '42501') {
        return PermissionFailure(message: message, debugInfo: details);
      }

      if (code == '23505') {
        return ConflictFailure(message: message, debugInfo: details);
      }

      if (code == 'PGRST116') {
        return NotFoundFailure(message: message, debugInfo: details);
      }

      return ServerFailure(message: message, debugInfo: details);
    }

    return UnknownFailure(
      debugInfo: '$error\n$stackTrace',
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});
