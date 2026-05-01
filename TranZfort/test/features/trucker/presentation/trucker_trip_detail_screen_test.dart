import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';
import 'package:tranzfort/src/shared/widgets/action_buttons.dart';
import 'package:tranzfort/src/features/communication/data/chat_repository.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_profile_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_providers.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_trip_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_trip_detail_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);

  Stream<AuthState> get authStateChanges => Stream.value(
        AuthState(
          AuthChangeEvent.signedIn,
          Session(
            accessToken: 'test-token',
            tokenType: 'bearer',
            user: User(
              id: 'test-user',
              email: 'test@test.com',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ),
      );

  Future<String?> get currentUserId async => 'test-user';

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> updatePreferredLanguage(String languageCode) async => const Success(null);
}

class _FakeAppLocaleController extends AppLocaleController {
  _FakeAppLocaleController()
      : super(_FakeAuthRepository(), profileLanguageCode: 'hi') {
    state = state.copyWith(
      locale: const Locale('hi'),
      isInitialized: true,
      clearFailure: true,
    );
  }
}

class _FakeContextualTtsService extends ContextualTtsService {
  _FakeContextualTtsService()
      : super(
          setLanguageFn: (_) async {},
          setSpeechRateFn: (_) async {},
          speakFn: (_) async {},
          stopFn: () async {},
          preferencesFn: SharedPreferences.getInstance as Future<SharedPreferences> Function(),
          getVoices: Future.value,
          setVoiceFn: (_) async {},
        );

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    return ContextualTtsOutcome.spoken;
  }
}

class _TripDetailBackend implements TruckerTripsBackend {
  final String stage;
  final String supplierVerificationStatus;
  final Map<String, dynamic>? ratingRow;
  final Object? tripDetailError;
  final bool omitDisputeSummary;
  final String disputeStatus;
  final String disputeCategory;
  final DateTime? podUploadedAtOverride;

