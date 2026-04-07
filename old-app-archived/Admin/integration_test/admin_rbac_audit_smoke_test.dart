import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/features/auth/presentation/admin_login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Admin app smoke: login guard guidance renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
        child: const MaterialApp(home: AdminLoginScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('TranZfort Admin'), findsOneWidget);
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });
}
