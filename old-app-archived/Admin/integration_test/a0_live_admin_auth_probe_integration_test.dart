import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:admin/src/core/config/supabase_config.dart';

bool _supabaseReady = false;

Future<void> _ensureSupabaseInitialized() async {
  if (_supabaseReady) return;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // fall back to dart-define
  }

  final config = SupabaseConfig.fromEnvironment();
  if (!config.isConfigured) {
    throw Exception('Supabase config missing for admin live auth probe tests.');
  }

  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  _supabaseReady = true;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('super admin can sign in and has active admin_users role mapping', (
    tester,
  ) async {
    await _ensureSupabaseInitialized();

    final adminEmail = const String.fromEnvironment('TZ_ADMIN_EMAIL').isNotEmpty
        ? const String.fromEnvironment('TZ_ADMIN_EMAIL')
        : (dotenv.env['TZ_ADMIN_EMAIL'] ?? 'zaftyslogistics@gmail.com');
    final passcode = const String.fromEnvironment('TZ_TEST_PASSCODE').isNotEmpty
        ? const String.fromEnvironment('TZ_TEST_PASSCODE')
        : (dotenv.env['TZ_TEST_PASSCODE'] ?? 'Tabish%%Khan721');

    final client = Supabase.instance.client;
    await client.auth.signOut(scope: SignOutScope.local);

    final auth = await client.auth.signInWithPassword(
      email: adminEmail,
      password: passcode,
    );

    expect(auth.session, isNotNull);
    expect(auth.user, isNotNull);

    final adminRow = await client
        .from('admin_users')
        .select('id,email,role,is_active,auth_user_id')
        .eq('auth_user_id', auth.user!.id)
        .maybeSingle();

    debugPrint('admin row: $adminRow');
    expect(adminRow, isNotNull);
    expect(adminRow?['role'], 'super_admin');
    expect(adminRow?['is_active'], true);

    await client.auth.signOut(scope: SignOutScope.local);
  });
}
