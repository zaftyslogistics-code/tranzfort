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
      await _clearGoogleSession();

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

  Future<Result<void>> saveMobileNumber(String formattedPhone) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Failure(
          AppFailureType.auth,
          debugMessage: 'No active session',
        );
      }

      await _supabase
          .from('profiles')
          .update({'mobile': formattedPhone})
          .eq('id', user.id);

      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      await _clearGoogleSession();
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
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

  Future<Result<Map<String, dynamic>>> fetchProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) {
        return const Failure(AppFailureType.notFound, debugMessage: 'Profile not found');
      }
      return Success(response);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<String?>> fetchUserRole(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('user_role_type')
          .eq('id', userId)
          .maybeSingle();
      
      return Success(response?['user_role_type'] as String?);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<String?>> fetchTruckerDlExpiryDate(String userId) async {
    try {
      final response = await _supabase
          .from('truckers')
          .select('dl_expiry_date')
          .eq('id', userId)
          .maybeSingle();

      return Success(response?['dl_expiry_date']?.toString());
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> updateProfile(String userId, {String? role, String? mobile}) async {
    try {
      final Map<String, dynamic> data = {};
      if (role != null) data['user_role_type'] = role;
      if (mobile != null) data['mobile'] = mobile;
      
      if (data.isNotEmpty) {
        await _supabase.from('profiles').update(data).eq('id', userId);
      }
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> recordPrivacyConsent(String userId, String version) async {
    try {
      await _supabase.from('user_consents').insert({
        'profile_id': userId,
        'consent_type': 'terms_and_privacy',
        'consent_version': version,
      });
      
      await _supabase.from('profiles').update({
        'privacy_consent_at': DateTime.now().toIso8601String(),
        'privacy_consent_version': version,
      }).eq('id', userId);
      
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> createSupplierRecord(String userId) async {
    try {
      await _supabase.from('suppliers').insert({'id': userId});
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> createTruckerRecord(String userId) async {
    try {
      await _supabase.from('truckers').insert({'id': userId});
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}
