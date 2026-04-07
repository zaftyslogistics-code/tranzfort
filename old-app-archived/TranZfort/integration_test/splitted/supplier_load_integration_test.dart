import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/marketplace/presentation/my_loads_screen.dart';
import 'package:app/src/features/marketplace/presentation/post_load_screen.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Supplier load integration smoke', () {
    testWidgets('my-loads renders for signed-in supplier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith((ref) async => _supplierProfile),
            myLoadsProvider(false).overrideWith((ref) async => [
              {
                'id': 'load-1',
                'status': 'active',
                'origin_city': 'Mumbai',
                'destination_city': 'Pune',
                'material': 'Steel',
                'weight_tonnes': 24,
                'price': 64000,
                'created_at': DateTime.now().toIso8601String(),
              }
            ]),
            myLoadsProvider(true).overrideWith((ref) async => const []),
          ],
          child: MaterialApp.router(
            routerConfig: _buildRouter('/my-loads'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MyLoadsScreen), findsOneWidget);
      expect(find.textContaining('Mumbai'), findsWidgets);
    });

    testWidgets('post-load route renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authSessionProvider.overrideWith(
              (ref) => Stream.value(_signedInSupplierAuthState()),
            ),
            userProfileProvider.overrideWith((ref) async => _supplierProfile),
          ],
          child: MaterialApp.router(
            routerConfig: _buildRouter('/post-load'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PostLoadScreen), findsOneWidget);
    });
  });
}

AuthState _signedInSupplierAuthState() {
  final session = Session.fromJson({
    'access_token': 'p2-supplier-access-token',
    'token_type': 'bearer',
    'refresh_token': 'p2-supplier-refresh-token',
    'expires_in': 3600,
    'user': {
      'id': '44444444-4444-4444-4444-444444444444',
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'supplier@example.com',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-03-01T00:00:00Z',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

const Map<String, dynamic> _supplierProfile = {
  'user_role_type': 'supplier',
  'verification_status': 'verified',
  'company_name': 'Test Supplier Pvt Ltd',
  'mobile': '+919999999999',
};

GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/my-loads',
        builder: (context, state) => const MyLoadsScreen(),
      ),
      GoRoute(
        path: '/post-load',
        builder: (context, state) => const PostLoadScreen(),
      ),
    ],
  );
}
