import 'package:admin/src/core/repositories/admin_support_repository.dart';
import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/features/support/presentation/admin_support_queue_screen.dart';
import 'package:admin/src/features/support/providers/admin_support_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminSupportQueueController extends AdminSupportQueueController {
  final AdminSupportQueueState initialState;

  _FakeAdminSupportQueueController(this.initialState);

  @override
  Future<AdminSupportQueueState> build() async => initialState;
}

void main() {
  testWidgets('support queue screen renders counts and rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminSupportQueueProvider.overrideWith(
            () => _FakeAdminSupportQueueController(
              AdminSupportQueueState.initial().copyWith(
                counts: const SupportQueueCounts(open: 1, inProgress: 2, resolved: 3),
                items: [
                  AdminSupportTicketItem(
                    id: 'ticket-1',
                    ownerProfileId: 'user-1',
                    ownerName: 'Supplier One',
                    ownerContact: '9999999999 • supplier@example.com',
                    ownerRole: 'supplier',
                    ownerVerificationStatus: 'approved',
                    ownerIsBanned: false,
                    ownerCreatedAt: DateTime(2026, 3, 1, 9, 30),
                    ownerLastLoginAt: DateTime(2026, 3, 12, 18, 45),
                    category: 'payment',
                    status: 'open',
                    priority: 'high',
                    relatedLoadId: 'load-1',
                    relatedTripId: 'trip-1',
                    resolutionSummary: 'Refund approved',
                    createdAt: DateTime(2026, 3, 10, 8, 15),
                    updatedAt: DateTime(2026, 3, 12, 19, 20),
                    resolvedAt: null,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminSupportQueueScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Support queue'), findsOneWidget);
    expect(find.text('Current queue contract'), findsOneWidget);
    expect(find.textContaining('Assign-to-me, status changes, priority changes, and resolve actions remain intentionally unavailable'), findsOneWidget);
    expect(find.text('Ticket id, owner/user id, role/state, load/trip id, category, status, priority, or resolution'), findsOneWidget);
    expect(find.text('Open (1)'), findsOneWidget);
    expect(find.text('In Progress (2)'), findsOneWidget);
    expect(find.text('Resolved (3)'), findsOneWidget);
    expect(find.text('Supplier One • ticket-1'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Ticket ticket-1'), findsOneWidget);
    expect(find.text('User user-1'), findsOneWidget);
    expect(find.text('Load load-1'), findsOneWidget);
    expect(find.text('Trip trip-1'), findsOneWidget);
    expect(find.text('Supplier • Approved • Active'), findsOneWidget);
    expect(find.text('Resolution Refund approved'), findsOneWidget);
    expect(find.text('Opened 2026-03-10 08:15 • Updated 2026-03-12 19:20'), findsOneWidget);
    expect(find.text('Owner joined 2026-03-01 09:30 • Last login 2026-03-12 18:45'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-support-open-owner-ticket-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-support-open-load-ticket-1')), findsOneWidget);
  });

  testWidgets('support queue routes to ticket detail, owner detail, and load detail', (tester) async {
    final state = AdminSupportQueueState.initial().copyWith(
      counts: const SupportQueueCounts(open: 1, inProgress: 0, resolved: 0),
      items: [
        AdminSupportTicketItem(
          id: 'ticket-1',
          ownerProfileId: 'user-1',
          ownerName: 'Supplier One',
          ownerContact: '9999999999 • supplier@example.com',
          ownerRole: 'supplier',
          ownerVerificationStatus: 'approved',
          ownerIsBanned: false,
          ownerCreatedAt: DateTime(2026, 3, 1, 9, 30),
          ownerLastLoginAt: DateTime(2026, 3, 12, 18, 45),
          category: 'payment',
          status: 'open',
          priority: 'high',
          relatedLoadId: 'load-1',
          relatedTripId: 'trip-1',
          resolutionSummary: '',
          createdAt: DateTime(2026, 3, 10, 8, 15),
          updatedAt: DateTime(2026, 3, 12, 19, 20),
          resolvedAt: null,
        ),
      ],
    );

    final router = GoRouter(
      initialLocation: AdminRoutes.supportPath,
      routes: [
        GoRoute(
          path: AdminRoutes.supportPath,
          builder: (context, state) => const AdminSupportQueueScreen(),
        ),
        GoRoute(
          path: AdminRoutes.supportDetailPath,
          builder: (context, state) => Scaffold(body: Text('Support detail opened: ${state.pathParameters['ticketId']}')),
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
          adminSupportQueueProvider.overrideWith(
            () => _FakeAdminSupportQueueController(state),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-support-open-owner-ticket-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-support-open-owner-ticket-1')));
    await tester.pumpAndSettle();
    expect(find.text('User detail opened: user-1'), findsOneWidget);

    router.go(AdminRoutes.supportPath);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-support-open-load-ticket-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-support-open-load-ticket-1')));
    await tester.pumpAndSettle();
    expect(find.text('Load detail opened: load-1'), findsOneWidget);

    router.go(AdminRoutes.supportPath);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-support-queue-item-ticket-1')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin-support-queue-item-ticket-1')));
    await tester.pumpAndSettle();
    expect(find.text('Support detail opened: ticket-1'), findsOneWidget);
  });
}
