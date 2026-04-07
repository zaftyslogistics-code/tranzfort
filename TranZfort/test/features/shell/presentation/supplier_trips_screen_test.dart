import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/shell/presentation/supplier_shell_screens.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_trips_provider.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _TestSupplierTripsController extends SupplierTripsController {
  _TestSupplierTripsController(this._initialState)
      : super(
          SupplierTripsRepository(_NoopTripsBackend(), () => 'supplier-1'),
        ) {
    state = _initialState;
  }

  final SupplierTripsState _initialState;

  @override
  Future<void> load() async {}

  @override
  Future<void> selectTab(SupplierTripsTab tab) async {
    state = state.copyWith(selectedTab: tab);
  }
}

class _NoopTripsBackend implements SupplierTripsBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages}) async => const <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => null;

  @override
  Future<void> cancelTrip(String tripId) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;

  @override
  Future<void> confirmTripDelivery(String tripId) async {}

  @override
  Future<String> raiseTripDispute({
    required String tripId,
    required String category,
    required String reason,
    String? attachmentPath,
  }) async => 'support-ticket-1';
}

Widget _buildApp(SupplierTripsState state) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: SupplierTripsScreen()),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads opened')),
      ),
      GoRoute(
        path: AppRoutes.supplierTripsPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier trips route opened')),
      ),
      GoRoute(
        path: '${AppRoutes.tripDetailPath}/:tripId',
        builder: (context, state) => Scaffold(body: Text('Trip detail opened: ${state.pathParameters['tripId']}')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      supplierTripsProvider.overrideWith((ref) => _TestSupplierTripsController(state)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

SupplierTrip _sampleTrip(String id, String stage) {
  return SupplierTrip(
    id: id,
    loadId: 'load-$id',
    routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
    material: 'Coal',
    stage: stage,
    truckerId: 'trucker-$id',
    truckId: 'truck-$id',
    assignedAt: DateTime(2026, 3, 8),
    deliveredAt: null,
    podUploadedAt: stage == 'completed' ? DateTime(2026, 3, 10) : null,
    completedAt: stage == 'completed' ? DateTime(2026, 3, 10) : null,
    hasLrProof: true,
    hasPodProof: stage == 'completed',
  );
}

void main() {
  testWidgets('renders supplier trips success state', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SupplierTripsState.initial().copyWith(
          isLoading: false,
          trips: <SupplierTrip>[_sampleTrip('1', 'in_transit')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier trips'), findsOneWidget);
    expect(find.textContaining('Chandrapur, Maharashtra > Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('Track trip'), findsOneWidget);

    await tester.tap(find.text('Track trip'));
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: 1'), findsOneWidget);
  });

  testWidgets('supplier trips card tap opens trip detail', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SupplierTripsState.initial().copyWith(
          isLoading: false,
          trips: <SupplierTrip>[_sampleTrip('1', 'in_transit')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tripCardTitle = find.textContaining('Chandrapur, Maharashtra > Mumbai, Maharashtra').first;

    await tester.tap(tripCardTitle);
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: 1'), findsOneWidget);
  });

  testWidgets('supplier trips fall back to unknown for unsupported stage', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SupplierTripsState.initial().copyWith(
          isLoading: false,
          trips: <SupplierTrip>[_sampleTrip('1', 'needs_manual_review')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UNKNOWN'), findsOneWidget);
    expect(find.text('NEEDS MANUAL REVIEW'), findsNothing);
  });

  testWidgets('renders empty state for active supplier trips', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SupplierTripsState.initial().copyWith(
          isLoading: false,
          trips: const <SupplierTrip>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No active trips yet'), findsOneWidget);
    expect(find.text('Open my loads'), findsOneWidget);

    await tester.tap(find.text('Open my loads'));
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });

  testWidgets('supplier trips completed empty-state action opens supplier trips route', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SupplierTripsState.initial().copyWith(
          isLoading: false,
          selectedTab: SupplierTripsTab.completed,
          trips: const <SupplierTrip>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No completed trips yet'), findsOneWidget);
    expect(find.text('View active trips'), findsOneWidget);

    await tester.tap(find.text('View active trips'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier trips route opened'), findsOneWidget);
  });

  testWidgets('renders error state for supplier trips', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        SupplierTripsState.initial().copyWith(
          isLoading: false,
          trips: const <SupplierTrip>[],
          failure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load supplier trips'), findsOneWidget);
    expect(
      find.text('We could not load your supplier trips right now. Retry shortly to refresh the latest trip list and statuses.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
