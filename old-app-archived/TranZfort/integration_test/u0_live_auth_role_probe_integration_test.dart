import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/src/core/config/supabase_config.dart';

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
    throw Exception('Supabase config missing for live auth probe tests.');
  }

  await Supabase.initialize(url: config.url, anonKey: config.anonKey);
  _supabaseReady = true;
}

Future<Map<String, dynamic>?> _ensureRoleSetup(
  SupabaseClient client,
  String userId,
  String expectedRole,
) async {
  var profile = await client
      .from('profiles')
      .select('id,user_role_type')
      .eq('id', userId)
      .maybeSingle();

  if (profile?['user_role_type'] == expectedRole) {
    return profile;
  }

  await client.from('profiles').update({'user_role_type': expectedRole}).eq('id', userId);

  if (expectedRole == 'trucker') {
    await client.from('truckers').upsert({'id': userId});
  } else if (expectedRole == 'supplier') {
    await client.from('suppliers').upsert({'id': userId});
  }

  profile = await client
      .from('profiles')
      .select('id,user_role_type')
      .eq('id', userId)
      .maybeSingle();

  return profile;
}

Future<void> _assertSessionRestoreAndSignOutCycle({
  required SupabaseClient client,
  required String email,
  required String passcode,
}) async {
  await client.auth.signOut(scope: SignOutScope.local);

  final auth = await client.auth.signInWithPassword(
    email: email,
    password: passcode,
  );

  expect(auth.session, isNotNull);
  expect(client.auth.currentSession, isNotNull);
  expect(client.auth.currentSession?.user.email, email);

  await client.auth.signOut(scope: SignOutScope.local);
  expect(client.auth.currentSession, isNull);
}

Future<void> _assertInvalidPasscodeRejected({
  required SupabaseClient client,
  required String email,
}) async {
  await client.auth.signOut(scope: SignOutScope.local);

  Object? failure;
  try {
    await client.auth.signInWithPassword(
      email: email,
      password: 'invalid-passcode-for-test',
    );
  } catch (error) {
    failure = error;
  }

  expect(failure, isNotNull);
  expect(failure, isA<AuthException>());
  expect(client.auth.currentSession, isNull);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('U0 live auth role probes', () {
    testWidgets('trucker@example.com can sign in and has trucker profile role', (
      tester,
    ) async {
      await _ensureSupabaseInitialized();

      final truckerEmail =
          const String.fromEnvironment('TZ_TRUCKER_EMAIL').isNotEmpty
          ? const String.fromEnvironment('TZ_TRUCKER_EMAIL')
          : (dotenv.env['TZ_TRUCKER_EMAIL'] ?? 'trucker@example.com');
      final passcode = const String.fromEnvironment('TZ_TEST_PASSCODE').isNotEmpty
          ? const String.fromEnvironment('TZ_TEST_PASSCODE')
          : (dotenv.env['TZ_TEST_PASSCODE'] ?? 'Tabish%%Khan721');

      final client = Supabase.instance.client;
      await client.auth.signOut(scope: SignOutScope.local);

      final auth = await client.auth.signInWithPassword(
        email: truckerEmail,
        password: passcode,
      );

      expect(auth.session, isNotNull);
      expect(auth.user, isNotNull);

      final profile = await _ensureRoleSetup(client, auth.user!.id, 'trucker');

      debugPrint('trucker profile row: $profile');
      expect(profile, isNotNull);
      expect(profile?['user_role_type'], 'trucker');

      await _assertSessionRestoreAndSignOutCycle(
        client: client,
        email: truckerEmail,
        passcode: passcode,
      );

      await client.auth.signOut(scope: SignOutScope.local);
    });

    testWidgets('supplier@example.com can sign in and has supplier profile role', (
      tester,
    ) async {
      await _ensureSupabaseInitialized();

      final supplierEmail =
          const String.fromEnvironment('TZ_SUPPLIER_EMAIL').isNotEmpty
          ? const String.fromEnvironment('TZ_SUPPLIER_EMAIL')
          : (dotenv.env['TZ_SUPPLIER_EMAIL'] ?? 'supplier@example.com');
      final passcode = const String.fromEnvironment('TZ_TEST_PASSCODE').isNotEmpty
          ? const String.fromEnvironment('TZ_TEST_PASSCODE')
          : (dotenv.env['TZ_TEST_PASSCODE'] ?? 'Tabish%%Khan721');

      final client = Supabase.instance.client;
      await client.auth.signOut(scope: SignOutScope.local);

      final auth = await client.auth.signInWithPassword(
        email: supplierEmail,
        password: passcode,
      );

      expect(auth.session, isNotNull);
      expect(auth.user, isNotNull);

      final profile = await _ensureRoleSetup(client, auth.user!.id, 'supplier');

      debugPrint('supplier profile row: $profile');
      expect(profile, isNotNull);
      expect(profile?['user_role_type'], 'supplier');

      await _assertSessionRestoreAndSignOutCycle(
        client: client,
        email: supplierEmail,
        passcode: passcode,
      );

      await _assertInvalidPasscodeRejected(client: client, email: supplierEmail);

      await client.auth.signOut(scope: SignOutScope.local);
    });

    testWidgets('invalid passcode is rejected for trucker and supplier personas', (
      tester,
    ) async {
      await _ensureSupabaseInitialized();

      final truckerEmail =
          const String.fromEnvironment('TZ_TRUCKER_EMAIL').isNotEmpty
          ? const String.fromEnvironment('TZ_TRUCKER_EMAIL')
          : (dotenv.env['TZ_TRUCKER_EMAIL'] ?? 'trucker@example.com');
      final supplierEmail =
          const String.fromEnvironment('TZ_SUPPLIER_EMAIL').isNotEmpty
          ? const String.fromEnvironment('TZ_SUPPLIER_EMAIL')
          : (dotenv.env['TZ_SUPPLIER_EMAIL'] ?? 'supplier@example.com');

      final client = Supabase.instance.client;
      await _assertInvalidPasscodeRejected(client: client, email: truckerEmail);
      await _assertInvalidPasscodeRejected(client: client, email: supplierEmail);
    });
  });
}
