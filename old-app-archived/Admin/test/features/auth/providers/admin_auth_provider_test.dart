import 'package:admin/src/core/repositories/admin_access_repository.dart';
import 'package:admin/src/features/auth/providers/admin_auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('adminHasAccess', () {
    test('returns false when role is null', () {
      expect(adminHasAccess(null, {AdminRole.superAdmin}), isFalse);
    });

    test('returns true only when role is in allowed set', () {
      expect(
        adminHasAccess(AdminRole.superAdmin, {AdminRole.superAdmin}),
        isTrue,
      );
      expect(
        adminHasAccess(AdminRole.supportAgent, {AdminRole.superAdmin}),
        isFalse,
      );
      expect(
        adminHasAccess(
          AdminRole.opsAdmin,
          {AdminRole.superAdmin, AdminRole.opsAdmin},
        ),
        isTrue,
      );
    });
  });
}
