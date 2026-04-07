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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'User router loading guard: configured app stays on splash while auth loads',
    (WidgetTester tester) async {
      final authController = StreamController<AuthState>();

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

      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('TranZfort'), findsOneWidget);
      expect(find.text('Continue your journey'), findsNothing);

      await authController.close();
    },
  );
}
