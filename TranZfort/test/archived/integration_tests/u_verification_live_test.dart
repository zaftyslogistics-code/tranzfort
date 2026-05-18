import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';

bool _supabaseReady = false;

final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

Future<void> _ensureSupabaseInitialized() async {
  if (_supabaseReady) {
    return;
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    // Will be handled by group-level skip
    return;
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  _supabaseReady = true;
}

String _testPasscode() {
  return const String.fromEnvironment('TZ_TEST_PASSCODE', defaultValue: 'Tabish%%Khan721');
}

String _supplierEmail() {
  return const String.fromEnvironment('TZ_SUPPLIER_EMAIL', defaultValue: 'supplier@example.com');
}

String _truckerEmail() {
  return const String.fromEnvironment('TZ_TRUCKER_EMAIL', defaultValue: 'trucker@example.com');
}

Future<void> _signIn(SupabaseClient client, String email) async {
  await client.auth.signOut(scope: SignOutScope.local);

  final auth = await client.auth.signInWithPassword(
    email: email,
    password: _testPasscode(),
  );

  expect(auth.session, isNotNull);
  expect(auth.user, isNotNull);
  expect(client.auth.currentSession, isNotNull);
  expect(client.auth.currentUser?.email, email);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'U-VER live verification probes',
    () {
    testWidgets('U-VER-001 trucker verification detail loads through current repository contract', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signIn(client, _truckerEmail());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(verificationRepositoryProvider);
      final result = await repository.fetchCurrentDetail();

      expect(result.isSuccess, isTrue);
      final detail = result.valueOrNull;
      expect(detail, isNotNull);
      expect(detail!.profileId, client.auth.currentUser!.id);
      expect(detail.role, AppUserRole.trucker);
      expect(detail.visibleDocuments, hasLength(4), 
          reason: 'Trucker should have 4 visible docs including profilePhoto after fix');
      expect(detail.visibleDocuments.contains(VerificationDocumentType.profilePhoto), isTrue);
      expect(detail.visibleDocuments.contains(VerificationDocumentType.businessLicence), isFalse);
      expect(detail.visibleDocuments.contains(VerificationDocumentType.gstCertificate), isFalse);
      expect(detail.approvedTruckCount, greaterThanOrEqualTo(0));
      expect(detail.verificationReadyTruckCount, greaterThanOrEqualTo(0));
      expect(detail.verificationStatus.trim(), isNotEmpty);

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });

    testWidgets('U-VER-002 supplier verification detail loads through current repository contract', (tester) async {
      await _ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await _signIn(client, _supplierEmail());

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final repository = container.read(verificationRepositoryProvider);
      final result = await repository.fetchCurrentDetail();

      expect(result.isSuccess, isTrue);
      final detail = result.valueOrNull;
      expect(detail, isNotNull);
      expect(detail!.profileId, client.auth.currentUser!.id);
      expect(detail.role, AppUserRole.supplier);
      expect(detail.visibleDocuments, hasLength(6),
          reason: 'Supplier should have 6 visible docs including profilePhoto after fix');
      expect(detail.visibleDocuments.contains(VerificationDocumentType.profilePhoto), isTrue);
      expect(detail.visibleDocuments.contains(VerificationDocumentType.businessLicence), isTrue);
      expect(detail.visibleDocuments.contains(VerificationDocumentType.gstCertificate), isTrue);
      expect(detail.verificationStatus.trim(), isNotEmpty);

      await client.auth.signOut(scope: SignOutScope.local);
      expect(client.auth.currentSession, isNull);
    });
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
