import 'dart:async';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/features/auth/presentation/auth_screen.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User auth entry smoke: keyless auth screen renders', (
    WidgetTester tester,
  ) async {
    final authController = StreamController<AuthState>();
    authController.add(AuthState(AuthChangeEvent.signedOut, null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseConfiguredProvider.overrideWithValue(false),
          authSessionProvider.overrideWith((ref) => authController.stream),
          userProfileProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: AuthScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Continue your journey'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Phone'), findsOneWidget);

    await authController.close();
  });
}
