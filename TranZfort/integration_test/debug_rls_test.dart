import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// QUICK DEBUG - Check load visibility for trucker
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _init() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  group('DEBUG: Load visibility', () {
    testWidgets('Direct query loads as trucker', (tester) async {
      await _init();
      final client = Supabase.instance.client;

      // Sign in as trucker
      await client.auth.signInWithPassword(
        email: 'trucker@example.com',
        password: 'Tabish%%Khan721',
      );
      expect(client.auth.currentUser, isNotNull);
      final truckerId = client.auth.currentUser!.id;
      print('Trucker ID: $truckerId');

      // Query loads directly
      final loads = await client
          .from('loads')
          .select('id, status, supplier_id, origin_city, parent_load_id')
          .limit(5);

      print('Found ${loads.length} loads');
      for (final load in loads) {
        print('Load: ${load['id']} - status: ${load['status']} - parent: ${load['parent_load_id']}');
      }

      // If we have loads, try to query one by ID (like detail repo does)
      if (loads.isNotEmpty) {
        final firstLoadId = loads.first['id'];
        print('Querying load $firstLoadId by ID...');

        final singleLoad = await client
            .from('loads')
            .select('id, status, supplier_id')
            .eq('id', firstLoadId)
            .maybeSingle();

        print('Single load query result: $singleLoad');
        expect(singleLoad, isNotNull, reason: 'Should find load by ID');
      }

      await client.auth.signOut();
    });
  });
}
