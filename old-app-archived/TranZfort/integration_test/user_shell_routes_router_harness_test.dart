import 'dart:async';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/marketplace/presentation/my_loads_screen.dart';
import 'package:app/src/features/settings/presentation/settings_screen.dart';
import 'package:app/src/features/trips/presentation/my_trips_screen.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _ShellRouterHost extends StatelessWidget {
  const _ShellRouterHost({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

GoRouter _buildShellRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/my-loads',
        builder: (context, state) => const MyLoadsScreen(),
      ),
      GoRoute(
        path: '/my-trips',
        builder: (context, state) => const MyTripsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User shell routes harness', () {
    testWidgets('Shell route /my-loads renders with GoRouter context', (
      WidgetTester tester,
    ) async {
      final authController = StreamController<AuthState>.broadcast();
      authController.add(AuthState(AuthChangeEvent.signedOut, null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/my-loads')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('My Loads'), findsAtLeastNWidgets(1));
      expect(find.text('No active loads'), findsOneWidget);

      await tester.tap(find.text('Completed').first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No completed loads'), findsOneWidget);

      await authController.close();
    });

    testWidgets('Shell route /my-trips renders with GoRouter context', (
      WidgetTester tester,
    ) async {
      final authController = StreamController<AuthState>.broadcast();
      authController.add(AuthState(AuthChangeEvent.signedOut, null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/my-trips')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('My Trips'), findsAtLeastNWidgets(1));
      expect(find.text('No active trips'), findsOneWidget);

      await tester.tap(find.text('Completed').first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('No completed trips'), findsOneWidget);

      await authController.close();
    });

    testWidgets('Shell route /settings renders with GoRouter context', (
      WidgetTester tester,
    ) async {
      final authController = StreamController<AuthState>.broadcast();
      authController.add(AuthState(AuthChangeEvent.signedOut, null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
          ],
          child: _ShellRouterHost(router: _buildShellRouter('/settings')),
        ),
      );

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Voice & notifications'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Danger zone'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Danger zone'), findsOneWidget);

      await authController.close();
    });
  });
}
