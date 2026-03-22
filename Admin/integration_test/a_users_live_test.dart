import 'package:admin/src/core/repositories/admin_user_repository.dart';
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
    throw Exception('Supabase config missing for Admin live user tests.');
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

Future<AdminUserDetail?> _findFirstUsefulUserDetail(AdminUserRepository repository) async {
  const filters = <AdminUserFilter>[
    AdminUserFilter.trucker,
    AdminUserFilter.supplier,
    AdminUserFilter.all,
  ];

  for (final filter in filters) {
    final page = await repository.searchUsers(
      AdminUserListQuery(
        filter: filter,
        search: '',
      ),
    );

    for (final item in page.items) {
      final detail = await repository.getUserDetail(item.id);
      if (detail != null) {
        return detail;
      }
    }
  }

  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('A-USER live user probes', () {
    testWidgets('A-USER-001 users list and detail load through current repository contract', (tester) async {
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

      final repository = container.read(adminUserRepositoryProvider);
      final page = await repository.searchUsers(
        const AdminUserListQuery(
          filter: AdminUserFilter.all,
          search: '',
        ),
      );

      expect(page.items, isNotEmpty);
      final firstItem = page.items.first;
      expect(firstItem.id, isNotEmpty);
      expect(firstItem.role, isNotEmpty);
      expect(firstItem.email, isNotEmpty);

      final detail = await _findFirstUsefulUserDetail(repository);
      expect(detail, isNotNull);
      expect(detail!.profile.id, isNotEmpty);
      expect(detail.profile.role, isNotEmpty);
      expect(detail.roleMetadata, isNotEmpty);

      if (detail.profile.role == 'trucker') {
        expect(detail.fleetTrucks, isNotNull);
      }

      await client.auth.signOut(scope: SignOutScope.local);
    });
  });
}
