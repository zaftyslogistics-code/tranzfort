import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../error/app_failure.dart';
import '../error/result.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRepository(this._supabase, this._googleSignIn);

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<Result<User>> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'Google sign in aborted by user',
        );
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'Missing Google tokens',
        );
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'Supabase sign in failed',
        );
      }

      return Success(response.user!);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> sendOtp(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(phone: phone);
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<User>> verifyOtp(String phone, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: phone,
      );

      if (response.user == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'OTP verification failed',
        );
      }

      return Success(response.user!);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}
