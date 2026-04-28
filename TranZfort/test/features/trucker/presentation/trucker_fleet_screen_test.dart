import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/trucker/data/truck_document_upload_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_fleet_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_fleet_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_fleet_provider.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _NoopFleetBackend implements TruckerFleetBackend {
  @override
  Future<Map<String, dynamic>> createTruck(Map<String, dynamic> values) async => {'id': 'truck-1'};

  @override
  Future<List<Map<String, dynamic>>> fetchTrucks(String ownerId, {int limit = 20, int offset = 0}) async => const <Map<String, dynamic>>[];

  @override
  Future<void> updateTruck({required String ownerId, required String truckId, required Map<String, dynamic> values}) async {}

  @override
  Future<String?> getSignedUrl(String bucketPath, {int expiresInSeconds = 300}) async => null;
}

class _MutableFleetBackend implements TruckerFleetBackend {
  List<Map<String, dynamic>> truckRows = <Map<String, dynamic>>[];
  String? updatedOwnerId;
  String? updatedTruckId;
  Map<String, dynamic>? updatedValues;

  @override
  Future<Map<String, dynamic>> createTruck(Map<String, dynamic> values) async => {'id': 'truck-new'};

  @override
  Future<List<Map<String, dynamic>>> fetchTrucks(String ownerId, {int limit = 20, int offset = 0}) async => truckRows;

  @override
  Future<void> updateTruck({required String ownerId, required String truckId, required Map<String, dynamic> values}) async {
    updatedOwnerId = ownerId;
    updatedTruckId = truckId;
    updatedValues = values;
    truckRows = truckRows
        .map(
          (row) => (row['id'] ?? '').toString() == truckId
              ? {
                  ...row,
                  ...values,
                  'updated_at': '2026-03-15T00:00:00.000Z',
                }
              : row,
        )
        .toList(growable: false);
  }

  @override
  Future<String?> getSignedUrl(String bucketPath, {int expiresInSeconds = 300}) async => null;
}

class _FakeTruckDocumentUploadService extends TruckDocumentUploadService {
  _FakeTruckDocumentUploadService({required this.storagePath}) : super(null);

  final String? storagePath;
  String? lastOwnerId;
  String? lastTruckId;
  ImageSource? lastSource;

  @override
  Future<Result<String?>> pickCompressAndUploadRcDocument({
    required String ownerId,
    required String truckId,
    required ImageSource source,
  }) async {
    lastOwnerId = ownerId;
    lastTruckId = truckId;
    lastSource = source;
    return Success<String?>(storagePath);
  }
}

class _TestTruckerFleetController extends TruckerFleetController {
  _TestTruckerFleetController(TruckerFleetState initialState)
      : super(
          TruckerFleetRepository(_NoopFleetBackend(), _currentUserId),
          TruckDocumentUploadService(null),
          _currentUserId,
        ) {
    state = initialState;
  }

  static String? _currentUserId() => 'trucker-1';

  @override
  Future<void> load() async {}
}

class _TrackingTruckerFleetController extends _TestTruckerFleetController {
  _TrackingTruckerFleetController(super.initialState);

  var startCreateCalls = 0;

  @override
  void startCreate() {
    startCreateCalls += 1;
    super.startCreate();
  }
}

