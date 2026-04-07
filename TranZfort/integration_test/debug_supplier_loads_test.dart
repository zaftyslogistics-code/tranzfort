import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check supplier loads and their detail/bookings/trips errors
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> initSupabase() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  group('DEBUG: Supplier loads', () {
    testWidgets('Check loads and their errors', (tester) async {
      await initSupabase();
      final client = Supabase.instance.client;

      // Sign in as supplier
      await client.auth.signInWithPassword(
        email: 'supplier@example.com',
        password: 'Tabish%%Khan721',
      );

      // Get supplier loads
      final loads = await client
          .from('loads')
          .select('id, origin_city, destination_city, status')
          .eq('supplier_id', client.auth.currentUser!.id)
          .limit(5);

      debugPrint('Found ${loads.length} loads for supplier');

      for (final load in loads) {
        final loadId = load['id'];
        debugPrint('\nLoad: ${load['origin_city']} -> ${load['destination_city']} (${load['status']})');

        // Try RPC for load detail
        try {
          final detail = await client.rpc('get_load_detail_for_supplier', params: {'p_load_id': loadId});
          debugPrint('  Detail: OK - ${detail != null ? 'has data' : 'null'}');
        } catch (e) {
          debugPrint('  Detail ERROR: $e');
        }

        // Try RPC for booking requests
        try {
          final bookings = await client.rpc('get_load_booking_requests', params: {'p_load_id': loadId});
          debugPrint('  Bookings: OK - ${bookings.length} items');
        } catch (e) {
          debugPrint('  Bookings ERROR: $e');
        }

        // Try RPC for linked trips
        try {
          final trips = await client.rpc('get_linked_trips_for_supplier', params: {'p_load_id': loadId});
          debugPrint('  Trips: OK - ${trips.length} items');
        } catch (e) {
          debugPrint('  Trips ERROR: $e');
        }
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  });
}
