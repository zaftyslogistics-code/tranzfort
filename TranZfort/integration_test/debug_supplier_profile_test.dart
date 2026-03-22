import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check supplier profile exists for load
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _init() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  group('DEBUG: Supplier profile', () {
    testWidgets('Check supplier profile for existing loads', (tester) async {
      await _init();
      final client = Supabase.instance.client;

      // Sign in as trucker
      await client.auth.signInWithPassword(
        email: 'trucker@example.com',
        password: 'Tabish%%Khan721',
      );

      // Get a load
      final loads = await client
          .from('loads')
          .select('id, supplier_id, origin_city')
          .limit(1);

      if (loads.isEmpty) {
        print('No loads found');
        return;
      }

      final supplierId = loads.first['supplier_id'];
      print('Supplier ID from load: $supplierId');

      // Check supplier profile
      final profile = await client
          .from('profiles')
          .select('id, full_name, user_role_type')
          .eq('id', supplierId)
          .maybeSingle();
      print('Supplier profile: $profile');

      // Check suppliers extension
      final supplier = await client
          .from('suppliers')
          .select('id, company_name')
          .eq('id', supplierId)
          .maybeSingle();
      print('Supplier extension: $supplier');

      expect(profile, isNotNull, reason: 'Supplier profile should exist');

      await client.auth.signOut();
    });
  });
}
