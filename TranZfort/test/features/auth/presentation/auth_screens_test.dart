import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tranzfort/src/core/config/supabase_config.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/core/services/contextual_tts_service.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/auth/presentation/auth_screens.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeAuthRepository extends AuthRepository {
  Result<void> googleResult;
  Result<void> passwordSignInResult;
  Result<void> passwordSignUpResult;
  Result<void> resendVerificationResult;

  _FakeAuthRepository({
    required this.googleResult,
    required this.passwordSignInResult,
    required this.passwordSignUpResult,
    this.resendVerificationResult = const Success<void>(null),
  }) : super(null);

  @override
  Future<Result<void>> signInWithGoogle() async => googleResult;

  @override
  Future<Result<void>> signInWithPassword({required String email, required String password}) async =>
      passwordSignInResult;

  @override
  Future<Result<void>> signUpWithPassword({required String email, required String password}) async =>
      passwordSignUpResult;

  @override
  Future<Result<void>> resendSignUpVerificationEmail({required String email}) async =>
      resendVerificationResult;
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

Widget _buildApp({
  required AuthRepository repository,
  required Widget home,
  _FakeContextualTtsService? ttsService,
  Stream<AuthStateSnapshot>? authStateStream,
  AuthStateSnapshot authState = const AuthStateSnapshot(
    hasSession: false,
    role: AppUserRole.unknown,
    isBanned: false,
    isDeactivated: false,
    isProfileComplete: false,
    isResolved: true,
    profile: null,
  ),
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => home),
      GoRoute(path: AppRoutes.authPasswordPath, builder: (context, state) => const EmailPasswordAuthScreen()),
      GoRoute(path: AppRoutes.onboardingPath, builder: (context, state) => const Scaffold(body: Text('Onboarding opened'))),
      GoRoute(path: AppRoutes.bannedPath, builder: (context, state) => const Scaffold(body: Text('Restricted access'))),
      GoRoute(path: AppRoutes.deleteAccountPath, builder: (context, state) => const Scaffold(body: Text('Delete account'))),
    ],
  );
  final resolvedTtsService = ttsService ?? _FakeContextualTtsService();

  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfigState(
          supabaseConfig: SupabaseConfig(
            url: 'https://example.supabase.co',
            anonKey: 'anon-key',
            googleWebClientId: 'google-web-client-id',
          ),
        ),
      ),
      authRepositoryProvider.overrideWithValue(repository),
      contextualTtsServiceProvider.overrideWithValue(resolvedTtsService),
      authStateProvider.overrideWith((ref) => authStateStream ?? (() async* {
            yield authState;
          })()),
      currentAuthStateProvider.overrideWithValue(authState),
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

  testWidgets('splash routes banned users to restricted access', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_splash': true});
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        home: const SplashScreen(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: true,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Restricted access'), findsOneWidget);
  });

  testWidgets('splash routes restricted trucker users to restricted access', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_splash': true});
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        home: const SplashScreen(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: true,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Restricted access'), findsOneWidget);
  });

  testWidgets('splash routes deactivated users to delete-account flow before other resolution', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_splash': true});
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        home: const SplashScreen(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('splash routes deactivated supplier users to delete-account flow before other resolution', (tester) async {
    SharedPreferences.setMockInitialValues({'has_seen_splash': true});
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        home: const SplashScreen(),
        authState: const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.supplier,
          isBanned: false,
          isDeactivated: true,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('auth entry shows sanitized Google sign-in failure copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeAuthRepository(
      googleResult: const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail')),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const AuthEntryScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('We could not continue with Google right now. Retry shortly or use email sign-in instead.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('auth entry prompt uses the shared contextual TTS service', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );
    final ttsService = _FakeContextualTtsService();

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const AuthEntryScreen(), ttsService: ttsService),
    );
    await tester.pumpAndSettle();

    expect(ttsService.lastLanguageCode, 'hi');
    expect(ttsService.lastMessage, 'Choose how you want to sign in to TranZfort.');
  });

  testWidgets('auth entry shows inline email/password auth controls', (tester) async {
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const AuthEntryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AuthEntryScreen), findsOneWidget);
    expect(find.text('Sign in with password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in with password'), findsOneWidget);
  });

  testWidgets('email/password sign-in shows sanitized failure copy', (tester) async {
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail')),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const EmailPasswordAuthScreen()),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('Sign in with password'));
    await tester.pumpAndSettle();

    expect(find.text('We could not sign you in with email and password right now. Retry shortly or use another sign-in method.'), findsOneWidget);
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });

  testWidgets('email/password sign-in surfaces explicit email verification guidance', (tester) async {
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Failure<void>(
        BusinessRuleFailure(
          message:
              'Confirm your email before signing in. Open the verification email from TranZfort, finish verification, and then try again.',
        ),
      ),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const EmailPasswordAuthScreen()),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'user@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.text('Sign in with password'));
    await tester.pumpAndSettle();

    expect(
      find.text('Confirm your email before signing in. Open the verification email from TranZfort, finish verification, and then try again.'),
      findsOneWidget,
    );
  });

  testWidgets('email/password sign-up shows explicit check-email state when session is not ready yet', (tester) async {
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const EmailPasswordAuthScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New to TranZfort? Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'new@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('We sent a verification link to new@example.com. Open that email, finish verification, and then return here to sign in.'), findsOneWidget);
    expect(find.text('Back to sign in'), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
  });

  testWidgets('manual auth check-email state can resend verification email', (tester) async {
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
      resendVerificationResult: const Success<void>(null),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const EmailPasswordAuthScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New to TranZfort? Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'new@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();

    expect(
      find.text('We sent a fresh verification email to new@example.com. Open it, finish verification, and then sign in.'),
      findsOneWidget,
    );
  });

  testWidgets('manual auth resend verification surfaces safe failure copy', (tester) async {
    final repository = _FakeAuthRepository(
      googleResult: const Success<void>(null),
      passwordSignInResult: const Success<void>(null),
      passwordSignUpResult: const Success<void>(null),
      resendVerificationResult: const Failure<void>(UnknownFailure(message: 'PostgrestException: leaked detail')),
    );

    await tester.pumpWidget(
      _buildApp(repository: repository, home: const EmailPasswordAuthScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New to TranZfort? Create account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'new@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'password123');
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();

    expect(
      find.text('We could not resend the verification email right now. Retry shortly or use a different email.'),
      findsOneWidget,
    );
    expect(find.text('PostgrestException: leaked detail'), findsNothing);
  });
}
