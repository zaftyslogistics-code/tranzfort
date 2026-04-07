import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'admin_access_repository.dart';

final adminAuditRepositoryProvider = Provider<AdminAuditRepository>(
  (ref) => AdminAuditRepository(ref),
);

class AdminAuditResult {
  final bool persisted;
  final String message;

  const AdminAuditResult({required this.persisted, required this.message});
}

class AdminAuditRepository {
  final Ref _ref;

  AdminAuditRepository(this._ref);

  Future<AdminAuditResult> logAction({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> metadata = const {},
    String? adminId,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) {
      return const AdminAuditResult(
        persisted: false,
        message: 'Audit logging skipped because Supabase is not configured.',
      );
    }

    final client = Supabase.instance.client;

    final actorAdminId = adminId ?? await _currentAdminId();
    if (actorAdminId == null || actorAdminId.isEmpty) {
      return const AdminAuditResult(
        persisted: false,
        message: 'Audit logging skipped because no active admin actor was resolved.',
      );
    }

    try {
      await client.from('audit_logs').insert({
        'admin_id': actorAdminId,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': metadata,
      });
      return const AdminAuditResult(
        persisted: true,
        message: 'Audit log persisted successfully.',
      );
    } catch (_) {
      return const AdminAuditResult(
        persisted: false,
        message: 'Core admin action may have succeeded, but audit logging did not persist.',
      );
    }
  }

  Future<String?> _currentAdminId() async {
    final admin = await _ref
        .read(adminAccessRepositoryProvider)
        .fetchCurrentAdmin();
    if (admin == null || !admin.isActive) return null;
    return admin.id;
  }
}
