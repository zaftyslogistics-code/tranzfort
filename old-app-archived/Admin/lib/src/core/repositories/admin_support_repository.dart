import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'admin_audit_repository.dart';

final adminSupportRepositoryProvider = Provider<AdminSupportRepository>(
  (ref) => AdminSupportRepository(ref),
);

class AdminSupportRepository {
  final Ref _ref;

  AdminSupportRepository(this._ref);

  Future<SupportTicketCounts> fetchCounts() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const SupportTicketCounts();

    final client = Supabase.instance.client;

    final open = await _safeCount(() {
      return client
          .from('support_tickets')
          .select('id')
          .eq('status', supportTicketStatusDbValue(SupportTicketStatus.open));
    });
    final inProgress = await _safeCount(() {
      return client
          .from('support_tickets')
          .select('id')
          .eq(
            'status',
            supportTicketStatusDbValue(SupportTicketStatus.inProgress),
          );
    });
    final resolved = await _safeCount(() {
      return client
          .from('support_tickets')
          .select('id')
          .eq(
            'status',
            supportTicketStatusDbValue(SupportTicketStatus.resolved),
          );
    });

    return SupportTicketCounts(
      open: open,
      inProgress: inProgress,
      resolved: resolved,
    );
  }

  Future<List<SupportTicketListItem>> fetchQueue(
    SupportTicketQueueQuery query,
  ) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      final rows = await client
          .from('support_tickets')
          .select(
            'id,user_id,subject,status,priority,assigned_to,created_at,updated_at',
          )
          .eq('status', supportTicketStatusDbValue(query.status))
          .order('created_at', ascending: false);

      final tickets = List<Map<String, dynamic>>.from(rows);
      if (tickets.isEmpty) return const [];

      final userIds = tickets
          .map((e) => _asString(e['user_id']))
          .toSet()
          .toList();
      final adminIds = tickets
          .map((e) => _asString(e['assigned_to']))
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      final userNames = await _loadProfileNames(client, userIds);
      final adminNames = await _loadAdminNamesByAdminId(client, adminIds);

      final loweredQuery = query.search.trim().toLowerCase();
      final items = tickets
          .map((row) {
            final userId = _asString(row['user_id']);
            final assignedTo = _asString(row['assigned_to']);
            return SupportTicketListItem(
              id: _asString(row['id']),
              subject: _asString(row['subject']),
              userName: userNames[userId] ?? userId,
              priority: supportTicketPriorityFromDb(_asString(row['priority'])),
              status: supportTicketStatusFromDb(_asString(row['status'])),
              createdAt: DateTime.tryParse(_asString(row['created_at'])),
              assignedAdminId: assignedTo,
              assignedAdminName: assignedTo.isEmpty
                  ? ''
                  : (adminNames[assignedTo] ?? ''),
            );
          })
          .where((item) {
            if (loweredQuery.isEmpty) return true;
            return item.subject.toLowerCase().contains(loweredQuery) ||
                item.userName.toLowerCase().contains(loweredQuery) ||
                item.id.toLowerCase().contains(loweredQuery);
          })
          .toList();

      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<SupportTicketDetail?> fetchTicketDetail(String ticketId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return null;

    final client = Supabase.instance.client;

    try {
      final ticket = await client
          .from('support_tickets')
          .select(
            'id,user_id,subject,description,category,status,priority,assigned_to,resolved_by,resolution_notes,created_at,updated_at,resolved_at',
          )
          .eq('id', ticketId)
          .maybeSingle();
      if (ticket == null) return null;

      final userId = _asString(ticket['user_id']);
      final userProfile = await client
          .from('profiles')
          .select('full_name,mobile,email,user_role_type')
          .eq('id', userId)
          .maybeSingle();

      final assignedToId = _asString(ticket['assigned_to']);
      final assignedName = assignedToId.isEmpty
          ? ''
          : await _loadAdminNameByAdminId(client, assignedToId);

      final messageRows = await client
          .from('support_ticket_messages')
          .select('id,sender_id,sender_role,content,created_at')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);
      final messageList = List<Map<String, dynamic>>.from(messageRows);

      final adminSenderAuthIds = messageList
          .where((m) => _asString(m['sender_role']) == 'admin')
          .map((m) => _asString(m['sender_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final adminSenderNames = await _loadAdminNamesByAuthId(
        client,
        adminSenderAuthIds,
      );

      final messages = messageList.map((m) {
        final senderRole = _asString(m['sender_role']);
        final senderId = _asString(m['sender_id']);
        final senderName = senderRole == 'admin'
            ? (adminSenderNames[senderId] ?? 'Admin')
            : _asString(userProfile?['full_name']).ifEmpty('User');
        return SupportTicketMessage(
          id: _asString(m['id']),
          senderRole: senderRole,
          senderName: senderName,
          content: _asString(m['content']),
          createdAt: DateTime.tryParse(_asString(m['created_at'])),
        );
      }).toList();

      return SupportTicketDetail(
        ticket: SupportTicketListItem(
          id: _asString(ticket['id']),
          subject: _asString(ticket['subject']),
          userName: _asString(userProfile?['full_name']),
          priority: supportTicketPriorityFromDb(_asString(ticket['priority'])),
          status: supportTicketStatusFromDb(_asString(ticket['status'])),
          createdAt: DateTime.tryParse(_asString(ticket['created_at'])),
          assignedAdminId: assignedToId,
          assignedAdminName: assignedName,
        ),
        description: _asString(ticket['description']),
        category: _asString(ticket['category']),
        userMobile: _asString(userProfile?['mobile']),
        userEmail: _asString(userProfile?['email']),
        userRole: _asString(userProfile?['user_role_type']),
        resolutionNotes: _asString(ticket['resolution_notes']),
        resolvedAt: DateTime.tryParse(_asString(ticket['resolved_at'])),
        messages: messages,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> assignToMe(String ticketId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await client
          .from('support_tickets')
          .update({
            'assigned_to': adminId,
            'status': supportTicketStatusDbValue(
              SupportTicketStatus.inProgress,
            ),
            'updated_at': now,
          })
          .eq('id', ticketId);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'assign_ticket',
            entityType: 'support_ticket',
            entityId: ticketId,
            metadata: {'assigned_to': adminId},
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePriority({
    required String ticketId,
    required SupportTicketPriority priority,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      await client
          .from('support_tickets')
          .update({
            'priority': supportTicketPriorityDbValue(priority),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', ticketId);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'change_ticket_priority',
            entityType: 'support_ticket',
            entityId: ticketId,
            metadata: {'priority': supportTicketPriorityDbValue(priority)},
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendReply({
    required String ticketId,
    required String text,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final authUserId = client.auth.currentUser?.id;
    if (authUserId == null) return false;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await client.from('support_ticket_messages').insert({
        'ticket_id': ticketId,
        'sender_id': authUserId,
        'sender_role': 'admin',
        'content': text,
        'created_at': now,
      });
      await client
          .from('support_tickets')
          .update({
            'status': supportTicketStatusDbValue(
              SupportTicketStatus.inProgress,
            ),
            'updated_at': now,
          })
          .eq('id', ticketId);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'reply_ticket',
            entityType: 'support_ticket',
            entityId: ticketId,
            metadata: {'message_length': text.length},
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resolveTicket({
    required String ticketId,
    required String notes,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await client
          .from('support_tickets')
          .update({
            'status': supportTicketStatusDbValue(SupportTicketStatus.resolved),
            'resolution_notes': notes,
            'resolved_by': adminId,
            'resolved_at': now,
            'updated_at': now,
          })
          .eq('id', ticketId);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'resolve_ticket',
            entityType: 'support_ticket',
            entityId: ticketId,
            metadata: {'notes_length': notes.length},
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() call) async {
    try {
      final rows = await call();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _currentAdminId(SupabaseClient client) async {
    final authUserId = client.auth.currentUser?.id;
    if (authUserId == null) return null;

    try {
      final row = await client
          .from('admin_users')
          .select('id,is_active')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null || row['is_active'] != true) return null;
      return _asString(row['id']);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _loadProfileNames(
    SupabaseClient client,
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', userIds);
      return {
        for (final row in rows)
          _asString(row['id']): _asString(
            row['full_name'],
          ).ifEmpty('Unknown user'),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<String> _loadAdminNameByAdminId(
    SupabaseClient client,
    String adminId,
  ) async {
    try {
      final row = await client
          .from('admin_users')
          .select('full_name')
          .eq('id', adminId)
          .maybeSingle();
      return _asString(row?['full_name']);
    } catch (_) {
      return '';
    }
  }

  Future<Map<String, String>> _loadAdminNamesByAdminId(
    SupabaseClient client,
    List<String> adminIds,
  ) async {
    if (adminIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('admin_users')
          .select('id,full_name')
          .inFilter('id', adminIds);
      return {
        for (final row in rows)
          _asString(row['id']): _asString(row['full_name']).ifEmpty('Admin'),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, String>> _loadAdminNamesByAuthId(
    SupabaseClient client,
    List<String> authIds,
  ) async {
    if (authIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('admin_users')
          .select('auth_user_id,full_name')
          .inFilter('auth_user_id', authIds);
      return {
        for (final row in rows)
          _asString(row['auth_user_id']): _asString(
            row['full_name'],
          ).ifEmpty('Admin'),
      };
    } catch (_) {
      return const {};
    }
  }
}

String _asString(dynamic value) => (value ?? '').toString();

enum SupportTicketStatus { open, inProgress, resolved }

SupportTicketStatus supportTicketStatusFromDb(String value) {
  switch (value) {
    case 'in_progress':
      return SupportTicketStatus.inProgress;
    case 'resolved':
      return SupportTicketStatus.resolved;
    case 'open':
    default:
      return SupportTicketStatus.open;
  }
}

String supportTicketStatusDbValue(SupportTicketStatus status) {
  switch (status) {
    case SupportTicketStatus.open:
      return 'open';
    case SupportTicketStatus.inProgress:
      return 'in_progress';
    case SupportTicketStatus.resolved:
      return 'resolved';
  }
}

enum SupportTicketPriority { low, medium, high, urgent }

SupportTicketPriority supportTicketPriorityFromDb(String value) {
  switch (value) {
    case 'low':
      return SupportTicketPriority.low;
    case 'high':
      return SupportTicketPriority.high;
    case 'urgent':
      return SupportTicketPriority.urgent;
    case 'medium':
    default:
      return SupportTicketPriority.medium;
  }
}

String supportTicketPriorityDbValue(SupportTicketPriority priority) {
  switch (priority) {
    case SupportTicketPriority.low:
      return 'low';
    case SupportTicketPriority.medium:
      return 'medium';
    case SupportTicketPriority.high:
      return 'high';
    case SupportTicketPriority.urgent:
      return 'urgent';
  }
}

class SupportTicketQueueQuery {
  final SupportTicketStatus status;
  final String search;

  const SupportTicketQueueQuery({required this.status, required this.search});

  @override
  bool operator ==(Object other) {
    return other is SupportTicketQueueQuery &&
        other.status == status &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(status, search);
}

class SupportTicketCounts {
  final int open;
  final int inProgress;
  final int resolved;

  const SupportTicketCounts({
    this.open = 0,
    this.inProgress = 0,
    this.resolved = 0,
  });
}

class SupportTicketListItem {
  final String id;
  final String subject;
  final String userName;
  final SupportTicketPriority priority;
  final SupportTicketStatus status;
  final DateTime? createdAt;
  final String assignedAdminId;
  final String assignedAdminName;

  const SupportTicketListItem({
    required this.id,
    required this.subject,
    required this.userName,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.assignedAdminId,
    required this.assignedAdminName,
  });
}

class SupportTicketDetail {
  final SupportTicketListItem ticket;
  final String description;
  final String category;
  final String userMobile;
  final String userEmail;
  final String userRole;
  final String resolutionNotes;
  final DateTime? resolvedAt;
  final List<SupportTicketMessage> messages;

  const SupportTicketDetail({
    required this.ticket,
    required this.description,
    required this.category,
    required this.userMobile,
    required this.userEmail,
    required this.userRole,
    required this.resolutionNotes,
    required this.resolvedAt,
    required this.messages,
  });
}

class SupportTicketMessage {
  final String id;
  final String senderRole;
  final String senderName;
  final String content;
  final DateTime? createdAt;

  const SupportTicketMessage({
    required this.id,
    required this.senderRole,
    required this.senderName,
    required this.content,
    required this.createdAt,
  });
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
