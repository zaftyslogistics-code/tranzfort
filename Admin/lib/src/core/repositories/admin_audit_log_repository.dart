import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

const Object _adminAuditLogNoChange = Object();

enum AdminAuditLogFilter { all, userActions, adminActions, internalOnly }

class AdminAuditLogQuery {
  final AdminAuditLogFilter filter;
  final String search;
  final String actorType;
  final String targetObjectType;
  final DateTime? startDate;
  final DateTime? endDate;
  final int page;
  final int pageSize;

  const AdminAuditLogQuery({
    required this.filter,
    required this.search,
    this.actorType = '',
    this.targetObjectType = '',
    this.startDate,
    this.endDate,
    this.page = 0,
    this.pageSize = 30,
  });

  AdminAuditLogQuery copyWith({
    AdminAuditLogFilter? filter,
    String? search,
    String? actorType,
    String? targetObjectType,
    Object? startDate = _adminAuditLogNoChange,
    Object? endDate = _adminAuditLogNoChange,
    int? page,
    int? pageSize,
  }) {
    return AdminAuditLogQuery(
      filter: filter ?? this.filter,
      search: search ?? this.search,
      actorType: actorType ?? this.actorType,
      targetObjectType: targetObjectType ?? this.targetObjectType,
      startDate: startDate == _adminAuditLogNoChange ? this.startDate : startDate as DateTime?,
      endDate: endDate == _adminAuditLogNoChange ? this.endDate : endDate as DateTime?,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminAuditLogQuery &&
        other.filter == filter &&
        other.search == search &&
        other.actorType == actorType &&
        other.targetObjectType == targetObjectType &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(filter, search, actorType, targetObjectType, startDate, endDate, page, pageSize);
}

class AdminAuditLogEntry {
  final String id;
  final String actorAdminUserId;
  final String actorAdminLabel;
  final String actorType;
  final String actorRole;
  final String actionType;
  final String targetObjectType;
  final String targetObjectId;
  final String secondaryObjectType;
  final String secondaryObjectId;
  final String summary;
  final Map<String, dynamic> payload;
  final String visibilityClass;
  final DateTime? createdAt;

  const AdminAuditLogEntry({
    required this.id,
    required this.actorAdminUserId,
    this.actorAdminLabel = '',
    required this.actorType,
    required this.actorRole,
    required this.actionType,
    required this.targetObjectType,
    required this.targetObjectId,
    required this.secondaryObjectType,
    required this.secondaryObjectId,
    required this.summary,
    this.payload = const {},
    required this.visibilityClass,
    required this.createdAt,
  });
}

class AdminAuditLogSummary {
  final int totalCount;
  final int internalCount;
  final int userActionCount;
  final int adminActionCount;

  const AdminAuditLogSummary({
    required this.totalCount,
    required this.internalCount,
    required this.userActionCount,
    required this.adminActionCount,
  });

  factory AdminAuditLogSummary.empty() {
    return const AdminAuditLogSummary(
      totalCount: 0,
      internalCount: 0,
      userActionCount: 0,
      adminActionCount: 0,
    );
  }
}

class AdminAuditLogPage {
  final List<AdminAuditLogEntry> items;
  final bool hasMore;
  final AdminAuditLogSummary summary;

  const AdminAuditLogPage({
    required this.items,
    required this.hasMore,
    required this.summary,
  });
}

abstract class AdminAuditLogBackend {
  Future<List<Map<String, dynamic>>> fetchAuditLogs();

  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids);
}

class SupabaseAdminAuditLogBackend implements AdminAuditLogBackend {
  final SupabaseClient? client;

  const SupabaseAdminAuditLogBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('audit_logs')
          .select('id, actor_admin_user_id, actor_type, actor_role, action_type, target_object_type, target_object_id, secondary_object_type, secondary_object_id, summary_text, payload_json, visibility_class, created_at')
          .order('created_at', ascending: false);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('admin_users')
          .select('id, full_name, role')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

class AdminAuditLogRepository {
  final AdminAuditLogBackend backend;

  const AdminAuditLogRepository({required this.backend});

