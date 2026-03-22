import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/features/support/presentation/admin_support_ticket_detail_screen.dart';
import 'package:admin/src/features/support/providers/admin_support_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminSupportReplyController extends AdminSupportReplyController {
  bool called = false;
  String? lastTicketId;
  String? lastMessage;

  @override
  Future<bool> replyToTicket({required String ticketId, required String messageBody}) async {
    called = true;
    lastTicketId = ticketId;
    lastMessage = messageBody;
    return true;
  }
}

void main() {
  testWidgets('support ticket detail renders summary, messages, and reply action', (tester) async {
    late _FakeAdminSupportReplyController replyController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminSupportTicketDetailProvider('ticket-1').overrideWith((ref) async {
            return AdminSupportTicketDetail(
              ticket: const AdminSupportTicketItem(
                id: 'ticket-1',
                ownerProfileId: 'user-1',
                ownerName: 'Supplier One',
                ownerContact: '9999999999 • supplier@example.com',
                ownerRole: 'supplier',
                ownerVerificationStatus: 'approved',
                ownerIsBanned: false,
                ownerCreatedAt: null,
                ownerLastLoginAt: null,
                category: 'payment',
                status: 'in_progress',
                priority: 'high',
                relatedLoadId: 'load-1',
                relatedTripId: 'trip-1',
                resolutionSummary: '',
                createdAt: null,
                updatedAt: null,
                resolvedAt: null,
              ),
              messages: [
                AdminSupportTicketMessage(
                  id: 'msg-1',
                  senderLabel: 'Supplier One',
                  messageBody: 'Need payout help',
                  attachmentPath: 'ticket-1/screenshot.png',
                  visibilityClass: 'visible',
                  createdAt: DateTime(2026, 3, 12, 19, 20),
                ),
                AdminSupportTicketMessage(
                  id: 'msg-2',
                  senderLabel: 'Ops One (ops_admin)',
                  messageBody: 'We are reviewing this now',
                  attachmentPath: '',
                  visibilityClass: 'visible',
                  createdAt: DateTime(2026, 3, 12, 19, 25),
                ),
              ],
            );
          }),
          adminSupportReplyProvider.overrideWith(() {
            replyController = _FakeAdminSupportReplyController();
            return replyController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AdminSupportTicketDetailScreen(ticketId: 'ticket-1'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ticket-1'), findsWidgets);
    expect(find.text('Ticket summary'), findsOneWidget);
    expect(find.text('Payment'), findsWidgets);
    expect(find.text('In Progress'), findsWidgets);
    expect(find.text('High'), findsWidgets);
    expect(find.text('User profile preview'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-owner-profile-button')), findsOneWidget);

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-related-load-button')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Linked context'), findsOneWidget);
    expect(find.byKey(const ValueKey('support-related-load-button')), findsOneWidget);
    expect(find.textContaining('dedicated admin trip-detail route is not available'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Current support contract'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Current support contract'), findsOneWidget);
    expect(find.textContaining('Visible admin replies are live on this ticket'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Reply to ticket'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Conversation'), findsOneWidget);
    expect(find.text('Reply to ticket'), findsOneWidget);
    expect(find.text('Need payout help'), findsOneWidget);
    expect(find.text('Ops One (ops_admin)'), findsOneWidget);
    expect(find.text('We are reviewing this now'), findsOneWidget);
    expect(find.text('Message msg-1'), findsOneWidget);
    expect(find.text('Message msg-2'), findsOneWidget);
    expect(find.text('Attachment ticket-1/screenshot.png'), findsOneWidget);
    expect(find.text('Visibility Visible'), findsNWidgets(2));
    expect(find.text('Created 2026-03-12 19:20'), findsWidgets);
    expect(find.text('Created 2026-03-12 19:25'), findsWidgets);
    expect(find.byKey(const ValueKey('support-canned-response-dropdown')), findsOneWidget);
    expect(find.textContaining('Canned responses only prefill the visible reply text below'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-reply-button')),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('support-reply-button')));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least 2 characters before sending a support reply.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('support-canned-response-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escalated to operations team').last);
    await tester.pumpAndSettle();

    expect(find.text('Escalated to operations team'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('support-reply-button')));
    await tester.pumpAndSettle();

    expect(replyController.called, isTrue);
    expect(replyController.lastTicketId, 'ticket-1');
    expect(replyController.lastMessage, 'Escalated to operations team');
  });

  testWidgets('support ticket detail routes to owner profile and related load', (tester) async {
    final router = GoRouter(
      initialLocation: AdminRoutes.supportDetailPathFor('ticket-1'),
      routes: [
        GoRoute(
          path: AdminRoutes.supportDetailPath,
          builder: (context, state) => Scaffold(
            body: AdminSupportTicketDetailScreen(ticketId: state.pathParameters['ticketId']!),
          ),
        ),
        GoRoute(
          path: AdminRoutes.userDetailPath,
          builder: (context, state) => Scaffold(body: Text('User detail opened: ${state.pathParameters['userId']}')),
        ),
        GoRoute(
          path: AdminRoutes.loadDetailPath,
          builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminSupportTicketDetailProvider('ticket-1').overrideWith((ref) async {
            return AdminSupportTicketDetail(
              ticket: const AdminSupportTicketItem(
                id: 'ticket-1',
                ownerProfileId: 'user-1',
                ownerName: 'Supplier One',
                ownerContact: '9999999999 • supplier@example.com',
                ownerRole: 'supplier',
                ownerVerificationStatus: 'approved',
                ownerIsBanned: false,
                ownerCreatedAt: null,
                ownerLastLoginAt: null,
                category: 'payment',
                status: 'in_progress',
                priority: 'high',
                relatedLoadId: 'load-1',
                relatedTripId: 'trip-1',
                resolutionSummary: '',
                createdAt: null,
                updatedAt: null,
                resolvedAt: null,
              ),
              messages: const <AdminSupportTicketMessage>[],
            );
          }),
          adminSupportReplyProvider.overrideWith(() => _FakeAdminSupportReplyController()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-owner-profile-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('support-owner-profile-button')));
    await tester.pumpAndSettle();
    expect(find.text('User detail opened: user-1'), findsOneWidget);

    router.go(AdminRoutes.supportDetailPathFor('ticket-1'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('support-related-load-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('support-related-load-button')));
    await tester.pumpAndSettle();
    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });
}