  _TripDetailBackend({
    this.stage = 'delivered',
    this.supplierVerificationStatus = 'verified',
    this.ratingRow,
    this.tripDetailError,
    this.omitDisputeSummary = false,
    this.disputeStatus = 'in_progress',
    this.disputeCategory = 'document_mismatch',
    this.podUploadedAtOverride,
  });

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String truckerId, required List<String> stages, int limit = 15, int offset = 0}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => ratingRow;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String truckerId, required String tripId}) async {
    if (tripDetailError != null) {
      throw tripDetailError!;
    }
    return {
      'id': tripId,
      'load_id': 'load-1',
      'trucker_id': truckerId,
      'supplier_id': 'supplier-1',
      'truck_id': 'truck-1',
      'stage': stage,
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'started_at': stage == 'assigned' ? null : '2026-03-09T08:00:00.000Z',
      'delivered_at': stage == 'assigned' || stage == 'pickup_pending' || stage == 'picked_up' || stage == 'in_transit'
          ? null
          : '2026-03-10T10:00:00.000Z',
      'pod_uploaded_at': stage == 'proof_submitted' || stage == 'completed'
          ? (podUploadedAtOverride ?? DateTime(2026, 3, 10, 11)).toUtc().toIso8601String()
          : null,
      'completed_at': stage == 'completed' ? '2026-03-10T12:00:00.000Z' : null,
      'lr_document_path': null,
      'pod_document_path': stage == 'proof_submitted' || stage == 'completed' ? 'trip-1/pod.jpg' : null,
      'load_snapshot_summary': {
        'origin_label': 'Chandrapur, Maharashtra',
        'destination_label': 'Mumbai, Maharashtra',
        'material': 'Coal',
      },
      'loads': {
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
        'route_snapshot_source': 'osrm',
        'material': 'Coal',
        'pickup_date': '2026-03-12',
      },
      'trucks': {
        'truck_number': 'MH12AB1234',
        'body_type': 'Open',
        'tyres': 12,
      },
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetailWithSupplier({
    required String truckerId,
    required String tripId,
  }) async {
    if (tripDetailError != null) {
      throw tripDetailError!;
    }
    final detail = await fetchTripDetail(truckerId: truckerId, tripId: tripId);
    if (detail == null) return null;
    final supplierId = (detail['supplier_id'] ?? 'supplier-1').toString();
    return <String, dynamic>{
      'trip': detail,
      'supplier_profile': await fetchSupplierProfile(supplierId),
      'supplier_extension': await fetchSupplierExtension(supplierId),
      'dispute_summary': omitDisputeSummary ? null : await fetchTripDisputeSummary(tripId: tripId),
    };
  }

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
  Future<Map<String, dynamic>?> fetchSupplierExtension(String supplierId) async => {
        'id': supplierId,
        'company_name': 'Amit Logistics',
      };

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => {
        'id': supplierId,
        'full_name': 'Amit Supplier',
        'mobile': '+919876543210',
        'verification_status': supplierVerificationStatus,
      };

  @override
  Future<Map<String, dynamic>?> fetchTripDisputeSummary({required String tripId}) async {
    if (stage != 'disputed' || omitDisputeSummary) {
      return null;
    }
    return {
      'category': disputeCategory,
      'status': disputeStatus,
      'updated_at': '2026-03-11T10:30:00.000Z',
    };
  }
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
  Future<List<Map<String, dynamic>>> fetchMessagesPaginated({
    required String conversationId,
    int limit = 50,
    DateTime? beforeCreatedAt,
    String? beforeMessageId,
  }) async => throw UnimplementedError();

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

Widget _buildRoutedApp({required ChatRepository chatRepository, TruckerProfile? truckerProfile}) {
  final router = GoRouter(
    initialLocation: '${AppRoutes.tripDetailPath}/trip-1',
    routes: [
      GoRoute(
        path: '${AppRoutes.tripDetailPath}/:tripId',
        builder: (context, state) => TruckerTripDetailScreen(tripId: state.pathParameters['tripId'] ?? ''),
      ),
      GoRoute(
        path: '${AppRoutes.chatPath}/:conversationId',
        builder: (context, state) => Scaffold(
          body: Text('Chat ${state.pathParameters['conversationId'] ?? ''}'),
        ),
      ),
      GoRoute(
        path: AppRoutes.reportIssuePath,
        builder: (context, state) => const Scaffold(body: Text('Report issue opened')),
      ),
      GoRoute(
        path: AppRoutes.truckerVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Trucker verification opened')),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
      authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
      contextualTtsServiceProvider.overrideWithValue(_FakeContextualTtsService()),
      truckerTripsRepositoryProvider.overrideWithValue(
        TruckerTripsRepository(_TripDetailBackend(stage: 'in_transit'), () => 'trucker-1'),
      ),
      truckerProfileProvider.overrideWith((ref) async => truckerProfile ?? _verifiedTruckerProfile()),
      chatRepositoryProvider.overrideWithValue(chatRepository),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

TruckerProfile _verifiedTruckerProfile() {
  return const TruckerProfile(
    id: 'trucker-1',
    fullName: 'Ravi Trucker',
    mobile: '+919812345678',
    email: 'trucker@example.com',
    verificationStatus: 'verified',
    dlNumber: 'DL-12345',
    rating: 4.5,
    totalTrips: 10,
    completedTrips: 8,
    totalTrucks: 1,
    approvedTrucks: 1,
  );
}

Widget _buildPlainTripDetailApp(
  List<Override> overrides, {
  String tripId = 'trip-1',
}) {
  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
      authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
      contextualTtsServiceProvider.overrideWithValue(_FakeContextualTtsService()),
      truckerProfileProvider.overrideWith((ref) async => _verifiedTruckerProfile()),
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
      ...overrides,
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TruckerTripDetailScreen(tripId: tripId),
    ),
  );
}

void main() {
  testWidgets('renders sanitized trip detail failure copy', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(tripDetailError: Exception('PostgrestException: leaked detail')),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load trip detail'), findsOneWidget);
    expect(
      find.text('We could not load this trip detail right now. Retry shortly to refresh the latest trip status and actions.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('trucker trip-detail not-found fallback opens trips route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TruckerTripDetailScreen(tripId: 'trip-404'),
        ),
        GoRoute(
          path: AppRoutes.tripsPath,
          builder: (context, state) => const Scaffold(body: Text('Trips opened')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          truckerTripsRepositoryProvider.overrideWithValue(
            TruckerTripsRepository(
              _TripDetailBackend(tripDetailError: const NotFoundFailure()),
              () => 'trucker-1',
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

    expect(find.text('Trip not found'), findsOneWidget);
    expect(find.text('Back to my trips'), findsOneWidget);

    await tester.tap(find.text('Back to my trips'));
    await tester.pumpAndSettle();

    expect(find.text('Trips opened'), findsOneWidget);
  });

  testWidgets('renders trucker trip detail success state', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(_TripDetailBackend(), () => 'trucker-1'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip Detail'), findsOneWidget);
    expect(find.text('Next step'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.text('Awaiting POD'), findsOneWidget);
    expect(find.text('Upload POD'), findsOneWidget);
    expect(find.text('Upload POD Photo'), findsOneWidget);
    expect(find.text('Call Supplier'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Truck and supplier'), findsOneWidget);
    expect(find.text('Body type: Open'), findsOneWidget);
    expect(find.text('Supplier: Amit Supplier'), findsOneWidget);
  });

  testWidgets('renders neutral fallback for unknown trucker trip stage and supplier verification status', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(stage: 'handover_review', supplierVerificationStatus: 'needs_manual_review'),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Handover review'), findsNothing);
    expect(find.text('Needs manual review'), findsNothing);
  });

  testWidgets('renders optional LR upload action during pickup flow', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(_TripDetailBackend(stage: 'pickup_pending'), () => 'trucker-1'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upload LR (Optional)'), findsOneWidget);
  });

  testWidgets('renders localized proof review countdown duration', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(
              stage: 'proof_submitted',
              podUploadedAtOverride: DateTime.now().subtract(const Duration(hours: 1)),
            ),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delivery review countdown'), findsOneWidget);
    expect(find.textContaining('Auto-complete in:'), findsOneWidget);
  });

  testWidgets('renders trucker completed trip rating prompt', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(_TripDetailBackend(stage: 'completed'), () => 'trucker-1'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip summary'), findsOneWidget);
    expect(find.text('Rate this trip'), findsOneWidget);
    expect(find.text('Submit Rating'), findsOneWidget);
  });

  testWidgets('renders already rated state on completed trip', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(
              stage: 'completed',
              ratingRow: {
                'id': 'rating-1',
                'score': 4,
                'comment': 'Smooth unload',
                'created_at': '2026-03-10T13:00:00.000Z',
              },
            ),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('You already rated this trip.'), findsOneWidget);
    expect(find.text('Smooth unload'), findsOneWidget);
  });

  testWidgets('renders disputed trip status card', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TruckerTripDetailScreen(tripId: 'trip-1'),
        ),
        GoRoute(
          path: AppRoutes.supportPath,
          builder: (context, state) => const Scaffold(body: Text('Support opened')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          truckerTripsRepositoryProvider.overrideWithValue(
            TruckerTripsRepository(_TripDetailBackend(stage: 'disputed'), () => 'trucker-1'),
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

    expect(find.text('Dispute in progress'), findsWidgets);
    expect(find.text('Dispute status'), findsOneWidget);
    expect(find.text('Current state: In progress'), findsOneWidget);
    expect(find.text('Category: Document mismatch'), findsOneWidget);
    expect(
      find.text('Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.'),
      findsOneWidget,
    );
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'),
      findsOneWidget,
    );
    expect(
      find.text('If additional supporting proofs are not attached in the current single-image flow, keep the related support replies clear so support and operations know what else to review.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Support'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('renders trucker disputed-stage fallback summary when dispute summary is unavailable', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(stage: 'disputed', omitDisputeSummary: true),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute in progress'), findsWidgets);
    expect(find.text('Dispute status'), findsOneWidget);
    expect(find.text('Current state: Dispute raised'), findsOneWidget);
    expect(find.text('Category: Document mismatch'), findsNothing);
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'),
      findsOneWidget,
    );
  });

  testWidgets('renders trucker waiting-for-user dispute banner copy', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(stage: 'disputed', disputeStatus: 'waiting_for_user'),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute waiting for your reply'), findsOneWidget);
    expect(
      find.text('A dispute has been raised on this trip under Document mismatch and is waiting on your clarification or proof. Sensitive evidence may remain restricted during review.'),
      findsOneWidget,
    );
  });

  testWidgets('renders trucker resolved dispute banner copy', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(stage: 'disputed', disputeStatus: 'resolved'),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute review closed'), findsOneWidget);
    expect(
      find.text('A dispute raised on this trip under Document mismatch has reached a final review outcome. Recorded status updates remain visible, while sensitive evidence may remain restricted.'),
      findsOneWidget,
    );
    expect(
      find.text('This dispute has reached a final review state. Keep this trip detail for the recorded outcome and start a fresh follow-up only if a genuinely new issue appears.'),
      findsOneWidget,
    );
    expect(
      find.text('Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.'),
      findsOneWidget,
    );
    expect(
      find.text('If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.'),
      findsOneWidget,
    );
  });

  testWidgets('renders trucker in-progress dispute coverage for damage-or-shortage category', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(stage: 'disputed', disputeCategory: 'damage_or_shortage'),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category: Damage or shortage'), findsOneWidget);
    expect(find.text('Dispute in progress'), findsWidgets);
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'),
      findsOneWidget,
    );
    expect(
      find.text('If additional supporting proofs are not attached in the current single-image flow, keep the related support replies clear so support and operations know what else to review.'),
      findsOneWidget,
    );
  });

  testWidgets('renders trucker resolved dispute banner copy for non-payment category', (tester) async {
    await tester.pumpWidget(
      _buildPlainTripDetailApp([
        truckerTripsRepositoryProvider.overrideWithValue(
          TruckerTripsRepository(
            _TripDetailBackend(
              stage: 'disputed',
              disputeStatus: 'resolved',
              disputeCategory: 'non_payment',
            ),
            () => 'trucker-1',
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute review closed'), findsOneWidget);
    expect(
      find.text('A dispute raised on this trip under Non-payment has reached a final review outcome. Recorded status updates remain visible, while sensitive evidence may remain restricted.'),
      findsOneWidget,
    );
  });

  testWidgets('renders cancelled trip summary card', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
          contextualTtsServiceProvider.overrideWithValue(_FakeContextualTtsService()),
          truckerTripsRepositoryProvider.overrideWithValue(
            TruckerTripsRepository(_TripDetailBackend(stage: 'cancelled'), () => 'trucker-1'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TruckerTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip cancelled'), findsWidgets);
    expect(find.text('Cancellation summary'), findsOneWidget);
    expect(find.textContaining('Current state: cancelled'), findsOneWidget);
  });

  testWidgets('starts or resumes supplier chat from trip detail', (tester) async {
    final chatBackend = _ScreenChatBackend()..createConversationResult = 'conversation-42';
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );

    await tester.pumpWidget(_buildRoutedApp(chatRepository: chatRepository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Chat with supplier'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat with supplier'));
    await tester.pumpAndSettle();

    expect(chatBackend.lastSupplierId, 'supplier-1');
    expect(chatBackend.lastTruckerId, 'trucker-1');
    expect(chatBackend.lastLoadId, 'load-1');
    expect(find.text('Chat conversation-42'), findsOneWidget);
  });

  testWidgets('opens report issue route from trip detail with trip context', (tester) async {
    final chatBackend = _ScreenChatBackend()..createConversationResult = 'conversation-42';
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );
    ReportIssueContext? receivedContext;

    final router = GoRouter(
      initialLocation: '${AppRoutes.tripDetailPath}/trip-1',
      routes: [
        GoRoute(
          path: '${AppRoutes.tripDetailPath}/:tripId',
          builder: (context, state) => TruckerTripDetailScreen(tripId: state.pathParameters['tripId'] ?? ''),
        ),
        GoRoute(
          path: '${AppRoutes.chatPath}/:conversationId',
          builder: (context, state) => Scaffold(
            body: Text('Chat ${state.pathParameters['conversationId'] ?? ''}'),
          ),
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
          appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
          contextualTtsServiceProvider.overrideWithValue(_FakeContextualTtsService()),
          truckerTripsRepositoryProvider.overrideWithValue(
            TruckerTripsRepository(_TripDetailBackend(stage: 'in_transit'), () => 'trucker-1'),
          ),
          truckerProfileProvider.overrideWith((ref) async => _verifiedTruckerProfile()),
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

    await tester.ensureVisible(find.text('Report spam or abuse'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report spam or abuse'));
    await tester.pumpAndSettle();

    expect(find.text('Report issue opened'), findsOneWidget);
    expect(receivedContext, isNotNull);
    expect(receivedContext!.initialCategory, 'spam_or_scam');
    expect(receivedContext!.relatedLoadId, 'load-1');
    expect(receivedContext!.relatedTripId, 'trip-1');
    expect(receivedContext!.sourceLabel, contains('Chandrapur, Maharashtra'));
    expect(receivedContext!.sourceLabel, contains('Mumbai, Maharashtra'));
  });

  testWidgets('blocks supplier chat from trip detail until trucker verification is complete', (tester) async {
    final chatBackend = _ScreenChatBackend()..createConversationResult = 'conversation-42';
    final chatRepository = ChatRepository(
      chatBackend,
      () => 'trucker-1',
      () => AppUserRole.trucker,
    );

    await tester.pumpWidget(
      _buildRoutedApp(
        chatRepository: chatRepository,
        truckerProfile: const TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919812345678',
          email: 'trucker@example.com',
          verificationStatus: 'unverified',
          dlNumber: null,
          rating: 0,
          totalTrips: 0,
          completedTrips: 0,
          totalTrucks: 0,
          approvedTrucks: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.'),
      findsOneWidget,
    );
    expect(find.text('Open verification'), findsOneWidget);
    final callButton = tester.widget<OutlineButton>(find.widgetWithText(OutlineButton, 'Call Supplier'));
    expect(callButton.onPressed, isNull);

    await tester.scrollUntilVisible(
      find.text('Open verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification opened'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('blocked trip-detail verification CTA opens verification route', (tester) async {
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

    await tester.pumpWidget(
      _buildRoutedApp(
        chatRepository: chatRepository,
        truckerProfile: const TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919812345678',
          email: 'trucker@example.com',
          verificationStatus: 'unverified',
          dlNumber: null,
          rating: 0,
          totalTrips: 0,
          completedTrips: 0,
          totalTrucks: 0,
          approvedTrucks: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Open verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification opened'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('blocks supplier chat and call from trip detail until a truck is approved', (tester) async {
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

    await tester.pumpWidget(
      _buildRoutedApp(
        chatRepository: chatRepository,
        truckerProfile: const TruckerProfile(
          id: 'trucker-1',
          fullName: 'Ravi Trucker',
          mobile: '+919812345678',
          email: 'trucker@example.com',
          verificationStatus: 'verified',
          dlNumber: 'DL-12345',
          rating: 0,
          totalTrips: 0,
          completedTrips: 0,
          totalTrucks: 1,
          approvedTrucks: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Add and approve at least one truck before booking this load or unlocking supplier chat.'),
      findsOneWidget,
    );
    expect(find.text('Open fleet'), findsOneWidget);
    final callButton = tester.widget<OutlineButton>(
      find.widgetWithText(OutlineButton, 'Call Supplier').first,
    );
    expect(callButton.onPressed, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
