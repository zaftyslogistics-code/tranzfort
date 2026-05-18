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

Widget _buildRestrictedApp(_FakeAuthRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
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
      currentAuthStateProvider.overrideWithValue(
        const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: true,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
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

void main() {
  testWidgets('access restricted screen signs out and routes to auth', (tester) async {
    final repository = _FakeAuthRepository();

    await tester.pumpWidget(_buildRestrictedApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Access restricted'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(repository.signOutCalls, 0);

    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('Auth screen opened'), findsOneWidget);
  });

  testWidgets('app route error screen shows attempted path', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppRouteErrorScreen(attemptedPath: '/missing-path'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('/missing-path'), findsOneWidget);
  });
}
