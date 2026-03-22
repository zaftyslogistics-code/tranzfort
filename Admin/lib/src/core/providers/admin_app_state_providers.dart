import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AdminRole {
  opsAdmin,
  superAdmin,
  unknown,
}

class AdminAuthStateSnapshot {
  final bool hasSession;
  final AdminRole role;
  final bool isActive;
  final bool verificationFailed;
  final bool isLoading;

  const AdminAuthStateSnapshot({
    required this.hasSession,
    required this.role,
    required this.isActive,
    this.verificationFailed = false,
    this.isLoading = false,
  });

  bool get hasAdminAccess => hasSession && isActive && role != AdminRole.unknown && !verificationFailed;

  factory AdminAuthStateSnapshot.signedOut() {
    return const AdminAuthStateSnapshot(
      hasSession: false,
      role: AdminRole.unknown,
      isActive: false,
      verificationFailed: false,
      isLoading: false,
    );
  }

  factory AdminAuthStateSnapshot.fromClient(SupabaseClient? client) {
    if (client == null) {
      return AdminAuthStateSnapshot.signedOut();
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return AdminAuthStateSnapshot.signedOut();
    }

    return AdminAuthStateSnapshot(
      hasSession: true,
      role: AdminRole.unknown,
      isActive: false,
      isLoading: true,
    );
  }
}

final adminSupabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

final adminAuthStateProvider = StreamProvider<AdminAuthStateSnapshot>((ref) async* {
  final client = ref.watch(adminSupabaseClientProvider);
  yield await _loadAdminAuthStateSnapshot(client);

  if (client == null) {
    return;
  }

  yield* client.auth.onAuthStateChange.asyncMap(
    (_) => _loadAdminAuthStateSnapshot(client),
  );
});

final currentAdminAuthStateProvider = Provider<AdminAuthStateSnapshot>((ref) {
  final authState = ref.watch(adminAuthStateProvider);
  return authState.valueOrNull ??
      AdminAuthStateSnapshot.fromClient(ref.watch(adminSupabaseClientProvider));
});

Future<AdminAuthStateSnapshot> _loadAdminAuthStateSnapshot(SupabaseClient? client) async {
  if (client == null) {
    return AdminAuthStateSnapshot.signedOut();
  }

  final user = client.auth.currentUser;
  if (user == null) {
    return AdminAuthStateSnapshot.signedOut();
  }

  try {
    Map<String, dynamic>? row;

    try {
      final result = await client.rpc(
        'verify_admin_after_auth',
        params: {'p_auth_user_id': user.id},
      );

      if (result != null && result['found'] == true) {
        row = {
          'role': result['role'],
          'is_active': result['is_active'],
        };
      }
    } catch (_) {
      row = await client
          .from('admin_users')
          .select('role, is_active')
          .eq('auth_user_id', user.id)
          .maybeSingle();
    }

    if (row == null) {
      return const AdminAuthStateSnapshot(
        hasSession: true,
        role: AdminRole.unknown,
        isActive: false,
      );
    }

    final role = switch ((row['role'] ?? '').toString().trim().toLowerCase()) {
      'ops_admin' => AdminRole.opsAdmin,
      'super_admin' => AdminRole.superAdmin,
      _ => AdminRole.unknown,
    };

    return AdminAuthStateSnapshot(
      hasSession: true,
      role: role,
      isActive: row['is_active'] == true,
    );
  } catch (error, stackTrace) {
    if (error is AuthApiException && error.code == 'refresh_token_not_found') {
      try {
        await client.auth.signOut();
      } catch (_) {
        // Best-effort local cleanup; fallback state below still signs user out.
      }
      return AdminAuthStateSnapshot.signedOut();
    }
    debugPrint('_loadAdminAuthStateSnapshot failed: $error\n$stackTrace');
    return const AdminAuthStateSnapshot(
      hasSession: true,
      role: AdminRole.unknown,
      isActive: false,
      verificationFailed: true,
    );
  }
}
