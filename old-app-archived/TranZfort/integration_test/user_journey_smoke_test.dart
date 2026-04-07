import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/features/splash/presentation/splash_screen.dart';
import 'package:app/src/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User app smoke: splash renders in keyless mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: SplashScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('TranZfort'), findsOneWidget);
    expect(
      find.text('Fast. Trusted. India-first load movement.'),
      findsOneWidget,
    );
  });
}