  Future<AdminAuditLogPage> searchAuditLogs(AdminAuditLogQuery query) async {
    final rows = await backend.fetchAuditLogs();
    final adminUserIds = rows
        .map((row) => _asString(row['actor_admin_user_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final adminUsers = await backend.fetchAdminUsersByIds(adminUserIds);
    final adminUserById = {for (final row in adminUsers) _asString(row['id']): row};
    final filtered = await _applyFilterAndSearch(rows, query);
    final total = filtered.length;
    final start = query.page * query.pageSize;
    if (start >= total) {
      return AdminAuditLogPage(
        items: const [],
        hasMore: false,
        summary: _buildSummary(rows),
      );
    }
    final end = (start + query.pageSize) > total ? total : start + query.pageSize;
    final pageRows = filtered.sublist(start, end);

    return AdminAuditLogPage(
      items: pageRows.map((row) => _mapEntry(row, adminUserById)).toList(growable: false),
      hasMore: end < total,
      summary: _buildSummary(rows),
    );
  }

  AdminAuditLogSummary _buildSummary(List<Map<String, dynamic>> rows) {
    return AdminAuditLogSummary(
      totalCount: rows.length,
      internalCount: rows.where((row) => _asString(row['visibility_class']) == 'internal').length,
      userActionCount: rows.where((row) => _isUserAction(_asString(row['action_type']))).length,
      adminActionCount: rows.where((row) => _asString(row['action_type']).startsWith('admin_')).length,
    );
  }

  AdminAuditLogEntry _mapEntry(Map<String, dynamic> row, Map<String, Map<String, dynamic>> adminUserById) {
    final actorAdminUserId = _asString(row['actor_admin_user_id']);
    return AdminAuditLogEntry(
      id: _asString(row['id']),
      actorAdminUserId: actorAdminUserId,
      actorAdminLabel: _adminUserLabel(adminUserById[actorAdminUserId]),
      actorType: _asString(row['actor_type']),
      actorRole: _asString(row['actor_role']),
      actionType: _asString(row['action_type']),
      targetObjectType: _asString(row['target_object_type']),
      targetObjectId: _asString(row['target_object_id']),
      secondaryObjectType: _asString(row['secondary_object_type']),
      secondaryObjectId: _asString(row['secondary_object_id']),
      summary: _asString(row['summary_text']),
      payload: _asMap(row['payload_json']),
      visibilityClass: _asString(row['visibility_class']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
    );
  }

  Future<List<Map<String, dynamic>>> _applyFilterAndSearch(
    List<Map<String, dynamic>> rows,
    AdminAuditLogQuery query,
  ) async {
    final filtered = rows.where((row) {
      final actionType = _asString(row['action_type']);
      final visibilityClass = _asString(row['visibility_class']);
      final createdAt = DateTime.tryParse(_asString(row['created_at']))?.toLocal();
      final matchesPrimaryFilter = switch (query.filter) {
        AdminAuditLogFilter.all => true,
        AdminAuditLogFilter.userActions => _isUserAction(actionType),
        AdminAuditLogFilter.adminActions => actionType.startsWith('admin_'),
        AdminAuditLogFilter.internalOnly => visibilityClass == 'internal',
      };

      if (!matchesPrimaryFilter) {
        return false;
      }

      final actorType = query.actorType.trim().toLowerCase();
      if (actorType.isNotEmpty && _asString(row['actor_type']).trim().toLowerCase() != actorType) {
        return false;
      }

      final targetObjectType = query.targetObjectType.trim().toLowerCase();
      if (targetObjectType.isNotEmpty && _asString(row['target_object_type']).trim().toLowerCase() != targetObjectType) {
        return false;
      }

      final startDate = query.startDate;
      if (startDate != null) {
        if (createdAt == null || createdAt.isBefore(_startOfDay(startDate))) {
          return false;
        }
      }

      final endDate = query.endDate;
      if (endDate != null) {
        if (createdAt == null || createdAt.isAfter(_endOfDay(endDate))) {
          return false;
        }
      }

      return true;
    }).toList(growable: false);

    final search = query.search.trim().toLowerCase();
    if (search.isEmpty) {
      return filtered;
    }

    final adminUserIds = filtered
        .map((row) => _asString(row['actor_admin_user_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final adminUsers = await backend.fetchAdminUsersByIds(adminUserIds);
    final adminUserById = {for (final row in adminUsers) _asString(row['id']): row};

    return filtered.where((row) {
      final actorAdminUserId = _asString(row['actor_admin_user_id']);
      final actorAdminLabel = _adminUserLabel(adminUserById[actorAdminUserId]).toLowerCase();
      return _asString(row['action_type']).toLowerCase().contains(search) ||
          _asString(row['summary_text']).toLowerCase().contains(search) ||
          actorAdminUserId.toLowerCase().contains(search) ||
          actorAdminLabel.contains(search) ||
          _asString(row['target_object_type']).toLowerCase().contains(search) ||
          _asString(row['target_object_id']).toLowerCase().contains(search) ||
          _asString(row['secondary_object_type']).toLowerCase().contains(search) ||
          _asString(row['secondary_object_id']).toLowerCase().contains(search);
    }).toList(growable: false);
  }
}

DateTime _startOfDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime _endOfDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day, 23, 59, 59, 999);
}

bool _isUserAction(String actionType) {
  final normalized = actionType.trim().toLowerCase();
  return normalized.startsWith('user_') || normalized.startsWith('profile_');
}

String _adminUserLabel(Map<String, dynamic>? row) {
  final fullName = _asString(row?['full_name']);
  final role = _asString(row?['role']);
  if (fullName.isEmpty && role.isEmpty) {
    return '';
  }
  if (fullName.isEmpty) {
    return role;
  }
  return role.isEmpty ? fullName : '$fullName ($role)';
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

String _asString(dynamic value) => (value ?? '').toString();

final adminAuditLogBackendProvider = Provider<AdminAuditLogBackend>((ref) {
  return SupabaseAdminAuditLogBackend(ref.watch(adminSupabaseClientProvider));
});

final adminAuditLogRepositoryProvider = Provider<AdminAuditLogRepository>((ref) {
  return AdminAuditLogRepository(
    backend: ref.watch(adminAuditLogBackendProvider),
  );
});
