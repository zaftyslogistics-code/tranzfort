import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('admin role mappings', () {
    test('adminRoleFromDb maps known values and defaults safely', () {
      expect(adminRoleFromDb('super_admin'), AdminRole.superAdmin);
      expect(adminRoleFromDb('ops_admin'), AdminRole.opsAdmin);
      expect(adminRoleFromDb('support_agent'), AdminRole.supportAgent);
      expect(adminRoleFromDb('unknown_role'), AdminRole.supportAgent);
    });

    test('adminRoleDbValue maps enum values to DB values', () {
      expect(adminRoleDbValue(AdminRole.superAdmin), 'super_admin');
      expect(adminRoleDbValue(AdminRole.opsAdmin), 'ops_admin');
      expect(adminRoleDbValue(AdminRole.supportAgent), 'support_agent');
    });

    test('adminRoleLabel maps enum values to display labels', () {
      expect(adminRoleLabel(AdminRole.superAdmin), 'Super Admin');
      expect(adminRoleLabel(AdminRole.opsAdmin), 'Ops Admin');
      expect(adminRoleLabel(AdminRole.supportAgent), 'Support Agent');
    });
  });
}
