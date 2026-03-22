import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/repositories/admin_operational_case_repository.dart';
import 'package:admin/src/features/super_ops/presentation/admin_operational_case_detail_screen.dart';
import 'package:admin/src/features/super_ops/providers/admin_operational_case_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminOperationalCaseActionController extends AdminOperationalCaseActionController {
  String? lastClaimCaseId;
  String? lastReleaseCaseId;
  OperationalCaseTransitionTarget? lastTransitionTarget;
  OperationalCaseResolutionTarget? lastResolutionTarget;
  String? lastSummary;
  String? lastInternalNote;
  String? lastResolutionSummary;
  String? lastEscalationTargetId;
  String? lastEscalationReason;

  @override
  Future<bool> claimCase(String caseId) async {
    lastClaimCaseId = caseId;
    return true;
  }

  @override
  Future<bool> releaseCase(String caseId) async {
    lastReleaseCaseId = caseId;
    return true;
  }

  @override
  Future<bool> transitionCase({
    required String caseId,
    required OperationalCaseTransitionTarget target,
    String? summary,
    String? internalNote,
  }) async {
    lastTransitionTarget = target;
    lastSummary = summary;
    lastInternalNote = internalNote;
    return true;
  }

  @override
  Future<bool> resolveCase({
    required String caseId,
    required OperationalCaseResolutionTarget target,
    required String summary,
  }) async {
    lastResolutionTarget = target;
    lastResolutionSummary = summary;
    return true;
  }

  @override
  Future<bool> escalateCase({
    required String caseId,
    required String targetAdminUserId,
    String? reason,
  }) async {
    lastEscalationTargetId = targetAdminUserId;
    lastEscalationReason = reason;
    return true;
  }
}

