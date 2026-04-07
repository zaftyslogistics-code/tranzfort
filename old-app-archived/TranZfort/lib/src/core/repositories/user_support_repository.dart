import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/app_failure.dart';
import '../error/result.dart';

class UserSupportRepository {
  final SupabaseClient _supabase;

  UserSupportRepository(this._supabase);

  Future<Result<List<UserSupportTicketListItem>>> fetchMyTickets(
    String userId,
  ) async {
    try {
      final rows = await _supabase
          .from('support_tickets')
          .select(
            'id,subject,description,category,status,priority,created_at,resolved_at,resolution_notes',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final tickets = List<Map<String, dynamic>>.from(rows)
          .map(
            (row) => UserSupportTicketListItem(
              id: _asString(row['id']),
              subject: _asString(row['subject']),
              category: _asString(row['category']),
              status: userSupportTicketStatusFromDb(_asString(row['status'])),
              priority: userSupportTicketPriorityFromDb(
                _asString(row['priority']),
              ),
              createdAt: DateTime.tryParse(_asString(row['created_at'])),
              resolvedAt: DateTime.tryParse(_asString(row['resolved_at'])),
              resolutionNotes: _asString(row['resolution_notes']),
            ),
          )
          .toList(growable: false);

      return Success(tickets);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<UserSupportTicketDetail?>> fetchTicketDetail({
    required String ticketId,
    required String userId,
  }) async {
    try {
      final ticket = await _supabase
          .from('support_tickets')
          .select(
            'id,subject,description,category,status,priority,created_at,resolved_at,resolution_notes',
          )
          .eq('id', ticketId)
          .eq('user_id', userId)
          .maybeSingle();

      if (ticket == null) {
        return const Success(null);
      }

      final messageRows = await _supabase
          .from('support_ticket_messages')
          .select('id,sender_role,content,created_at')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      final messages = List<Map<String, dynamic>>.from(messageRows)
          .map(
            (row) => UserSupportTicketMessage(
              id: _asString(row['id']),
              senderRole: _asString(row['sender_role']),
              content: _asString(row['content']),
              createdAt: DateTime.tryParse(_asString(row['created_at'])),
            ),
          )
          .toList(growable: false);

      return Success(
        UserSupportTicketDetail(
          ticket: UserSupportTicketListItem(
            id: _asString(ticket['id']),
            subject: _asString(ticket['subject']),
            category: _asString(ticket['category']),
            status: userSupportTicketStatusFromDb(_asString(ticket['status'])),
            priority: userSupportTicketPriorityFromDb(
              _asString(ticket['priority']),
            ),
            createdAt: DateTime.tryParse(_asString(ticket['created_at'])),
            resolvedAt: DateTime.tryParse(_asString(ticket['resolved_at'])),
            resolutionNotes: _asString(ticket['resolution_notes']),
          ),
          description: _asString(ticket['description']),
          messages: messages,
        ),
      );
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<String>> createTicket({
    required String userId,
    required String subject,
    required String description,
    required String category,
  }) async {
    try {
      final row = await _supabase
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'subject': subject,
            'description': description,
            'category': category,
          })
          .select('id')
          .single();

      return Success(_asString(row['id']));
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }

  Future<Result<void>> sendReply({
    required String ticketId,
    required String userId,
    required String text,
  }) async {
    try {
      await _supabase.from('support_ticket_messages').insert({
        'ticket_id': ticketId,
        'sender_id': userId,
        'sender_role': 'user',
        'content': text,
      });
      return const Success(null);
    } catch (e) {
      return Failure(classifyError(e), debugMessage: e.toString());
    }
  }
}

String _asString(dynamic value) => (value ?? '').toString();

enum UserSupportTicketStatus { open, inProgress, resolved }

UserSupportTicketStatus userSupportTicketStatusFromDb(String value) {
  switch (value) {
    case 'in_progress':
      return UserSupportTicketStatus.inProgress;
    case 'resolved':
      return UserSupportTicketStatus.resolved;
    case 'open':
    default:
      return UserSupportTicketStatus.open;
  }
}

enum UserSupportTicketPriority { low, medium, high, urgent }

UserSupportTicketPriority userSupportTicketPriorityFromDb(String value) {
  switch (value) {
    case 'low':
      return UserSupportTicketPriority.low;
    case 'high':
      return UserSupportTicketPriority.high;
    case 'urgent':
      return UserSupportTicketPriority.urgent;
    case 'medium':
    default:
      return UserSupportTicketPriority.medium;
  }
}

class UserSupportTicketListItem {
  final String id;
  final String subject;
  final String category;
  final UserSupportTicketStatus status;
  final UserSupportTicketPriority priority;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String resolutionNotes;

  const UserSupportTicketListItem({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.resolvedAt,
    required this.resolutionNotes,
  });
}

class UserSupportTicketDetail {
  final UserSupportTicketListItem ticket;
  final String description;
  final List<UserSupportTicketMessage> messages;

  const UserSupportTicketDetail({
    required this.ticket,
    required this.description,
    required this.messages,
  });
}

class UserSupportTicketMessage {
  final String id;
  final String senderRole;
  final String content;
  final DateTime? createdAt;

  const UserSupportTicketMessage({
    required this.id,
    required this.senderRole,
    required this.content,
    required this.createdAt,
  });
}