Widget _buildApp(TruckerFleetState state, {bool returnToVerification = false}) {
  return ProviderScope(
    overrides: [
      truckerFleetProvider.overrideWith((ref) => _TestTruckerFleetController(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TruckerFleetScreen(returnToVerification: returnToVerification),
    ),
  );
}

Widget _buildAppWithController(TruckerFleetController controller, {bool returnToVerification = false}) {
  return ProviderScope(
    overrides: [
      truckerFleetProvider.overrideWith((ref) => controller),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TruckerFleetScreen(returnToVerification: returnToVerification),
    ),
  );
}

Widget _buildBehaviorApp({
  required TruckerFleetBackend backend,
  required String currentUserId,
  required TruckDocumentUploadService uploadService,
  bool returnToVerification = false,
}) {
  return ProviderScope(
    overrides: [
      truckerFleetProvider.overrideWith(
        (ref) => TruckerFleetController(
          TruckerFleetRepository(backend, () => currentUserId),
          uploadService,
          () => currentUserId,
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TruckerFleetScreen(returnToVerification: returnToVerification),
    ),
  );
}

void main() {
  testWidgets('shows verification return guidance when fleet is opened from verification flow', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: null,
          trucks: const <TruckerFleetTruck>[],
        ),
        returnToVerification: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Back to verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Return to verification'), findsOneWidget);
    expect(find.text('Back to verification'), findsOneWidget);
    expect(
      find.text('Add or update your truck, then return to verification to continue.'),
      findsOneWidget,
    );
  });

  testWidgets('fleet empty state exposes add truck recovery action', (tester) async {
    final controller = _TrackingTruckerFleetController(
      TruckerFleetState.initial().copyWith(
        isLoading: false,
        loadFailure: null,
        trucks: const <TruckerFleetTruck>[],
      ),
    );

    await tester.pumpWidget(_buildAppWithController(controller));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add truck').last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Add truck'), findsWidgets);

    await tester.tap(find.text('Add truck').last);
    await tester.pumpAndSettle();

    expect(controller.startCreateCalls, 1);
    expect(find.text('Add or update truck'), findsOneWidget);
  });

  testWidgets('renders localized fleet truck card subtitle copy', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: null,
          trucks: <TruckerFleetTruck>[
            TruckerFleetTruck(
              id: 'truck-1',
              truckModelId: null,
              truckNumber: 'MH12AB1234',
              bodyType: 'Open',
              tyres: 12,
              capacityTonnes: 25,
              rcDocumentPath: 'fleet/truck-1/rc.jpg',
              status: TruckerFleetTruckStatus.verified,
              rejectionReason: null,
              reviewFeedback: const TruckerFleetReviewFeedback(summary: null, nextStep: null),
              modelLabel: 'Tata Signa',
              verifiedAt: DateTime(2026, 3, 13),
              createdAt: DateTime(2026, 3, 10),
              updatedAt: DateTime(2026, 3, 13),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Open - 12 tyres - 25T'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Open - 12 tyres - 25T'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.text('Model: Tata Signa'), findsOneWidget);
  });

  testWidgets('renders sanitized fleet load failure copy', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Fleet unavailable'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Fleet unavailable'), findsOneWidget);
    expect(
      find.text('We could not load your fleet right now. Retry shortly to refresh the latest truck readiness and approval state.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('renders sanitized fleet action failure copy', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: null,
          trucks: const <TruckerFleetTruck>[],
          actionFailure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Truck action needs attention'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Truck action needs attention'), findsOneWidget);
    expect(
      find.text('The latest truck action could not be completed right now. Review the truck details and retry shortly.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('renders rejected truck review summary, next step, and blocked-booking guidance', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: null,
          trucks: <TruckerFleetTruck>[
            TruckerFleetTruck(
              id: 'truck-1',
              truckModelId: null,
              truckNumber: 'MH12AB1234',
              bodyType: 'Open',
              tyres: 12,
              capacityTonnes: 25,
              rcDocumentPath: 'fleet/truck-1/rc.jpg',
              status: TruckerFleetTruckStatus.rejected,
              rejectionReason: 'RC image is blurred',
              reviewFeedback: const TruckerFleetReviewFeedback(
                summary: 'RC image is blurred',
                nextStep: 'Upload a clearer RC image and resubmit this truck.',
              ),
              modelLabel: 'Tata Signa',
              verifiedAt: null,
              createdAt: DateTime(2026, 3, 10),
              updatedAt: DateTime(2026, 3, 15),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Review summary: RC image is blurred'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('RC image is blurred'), findsWidgets);
    expect(find.text('REJECTED'), findsOneWidget);
    expect(find.text('Review summary: RC image is blurred'), findsOneWidget);
    expect(find.text('Next step: Upload a clearer RC image and resubmit this truck.'), findsOneWidget);
    expect(find.text('This truck is blocked for approval-dependent booking workflows until review clears.'), findsOneWidget);
    expect(find.text('Fix and resubmit truck'), findsOneWidget);
  });

  testWidgets('renders edited-pending-reapproval truck guidance and blocked-booking warning', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: null,
          trucks: <TruckerFleetTruck>[
            TruckerFleetTruck(
              id: 'truck-2',
              truckModelId: null,
              truckNumber: 'MH14CD5678',
              bodyType: 'Container',
              tyres: 10,
              capacityTonnes: 18,
              rcDocumentPath: 'fleet/truck-2/rc.jpg',
              status: TruckerFleetTruckStatus.editedPendingReapproval,
              rejectionReason: null,
              reviewFeedback: const TruckerFleetReviewFeedback(
                summary: null,
                nextStep: 'Review is running again after your latest truck update.',
              ),
              modelLabel: 'Ashok Leyland Bada Dost',
              verifiedAt: null,
              createdAt: DateTime(2026, 3, 11),
              updatedAt: DateTime(2026, 3, 15),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('This truck is blocked for approval-dependent booking workflows until review clears.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('This truck stays visible, but recent edits sent it back for reapproval before it can be used again.'), findsOneWidget);
    expect(find.text('PENDING REAPPROVAL'), findsOneWidget);
    expect(find.text('Next step: Review is running again after your latest truck update.'), findsOneWidget);
    expect(find.text('This truck is blocked for approval-dependent booking workflows until review clears.'), findsOneWidget);
    expect(find.text('Edit truck'), findsOneWidget);
  });

  testWidgets('renders rejected truck fallback guidance when review summary is unavailable', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        TruckerFleetState.initial().copyWith(
          isLoading: false,
          loadFailure: null,
          trucks: <TruckerFleetTruck>[
            TruckerFleetTruck(
              id: 'truck-3',
              truckModelId: null,
              truckNumber: 'MH01EF9012',
              bodyType: 'Open',
              tyres: 14,
              capacityTonnes: 28,
              rcDocumentPath: 'fleet/truck-3/rc.jpg',
              status: TruckerFleetTruckStatus.rejected,
              rejectionReason: 'RC document needs correction.',
              reviewFeedback: const TruckerFleetReviewFeedback(
                summary: null,
                nextStep: null,
              ),
              modelLabel: 'BharatBenz 2823C',
              verifiedAt: null,
              createdAt: DateTime(2026, 3, 9),
              updatedAt: DateTime(2026, 3, 15),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('This truck was rejected. Review the guidance below and update the affected details or RC document.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('This truck was rejected. Review the guidance below and update the affected details or RC document.'),
      findsOneWidget,
    );
    expect(find.text('Review summary:'), findsNothing);
    expect(find.textContaining('Next step:'), findsNothing);
    expect(find.text('This truck is blocked for approval-dependent booking workflows until review clears.'), findsOneWidget);
    expect(find.text('Fix and resubmit truck'), findsOneWidget);
  });

  testWidgets('fix and resubmit on a rejected truck loads the edit form and replaces the RC document', (tester) async {
    final backend = _MutableFleetBackend()
      ..truckRows = <Map<String, dynamic>>[
        {
          'id': 'truck-1',
          'truck_model_id': null,
          'truck_number': 'MH12AB1234',
          'body_type': 'Open',
          'tyres': 12,
          'capacity_tonnes': 25,
          'rc_document_path': 'trucker-1/truck-1/rc/old-rc.jpg',
          'status': 'rejected',
          'rejection_reason': 'RC image is blurred',
          'verification_feedback_json': {
            'summary': 'RC image is blurred',
            'next_step': 'Upload a clearer RC image and resubmit this truck.',
          },
          'verified_at': null,
          'created_at': '2026-03-10T10:00:00.000Z',
          'updated_at': '2026-03-10T10:00:00.000Z',
          'truck_models': {
            'make': 'Tata',
            'model': 'Signa',
          },
        },
      ];
    final uploadService = _FakeTruckDocumentUploadService(
      storagePath: 'trucker-1/truck-1/rc/new-rc.jpg',
    );

    await tester.pumpWidget(
      _buildBehaviorApp(
        backend: backend,
        currentUserId: 'trucker-1',
        uploadService: uploadService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Fix and resubmit truck'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix and resubmit truck'));
    await tester.pumpAndSettle();

    expect(find.text('Editing truck'), findsOneWidget);
    expect(find.text('Stored path: trucker-1/truck-1/rc/old-rc.jpg'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Replace RC document'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replace RC document'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose from gallery'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(uploadService.lastOwnerId, 'trucker-1');
    expect(uploadService.lastTruckId, 'truck-1');
    expect(uploadService.lastSource, ImageSource.gallery);
    expect(find.text('Stored path: trucker-1/truck-1/rc/new-rc.jpg'), findsOneWidget);

    await tester.tap(find.text('Save truck updates'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(backend.updatedOwnerId, 'trucker-1');
    expect(backend.updatedTruckId, 'truck-1');
    expect(backend.updatedValues?['rc_document_path'], 'trucker-1/truck-1/rc/new-rc.jpg');
    expect(backend.updatedValues?['status'], 'pending');
    expect(backend.updatedValues?['rejection_reason'], isNull);
    expect(backend.updatedValues?['verification_feedback_json'], isNull);
  });
}
