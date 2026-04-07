// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/features/splash/presentation/splash_screen.dart';
import 'package:app/src/l10n/app_localizations.dart';

void main() {
  testWidgets('renders splash screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('TranZfort'), findsOneWidget);
    expect(
      find.text('Trusted load movement across India.'),
      findsOneWidget,
    );
  });
}
