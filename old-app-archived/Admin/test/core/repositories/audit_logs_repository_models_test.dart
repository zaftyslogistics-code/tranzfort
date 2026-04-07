import 'package:admin/src/core/repositories/audit_logs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditLogQuery', () {
    test('equality and hashCode include all filter fields', () {
      final from = DateTime(2026, 2, 1);
      final to = DateTime(2026, 2, 28);

      final a = AuditLogQuery(
        keyword: 'ban',
        action: 'ban_user',
        entityType: 'profile',
        from: from,
        to: to,
        offset: 0,
        limit: 50,
      );
      final b = AuditLogQuery(
        keyword: 'ban',
        action: 'ban_user',
        entityType: 'profile',
        from: from,
        to: to,
        offset: 0,
        limit: 50,
      );
      final c = AuditLogQuery(
        keyword: 'unban',
        action: 'ban_user',
        entityType: 'profile',
        from: from,
        to: to,
        offset: 0,
        limit: 50,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('AuditLogEntry', () {
    test('stores entry fields and metadata map', () {
      final entry = AuditLogEntry(
        id: 'log-1',
        adminId: 'admin-1',
        adminName: 'Super Admin',
        action: 'ban_user',
        entityType: 'profile',
        entityId: 'user-1',
        metadata: const {'reason': 'policy'},
        createdAt: DateTime(2026, 2, 27),
      );

      expect(entry.action, 'ban_user');
      expect(entry.entityType, 'profile');
      expect(entry.entityId, 'user-1');
      expect(entry.metadata['reason'], 'policy');
    });
  });
}
