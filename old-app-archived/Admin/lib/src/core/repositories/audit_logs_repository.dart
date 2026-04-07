import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

final auditLogsRepositoryProvider = Provider<AuditLogsRepository>(
  (ref) => AuditLogsRepository(ref),
);

class AuditLogsRepository {
  final Ref _ref;

  AuditLogsRepository(this._ref);

  Future<List<AuditLogEntry>> fetchLogs(AuditLogQuery query) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      dynamic request = client
          .from('audit_logs')
          .select(
            'id,admin_id,action,entity_type,entity_id,metadata,created_at',
          );

      final action = query.action.trim();
      if (action.isNotEmpty) {
        request = request.ilike('action', '%$action%');
      }

      final entityType = query.entityType.trim();
      if (entityType.isNotEmpty) {
        request = request.ilike('entity_type', '%$entityType%');
      }

      if (query.from != null) {
        request = request.gte(
          'created_at',
          query.from!.toUtc().toIso8601String(),
        );
      }
      if (query.to != null) {
        request = request.lte(
          'created_at',
          query.to!.toUtc().toIso8601String(),
        );
      }

      final rows = await request
          .order('created_at', ascending: false)
          .range(query.offset, query.offset + query.limit - 1);

      final logs = List<Map<String, dynamic>>.from(rows);
      if (logs.isEmpty) return const [];

      final adminIds = logs
          .map((row) => _asString(row['admin_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final adminNames = await _loadAdminNames(client, adminIds);

      final keyword = query.keyword.trim().toLowerCase();
      return logs
          .map(
            (row) => AuditLogEntry(
              id: _asString(row['id']),
              adminId: _asString(row['admin_id']),
              adminName: adminNames[_asString(row['admin_id'])] ?? 'Admin',
              action: _asString(row['action']),
              entityType: _asString(row['entity_type']),
              entityId: _asString(row['entity_id']),
              metadata: Map<String, dynamic>.from(
                row['metadata'] is Map ? row['metadata'] as Map : {},
              ),
              createdAt: DateTime.tryParse(_asString(row['created_at'])),
            ),
          )
          .where((entry) {
            if (keyword.isEmpty) return true;
            return entry.adminName.toLowerCase().contains(keyword) ||
                entry.action.toLowerCase().contains(keyword) ||
                entry.entityType.toLowerCase().contains(keyword) ||
                entry.entityId.toLowerCase().contains(keyword);
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Map<String, String>> _loadAdminNames(
    SupabaseClient client,
    List<String> adminIds,
  ) async {
    if (adminIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('admin_users')
          .select('id,full_name')
          .inFilter('id', adminIds);
      return {
        for (final row in rows)
          _asString(row['id']): _asString(row['full_name']).ifEmpty('Admin'),
      };
    } catch (_) {
      return const {};
    }
  }
}

class AuditLogQuery {
  final String keyword;
  final String action;
  final String entityType;
  final DateTime? from;
  final DateTime? to;
  final int offset;
  final int limit;

  const AuditLogQuery({
    required this.keyword,
    this.action = '',
    this.entityType = '',
    this.from,
    this.to,
    this.offset = 0,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) {
    return other is AuditLogQuery &&
        other.keyword == keyword &&
        other.action == action &&
        other.entityType == entityType &&
        other.from == from &&
        other.to == to &&
        other.offset == offset &&
        other.limit == limit;
  }

  @override
  int get hashCode =>
      Object.hash(keyword, action, entityType, from, to, offset, limit);
}

class AuditLogEntry {
  final String id;
  final String adminId;
  final String adminName;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const AuditLogEntry({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.metadata,
    required this.createdAt,
  });
}

String _asString(dynamic value) => (value ?? '').toString();

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
