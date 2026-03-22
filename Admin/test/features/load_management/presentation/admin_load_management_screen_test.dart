import 'package:admin/src/core/navigation/admin_routes.dart';
import 'package:admin/src/core/repositories/admin_load_management_repository.dart';
import 'package:admin/src/core/repositories/admin_audit_log_repository.dart';
import 'package:admin/src/features/load_management/presentation/admin_load_detail_screen.dart';
import 'package:admin/src/features/load_management/presentation/admin_load_management_screen.dart';
import 'package:admin/src/features/load_management/providers/admin_load_management_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _FakeAdminLoadManagementController extends AdminLoadManagementController {
  final AdminLoadManagementState initialState;

  _FakeAdminLoadManagementController(this.initialState);

  @override
  Future<AdminLoadManagementState> build() async => initialState;
}

class _FakeAdminLoadActionController extends AdminLoadActionController {
  String? lastCancelledLoadId;

  @override
  Future<bool> cancelLoad(String loadId) async {
    lastCancelledLoadId = loadId;
    return true;
  }
}

Widget _buildRoutedLoadManagementApp({
  required AdminLoadManagementState state,
  AdminLoadDetail? detail,
  List<AdminAuditLogEntry> auditEntries = const <AdminAuditLogEntry>[],
}) {
  final router = GoRouter(
    initialLocation: AdminRoutes.loadManagementPath,
    routes: [
      GoRoute(
        path: AdminRoutes.loadManagementPath,
        builder: (context, state) => const Scaffold(body: AdminLoadManagementScreen()),
      ),
      GoRoute(
        path: AdminRoutes.loadDetailPath,
        builder: (context, state) {
          final loadId = state.pathParameters['loadId']!;
          if (detail != null && detail.id == loadId) {
            return Scaffold(body: AdminLoadDetailScreen(loadId: loadId));
          }
          return Scaffold(body: Text('Load detail opened: $loadId'));
        },
      ),
      GoRoute(
        path: AdminRoutes.userDetailPath,
        builder: (context, state) => Scaffold(body: Text('User detail opened: ${state.pathParameters['userId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      adminLoadManagementProvider.overrideWith(() => _FakeAdminLoadManagementController(state)),
      adminLoadActionProvider.overrideWith(() => _FakeAdminLoadActionController()),
      if (detail != null) adminLoadDetailProvider(detail.id).overrideWith((ref) async => detail),
      if (detail != null) adminLoadAuditTrailProvider(detail.id).overrideWith((ref) async => auditEntries),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('admin load management screen renders rows', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminLoadManagementProvider.overrideWith(
            () => _FakeAdminLoadManagementController(
              AdminLoadManagementState.initial().copyWith(
                items: [
                  AdminLoadListItem(
                    id: 'load-1',
                    supplierId: 'supplier-1',
                    supplierName: 'Supplier One',
                    routeLabel: 'Mumbai → Pune',
                    material: 'Steel',
                    priceAmount: 42000,
                    trucksNeeded: 2,
                    trucksBooked: 1,
                    status: 'active',
                    isSuperLoad: true,
                    superStatus: 'approved_payment_pending',
                    pickupDate: DateTime(2026, 3, 15, 6, 30),
                    createdAt: DateTime(2026, 3, 12, 18, 10),
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminLoadManagementScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Load management'), findsOneWidget);
    expect(find.text('Load id, supplier or supplier id, route, material, status, or super status'), findsOneWidget);
    expect(find.textContaining('This surface is currently read-heavy'), findsOneWidget);
    expect(find.text('Mumbai → Pune • Steel'), findsOneWidget);
    expect(find.text('Supplier One • Active'), findsOneWidget);
    expect(find.text('Supplier supplier-1'), findsOneWidget);
    expect(find.text('Load load-1'), findsOneWidget);
    expect(find.text('Super status Approved Payment Pending'), findsOneWidget);
    expect(find.text('Pickup 2026-03-15 06:30 • Created 2026-03-12 18:10'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-load-list-open-supplier-load-1')), findsOneWidget);
  });

  testWidgets('admin load detail screen renders detail and cancels', (tester) async {
    late _FakeAdminLoadActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminLoadDetailProvider('load-1').overrideWith((ref) async {
            return AdminLoadDetail(
              id: 'load-1',
              supplierId: 'supplier-1',
              supplierName: 'Supplier One',
              originLabel: 'Mumbai Yard',
              destinationLabel: 'Pune Site',
              routeLabel: 'Mumbai → Pune',
              material: 'Steel',
              weightTonnes: 18,
              requiredBodyType: 'Open',
              requiredTyres: [10, 12],
              trucksNeeded: 2,
              trucksBooked: 1,
              priceAmount: 42000,
              priceType: 'fixed',
              advancePercentage: 20,
              status: 'active',
              isSuperLoad: false,
              superStatus: 'none',
              pickupDate: DateTime(2026, 3, 15, 6, 30),
              publishedAt: DateTime(2026, 3, 12, 19, 0),
              createdAt: DateTime(2026, 3, 12, 18, 10),
            );
          }),
          adminLoadActionProvider.overrideWith(() {
            actionController = _FakeAdminLoadActionController();
            return actionController;
          }),
          adminLoadManagementProvider.overrideWith(
            () => _FakeAdminLoadManagementController(AdminLoadManagementState.initial()),
          ),
          adminLoadAuditTrailProvider('load-1').overrideWith((ref) async {
            return [
              AdminAuditLogEntry(
                id: 'audit-1',
                actorAdminUserId: 'admin-1',
                actorAdminLabel: 'Ops One (ops_admin)',
                actorType: 'admin',
                actorRole: 'ops_admin',
                actionType: 'admin_cancel_load',
                targetObjectType: 'load',
                targetObjectId: 'load-1',
                secondaryObjectType: '',
                secondaryObjectId: '',
                summary: 'Load cancellation requested by admin',
                visibilityClass: 'internal',
                createdAt: DateTime(2026, 3, 12, 21, 30),
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: AdminLoadDetailScreen(loadId: 'load-1')),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Load detail'), findsOneWidget);
    expect(find.text('load-1'), findsOneWidget);
    expect(find.text('supplier-1'), findsOneWidget);
    expect(find.text('Supplier One'), findsOneWidget);
    expect(find.text('2026-03-15 06:30'), findsOneWidget);
    expect(find.text('2026-03-12 19:00'), findsOneWidget);
    expect(find.text('2026-03-12 18:10'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-load-open-supplier-button')), findsOneWidget);
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Current load management contract'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('Current load management contract'), findsOneWidget);
    expect(find.textContaining('inspection-first'), findsOneWidget);
    expect(find.textContaining('shared cancellation path is now audited'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent audit trail'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent audit trail'), findsOneWidget);
    expect(find.textContaining('shared audited cancellation path'), findsOneWidget);
    expect(find.text('Load cancellation requested by admin'), findsOneWidget);
    expect(find.text('admin_cancel_load'), findsOneWidget);
    expect(find.text('Visibility internal'), findsOneWidget);
    expect(find.text('Actor Ops One (ops_admin) • admin-1 • ops_admin'), findsOneWidget);
    expect(find.text('Audit audit-1'), findsOneWidget);
    expect(find.text('Created 12 Mar 21:30'), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-load-audit-entry-audit-1')), findsOneWidget);
    await actionController.cancelLoad('load-1');

    expect(actionController.lastCancelledLoadId, 'load-1');
  });

  testWidgets('admin load management list routes to load detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedLoadManagementApp(
        state: AdminLoadManagementState.initial().copyWith(
          items: [
            AdminLoadListItem(
              id: 'load-1',
              supplierId: 'supplier-1',
              supplierName: 'Supplier One',
              routeLabel: 'Mumbai → Pune',
              material: 'Steel',
              priceAmount: 42000,
              trucksNeeded: 2,
              trucksBooked: 1,
              status: 'active',
              isSuperLoad: true,
              superStatus: 'approved_payment_pending',
              pickupDate: DateTime(2026, 3, 15, 6, 30),
              createdAt: DateTime(2026, 3, 12, 18, 10),
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Open'),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('admin load management list routes to supplier detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedLoadManagementApp(
        state: AdminLoadManagementState.initial().copyWith(
          items: [
            AdminLoadListItem(
              id: 'load-1',
              supplierId: 'supplier-1',
              supplierName: 'Supplier One',
              routeLabel: 'Mumbai → Pune',
              material: 'Steel',
              priceAmount: 42000,
              trucksNeeded: 2,
              trucksBooked: 1,
              status: 'active',
              isSuperLoad: true,
              superStatus: 'approved_payment_pending',
              pickupDate: DateTime(2026, 3, 15, 6, 30),
              createdAt: DateTime(2026, 3, 12, 18, 10),
            ),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-load-list-open-supplier-load-1')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.byKey(const ValueKey('admin-load-list-open-supplier-load-1')));
    await tester.pumpAndSettle();

    expect(find.text('User detail opened: supplier-1'), findsOneWidget);
  });

  testWidgets('admin load detail routes to supplier detail', (tester) async {
    await tester.pumpWidget(
      _buildRoutedLoadManagementApp(
        state: AdminLoadManagementState.initial(),
        detail: AdminLoadDetail(
          id: 'load-1',
          supplierId: 'supplier-1',
          supplierName: 'Supplier One',
          originLabel: 'Mumbai Yard',
          destinationLabel: 'Pune Site',
          routeLabel: 'Mumbai → Pune',
          material: 'Steel',
          weightTonnes: 18,
          requiredBodyType: 'Open',
          requiredTyres: const [10, 12],
          trucksNeeded: 2,
          trucksBooked: 1,
          priceAmount: 42000,
          priceType: 'fixed',
          advancePercentage: 20,
          status: 'active',
          isSuperLoad: false,
          superStatus: 'none',
          pickupDate: DateTime(2026, 3, 15, 6, 30),
          publishedAt: DateTime(2026, 3, 12, 19, 0),
          createdAt: DateTime(2026, 3, 12, 18, 10),
        ),
      ),
    );

    final router = GoRouter.of(tester.element(find.byType(AdminLoadManagementScreen)));
    router.go(AdminRoutes.loadDetailPathFor('load-1'));
    await tester.pumpAndSettle();
    
    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('admin-load-open-supplier-button')),
      200,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    
    await tester.tap(find.byKey(const ValueKey('admin-load-open-supplier-button')));
    await tester.pumpAndSettle();

    expect(find.text('User detail opened: supplier-1'), findsOneWidget);
  });
}
