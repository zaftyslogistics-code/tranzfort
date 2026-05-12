import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';

class _FakeSupportBackend implements SupportBackend {
  List<Map<String, dynamic>> ticketRows = const <Map<String, dynamic>>[];
  final Map<String, Map<String, dynamic>> ticketById = <String, Map<String, dynamic>>{};
  final Map<String, List<Map<String, dynamic>>> messagesByTicket = <String, List<Map<String, dynamic>>>{};
  Object? error;
  String createdTicketId = 'ticket-created';
  String createdReplyId = 'reply-created';
  String? lastCreateCategory;
  String? lastCreateMessageBody;
  String? lastReplyTicketId;
  String? lastReplyMessageBody;

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({required String userId, int limit = 20, DateTime? before}) async {
    if (error != null) {
      throw error!;
    }
    var rows = ticketRows;
    if (before != null) {
      rows = rows
          .where(
            (row) => DateTime.parse((row['created_at'] ?? '').toString()).isBefore(before),
          )
          .toList(growable: false);
    }
    return rows.take(limit).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchTicket({required String userId, required String ticketId}) async {
    if (error != null) {
      throw error!;
    }
    return ticketById[ticketId];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({
    required String userId,
    required String ticketId,
    int limit = 50,
  }) async {
    if (error != null) {
      throw error!;
    }
    return messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessagesPaginated({
    required String userId,
    required String ticketId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async {
    if (error != null) {
      throw error!;
    }
    final messages = messagesByTicket[ticketId] ?? const <Map<String, dynamic>>[];
    return messages.take(limit).toList(growable: false);
  }

  @override
  Future<String> createTicket({
    required String category,
    required String messageBody,
    String? relatedLoadId,
    String? relatedTripId,
    String? attachmentPath,
    SupportTicketPriority? priority,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastCreateCategory = category;
    lastCreateMessageBody = messageBody;
    return createdTicketId;
  }

  @override
  Future<String> replyToTicket({
    required String ticketId,
    required String messageBody,
    String? attachmentPath,
  }) async {
    if (error != null) {
      throw error!;
    }
    lastReplyTicketId = ticketId;
    lastReplyMessageBody = messageBody;
    return createdReplyId;
  }

  @override
  Future<int> finalizeTicketAttachments({
    required String ticketId,
    required String sessionId,
  }) async {
    if (error != null) {
      throw error!;
    }
    return 0; // Mock implementation
  }
}

void main() {
  test('support repository maps ticket list', () async {
    final backend = _FakeSupportBackend()
      ..ticketRows = [
        {
          'id': 'ticket-1',
          'category': 'trip_dispute',
          'status': 'waiting_for_user',
          'priority': 'high',
          'related_load_id': 'load-1',
          'related_trip_id': 'trip-1',
          'resolution_summary': null,
          'created_at': '2026-03-10T09:00:00.000Z',
          'updated_at': '2026-03-10T10:00:00.000Z',
          'resolved_at': null,
        },
      ];
    final repository = SupportRepository(backend, () => 'user-1');

    final result = await repository.getTickets();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(1));
    expect(result.valueOrNull!.first.status, SupportTicketStatus.waitingForUser);
    expect(result.valueOrNull!.first.priority, SupportTicketPriority.high);
    expect(result.valueOrNull!.first.relatedTripId, 'trip-1');
  });

  test('support repository sorts tickets by latest updated activity', () async {
    final backend = _FakeSupportBackend()
      ..ticketRows = [
        {
          'id': 'ticket-older-update',
          'category': 'trip_dispute',
          'status': 'open',
          'priority': 'medium',
          'related_load_id': 'load-1',
          'related_trip_id': 'trip-1',
          'resolution_summary': null,
          'created_at': '2026-03-10T12:00:00.000Z',
          'updated_at': '2026-03-10T12:05:00.000Z',
          'resolved_at': null,
        },
        {
          'id': 'ticket-newer-update',
          'category': 'non_payment',
          'status': 'in_progress',
          'priority': 'high',
          'related_load_id': 'load-2',
          'related_trip_id': null,
          'resolution_summary': null,
          'created_at': '2026-03-10T08:00:00.000Z',
          'updated_at': '2026-03-10T13:00:00.000Z',
          'resolved_at': null,
        },
      ];
    final repository = SupportRepository(backend, () => 'user-1');

    final result = await repository.getTickets();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.map((ticket) => ticket.id).toList(), ['ticket-newer-update', 'ticket-older-update']);
  });

  test('support repository maps ticket detail and messages', () async {
    final backend = _FakeSupportBackend()
      ..ticketById['ticket-1'] = {
        'id': 'ticket-1',
        'category': 'trip_dispute',
        'status': 'in_progress',
        'priority': 'medium',
        'related_load_id': 'load-1',
        'related_trip_id': 'trip-1',
        'resolution_summary': null,
        'created_at': '2026-03-10T09:00:00.000Z',
        'updated_at': '2026-03-10T10:00:00.000Z',
        'resolved_at': null,
      }
      ..messagesByTicket['ticket-1'] = [
        {
          'id': 'message-1',
          'support_ticket_id': 'ticket-1',
          'sender_profile_id': 'user-1',
          'sender_admin_user_id': null,
          'message_body': 'Initial dispute reason',
          'attachment_path': null,
          'visibility_class': 'visible',
          'created_at': '2026-03-10T09:05:00.000Z',
        },
        {
          'id': 'message-2',
          'support_ticket_id': 'ticket-1',
          'sender_profile_id': null,
          'sender_admin_user_id': 'admin-1',
          'message_body': 'Please upload extra proof',
          'attachment_path': null,
          'visibility_class': 'visible',
          'created_at': '2026-03-10T09:10:00.000Z',
        },
      ];
    final repository = SupportRepository(backend, () => 'user-1');

    final result = await repository.getTicketDetail('ticket-1');

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.ticket.id, 'ticket-1');
    expect(result.valueOrNull!.messages, hasLength(2));
    expect(result.valueOrNull!.messages.first.senderType, SupportMessageSenderType.user);
    expect(result.valueOrNull!.messages.last.senderType, SupportMessageSenderType.support);
  });

  test('support repository validates missing ticket id', () async {
    final repository = SupportRepository(_FakeSupportBackend(), () => 'user-1');

    final result = await repository.getTicketDetail('   ');

    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('support repository creates support ticket through backend rpc contract', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');

    final result = await repository.createTicket(
      category: 'general',
      messageBody: 'Need help with my account flow.',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'ticket-created');
    expect(backend.lastCreateCategory, 'general');
    expect(backend.lastCreateMessageBody, 'Need help with my account flow.');
  });

  test('support repository sends user reply through backend rpc contract', () async {
    final backend = _FakeSupportBackend();
    final repository = SupportRepository(backend, () => 'user-1');

    final result = await repository.replyToTicket(
      ticketId: 'ticket-1',
      messageBody: 'Uploading the extra proof now.',
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'reply-created');
    expect(backend.lastReplyTicketId, 'ticket-1');
    expect(backend.lastReplyMessageBody, 'Uploading the extra proof now.');
  });

  test('support repository returns unauthorized when no user session exists', () async {
    final repository = SupportRepository(_FakeSupportBackend(), () => null);

    final result = await repository.getTickets();

    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });

  test('support repository maps backend errors', () async {
    final backend = _FakeSupportBackend()
      ..error = const PostgrestException(message: 'permission denied', code: '42501');
    final repository = SupportRepository(backend, () => 'user-1');

    final result = await repository.getTickets();

    expect(result.failureOrNull, isA<PermissionFailure>());
  });
}
