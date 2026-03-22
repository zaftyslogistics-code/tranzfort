import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check get_supplier_booking_requests RPC error
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _init() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  group('DEBUG: Booking requests', () {
    testWidgets('Check RPC error', (tester) async {
      await _init();
      final client = Supabase.instance.client;

      // Sign in as supplier
      await client.auth.signInWithPassword(
        email: 'supplier@example.com',
        password: 'Tabish%%Khan721',
      );

      // Get first load
      final loads = await client
          .from('loads')
          .select('id')
          .eq('supplier_id', client.auth.currentUser!.id)
          .limit(1);

      if (loads.isEmpty) {
        print('No loads found');
        return;
      }

      final loadId = loads.first['id'];
      print('Testing with load: $loadId');

      try {
        final result = await client.rpc('get_supplier_booking_requests', params: {'p_load_id': loadId});
        print('RPC result: $result');
      } catch (e) {
        print('RPC ERROR: $e');
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  });
}
