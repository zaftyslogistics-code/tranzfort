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
      return null;
    }

    final response = await activeClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    return response.user?.id ?? activeClient.auth.currentUser?.id;
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
      return null;
    }

    try {
      // Use RPC to bypass RLS issues
      final result = await activeClient
          .rpc('verify_admin_after_auth', params: {'p_auth_user_id': authUserId});
      
      if (result == null || result['found'] != true) {
        return null;
      }
      
      return {
        'role': result['role'],
        'is_active': result['is_active'],
      };
    } catch (e) {
      // Fallback to direct query if RPC fails
      final row = await activeClient
          .from('admin_users')
          .select('role, is_active')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      
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
      if (authUserId == null || authUserId.isEmpty) {
        return AdminSignInResult.failure(AdminSignInFailureReason.unavailable);
      }

      final row = await backend.fetchAdminAccessRow(authUserId: authUserId);
      if (row == null) {
        await backend.signOut();
        return AdminSignInResult.failure(AdminSignInFailureReason.notAuthorized);
      }

      final role = _parseRole((row['role'] ?? '').toString());
      if (role == AdminRole.unknown) {
        await backend.signOut();
        return AdminSignInResult.failure(AdminSignInFailureReason.notAuthorized);
      }

      final isActive = row['is_active'] == true;
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
    } on AuthException {
      return AdminSignInResult.failure(AdminSignInFailureReason.invalidCredentials);
    } catch (_) {
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
