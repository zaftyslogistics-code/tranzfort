import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/repositories/admin_verification_repository.dart';
import 'package:admin/src/features/verification/presentation/admin_verification_queue_screen.dart';
import 'package:admin/src/features/verification/providers/admin_verification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminVerificationQueueController extends AdminVerificationQueueController {
  final AdminVerificationQueueState initialState;

  _FakeAdminVerificationQueueController(this.initialState);

  @override
  Future<AdminVerificationQueueState> build() async => initialState;
}

Widget _buildRoutedQueueApp({required AdminVerificationQueueState state}) {
  final router = GoRouter(
    initialLocation: AdminRoutes.verificationPath,
    routes: [
      GoRoute(
        path: AdminRoutes.verificationPath,
        builder: (context, state) => const Scaffold(body: AdminVerificationQueueScreen()),
      ),
      GoRoute(
        path: AdminRoutes.verificationDetailPath,
        builder: (context, state) => Scaffold(body: Text('Verification detail opened: ${state.pathParameters['caseId']}')),
      ),
      GoRoute(
        path: AdminRoutes.userDetailPath,
        builder: (context, state) => Scaffold(body: Text('User detail opened: ${state.pathParameters['userId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminVerificationQueueProvider.overrideWith(() => _FakeAdminVerificationQueueController(state)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('verification queue screen renders tabs and mapped cases', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminVerificationQueueProvider.overrideWith(
            () => _FakeAdminVerificationQueueController(
              AdminVerificationQueueState.initial().copyWith(
                counts: const VerificationQueueCounts(
                  suppliers: 1,
                  truckers: 2,
                  trucks: 3,
                ),
                items: [
                  VerificationQueueItem(
                    caseId: 'case-1',
                    subjectId: 'user-1',
                    subjectType: 'supplier_profile',
                    displayName: 'S1 Logistics',
                    secondaryLabel: 'supplier@example.com',
                    contactLabel: '9999999999',
                    profileLinkId: 'user-1',
                    profileLinkLabel: 'Open subject profile',
                    caseStatus: 'submitted',
                    submittedAt: DateTime(2026, 3, 12, 21, 10),
                    slaLabel: '12h left',
                    slaPriority: 1,
                    isClaimed: false,
                    assignedAdminUserId: '',
                    assignedAdminLabel: '',
                  ),
                  VerificationQueueItem(
                    caseId: 'case-2',
                    subjectId: 'truck-1',
                    subjectType: 'truck',
                    displayName: 'MH12AB1234',
                    secondaryLabel: 'Open body',
                    contactLabel: 'Trucker One • 8888888888',
                    profileLinkId: 'trucker-1',
                    profileLinkLabel: 'Open owner profile',
                    caseStatus: 'waiting_for_review',
                    submittedAt: DateTime(2026, 3, 12, 22, 0),
                    slaLabel: '11h left',
                    slaPriority: 1,
                    isClaimed: true,
                    assignedAdminUserId: 'admin-1',
                    assignedAdminLabel: 'Ops One (ops_admin)',
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminVerificationQueueScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Verification queue'), findsOneWidget);
    expect(find.text('Case id, subject id/type, name, contact, status, or assigned admin'), findsOneWidget);
    expect(find.text('Suppliers (1)'), findsOneWidget);
    expect(find.text('Truckers (2)'), findsOneWidget);
    expect(find.text('Trucks (3)'), findsOneWidget);
    expect(find.text('SLA urgency'), findsOneWidget);
    expect(find.text('S1 Logistics'), findsOneWidget);
    expect(find.text('supplier@example.com'), findsOneWidget);
    expect(find.text('9999999999'), findsOneWidget);
    expect(find.text('Case case-1'), findsOneWidget);
    expect(find.text('Subject user-1'), findsOneWidget);
    expect(find.text('Submitted 2026-03-12 21:10'), findsOneWidget);
    expect(find.text('12h left'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-queue-open-subject-case-1')), findsOneWidget);
    expect(find.text('MH12AB1234'), findsOneWidget);
    expect(find.text('Trucker One • 8888888888'), findsOneWidget);
    expect(find.text('Assigned admin Ops One (ops_admin) • admin-1'), findsOneWidget);
    expect(find.text('Case case-2'), findsOneWidget);
    expect(find.text('Subject truck-1'), findsOneWidget);
    expect(find.text('Submitted 2026-03-12 22:00'), findsOneWidget);
    expect(find.byKey(const ValueKey('verification-queue-open-subject-case-2')), findsOneWidget);
    expect(find.text('Open owner profile'), findsOneWidget);
  });

  testWidgets('verification queue routes to verification detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedQueueApp(
        state: AdminVerificationQueueState.initial().copyWith(
          items: [
            VerificationQueueItem(
              caseId: 'case-1',
              subjectId: 'user-1',
              subjectType: 'supplier_profile',
              displayName: 'S1 Logistics',
              secondaryLabel: 'supplier@example.com',
              contactLabel: '9999999999',
              profileLinkId: 'user-1',
              profileLinkLabel: 'Open subject profile',
              caseStatus: 'submitted',
              submittedAt: DateTime(2026, 3, 12, 21, 10),
              slaLabel: '12h left',
              slaPriority: 1,
              isClaimed: false,
              assignedAdminUserId: '',
              assignedAdminLabel: '',
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('S1 Logistics'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('S1 Logistics'));
    await tester.pumpAndSettle();

    expect(find.text('Verification detail opened: case-1'), findsOneWidget);
  });

  testWidgets('verification queue routes to user detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedQueueApp(
        state: AdminVerificationQueueState.initial().copyWith(
          items: [
            VerificationQueueItem(
              caseId: 'case-1',
              subjectId: 'user-1',
              subjectType: 'supplier_profile',
              displayName: 'S1 Logistics',
              secondaryLabel: 'supplier@example.com',
              contactLabel: '9999999999',
              profileLinkId: 'user-1',
              profileLinkLabel: 'Open subject profile',
              caseStatus: 'submitted',
              submittedAt: DateTime(2026, 3, 12, 21, 10),
              slaLabel: '12h left',
              slaPriority: 1,
              isClaimed: false,
              assignedAdminUserId: '',
              assignedAdminLabel: '',
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('verification-queue-open-subject-case-1')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.byKey(const ValueKey('verification-queue-open-subject-case-1')));
    await tester.pumpAndSettle();

    expect(find.text('User detail opened: user-1'), findsOneWidget);
  });
}
