import 'package:admin/src/core/repositories/admin_super_load_repository.dart';
import 'package:admin/src/features/super_ops/presentation/admin_super_load_console_screen.dart';
import 'package:admin/src/features/super_ops/providers/admin_super_load_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminSuperLoadQueueController extends AdminSuperLoadQueueController {
  final AdminSuperLoadQueueState initialState;

  _FakeAdminSuperLoadQueueController(this.initialState);

  @override
  Future<AdminSuperLoadQueueState> build() async => initialState;
}

class _FakeAdminSuperLoadActionController extends AdminSuperLoadActionController {
  String? lastReviewLoadId;
  String? lastApproveLoadId;
  String? lastRejectLoadId;
  String? lastRejectReason;
  String? lastActivateLoadId;
  String? lastForceAssignLoadId;
  String? lastForceAssignTruckerId;
  String? lastForceAssignTruckId;

  @override
  Future<bool> markUnderReview(String loadId) async {
    lastReviewLoadId = loadId;
    return true;
  }

  @override
  Future<bool> approveRequest(String loadId) async {
    lastApproveLoadId = loadId;
    return true;
  }

  @override
  Future<bool> rejectRequest(String loadId, {String? reason}) async {
    lastRejectLoadId = loadId;
    lastRejectReason = reason;
    return true;
  }

  @override
  Future<bool> activateSuperLoad(String loadId) async {
    lastActivateLoadId = loadId;
    return true;
  }