Widget _buildRoutedDetailApp({
  required String caseId,
  required AdminOperationalCaseDetail detail,
  required AdminOperationalCaseActionController actionController,
  List<AdminOperationalEscalationTarget> escalationTargets = const <AdminOperationalEscalationTarget>[],
}) {
  final router = GoRouter(
    initialLocation: '/ops-case/$caseId',
    routes: [
      GoRoute(
        path: '/ops-case/:caseId',
        builder: (context, state) => Scaffold(
          body: AdminOperationalCaseDetailScreen(caseId: state.pathParameters['caseId']!),
        ),
      ),
      GoRoute(
        path: AdminRoutes.loadDetailPath,
        builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
      ),
      GoRoute(
        path: AdminRoutes.userDetailPath,
        builder: (context, state) => Scaffold(body: Text('User detail opened: ${state.pathParameters['userId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminOperationalCaseDetailProvider(caseId).overrideWith((ref) async => detail),
      adminOperationalEscalationTargetsProvider.overrideWith((ref) async => escalationTargets),
      adminOperationalCaseActionProvider.overrideWith(() => actionController),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('operational case detail renders timeline and lifecycle actions', (tester) async {
    late _FakeAdminOperationalCaseActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminOperationalCaseDetailProvider('case-1').overrideWith((ref) async {
            return AdminOperationalCaseDetail(
              item: AdminOperationalCaseItem(
                id: 'case-1',
                caseType: 'trip_dispute',
                primaryObjectType: 'trip',
                primaryObjectId: 'trip-1',
                queueClassification: 'dispute',
                status: 'claimed',
                claimedByAdminUserId: 'admin-1',
                claimedByLabel: 'Ops One',
                escalatedToAdminUserId: 'admin-super-1',
                escalatedToLabel: 'Super Admin One',
                businessLabel: 'Trip trip-1 • Mumbai → Pune • Steel',
                waitingReason: 'Awaiting clearer POD proof',
                resolutionSummary: 'Dispute settled after proof review',
                createdAt: DateTime(2026, 3, 12, 18, 15),
                updatedAt: DateTime(2026, 3, 12, 20, 45),
                resolvedAt: DateTime(2026, 3, 13, 9, 5),
              ),
              contextMetadata: const {
                'Case type': 'Trip Dispute',
                'Status': 'Claimed',
                'Business object': 'Trip trip-1 • Mumbai → Pune • Steel',
              },
              linkedObjectMetadata: const {
                'Trip id': 'trip-1',
                'Trip stage': 'Proof Submitted',
                'Load id': 'load-1',
                'Route': 'Mumbai → Pune',
                'Supplier id': 's1',
                'Supplier': 'Supplier One (s1)',
                'Trucker id': 't1',
                'Trucker': 'Trucker One (t1)',
              },
              events: [
                AdminOperationalCaseEvent(
                  id: 'event-1',
                  eventType: 'case_claimed',
                  summary: 'Operational case claimed',
                  internalNote: 'Case moved into active dispute review.',
                  createdAt: DateTime(2026, 3, 12, 19, 10),
                ),
              ],
            );
          }),
          adminOperationalEscalationTargetsProvider.overrideWith((ref) async {
            return const [
              AdminOperationalEscalationTarget(
                id: 'admin-super-1',
                name: 'Super Admin One',
                role: 'super_admin',
              ),
            ];
          }),
          adminOperationalCaseActionProvider.overrideWith(() {
            actionController = _FakeAdminOperationalCaseActionController();
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminOperationalCaseDetailScreen(caseId: 'case-1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Trip trip-1 • Mumbai → Pune • Steel'), findsAtLeastNWidgets(1));
    expect(find.text('case-1'), findsOneWidget);
    expect(find.text('Dispute'), findsWidgets);
    expect(find.text('trip • trip-1'), findsOneWidget);
    expect(find.text('Awaiting clearer POD proof'), findsOneWidget);
    expect(find.text('Dispute settled after proof review'), findsOneWidget);
    expect(find.text('2026-03-12 18:15'), findsOneWidget);
    expect(find.text('2026-03-12 20:45'), findsOneWidget);
    expect(find.text('2026-03-13 09:05'), findsOneWidget);
    expect(find.text('Claimed'), findsWidgets);
    expect(find.text('Ops One • admin-1'), findsOneWidget);
    expect(find.text('Super Admin One • admin-super-1'), findsOneWidget);
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Linked object context'),
      250,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Linked object context'), findsOneWidget);
    expect(find.text('Proof Submitted'), findsOneWidget);
    expect(find.textContaining('dedicated admin trip-detail route is not available'), findsOneWidget);
    expect(find.byKey(const ValueKey('ops-open-related-load-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('ops-open-supplier-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('ops-open-trucker-button')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Timeline'),
      250,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Operational case claimed'), findsOneWidget);
    expect(find.text('Event event-1'), findsOneWidget);
    expect(find.text('Created 2026-03-12 19:10'), findsOneWidget);
    expect(find.text('Internal note Case moved into active dispute review.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Current lifecycle contract'),
      250,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Current lifecycle contract'), findsOneWidget);
    expect(find.textContaining('Claim, release, waiting transitions, review transitions'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Lifecycle actions'),
      250,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Lifecycle actions'), findsOneWidget);
    expect(find.byKey(const ValueKey('ops-release-button')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ops-release-button')));
    await tester.pumpAndSettle();
    expect(actionController.lastReleaseCaseId, 'case-1');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-transition-user-button')),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    final transitionButton = tester.widget<OutlinedButton>(find.byKey(const ValueKey('ops-transition-user-button')));
    transitionButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.text('Enter a summary or internal note before moving this case into a waiting state.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('ops-summary-field')), 'Need more proof');
    await tester.enterText(find.byKey(const ValueKey('ops-note-field')), 'Ask for clearer POD image');
    transitionButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(actionController.lastTransitionTarget, OperationalCaseTransitionTarget.waitingForUser);
    expect(actionController.lastInternalNote, 'Ask for clearer POD image');

    await tester.tap(find.byKey(const ValueKey('ops-resolve-button')));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least 5 characters before resolving or rejecting a case.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('ops-resolution-field')), 'Dispute settled');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-resolve-button')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ops-resolve-button')));
    await tester.pumpAndSettle();

    expect(actionController.lastResolutionTarget, OperationalCaseResolutionTarget.resolved);
    expect(actionController.lastResolutionSummary, 'Dispute settled');

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-escalation-target-field')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('ops-escalation-reason-field')), 'Needs super admin review');
    final escalateButton = tester.widget<FilledButton>(find.byKey(const ValueKey('ops-escalate-button')));
    escalateButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(actionController.lastEscalationTargetId, 'admin-super-1');
    expect(actionController.lastEscalationReason, 'Needs super admin review');
  });

  testWidgets('operational case detail exposes close action for resolved cases', (tester) async {
    late _FakeAdminOperationalCaseActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminOperationalCaseDetailProvider('case-2').overrideWith((ref) async {
            return AdminOperationalCaseDetail(
              item: AdminOperationalCaseItem(
                id: 'case-2',
                caseType: 'trip_dispute',
                primaryObjectType: 'trip',
                primaryObjectId: 'trip-2',
                queueClassification: 'dispute',
                status: 'resolved',
                claimedByAdminUserId: 'admin-1',
                claimedByLabel: 'Ops One',
                escalatedToAdminUserId: '',
                escalatedToLabel: '',
                businessLabel: 'Trip trip-2 • Delhi → Jaipur • Cement',
                waitingReason: '',
                resolutionSummary: 'Closed after payout confirmation',
                createdAt: DateTime(2026, 3, 12, 18, 15),
                updatedAt: DateTime(2026, 3, 12, 20, 45),
                resolvedAt: DateTime(2026, 3, 13, 9, 5),
              ),
              contextMetadata: const {'Case type': 'Trip Dispute'},
              linkedObjectMetadata: const {'Trip id': 'trip-2'},
              events: const [],
            );
          }),
          adminOperationalEscalationTargetsProvider.overrideWith((ref) async => const []),
          adminOperationalCaseActionProvider.overrideWith(() {
            actionController = _FakeAdminOperationalCaseActionController();
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminOperationalCaseDetailScreen(caseId: 'case-2')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-transition-close-button')),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ops-transition-close-button')));
    await tester.pumpAndSettle();

    expect(actionController.lastTransitionTarget, OperationalCaseTransitionTarget.closed);
  });

  testWidgets('operational case detail routes to related load', (tester) async {
    await tester.pumpWidget(
      _buildRoutedDetailApp(
        caseId: 'case-1',
        detail: AdminOperationalCaseDetail(
          item: AdminOperationalCaseItem(
            id: 'case-1',
            caseType: 'trip_dispute',
            primaryObjectType: 'trip',
            primaryObjectId: 'trip-1',
            queueClassification: 'dispute',
            status: 'claimed',
            claimedByAdminUserId: 'admin-1',
            claimedByLabel: 'Ops One',
            escalatedToAdminUserId: '',
            escalatedToLabel: '',
            businessLabel: 'Trip trip-1 • Mumbai → Pune • Steel',
            waitingReason: '',
            resolutionSummary: '',
            createdAt: DateTime(2026, 3, 12, 18, 15),
            updatedAt: DateTime(2026, 3, 12, 20, 45),
            resolvedAt: null,
          ),
          contextMetadata: const {'Status': 'Claimed'},
          linkedObjectMetadata: const {
            'Trip id': 'trip-1',
            'Load id': 'load-1',
            'Supplier id': 's1',
            'Trucker id': 't1',
          },
          events: const [],
        ),
        actionController: _FakeAdminOperationalCaseActionController(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-open-related-load-button')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ops-open-related-load-button')));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('operational case detail routes to supplier profile', (tester) async {
    await tester.pumpWidget(
      _buildRoutedDetailApp(
        caseId: 'case-1',
        detail: AdminOperationalCaseDetail(
          item: AdminOperationalCaseItem(
            id: 'case-1',
            caseType: 'trip_dispute',
            primaryObjectType: 'trip',
            primaryObjectId: 'trip-1',
            queueClassification: 'dispute',
            status: 'claimed',
            claimedByAdminUserId: 'admin-1',
            claimedByLabel: 'Ops One',
            escalatedToAdminUserId: '',
            escalatedToLabel: '',
            businessLabel: 'Trip trip-1 • Mumbai → Pune • Steel',
            waitingReason: '',
            resolutionSummary: '',
            createdAt: DateTime(2026, 3, 12, 18, 15),
            updatedAt: DateTime(2026, 3, 12, 20, 45),
            resolvedAt: null,
          ),
          contextMetadata: const {'Status': 'Claimed'},
          linkedObjectMetadata: const {
            'Trip id': 'trip-1',
            'Load id': 'load-1',
            'Supplier id': 's1',
            'Trucker id': 't1',
          },
          events: const [],
        ),
        actionController: _FakeAdminOperationalCaseActionController(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-open-supplier-button')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ops-open-supplier-button')));
    await tester.pumpAndSettle();

    expect(find.text('User detail opened: s1'), findsOneWidget);
  });

  testWidgets('operational case detail routes to trucker profile', (tester) async {
    await tester.pumpWidget(
      _buildRoutedDetailApp(
        caseId: 'case-1',
        detail: AdminOperationalCaseDetail(
          item: AdminOperationalCaseItem(
            id: 'case-1',
            caseType: 'trip_dispute',
            primaryObjectType: 'trip',
            primaryObjectId: 'trip-1',
            queueClassification: 'dispute',
            status: 'claimed',
            claimedByAdminUserId: 'admin-1',
            claimedByLabel: 'Ops One',
            escalatedToAdminUserId: '',
            escalatedToLabel: '',
            businessLabel: 'Trip trip-1 • Mumbai → Pune • Steel',
            waitingReason: '',
            resolutionSummary: '',
            createdAt: DateTime(2026, 3, 12, 18, 15),
            updatedAt: DateTime(2026, 3, 12, 20, 45),
            resolvedAt: null,
          ),
          contextMetadata: const {'Status': 'Claimed'},
          linkedObjectMetadata: const {
            'Trip id': 'trip-1',
            'Load id': 'load-1',
            'Supplier id': 's1',
            'Trucker id': 't1',
          },
          events: const [],
        ),
        actionController: _FakeAdminOperationalCaseActionController(),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-open-trucker-button')),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ops-open-trucker-button')));
    await tester.pumpAndSettle();

    expect(find.text('User detail opened: t1'), findsOneWidget);
  });

  testWidgets('operational case detail exposes claim action for unclaimed cases', (tester) async {
    late _FakeAdminOperationalCaseActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminOperationalCaseDetailProvider('case-3').overrideWith((ref) async {
            return AdminOperationalCaseDetail(
              item: AdminOperationalCaseItem(
                id: 'case-3',
                caseType: 'trip_dispute',
                primaryObjectType: 'trip',
                primaryObjectId: 'trip-3',
                queueClassification: 'dispute',
                status: 'queued',
                claimedByAdminUserId: '',
                claimedByLabel: '',
                escalatedToAdminUserId: '',
                escalatedToLabel: '',
                businessLabel: 'Trip trip-3 • Nagpur → Bhopal • Coal',
                waitingReason: '',
                resolutionSummary: '',
                createdAt: DateTime(2026, 3, 12, 18, 15),
                updatedAt: DateTime(2026, 3, 12, 20, 45),
                resolvedAt: null,
              ),
              contextMetadata: const {'Case type': 'Trip Dispute'},
              linkedObjectMetadata: const {'Trip id': 'trip-3'},
              events: const [],
            );
          }),
          adminOperationalEscalationTargetsProvider.overrideWith((ref) async => const []),
          adminOperationalCaseActionProvider.overrideWith(() {
            actionController = _FakeAdminOperationalCaseActionController();
            return actionController;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(body: AdminOperationalCaseDetailScreen(caseId: 'case-3')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('ops-claim-button')),
      300,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ops-claim-button')));
    await tester.pumpAndSettle();

    expect(actionController.lastClaimCaseId, 'case-3');
  });
}
