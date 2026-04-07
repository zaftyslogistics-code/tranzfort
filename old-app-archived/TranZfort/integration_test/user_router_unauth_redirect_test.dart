import 'dart:async';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/core/routing/app_router.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RouterHost extends ConsumerWidget {
  const _RouterHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    );
  }
}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'test-access-token',
    'token_type': 'bearer',
    'refresh_token': 'test-refresh-token',
    'expires_in': 3600,
    'user': {
      'id': '11111111-1111-1111-1111-111111111111',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'trucker@example.com',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-03-02T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'User router unauth redirect: configured app routes /splash to /auth',
    (WidgetTester tester) async {
      final authController = StreamController<AuthState>();
      authController.add(AuthState(AuthChangeEvent.signedOut, null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            authSessionProvider.overrideWith((ref) => authController.stream),
            userProfileProvider.overrideWith((ref) async => null),
          ],
          child: const _RouterHost(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Continue your journey'), findsOneWidget);
      expect(find.text('Continue with Phone'), findsOneWidget);

      await authController.close();
    },
  );

  testWidgets(
    'T-AUTH-04: sign-out redirects to auth and protected route stays guarded',
    (WidgetTester tester) async {
      final authController = StreamController<AuthState>.broadcast();
      authController.add(_signedInAuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            authSessionProvider.overrideWith((ref) => authController.stream),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
          ],
          child: const _RouterHost(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));

      final element = tester.element(find.byType(_RouterHost));
      final container = ProviderScope.containerOf(element);
      final router = container.read(appRouterProvider);

      authController.add(AuthState(AuthChangeEvent.signedOut, null));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Continue your journey'), findsOneWidget);

      router.go('/my-trips');
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Continue your journey'), findsOneWidget);

      await authController.close();
    },
  );
}
