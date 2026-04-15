import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/features/trucker/data/diesel_price_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trip_gps_capture_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_share_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_profile_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_load_detail_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_providers.dart';

class _ScreenTruckerLoadDetailBackend implements TruckerLoadDetailBackend {
  final bool noApprovedTrucks;
  final Object? loadDetailError;
  final List<Map<String, dynamic>> bookingRequestRows;
  final bool missingLoad;
  final String priceType;
  final String status;

  _ScreenTruckerLoadDetailBackend({
    this.noApprovedTrucks = false,
    this.loadDetailError,
    this.bookingRequestRows = const <Map<String, dynamic>>[],
    this.missingLoad = false,
    this.priceType = 'negotiable',
    this.status = 'active',
  });

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail(String loadId) async {
    if (loadDetailError != null) {
      throw loadDetailError!;
    }
    if (missingLoad) {
      return null;
    }
    return {
      'id': 'load-1',
      'supplier_id': 'supplier-1',
      'parent_load_id': null,
      'origin_label': 'Chandrapur, Maharashtra',
      'origin_city': 'Chandrapur',
      'origin_state': 'Maharashtra',
      'origin_lat': 19.95,
      'origin_lng': 79.30,
      'destination_label': 'Mumbai, Maharashtra',
      'destination_city': 'Mumbai',
      'destination_state': 'Maharashtra',
      'destination_lat': 19.07,
      'destination_lng': 72.87,
      'route_distance_km': 820,
      'route_duration_minutes': 780,
      'route_polyline': null,
      'route_snapshot_source': 'osrm',
      'material': 'Coal',
      'weight_tonnes': 22,
      'required_body_type': 'Open',
      'required_tyres': [10, 12],
      'trucks_needed': 2,
      'trucks_booked': 1,
      'price_amount': 54000,
      'price_type': priceType,
      'advance_percentage': 30,
      'pickup_date': '2026-03-12',
      'status': status,
      'is_super_load': true,
      'super_status': 'active',
      'assigned_trucker_id': null,
      'assigned_truck_id': null,
      'published_at': '2026-03-08T12:00:00.000Z',
      'created_at': '2026-03-08T12:00:00.000Z',
      'updated_at': '2026-03-08T13:00:00.000Z',
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => {
        'id': 'supplier-1',
        'company_name': 'Amit Logistics',
      };

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => {
        'id': 'supplier-1',
        'full_name': 'Amit Supplier',
        'verification_status': 'verified',
      };

  @override
  Future<List<Map<String, dynamic>>> fetchApprovedTrucks(String truckerId) async {
    if (noApprovedTrucks) {
      return const <Map<String, dynamic>>[];
    }
    return [
      {
        'id': 'truck-match',
        'truck_number': 'MH12AB1234',
        'body_type': 'Open',
        'tyres': 12,
        'capacity_tonnes': 25,
        'truck_models': {
          'axles': 4,
          'payload_kg': 25000,
          'mileage_empty_kmpl': 5.0,
          'mileage_loaded_kmpl': 3.0,
        },
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests(String truckerId, String loadId) async => bookingRequestRows;

  @override
  Future<String> submitBookingRequest(
    String loadId,
    String truckId, {
    double? bookingGpsLat,
    double? bookingGpsLng,
  }) async => 'booking-1';
}

TripGpsCaptureService _gpsService() {
  return TripGpsCaptureService(
    isLocationServiceEnabledFn: () async => true,
    checkPermissionFn: () async => LocationPermission.whileInUse,
    requestPermissionFn: () async => LocationPermission.whileInUse,
    getCurrentPositionFn: () async => Position(
      longitude: 79.30,
      latitude: 19.95,
      timestamp: DateTime(2026, 3, 10, 23),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 1,
      heading: 0,
      headingAccuracy: 1,
      speed: 0,
      speedAccuracy: 1,
    ),
  );
}

class _ScreenChatBackend implements ChatBackend {
  String createConversationResult = 'conversation-1';
  String? lastSupplierId;
  String? lastTruckerId;
  String? lastLoadId;

  @override
  Future<String> createOrGetConversation({required String supplierId, required String truckerId, required String loadId}) async {
    lastSupplierId = supplierId;
    lastTruckerId = truckerId;
    lastLoadId = loadId;
    return createConversationResult;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchConversations({required String userId, required AppUserRole role}) async => throw UnimplementedError();

  @override
  Stream<List<Map<String, dynamic>>> watchConversations({required String userId, required AppUserRole role}) => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> fetchMessages({required String conversationId}) async => throw UnimplementedError();

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({required String conversationId}) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchLatestMessage({required String conversationId}) async => throw UnimplementedError();

  @override
  Future<bool> fetchHasUnread({required String conversationId, required String currentUserId}) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchLoadContext(String loadId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchProfile(String profileId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>?> fetchBookingContext({required String loadId, required String truckerId}) async => throw UnimplementedError();

  @override
  Future<Object?> fetchConversation(String conversationId) async => throw UnimplementedError();

  @override
  Future<String> sendMessage({required String conversationId, required ChatMessageType type, String? messageId, String? textBody, String? attachmentPath, Map<String, dynamic>? structuredPayload}) async => throw UnimplementedError();

  @override
  Future<void> markMessagesRead({required String conversationId, required String readerId}) async => throw UnimplementedError();

  @override
  Future<int> fetchUnreadConversationCount() async => throw UnimplementedError();
}

Widget _buildApp({
  bool verified = true,
  bool noApprovedTrucks = false,
  ChatRepository? chatRepository,
  List<Map<String, dynamic>> bookingRequestRows = const <Map<String, dynamic>>[],
  String priceType = 'negotiable',
  String status = 'active',
}) {
  return ProviderScope(
    overrides: [
      truckerLoadDetailRepositoryProvider.overrideWithValue(
        TruckerLoadDetailRepository(
          _ScreenTruckerLoadDetailBackend(
            noApprovedTrucks: noApprovedTrucks,
            bookingRequestRows: bookingRequestRows,
            priceType: priceType,
            status: status,
          ),
          () => 'trucker-1',
        ),
      ),
      truckerProfileProvider.overrideWith(
        (ref) async => TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919999999999',
          email: 'ravi@example.com',
          verificationStatus: verified ? 'verified' : 'pending',
          dlNumber: 'DL-0099',
          rating: 4.8,
          totalTrips: 20,
          completedTrips: 18,
          totalTrucks: noApprovedTrucks ? 0 : 1,
          approvedTrucks: noApprovedTrucks ? 0 : 1,
        ),
      ),
      dieselPriceMapProvider.overrideWith((ref) async => {'maharashtra': 92.5}),
      tripGpsCaptureServiceProvider.overrideWithValue(_gpsService()),
      truckerLoadShareServiceProvider.overrideWithValue(
        TruckerLoadShareService(
          canLaunchUrlFn: (_) async => true,
          launchUrlFn: (_) async => true,
          shareSystemTextFn: (_, subject) async {},
        ),
      ),
      if (chatRepository != null) chatRepositoryProvider.overrideWithValue(chatRepository),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TruckerLoadDetailScreen(loadId: 'load-1'),
    ),
  );
}

Widget _buildRoutedApp({
  required ChatRepository chatRepository,
  bool verified = true,
  bool noApprovedTrucks = false,
  bool missingLoad = false,
}) {
  final router = GoRouter(
    initialLocation: '${AppRoutes.loadDetailPath}/load-1',
    routes: [
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, state) => TruckerLoadDetailScreen(loadId: state.pathParameters['loadId'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.chatPath}/:conversationId',
        builder: (context, state) => Scaffold(
          body: Text('Chat ${state.pathParameters['conversationId'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
      ),
      GoRoute(
        path: AppRoutes.findLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('Find loads opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      truckerLoadDetailRepositoryProvider.overrideWithValue(
        TruckerLoadDetailRepository(
          _ScreenTruckerLoadDetailBackend(
            noApprovedTrucks: noApprovedTrucks,
            missingLoad: missingLoad,
          ),
          () => 'trucker-1',
        ),
      ),
      truckerProfileProvider.overrideWith(
        (ref) async => TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919999999999',
          email: 'ravi@example.com',
          verificationStatus: verified ? 'verified' : 'pending',
          dlNumber: 'DL-0099',
          rating: 4.8,
          totalTrips: 20,
          completedTrips: 18,
          totalTrucks: noApprovedTrucks ? 0 : 1,
          approvedTrucks: noApprovedTrucks ? 0 : 1,
        ),
      ),
      dieselPriceMapProvider.overrideWith((ref) async => {'maharashtra': 92.5}),
      tripGpsCaptureServiceProvider.overrideWithValue(_gpsService()),
      truckerLoadShareServiceProvider.overrideWithValue(
        TruckerLoadShareService(
          canLaunchUrlFn: (_) async => true,
          launchUrlFn: (_) async => true,
          shareSystemTextFn: (_, subject) async {},
        ),
      ),
      chatRepositoryProvider.overrideWithValue(chatRepository),
      currentAuthStateProvider.overrideWithValue(
        const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
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

void main() {
  testWidgets('renders sanitized freight detail failure copy', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          truckerLoadDetailRepositoryProvider.overrideWithValue(
            TruckerLoadDetailRepository(
              _ScreenTruckerLoadDetailBackend(loadDetailError: Exception('PostgrestException: leaked detail')),
              () => 'trucker-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TruckerLoadDetailScreen(loadId: 'load-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load freight detail'), findsOneWidget);
    expect(
      find.text('We could not load this freight detail right now. Retry shortly to refresh the current route, pricing, and booking context.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('renders trucker load detail success state', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Load Detail'), findsOneWidget);
    expect(find.text('Route and price summary'), findsOneWidget);
    expect(find.text('₹54000 - Per Ton'), findsOneWidget);
    expect(find.text('Price: ₹54000 - Per Ton'), findsOneWidget);
    expect(find.text('Truck requirement summary'), findsOneWidget);
    expect(find.text('Trip cost estimate'), findsOneWidget);
    expect(find.text('Book This Load'), findsOneWidget);
    expect(find.text('Share load'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Supplier summary'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier summary'), findsOneWidget);
    expect(find.text('Truck match available'), findsWidgets);
    expect(find.text('Using MH12AB1234'), findsOneWidget);
    expect(find.textContaining('This load will be booked with MH12AB1234'), findsOneWidget);
  });

  testWidgets('renders localized latest booking status on trucker load detail', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        bookingRequestRows: const [
          {
            'id': 'booking-1',
            'truck_id': 'truck-match',
            'status': 'approved',
            'decision_reason': 'Supplier confirmed the selected truck.',
            'created_at': '2026-03-10T09:00:00.000Z',
            'decided_at': '2026-03-10T09:30:00.000Z',
          },
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Next step'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking status: Approved'), findsOneWidget);
    expect(find.text('Supplier confirmed the selected truck.'), findsOneWidget);
  });

  testWidgets('renders neutral fallback for unknown booking status on trucker load detail', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        bookingRequestRows: const [
          {
            'id': 'booking-unknown-1',
            'truck_id': 'truck-match',
            'status': 'needs_manual_review',
            'decision_reason': 'Supplier asked support to verify this booking manually.',
            'created_at': '2026-03-10T09:00:00.000Z',
            'decided_at': null,
          },
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Next step'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking status: Unknown'), findsOneWidget);
    expect(find.text('Needs manual review'), findsNothing);
    expect(find.text('Supplier asked support to verify this booking manually.'), findsOneWidget);
  });

  testWidgets('trucker load detail falls back to unknown for unsupported price type', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(priceType: 'partner_negotiated'),
    );
    await tester.pumpAndSettle();

    expect(find.text('₹54000 - Unknown'), findsOneWidget);
    expect(find.text('Price: ₹54000 - Unknown'), findsOneWidget);
    expect(find.text('Partner Negotiated'), findsNothing);
  });

  testWidgets('trucker load detail falls back to unknown for unsupported load status', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(status: 'assigned_full'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('Assigned full'), findsNothing);
  });

  testWidgets('trucker load detail prompts truckers to add an approved truck before booking', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(noApprovedTrucks: true),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Booking is blocked'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking is blocked'), findsOneWidget);
    expect(find.text('Add and approve at least one truck before booking this load or unlocking supplier chat.'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Chat unavailable:'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat unavailable:'), findsOneWidget);
    expect(
      find.text('Chat unavailable: Add and approve at least one truck before booking this load or unlocking supplier chat.'),
      findsOneWidget,
    );
    expect(find.text('Add a Truck First'), findsOneWidget);
  });

  testWidgets('blocked no-approved-trucks CTA opens fleet after confirmation', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final chatBackend = _ScreenChatBackend();
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );

    await tester.pumpWidget(
      _buildRoutedApp(
        chatRepository: chatRepository,
        noApprovedTrucks: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add a Truck First'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add a Truck First'));
    await tester.pumpAndSettle();

    expect(find.text('Open Fleet'), findsOneWidget);

    await tester.tap(find.text('Open Fleet'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet opened'), findsOneWidget);
  });

  testWidgets('load-detail not-found fallback opens find loads route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final chatBackend = _ScreenChatBackend();
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );

    await tester.pumpWidget(
      _buildRoutedApp(
        chatRepository: chatRepository,
        missingLoad: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Load not found'), findsOneWidget);
    expect(find.text('Back to find loads'), findsOneWidget);

    await tester.tap(find.text('Back to find loads'));
    await tester.pumpAndSettle();

    expect(find.text('Find loads opened'), findsOneWidget);
  });

  testWidgets('renders blocked booking guidance when unverified', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(_buildApp(verified: false));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Booking is blocked'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Booking is blocked'), findsOneWidget);
    expect(
      find.text('Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.textContaining('Chat unavailable:'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chat unavailable:'), findsOneWidget);
    expect(
      find.text('Chat unavailable: Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.'),
      findsOneWidget,
    );
  });

