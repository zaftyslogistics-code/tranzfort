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
  debugPrint('=== ADMIN AUTH STATE PROVIDER INITIALIZED ===');
  final client = ref.watch(adminSupabaseClientProvider);
  debugPrint('Initial client: ${client != null ? "available" : "null"}');
  
  final initialState = await _loadAdminAuthStateSnapshot(client);
  debugPrint('=== YIELDING INITIAL STATE ===');
  debugPrint('Initial state: hasSession=${initialState.hasSession}, role=${initialState.role}, isActive=${initialState.isActive}');
  yield initialState;

  if (client == null) {
    debugPrint('Client is null, not listening to auth state changes');
    return;
  }

  debugPrint('=== STARTING AUTH STATE CHANGE LISTENER ===');
  yield* client.auth.onAuthStateChange.asyncMap(
    (event) {
      debugPrint('=== AUTH STATE CHANGE EVENT ===');
      debugPrint('Event: ${event.event}');
      debugPrint('Session: ${event.session?.user?.id}');
      return _loadAdminAuthStateSnapshot(client);
    },
  );
});

final currentAdminAuthStateProvider = Provider<AdminAuthStateSnapshot>((ref) {
  final authState = ref.watch(adminAuthStateProvider);
  return authState.valueOrNull ??
      AdminAuthStateSnapshot.fromClient(ref.watch(adminSupabaseClientProvider));
});

Future<AdminAuthStateSnapshot> _loadAdminAuthStateSnapshot(SupabaseClient? client) async {
  debugPrint('=== ADMIN AUTH STATE LOADING ===');
  debugPrint('Client is null: ${client == null}');
  
  if (client == null) {
    debugPrint('Client is null, returning signedOut');
    return AdminAuthStateSnapshot.signedOut();
  }

  final user = client.auth.currentUser;
  debugPrint('Current user: ${user?.id}');
  
  if (user == null) {
    debugPrint('User is null, returning signedOut');
    return AdminAuthStateSnapshot.signedOut();
  }

  debugPrint('User found, loading admin access...');
  try {
    Map<String, dynamic>? row;

    try {
      debugPrint('Calling verify_admin_after_auth RPC for user: ${user.id}');
      final result = await client.rpc(
        'verify_admin_after_auth',
        params: {'p_auth_user_id': user.id},
      );
      debugPrint('RPC result: $result');

      if (result != null && result['found'] == true) {
        row = {
          'role': result['role'],
          'is_active': result['is_active'],
        };
        debugPrint('Admin found via RPC: role=${result['role']}, is_active=${result['is_active']}');
      } else {
        debugPrint('RPC returned null or found=false');
      }
    } catch (e) {
      debugPrint('RPC failed with error: $e, trying fallback query');
      row = await client
          .from('admin_users')
          .select('role, is_active')
          .eq('auth_user_id', user.id)
          .maybeSingle();
    }

    if (row == null) {
      debugPrint('Row is null, returning unknown role');
      return const AdminAuthStateSnapshot(
        hasSession: true,
        role: AdminRole.unknown,
        isActive: false,
      );
    }

    debugPrint('Row data: $row');
    final role = switch ((row['role'] ?? '').toString().trim().toLowerCase()) {
      'ops_admin' => AdminRole.opsAdmin,
      'super_admin' => AdminRole.superAdmin,
      _ => AdminRole.unknown,
    };

    final snapshot = AdminAuthStateSnapshot(
      hasSession: true,
      role: role,
      isActive: row['is_active'] == true,
    );
    debugPrint('Returning auth state snapshot: hasSession=${snapshot.hasSession}, role=${snapshot.role}, isActive=${snapshot.isActive}, hasAdminAccess=${snapshot.hasAdminAccess}');
    return snapshot;
  } catch (error, stackTrace) {
    debugPrint('_loadAdminAuthStateSnapshot failed: $error\n$stackTrace');
    if (error is AuthApiException && error.code == 'refresh_token_not_found') {
      try {
        await client.auth.signOut();
      } catch (_) {
        // Best-effort local cleanup; fallback state below still signs user out.
      }
      debugPrint('Refresh token not found, signed out');
      return AdminAuthStateSnapshot.signedOut();
    }
    debugPrint('Returning verificationFailed state');
    return const AdminAuthStateSnapshot(
      hasSession: true,
      role: AdminRole.unknown,
      isActive: false,
      verificationFailed: true,
    );
  }
}
