import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/core/repositories/splitted/super_ops_models.dart';
import 'package:admin/src/features/super_ops/presentation/super_ops_console_screen.dart';
import 'package:admin/src/features/super_ops/presentation/super_ops_load_detail_screen.dart';
import 'package:admin/src/features/super_ops/providers/super_ops_detail_provider.dart';
import 'package:admin/src/core/repositories/admin_super_ops_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Admin super ops integration tests', () {
    testWidgets('A-SOPS-01: super-ops queue render', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            adminSuperOpsRepositoryProvider.overrideWith(
              (ref) => FakeAdminSuperOpsRepository(),
            ),
          ],
          child: const MaterialApp(home: SuperOpsConsoleScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Super Ops Console'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Dispatch'), findsOneWidget);
      expect(find.text('POD Review'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('A-SOPS-02: accept request', (WidgetTester tester) async {
      var acceptedLoadId = '';
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsLoadDetailProvider('load-123').overrideWith(
              (ref) async => _fixtureLoadDetailRequested(),
            ),
            adminSuperOpsRepositoryProvider.overrideWith(
              (ref) => FakeAdminSuperOpsRepository(
                onAcceptRequest: (loadId) => acceptedLoadId = loadId,
              ),
            ),
          ],
          child: const MaterialApp(home: SuperOpsLoadDetailScreen(loadId: 'load-123')),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept Request'));
      await tester.pumpAndSettle();

      expect(acceptedLoadId, 'load-123');
    });

    testWidgets('A-SOPS-03: reject request', (WidgetTester tester) async {
      var rejectedLoadId = '';
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsLoadDetailProvider('load-123').overrideWith(
              (ref) async => _fixtureLoadDetailRequested(),
            ),
            adminSuperOpsRepositoryProvider.overrideWith(
              (ref) => FakeAdminSuperOpsRepository(
                onRejectRequest: (loadId) => rejectedLoadId = loadId,
              ),
            ),
          ],
          child: const MaterialApp(home: SuperOpsLoadDetailScreen(loadId: 'load-123')),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Reject Request'));
      await tester.pumpAndSettle();

      expect(rejectedLoadId, 'load-123');
    });

    testWidgets('A-SOPS-04: force assign trucker', (WidgetTester tester) async {
      var assignmentData = <String, dynamic>{};
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            superOpsLoadDetailProvider('load-123').overrideWith(
              (ref) async => _fixtureLoadDetailProcessing(),
            ),
            adminSuperOpsRepositoryProvider.overrideWith(
              (ref) => FakeAdminSuperOpsRepository(
                onForceAssign: (loadId, truckerId, truckId) {
                  assignmentData = {
                    'loadId': loadId,
                    'truckerId': truckerId,
                    'truckId': truckId,
                  };
                },
              ),
            ),
          ],
          child: const MaterialApp(home: SuperOpsLoadDetailScreen(loadId: 'load-123')),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.radio_button_unchecked).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Force assignment'));
      await tester.pumpAndSettle();

      expect(assignmentData['loadId'], 'load-123');
      expect(assignmentData['truckerId'], 'trucker-1');
      expect(assignmentData['truckId'], 'truck-1');
    });
  });
}

class FakeAdminSuperOpsRepository extends AdminSuperOpsRepository {
  final Function(String loadId)? onAcceptRequest;
  final Function(String loadId)? onRejectRequest;
  final Function(String loadId, String truckerId, String truckId)? onForceAssign;

  FakeAdminSuperOpsRepository({
    this.onAcceptRequest,
    this.onRejectRequest,
    this.onForceAssign,
  }) : super(_FakeRef());

  @override
  Future<bool> acceptRequest(String loadId) async {
    onAcceptRequest?.call(loadId);
    return true;
  }

  @override
  Future<bool> rejectRequest(String loadId) async {
    onRejectRequest?.call(loadId);
    return true;
  }

  @override
  Future<bool> forceAssign({
    required String loadId,
    required String truckerId,
    required String truckId,
    int? truckCount,
  }) async {
    onForceAssign?.call(loadId, truckerId, truckId);
    return true;
  }

  @override
  Future<SuperOpsQueueCounts> fetchQueueCounts() async {
    return const SuperOpsQueueCounts(
      requests: 5,
      dispatch: 3,
      podReview: 2,
      completed: 10,
    );
  }

  @override
  Future<List<SuperOpsLoadSummary>> fetchQueue(SuperOpsQueueQuery query) async {
    return [];
  }

  @override
  Future<SuperOpsLoadDetail?> fetchLoadDetail(String loadId) async {
    return null;
  }

  @override
  Future<bool> confirmPayout(String loadId) async => true;

  @override
  Future<bool> disputePod(String loadId) async => true;

  @override
  Future<List<DispatchTruckerCandidate>> searchDispatchCandidates({
    required String loadId,
    double? originLat,
    double? originLng,
    String? requiredTruckType,
    List<int>? requiredTyres,
    int? trucksNeeded,
    bool fallback = false,
  }) async {
    return [];
  }

  @override
  Future<List<SuperOpsSupplierOption>> fetchSuppliers() async {
    return [];
  }

  @override
  Future<bool> postLoadOnBehalf(SuperOpsPostLoadPayload payload) async {
    return true;
  }
}

class _FakeRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

SuperOpsLoadDetail _fixtureLoadDetailRequested() {
  return const SuperOpsLoadDetail(
    id: 'load-123',
    routeLabel: 'Mumbai → Pune',
    originLat: null,
    originLng: null,
    material: 'Steel',
    weightTonnes: 24,
    price: 64000,
    priceType: 'fixed',
    advancePercentage: 10,
    pickupDate: null,
    requiredTruckType: 'open',
    requiredTyres: [],
    trucksNeeded: 1,
    trucksBooked: 0,
    status: 'active',
    superStatus: 'requested',
    podPhotoUrl: '',
    lrPhotoUrl: '',
    createdAt: null,
    supplier: SuperOpsSupplierInfo(
      id: 'supplier-1',
      fullName: 'Test Supplier',
      companyName: 'Test Company',
      mobile: '+919999999999',
      email: 'supplier@test.com',
      verificationStatus: 'verified',
      gstNumber: 'GST123',
    ),
    payout: SuperOpsPayoutInfo(
      accountHolderName: '',
      accountNumberLast4: '',
      ifscCode: '',
      bankName: '',
      status: '',
    ),
    assignments: [],
  );
}

SuperOpsLoadDetail _fixtureLoadDetailProcessing() {
  final detail = _fixtureLoadDetailRequested();
  return SuperOpsLoadDetail(
    id: detail.id,
    routeLabel: detail.routeLabel,
    originLat: detail.originLat,
    originLng: detail.originLng,
    material: detail.material,
    weightTonnes: detail.weightTonnes,
    price: detail.price,
    priceType: detail.priceType,
    advancePercentage: detail.advancePercentage,
    pickupDate: detail.pickupDate,
    requiredTruckType: detail.requiredTruckType,
    requiredTyres: detail.requiredTyres,
    trucksNeeded: detail.trucksNeeded,
    trucksBooked: detail.trucksBooked,
    status: detail.status,
    superStatus: 'processing',
    podPhotoUrl: detail.podPhotoUrl,
    lrPhotoUrl: detail.lrPhotoUrl,
    createdAt: detail.createdAt,
    supplier: detail.supplier,
    payout: detail.payout,
    assignments: detail.assignments,
  );
}
