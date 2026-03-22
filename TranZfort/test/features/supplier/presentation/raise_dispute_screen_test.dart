import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_trip_repository.dart';
import 'package:tranzfort/src/features/supplier/presentation/raise_dispute_screen.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';
import 'package:tranzfort/src/features/support/providers/support_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _RaiseDisputeBackend implements SupplierTripsBackend {
  String stage = 'proof_submitted';
  String? disputedTripId;
  String? disputeCategory;
  String? disputeReason;
  String? disputeAttachmentPath;
  Object? tripDetailError;

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
      'pod_uploaded_at': '2026-03-10T11:00:00.000Z',
      'completed_at': null,
      'lr_document_path': null,
      'pod_document_path': 'trip-1/pod.jpg',
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
        'verification_status': 'verified',
      };

  @override
  Future<Map<String, dynamic>?> fetchOwnRating({required String reviewerId, required String loadId}) async => null;

  @override
  Future<void> submitRating({required String loadId, required int score, String? comment}) async {}

  @override
  Future<String?> createProofSignedUrl(String path) async => 'https://example.com/$path';

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
  }) async {
    disputedTripId = tripId;
    disputeCategory = category;
    disputeReason = reason;
    disputeAttachmentPath = attachmentPath;
    stage = 'disputed';
    return 'support-ticket-1';
  }
}

class _NoopSupportBackend implements SupportBackend {
  @override
  Future<String> createTicket({required String category, required String messageBody, String? relatedLoadId, String? relatedTripId, String? attachmentPath, SupportTicketPriority? priority}) async => 'ticket-created';

