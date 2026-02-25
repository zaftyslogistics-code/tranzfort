// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:admin/src/core/config/supabase_config.dart';
import 'package:admin/src/features/auth/presentation/admin_login_screen.dart';

void main() {
  testWidgets('renders admin login smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseConfiguredProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: AdminLoginScreen()),
      ),
    );

    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('TranZfort Admin'), findsOneWidget);
    expect(find.textContaining('Supabase is not configured'), findsOneWidget);
  });
}
