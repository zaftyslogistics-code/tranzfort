import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/shell/presentation/supplier_shell_screens.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_dashboard_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_profile_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_providers.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeContextualTtsService extends ContextualTtsService {
  String? lastLanguageCode;
  String? lastMessage;
  int speakCalls = 0;

  _FakeContextualTtsService()
      : super(
          setLanguageFn: (_) async {},
          setSpeechRateFn: (_) async {},
          speakFn: (_) async {},
          stopFn: () async {},
          preferencesFn: () async => throw StateError('unused'),
        );

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    lastLanguageCode = languageCode;
    lastMessage = message;
    speakCalls += 1;
    return ContextualTtsOutcome.spoken;
  }
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);
}

class _FixedAppLocaleController extends AppLocaleController {
  _FixedAppLocaleController(String languageCode)
      : super(
          _FakeAuthRepository(),
          profileLanguageCode: languageCode,
        ) {
    state = state.copyWith(
      locale: Locale(languageCode),
      isInitialized: true,
      clearFailure: true,
    );
  }
}

Widget _buildTestApp(
  List<Override> overrides, {
  _FakeContextualTtsService? ttsService,
  String languageCode = 'en',
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: SupplierDashboardScreen()),
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
        path: AppRoutes.myLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('My loads opened')),
      ),
      GoRoute(
        path: AppRoutes.supportPath,
        builder: (context, state) => const Scaffold(body: Text('Support opened')),
      ),
      GoRoute(
        path: AppRoutes.supplierTripsPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier trips opened')),
      ),
      GoRoute(
        path: AppRoutes.messagesPath,
        builder: (context, state) => const Scaffold(body: Text('Messages opened')),
      ),
      GoRoute(
        path: AppRoutes.notificationsPath,
        builder: (context, state) => const Scaffold(body: Text('Notifications opened')),
      ),
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, state) => Scaffold(body: Text('Load detail opened: ${state.pathParameters['loadId']}')),
      ),
    ],
  );

  final resolvedTtsService = ttsService ?? _FakeContextualTtsService();

  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FixedAppLocaleController(languageCode)),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      ...overrides,
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('renders supplier dashboard success state', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => [
            Load(
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
              status: 'active',
              requiredBodyType: 'open',
              requiredTyres: const [10, 12],
              isSuperLoad: false,
              superStatus: 'none',
              publishedAt: DateTime(2026, 3, 8),
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.textContaining('Verification complete'), findsWidgets);
    expect(find.textContaining('Review verification'), findsWidgets);
    expect(find.textContaining('Post Load'), findsWidgets);

    expect(find.textContaining('Dashboard overview'), findsOneWidget);
    expect(find.textContaining('Active loads'), findsOneWidget);
    expect(find.textContaining('Pending bookings'), findsOneWidget);

    expect(find.text('Super Load readiness'), findsOneWidget);
    expect(find.textContaining('Verification complete'), findsWidgets);
    expect(find.textContaining('Business licence on file'), findsOneWidget);

    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('My Loads'), findsWidgets);
    expect(find.text('Trips'), findsWidgets);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    expect(find.textContaining('Chandrapur'), findsOneWidget);
    expect(find.text('Coal - 22T - Per Ton'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
  });

  testWidgets('supplier dashboard does not auto-speak at launch', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ], ttsService: ttsService),
    );
    await tester.pumpAndSettle();

    expect(ttsService.speakCalls, 0);
    expect(ttsService.lastLanguageCode, isNull);
    expect(ttsService.lastMessage, isNull);
  });

  testWidgets('supplier dashboard recent loads fall back to unknown for unsupported price type', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => [
            Load(
              id: 'load-1',
              originLabel: 'Chandrapur, Maharashtra',
              destinationLabel: 'Mumbai, Maharashtra',
              material: 'Coal',
              weightTonnes: 22,
              trucksNeeded: 2,
              trucksBooked: 1,
              priceAmount: 54000,
              priceType: 'partner_negotiated',
              pickupDate: DateTime(2026, 3, 10),
              status: 'active',
              requiredBodyType: 'open',
              requiredTyres: const [10, 12],
              isSuperLoad: false,
              superStatus: 'none',
              publishedAt: DateTime(2026, 3, 8),
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coal - 22T - Unknown'), findsOneWidget);
    expect(find.text('Partner Negotiated'), findsNothing);
  });

  testWidgets('verified supplier dashboard review verification action opens supplier verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Post Load'), findsWidgets);

    await tester.tap(find.text('Post Load').first);
    await tester.pumpAndSettle();

    expect(find.text('Post load opened'), findsOneWidget);
  });

  testWidgets('verified supplier dashboard hero action opens post load', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Post Load'), findsWidgets);

    await tester.tap(find.text('Post Load').first);
    await tester.pumpAndSettle();

    expect(find.text('Post load opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard recent-load workspace action opens my loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => [
            Load(
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
              status: 'active',
              requiredBodyType: 'open',
              requiredTyres: const [10, 12],
              isSuperLoad: false,
              superStatus: 'none',
              publishedAt: DateTime(2026, 3, 8),
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final openLoadsWorkspaceAction = find.text('Open loads workspace');

    expect(openLoadsWorkspaceAction, findsOneWidget);

    await tester.scrollUntilVisible(
      openLoadsWorkspaceAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(openLoadsWorkspaceAction);
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard quick action opens my loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    final quickMyLoadsAction = find.text('My Loads').first;

    await tester.scrollUntilVisible(
      quickMyLoadsAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(quickMyLoadsAction);
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard empty recent-loads CTA opens my loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('No loads posted yet'), findsOneWidget);
    final emptyRecentLoadsAction = find.text('Open my loads').first;

    expect(emptyRecentLoadsAction, findsOneWidget);

    await tester.scrollUntilVisible(
      emptyRecentLoadsAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(emptyRecentLoadsAction);
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard recent-load card opens load detail', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => [
            Load(
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
              status: 'active',
              requiredBodyType: 'open',
              requiredTyres: const [10, 12],
              isSuperLoad: false,
              superStatus: 'none',
              publishedAt: DateTime(2026, 3, 8),
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    final recentLoadCardTitle = find.textContaining('Chandrapur, Maharashtra > Mumbai, Maharashtra').first;

    await tester.scrollUntilVisible(
      recentLoadCardTitle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(recentLoadCardTitle);
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('supplier dashboard quick action opens supplier trips', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    final quickTripsAction = find.text('Trips').first;

    await tester.scrollUntilVisible(
      quickTripsAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(quickTripsAction);
    await tester.pumpAndSettle();

    expect(find.text('Supplier trips opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard quick action opens messages', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    final quickChatAction = find.text('Chat');

    await tester.scrollUntilVisible(
      quickChatAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(quickChatAction);
    await tester.pumpAndSettle();

    expect(find.text('Messages opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard quick action opens notifications', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    final quickNotificationsAction = find.text('Notifications');

    await tester.scrollUntilVisible(
      quickNotificationsAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(quickNotificationsAction);
    await tester.pumpAndSettle();

    expect(find.text('Notifications opened'), findsOneWidget);
  });

  testWidgets('unverified supplier dashboard hero action opens supplier verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'pending',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 0,
            activeLoadsCount: 0,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete verification'), findsOneWidget);

    await tester.tap(find.text('Complete verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('pending supplier dashboard verification action opens supplier verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'pending',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open verification'), findsWidgets);

    await tester.tap(find.text('Open verification').first);
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('rejected supplier dashboard verification action opens supplier verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'rejected',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fix verification'), findsWidgets);

    await tester.tap(find.text('Fix verification').first);
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('rejected supplier dashboard verification banner shows current-runtime guidance copy', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'rejected',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification needs attention'), findsOneWidget);
    expect(
      find.text('Review the latest verification feedback, update the required documents, and resubmit when you are ready.'),
      findsOneWidget,
    );
    expect(find.text('Fix verification'), findsWidgets);
    expect(find.text('Review verification'), findsNothing);
  });

  testWidgets('supplier dashboard falls back to unknown for unsupported verification status', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'needs_manual_review',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Needs Manual Review'), findsNothing);
  });

  testWidgets('renders setup warning when supplier company name is missing outside active verification banner states', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: '',
            companyName: '',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete your supplier setup'), findsOneWidget);
    expect(
      find.text('Complete supplier verification and add your company details before using the full supplier workspace.'),
      findsOneWidget,
    );
    expect(find.text('Open verification'), findsWidgets);
    expect(find.text('Review verification'), findsNothing);
    expect(find.text('Fix verification'), findsNothing);
  });

  testWidgets('generic missing-company-name setup warning opens supplier verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: '',
            companyName: '',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification').first);
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('verified supplier missing company name keeps dashboard in setup state and routes hero action to verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: '',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete your supplier setup'), findsOneWidget);
    expect(find.text('Review verification'), findsNothing);
    expect(find.text('Complete verification'), findsOneWidget);
    expect(find.text('Post Load'), findsNothing);

    await tester.tap(find.text('Complete verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard super load readiness verification action opens supplier verification', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'unverified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: null,
            gstNumber: null,
            totalLoadsPosted: 0,
            activeLoadsCount: 0,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open verification'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Open verification').last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification').last);
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard super load readiness support action opens support when verification is incomplete', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'pending',
            companyName: 'Amit Logistics',
            businessLicenceNumber: null,
            gstNumber: null,
            totalLoadsPosted: 0,
            activeLoadsCount: 0,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support'), findsOneWidget);

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

  testWidgets('pending supplier dashboard super load readiness shows pending-review guidance and review action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'pending',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: null,
            totalLoadsPosted: 0,
            activeLoadsCount: 0,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Review verification'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Review verification'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('rejected supplier dashboard super load readiness shows correction guidance and fix action', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'rejected',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: null,
            totalLoadsPosted: 0,
            activeLoadsCount: 0,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('Fix verification'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Fix verification').last,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fix verification').last);
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('verified supplier dashboard super load readiness secondary action opens my loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open my loads'), findsWidgets);
    final readinessMyLoadsAction = find.text('Open my loads').last;

    await tester.scrollUntilVisible(
      readinessMyLoadsAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(readinessMyLoadsAction);
    await tester.pumpAndSettle();

    expect(find.text('My loads opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard hero action opens support when supplier profile is unavailable', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith((ref) async => null),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Supplier account state unavailable'), findsWidgets);
    expect(find.text('Support'), findsWidgets);
    expect(find.text('Complete verification'), findsNothing);

    await tester.tap(find.text('Support').first);
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('supplier dashboard readiness fallback opens support when supplier profile is unavailable', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith((ref) async => null),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 0,
            pendingBookings: 0,
            inTransitTrips: 0,
            completedTrips: 0,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith((ref) async => const <Load>[]),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support'), findsWidgets);
    final readinessSupportAction = find.text('Support').last;

    await tester.scrollUntilVisible(
      readinessSupportAction,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(readinessSupportAction);
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('renders loading state while async dashboard data resolves', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final completer = Completer<SupplierDashboardStats>();

    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'pending',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith((ref) => completer.future),
        supplierRecentLoadsProvider.overrideWith((ref) => Future<List<Load>>.delayed(const Duration(days: 1))),
      ]),
    );
    await tester.pump();

    expect(find.textContaining('Verification pending'), findsOneWidget);
    expect(find.textContaining('Open verification'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Dashboard overview'), findsOneWidget);
  });

  testWidgets('renders error and empty states for supplier dashboard sections', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'unverified',
            companyName: '',
            businessLicenceNumber: null,
            gstNumber: null,
            totalLoadsPosted: 0,
            activeLoadsCount: 0,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => throw const NetworkFailure(),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => throw const UnknownFailure(message: 'PostgrestException: leaked recent load detail'),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Complete your supplier setup'), findsOneWidget);
    expect(find.textContaining('Open verification'), findsWidgets);
    expect(find.textContaining('Complete verification'), findsOneWidget);

    expect(find.textContaining('Unable to load your supplier dashboard'), findsOneWidget);
    expect(find.text('Recent loads unavailable'), findsOneWidget);
    expect(
      find.text('We could not load your recent supplier loads right now. Retry shortly to refresh the latest load list.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked recent load detail'), findsNothing);

    expect(find.text('Business licence missing'), findsOneWidget);
    expect(find.text('Needs attention'), findsWidgets);

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);

    await tester.tap(find.text('Open verification').first);
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('renders Super Load trust state in supplier recent loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => [
            Load(
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
              status: 'active',
              requiredBodyType: 'open',
              requiredTyres: const [10, 12],
              isSuperLoad: true,
              superStatus: 'under_review',
              publishedAt: DateTime(2026, 3, 8),
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chandrapur'), findsOneWidget);
    expect(find.textContaining('under admin review'), findsOneWidget);
  });

  testWidgets('renders rejected Super Load guidance in supplier recent loads', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        supplierProfileProvider.overrideWith(
          (ref) async => const SupplierProfile(
            id: 'supplier-1',
            fullName: 'Amit Supplier',
            mobile: '+919999999999',
            email: 'amit@example.com',
            verificationStatus: 'verified',
            companyName: 'Amit Logistics',
            businessLicenceNumber: 'BL-42',
            gstNumber: '27ABCDE1234F1Z5',
            totalLoadsPosted: 12,
            activeLoadsCount: 4,
          ),
        ),
        supplierDashboardProvider.overrideWith(
          (ref) async => const SupplierDashboardStats(
            activeLoads: 4,
            pendingBookings: 2,
            inTransitTrips: 1,
            completedTrips: 9,
          ),
        ),
        supplierRecentLoadsProvider.overrideWith(
          (ref) async => [
            Load(
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
              status: 'active',
              requiredBodyType: 'open',
              requiredTyres: const [10, 12],
              isSuperLoad: true,
              superStatus: 'rejected',
              publishedAt: DateTime(2026, 3, 8),
            ),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chandrapur'), findsOneWidget);
    expect(find.textContaining('Super Load - Rejected'), findsOneWidget);
    expect(
      find.textContaining('This Super Load request was not approved. Use support if you need follow-up while the dedicated supplier readiness surface is still pending.'),
      findsOneWidget,
    );
  });
}
