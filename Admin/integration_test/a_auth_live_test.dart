import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseReady = false;

Future<void> _ensureSupabaseInitialized() async {
  if (_supabaseReady) {
    return;
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  final url = dotenv.env['SUPABASE_URL'] ?? const String.fromEnvironment('SUPABASE_URL');
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? const String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception('Supabase config missing for Admin live auth tests.');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
  _supabaseReady = true;
}

String _testPasscode() {
  final fromDefine = const String.fromEnvironment('TZ_TEST_PASSCODE');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_TEST_PASSCODE'] ?? 'Tabish%%Khan721';
}

String _adminEmail() {
  final fromDefine = const String.fromEnvironment('TZ_ADMIN_EMAIL');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_ADMIN_EMAIL'] ?? 'zaftyslogistics@gmail.com';
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('A-AUTH live auth probes', () {
    testWidgets('A-AUTH-001 admin auth resolves to active admin_users row', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;

      await client.auth.signOut(scope: SignOutScope.local);

      final auth = await client.auth.signInWithPassword(
        email: _adminEmail(),
        password: _testPasscode(),
      );

      expect(auth.session, isNotNull);
      expect(auth.user, isNotNull);
      expect(client.auth.currentUser?.email, _adminEmail());

      final adminRow = await client
          .from('admin_users')
          .select('id,email,role,is_active,auth_user_id')
          .eq('auth_user_id', auth.user!.id)
          .maybeSingle();

      expect(adminRow, isNotNull);
      expect(adminRow?['is_active'], true);
      expect(adminRow?['role'], anyOf('super_admin', 'ops_admin'));

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });
  });
}
