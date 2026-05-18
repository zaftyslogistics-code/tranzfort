import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG: Check supplier profile exists for load
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
    'DEBUG: Supplier profile',
    () {
    testWidgets('Check supplier profile for existing loads', (tester) async {
      await initSupabase();
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
        debugPrint('No loads found');
        return;
      }

      final supplierId = loads.first['supplier_id'];
      debugPrint('Supplier ID from load: $supplierId');

      // Check supplier profile
      final profile = await client
          .from('profiles')
          .select('id, full_name, user_role_type')
          .eq('id', supplierId)
          .maybeSingle();
      debugPrint('Supplier profile: $profile');

      // Check suppliers extension
      final supplier = await client
          .from('suppliers')
          .select('id, company_name')
          .eq('id', supplierId)
          .maybeSingle();
      debugPrint('Supplier extension: $supplier');

      expect(profile, isNotNull, reason: 'Supplier profile should exist');

      await client.auth.signOut();
      expect(true, isTrue);
    });
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