  @override
  Future<Map<String, dynamic>?> fetchTicket({required String userId, required String ticketId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchTicketMessages({required String ticketId}) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchTickets({required String userId, int limit = 20, DateTime? before}) async => const <Map<String, dynamic>>[];

  @override
  Future<String> replyToTicket({required String ticketId, required String messageBody, String? attachmentPath}) async => 'reply-created';
}

class _TestSupportTicketsController extends SupportTicketsController {
  int loadCalls = 0;

  _TestSupportTicketsController(super.repository) : super();

  @override
  Future<void> load() async {
    loadCalls += 1;
  }
}

void main() {
  testWidgets('raise dispute screen sanitizes trip detail load failure copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _RaiseDisputeBackend()..tripDetailError = Exception('PostgrestException: leaked detail');
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');
    final router = GoRouter(
      initialLocation: '${AppRoutes.raiseDisputePath}/trip-1',
      routes: [
        GoRoute(
          path: '${AppRoutes.raiseDisputePath}/:tripId',
          builder: (context, state) => RaiseDisputeScreen(
            tripId: state.pathParameters['tripId'] ?? '',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(repository),
          currentProfileProvider.overrideWith((ref) => const AsyncValue<UserProfile?>.data(
                UserProfile(
                  id: 'supplier-1',
                  fullName: 'Amit Supplier',
                  mobile: '+919999999999',
                  email: 'amit@example.com',
                  roleType: 'supplier',
                  isBanned: false,
                  accountDeletionStatus: 'active',
                  trustSafetyStatus: 'normal',
                ),
              )),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip detail unavailable'), findsOneWidget);
    expect(
      find.text('We could not load this trip detail right now. Retry shortly to review the latest dispute context.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('raise dispute not-found fallback opens supplier trips route', (tester) async {
    final backend = _RaiseDisputeBackend()..tripDetailError = const NotFoundFailure();
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');
    final router = GoRouter(
      initialLocation: '${AppRoutes.raiseDisputePath}/trip-404',
      routes: [
        GoRoute(
          path: '${AppRoutes.raiseDisputePath}/:tripId',
          builder: (context, state) => RaiseDisputeScreen(
            tripId: state.pathParameters['tripId'] ?? '',
          ),
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
          supplierTripsRepositoryProvider.overrideWithValue(repository),
          currentProfileProvider.overrideWith((ref) => const AsyncValue<UserProfile?>.data(
                UserProfile(
                  id: 'supplier-1',
                  fullName: 'Amit Supplier',
                  mobile: '+919999999999',
                  email: 'amit@example.com',
                  roleType: 'supplier',
                  isBanned: false,
                  accountDeletionStatus: 'active',
                  trustSafetyStatus: 'normal',
                ),
              )),
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

  testWidgets('raise dispute screen submits dispute and opens support with created ticket id', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _RaiseDisputeBackend();
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');
    final supportRepository = SupportRepository(_NoopSupportBackend(), () => 'supplier-1');
    final supportTicketsController = _TestSupportTicketsController(supportRepository);
    Object? receivedExtra;
    final router = GoRouter(
      initialLocation: '${AppRoutes.raiseDisputePath}/trip-1',
      routes: [
        GoRoute(
          path: '${AppRoutes.raiseDisputePath}/:tripId',
          builder: (context, state) => RaiseDisputeScreen(
            tripId: state.pathParameters['tripId'] ?? '',
          ),
        ),
        GoRoute(
          path: AppRoutes.supportPath,
          builder: (context, state) {
            receivedExtra = state.extra;
            return const Scaffold(body: Text('Support opened'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(repository),
          supportRepositoryProvider.overrideWithValue(supportRepository),
          supportTicketsProvider.overrideWith((ref) => supportTicketsController),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Raise Dispute'), findsOneWidget);
    expect(find.text('Dispute delivery proof'), findsOneWidget);
    expect(find.text('Current stage: Proof submitted'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Dispute reason'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Dispute category'), findsOneWidget);
    expect(find.text('Dispute reason'), findsOneWidget);
    expect(find.text('Helpful details to include'), findsOneWidget);
    expect(
      find.text('The current dispute flow still accepts one optional image. Use these prompts to capture any second or third proof in your written explanation.'),
      findsOneWidget,
    );
    expect(find.text('Document field that does not match:'), findsOneWidget);
    expect(find.text('Correct trip or POD detail should be:'), findsOneWidget);
    expect(find.text('No evidence image attached yet. You can attach one supporting image in the current flow.'), findsOneWidget);
    expect(find.textContaining('Only one image can be attached right now.'), findsOneWidget);
    expect(find.textContaining('Choose the clearest single document image'), findsOneWidget);
    expect(find.text('Visible to the other party: dispute category and status only. Raw evidence may stay restricted during review.'), findsOneWidget);
    expect(find.textContaining('Make sure key document fields are readable in one frame'), findsOneWidget);
    await tester.tap(find.text('Document field that does not match:'));
    await tester.pumpAndSettle();
    final editableText = tester.widget<EditableText>(find.byType(EditableText).first);
    expect(editableText.controller.text, contains('Document field that does not match:'));
    await tester.enterText(find.byType(TextField).first, 'POD image is unclear and unloading evidence does not match this trip.');
    await tester.scrollUntilVisible(find.text('Submit dispute'), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit dispute'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
    expect(receivedExtra, 'support-ticket-1');
    expect(backend.disputedTripId, 'trip-1');
    expect(backend.disputeCategory, 'document_mismatch');
    expect(backend.disputeReason, contains('POD image is unclear'));
    expect(backend.disputeAttachmentPath, isNull);
    expect(supportTicketsController.loadCalls, greaterThanOrEqualTo(1));
  });

  testWidgets('raise dispute screen falls back to unknown for unsupported trip stage', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final backend = _RaiseDisputeBackend()..stage = 'needs_manual_review';
    final repository = SupplierTripsRepository(backend, () => 'supplier-1');
    final router = GoRouter(
      initialLocation: '${AppRoutes.raiseDisputePath}/trip-1',
      routes: [
        GoRoute(
          path: '${AppRoutes.raiseDisputePath}/:tripId',
          builder: (context, state) => RaiseDisputeScreen(
            tripId: state.pathParameters['tripId'] ?? '',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierTripsRepositoryProvider.overrideWithValue(repository),
          currentProfileProvider.overrideWith((ref) => const AsyncValue<UserProfile?>.data(
                UserProfile(
                  id: 'supplier-1',
                  fullName: 'Amit Supplier',
                  mobile: '+919999999999',
                  email: 'amit@example.com',
                  roleType: 'supplier',
                  isBanned: false,
                  accountDeletionStatus: 'active',
                  trustSafetyStatus: 'normal',
                ),
              )),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Current stage: Unknown'), findsOneWidget);
    expect(find.text('Needs Manual Review'), findsNothing);
  });
}
