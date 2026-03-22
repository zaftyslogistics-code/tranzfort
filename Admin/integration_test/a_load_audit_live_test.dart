import 'package:admin/src/core/repositories/admin_audit_log_repository.dart';
import 'package:admin/src/core/repositories/admin_load_management_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    throw Exception('Supabase config missing for Admin live load/audit tests.');
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

  group('A-LOAD/A-AUD live probes', () {
    testWidgets('A-LOAD-001 and A-AUD-001 current repository reads succeed', (tester) async {
      await _ensureSupabaseInitialized();

      final client = Supabase.instance.client;
      await client.auth.signOut(scope: SignOutScope.local);
      final auth = await client.auth.signInWithPassword(
        email: _adminEmail(),
        password: _testPasscode(),
      );

      expect(auth.session, isNotNull);
      expect(auth.user, isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final loadRepository = container.read(adminLoadManagementRepositoryProvider);
      final auditRepository = container.read(adminAuditLogRepositoryProvider);

      final loads = await loadRepository.getLoads(
        const AdminLoadManagementQuery(
          filter: AdminLoadFilter.all,
          search: '',
        ),
      );
      expect(loads, isA<List<AdminLoadListItem>>());

      if (loads.isNotEmpty) {
        final firstLoad = loads.first;
        expect(firstLoad.id, isNotEmpty);
        expect(firstLoad.routeLabel, isNotEmpty);
        expect(firstLoad.status, isNotEmpty);

        final detail = await loadRepository.getLoadDetail(firstLoad.id);
        expect(detail, isNotNull);
        expect(detail!.id, firstLoad.id);
        expect(detail.supplierId, firstLoad.supplierId);
        expect(detail.routeLabel, isNotEmpty);
      }

      final auditPage = await auditRepository.searchAuditLogs(
        const AdminAuditLogQuery(
          filter: AdminAuditLogFilter.all,
          search: '',
        ),
      );

      expect(auditPage.summary.totalCount, greaterThanOrEqualTo(auditPage.items.length));
      if (auditPage.items.isNotEmpty) {
        final firstAudit = auditPage.items.first;
        expect(firstAudit.id, isNotEmpty);
        expect(firstAudit.actionType, isNotEmpty);
        expect(firstAudit.targetObjectType, isNotEmpty);
      }

      await client.auth.signOut(scope: SignOutScope.local);
    });
  });
}