  @override
  Future<bool> forceAssignSuperLoad({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) async {
    lastForceAssignLoadId = loadId;
    lastForceAssignTruckerId = truckerId;
    lastForceAssignTruckId = truckId;
    return true;
  }
}

void main() {
  testWidgets('super load console renders rows and actions', (tester) async {
    late _FakeAdminSuperLoadActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminSuperLoadQueueProvider.overrideWith(
            () => _FakeAdminSuperLoadQueueController(
              AdminSuperLoadQueueState.initial().copyWith(
                counts: const AdminSuperLoadCounts(requestSubmitted: 1, underReview: 0, paymentPending: 0, active: 0, rejected: 0),
                items: [
                  AdminSuperLoadItem(
                    id: 'load-1',
                    supplierId: 'supplier-1',
                    supplierName: 'Supplier One',
                    routeLabel: 'Mumbai → Pune',
                    material: 'Steel',
                    status: 'request_submitted',
                    loadStatus: 'active',
                    trucksNeeded: 2,
                    trucksBooked: 0,
                    priceAmount: 42000,
                    pickupDate: DateTime(2026, 3, 18, 7, 15),
                    updatedAt: DateTime(2026, 3, 12, 20, 40),
                  ),
                ],
              ),
            ),
          ),
          adminSuperLoadActionProvider.overrideWith(() {
            actionController = _FakeAdminSuperLoadActionController();
            return actionController;
          }),
          adminSuperLoadDispatchCandidatesProvider('').overrideWith((ref) async {
            return const [
              AdminSuperLoadDispatchCandidate(
                truckerId: 'trucker-1',
                truckId: 'truck-1',
                truckerName: 'Trucker One',
                mobile: '9999999999',
                truckNumber: 'MH12AB1234',
                bodyType: 'Open',
                rating: '4.8',
                completedTrips: '12',
                superTruckerStatus: 'eligible',
              ),
            ];
          }),
          adminSuperLoadPodReviewProvider.overrideWith((ref) async {
            return [
              AdminSuperLoadPodReviewItem(
                tripId: 'trip-1',
                loadId: 'child-load-1',
                supplierId: 'supplier-1',
                supplierName: 'Supplier One',
                truckerId: 'trucker-1',
                truckerName: 'Trucker One',
                truckId: 'truck-1',
                truckNumber: 'MH12AB1234',
                routeLabel: 'Mumbai → Pune',
                material: 'Steel',
                deliveredAt: DateTime(2026, 3, 12, 6, 0),
                podUploadedAt: DateTime(2026, 3, 12, 6, 30),
                deliveredGpsLat: 18.5204,
                deliveredGpsLng: 73.8567,
                podGpsLat: 18.5210,
                podGpsLng: 73.8571,
                podSignedUrl: 'https://example.test/pod.jpg',
                lrSignedUrl: 'https://example.test/lr.jpg',
              ),
            ];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminSuperLoadConsoleScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Super Load console'), findsOneWidget);
    expect(find.text('Load id, supplier or supplier id, route, material, super status, or load status'), findsOneWidget);
    expect(find.text('Requests (1)'), findsOneWidget);
    expect(find.text('Mumbai → Pune • Steel'), findsAtLeastNWidgets(1));
    expect(find.text('Supplier One • Request Submitted'), findsOneWidget);
    expect(find.text('Super status Request Submitted'), findsOneWidget);
    expect(find.text('Load ID load-1'), findsOneWidget);
    expect(find.text('Pickup 2026-03-18 07:15 • Updated 2026-03-12 20:40'), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-load-row-load-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-supplier-row-load-1')), findsOneWidget);

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('super-review-load-1')),
      150,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('super-review-load-1')));
    await tester.pumpAndSettle();
    expect(actionController.lastReviewLoadId, 'load-1');

    await tester.tap(find.byKey(const ValueKey('super-approve-load-1')));
    await tester.pumpAndSettle();
    expect(actionController.lastApproveLoadId, 'load-1');

    await tester.tap(find.byKey(const ValueKey('super-reject-load-1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('super-reject-reason-field')), 'Missing readiness');
    await tester.tap(find.byKey(const ValueKey('super-reject-confirm-button')));
    await tester.pumpAndSettle();
    expect(actionController.lastRejectLoadId, 'load-1');
    expect(actionController.lastRejectReason, 'Missing readiness');

    await tester.scrollUntilVisible(
      find.text('POD review'),
      250,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();
    expect(find.text('POD review'), findsOneWidget);
    expect(find.textContaining('dedicated admin trip-detail route is not available'), findsOneWidget);
    expect(find.text('Load child-load-1'), findsOneWidget);
    expect(find.text('Supplier supplier-1'), findsAtLeastNWidgets(1));
    expect(find.text('Trucker trucker-1'), findsOneWidget);
    expect(find.text('Truck truck-1'), findsOneWidget);
    expect(find.text('Delivered 2026-03-12 06:00 • Proof uploaded 2026-03-12 06:30'), findsOneWidget);
    expect(find.text('Proofs POD Available • LR Available'), findsOneWidget);
    expect(find.text('Delivery GPS 18.52040, 73.85670'), findsOneWidget);
    expect(find.text('POD GPS 18.52100, 73.85710'), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-pod-trip-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-load-trip-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-supplier-trip-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-trucker-trip-1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('super-open-pod-trip-1')));
    await tester.pumpAndSettle();
    expect(find.text('POD proof'), findsOneWidget);
    expect(find.text('https://example.test/pod.jpg'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  });

  testWidgets('super load console force assigns active loads', (tester) async {
    late _FakeAdminSuperLoadActionController actionController;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminSuperLoadQueueProvider.overrideWith(
            () => _FakeAdminSuperLoadQueueController(
              AdminSuperLoadQueueState.initial().copyWith(
                counts: const AdminSuperLoadCounts(requestSubmitted: 0, underReview: 0, paymentPending: 1, active: 1, rejected: 1),
                items: const [
                  AdminSuperLoadItem(
                    id: 'load-1',
                    supplierId: 'supplier-1',
                    supplierName: 'Supplier One',
                    routeLabel: 'Mumbai → Nashik',
                    material: 'Steel',
                    status: 'approved_payment_pending',
                    loadStatus: 'active',
                    trucksNeeded: 2,
                    trucksBooked: 1,
                    priceAmount: 32000,
                    pickupDate: null,
                    updatedAt: null,
                  ),
                  AdminSuperLoadItem(
                    id: 'load-2',
                    supplierId: 'supplier-1',
                    supplierName: 'Supplier One',
                    routeLabel: 'Delhi → Jaipur',
                    material: 'Cement',
                    status: 'active',
                    loadStatus: 'active',
                    trucksNeeded: 1,
                    trucksBooked: 0,
                    priceAmount: 18000,
                    pickupDate: null,
                    updatedAt: null,
                  ),
                ],
              ),
            ),
          ),
          adminSuperLoadActionProvider.overrideWith(() {
            actionController = _FakeAdminSuperLoadActionController();
            return actionController;
          }),
          adminSuperLoadDispatchCandidatesProvider('').overrideWith((ref) async {
            return const [
              AdminSuperLoadDispatchCandidate(
                truckerId: 'trucker-1',
                truckId: 'truck-1',
                truckerName: 'Trucker One',
                mobile: '9999999999',
                truckNumber: 'MH12AB1234',
                bodyType: 'Open',
                rating: '4.8',
                completedTrips: '12',
                superTruckerStatus: 'eligible',
              ),
            ];
          }),
          adminSuperLoadPodReviewProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminSuperLoadConsoleScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rejected (1)'), findsOneWidget);

    final primaryScrollView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Dispatch readiness'),
      250,
      scrollable: primaryScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispatch readiness'), findsOneWidget);
    expect(find.textContaining('Current dispatch authority here is limited to payment confirmation and force-assign'), findsOneWidget);
    expect(find.byKey(const ValueKey('super-dispatch-readiness-activate-load-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('super-dispatch-readiness-force-load-2')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('super-dispatch-readiness-activate-load-1')));
    await tester.pumpAndSettle();
    expect(actionController.lastActivateLoadId, 'load-1');

    await tester.tap(find.byKey(const ValueKey('super-dispatch-readiness-force-load-2')));
    await tester.pumpAndSettle();

    expect(find.text('Force assign Super Load'), findsOneWidget);
    expect(find.text('Name, trucker/truck id, mobile, truck number, body type, or status'), findsOneWidget);
    expect(find.text('Trucker One • MH12AB1234'), findsOneWidget);
    expect(find.text('9999999999 • Open'), findsOneWidget);
    expect(find.text('Rating 4.8 • Completed trips 12'), findsOneWidget);
    expect(find.text('Super trucker Eligible'), findsOneWidget);
    expect(find.byKey(const ValueKey('super-open-dispatch-trucker-truck-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('super-dispatch-candidate-truck-1')));
    await tester.pumpAndSettle();

    expect(actionController.lastForceAssignLoadId, 'load-2');
    expect(actionController.lastForceAssignTruckerId, 'trucker-1');
  });

}
