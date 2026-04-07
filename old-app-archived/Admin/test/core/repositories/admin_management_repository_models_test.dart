import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:admin/src/core/repositories/admin_management_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminAccountItem model', () {
    test('stores account metadata fields correctly', () {
      final createdAt = DateTime(2026, 2, 27);
      final item = AdminAccountItem(
        id: 'admin-1',
        authUserId: 'auth-1',
        fullName: 'Super Admin',
        email: 'super@example.com',
        role: AdminRole.superAdmin,
        isActive: true,
        createdAt: createdAt,
      );

      expect(item.id, 'admin-1');
      expect(item.authUserId, 'auth-1');
      expect(item.role, AdminRole.superAdmin);
      expect(item.isActive, isTrue);
      expect(item.createdAt, createdAt);
    });
  });
}
