import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// QUICK DEBUG - Check load visibility for trucker
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  Future<void> initSupabase() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  group(
    'DEBUG: Load visibility',
    () {
    testWidgets('Direct query loads as trucker', (tester) async {
      await initSupabase();
      final client = Supabase.instance.client;

      // Sign in as trucker
      await client.auth.signInWithPassword(
        email: 'trucker@example.com',
        password: 'Tabish%%Khan721',
      );
      expect(client.auth.currentUser, isNotNull);
      final truckerId = client.auth.currentUser!.id;
      debugPrint('Trucker ID: $truckerId');

      // Query loads directly
      final loads = await client
          .from('loads')
          .select('id, status, supplier_id, origin_city, parent_load_id')
          .limit(5);

      debugPrint('Found ${loads.length} loads');
      for (final load in loads) {
        debugPrint('Load: ${load['id']} - status: ${load['status']} - parent: ${load['parent_load_id']}');
      }

      // If we have loads, try to query one by ID (like detail repo does)
      if (loads.isNotEmpty) {
        final firstLoadId = loads.first['id'];
        debugPrint('Querying load $firstLoadId by ID...');

        final singleLoad = await client
            .from('loads')
            .select('id, status, supplier_id')
            .eq('id', firstLoadId)
            .maybeSingle();

        debugPrint('Single load query result: $singleLoad');
        expect(singleLoad, isNotNull, reason: 'Should find load by ID');
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
