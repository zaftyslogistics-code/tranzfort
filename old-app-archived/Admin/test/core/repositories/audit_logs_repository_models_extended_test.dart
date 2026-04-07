import 'package:admin/src/core/repositories/audit_logs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditLogQuery defaults and pagination', () {
    test('uses default offset/limit and optional filters when omitted', () {
      const query = AuditLogQuery(keyword: 'ban');

      expect(query.keyword, 'ban');
      expect(query.action, '');
      expect(query.entityType, '');
      expect(query.offset, 0);
      expect(query.limit, 100);
      expect(query.from, isNull);
      expect(query.to, isNull);
    });

    test('stores custom filters and date window', () {
      final from = DateTime(2026, 2, 1);
      final to = DateTime(2026, 2, 27);
      final query = AuditLogQuery(
        keyword: 'resolve',
        action: 'resolve_ticket',
        entityType: 'support_ticket',
        from: from,
        to: to,
        offset: 50,
        limit: 25,
      );

      expect(query.keyword, 'resolve');
      expect(query.action, 'resolve_ticket');
      expect(query.entityType, 'support_ticket');
      expect(query.from, from);
      expect(query.to, to);
      expect(query.offset, 50);
      expect(query.limit, 25);
    });
  });

  group('AuditLogEntry metadata semantics', () {
    test('supports empty metadata map', () {
      final entry = AuditLogEntry(
        id: 'log-1',
        adminId: 'admin-1',
        adminName: 'Admin',
        action: 'assign_ticket',
        entityType: 'support_ticket',
        entityId: 'ticket-1',
        metadata: const {},
        createdAt: DateTime(2026, 2, 27, 10),
      );

      expect(entry.metadata, isEmpty);
      expect(entry.entityId, 'ticket-1');
      expect(entry.createdAt, isNotNull);
    });

    test('supports mixed-type metadata values', () {
      final entry = AuditLogEntry(
        id: 'log-2',
        adminId: 'admin-2',
        adminName: 'Ops Admin',
        action: 'force_assign',
        entityType: 'load',
        entityId: 'load-1',
        metadata: const {
          'trucker_id': 'trucker-1',
          'attempt': 2,
          'is_auto': false,
        },
        createdAt: DateTime(2026, 2, 27, 12),
      );

      expect(entry.metadata['trucker_id'], 'trucker-1');
      expect(entry.metadata['attempt'], 2);
      expect(entry.metadata['is_auto'], false);
    });
  });
}
