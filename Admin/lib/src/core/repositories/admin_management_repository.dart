import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

class AdminManagementSummary {
  final int totalCount;
  final int activeCount;
  final int inactiveCount;
  final int superAdminCount;
  final int opsAdminCount;

  const AdminManagementSummary({
    required this.totalCount,
    required this.activeCount,
    required this.inactiveCount,
    required this.superAdminCount,
    required this.opsAdminCount,
  });

  factory AdminManagementSummary.empty() {
    return const AdminManagementSummary(
      totalCount: 0,
      activeCount: 0,
      inactiveCount: 0,
      superAdminCount: 0,
      opsAdminCount: 0,
    );
  }
}

enum AdminManagementFilter { all, superAdmins, opsAdmins, inactive }

class AdminManagementQuery {
  final AdminManagementFilter filter;
  final String search;

  const AdminManagementQuery({
    required this.filter,
    required this.search,
  });

  AdminManagementQuery copyWith({
    AdminManagementFilter? filter,
    String? search,
  }) {
    return AdminManagementQuery(
      filter: filter ?? this.filter,
      search: search ?? this.search,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminManagementQuery &&
        other.filter == filter &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(filter, search);
}

class AdminManagementListItem {
  final String id;
  final String authUserId;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final String createdBy;
  final DateTime? createdAt;

  const AdminManagementListItem({
    required this.id,
    required this.authUserId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
  });
}

class AdminManagementPage {
  final List<AdminManagementListItem> items;
  final AdminManagementSummary summary;

  const AdminManagementPage({
    required this.items,
    required this.summary,
  });
}

abstract class AdminManagementBackend {
  Future<List<Map<String, dynamic>>> fetchAdminUsers();
}

class SupabaseAdminManagementBackend implements AdminManagementBackend {
  final SupabaseClient? client;

  const SupabaseAdminManagementBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsers() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }

    try {
      final rows = await activeClient
          .from('admin_users')
          .select('id, auth_user_id, full_name, email, role, is_active, created_by, created_at')
          .order('created_at', ascending: false);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

class AdminManagementRepository {
  final AdminManagementBackend backend;

  const AdminManagementRepository({required this.backend});

  Future<AdminManagementPage> searchAdmins(AdminManagementQuery query) async {
    final rows = await backend.fetchAdminUsers();
    final summary = AdminManagementSummary(
      totalCount: rows.length,
      activeCount: rows.where((row) => row['is_active'] == true).length,
      inactiveCount: rows.where((row) => row['is_active'] != true).length,
      superAdminCount: rows.where((row) => _asString(row['role']) == 'super_admin').length,
      opsAdminCount: rows.where((row) => _asString(row['role']) == 'ops_admin').length,
    );

    final filtered = _applyFilterAndSearch(rows, query)
        .map(
          (row) => AdminManagementListItem(
            id: _asString(row['id']),
            authUserId: _asString(row['auth_user_id']),
            fullName: _asString(row['full_name']),
            email: _asString(row['email']),
            role: _asString(row['role']),
            isActive: row['is_active'] == true,
            createdBy: _asString(row['created_by']),
            createdAt: DateTime.tryParse(_asString(row['created_at'])),
          ),
        )
        .toList(growable: false);

    return AdminManagementPage(items: filtered, summary: summary);
  }

  List<Map<String, dynamic>> _applyFilterAndSearch(
    List<Map<String, dynamic>> rows,
    AdminManagementQuery query,
  ) {
    final filtered = rows.where((row) {
      final role = _asString(row['role']);
      final isActive = row['is_active'] == true;
      return switch (query.filter) {
        AdminManagementFilter.all => true,
        AdminManagementFilter.superAdmins => role == 'super_admin',
        AdminManagementFilter.opsAdmins => role == 'ops_admin',
        AdminManagementFilter.inactive => !isActive,
      };
    }).toList(growable: false);

    final search = query.search.trim().toLowerCase();
    if (search.isEmpty) {
      return filtered;
    }

    return filtered.where((row) {
      return _asString(row['full_name']).toLowerCase().contains(search) ||
          _asString(row['email']).toLowerCase().contains(search);
    }).toList(growable: false);
  }
}

final adminManagementBackendProvider = Provider<AdminManagementBackend>((ref) {
  return SupabaseAdminManagementBackend(ref.watch(adminSupabaseClientProvider));
});

final adminManagementRepositoryProvider = Provider<AdminManagementRepository>((ref) {
  return AdminManagementRepository(
    backend: ref.watch(adminManagementBackendProvider),
  );
});

String _asString(dynamic value) => (value ?? '').toString();
