import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

final adminAccessRepositoryProvider = Provider<AdminAccessRepository>(
  (ref) => AdminAccessRepository(ref),
);

class AdminAccessRepository {
  final Ref _ref;

  AdminAccessRepository(this._ref);

  Future<AdminAccessUser?> fetchCurrentAdmin() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return null;

    final client = Supabase.instance.client;
    final authUserId = client.auth.currentUser?.id;
    if (authUserId == null) return null;

    try {
      final row = await client
          .from('admin_users')
          .select('id,auth_user_id,full_name,email,role,is_active')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null) return null;

      return AdminAccessUser(
        id: _asString(row['id']),
        authUserId: _asString(row['auth_user_id']),
        fullName: _asString(row['full_name']),
        email: _asString(row['email']),
        role: adminRoleFromDb(_asString(row['role'])),
        isActive: row['is_active'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

enum AdminRole { superAdmin, opsAdmin, supportAgent }

AdminRole adminRoleFromDb(String value) {
  switch (value) {
    case 'super_admin':
      return AdminRole.superAdmin;
    case 'ops_admin':
      return AdminRole.opsAdmin;
    case 'support_agent':
    default:
      return AdminRole.supportAgent;
  }
}

String adminRoleDbValue(AdminRole role) {
  switch (role) {
    case AdminRole.superAdmin:
      return 'super_admin';
    case AdminRole.opsAdmin:
      return 'ops_admin';
    case AdminRole.supportAgent:
      return 'support_agent';
  }
}

String adminRoleLabel(AdminRole role) {
  switch (role) {
    case AdminRole.superAdmin:
      return 'Super Admin';
    case AdminRole.opsAdmin:
      return 'Ops Admin';
    case AdminRole.supportAgent:
      return 'Support Agent';
  }
}

class AdminAccessUser {
  final String id;
  final String authUserId;
  final String fullName;
  final String email;
  final AdminRole role;
  final bool isActive;

  const AdminAccessUser({
    required this.id,
    required this.authUserId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
  });
}

String _asString(dynamic value) => (value ?? '').toString();
