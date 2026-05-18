import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DEBUG TEST - Isolate U-FLOW-005 failure
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  Future<void> ensureSupabaseInitialized() async {
    final url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final key = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    await Supabase.initialize(url: url, anonKey: key);
  }

  Future<void> signIn(SupabaseClient client, String email) async {
    final passcode = const String.fromEnvironment('TZ_TEST_PASSCODE', defaultValue: 'TestPass123!');
    await client.auth.signInWithPassword(email: email, password: passcode);
    expect(client.auth.currentUser, isNotNull);
  }

  group('DEBUG: U-FLOW-005 Failure Analysis', () {
    testWidgets('Check supplier profile exists', (tester) async {
      await ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await signIn(client, 'supplier@example.com');

      // Check profile
      final profile = await client
          .from('profiles')
          .select('id, user_role_type, full_name')
          .eq('id', client.auth.currentUser!.id)
          .single();
      expect(profile['user_role_type'], 'supplier',
          reason: 'Supplier should have user_role_type = supplier');

      // Check suppliers record
      final supplier = await client
          .from('suppliers')
          .select('id, company_name')
          .eq('id', client.auth.currentUser!.id)
          .maybeSingle();
      expect(supplier, isNotNull,
          reason: 'Supplier should have record in suppliers table');

      await client.auth.signOut();
    });

    testWidgets('Check trucker profile exists', (tester) async {
      await ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await signIn(client, 'trucker@example.com');

      // Check profile
      final profile = await client
          .from('profiles')
          .select('id, user_role_type, full_name')
          .eq('id', client.auth.currentUser!.id)
          .single();
      expect(profile['user_role_type'], 'trucker',
          reason: 'Trucker should have user_role_type = trucker');

      // Check truckers record
      final trucker = await client
          .from('truckers')
          .select('id')
          .eq('id', client.auth.currentUser!.id)
          .maybeSingle();
      expect(trucker, isNotNull,
          reason: 'Trucker should have record in truckers table');

      await client.auth.signOut();
    });

    testWidgets('Check loads table RLS for trucker', (tester) async {
      await ensureSupabaseInitialized();
      final client = Supabase.instance.client;
      await signIn(client, 'trucker@example.com');

      // Try to query loads directly (bypassing repository)
      final loads = await client
          .from('loads')
          .select('id, status, supplier_id, origin_city')
          .limit(5);

      // This should work due to loads_trucker_select RLS policy
      expect(loads, isA<List>(),
          reason: 'Trucker should be able to query loads table');

      await client.auth.signOut();
    });

    testWidgets('Create load and verify visibility', (tester) async {
      await ensureSupabaseInitialized();
      final client = Supabase.instance.client;

      // Sign in as supplier and create a load
      await signIn(client, 'supplier@example.com');

      final result = await client.rpc('create_load', params: {
        'p_origin_label': 'Debug Origin',
        'p_origin_city': 'DebugCity',
        'p_origin_state': 'TestState',
        'p_origin_lat': 19.0,
        'p_origin_lng': 72.0,
        'p_destination_label': 'Debug Dest',
        'p_destination_city': 'DebugDestCity',
        'p_destination_state': 'TestState',
        'p_destination_lat': 20.0,
        'p_destination_lng': 73.0,
        'p_route_distance_km': 100.0,
        'p_route_duration_minutes': 120,
        'p_route_polyline': null,
        'p_route_snapshot_source': 'debug',
        'p_material': 'TestMaterial',
        'p_weight_tonnes': 5.0,
        'p_required_body_type': null,
        'p_required_tyres': null,
        'p_trucks_needed': 1,
        'p_price_amount': 5000.0,
        'p_price_type': 'fixed',
        'p_advance_percentage': 0,
        'p_pickup_date': '2026-03-25',
      });

      expect(result, isNotNull, reason: 'create_load should return load ID');
      final loadId = result.toString();
      expect(loadId.isNotEmpty, isTrue);

      // Verify load exists
      final load = await client
          .from('loads')
          .select('id, status, supplier_id')
          .eq('id', loadId)
          .single();
      expect(load['status'], 'active');

      await client.auth.signOut();

      // Sign in as trucker and try to find the load
      await signIn(client, 'trucker@example.com');

      // Wait a moment for any replication
      await Future.delayed(const Duration(seconds: 2));

      // Try to fetch the load directly
      final truckerLoad = await client
          .from('loads')
          .select('id, status, supplier_id, origin_city')
          .eq('id', loadId)
          .maybeSingle();

      // This is the key test - if this is null, RLS is blocking
      expect(truckerLoad, isNotNull,
          reason: 'Trucker should see load via RLS policy');

      if (truckerLoad != null) {
        expect(truckerLoad['status'], 'active');
      }

      await client.auth.signOut();
    });
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
