import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

class AdminSessionRepository {
  final Ref ref;

  const AdminSessionRepository(this.ref);

  Future<AdminAuthStateSnapshot> loadCurrentAccess() async {
    final client = ref.read(adminSupabaseClientProvider);
    if (client == null) {
      return AdminAuthStateSnapshot.signedOut();
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return AdminAuthStateSnapshot.signedOut();
    }

    try {
      final row = await client
          .from('admin_users')
          .select('role, is_active')
          .eq('auth_user_id', user.id)
          .maybeSingle();

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

      final isActive = row['is_active'] == true;

      return AdminAuthStateSnapshot(
        hasSession: true,
        role: role,
        isActive: isActive,
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
      debugPrint('AdminSessionRepository.loadCurrentAccess failed: $error\n$stackTrace');
      return const AdminAuthStateSnapshot(
        hasSession: true,
        role: AdminRole.unknown,
        isActive: false,
        verificationFailed: true,
      );
    }
  }
}

final adminSessionRepositoryProvider = Provider<AdminSessionRepository>((ref) {
  return AdminSessionRepository(ref);
});
