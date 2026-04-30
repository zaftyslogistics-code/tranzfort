import 'dart:io';

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
    throw Exception('Supabase config missing for TranZfort live auth tests.');
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

String _supplierEmail() {
  final fromDefine = const String.fromEnvironment('TZ_SUPPLIER_EMAIL');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_SUPPLIER_EMAIL'] ?? 'testa@example.com';
}

String _truckerEmail() {
  final fromDefine = const String.fromEnvironment('TZ_TRUCKER_EMAIL');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }
  return dotenv.env['TZ_TRUCKER_EMAIL'] ?? 'testt@example.com';
}

Future<Map<String, dynamic>?> _loadProfile(SupabaseClient client, String userId) {
  return client
      .from('profiles')
      .select('id,user_role_type,verification_status,email')
      .eq('id', userId)
      .maybeSingle();
}

bool _isRetryableError(Object error) {
  if (error is SocketException || error is HttpException) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('failed host lookup') ||
      message.contains('software caused connection abort') ||
      message.contains('authretryablefetchexception') ||
      message.contains('clientexception');
}

Future<T> _withRetry<T>(Future<T> Function() action) async {
  const maxAttempts = 6;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (error) {
      final canRetry = attempt < maxAttempts && _isRetryableError(error);
      if (!canRetry) {
        rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 1200 * attempt));
    }
  }

  throw StateError('Retry flow reached unreachable state.');
}

Future<void> _assertSignInAndRole({
  required SupabaseClient client,
  required String email,
  required String expectedRole,
}) async {
  await _withRetry(() => client.auth.signOut(scope: SignOutScope.local));

  final auth = await _withRetry(
    () => client.auth.signInWithPassword(
      email: email,
      password: _testPasscode(),
    ),
  );

  expect(auth.session, isNotNull);
  expect(auth.user, isNotNull);
  expect(client.auth.currentSession, isNotNull);
  expect(client.auth.currentUser?.email, email);

  final profile = await _withRetry(() => _loadProfile(client, auth.user!.id));
  expect(profile, isNotNull);
  expect(profile?['user_role_type'], expectedRole);

  await _withRetry(() => client.auth.signOut(scope: SignOutScope.local));
  expect(client.auth.currentSession, isNull);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('U-AUTH live auth probes', () {
    testWidgets('U-AUTH-001 supplier auth resolves to supplier profile', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;

      await _assertSignInAndRole(
        client: client,
        email: _supplierEmail(),
        expectedRole: 'supplier',
      );
    });

    testWidgets('U-AUTH-002 trucker auth resolves to trucker profile', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;

      await _assertSignInAndRole(
        client: client,
        email: _truckerEmail(),
        expectedRole: 'trucker',
      );
    });
  });
}
