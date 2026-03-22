import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/auth/presentation/onboarding_screens.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeOnboardingAuthRepository extends AuthRepository {
  Result<void> updateRoleResult;
  Result<void> provisionRoleResult;
  Result<void> updateProfileResult;

  _FakeOnboardingAuthRepository({
    required this.updateRoleResult,
    required this.provisionRoleResult,
    required this.updateProfileResult,
  }) : super(null);

  @override
  Future<Result<void>> updateRoleSelection(AppUserRole role) async => updateRoleResult;

  @override
  Future<Result<void>> provisionRoleExtension(AppUserRole role) async => provisionRoleResult;

  @override
  Future<Result<void>> updateProfile({required String fullName, required String mobile}) async => updateProfileResult;

  @override
  Future<Result<void>> recordTermsAcceptance() async => const Success<void>(null);
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
          preferencesFn: SharedPreferences.getInstance,
        );

  @override
  Future<ContextualTtsOutcome> speakSummary({required String languageCode, required String message}) async {
    lastLanguageCode = languageCode;
    lastMessage = message;
    return ContextualTtsOutcome.spoken;
  }
}

Widget _buildApp({
  required AuthRepository repository,
  required Widget home,
  UserProfile? profile,
  _FakeContextualTtsService? ttsService,
}) {
  final resolvedTtsService = ttsService ?? _FakeContextualTtsService();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      authStateProvider.overrideWith((ref) => const Stream<AuthStateSnapshot>.empty()),
      currentAuthStateProvider.overrideWithValue(
        AuthStateSnapshot(
          hasSession: true,
          role: profile?.role ?? AppUserRole.unknown,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: false,
          isResolved: true,
          profile: profile,
        ),
      ),
      currentProfileProvider.overrideWithValue(AsyncValue.data(profile)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Widget _buildRoutedApp({
  required AuthRepository repository,
  required AuthStateSnapshot authState,
  UserProfile? profile,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.onboardingPath,
    redirect: (context, state) {
      if (state.uri.path != AppRoutes.onboardingPath) {
        return null;
      }

      final hasKnownRole = (profile?.hasRole ?? false) || authState.role != AppUserRole.unknown;
      if (!hasKnownRole) {
        return AppRoutes.onboardingRolePath;
      }

      final hasName = profile?.hasName ?? false;
      final hasMobile = profile?.hasMobile ?? false;
      if (!(hasName && hasMobile && hasKnownRole)) {
        return AppRoutes.onboardingProfilePath;
      }

      return authState.role == AppUserRole.supplier
          ? AppRoutes.supplierDashboardPath
          : AppRoutes.truckerDashboardPath;
    },
    routes: [
      GoRoute(path: AppRoutes.onboardingPath, builder: (context, state) => const OnboardingGateScreen()),
      GoRoute(path: AppRoutes.onboardingRolePath, builder: (context, state) => const Scaffold(body: Text('Role selection opened'))),
      GoRoute(path: AppRoutes.onboardingProfilePath, builder: (context, state) => const Scaffold(body: Text('Profile completion opened'))),
      GoRoute(path: AppRoutes.supplierDashboardPath, builder: (context, state) => const Scaffold(body: Text('Supplier dashboard opened'))),
      GoRoute(path: AppRoutes.truckerDashboardPath, builder: (context, state) => const Scaffold(body: Text('Trucker dashboard opened'))),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authStateProvider.overrideWith((ref) async* {
        yield authState;
      }),
      currentAuthStateProvider.overrideWithValue(authState),
      currentProfileProvider.overrideWithValue(AsyncValue.data(profile)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding gate skips role selection when auth state already knows the role', (tester) async {
    final repository = _FakeOnboardingAuthRepository(
      updateRoleResult: const Success<void>(null),
      provisionRoleResult: const Success<void>(null),
      updateProfileResult: const Success<void>(null),
    );

    const authState = AuthStateSnapshot(
      hasSession: true,
      role: AppUserRole.supplier,
      isBanned: false,
      isDeactivated: false,
      isProfileComplete: false,
      isResolved: true,
      profile: null,
    );

    const profile = UserProfile(
      id: 'user-1',
      fullName: '',
      mobile: null,
      email: 'supplier@example.com',
      roleType: null,
      isBanned: false,
      accountDeletionStatus: 'active',
      trustSafetyStatus: 'normal',
    );

    await tester.pumpWidget(
      _buildRoutedApp(
        repository: repository,
        authState: authState,
        profile: profile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile completion opened'), findsOneWidget);
    expect(find.text('Role selection opened'), findsNothing);
  });

  testWidgets('role selection shows sanitized workspace provisioning failure copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeOnboardingAuthRepository(
      updateRoleResult: const Success<void>(null),
      provisionRoleResult: const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail')),
      updateProfileResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const RoleSelectionScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supplier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('We could not prepare your role workspace right now. Retry shortly after selecting your role again.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('profile completion shows sanitized profile save failure copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const profile = UserProfile(
      id: 'user-1',
      fullName: 'Amit Supplier',
      mobile: '+919999999999',
      email: 'amit@example.com',
      roleType: 'supplier',
      isBanned: false,
      accountDeletionStatus: 'active',
      trustSafetyStatus: 'normal',
    );

    final repository = _FakeOnboardingAuthRepository(
      updateRoleResult: const Success<void>(null),
      provisionRoleResult: const Success<void>(null),
      updateProfileResult: const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail')),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const ProfileCompletionScreen(), profile: profile),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Amit Supplier');
    await tester.enterText(find.byType(TextField).at(1), '+919999999999');
    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();

    expect(find.text('We could not save your profile right now. Review the details and retry shortly.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('role selection prompt uses the shared contextual TTS service', (tester) async {
    final repository = _FakeOnboardingAuthRepository(
      updateRoleResult: const Success<void>(null),
      provisionRoleResult: const Success<void>(null),
      updateProfileResult: const Success<void>(null),
    );
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        home: const RoleSelectionScreen(),
        ttsService: ttsService,
      ),
    );
    await tester.pumpAndSettle();

    expect(ttsService.lastLanguageCode, 'hi');
    expect(ttsService.lastMessage, 'Choose your role to continue onboarding.');
  });
}
