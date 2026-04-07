import 'dart:async';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/core/routing/app_router.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
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

final _testSupabaseClient = SupabaseClient(
  'https://example.supabase.co',
  'public-anon-key',
);

void _setLargeViewport(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3.0;
}

class _SeededFindLoadsNotifier extends FindLoadsNotifier {
  _SeededFindLoadsNotifier(super.ref) : super() {
    state = const FindLoadsState(
      isSearching: false,
      hasMore: false,
      results: [
        {
          'id': 'load-1',
          'origin_city': 'Pune',
          'dest_city': 'Nashik',
          'material': 'Steel',
          'weight_tonnes': 18,
          'price': 32000,
        },
      ],
    );
  }

  @override
  Future<void> initialize() async {}
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
      'email': 'router-test@tranzfort.app',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-02-27T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User router onboarded guards', () {
    testWidgets('3.4: Signed-in + phone missing routes to phone entry', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      final authController = StreamController<AuthState>();
      authController.add(_signedInAuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            supabaseClientProvider.overrideWithValue(_testSupabaseClient),
            authSessionProvider.overrideWith((ref) => authController.stream),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': null,
              },
            ),
          ],
          child: const _RouterHost(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('Enter your mobile number'), findsOneWidget);

      await authController.close();
    });

    testWidgets('3.5: Signed-in + role missing routes to role selection', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      final authController = StreamController<AuthState>();
      authController.add(_signedInAuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            supabaseClientProvider.overrideWithValue(_testSupabaseClient),
            authSessionProvider.overrideWith((ref) => authController.stream),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': null,
                'mobile': '+919999999999',
              },
            ),
          ],
          child: const _RouterHost(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 900));

      expect(
        find.text(
          'Select your role to personalize your dashboard and actions.',
        ),
        findsOneWidget,
      );

      await authController.close();
    });

    testWidgets('3.6: Fully onboarded supplier routes to /supplier-dashboard', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      final authController = StreamController<AuthState>();
      authController.add(_signedInAuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            supabaseClientProvider.overrideWithValue(_testSupabaseClient),
            authSessionProvider.overrideWith((ref) => authController.stream),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'supplier',
                'mobile': '+919999999999',
              },
            ),
          ],
          child: const _RouterHost(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('My Loads'), findsAtLeastNWidgets(1));

      await authController.close();
    });

    testWidgets('3.7: Fully onboarded trucker routes to /find-loads', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      final authController = StreamController<AuthState>();
      authController.add(_signedInAuthState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(true),
            supabaseClientProvider.overrideWithValue(_testSupabaseClient),
            authSessionProvider.overrideWith((ref) => authController.stream),
            userProfileProvider.overrideWith(
              (ref) async => <String, dynamic>{
                'user_role_type': 'trucker',
                'mobile': '+919999999999',
              },
            ),
            findLoadsProvider.overrideWith(
              (ref) => _SeededFindLoadsNotifier(ref),
            ),
          ],
          child: const _RouterHost(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1000));

      expect(find.text('Find Loads'), findsAtLeastNWidgets(1));

      await authController.close();
    });

    testWidgets('T-AUTH-03: signed-in trucker session restores after app restart', (
      WidgetTester tester,
    ) async {
      _setLargeViewport(tester);
      addTearDown(tester.view.reset);

      Future<void> pumpHost() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseConfiguredProvider.overrideWithValue(true),
              supabaseClientProvider.overrideWithValue(_testSupabaseClient),
              authSessionProvider.overrideWith(
                (ref) => Stream.value(_signedInAuthState()),
              ),
              userProfileProvider.overrideWith(
                (ref) async => <String, dynamic>{
                  'user_role_type': 'trucker',
                  'mobile': '+919999999999',
                },
              ),
              findLoadsProvider.overrideWith((ref) => _SeededFindLoadsNotifier(ref)),
            ],
            child: const _RouterHost(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 1000));
      }

      await pumpHost();
      expect(find.text('Find Loads'), findsAtLeastNWidgets(1));

      await pumpHost();
      expect(find.text('Find Loads'), findsAtLeastNWidgets(1));
    });
  });
}
