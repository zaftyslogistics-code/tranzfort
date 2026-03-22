import 'package:admin/src/core/repositories/admin_management_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminManagementBackend implements AdminManagementBackend {
  List<Map<String, dynamic>> rows = const [];

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsers() async => rows;
}

void main() {
  test('searchAdmins filters and summarizes admin rows', () async {
    final backend = _FakeAdminManagementBackend()
      ..rows = [
        {
          'id': 'admin-1',
          'full_name': 'Super Admin One',
          'email': 'super@example.com',
          'role': 'super_admin',
          'is_active': true,
          'created_by': '',
          'created_at': '2026-03-11T10:00:00.000Z',
        },
        {
          'id': 'admin-2',
          'full_name': 'Ops Admin One',
          'email': 'ops@example.com',
          'role': 'ops_admin',
          'is_active': false,
          'created_by': 'admin-1',
          'created_at': '2026-03-11T11:00:00.000Z',
        },
      ];

    final container = ProviderContainer(
      overrides: [
        adminManagementBackendProvider.overrideWithValue(backend),
      ],
    );
    addTearDown(container.dispose);

    final repository = container.read(adminManagementRepositoryProvider);
    final page = await repository.searchAdmins(
      const AdminManagementQuery(
        filter: AdminManagementFilter.inactive,
        search: 'ops',
      ),
    );

    expect(page.summary.totalCount, 2);
    expect(page.summary.activeCount, 1);
    expect(page.summary.inactiveCount, 1);
    expect(page.summary.superAdminCount, 1);
    expect(page.summary.opsAdminCount, 1);
    expect(page.items, hasLength(1));
    expect(page.items.single.fullName, 'Ops Admin One');
    expect(page.items.single.isActive, isFalse);
  });
}
