import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

enum SupportQueueTab { open, inProgress, resolved }

class SupportQueueQuery {
  final SupportQueueTab tab;
  final String search;
  final int page;
  final int pageSize;

  const SupportQueueQuery({
    required this.tab,
    required this.search,
    this.page = 0,
    this.pageSize = 20,
  });

  SupportQueueQuery copyWith({
    SupportQueueTab? tab,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return SupportQueueQuery(
      tab: tab ?? this.tab,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class SupportQueueCounts {
  final int open;
  final int inProgress;
  final int resolved;

  const SupportQueueCounts({
    required this.open,
    required this.inProgress,
    required this.resolved,
  });

  factory SupportQueueCounts.empty() {
    return const SupportQueueCounts(open: 0, inProgress: 0, resolved: 0);
  }
}

class AdminSupportTicketItem {
  final String id;
  final String ownerProfileId;
  final String ownerName;
  final String ownerContact;
  final String ownerRole;
  final String ownerVerificationStatus;
  final bool ownerIsBanned;
  final DateTime? ownerCreatedAt;
  final DateTime? ownerLastLoginAt;
  final String category;
  final String status;
  final String priority;
  final String relatedLoadId;
  final String relatedTripId;
  final String resolutionSummary;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  const AdminSupportTicketItem({
    required this.id,
    required this.ownerProfileId,
    required this.ownerName,
    required this.ownerContact,
    required this.ownerRole,
    required this.ownerVerificationStatus,
    required this.ownerIsBanned,
    required this.ownerCreatedAt,
    required this.ownerLastLoginAt,
    required this.category,
    required this.status,
    required this.priority,
    required this.relatedLoadId,
    required this.relatedTripId,
    required this.resolutionSummary,
    required this.createdAt,
    required this.updatedAt,
    required this.resolvedAt,
  });
}

class AdminSupportTicketMessage {
  final String id;
  final String senderLabel;
  final String messageBody;
  final String attachmentPath;
  final String visibilityClass;
  final DateTime? createdAt;

  const AdminSupportTicketMessage({
    required this.id,
    required this.senderLabel,
    required this.messageBody,
    required this.attachmentPath,
    required this.visibilityClass,
    required this.createdAt,
  });
}

class AdminSupportTicketDetail {
  final AdminSupportTicketItem ticket;
  final List<AdminSupportTicketMessage> messages;

  const AdminSupportTicketDetail({
    required this.ticket,
    required this.messages,
  });
}

class AdminSupportTicketPage {
  final List<AdminSupportTicketItem> items;
  final bool hasMore;
  final SupportQueueCounts counts;

  const AdminSupportTicketPage({
    required this.items,
    required this.hasMore,
    required this.counts,
  });
}

abstract class AdminSupportBackend {
  Future<List<Map<String, dynamic>>> fetchSupportTickets();

  Future<Map<String, dynamic>?> fetchSupportTicketById(String ticketId);

  Future<List<Map<String, dynamic>>> fetchSupportTicketMessages(String ticketId);

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids);

  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids);

  Future<bool> replyToSupportTicket({
    required String ticketId,
    required String messageBody,
  });
}

class SupabaseAdminSupportBackend implements AdminSupportBackend {
  final SupabaseClient? client;

  const SupabaseAdminSupportBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchSupportTickets() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('support_tickets')
          .select(
            'id, owner_profile_id, category, status, priority, related_load_id, related_trip_id, resolution_summary, created_at, updated_at, resolved_at',
          )
          .order('updated_at', ascending: false);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchSupportTicketById(String ticketId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    try {
      final row = await activeClient
          .from('support_tickets')
          .select(
            'id, owner_profile_id, category, status, priority, related_load_id, related_trip_id, resolution_summary, created_at, updated_at, resolved_at',
          )
          .eq('id', ticketId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return Map<String, dynamic>.from(row);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSupportTicketMessages(String ticketId) async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('support_ticket_messages')
          .select('id, support_ticket_id, sender_profile_id, sender_admin_user_id, message_body, attachment_path, visibility_class, created_at')
          .eq('support_ticket_id', ticketId)
          .order('created_at', ascending: true);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('profiles')
          .select('id, full_name, mobile, email, user_role_type, verification_status, is_banned, created_at, last_login_at')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('admin_users')
          .select('id, full_name, role')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<bool> replyToSupportTicket({
    required String ticketId,
    required String messageBody,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    try {
      await activeClient.rpc(
        'reply_to_support_ticket',
        params: {
          'p_support_ticket_id': ticketId,
          'p_message_body': messageBody,
          'p_visibility_class': 'visible',
          'p_attachment_path': null,
        },
      );
      return true;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class AdminSupportRepository {
  final AdminSupportBackend backend;

  const AdminSupportRepository({required this.backend});

  Future<AdminSupportTicketPage> getSupportQueue(SupportQueueQuery query) async {
    final ticketRows = await backend.fetchSupportTickets();
    final counts = SupportQueueCounts(
      open: ticketRows.where((row) => _tabForStatus(_asString(row['status'])) == SupportQueueTab.open).length,
      inProgress: ticketRows.where((row) => _tabForStatus(_asString(row['status'])) == SupportQueueTab.inProgress).length,
      resolved: ticketRows.where((row) => _tabForStatus(_asString(row['status'])) == SupportQueueTab.resolved).length,
    );

    final ownerIds = ticketRows
        .map((row) => _asString(row['owner_profile_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profiles = await backend.fetchProfilesByIds(ownerIds);
    final profileById = {for (final row in profiles) _asString(row['id']): row};

    final items = ticketRows
        .where((row) => _tabForStatus(_asString(row['status'])) == query.tab)
        .map((row) => _mapTicketItem(row, profileById))
        .where((item) => _matchesSearch(item, query.search))
        .toList(growable: false)
      ..sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    final total = items.length;
    final start = query.page * query.pageSize;
    if (start >= total) {
      return AdminSupportTicketPage(items: const [], hasMore: false, counts: counts);
    }
    final end = (start + query.pageSize) > total ? total : start + query.pageSize;
    return AdminSupportTicketPage(
      items: items.sublist(start, end),
      hasMore: end < total,
      counts: counts,
    );
  }

  Future<AdminSupportTicketDetail?> getSupportTicketDetail(String ticketId) async {
    final ticketRow = await backend.fetchSupportTicketById(ticketId);
    if (ticketRow == null) {
      return null;
    }
    final ownerId = _asString(ticketRow['owner_profile_id']);
    final messageRows = await backend.fetchSupportTicketMessages(ticketId);
    final profileIds = <String>{
      if (ownerId.isNotEmpty) ownerId,
      ...messageRows.map((row) => _asString(row['sender_profile_id'])).where((id) => id.isNotEmpty),
    }.toList(growable: false);
    final adminUserIds = messageRows
        .map((row) => _asString(row['sender_admin_user_id']))
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profiles = await backend.fetchProfilesByIds(profileIds);
    final adminUsers = await backend.fetchAdminUsersByIds(adminUserIds);
    final profileById = {for (final row in profiles) _asString(row['id']): row};
    final adminUserById = {for (final row in adminUsers) _asString(row['id']): row};
    final ticket = _mapTicketItem(ticketRow, profileById);
    final messages = messageRows
        .map(
          (row) => AdminSupportTicketMessage(
            id: _asString(row['id']),
            senderLabel: _asString(row['sender_admin_user_id']).isNotEmpty
                ? _adminSenderLabel(adminUserById[_asString(row['sender_admin_user_id'])])
                : (_asString(profileById[_asString(row['sender_profile_id'])]?['full_name']).isEmpty
                    ? 'User'
                    : _asString(profileById[_asString(row['sender_profile_id'])]?['full_name'])),
            messageBody: _asString(row['message_body']),
            attachmentPath: _asString(row['attachment_path']),
            visibilityClass: _asString(row['visibility_class']),
            createdAt: DateTime.tryParse(_asString(row['created_at'])),
          ),
        )
        .toList(growable: false);
    return AdminSupportTicketDetail(ticket: ticket, messages: messages);
  }

  Future<bool> replyToSupportTicket({
    required String ticketId,
    required String messageBody,
  }) {
    return backend.replyToSupportTicket(ticketId: ticketId, messageBody: messageBody.trim());
  }

  AdminSupportTicketItem _mapTicketItem(
    Map<String, dynamic> row,
    Map<String, Map<String, dynamic>> profileById,
  ) {
    final ownerProfile = profileById[_asString(row['owner_profile_id'])];
    return AdminSupportTicketItem(
      id: _asString(row['id']),
      ownerProfileId: _asString(row['owner_profile_id']),
      ownerName: _asString(ownerProfile?['full_name']).isEmpty ? 'Unknown user' : _asString(ownerProfile?['full_name']),
      ownerContact: [
        _asString(ownerProfile?['mobile']),
        _asString(ownerProfile?['email']),
      ].where((part) => part.isNotEmpty).join(' • '),
      ownerRole: _asString(ownerProfile?['user_role_type']),
      ownerVerificationStatus: _asString(ownerProfile?['verification_status']),
      ownerIsBanned: _asBool(ownerProfile?['is_banned']),
      ownerCreatedAt: DateTime.tryParse(_asString(ownerProfile?['created_at'])),
      ownerLastLoginAt: DateTime.tryParse(_asString(ownerProfile?['last_login_at'])),
      category: _asString(row['category']),
      status: _asString(row['status']),
      priority: _asString(row['priority']),
      relatedLoadId: _asString(row['related_load_id']),
      relatedTripId: _asString(row['related_trip_id']),
      resolutionSummary: _asString(row['resolution_summary']),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
      updatedAt: DateTime.tryParse(_asString(row['updated_at'])),
      resolvedAt: DateTime.tryParse(_asString(row['resolved_at'])),
    );
  }
}

String _adminSenderLabel(Map<String, dynamic>? row) {
  final fullName = _asString(row?['full_name']);
  final role = _asString(row?['role']);
  if (fullName.isEmpty && role.isEmpty) {
    return 'Admin';
  }
  if (fullName.isEmpty) {
    return role.isEmpty ? 'Admin' : 'Admin ($role)';
  }
  return role.isEmpty ? fullName : '$fullName ($role)';
}

SupportQueueTab _tabForStatus(String value) {
  return switch (value.trim()) {
    'resolved' || 'closed' => SupportQueueTab.resolved,
    'open' => SupportQueueTab.open,
    _ => SupportQueueTab.inProgress,
  };
}

bool _matchesSearch(AdminSupportTicketItem item, String search) {
  final normalized = search.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return item.id.toLowerCase().contains(normalized) ||
      item.ownerProfileId.toLowerCase().contains(normalized) ||
      item.ownerName.toLowerCase().contains(normalized) ||
      item.ownerContact.toLowerCase().contains(normalized) ||
      item.ownerRole.toLowerCase().contains(normalized) ||
      item.ownerVerificationStatus.toLowerCase().contains(normalized) ||
      (item.ownerIsBanned ? 'banned' : 'active').contains(normalized) ||
      item.category.toLowerCase().contains(normalized) ||
      item.status.toLowerCase().contains(normalized) ||
      item.priority.toLowerCase().contains(normalized) ||
      item.resolutionSummary.toLowerCase().contains(normalized) ||
      item.relatedLoadId.toLowerCase().contains(normalized) ||
      item.relatedTripId.toLowerCase().contains(normalized);
}

String _asString(dynamic value) => (value ?? '').toString();

bool _asBool(dynamic value) => value == true;

final adminSupportBackendProvider = Provider<AdminSupportBackend>((ref) {
  return SupabaseAdminSupportBackend(ref.watch(adminSupabaseClientProvider));
});

final adminSupportRepositoryProvider = Provider<AdminSupportRepository>((ref) {
  return AdminSupportRepository(backend: ref.watch(adminSupportBackendProvider));
});
