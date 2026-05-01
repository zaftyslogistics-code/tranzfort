import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/shell/presentation/shell_destinations.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeAuthRepoForLocale extends AuthRepository {
  _FakeAuthRepoForLocale() : super(null);
}

class _FixedAppLocaleController extends AppLocaleController {
  _FixedAppLocaleController(String languageCode)
      : super(
          _FakeAuthRepoForLocale(),
          profileLanguageCode: languageCode,
        ) {
    state = state.copyWith(
      locale: Locale(languageCode),
      isInitialized: true,
      clearFailure: true,
    );
  }
}

class _FakeContextualTtsService extends ContextualTtsService {
  String? lastLanguageCode;
  String? lastMessage;

  _FakeContextualTtsService()
      : super(
          setLanguageFn: (_) async {},
          setSpeechRateFn: (_) async {},
          speakFn: (_) async {},
          stopFn: () async {},
          preferencesFn: () async => SharedPreferences.getInstance,
          getVoices: Future.value,
          setVoiceFn: (_) async {},
        );

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    lastLanguageCode = languageCode;
    lastMessage = message;
    return ContextualTtsOutcome.spoken;
  }
}

class _FakeAuthRepository extends AuthRepository {
  int signOutCalls = 0;

  _FakeAuthRepository() : super(null);

  @override
  Future<Result<void>> signOutAndClearLocalState() async {
    signOutCalls += 1;
    return const Success<void>(null);
  }
}

Widget _buildApp({
  required Widget child,
  required AppUserRole role,
  required UserProfile profile,
  _FakeContextualTtsService? ttsService,
}) {
  final resolvedTtsService = ttsService ?? _FakeContextualTtsService();
  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        AuthStateSnapshot(
          hasSession: true,
          role: role,
          isBanned: profile.isBanned,
          isDeactivated: profile.accountDeletionStatus == 'deactivated_pending_cleanup',
          isProfileComplete: true,
          isResolved: true,
          profile: profile,
        ),
      ),
      currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      appLocaleProvider.overrideWith((ref) => _FixedAppLocaleController('en')),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

