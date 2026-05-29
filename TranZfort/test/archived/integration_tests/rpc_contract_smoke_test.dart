import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// RPC Contract Smoke Tests
/// Validates that all critical RPCs return expected JSONB shapes and required fields.
/// This is a smoke test - it checks structure, not business logic correctness.
void main() {
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  
  group(
    'RPC Contract Smoke Tests',
    () {
      late SupabaseClient client;

      setUpAll(() async {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );

        client = Supabase.instance.client;
      });

      tearDownAll(() async {
        await Supabase.instance.dispose();
      });

    test('get_marketplace_feed returns valid JSONB structure', () async {
      try {
        final response = await client.rpc(
          'get_marketplace_feed',
          params: <String, dynamic>{
            'p_page_size': 5,
            'p_page': 1,
          },
        );

        expect(response, isA<Map<String, dynamic>>());

        final map = response as Map<String, dynamic>;
        expect(map.containsKey('loads'), isTrue);
        expect(map.containsKey('total'), isTrue);
        expect(map.containsKey('page'), isTrue);
        expect(map.containsKey('page_size'), isTrue);
        expect(map.containsKey('has_more'), isTrue);

        final loads = map['loads'];
        expect(loads, isA<List>());

        if (loads is List && loads.isNotEmpty) {
          final firstLoad = loads.first;
          expect(firstLoad, isA<Map<String, dynamic>>());
          final loadMap = firstLoad as Map<String, dynamic>;

          // Required load fields
          expect(loadMap.containsKey('id'), isTrue);
          expect(loadMap.containsKey('supplier_id'), isTrue);
          expect(loadMap.containsKey('origin_city'), isTrue);
          expect(loadMap.containsKey('destination_city'), isTrue);
          expect(loadMap.containsKey('material'), isTrue);
          expect(loadMap.containsKey('weight_tonnes'), isTrue);
          expect(loadMap.containsKey('price_amount'), isTrue);
          expect(loadMap.containsKey('price_type'), isTrue);
          expect(loadMap.containsKey('status'), isTrue);

          // Supplier summary should be embedded
          expect(loadMap.containsKey('supplier_summary'), isTrue);
          final supplierSummary = loadMap['supplier_summary'];
          if (supplierSummary != null) {
            expect(supplierSummary, isA<Map<String, dynamic>>());
          }
        }

        debugPrint('✓ get_marketplace_feed contract valid');
      } catch (e, stackTrace) {
        debugPrint('✗ get_marketplace_feed contract failed: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('get_public_profile returns valid JSONB structure', () async {
      try {
        // Use a test user ID (replace with actual test user)
        final response = await client.rpc(
          'get_public_profile',
          params: <String, dynamic>{
            'p_user_id': '00000000-0000-0000-0000-000000000000',
          },
        );

        // Can return null for non-existent user
        if (response == null) {
          debugPrint('✓ get_public_profile returns null for non-existent user (valid)');
          return;
        }

        expect(response, isA<Map<String, dynamic>>());

        final map = response as Map<String, dynamic>;
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('full_name'), isTrue);
        expect(map.containsKey('avatar_url'), isTrue);
        expect(map.containsKey('role'), isTrue);
        expect(map.containsKey('verification_status'), isTrue);
        expect(map.containsKey('trust_scores'), isTrue);
        expect(map.containsKey('role_specific'), isTrue);

        debugPrint('✓ get_public_profile contract valid');
      } catch (e, stackTrace) {
        debugPrint('✗ get_public_profile contract failed: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('get_profile_reviews returns valid JSONB structure', () async {
      try {
        final response = await client.rpc(
          'get_profile_reviews',
          params: <String, dynamic>{
            'p_user_id': '00000000-0000-0000-0000-000000000000',
            'p_limit': 5,
          },
        );

        expect(response, isA<List>());

        final list = response as List;
        if (list.isNotEmpty) {
          final firstReview = list.first;
          expect(firstReview, isA<Map<String, dynamic>>());
          final reviewMap = firstReview as Map<String, dynamic>;

          // Required review fields
          expect(reviewMap.containsKey('id'), isTrue);
          expect(reviewMap.containsKey('reviewer_id'), isTrue);
          expect(reviewMap.containsKey('reviewer_name'), isTrue);
          expect(reviewMap.containsKey('rating'), isTrue);
          expect(reviewMap.containsKey('comment'), isTrue);
          expect(reviewMap.containsKey('created_at'), isTrue);
        }

        debugPrint('✓ get_profile_reviews contract valid');
      } catch (e, stackTrace) {
        debugPrint('✗ get_profile_reviews contract failed: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('get_supplier_trip_detail returns valid JSONB structure', () async {
      try {
        final response = await client.rpc(
          'get_supplier_trip_detail',
          params: <String, dynamic>{
            'p_trip_id': '00000000-0000-0000-0000-000000000000',
            'p_supplier_id': '00000000-0000-0000-0000-000000000000',
          },
        );

        // Can return null for non-existent trip or ownership mismatch
        if (response == null) {
          debugPrint('✓ get_supplier_trip_detail returns null for invalid trip (valid)');
          return;
        }

        expect(response, isA<Map<String, dynamic>>());

        final map = response as Map<String, dynamic>;
        expect(map.containsKey('trip'), isTrue);
        expect(map.containsKey('trucker_profile'), isTrue);
        expect(map.containsKey('load_snapshot'), isTrue);
        expect(map.containsKey('truck'), isTrue);

        final trip = map['trip'];
        if (trip != null) {
          expect(trip, isA<Map<String, dynamic>>());
        }

        debugPrint('✓ get_supplier_trip_detail contract valid');
      } catch (e, stackTrace) {
        debugPrint('✗ get_supplier_trip_detail contract failed: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });

    test('get_backend_rpc_contract_version returns version string', () async {
      try {
        final response = await client.rpc('get_backend_rpc_contract_version');

        expect(response, isA<Map<String, dynamic>>());

        final map = response as Map<String, dynamic>;
        expect(map.containsKey('version'), isTrue);
        expect(map.containsKey('required_rpcs'), isTrue);

        final version = map['version'];
        expect(version, isA<String>());

        final requiredRpcs = map['required_rpcs'];
        expect(requiredRpcs, isA<List>());

        debugPrint('✓ get_backend_rpc_contract_version contract valid');
        debugPrint('  Version: $version');
        debugPrint('  Required RPCs: ${requiredRpcs.length}');
      } catch (e, stackTrace) {
        debugPrint('✗ get_backend_rpc_contract_version contract failed: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    });
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
