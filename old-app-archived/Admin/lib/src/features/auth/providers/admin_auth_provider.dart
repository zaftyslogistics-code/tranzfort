import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/repositories/admin_access_repository.dart';

final currentAdminAccessProvider = FutureProvider<AdminAccessUser?>(
  (ref) => ref.read(adminAccessRepositoryProvider).fetchCurrentAdmin(),
);

final currentAdminRoleProvider = Provider<AdminRole?>((ref) {
  final admin = ref.watch(currentAdminAccessProvider).valueOrNull;
  return admin?.isActive == true ? admin?.role : null;
});

bool adminHasAccess(AdminRole? role, Set<AdminRole> allowedRoles) {
  if (role == null) return false;
  return allowedRoles.contains(role);
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AsyncValue<void>>(
      (ref) => AdminAuthNotifier(ref),
    );

class AdminAuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  AdminAuthNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> signIn({required String email, required String password}) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) {
      state = const AsyncError(
        'Supabase not configured for admin auth.',
        StackTrace.empty,
      );
      return false;
    }

    state = const AsyncLoading();
    try {
      final result = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final success = result.session != null;
      if (!success) {
        state = const AsyncError('Invalid credentials.', StackTrace.empty);
        return false;
      }

      final admin = await _ref
          .read(adminAccessRepositoryProvider)
          .fetchCurrentAdmin();
      final authorized = admin != null && admin.isActive;

      if (!authorized) {
        await Supabase.instance.client.auth.signOut();
        state = const AsyncError(
          'You are not authorized for Admin access or your account is inactive.',
          StackTrace.empty,
        );
        return false;
      }

      _ref.invalidate(currentAdminAccessProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return;

    try {
      await Supabase.instance.client.auth.signOut();
      _ref.invalidate(currentAdminAccessProvider);
    } catch (_) {
      // Keep sign out non-blocking in keyless/local mode.
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) {
      state = const AsyncError(
        'Supabase not configured for password reset.',
        StackTrace.empty,
      );
      return false;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
