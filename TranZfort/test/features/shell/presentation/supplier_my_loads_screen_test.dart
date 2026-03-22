import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_profile_repository.dart';
import 'package:tranzfort/src/features/shell/presentation/supplier_shell_screens.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/providers/my_loads_provider.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _TestMyLoadsController extends MyLoadsController {
  _TestMyLoadsController(this._state)
      : super(
          SupplierLoadRepository(_NoopSupplierLoadBackend(), () => 'supplier-1'),
        ) {
    state = _state;
  }

  final MyLoadsState _state;

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> selectTab(MyLoadsTab tab) async {
    state = state.copyWith(selectedTab: tab);
  }
}

class _NoopSupplierLoadBackend implements SupplierLoadBackend {
  @override
  Future<String> approveBookingRequest(String bookingId) async => 'trip-1';

  @override
  Future<String> createLoad(Map<String, dynamic> params) async => 'load-new';

  @override
  Future<void> cancelLoad(String loadId) async {}

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {}

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({required String supplierId, required String loadId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({required String supplierId, required String loadId}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({required String supplierId, required String loadId}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({required String supplierId, required LoadFilters filters, required int page, required int pageSize}) async => const <Map<String, dynamic>>[];

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {}
}

Widget _buildApp(
  MyLoadsState state, {
  required String verificationStatus,
  bool supplierProfileUnavailable = false,
  String companyName = 'North Hub Logistics',
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: SupplierMyLoadsScreen()),
      ),
      GoRoute(
        path: AppRoutes.supplierVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier verification opened')),
      ),
      GoRoute(
        path: AppRoutes.postLoadPath,
        builder: (context, state) => const Scaffold(body: Text('Post load opened')),
      ),
      GoRoute(
        path: AppRoutes.supportPath,
        builder: (context, state) => const Scaffold(body: Text('Support opened')),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads route opened')),
      ),
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      myLoadsProvider.overrideWith((ref) => _TestMyLoadsController(state)),
      supplierProfileProvider.overrideWith(
        (ref) async => supplierProfileUnavailable
            ? null
            : SupplierProfile(
                id: 'supplier-1',
                fullName: 'North Hub Logistics',
                mobile: '+919999999999',
                email: 'ops@northhub.test',
                verificationStatus: verificationStatus,
                companyName: companyName,
                businessLicenceNumber: 'BL-42',
                gstNumber: '27ABCDE1234F1Z5',
                totalLoadsPosted: 0,
                activeLoadsCount: 0,
              ),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

Load _sampleLoad(
  String id,
  String status, {
  bool isSuperLoad = false,
  String superStatus = 'none',
}) {
  return Load(
    id: id,
    originLabel: 'Chandrapur, Maharashtra',
    destinationLabel: 'Mumbai, Maharashtra',
    material: 'Coal',
    weightTonnes: 22,
    trucksNeeded: 2,
    trucksBooked: 1,
    priceAmount: 54000,
    priceType: 'negotiable',
    pickupDate: DateTime(2026, 3, 10),
    status: status,
    requiredBodyType: 'Open',
    requiredTyres: const [10, 12],
    isSuperLoad: isSuperLoad,
    superStatus: superStatus,
    publishedAt: DateTime(2026, 3, 8),
  );
}

void main() {
  testWidgets('renders supplier my loads success state', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: <Load>[_sampleLoad('load-1', 'active')],
          hasMore: false,
        ),
        verificationStatus: 'verified',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My loads'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.textContaining('Chandrapur, Maharashtra → Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('supplier my loads card tap opens load detail', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: <Load>[_sampleLoad('load-1', 'active')],
          hasMore: false,
        ),
        verificationStatus: 'verified',
      ),
    );
    await tester.pumpAndSettle();

    final loadCardTitle = find.textContaining('Chandrapur, Maharashtra → Mumbai, Maharashtra').first;

    await tester.tap(loadCardTitle);
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('renders empty state for active loads', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <Load>[],
          hasMore: false,
        ),
        verificationStatus: 'pending',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active loads yet'), findsOneWidget);
    expect(find.text('Complete verification'), findsOneWidget);

    await tester.tap(find.text('Complete verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('verified supplier empty-state posting action opens post load', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <Load>[],
          hasMore: false,
        ),
        verificationStatus: 'verified',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active loads yet'), findsOneWidget);
    expect(find.text('Post Load'), findsOneWidget);

    await tester.tap(find.text('Post Load'));
    await tester.pumpAndSettle();

    expect(find.text('Post load opened'), findsOneWidget);
  });

  testWidgets('verified supplier without company name routes empty-state CTA to verification', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <Load>[],
          hasMore: false,
        ),
        verificationStatus: 'verified',
        companyName: '',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active loads yet'), findsOneWidget);
    expect(find.text('Complete verification'), findsOneWidget);
    expect(find.text('Post Load'), findsNothing);

    await tester.tap(find.text('Complete verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('supplier my loads routes active empty-state CTA to support when supplier profile is unavailable', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <Load>[],
          hasMore: false,
        ),
        verificationStatus: 'pending',
        supplierProfileUnavailable: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active loads yet'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Complete verification'), findsNothing);

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('supplier my loads completed empty-state action opens my loads route', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          selectedTab: MyLoadsTab.completed,
          loads: const <Load>[],
          hasMore: false,
        ),
        verificationStatus: 'verified',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No completed loads yet'), findsOneWidget);
    expect(find.text('Open active loads'), findsOneWidget);

    await tester.tap(find.text('Open active loads'));
    await tester.pumpAndSettle();

    expect(find.text('My loads route opened'), findsOneWidget);
  });

  testWidgets('renders Super Load trust state on supplier load cards', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: <Load>[
            _sampleLoad(
              'load-1',
              'active',
              isSuperLoad: true,
              superStatus: 'approved_payment_pending',
            ),
          ],
          hasMore: false,
        ),
        verificationStatus: 'verified',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Super Load • Approved • payment pending'), findsOneWidget);
    expect(find.textContaining('activation still depends on the off-platform payment confirmation step'), findsOneWidget);
  });

  testWidgets('renders error state when my loads fail', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        MyLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <Load>[],
          hasMore: false,
          failure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
        verificationStatus: 'unverified',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load your supplier loads'), findsOneWidget);
    expect(
      find.text('We could not load your supplier loads right now. Retry shortly to refresh the latest load list.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
