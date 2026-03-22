import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/shell/presentation/supplier_shell_screens.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/load_detail_provider.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

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
  Future<List<Map<String, dynamic>>> fetchMyLoads({required String supplierId, required LoadFilters filters, required int page, required int pageSize}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {}
}

class _TestLoadDetailController extends LoadDetailController {
  final LoadDetailState _testState;

  _TestLoadDetailController(this._testState)
      : super(
          SupplierLoadRepository(_NoopSupplierLoadBackend(), () => 'supplier-1'),
          _testState.loadId,
        ) {
    state = _testState;
  }

  @override
  Future<void> load() async {}

  @override
  Future<Result<void>> cancelLoad() async => const Success<void>(null);

  @override
  Future<Result<void>> closeFilledOutsideApp() async => const Success<void>(null);

  @override
  Future<Result<String>> approveBookingRequest(String bookingId) async => const Success<String>('trip-1');

  @override
  Future<Result<void>> rejectBookingRequest(String bookingId, {String? reason}) async => const Success<void>(null);
}

Widget _buildApp(LoadDetailState state) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: SupplierLoadDetailScreen(loadId: 'load-1')),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads opened')),
      ),
      GoRoute(
        path: '${AppRoutes.tripDetailPath}/:tripId',
        builder: (context, state) => Scaffold(body: Text('Trip detail opened: ${state.pathParameters['tripId']}')),
      ),
      GoRoute(
        path: AppRoutes.reportIssuePath,
        builder: (context, state) => const Scaffold(body: Text('Report issue opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      loadDetailProvider('load-1').overrideWith((ref) => _TestLoadDetailController(state)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

LoadDetailState _successState() {
  return LoadDetailState(
    loadId: 'load-1',
    detail: LoadDetail(
      summary: Load(
        id: 'load-1',
        originLabel: 'Chandrapur, Maharashtra',
        destinationLabel: 'Mumbai, Maharashtra',
        material: 'Coal',
        weightTonnes: 22,
        trucksNeeded: 2,
        trucksBooked: 1,
        priceAmount: 54000,
        priceType: 'negotiable',
        pickupDate: DateTime(2026, 3, 10),
        status: 'assigned_partial',
        requiredBodyType: 'Open',
        requiredTyres: const [10, 12],
        isSuperLoad: false,
        superStatus: 'none',
        publishedAt: DateTime(2026, 3, 8, 10),
      ),
      originCity: 'Chandrapur',
      originState: 'Maharashtra',
      originLat: null,
      originLng: null,
      destinationCity: 'Mumbai',
      destinationState: 'Maharashtra',
      destinationLat: null,
      destinationLng: null,
      routeDistanceKm: 825.5,
      routeDurationMinutes: 900,
      routePolyline: null,
      routeSnapshotSource: null,
      parentLoadId: null,
      assignedTruckerId: null,
      assignedTruckId: null,
      createdAt: DateTime(2026, 3, 8, 9),
      updatedAt: DateTime(2026, 3, 9, 14),
      bookingRequest: null,
      linkedTrips: const <LinkedTrip>[],
    ),
    bookingRequests: <LoadBookingRequest>[
      LoadBookingRequest(
        id: 'booking-1',
        loadId: 'load-1',
        truckerId: 'trucker-1',
        truckId: 'truck-1',
        status: 'approved',
        decisionReason: 'Matched truck and timing confirmed',
        createdAt: DateTime(2026, 3, 8, 11),
        decidedAt: DateTime(2026, 3, 8, 12),
        truckerName: 'Ravi Trucker',
        truckerVerificationStatus: 'verified',
        truckerRating: 4.8,
        truckNumber: 'MH12AB1234',
        truckBodyType: 'Open',
        truckTyres: 12,
        truckModelLabel: 'Tata Signa',
      ),
    ],
    linkedTrips: <LinkedTrip>[
      LinkedTrip(
        id: 'trip-1',
        loadId: 'load-1',
        parentLoadId: null,
        routeLabel: 'Chandrapur, Maharashtra → Mumbai, Maharashtra',
        material: 'Coal',
        stage: 'in_transit',
        truckerId: 'trucker-1',
        truckId: 'truck-1',
        assignedAt: DateTime(2026, 3, 8, 13),
        deliveredAt: null,
        podUploadedAt: null,
        completedAt: null,
        hasLrProof: false,
        hasPodProof: false,
      ),
    ],
    isLoading: false,
    isCancelling: false,
    isClosingFilledOutsideApp: false,
    approvingBookingId: null,
    rejectingBookingId: null,
    failure: null,
    actionFailure: null,
  );
}

LoadDetailState _successStateWithBookingStatus(String bookingStatus) {
  final state = _successState();
  final booking = state.bookingRequests.first;
  return state.copyWith(
    bookingRequests: <LoadBookingRequest>[
      LoadBookingRequest(
        id: booking.id,
        loadId: booking.loadId,
        truckerId: booking.truckerId,
        truckId: booking.truckId,
        status: bookingStatus,
        decisionReason: booking.decisionReason,
        createdAt: booking.createdAt,
        decidedAt: booking.decidedAt,
        truckerName: booking.truckerName,
        truckerVerificationStatus: booking.truckerVerificationStatus,
        truckerRating: booking.truckerRating,
        truckNumber: booking.truckNumber,
        truckBodyType: booking.truckBodyType,
        truckTyres: booking.truckTyres,
        truckModelLabel: booking.truckModelLabel,
      ),
    ],
  );
}

LoadDetailState _successStateWithLoadStatus(String loadStatus) {
  final state = _successState();
  final summary = state.detail!.summary;
  return state.copyWith(
    detail: LoadDetail(
      summary: Load(
        id: summary.id,
        originLabel: summary.originLabel,
        destinationLabel: summary.destinationLabel,
        material: summary.material,
        weightTonnes: summary.weightTonnes,
        trucksNeeded: summary.trucksNeeded,
        trucksBooked: summary.trucksBooked,
        priceAmount: summary.priceAmount,
        priceType: summary.priceType,
        pickupDate: summary.pickupDate,
        status: loadStatus,
        requiredBodyType: summary.requiredBodyType,
        requiredTyres: summary.requiredTyres,
        isSuperLoad: summary.isSuperLoad,
        superStatus: summary.superStatus,
        publishedAt: summary.publishedAt,
      ),
      originCity: state.detail!.originCity,
      originState: state.detail!.originState,
      originLat: state.detail!.originLat,
      originLng: state.detail!.originLng,
      destinationCity: state.detail!.destinationCity,
      destinationState: state.detail!.destinationState,
      destinationLat: state.detail!.destinationLat,
      destinationLng: state.detail!.destinationLng,
      routeDistanceKm: state.detail!.routeDistanceKm,
      routeDurationMinutes: state.detail!.routeDurationMinutes,
      routePolyline: state.detail!.routePolyline,
      routeSnapshotSource: state.detail!.routeSnapshotSource,
      parentLoadId: state.detail!.parentLoadId,
      assignedTruckerId: state.detail!.assignedTruckerId,
      assignedTruckId: state.detail!.assignedTruckId,
      createdAt: state.detail!.createdAt,
      updatedAt: state.detail!.updatedAt,
      bookingRequest: state.detail!.bookingRequest,
      linkedTrips: state.detail!.linkedTrips,
    ),
  );
}

LoadDetailState _notFoundState() {
  return const LoadDetailState(
    loadId: 'load-1',
    detail: null,
    bookingRequests: <LoadBookingRequest>[],
    linkedTrips: <LinkedTrip>[],
    isLoading: false,
    isCancelling: false,
    isClosingFilledOutsideApp: false,
    approvingBookingId: null,
    rejectingBookingId: null,
    failure: NotFoundFailure(message: 'load not found'),
    actionFailure: null,
  );
}

LoadDetailState _failureState() {
  return const LoadDetailState(
    loadId: 'load-1',
    detail: null,
    bookingRequests: <LoadBookingRequest>[],
    linkedTrips: <LinkedTrip>[],
    isLoading: false,
    isCancelling: false,
    isClosingFilledOutsideApp: false,
    approvingBookingId: null,
    rejectingBookingId: null,
    failure: UnknownFailure(message: 'PostgrestException: leaked supplier debug detail'),
    actionFailure: null,
  );
}

void main() {
  testWidgets('renders localized supplier load detail success status surfaces', (tester) async {
    await tester.pumpWidget(_buildApp(_successState()));
    await tester.pumpAndSettle();

    expect(find.text('Current status: Assigned partial'), findsOneWidget);
    expect(find.text('1/2 trucks booked'), findsOneWidget);
    expect(find.textContaining('Coal • ₹54000 • Negotiable'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('IN TRANSIT'), findsOneWidget);

    final trackTripAction = find.text('Track trip');

    await tester.scrollUntilVisible(
      trackTripAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(trackTripAction);
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: trip-1'), findsOneWidget);
  });

  testWidgets('supplier load detail falls back to unknown for unsupported booking status', (tester) async {
    await tester.pumpWidget(_buildApp(_successStateWithBookingStatus('needs_manual_review')));
    await tester.pumpAndSettle();

    expect(find.text('UNKNOWN'), findsOneWidget);
    expect(find.text('NEEDS MANUAL REVIEW'), findsNothing);
  });

  testWidgets('supplier load detail falls back to unknown for unsupported load status', (tester) async {
    await tester.pumpWidget(_buildApp(_successStateWithLoadStatus('needs_manual_review')));
    await tester.pumpAndSettle();

    expect(find.text('Current status: Unknown'), findsOneWidget);
    expect(find.text('NEEDS MANUAL REVIEW'), findsNothing);
  });

  testWidgets('renders sanitized localized supplier load detail failure state', (tester) async {
    await tester.pumpWidget(_buildApp(_failureState()));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load load detail'), findsOneWidget);
    expect(
      find.text(
        'Could not load this load detail. Please try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked supplier debug detail'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('supplier load detail linked-trip card opens trip detail', (tester) async {
    await tester.pumpWidget(_buildApp(_successState()));
    await tester.pumpAndSettle();

    final linkedTripRouteLabel = find.text('Chandrapur, Maharashtra → Mumbai, Maharashtra').last;

    await tester.scrollUntilVisible(
      linkedTripRouteLabel,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(linkedTripRouteLabel);
    await tester.pumpAndSettle();

    expect(find.text('Trip detail opened: trip-1'), findsOneWidget);
  });

  testWidgets('supplier load detail report action opens report issue route with load context', (tester) async {
    Object? receivedExtra;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: SupplierLoadDetailScreen(loadId: 'load-1')),
        ),
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) {
            receivedExtra = state.extra;
            return const Scaffold(body: Text('Report issue opened'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loadDetailProvider('load-1').overrideWith((ref) => _TestLoadDetailController(_successState())),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reportIssueAction = find.text('Report spam or abuse');

    await tester.scrollUntilVisible(
      reportIssueAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(reportIssueAction);
    await tester.pumpAndSettle();

    expect(find.text('Report issue opened'), findsOneWidget);
    expect(receivedExtra, isA<ReportIssueContext>());
    final contextData = receivedExtra! as ReportIssueContext;
    expect(contextData.initialCategory, 'spam_or_scam');
    expect(contextData.relatedLoadId, 'load-1');
    expect(contextData.relatedTripId, '');
  });

  testWidgets('supplier load detail not-found action opens my loads', (tester) async {
    await tester.pumpWidget(_buildApp(_notFoundState()));
    await tester.pumpAndSettle();

    expect(find.text('Load not found'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });
}
