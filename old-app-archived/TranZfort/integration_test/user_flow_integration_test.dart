import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/src/core/config/supabase_config.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/auth/presentation/auth_screen.dart';
import 'package:app/src/features/auth/presentation/phone_entry_screen.dart';
import 'package:app/src/features/auth/presentation/role_selection_screen.dart';
import 'package:app/src/features/splash/presentation/splash_screen.dart';
import 'package:app/src/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User flow integration tests', () {
    testWidgets('4.1: Splash screen renders in keyless mode', (
      WidgetTester tester,
    ) async {
      final authController = StreamController<AuthState>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
          ],
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

      await authController.close();
    });

    testWidgets('4.2: Auth screen renders in keyless mode', (
      WidgetTester tester,
    ) async {
      final authController = StreamController<AuthState>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
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

    testWidgets('4.3: Phone entry screen renders', (WidgetTester tester) async {
      final authController = StreamController<AuthState>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: PhoneEntryScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Enter your mobile number'), findsOneWidget);

      await authController.close();
    });

    testWidgets('4.4: Role selection screen renders', (
      WidgetTester tester,
    ) async {
      final authController = StreamController<AuthState>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            supabaseConfiguredProvider.overrideWithValue(false),
            authSessionProvider.overrideWith((ref) => authController.stream),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: RoleSelectionScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.text(
          'Select your role to personalize your dashboard and actions.',
        ),
        findsOneWidget,
      );
      expect(find.text('I am a Supplier / Consignor'), findsOneWidget);
      expect(find.text('I am a Trucker / Transporter'), findsOneWidget);

      await authController.close();
    });
  });
}
