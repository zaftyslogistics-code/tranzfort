import 'package:admin/src/core/repositories/admin_verification_repository.dart';
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
    throw Exception('Supabase config missing for Admin live verification tests.');
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

Future<VerificationQueuePage> _fetchFirstNonEmptyQueue(AdminVerificationRepository repository) async {
  const tabs = <VerificationQueueTab>[
    VerificationQueueTab.trucks,
    VerificationQueueTab.truckers,
    VerificationQueueTab.suppliers,
  ];

  for (final tab in tabs) {
    final page = await repository.getVerificationQueue(
      VerificationQueueQuery(
        tab: tab,
        sort: VerificationQueueSort.newest,
        search: '',
      ),
    );
    if (page.items.isNotEmpty) {
      return page;
    }
  }

  return await repository.getVerificationQueue(
    const VerificationQueueQuery(
      tab: VerificationQueueTab.trucks,
      sort: VerificationQueueSort.newest,
      search: '',
    ),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('A-VER live verification probes', () {
    testWidgets('A-VER-001 queue and detail load through current repository contract', (tester) async {
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

      final repository = container.read(adminVerificationRepositoryProvider);
      final userRepository = container.read(adminUserRepositoryProvider);
      final page = await _fetchFirstNonEmptyQueue(repository);

      final totalCount = page.counts.suppliers + page.counts.truckers + page.counts.trucks;
      expect(totalCount, greaterThanOrEqualTo(1));
      expect(page.items, isNotEmpty);

      final item = page.items.first;
      expect(item.caseId, isNotEmpty);
      expect(item.subjectId, isNotEmpty);
      expect(item.subjectType, isNotEmpty);
      expect(item.caseStatus, isNotEmpty);

      final detail = await repository.getVerificationDetail(item.caseId);
      expect(detail, isNotNull);
      expect(detail!.caseId, item.caseId);
      expect(detail.subjectId, item.subjectId);
      expect(detail.subjectType, item.subjectType);
      expect(detail.subjectMetadata, isNotEmpty);
      expect(detail.documents, isNotEmpty);

      if (detail.subjectType == 'truck') {
        expect(detail.profileLinkId, isNotEmpty);
        final ownerDetail = await userRepository.getUserDetail(detail.profileLinkId);
        expect(ownerDetail, isNotNull);
        expect(ownerDetail!.profile.id, detail.profileLinkId);
        expect(ownerDetail.profile.role, 'trucker');
      }

      await client.auth.signOut(scope: SignOutScope.local);
    });
  });
}
