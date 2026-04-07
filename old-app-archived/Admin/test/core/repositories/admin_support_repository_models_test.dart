import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('support ticket status mappings', () {
    test('supportTicketStatusFromDb maps known values and defaults to open', () {
      expect(supportTicketStatusFromDb('open'), SupportTicketStatus.open);
      expect(
        supportTicketStatusFromDb('in_progress'),
        SupportTicketStatus.inProgress,
      );
      expect(
        supportTicketStatusFromDb('resolved'),
        SupportTicketStatus.resolved,
      );
      expect(supportTicketStatusFromDb('unknown'), SupportTicketStatus.open);
    });

    test('supportTicketStatusDbValue maps enum to DB values', () {
      expect(supportTicketStatusDbValue(SupportTicketStatus.open), 'open');
      expect(
        supportTicketStatusDbValue(SupportTicketStatus.inProgress),
        'in_progress',
      );
      expect(
        supportTicketStatusDbValue(SupportTicketStatus.resolved),
        'resolved',
      );
    });
  });

  group('support ticket priority mappings', () {
    test('supportTicketPriorityFromDb maps known values and defaults to medium', () {
      expect(supportTicketPriorityFromDb('low'), SupportTicketPriority.low);
      expect(
        supportTicketPriorityFromDb('medium'),
        SupportTicketPriority.medium,
      );
      expect(supportTicketPriorityFromDb('high'), SupportTicketPriority.high);
      expect(
        supportTicketPriorityFromDb('urgent'),
        SupportTicketPriority.urgent,
      );
      expect(
        supportTicketPriorityFromDb('unknown'),
        SupportTicketPriority.medium,
      );
    });

    test('supportTicketPriorityDbValue maps enum to DB values', () {
      expect(supportTicketPriorityDbValue(SupportTicketPriority.low), 'low');
      expect(
        supportTicketPriorityDbValue(SupportTicketPriority.medium),
        'medium',
      );
      expect(supportTicketPriorityDbValue(SupportTicketPriority.high), 'high');
      expect(
        supportTicketPriorityDbValue(SupportTicketPriority.urgent),
        'urgent',
      );
    });
  });

  group('support ticket query/models', () {
    test('SupportTicketQueueQuery equality/hc are stable', () {
      const a = SupportTicketQueueQuery(
        status: SupportTicketStatus.open,
        search: 'load',
      );
      const b = SupportTicketQueueQuery(
        status: SupportTicketStatus.open,
        search: 'load',
      );
      const c = SupportTicketQueueQuery(
        status: SupportTicketStatus.resolved,
        search: 'load',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('SupportTicketCounts has zero defaults', () {
      const counts = SupportTicketCounts();
      expect(counts.open, 0);
      expect(counts.inProgress, 0);
      expect(counts.resolved, 0);
    });
  });
}
