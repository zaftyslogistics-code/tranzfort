import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('support ticket list/detail/message models', () {
    test('SupportTicketListItem stores display metadata', () {
      final createdAt = DateTime(2026, 2, 27);
      final item = SupportTicketListItem(
        id: 'ticket-1',
        subject: 'Payment mismatch',
        userName: 'Supplier One',
        priority: SupportTicketPriority.urgent,
        status: SupportTicketStatus.inProgress,
        createdAt: createdAt,
        assignedAdminId: 'admin-1',
        assignedAdminName: 'Support Agent',
      );

      expect(item.id, 'ticket-1');
      expect(item.subject, contains('Payment'));
      expect(item.priority, SupportTicketPriority.urgent);
      expect(item.status, SupportTicketStatus.inProgress);
      expect(item.assignedAdminName, 'Support Agent');
      expect(item.createdAt, createdAt);
    });

    test('SupportTicketMessage stores sender metadata and content', () {
      final createdAt = DateTime(2026, 2, 27, 10, 30);
      final message = SupportTicketMessage(
        id: 'msg-1',
        senderRole: 'admin',
        senderName: 'Super Admin',
        content: 'We are checking this now.',
        createdAt: createdAt,
      );

      expect(message.id, 'msg-1');
      expect(message.senderRole, 'admin');
      expect(message.senderName, 'Super Admin');
      expect(message.content, contains('checking'));
      expect(message.createdAt, createdAt);
    });

    test('SupportTicketDetail composes ticket + messages + user metadata', () {
      final ticket = SupportTicketListItem(
        id: 'ticket-2',
        subject: 'Delay issue',
        userName: 'Trucker One',
        priority: SupportTicketPriority.high,
        status: SupportTicketStatus.open,
        createdAt: DateTime(2026, 2, 27),
        assignedAdminId: '',
        assignedAdminName: '',
      );
      final messages = [
        SupportTicketMessage(
          id: 'msg-2',
          senderRole: 'user',
          senderName: 'Trucker One',
          content: 'Need update',
          createdAt: DateTime(2026, 2, 27, 9),
        ),
        SupportTicketMessage(
          id: 'msg-3',
          senderRole: 'admin',
          senderName: 'Support Agent',
          content: 'Acknowledged',
          createdAt: DateTime(2026, 2, 27, 10),
        ),
      ];

      final detail = SupportTicketDetail(
        ticket: ticket,
        description: 'Trip was delayed by 6 hours',
        category: 'trip_status',
        userMobile: '9999999999',
        userEmail: 'trucker@example.com',
        userRole: 'trucker',
        resolutionNotes: '',
        resolvedAt: null,
        messages: messages,
      );

      expect(detail.ticket.id, 'ticket-2');
      expect(detail.userRole, 'trucker');
      expect(detail.category, 'trip_status');
      expect(detail.messages.length, 2);
      expect(detail.messages.last.senderRole, 'admin');
    });
  });
}
