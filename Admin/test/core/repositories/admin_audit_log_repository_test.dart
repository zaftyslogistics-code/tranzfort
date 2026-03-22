import 'package:admin/src/core/repositories/admin_audit_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminAuditLogBackend implements AdminAuditLogBackend {
  List<Map<String, dynamic>> rows = const [];
  Map<String, Map<String, dynamic>> adminUsersById = const {};

  @override
  Future<List<Map<String, dynamic>>> fetchAuditLogs() async => rows;

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async => ids
      .map((id) => adminUsersById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

void main() {
  test('searchAuditLogs filters, paginates, summarizes, and supports actor admin search', () async {
    final backend = _FakeAdminAuditLogBackend()
      ..rows = [
        {
          'id': 'audit-1',
          'actor_admin_user_id': 'admin-1',
          'actor_type': 'admin',
          'actor_role': 'super_admin',
          'action_type': 'user_banned',
          'target_object_type': 'profile',
          'target_object_id': 'user-1',
          'secondary_object_type': '',
          'secondary_object_id': '',
          'summary_text': 'User was banned for fraud',
          'payload_json': {'reason': 'fraud'},
          'visibility_class': 'internal',
          'created_at': '2026-03-11T10:00:00.000Z',
        },
        {
          'id': 'audit-2',
          'actor_admin_user_id': 'admin-1',
          'actor_type': 'admin',
          'actor_role': 'super_admin',
          'action_type': 'admin_created',
          'target_object_type': 'admin_user',
          'target_object_id': 'admin-2',
          'secondary_object_type': '',
          'secondary_object_id': '',
          'summary_text': 'Created ops admin',
          'payload_json': {'role': 'ops_admin'},
          'visibility_class': 'internal',
          'created_at': '2026-03-11T09:00:00.000Z',
        },
      ]
      ..adminUsersById = {
        'admin-1': {
          'id': 'admin-1',
          'full_name': 'Super Ops One',
          'role': 'super_admin',
        },
      };

    final container = ProviderContainer(
      overrides: [
        adminAuditLogBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminAuditLogRepositoryProvider);
    final page = await repository.searchAuditLogs(
      const AdminAuditLogQuery(
        filter: AdminAuditLogFilter.userActions,
        search: 'fraud',
        page: 0,
        pageSize: 1,
      ),
    );
    final adminIdPage = await repository.searchAuditLogs(
      const AdminAuditLogQuery(
        filter: AdminAuditLogFilter.all,
        search: 'admin-1',
        page: 0,
        pageSize: 10,
      ),
    );
    final adminLabelPage = await repository.searchAuditLogs(
      const AdminAuditLogQuery(
        filter: AdminAuditLogFilter.all,
        search: 'super ops one',
        page: 0,
        pageSize: 10,
      ),
    );
    final actorTypePage = await repository.searchAuditLogs(
      const AdminAuditLogQuery(
        filter: AdminAuditLogFilter.all,
        search: '',
        actorType: 'admin',
        page: 0,
        pageSize: 10,
      ),
    );
    final objectTypePage = await repository.searchAuditLogs(
      const AdminAuditLogQuery(
        filter: AdminAuditLogFilter.all,
        search: '',
        targetObjectType: 'profile',
        page: 0,
        pageSize: 10,
      ),
    );
    final dateRangePage = await repository.searchAuditLogs(
      AdminAuditLogQuery(
        filter: AdminAuditLogFilter.all,
        search: '',
        startDate: DateTime(2026, 3, 11),
        endDate: DateTime(2026, 3, 11),
        page: 0,
        pageSize: 10,
      ),
    );

    expect(page.summary.totalCount, 2);
    expect(page.summary.internalCount, 2);
    expect(page.summary.userActionCount, 1);
    expect(page.summary.adminActionCount, 1);
    expect(page.items, hasLength(1));
    expect(page.items.single.actionType, 'user_banned');
    expect(page.items.single.actorAdminLabel, 'Super Ops One (super_admin)');
    expect(page.hasMore, isFalse);
    expect(adminIdPage.items, hasLength(2));
    expect(adminLabelPage.items, hasLength(2));
    expect(actorTypePage.items, hasLength(2));
    expect(objectTypePage.items, hasLength(1));
    expect(objectTypePage.items.single.targetObjectType, 'profile');
    expect(dateRangePage.items, hasLength(2));
  });
}
