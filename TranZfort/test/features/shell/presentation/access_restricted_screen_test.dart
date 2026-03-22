import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/shell/presentation/shell_destinations.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

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
  required AuthRepository repository,
  required AuthStateSnapshot authState,
}) {
  final router = GoRouter(
    initialLocation: AppRoutes.bannedPath,
    routes: [
      GoRoute(
        path: AppRoutes.bannedPath,
        builder: (context, state) => const AccessRestrictedScreen(),
      ),
      GoRoute(
        path: AppRoutes.authPath,
        builder: (context, state) => const Scaffold(body: Text('Auth screen opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authStateProvider.overrideWith((ref) async* {
        yield authState;
      }),
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
  testWidgets('access restricted screen shows generic restricted snackbar for suspended accounts', (tester) async {
    final repository = _FakeAuthRepository();
    const authState = AuthStateSnapshot(
      hasSession: true,
      role: AppUserRole.trucker,
      isBanned: true,
      isDeactivated: false,
      isProfileComplete: true,
      isResolved: true,
      profile: UserProfile(
        id: 'user-1',
        fullName: 'Ravi Trucker',
        mobile: '+919999999999',
        email: 'ravi@example.com',
        roleType: 'trucker',
        isBanned: false,
        accountDeletionStatus: 'active',
        trustSafetyStatus: 'suspended',
      ),
    );

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        authState: authState,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Access restricted'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(repository.signOutCalls, 0);
    expect(find.text('Account banned'), findsNothing);

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('Auth screen opened'), findsOneWidget);
  });
}
