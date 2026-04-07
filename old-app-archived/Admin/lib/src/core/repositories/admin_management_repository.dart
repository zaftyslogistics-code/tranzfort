import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'admin_access_repository.dart';
import 'admin_audit_repository.dart';

final adminManagementRepositoryProvider = Provider<AdminManagementRepository>(
  (ref) => AdminManagementRepository(ref),
);

class AdminManagementRepository {
  final Ref _ref;

  AdminManagementRepository(this._ref);

  Future<List<AdminAccountItem>> fetchAdmins() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      final rows = await client
          .from('admin_users')
          .select('id,auth_user_id,full_name,email,role,is_active,created_at')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(rows)
          .map(
            (row) => AdminAccountItem(
              id: _asString(row['id']),
              authUserId: _asString(row['auth_user_id']),
              fullName: _asString(row['full_name']),
              email: _asString(row['email']),
              role: adminRoleFromDb(_asString(row['role'])),
              isActive: row['is_active'] == true,
              createdAt: DateTime.tryParse(_asString(row['created_at'])),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<AdminInviteResult> inviteAdmin({
    required String fullName,
    required String email,
    required AdminRole role,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) {
      return const AdminInviteResult(
        ok: false,
        message: 'Supabase is not configured.',
      );
    }

    final client = Supabase.instance.client;

    try {
      await client.functions.invoke(
        'admin-promote-invite',
        body: {
          'full_name': fullName,
          'email': email,
          'role': adminRoleDbValue(role),
        },
      );

      final auditResult = await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'invite_admin',
            entityType: 'admin_user',
            entityId: email,
            metadata: {
              'full_name': fullName,
              'email': email,
              'role': adminRoleDbValue(role),
            },
          );

      return AdminInviteResult(
        ok: true,
        message: auditResult.persisted
            ? 'Invite triggered. If the edge function is configured, email is sent.'
            : 'Invite triggered, but audit logging did not persist. ${auditResult.message}',
      );
    } on FunctionException catch (e) {
      return AdminInviteResult(
        ok: false,
        message: 'Invite failed from edge function: ${e.details ?? e.reasonPhrase ?? 'unknown error'}',
      );
    } catch (e) {
      return AdminInviteResult(
        ok: false,
        message: 'Invite failed. Ensure admin-promote-invite Edge Function is deployed and reachable. ${e.toString()}',
      );
    }
  }

  Future<AdminActionResult> setAdminActive({
    required String adminId,
    required bool isActive,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) {
      return const AdminActionResult(
        ok: false,
        message: 'Supabase is not configured.',
      );
    }

    final client = Supabase.instance.client;

    final current = await _ref
        .read(adminAccessRepositoryProvider)
        .fetchCurrentAdmin();
    if (current == null) {
      return const AdminActionResult(
        ok: false,
        message: 'No active admin context found.',
      );
    }

    if (!isActive) {
      if (current.id == adminId) {
        return const AdminActionResult(
          ok: false,
          message: 'You cannot deactivate your own admin account.',
        );
      }

      final allAdmins = await fetchAdmins();
      final activeSuperAdmins = allAdmins
          .where((a) => a.role == AdminRole.superAdmin && a.isActive)
          .toList();
      final target = allAdmins.where((a) => a.id == adminId).firstOrNull;
      if (target == null) {
        return const AdminActionResult(
          ok: false,
          message: 'Target admin account was not found.',
        );
      }

      final deactivatingLastSuperAdmin =
          target.role == AdminRole.superAdmin && activeSuperAdmins.length <= 1;
      if (deactivatingLastSuperAdmin) {
        return const AdminActionResult(
          ok: false,
          message: 'Cannot deactivate the last active super admin.',
        );
      }
    }

    try {
      await client
          .from('admin_users')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', adminId);

      final auditResult = await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: isActive ? 'activate_admin' : 'deactivate_admin',
            entityType: 'admin_user',
            entityId: adminId,
            metadata: {'target_admin_id': adminId, 'is_active': isActive},
            adminId: current.id,
          );

      return AdminActionResult(
        ok: true,
        message: auditResult.persisted
            ? (isActive ? 'Admin activated.' : 'Admin deactivated.')
            : '${isActive ? 'Admin activated' : 'Admin deactivated'}, but audit logging did not persist. ${auditResult.message}',
      );
    } catch (_) {
      return const AdminActionResult(
        ok: false,
        message: 'Failed to update admin account state.',
      );
    }
  }
}

class AdminAccountItem {
  final String id;
  final String authUserId;
  final String fullName;
  final String email;
  final AdminRole role;
  final bool isActive;
  final DateTime? createdAt;

  const AdminAccountItem({
    required this.id,
    required this.authUserId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });
}

class AdminInviteResult {
  final bool ok;
  final String message;

  const AdminInviteResult({required this.ok, required this.message});
}

class AdminActionResult {
  final bool ok;
  final String message;

  const AdminActionResult({required this.ok, required this.message});
}

String _asString(dynamic value) => (value ?? '').toString();

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
