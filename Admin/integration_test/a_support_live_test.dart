import 'package:admin/src/core/repositories/admin_support_repository.dart';
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
    throw Exception('Supabase config missing for Admin live support tests.');
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

Future<AdminSupportTicketPage> _fetchFirstNonEmptySupportPage(AdminSupportRepository repository) async {
  const tabs = <SupportQueueTab>[
    SupportQueueTab.open,
    SupportQueueTab.inProgress,
    SupportQueueTab.resolved,
  ];

  for (final tab in tabs) {
    final page = await repository.getSupportQueue(
      SupportQueueQuery(
        tab: tab,
        search: '',
      ),
    );
    if (page.items.isNotEmpty) {
      return page;
    }
  }

  return await repository.getSupportQueue(
    const SupportQueueQuery(
      tab: SupportQueueTab.open,
      search: '',
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('A-SUPP live support probes', () {
    testWidgets('A-SUPP-001 support queue and detail load through current repository contract', (tester) async {
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

      final repository = container.read(adminSupportRepositoryProvider);
      final page = await _fetchFirstNonEmptySupportPage(repository);
      final totalCount = page.counts.open + page.counts.inProgress + page.counts.resolved;

      expect(totalCount, greaterThanOrEqualTo(0));

      if (page.items.isNotEmpty) {
        final item = page.items.first;
        expect(item.id, isNotEmpty);
        expect(item.ownerProfileId, isNotEmpty);
        expect(item.status, isNotEmpty);
        expect(item.priority, isNotEmpty);

        final detail = await repository.getSupportTicketDetail(item.id);
        expect(detail, isNotNull);
        expect(detail!.ticket.id, item.id);
        expect(detail.ticket.ownerProfileId, item.ownerProfileId);
        expect(detail.ticket.status, item.status);
      }

      await client.auth.signOut(scope: SignOutScope.local);
    });
  });
}
