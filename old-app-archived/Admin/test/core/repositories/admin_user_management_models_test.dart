import 'package:admin/src/core/repositories/admin_user_management_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserListQuery equality', () {
    test('same filter and search are equal with same hashCode', () {
      const a = UserListQuery(filter: UserFilter.supplier, search: 'mumbai');
      const b = UserListQuery(filter: UserFilter.supplier, search: 'mumbai');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different filter or search are not equal', () {
      const base = UserListQuery(filter: UserFilter.all, search: 'abc');
      const differentFilter = UserListQuery(
        filter: UserFilter.trucker,
        search: 'abc',
      );
      const differentSearch = UserListQuery(
        filter: UserFilter.all,
        search: 'xyz',
      );

      expect(base == differentFilter, isFalse);
      expect(base == differentSearch, isFalse);
    });
  });

  group('Admin user models', () {
    test('AdminUserListItem stores role and ban metadata', () {
      const item = AdminUserListItem(
        id: 'user-1',
        fullName: 'Test User',
        mobile: '9999999999',
        email: 'test@example.com',
        role: 'supplier',
        verificationStatus: 'approved',
        isBanned: true,
        banReason: 'policy violation',
        loadsCount: 3,
      );

      expect(item.role, 'supplier');
      expect(item.isBanned, isTrue);
      expect(item.banReason, 'policy violation');
      expect(item.loadsCount, 3);
    });

    test('AdminRecentItem stores title/status metadata', () {
      final now = DateTime.now();
      final item = AdminRecentItem(
        id: 'load-1',
        title: 'Mumbai -> Pune',
        status: 'active',
        createdAt: now,
      );

      expect(item.title, contains('Mumbai'));
      expect(item.status, 'active');
      expect(item.createdAt, now);
    });
  });
}
