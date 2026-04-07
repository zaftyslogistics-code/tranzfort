import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

enum AdminSignInFailureReason {
  invalidCredentials,
  notAuthorized,
  deactivated,
  unavailable,
}

class AdminSignInResult {
  final bool isSuccess;
  final AdminAuthStateSnapshot? snapshot;
  final AdminSignInFailureReason? failureReason;

  const AdminSignInResult._({
    required this.isSuccess,
    this.snapshot,
    this.failureReason,
  });

  factory AdminSignInResult.success(AdminAuthStateSnapshot snapshot) {
    return AdminSignInResult._(
      isSuccess: true,
      snapshot: snapshot,
    );
  }

  factory AdminSignInResult.failure(AdminSignInFailureReason reason) {
    return AdminSignInResult._(
      isSuccess: false,
      failureReason: reason,
    );
  }
}

abstract class AdminAuthBackend {
  Future<String?> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail({required String email});

  Future<void> signOut();

  Future<Map<String, dynamic>?> fetchAdminAccessRow({required String authUserId});
}

class SupabaseAdminAuthBackend implements AdminAuthBackend {
  final SupabaseClient? client;

  const SupabaseAdminAuthBackend(this.client);

  @override
  Future<String?> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      debugPrint('SupabaseAdminAuthBackend: client is null');
      return null;
    }

    try {
      debugPrint('SupabaseAdminAuthBackend: Attempting sign in for email: $email');
      final response = await activeClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('SupabaseAdminAuthBackend: Sign in successful, userId: ${response.user?.id}');
      return response.user?.id ?? activeClient.auth.currentUser?.id;
    } on AuthException catch (e) {
      debugPrint('SupabaseAdminAuthBackend: AuthException - message: ${e.message}, statusCode: ${e.statusCode}');
      rethrow;
    } catch (e) {
      debugPrint('SupabaseAdminAuthBackend: Unexpected error - $e');
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final activeClient = client;
    if (activeClient == null) {
      throw StateError('Supabase client unavailable');
    }

    await activeClient.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> signOut() async {
    final activeClient = client;
    if (activeClient == null) {
      return;
    }

    await activeClient.auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> fetchAdminAccessRow({required String authUserId}) async {
    final activeClient = client;
    if (activeClient == null) {
      debugPrint('fetchAdminAccessRow: client is null');
      return null;
    }

    try {
      debugPrint('fetchAdminAccessRow: Calling RPC verify_admin_after_auth for authUserId: $authUserId');
      // Use RPC to bypass RLS issues
      final result = await activeClient
          .rpc('verify_admin_after_auth', params: {'p_auth_user_id': authUserId});
      
      debugPrint('fetchAdminAccessRow: RPC result: $result');
      
      if (result == null || result['found'] != true) {
        debugPrint('fetchAdminAccessRow: Admin not found in RPC result');
        return null;
      }
      
      return {
        'role': result['role'],
        'is_active': result['is_active'],
      };
    } catch (e) {
      debugPrint('fetchAdminAccessRow: RPC failed with error: $e, trying fallback query');
      // Fallback to direct query if RPC fails
      final row = await activeClient
          .from('admin_users')
          .select('role, is_active')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      
      debugPrint('fetchAdminAccessRow: Fallback query result: $row');
      
      if (row == null) {
        return null;
      }
      
      return Map<String, dynamic>.from(row);
    }
  }
}

class AdminAuthRepository {
  final AdminAuthBackend backend;

  const AdminAuthRepository({
    required this.backend,
  });

  Future<AdminSignInResult> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      return AdminSignInResult.failure(AdminSignInFailureReason.invalidCredentials);
    }

    try {
      final authUserId = await backend.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      debugPrint('AdminAuthRepository: authUserId from backend: $authUserId');
      if (authUserId == null || authUserId.isEmpty) {
        return AdminSignInResult.failure(AdminSignInFailureReason.unavailable);
      }

      final row = await backend.fetchAdminAccessRow(authUserId: authUserId);
      debugPrint('AdminAuthRepository: row from fetchAdminAccessRow: $row');
      if (row == null) {
        await backend.signOut();
        return AdminSignInResult.failure(AdminSignInFailureReason.notAuthorized);
      }

      final role = _parseRole((row['role'] ?? '').toString());
      debugPrint('AdminAuthRepository: parsed role: $role');
      if (role == AdminRole.unknown) {
        await backend.signOut();
        return AdminSignInResult.failure(AdminSignInFailureReason.notAuthorized);
      }

      final isActive = row['is_active'] == true;
      debugPrint('AdminAuthRepository: isActive: $isActive');
      if (!isActive) {
        await backend.signOut();
        return AdminSignInResult.failure(AdminSignInFailureReason.deactivated);
      }

      return AdminSignInResult.success(
        AdminAuthStateSnapshot(
          hasSession: true,
          role: role,
          isActive: true,
        ),
      );
    } on AuthException catch (e) {
      debugPrint('AdminAuthRepository: AuthException during signIn - message: ${e.message}, statusCode: ${e.statusCode}');
      return AdminSignInResult.failure(AdminSignInFailureReason.invalidCredentials);
    } catch (e) {
      debugPrint('AdminAuthRepository: Unexpected error during signIn - $e');
      return AdminSignInResult.failure(AdminSignInFailureReason.unavailable);
    }
  }

  Future<bool> requestPasswordReset({required String email}) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) {
      return false;
    }

    try {
      await backend.sendPasswordResetEmail(email: normalizedEmail);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() {
    return backend.signOut();
  }

  AdminRole _parseRole(String value) {
    return switch (value.trim().toLowerCase()) {
      'ops_admin' => AdminRole.opsAdmin,
      'super_admin' => AdminRole.superAdmin,
      _ => AdminRole.unknown,
    };
  }

  String? _normalizeEmail(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}

final adminAuthBackendProvider = Provider<AdminAuthBackend>((ref) {
  return SupabaseAdminAuthBackend(ref.watch(adminSupabaseClientProvider));
});

final adminAuthRepositoryProvider = Provider<AdminAuthRepository>((ref) {
  return AdminAuthRepository(
    backend: ref.watch(adminAuthBackendProvider),
  );
});