  testWidgets('starts or resumes supplier chat from load detail', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final chatBackend = _ScreenChatBackend()..createConversationResult = 'conversation-42';
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );

    await tester.pumpWidget(_buildRoutedApp(chatRepository: chatRepository));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Chat with supplier'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat with supplier'));
    await tester.pumpAndSettle();

    expect(chatBackend.lastSupplierId, 'supplier-1');
    expect(chatBackend.lastTruckerId, 'trucker-1');
    expect(chatBackend.lastLoadId, 'load-1');
    expect(find.text('Chat conversation-42'), findsOneWidget);
  });

  testWidgets('opens report issue route from load detail with load context', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final chatBackend = _ScreenChatBackend()..createConversationResult = 'conversation-42';
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );
    ReportIssueContext? receivedContext;

    final router = GoRouter(
      initialLocation: '${AppRoutes.loadDetailPath}/load-1',
      routes: [
        GoRoute(
          path: '${AppRoutes.loadDetailPath}/:loadId',
          builder: (context, state) => TruckerLoadDetailScreen(loadId: state.pathParameters['loadId'] ?? ''),
        ),
        GoRoute(
          path: '${AppRoutes.chatPath}/:conversationId',
          builder: (context, state) => Scaffold(
            body: Text('Chat ${state.pathParameters['conversationId'] ?? ''}'),
          ),
        ),
        GoRoute(
          path: AppRoutes.fleetPath,
          builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
        ),
        GoRoute(
          path: AppRoutes.findLoadsPath,
          builder: (context, state) => const Scaffold(body: Text('Find loads opened')),
        ),
        GoRoute(
          path: AppRoutes.reportIssuePath,
          builder: (context, state) {
            receivedContext = state.extra as ReportIssueContext?;
            return const Scaffold(body: Text('Report issue opened'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          truckerLoadDetailRepositoryProvider.overrideWithValue(
            TruckerLoadDetailRepository(
              _ScreenTruckerLoadDetailBackend(),
              () => 'trucker-1',
            ),
          ),
          truckerProfileProvider.overrideWith(
            (ref) async => TruckerProfile(
              id: 'trucker-1',
              fullName: 'Ravi Trucker',
              mobile: '+919999999999',
              email: 'ravi@example.com',
              verificationStatus: 'verified',
              dlNumber: 'DL-0099',
              rating: 4.8,
              totalTrips: 20,
              completedTrips: 18,
              totalTrucks: 1,
              approvedTrucks: 1,
            ),
          ),
          dieselPriceMapProvider.overrideWith((ref) async => {'maharashtra': 92.5}),
          tripGpsCaptureServiceProvider.overrideWithValue(_gpsService()),
          truckerLoadShareServiceProvider.overrideWithValue(
            TruckerLoadShareService(
              canLaunchUrlFn: (_) async => true,
              launchUrlFn: (_) async => true,
              shareSystemTextFn: (_, subject) async {},
            ),
          ),
          chatRepositoryProvider.overrideWithValue(chatRepository),
          currentAuthStateProvider.overrideWithValue(
            const AuthStateSnapshot(
              hasSession: true,
              role: AppUserRole.trucker,
              isBanned: false,
              isDeactivated: false,
              isProfileComplete: true,
              isResolved: true,
              profile: null,
            ),
          ),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Report spam or abuse'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report spam or abuse'));
    await tester.pumpAndSettle();

    expect(find.text('Report issue opened'), findsOneWidget);
    expect(receivedContext, isNotNull);
    expect(receivedContext!.initialCategory, 'spam_or_scam');
    expect(receivedContext!.relatedLoadId, 'load-1');
    expect(receivedContext!.relatedTripId, '');
    expect(receivedContext!.sourceLabel, contains('Chandrapur, Maharashtra'));
    expect(receivedContext!.sourceLabel, contains('Mumbai, Maharashtra'));
  });

  testWidgets('requires confirmation before submitting booking request', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Book This Load'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book This Load'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm load booking'), findsOneWidget);
    expect(
      find.text('Book Coal Chandrapur, Maharashtra > Mumbai, Maharashtra with MH12AB1234?'),
      findsOneWidget,
    );

    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Book This Load')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Load booked! Waiting for supplier approval'), findsOneWidget);
  });

  testWidgets('successful booking request shows success snackbar', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final chatBackend = _ScreenChatBackend();
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );

    await tester.pumpWidget(
      _buildRoutedApp(chatRepository: chatRepository),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Book This Load'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Book This Load'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Book This Load')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Load booked! Waiting for supplier approval'), findsOneWidget);
  });
}
