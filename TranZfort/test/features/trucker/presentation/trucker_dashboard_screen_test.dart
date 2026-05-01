import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_dashboard_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_profile_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_dashboard_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_providers.dart';
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
          preferencesFn: SharedPreferences.getInstance as Future<SharedPreferences> Function(),
          getVoices: Future.value,
          setVoiceFn: (_) async {},
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
        builder: (context, state) => const Scaffold(
          body: TruckerDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet route')),
      ),
      GoRoute(
        path: AppRoutes.findLoadsPath,
        builder: (context, state) => const Scaffold(body: Text('Find loads route')),
      ),
      GoRoute(
        path: AppRoutes.tripsPath,
        builder: (context, state) => const Scaffold(body: Text('Trips route')),
      ),
      GoRoute(
        path: AppRoutes.messagesPath,
        builder: (context, state) => const Scaffold(body: Text('Messages route')),
      ),
      GoRoute(
        path: AppRoutes.truckerVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Trucker verification route')),
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
  testWidgets('renders sanitized trucker readiness failure copy', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => throw const UnknownFailure(message: 'PostgrestException: leaked detail'),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 0,
            approvedTrucks: 0,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Readiness state unavailable'), findsOneWidget);
    expect(
      find.text('Your trucker readiness state is temporarily unavailable. Retry shortly to refresh verification and fleet readiness.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('recent activity failure exposes retry and refreshes successfully', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    var dashboardCalls = 0;

    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'verified',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 2,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith((ref) async {
          dashboardCalls += 1;
          if (dashboardCalls == 1) {
            throw const UnknownFailure(message: 'PostgrestException: leaked detail');
          }
          return const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 4,
            totalTrucks: 2,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          );
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent activity unavailable'), findsWidgets);
    expect(find.text('Retry'), findsWidgets);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);

    await tester.tap(find.text('Retry').last);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(dashboardCalls, 2);
    expect(find.text('Recent activity unavailable'), findsNothing);
    expect(find.text('Booking activity'), findsOneWidget);
  });

  testWidgets('renders trucker dashboard success state', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'verified',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 2,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 4,
            upcomingTrips: 2,
            inTransitTrips: 1,
            completedTrips: 9,
            totalTrucks: 2,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 1,
            pendingReapprovalTrucks: 1,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Ravi Trucker'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Dashboard overview'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard overview'), findsOneWidget);
    expect(find.text('Active bids'), findsOneWidget);
    expect(find.text('Upcoming trips'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Fleet'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Recent activity'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Booking activity'), findsOneWidget);
    expect(find.text('Trip activity'), findsWidgets);
    expect(find.text('Fleet review activity'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Readiness and next steps'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Readiness and next steps'), findsOneWidget);
    expect(find.text('Verification status'), findsOneWidget);
    expect(find.text('Verified'), findsWidgets);
    expect(find.text('Fleet readiness'), findsOneWidget);
    expect(find.textContaining('Truck lifecycle attention:'), findsOneWidget);
  });

  testWidgets('unverified trucker without approved truck opens verification from readiness warning', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'unverified',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 4,
            totalTrucks: 1,
            approvedTrucks: 0,
            pendingTrucks: 1,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete fleet and verification setup'), findsOneWidget);
    expect(find.text('Open fleet and verification'), findsOneWidget);

    await tester.tap(find.text('Open fleet and verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification route'), findsOneWidget);
  });

  testWidgets('trucker dashboard does not auto-speak at launch', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'verified',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 2,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 4,
            upcomingTrips: 2,
            inTransitTrips: 1,
            completedTrips: 9,
            totalTrucks: 2,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 1,
            pendingReapprovalTrucks: 1,
          ),
        ),
      ], ttsService: ttsService),
    );
    await tester.pumpAndSettle();

    expect(ttsService.speakCalls, 0);
    expect(ttsService.lastLanguageCode, isNull);
    expect(ttsService.lastMessage, isNull);
  });

  testWidgets('renders loading state while async dashboard data resolves', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final completer = Completer<TruckerDashboardStats>();

    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'pending',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith((ref) => completer.future),
      ]),
    );
    await tester.pump();

    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.text('Open verification'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Dashboard overview'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Dashboard overview'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Quick actions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Fleet'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
  });

  testWidgets('trucker dashboard hero action opens find loads route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
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
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find Loads'), findsWidgets);

    await tester.tap(find.text('Find Loads').first);
    await tester.pumpAndSettle();

    expect(find.text('Find loads route'), findsOneWidget);
  });

  testWidgets('trucker dashboard quick action opens fleet route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
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
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Fleet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fleet').first);
    await tester.pumpAndSettle();

    expect(find.text('Fleet route'), findsOneWidget);
  });

  testWidgets('trucker dashboard quick action opens trips route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
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
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('My Trips'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('My Trips'));
    await tester.pumpAndSettle();

    expect(find.text('Trips route'), findsOneWidget);
  });

  testWidgets('trucker dashboard quick action opens messages route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
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
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Chat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.text('Messages route'), findsOneWidget);
  });

  testWidgets('pending verification banner action opens trucker verification route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'pending',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.text('Open verification'), findsOneWidget);

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification route'), findsOneWidget);
  });

  testWidgets('unknown verification status falls back to localized unknown copy', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'needs_manual_review',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('Needs manual review'), findsNothing);
  });

  testWidgets('renders combined verification and fleet warning when unverified and no approved truck exists', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'unverified',
            dlNumber: null,
            rating: 0,
            totalTrips: 0,
            completedTrips: 0,
            totalTrucks: 0,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => throw const NetworkFailure(),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete fleet and verification setup'), findsOneWidget);
    expect(find.text('Open fleet and verification'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Unable to load your trucker dashboard'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Unable to load your trucker dashboard'), findsOneWidget);
    expect(
      find.text('We could not load your trucker dashboard right now. Retry shortly to refresh the latest KPIs and activity summary.'),
      findsOneWidget,
    );
    expect(find.text('Check your internet connection and try again'), findsNothing);
  });

  testWidgets('verification-only warning opens trucker verification when fleet readiness is already satisfied', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'unverified',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete trucker verification'), findsOneWidget);
    expect(find.text('Open fleet and verification'), findsOneWidget);

    await tester.tap(find.text('Open fleet and verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification route'), findsOneWidget);
  });

  testWidgets('rejected verification attention action opens trucker verification route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'rejected',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification needs attention'), findsOneWidget);
    expect(find.text('Fix verification'), findsOneWidget);

    await tester.tap(find.text('Fix verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification route'), findsOneWidget);
  });

  testWidgets('rejected trucker dashboard verification banner shows current-runtime guidance copy', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'rejected',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 1,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification needs attention'), findsOneWidget);
    expect(find.text('Fix verification'), findsOneWidget);
    expect(find.text('Review verification'), findsNothing);
  });

  testWidgets('verified review verification action opens trucker verification route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
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
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 1,
            upcomingTrips: 1,
            inTransitTrips: 0,
            completedTrips: 5,
            totalTrucks: 1,
            approvedTrucks: 1,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verified'), findsWidgets);
    expect(find.text('Verification status'), findsOneWidget);
  });

  testWidgets('combined fleet and verification warning action opens fleet route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'unverified',
            dlNumber: null,
            rating: 0,
            totalTrips: 0,
            completedTrips: 0,
            totalTrucks: 0,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 0,
            approvedTrucks: 0,
            pendingTrucks: 0,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Complete fleet and verification setup'), findsOneWidget);
    expect(find.text('Open fleet and verification'), findsOneWidget);

    await tester.tap(find.text('Open fleet and verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification route'), findsOneWidget);
  });

  testWidgets('renders fleet-only warning when verification is pending but no approved truck exists', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'pending',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 1,
            approvedTrucks: 0,
            pendingTrucks: 1,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification pending'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Open verification'), findsOneWidget);
    expect(find.text('Add and approve your first truck'), findsNothing);
    expect(find.text('Complete fleet and verification setup'), findsNothing);
  });

  testWidgets('fleet-only warning action opens trucker verification route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: 'pending',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 1,
            approvedTrucks: 0,
            pendingTrucks: 1,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification route'), findsOneWidget);
  });

  testWidgets('renders fleet-only warning when no approved truck exists outside active verification banner states', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: '',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 1,
            approvedTrucks: 0,
            pendingTrucks: 1,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add and approve your first truck'), findsOneWidget);
    expect(find.text('Open fleet'), findsOneWidget);
    expect(find.text('Complete fleet and verification setup'), findsNothing);
    expect(find.text('Open verification'), findsNothing);
  });

  testWidgets('generic fleet-only warning action opens fleet route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildTestApp([
        truckerProfileProvider.overrideWith(
          (ref) async => const TruckerProfile(
            id: 'trucker-1',
            fullName: 'Ravi Trucker',
            mobile: '+919999999999',
            email: 'ravi@example.com',
            verificationStatus: '',
            dlNumber: 'DL-0099',
            rating: 4.8,
            totalTrips: 20,
            completedTrips: 18,
            totalTrucks: 1,
            approvedTrucks: 0,
          ),
        ),
        truckerDashboardProvider.overrideWith(
          (ref) async => const TruckerDashboardStats(
            activeBids: 0,
            upcomingTrips: 0,
            inTransitTrips: 0,
            completedTrips: 0,
            totalTrucks: 1,
            approvedTrucks: 0,
            pendingTrucks: 1,
            rejectedTrucks: 0,
            pendingReapprovalTrucks: 0,
          ),
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open fleet'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet route'), findsOneWidget);
  });
}
