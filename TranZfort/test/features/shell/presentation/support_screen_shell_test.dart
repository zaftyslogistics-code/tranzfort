import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/support/data/support_repository.dart';
import 'package:tranzfort/src/features/support/presentation/support_screen.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _FakeSupportRepository extends SupportRepository {
  _FakeSupportRepository()
      : super(
          const SupabaseSupportBackend(null),
          () => 'user-1',
        );

  @override
  Future<Result<List<SupportTicket>>> getTickets({
    int limit = 20,
    DateTime? before,
  }) async {
    return const Success<List<SupportTicket>>(<SupportTicket>[]);
  }
}

Widget _buildRoutedApp() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: AppRoutes.createSupportTicketPath,
        builder: (context, state) => const Scaffold(body: Text('Create support ticket opened')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      supportRepositoryProvider.overrideWithValue(_FakeSupportRepository()),
      currentAuthStateProvider.overrideWithValue(
        const AuthStateSnapshot(
          hasSession: true,
          role: AppUserRole.trucker,
          isBanned: false,
          isDeactivated: false,
          isProfileComplete: true,
          isResolved: true,
          profile: null,
        ),
      ),
      currentProfileProvider.overrideWithValue(const AsyncData(null)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('support screen create ticket action routes to create support ticket screen', (tester) async {
    await tester.pumpWidget(_buildRoutedApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create support ticket').first);
    await tester.pumpAndSettle();

    expect(find.text('Create support ticket opened'), findsOneWidget);
  });
}
