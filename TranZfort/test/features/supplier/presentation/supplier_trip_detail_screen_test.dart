import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/presentation/supplier_trip_detail_screen.dart';
import 'package:tranzfort/src/features/support/providers/support_compose_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _TripDetailBackend implements SupplierTripsBackend {
  final String stage;
  final String verificationStatus;
  final Map<String, dynamic>? ratingRow;
  final Object? tripDetailError;
  final bool omitDisputeSummary;
  final String disputeStatus;
  final String disputeCategory;

  _TripDetailBackend({
    this.stage = 'proof_submitted',
    this.verificationStatus = 'verified',
    this.ratingRow,
    this.tripDetailError,
    this.omitDisputeSummary = false,
    this.disputeStatus = 'in_progress',
    this.disputeCategory = 'document_mismatch',
  });

  @override
  Future<List<Map<String, dynamic>>> fetchTrips({required String supplierId, required List<String> stages}) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchTripDetail({required String supplierId, required String tripId}) async {
    if (tripDetailError != null) {
      throw tripDetailError!;
    }
    return {
      'id': tripId,
      'load_id': 'load-1',
      'trucker_id': 'trucker-1',
      'truck_id': 'truck-1',
      'stage': stage,
      'assigned_at': '2026-03-08T12:00:00.000Z',
      'delivered_at': '2026-03-10T10:00:00.000Z',
      'pod_uploaded_at': stage == 'proof_submitted' || stage == 'completed' ? '2026-03-10T11:00:00.000Z' : null,
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
        'destination_label': 'Mumbai, Maharashtra',
        'route_distance_km': 820,
        'route_duration_minutes': 780,
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
  Future<Map<String, dynamic>?> fetchTruckerProfile(String truckerId) async => {
        'id': truckerId,
        'full_name': 'Ravi Trucker',
        'verification_status': verificationStatus,
      };

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => ratingRow;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => 'https://example.com/$path';

  @override
  Future<void> cancelTrip(String tripId) async {}

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

void main() {
  testWidgets('renders sanitized supplier trip detail failure copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(tripDetailError: Exception('PostgrestException: leaked detail')),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load supplier trip detail'), findsOneWidget);
    expect(
      find.text('We could not load this supplier trip detail right now. Retry shortly to refresh the latest trip status and proof review context.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('supplier trip-detail not-found fallback opens supplier trips route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SupplierTripDetailScreen(tripId: 'trip-404'),
        ),
        GoRoute(
          path: AppRoutes.supplierTripsPath,
          builder: (context, state) => const Scaffold(body: Text('Supplier trips opened')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(tripDetailError: const NotFoundFailure()),
              () => 'supplier-1',
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
    expect(find.text('Back to supplier trips'), findsOneWidget);

    await tester.tap(find.text('Back to supplier trips'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier trips opened'), findsOneWidget);
  });

  testWidgets('renders supplier trip detail proof review state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(_TripDetailBackend(), () => 'supplier-1'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip Detail'), findsOneWidget);
    expect(find.text('Proof submitted'), findsOneWidget);
    expect(find.text('Proof documents'), findsOneWidget);
    expect(find.text('Confirm Delivery'), findsOneWidget);
    expect(find.text('Dispute POD'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Body type: Open'), findsOneWidget);
    expect(find.text('Trucker: Ravi Trucker'), findsOneWidget);
  });

  testWidgets('renders neutral fallback for unknown supplier trip stage and verification status', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(stage: 'handover_review', verificationStatus: 'needs_manual_review'),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Handover review'), findsNothing);
    expect(find.text('Needs manual review'), findsNothing);
  });

  testWidgets('supplier trip detail dispute action opens raise dispute route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
        GoRoute(
          path: '${AppRoutes.raiseDisputePath}/:tripId',
          builder: (context, state) => Scaffold(body: Text('Raise dispute opened: ${state.pathParameters['tripId']}')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(_TripDetailBackend(), () => 'supplier-1'),
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
      find.text('Dispute POD'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dispute POD'));
    await tester.pumpAndSettle();

    expect(find.text('Raise dispute opened: trip-1'), findsOneWidget);
  });

  testWidgets('supplier trip detail report action opens report issue route with trip context', (tester) async {
    Object? receivedExtra;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SupplierTripDetailScreen(tripId: 'trip-1'),
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
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(_TripDetailBackend(), () => 'supplier-1'),
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
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Report spam or abuse'));
    await tester.pumpAndSettle();

    expect(find.text('Report issue opened'), findsOneWidget);
    expect(receivedExtra, isA<ReportIssueContext>());
    final contextData = receivedExtra! as ReportIssueContext;
    expect(contextData.initialCategory, 'spam_or_scam');
    expect(contextData.relatedLoadId, 'load-1');
    expect(contextData.relatedTripId, 'trip-1');
  });

  testWidgets('renders supplier completed trip rating prompt', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(_TripDetailBackend(stage: 'completed'), () => 'supplier-1'),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rate this trip'), findsOneWidget);
    expect(find.text('Submit Rating'), findsOneWidget);
  });

  testWidgets('renders supplier already rated state on completed trip', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(
                stage: 'completed',
                ratingRow: {
                  'id': 'rating-1',
                  'score': 4,
                  'comment': 'Reliable trucker',
                  'created_at': '2026-03-10T13:00:00.000Z',
                },
              ),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You already rated this trip.'), findsOneWidget);
    expect(find.text('Reliable trucker'), findsOneWidget);
  });

  testWidgets('renders supplier disputed trip summary with visible category and status', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SupplierTripDetailScreen(tripId: 'trip-1'),
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
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(_TripDetailBackend(stage: 'disputed'), () => 'supplier-1'),
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

    expect(find.text('Dispute review in progress'), findsWidgets);
    expect(find.text('Dispute status'), findsOneWidget);
    expect(find.text('Category: Document mismatch'), findsOneWidget);
    expect(find.text('Current state: In progress'), findsOneWidget);
    expect(
      find.text('Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.'),
      findsOneWidget,
    );
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'),
      findsOneWidget,
    );
    expect(
      find.text('If this dispute depends on additional documents beyond the current single-image flow, summarize those missing proofs clearly in the related support ticket replies.'),
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

  testWidgets('renders supplier disputed trip fallback summary when dispute summary is unavailable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(stage: 'disputed', omitDisputeSummary: true),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute review in progress'), findsWidgets);
    expect(find.text('Dispute status'), findsOneWidget);
    expect(find.text('Current state: Dispute raised'), findsOneWidget);
    expect(find.text('Category: Document mismatch'), findsNothing);
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'),
      findsOneWidget,
    );
  });

  testWidgets('renders supplier waiting-for-user dispute banner copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(stage: 'disputed', disputeStatus: 'waiting_for_user'),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute review waiting for your reply'), findsOneWidget);
    expect(
      find.text('Category: Document mismatch. This trip dispute is waiting on your clarification or proof, while raw evidence access may remain restricted during review.'),
      findsOneWidget,
    );
  });

  testWidgets('renders supplier resolved dispute banner copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(stage: 'disputed', disputeStatus: 'resolved'),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute review closed'), findsOneWidget);
    expect(
      find.text('Category: Document mismatch. This trip dispute has reached a final review outcome. Recorded status updates remain visible, while raw evidence access may remain restricted.'),
      findsOneWidget,
    );
    expect(
      find.text('Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.'),
      findsOneWidget,
    );
    expect(
      find.text('This dispute has reached a final review state. Check the recorded outcome on the linked support ticket before opening any genuinely new follow-up issue.'),
      findsOneWidget,
    );
    expect(
      find.text('If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.'),
      findsOneWidget,
    );
  });

  testWidgets('renders supplier in-progress dispute coverage for fake payout proof category', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(stage: 'disputed', disputeCategory: 'fake_payout_proof'),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Category: Fake payout proof'), findsOneWidget);
    expect(find.text('Dispute review in progress'), findsWidgets);
    expect(
      find.text('Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'),
      findsOneWidget,
    );
    expect(
      find.text('If this dispute depends on additional documents beyond the current single-image flow, summarize those missing proofs clearly in the related support ticket replies.'),
      findsOneWidget,
    );
  });

  testWidgets('renders supplier waiting dispute banner copy for delay-or-no-show category', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(
            SupplierTripsRepository(
              _TripDetailBackend(
                stage: 'disputed',
                disputeStatus: 'waiting_for_user',
                disputeCategory: 'delay_or_no_show',
              ),
              () => 'supplier-1',
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SupplierTripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dispute review waiting for your reply'), findsOneWidget);
    expect(
      find.text('Category: Delay or no-show. This trip dispute is waiting on your clarification or proof, while raw evidence access may remain restricted during review.'),
      findsOneWidget,
    );
  });
}
