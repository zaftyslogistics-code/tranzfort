import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/repositories/admin_operational_case_repository.dart';
import 'package:admin/src/features/super_ops/presentation/admin_operational_case_queue_screen.dart';
import 'package:admin/src/features/super_ops/providers/admin_operational_case_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminOperationalCaseQueueController extends AdminOperationalCaseQueueController {
  final AdminOperationalCaseQueueState initialState;

  _FakeAdminOperationalCaseQueueController(this.initialState);

  @override
  Future<AdminOperationalCaseQueueState> build() async => initialState;
}

class _FakeAdminOperationalCaseActionController extends AdminOperationalCaseActionController {
  bool claimCalled = false;
  bool releaseCalled = false;
  String? lastCaseId;

  @override
  Future<bool> claimCase(String caseId) async {
    claimCalled = true;
    lastCaseId = caseId;
    return true;
  }

  @override
  Future<bool> releaseCase(String caseId) async {
    releaseCalled = true;
    lastCaseId = caseId;
    return true;
  }
}

Widget _buildRoutedQueueApp({
  required AdminOperationalCaseQueueState state,
  required AdminOperationalCaseActionController actionController,
}) {
  final router = GoRouter(
    initialLocation: '/ops-queue',
    routes: [
      GoRoute(
        path: '/ops-queue',
        builder: (context, state) => const Material(child: AdminOperationalCaseQueueScreen()),
      ),
      GoRoute(
        path: AdminRoutes.operationalCaseDetailPath,
        builder: (context, state) => Scaffold(body: Text('Operational case opened: ${state.pathParameters['caseId']}')),
      ),
      GoRoute(
        path: AdminRoutes.loadDetailPath,
        builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminOperationalCaseQueueProvider.overrideWith(() => _FakeAdminOperationalCaseQueueController(state)),
      adminOperationalCaseActionProvider.overrideWith(() => actionController),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('operational case queue screen renders rows and claim action', (tester) async {
    late _FakeAdminOperationalCaseActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminOperationalCaseQueueProvider.overrideWith(
            () => _FakeAdminOperationalCaseQueueController(
              AdminOperationalCaseQueueState.initial().copyWith(
                counts: const OperationalCaseCounts(queued: 1, claimed: 0, inReview: 0, waiting: 0, escalated: 0, closed: 1),
                items: [
                  AdminOperationalCaseItem(
                    id: 'case-1',
                    caseType: 'load_dispute',
                    primaryObjectType: 'load',
                    primaryObjectId: 'load-1',
                    queueClassification: 'dispute',
                    status: 'queued',
                    claimedByAdminUserId: '',
                    claimedByLabel: '',
                    escalatedToAdminUserId: '',
                    escalatedToLabel: '',
                    businessLabel: 'Load load-1 • Mumbai → Pune • Steel',
                    waitingReason: '',
                    resolutionSummary: '',
                    createdAt: DateTime(2026, 3, 12, 18, 5),
                    updatedAt: DateTime(2026, 3, 12, 20, 25),
                    resolvedAt: null,
                  ),
                  AdminOperationalCaseItem(
                    id: 'case-2',
                    caseType: 'trip_dispute',
                    primaryObjectType: 'trip',
                    primaryObjectId: 'trip-2',
                    queueClassification: 'dispute',
                    status: 'escalated',
                    claimedByAdminUserId: 'admin-1',
                    claimedByLabel: 'Ops One',
                    escalatedToAdminUserId: 'admin-super-1',
                    escalatedToLabel: 'Super Admin One',
                    businessLabel: 'Trip trip-2 • Delhi → Jaipur • Cement',
                    waitingReason: '',
                    resolutionSummary: 'Awaiting final super-admin review',
                    createdAt: DateTime(2026, 3, 11, 10, 0),
                    updatedAt: DateTime(2026, 3, 12, 21, 0),
                    resolvedAt: null,
                  ),
                ],
              ),
            ),
          ),
          adminOperationalCaseActionProvider.overrideWith(() {
            actionController = _FakeAdminOperationalCaseActionController();
            return actionController;
          }),
        ],
        child: const MaterialApp(home: AdminOperationalCaseQueueScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Operational case queue'), findsOneWidget);
    expect(find.text('Case id, type, queue, business object, waiting/resolution, or admin'), findsOneWidget);
    expect(find.text('Queued (1)'), findsOneWidget);
    expect(find.text('Closed (1)'), findsOneWidget);
    expect(find.text('Load load-1 • Mumbai → Pune • Steel'), findsOneWidget);
    expect(find.text('Queue Dispute'), findsWidgets);
    expect(find.text('Case case-1'), findsOneWidget);
    expect(find.text('Load load-1'), findsOneWidget);
    expect(find.text('Created 2026-03-12 18:05 • Updated 2026-03-12 20:25'), findsOneWidget);
    expect(find.byKey(const ValueKey('ops-queue-open-load-case-1')), findsOneWidget);
    expect(find.text('Trip trip-2 • Delhi → Jaipur • Cement'), findsOneWidget);
    expect(find.text('Escalated to Super Admin One'), findsOneWidget);
    expect(find.text('Claimed admin Ops One • admin-1'), findsOneWidget);
    expect(find.text('Escalated admin Super Admin One • admin-super-1'), findsOneWidget);
    expect(find.text('Resolution Awaiting final super-admin review'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('claim-case-1')));
    await tester.pumpAndSettle();

    expect(actionController.claimCalled, isTrue);
    expect(actionController.lastCaseId, 'case-1');
  });

  testWidgets('operational case queue routes to case detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedQueueApp(
        state: AdminOperationalCaseQueueState.initial().copyWith(
          counts: const OperationalCaseCounts(queued: 1, claimed: 0, inReview: 0, waiting: 0, escalated: 0, closed: 0),
          items: [
            AdminOperationalCaseItem(
              id: 'case-1',
              caseType: 'load_dispute',
              primaryObjectType: 'load',
              primaryObjectId: 'load-1',
              queueClassification: 'dispute',
              status: 'queued',
              claimedByAdminUserId: '',
              claimedByLabel: '',
              escalatedToAdminUserId: '',
              escalatedToLabel: '',
              businessLabel: 'Load load-1 • Mumbai → Pune • Steel',
              waitingReason: '',
              resolutionSummary: '',
              createdAt: DateTime(2026, 3, 12, 18, 5),
              updatedAt: DateTime(2026, 3, 12, 20, 25),
              resolvedAt: null,
            ),
          ],
        ),
        actionController: _FakeAdminOperationalCaseActionController(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Load load-1 • Mumbai → Pune • Steel'));
    await tester.pumpAndSettle();

    expect(find.text('Operational case opened: case-1'), findsOneWidget);
  });

  testWidgets('operational case queue routes to related load detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedQueueApp(
        state: AdminOperationalCaseQueueState.initial().copyWith(
          counts: const OperationalCaseCounts(queued: 1, claimed: 0, inReview: 0, waiting: 0, escalated: 0, closed: 0),
          items: [
            AdminOperationalCaseItem(
              id: 'case-1',
              caseType: 'load_dispute',
              primaryObjectType: 'load',
              primaryObjectId: 'load-1',
              queueClassification: 'dispute',
              status: 'queued',
              claimedByAdminUserId: '',
              claimedByLabel: '',
              escalatedToAdminUserId: '',
              escalatedToLabel: '',
              businessLabel: 'Load load-1 • Mumbai → Pune • Steel',
              waitingReason: '',
              resolutionSummary: '',
              createdAt: DateTime(2026, 3, 12, 18, 5),
              updatedAt: DateTime(2026, 3, 12, 20, 25),
              resolvedAt: null,
            ),
          ],
        ),
        actionController: _FakeAdminOperationalCaseActionController(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ops-queue-open-load-case-1')));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });
}
