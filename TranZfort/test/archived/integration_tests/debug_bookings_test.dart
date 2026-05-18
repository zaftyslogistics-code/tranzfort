import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check get_supplier_booking_requests RPC error
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
    'DEBUG: Booking requests',
    () {
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
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
