import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_trips_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_trips_provider.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _NoopTripsBackend implements TruckerTripsBackend {
  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String truckerId, required List<String> stages}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String truckerId, required String tripId}) async => null;

  @override
  Future<void> advanceTripStage({
    required String tripId,
    required String newStage,
    double? gpsLat,
    double? gpsLng,
  }) async {}

  @override
  Future<void> uploadTripProof({
    required String tripId,
    required String podPath,
    String? lrPath,
    double? gpsLat,
    double? gpsLng,
  }) async {}

  @override
  Future<Map<String, dynamic>?> uploadTripLr({
    required String tripId,
    required String lrPath,
  }) async => {'id': tripId};

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => null;

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async => null;
}

class _TestTruckerTripsController extends TruckerTripsController {
  _TestTruckerTripsController(TruckerTripsState initialState)
      : super(TruckerTripsRepository(_NoopTripsBackend(), () => 'trucker-1')) {
    state = initialState;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> selectTab(TruckerTripsTab tab) async {
    state = state.copyWith(selectedTab: tab);
  }
}

TruckerTrip _trip({String stage = 'in_transit'}) {
  return TruckerTrip(
    id: 'trip-1',
    loadId: 'load-1',
    routeLabel: 'Chandrapur, Maharashtra > Mumbai, Maharashtra',
    material: 'Coal',
    stage: stage,
    truckId: 'truck-1',
    truckNumber: 'MH12AB1234',
    assignedAt: DateTime(2026, 3, 8, 12),
    deliveredAt: stage == 'completed' ? DateTime(2026, 3, 10, 10) : null,
    podUploadedAt: stage == 'completed' ? DateTime(2026, 3, 10, 11) : null,
    completedAt: stage == 'completed' ? DateTime(2026, 3, 10, 12) : null,
    hasLrProof: false,
    hasPodProof: stage == 'completed',
  );
}

Widget _buildApp(TruckerTripsState state) {
  return ProviderScope(
    overrides: [
      truckerTripsProvider.overrideWith((ref) => _TestTruckerTripsController(state)),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TruckerTripsScreen()),
    ),
  );
}

Widget _buildRoutedApp(TruckerTripsState state) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, routeState) => const Scaffold(body: TruckerTripsScreen()),
      ),
      GoRoute(
        path: AppRoutes.findLoadsPath,
        builder: (context, routeState) => const Scaffold(body: Text('Find loads opened')),
      ),
      GoRoute(
        path: AppRoutes.tripsPath,
        builder: (context, routeState) => const Scaffold(body: Text('Trips route opened')),
      ),
      GoRoute(
        path: '${AppRoutes.tripDetailPath}/:tripId',
        builder: (context, routeState) => Scaffold(
          body: Text('Trip detail opened: ${routeState.pathParameters['tripId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      truckerTripsProvider.overrideWith((ref) => _TestTruckerTripsController(state)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

String _expectedLocalizedTripTimeContext(WidgetTester tester, TruckerTrip trip) {
  final context = tester.element(find.byType(TruckerTripsScreen).first);
  final l10n = AppLocalizations.of(context);
  final material = MaterialLocalizations.of(context);
  String formatDate(DateTime value) => material.formatShortDate(value.toLocal());
  if (trip.completedAt != null && trip.stage == 'completed') {
    return l10n.truckerTripsTimeContextCompleted(formatDate(trip.completedAt!));
  }
  if (trip.podUploadedAt != null && trip.stage == 'proof_submitted') {
    return l10n.truckerTripsTimeContextPodUploaded(formatDate(trip.podUploadedAt!));
  }
  if (trip.deliveredAt != null && trip.stage == 'delivered') {
    return l10n.truckerTripsTimeContextDelivered(formatDate(trip.deliveredAt!));
  }
  return l10n.truckerTripsTimeContextAssigned(formatDate(trip.assignedAt));
}

void main() {
  testWidgets('renders trucker trips success state', (tester) async {
    final trip = _trip();
    await tester.pumpWidget(
      _buildApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: [trip],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My trips'), findsOneWidget);
    expect(find.text('Chandrapur, Maharashtra > Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('IN TRANSIT'), findsOneWidget);
    expect(find.text('Coal - Proof pending'), findsOneWidget);
    expect(find.text(_expectedLocalizedTripTimeContext(tester, trip)), findsOneWidget);
    expect(find.text('Truck MH12AB1234'), findsOneWidget);
  });

  testWidgets('renders completed trips list', (tester) async {
    final trip = _trip(stage: 'completed');
    await tester.pumpWidget(
      _buildApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: [trip],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My trips'), findsOneWidget);
    expect(find.text('Chandrapur, Maharashtra > Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('Coal - POD uploaded'), findsOneWidget);
    expect(find.text(_expectedLocalizedTripTimeContext(tester, trip)), findsOneWidget);
    expect(find.text('Truck MH12AB1234'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: const <TruckerTrip>[],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No trips yet'), findsOneWidget);
    expect(find.textContaining('Book a load'), findsOneWidget);
  });

  testWidgets('trucker trips active empty-state action opens find loads route', (tester) async {
    await tester.pumpWidget(
      _buildRoutedApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: const <TruckerTrip>[],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No trips yet'), findsOneWidget);
    expect(find.text('Find loads'), findsOneWidget);

    await tester.tap(find.text('Find loads'));
    await tester.pumpAndSettle();

    expect(find.text('Find loads opened'), findsOneWidget);
  });

  testWidgets('trucker trips completed empty-state action opens trips route', (tester) async {
    await tester.pumpWidget(
      _buildRoutedApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          selectedTab: TruckerTripsTab.completed,
          trips: const <TruckerTrip>[],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No completed trips yet'), findsOneWidget);
    expect(find.text('View active trips'), findsOneWidget);

    await tester.tap(find.text('View active trips'));
    await tester.pumpAndSettle();

    expect(find.text('Trips route opened'), findsOneWidget);
  });

  testWidgets('renders active trips list', (tester) async {
    final trip = _trip(stage: 'in_transit');
    await tester.pumpWidget(
      _buildApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: [trip],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My trips'), findsOneWidget);
    expect(find.text('Chandrapur, Maharashtra > Mumbai, Maharashtra'), findsOneWidget);
    expect(find.text('IN TRANSIT'), findsOneWidget);
    expect(find.text('Coal - Proof pending'), findsOneWidget);
    expect(find.text('Truck MH12AB1234'), findsOneWidget);
  });

  testWidgets('renders unknown fallback for unsupported trucker trip stage', (tester) async {
    final trip = _trip(stage: 'needs_manual_review');
    await tester.pumpWidget(
      _buildApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: [trip],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('UNKNOWN'), findsOneWidget);
    expect(find.text('Needs Manual Review'), findsNothing);
  });

  testWidgets('trucker trips trip card opens trip detail route', (tester) async {
    final trip = _trip(stage: 'in_transit');
    await tester.pumpWidget(
      _buildRoutedApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: [trip],
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chandrapur, Maharashtra > Mumbai, Maharashtra'), findsOneWidget);

    await tester.tap(find.text('Chandrapur, Maharashtra > Mumbai, Maharashtra'));
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: trip-1'), findsOneWidget);
  });

  testWidgets('renders error state', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerTripsState.initial().copyWith(
          isLoading: false,
          trips: const <TruckerTrip>[],
          failure: const UnknownFailure(message: 'boom'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load trips'), findsOneWidget);
    expect(
      find.text('We could not load your trips right now. Retry shortly to refresh the latest execution timeline.'),
      findsOneWidget,
    );
  });
}
