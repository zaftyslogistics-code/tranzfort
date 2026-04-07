import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminAccessUser model', () {
    test('stores identity and role metadata', () {
      const user = AdminAccessUser(
        id: 'admin-1',
        authUserId: 'auth-1',
        fullName: 'Super Admin',
        email: 'super@example.com',
        role: AdminRole.superAdmin,
        isActive: true,
      );

      expect(user.id, 'admin-1');
      expect(user.authUserId, 'auth-1');
      expect(user.fullName, 'Super Admin');
      expect(user.email, 'super@example.com');
      expect(user.role, AdminRole.superAdmin);
      expect(user.isActive, isTrue);
    });

    test('supports non-super admin role values', () {
      const ops = AdminAccessUser(
        id: 'admin-2',
        authUserId: 'auth-2',
        fullName: 'Ops Admin',
        email: 'ops@example.com',
        role: AdminRole.opsAdmin,
        isActive: true,
      );
      const support = AdminAccessUser(
        id: 'admin-3',
        authUserId: 'auth-3',
        fullName: 'Support Agent',
        email: 'support@example.com',
        role: AdminRole.supportAgent,
        isActive: false,
      );

      expect(ops.role, AdminRole.opsAdmin);
      expect(support.role, AdminRole.supportAgent);
      expect(support.isActive, isFalse);
    });
  });
}
