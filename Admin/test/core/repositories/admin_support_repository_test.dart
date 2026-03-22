import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminSupportBackend implements AdminSupportBackend {
  List<Map<String, dynamic>> supportTickets = const [];
  Map<String, Map<String, dynamic>> supportTicketsById = const {};
  Map<String, List<Map<String, dynamic>>> supportMessagesByTicketId = const {};
  Map<String, Map<String, dynamic>> profilesById = const {};
  Map<String, Map<String, dynamic>> adminUsersById = const {};
  String? lastReplyTicketId;
  String? lastReplyMessage;

  @override
  Future<List<Map<String, dynamic>>> fetchSupportTickets() async => supportTickets;

  @override
  Future<Map<String, dynamic>?> fetchSupportTicketById(String ticketId) async => supportTicketsById[ticketId];

  @override
  Future<List<Map<String, dynamic>>> fetchSupportTicketMessages(String ticketId) async => supportMessagesByTicketId[ticketId] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async => ids
      .map((id) => profilesById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<List<Map<String, dynamic>>> fetchAdminUsersByIds(List<String> ids) async => ids
      .map((id) => adminUsersById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<bool> replyToSupportTicket({required String ticketId, required String messageBody}) async {
    lastReplyTicketId = ticketId;
    lastReplyMessage = messageBody;
    return true;
  }
}

void main() {
  test('getSupportQueue maps tickets, supports stable id search, and counts by tab', () async {
    final backend = _FakeAdminSupportBackend()
      ..supportTickets = [
        {
          'id': 'ticket-1',
          'owner_profile_id': 'user-1',
          'category': 'payment',
          'status': 'open',
          'priority': 'high',
          'related_load_id': 'load-1',
          'related_trip_id': 'trip-1',
          'resolution_summary': '',
          'created_at': '2026-03-11T08:00:00.000Z',
          'updated_at': '2026-03-11T08:30:00.000Z',
          'resolved_at': null,
        },
        {
          'id': 'ticket-2',
          'owner_profile_id': 'user-2',
          'category': 'spam_or_scam',
          'status': 'resolved',
          'priority': 'urgent',
          'related_load_id': null,
          'related_trip_id': null,
          'resolution_summary': 'Closed after review',
          'created_at': '2026-03-10T08:00:00.000Z',
          'updated_at': '2026-03-10T08:30:00.000Z',
          'resolved_at': '2026-03-10T09:00:00.000Z',
        },
      ]
      ..profilesById = {
        'user-1': {
          'id': 'user-1',
          'full_name': 'Supplier One',
          'mobile': '9999999999',
          'email': 'supplier@example.com',
          'user_role_type': 'supplier',
          'verification_status': 'approved',
          'is_banned': false,
          'created_at': '2026-02-01T08:00:00.000Z',
          'last_login_at': '2026-03-11T07:55:00.000Z',
        },
        'user-2': {
          'id': 'user-2',
          'full_name': 'Trucker Two',
          'mobile': '8888888888',
          'email': 'trucker@example.com',
          'user_role_type': 'trucker',
          'verification_status': 'pending',
          'is_banned': true,
          'created_at': '2026-01-15T08:00:00.000Z',
          'last_login_at': '2026-03-09T07:55:00.000Z',
        },
      };

    final container = ProviderContainer(overrides: [adminSupportBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminSupportRepositoryProvider);
    final page = await repository.getSupportQueue(const SupportQueueQuery(tab: SupportQueueTab.open, search: 'supplier'));
    final ownerIdPage = await repository.getSupportQueue(const SupportQueueQuery(tab: SupportQueueTab.open, search: 'user-1'));
    final loadIdPage = await repository.getSupportQueue(const SupportQueueQuery(tab: SupportQueueTab.open, search: 'load-1'));
    final tripIdPage = await repository.getSupportQueue(const SupportQueueQuery(tab: SupportQueueTab.open, search: 'trip-1'));
    final resolutionPage = await repository.getSupportQueue(
      const SupportQueueQuery(tab: SupportQueueTab.resolved, search: 'closed after review'),
    );
    final rolePage = await repository.getSupportQueue(const SupportQueueQuery(tab: SupportQueueTab.open, search: 'supplier'));
    final verificationPage = await repository.getSupportQueue(
      const SupportQueueQuery(tab: SupportQueueTab.open, search: 'approved'),
    );
    final activeStatePage = await repository.getSupportQueue(const SupportQueueQuery(tab: SupportQueueTab.open, search: 'active'));
    final bannedStatePage = await repository.getSupportQueue(
      const SupportQueueQuery(tab: SupportQueueTab.resolved, search: 'banned'),
    );

    expect(page.counts.open, 1);
    expect(page.counts.resolved, 1);
    expect(page.items, hasLength(1));
    expect(page.items.single.ownerName, 'Supplier One');
    expect(page.items.single.ownerRole, 'supplier');
    expect(page.items.single.ownerVerificationStatus, 'approved');
    expect(page.items.single.ownerIsBanned, isFalse);
    expect(page.items.single.relatedLoadId, 'load-1');
    expect(page.items.single.relatedTripId, 'trip-1');
    expect(ownerIdPage.items, hasLength(1));
    expect(ownerIdPage.items.single.id, 'ticket-1');
    expect(loadIdPage.items, hasLength(1));
    expect(loadIdPage.items.single.id, 'ticket-1');
    expect(tripIdPage.items, hasLength(1));
    expect(tripIdPage.items.single.id, 'ticket-1');
    expect(resolutionPage.items, hasLength(1));
    expect(resolutionPage.items.single.id, 'ticket-2');
    expect(rolePage.items, hasLength(1));
    expect(rolePage.items.single.id, 'ticket-1');
    expect(verificationPage.items, hasLength(1));
    expect(verificationPage.items.single.id, 'ticket-1');
    expect(activeStatePage.items, hasLength(1));
    expect(activeStatePage.items.single.id, 'ticket-1');
    expect(bannedStatePage.items, hasLength(1));
    expect(bannedStatePage.items.single.id, 'ticket-2');
  });

  test('getSupportTicketDetail maps messages and reply uses backend contract', () async {
    final backend = _FakeAdminSupportBackend()
      ..supportTicketsById = {
        'ticket-1': {
          'id': 'ticket-1',
          'owner_profile_id': 'user-1',
          'category': 'payment',
          'status': 'in_progress',
          'priority': 'high',
          'related_load_id': 'load-9',
          'related_trip_id': 'trip-4',
          'resolution_summary': '',
          'created_at': '2026-03-11T08:00:00.000Z',
          'updated_at': '2026-03-11T08:30:00.000Z',
          'resolved_at': null,
        },
      }
      ..supportMessagesByTicketId = {
        'ticket-1': [
          {
            'id': 'msg-1',
            'sender_profile_id': 'user-1',
            'sender_admin_user_id': null,
            'message_body': 'Need payout help',
            'attachment_path': '',
            'visibility_class': 'visible',
            'created_at': '2026-03-11T08:05:00.000Z',
          },
          {
            'id': 'msg-2',
            'sender_profile_id': null,
            'sender_admin_user_id': 'admin-1',
            'message_body': 'We are reviewing this now',
            'attachment_path': '',
            'visibility_class': 'visible',
            'created_at': '2026-03-11T08:10:00.000Z',
          },
        ],
      }
      ..profilesById = {
        'user-1': {
          'id': 'user-1',
          'full_name': 'Supplier One',
          'mobile': '9999999999',
          'email': 'supplier@example.com',
          'user_role_type': 'supplier',
          'verification_status': 'approved',
          'is_banned': false,
          'created_at': '2026-02-01T08:00:00.000Z',
          'last_login_at': '2026-03-11T07:55:00.000Z',
        },
      }
      ..adminUsersById = {
        'admin-1': {
          'id': 'admin-1',
          'full_name': 'Ops One',
          'role': 'ops_admin',
        },
      };

    final container = ProviderContainer(overrides: [adminSupportBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminSupportRepositoryProvider);
    final detail = await repository.getSupportTicketDetail('ticket-1');
    final ok = await repository.replyToSupportTicket(ticketId: 'ticket-1', messageBody: 'We are reviewing this now');

    expect(detail, isNotNull);
    expect(detail!.messages, hasLength(2));
    expect(detail.messages.first.senderLabel, 'Supplier One');
    expect(detail.messages.last.senderLabel, 'Ops One (ops_admin)');
    expect(detail.ticket.relatedLoadId, 'load-9');
    expect(detail.ticket.relatedTripId, 'trip-4');
    expect(detail.ticket.ownerRole, 'supplier');
    expect(ok, isTrue);
    expect(backend.lastReplyTicketId, 'ticket-1');
    expect(backend.lastReplyMessage, 'We are reviewing this now');
  });
}