Widget _buildRoutedApp({
  required Widget child,
  required AppUserRole role,
  required UserProfile profile,
  _FakeContextualTtsService? ttsService,
  AuthRepository? authRepository,
}) {
  final resolvedTtsService = ttsService ?? _FakeContextualTtsService();
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: AppRoutes.supplierVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Supplier verification opened')),
      ),
      GoRoute(
        path: AppRoutes.truckerVerificationPath,
        builder: (context, state) => const Scaffold(body: Text('Trucker verification opened')),
      ),
      GoRoute(
        path: AppRoutes.fleetPath,
        builder: (context, state) => const Scaffold(body: Text('Fleet opened')),
      ),
      GoRoute(
        path: AppRoutes.profilePath,
        builder: (context, state) => const Scaffold(body: Text('Profile opened')),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        builder: (context, state) => const Scaffold(body: Text('Settings opened')),
      ),
      GoRoute(
        path: AppRoutes.supportPath,
        builder: (context, state) => const Scaffold(body: Text('Support opened')),
      ),
      GoRoute(
        path: AppRoutes.deleteAccountPath,
        builder: (context, state) => const Scaffold(body: Text('Delete account opened')),
      ),
      GoRoute(
        path: AppRoutes.authPath,
        builder: (context, state) => const Scaffold(body: Text('Auth screen opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentAuthStateProvider.overrideWithValue(
        AuthStateSnapshot(
          hasSession: true,
          role: role,
          isBanned: profile.isBanned,
          isDeactivated: profile.accountDeletionStatus == 'deactivated_pending_cleanup',
          isProfileComplete: true,
          isResolved: true,
          profile: profile,
        ),
      ),
      currentProfileProvider.overrideWith((ref) => Stream.value(profile)),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      appLocaleProvider.overrideWith((ref) => _FixedAppLocaleController('en')),
      if (authRepository != null) authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

UserProfile _profile({
  required String trustSafetyStatus,
  bool isBanned = false,
  String? trustSafetyReasonSummary,
  String accountDeletionStatus = 'active',
}) {
  return UserProfile(
    id: 'user-1',
    fullName: 'Aarav Singh',
    mobile: '9999999999',
    email: 'aarav@example.com',
    roleType: 'supplier',
    isBanned: isBanned,
    accountDeletionStatus: accountDeletionStatus,
    trustSafetyStatus: trustSafetyStatus,
    trustSafetyReasonSummary: trustSafetyReasonSummary,
  );
}

void main() {
  testWidgets('account screen shows normal trust-safety guidance for healthy accounts', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety'), findsOneWidget);
    expect(find.text('Normal'), findsAtLeastNWidgets(1));
    expect(find.textContaining('no active trust or safety enforcement'), findsOneWidget);
    expect(find.textContaining('Keep delivery proofs, payout confirmations, and marketplace communication accurate'), findsOneWidget);
    expect(find.textContaining('open support for clarification before retrying blocked actions'), findsOneWidget);
  });

  testWidgets('account screen shows trust-safety warning guidance for warned users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'warned'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety warning active'), findsOneWidget);
    expect(find.textContaining('warning on record'), findsOneWidget);
    expect(find.textContaining('clarification on the warning or next-step expectations'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('account screen trust summary support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'warned'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen trust summary support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'warned'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen shows trust-safety restriction guidance for restricted users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'restricted',
          trustSafetyReasonSummary: 'Repeated payment-proof inconsistencies',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety restriction active'), findsOneWidget);
    expect(find.textContaining('Current status: Restricted'), findsOneWidget);
    expect(find.textContaining('Reason summary: Repeated payment-proof inconsistencies'), findsOneWidget);
    expect(find.textContaining('confirm which actions are limited'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('account screen shows suspension guidance for suspended users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'suspended'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety suspension active'), findsOneWidget);
    expect(find.textContaining('Current status: Suspended'), findsOneWidget);
    expect(find.textContaining('paused while this suspension remains active'), findsOneWidget);
    expect(find.textContaining('policy-allowed review updates or reinstatement guidance'), findsOneWidget);
  });

  testWidgets('account screen suspended trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'suspended'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen suspended trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'suspended'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen shows restriction guidance for restricted users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'restricted',
          trustSafetyReasonSummary: 'Repeated payment-proof inconsistencies',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety restriction active'), findsOneWidget);
    expect(find.textContaining('Current status: Restricted'), findsOneWidget);
    expect(find.textContaining('Reason summary: Repeated payment-proof inconsistencies'), findsOneWidget);
    expect(find.textContaining('confirm which actions are limited'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('account screen shows ban guidance for banned users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety ban active'), findsOneWidget);
    expect(find.textContaining('Current status: Banned'), findsOneWidget);
    expect(find.textContaining('Reason summary: Marketplace abuse pattern confirmed'), findsOneWidget);
    expect(find.textContaining('blocked from normal platform use'), findsOneWidget);
    expect(find.textContaining('final review outcome questions'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('account screen restricted trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'restricted',
          trustSafetyReasonSummary: 'Repeated payment-proof inconsistencies',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen restricted trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(
          trustSafetyStatus: 'restricted',
          trustSafetyReasonSummary: 'Repeated payment-proof inconsistencies',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen banned trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen banned trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen verification tile opens supplier verification for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification'), findsOneWidget);

    await tester.tap(find.text('Verification'));
    await tester.pumpAndSettle();

    expect(find.text('Supplier verification opened'), findsOneWidget);
  });

  testWidgets('account screen verification tile opens trucker verification for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verification'), findsOneWidget);

    await tester.tap(find.text('Verification'));
    await tester.pumpAndSettle();

    expect(find.text('Trucker verification opened'), findsOneWidget);
  });

  testWidgets('account screen fleet tile opens fleet for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fleet'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Fleet'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fleet'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet opened'), findsOneWidget);
  });

  testWidgets('account screen profile tile opens profile for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile opened'), findsOneWidget);
  });

  testWidgets('account screen profile tile opens profile for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Profile opened'), findsOneWidget);
  });

  testWidgets('account screen settings tile opens settings for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Settings'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings opened'), findsOneWidget);
  });

  testWidgets('account screen settings tile opens settings for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Settings'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings opened'), findsOneWidget);
  });

  testWidgets('account screen support tile opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen support tile opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('account screen delete account tile opens delete account for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Delete account'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account opened'), findsOneWidget);
  });

  testWidgets('account screen delete account tile opens delete account for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Delete account'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account opened'), findsOneWidget);
  });

  testWidgets('account screen sign out action opens auth for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sign out'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Auth screen opened'), findsOneWidget);
    expect(authRepository.signOutCalls, 1);
  });

  testWidgets('account screen sign out action opens auth for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      _buildRoutedApp(
        child: const AccountScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
        authRepository: authRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign out'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sign out'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(find.text('Auth screen opened'), findsOneWidget);
    expect(authRepository.signOutCalls, 1);
  });

  testWidgets('profile screen open fleet readiness action opens fleet for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open fleet readiness'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open fleet readiness'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open fleet readiness'));
    await tester.pumpAndSettle();

    expect(find.text('Fleet opened'), findsOneWidget);
  });

  testWidgets('profile screen shows trust-safety warning guidance for warned users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'warned'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety warning active'), findsOneWidget);
    expect(find.textContaining('warning on record'), findsOneWidget);
    expect(find.textContaining('clarification on the warning or next-step expectations'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('profile screen shows suspension guidance for suspended users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'suspended'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety suspension active'), findsOneWidget);
    expect(find.textContaining('Current status: Suspended'), findsOneWidget);
    expect(find.textContaining('paused while this suspension remains active'), findsOneWidget);
    expect(find.textContaining('policy-allowed review updates or reinstatement guidance'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('profile screen shows restriction guidance with reason summary for restricted users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'restricted',
          trustSafetyReasonSummary: 'Repeated payment-proof inconsistencies',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety restriction active'), findsOneWidget);
    expect(find.textContaining('Current status: Restricted'), findsOneWidget);
    expect(find.textContaining('Reason summary: Repeated payment-proof inconsistencies'), findsOneWidget);
    expect(find.textContaining('confirm which actions are limited'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('profile screen shows ban guidance with reason summary for banned users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety ban active'), findsOneWidget);
    expect(find.textContaining('Current status: Banned'), findsOneWidget);
    expect(find.textContaining('Reason summary: Marketplace abuse pattern confirmed'), findsOneWidget);
    expect(find.textContaining('blocked from normal platform use'), findsOneWidget);
    expect(find.textContaining('final review outcome questions'), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
  });

  testWidgets('profile screen warned trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'warned'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen warned trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'warned'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen suspended trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'suspended'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen suspended trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'suspended'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'restricted'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'restricted'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen banned trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen banned trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen delete account action opens delete account for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request account deletion'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Request account deletion'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request account deletion'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account opened'), findsOneWidget);
  });

  testWidgets('profile screen delete account action opens delete account for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(trustSafetyStatus: 'normal'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Request account deletion'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Request account deletion'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Request account deletion'));
    await tester.pumpAndSettle();

    expect(find.text('Delete account opened'), findsOneWidget);
  });

  testWidgets('profile screen shows ban guidance for banned users', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trust & safety ban active'), findsOneWidget);
    expect(find.textContaining('Current status: Banned'), findsOneWidget);
    expect(find.textContaining('Reason summary: Marketplace abuse pattern confirmed'), findsOneWidget);
    expect(find.textContaining('blocked from normal platform use'), findsOneWidget);
    expect(find.textContaining('final review outcome questions'), findsOneWidget);
  });

  testWidgets('profile screen banned trust support action opens support for suppliers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen banned trust support action opens support for truckers', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        child: const ProfileScreen(),
        role: AppUserRole.trucker,
        profile: _profile(
          trustSafetyStatus: 'banned',
          isBanned: true,
          trustSafetyReasonSummary: 'Marketplace abuse pattern confirmed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open support'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Open support'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open support'));
    await tester.pumpAndSettle();

    expect(find.text('Support opened'), findsOneWidget);
  });

  testWidgets('profile screen hear summary action triggers contextual TTS', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(trustSafetyStatus: 'restricted'),
        ttsService: ttsService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hear summary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hear summary'));
    await tester.pumpAndSettle();

    expect(ttsService.lastLanguageCode, 'en');
    expect(ttsService.lastMessage, contains('Profile screen.'));
    expect(ttsService.lastMessage, contains('Trust and safety status is Restricted.'));
  });

  testWidgets('profile screen hear summary falls back to unknown for unsupported trust and account states', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildApp(
        child: const ProfileScreen(),
        role: AppUserRole.supplier,
        profile: _profile(
          trustSafetyStatus: 'mystery_flag',
          accountDeletionStatus: 'manual_cleanup_pending',
        ),
        ttsService: ttsService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hear summary'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hear summary'));
    await tester.pumpAndSettle();

    expect(ttsService.lastLanguageCode, 'en');
    expect(ttsService.lastMessage, contains('Trust and safety status is Unknown.'));
    expect(ttsService.lastMessage, contains('Account deletion status is Unknown.'));
    expect(ttsService.lastMessage, isNot(contains('Mystery Flag')));
    expect(ttsService.lastMessage, isNot(contains('Manual Cleanup Pending')));
  });
}
