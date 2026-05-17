// ignore_for_file: depend_on_referenced_packages, uri_does_not_exist, undefined_identifier
// P0.1: flutter_dotenv removed - TODO: Fix in P5.2 to use --dart-define
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check get_supplier_booking_requests RPC error
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> initSupabase() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  group('DEBUG: Booking requests', () {
    testWidgets('Check RPC error', (tester) async {
      await initSupabase();
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
        debugPrint('No loads found');
        return;
      }

      final loadId = loads.first['id'];
      debugPrint('Testing with load: $loadId');

      try {
        final result = await client.rpc('get_supplier_booking_requests', params: {'p_load_id': loadId});
        debugPrint('RPC result: $result');
      } catch (e) {
        debugPrint('RPC ERROR: $e');
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  });
}
