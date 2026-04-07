import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_location_services.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_profile_repository.dart';
import 'package:tranzfort/src/features/supplier/presentation/post_load_screen.dart';
import 'package:tranzfort/src/features/supplier/providers/post_load_provider.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeSupplierLoadBackend implements SupplierLoadBackend {
  @override
  Future<String> approveBookingRequest(String bookingId) async => 'trip-1';

  @override
  Future<void> cancelLoad(String loadId) async {}

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {}

  @override
  Future<String> createLoad(Map<String, dynamic> params) async => 'load-1';

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
  Future<List<Map<String, dynamic>>> fetchMyLoads({
    required String supplierId,
    required LoadFilters filters,
    required int page,
    required int pageSize,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {}
}

class _FakeLocationService implements SupplierLocationService {
  @override
  Future<RoutePreview?> fetchRoutePreview({required PlaceSuggestion origin, required PlaceSuggestion destination}) async {
    return null;
  }

  @override
  Future<PlaceSuggestion> resolveSuggestion(PlaceSuggestion suggestion) async {
    return suggestion;
  }

  @override
  Future<List<PlaceSuggestion>> searchCities(String query) async {
    return const <PlaceSuggestion>[];
  }
}

Widget _buildApp({required String verificationStatus, String companyName = 'North Hub Logistics'}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const PostLoadScreen(),
      ),
      GoRoute(
        path: AppRoutes.supplierVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier verification opened')),
      ),
      GoRoute(
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads opened')),
      ),
      GoRoute(
        path: AppRoutes.supportPath,
        builder: (context, state) => const Scaffold(body: Text('Support opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      supplierLoadRepositoryProvider.overrideWithValue(
        SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
      ),
      supplierLocationServiceProvider.overrideWithValue(_FakeLocationService()),
      supplierProfileProvider.overrideWith(
        (ref) async => SupplierProfile(
          id: 'supplier-1',
          fullName: 'North Hub Logistics',
          mobile: '+919999999999',
          email: 'ops@northhub.test',
          verificationStatus: verificationStatus,
          companyName: companyName,
          businessLicenceNumber: 'BL-42',
          gstNumber: '27ABCDE1234F1Z5',
          totalLoadsPosted: 3,
          activeLoadsCount: 1,
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

PostLoadState _readyToSubmitState() {
  final today = DateTime.now();
  final pickupDate = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
  return PostLoadState.initial().copyWith(
    originCity: 'Chandrapur',
    originLocation: 'MIDC Yard, Chandrapur',
    destinationCity: 'Mumbai',
    destinationLocation: 'Nhava Sheva Port, Mumbai',
    weightTonnes: '22',
    trucksNeeded: '2',
    priceAmount: '54000',
    priceType: 'negotiable',
    pickupDate: pickupDate,
  );
}

void main() {
  testWidgets('renders sanitized post-load submission failure copy', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierLoadRepositoryProvider.overrideWithValue(
            SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
          ),
          supplierLocationServiceProvider.overrideWithValue(_FakeLocationService()),
          supplierProfileProvider.overrideWith(
            (ref) async => SupplierProfile(
              id: 'supplier-1',
              fullName: 'North Hub Logistics',
              mobile: '+919999999999',
              email: 'ops@northhub.test',
              verificationStatus: 'verified',
              companyName: 'North Hub Logistics',
              businessLicenceNumber: 'BL-42',
              gstNumber: '27ABCDE1234F1Z5',
              totalLoadsPosted: 3,
              activeLoadsCount: 1,
            ),
          ),
          postLoadProvider.overrideWith((ref) {
            return PostLoadController(
              ref.read(supplierLoadRepositoryProvider),
              ref.read(supplierLocationServiceProvider),
            )
              ..state = PostLoadState.initial().copyWith(
                submissionFailure: const UnknownFailure(message: 'PostgrestException: leaked detail'),
              );
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PostLoadScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Submission failed'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Submission failed'), findsOneWidget);
    expect(
      find.text('We could not prepare this load submission right now. Review the load details and retry shortly.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('blocks supplier posting until verification is complete', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(_buildApp(verificationStatus: 'pending'));
    await tester.pumpAndSettle();

    expect(find.text('Posting is blocked'), findsOneWidget);
    expect(
      find.text('Complete supplier verification before posting loads. Upload identity and business documents, then submit them for review.'),
      findsOneWidget,
    );
    expect(find.text('Open verification'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Complete verification to post load'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete verification to post load'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open verification'),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('blocks supplier posting when supplier profile is unavailable', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierLoadRepositoryProvider.overrideWithValue(
            SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
          ),
          supplierLocationServiceProvider.overrideWithValue(_FakeLocationService()),
          supplierProfileProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const PostLoadScreen(),
              ),
              GoRoute(
                path: AppRoutes.supportPath,
                builder: (context, state) => const Scaffold(body: Text('Support opened')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Posting is blocked'), findsOneWidget);
    expect(find.text('Supplier profile is unavailable right now. Retry shortly before posting this load.'), findsOneWidget);
    expect(find.text('Open verification'), findsNothing);
    expect(find.text('Support'), findsOneWidget);

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('blocks supplier posting when supplier profile fails to load and offers support recovery', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierLoadRepositoryProvider.overrideWithValue(
            SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
          ),
          supplierLocationServiceProvider.overrideWithValue(_FakeLocationService()),
          supplierProfileProvider.overrideWith((ref) async => throw const UnknownFailure(message: 'PostgrestException: leaked detail')),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const PostLoadScreen(),
              ),
              GoRoute(
                path: AppRoutes.supportPath,
                builder: (context, state) => const Scaffold(body: Text('Support opened')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Posting is blocked'), findsOneWidget);
    expect(find.text('Unable to confirm supplier verification right now. Retry shortly or open verification to review your trust status.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
    expect(find.text('Support'), findsOneWidget);

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('keeps supplier posting enabled once verification is complete', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(_buildApp(verificationStatus: 'verified'));
    await tester.pumpAndSettle();

    expect(find.text('Posting is blocked'), findsNothing);
    expect(find.text('Post Load'), findsOneWidget);
  });

  testWidgets('blocks verified supplier posting until company details are completed', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(_buildApp(verificationStatus: 'verified', companyName: ''));
    await tester.pumpAndSettle();

    expect(find.text('Posting is blocked'), findsOneWidget);
    expect(
      find.text('Complete supplier verification and add your company details before using the full supplier workspace.'),
      findsOneWidget,
    );
    expect(find.text('Open verification'), findsOneWidget);

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('successful supplier post load submission opens my loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final readyState = _readyToSubmitState();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supplierLoadRepositoryProvider.overrideWithValue(
            SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
          ),
          supplierLocationServiceProvider.overrideWithValue(_FakeLocationService()),
          supplierProfileProvider.overrideWith(
            (ref) async => SupplierProfile(
              id: 'supplier-1',
              fullName: 'North Hub Logistics',
              mobile: '+919999999999',
              email: 'ops@northhub.test',
              verificationStatus: 'verified',
              companyName: 'North Hub Logistics',
              businessLicenceNumber: 'BL-42',
              gstNumber: '27ABCDE1234F1Z5',
              totalLoadsPosted: 3,
              activeLoadsCount: 1,
            ),
          ),
          postLoadProvider.overrideWith((ref) {
            return PostLoadController(
              ref.read(supplierLoadRepositoryProvider),
              ref.read(supplierLocationServiceProvider),
            )..state = readyState;
          }),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const PostLoadScreen(),
              ),
              GoRoute(
                path: AppRoutes.myLoadsPath,
                builder: (context, state) => const Scaffold(body: Text('My loads opened')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('₹54000'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final screenContext = tester.element(find.byType(PostLoadScreen));
    final expectedPickup = MaterialLocalizations.of(screenContext).formatMediumDate(readyState.pickupDate);

    expect(find.textContaining('₹54000'), findsOneWidget);
    expect(find.textContaining(expectedPickup), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Post Load'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post Load'));
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });
}
