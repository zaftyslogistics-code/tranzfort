import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';

/// DEBUG: Check supplier loads through repository
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

  ProviderContainer buildContainer({required AppUserRole role}) {
    return ProviderContainer(
      overrides: [
        currentAuthStateProvider.overrideWithValue(
          AuthStateSnapshot(
            hasSession: true,
            role: role,
            isBanned: false,
            isDeactivated: false,
            isProfileComplete: true,
            isResolved: true,
            profile: null,
          ),
        ),
      ],
    );
  }

  group(
    'DEBUG: Supplier loads via repository',
    () {
    testWidgets('Check loads and their errors', (tester) async {
      await initSupabase();
      final client = Supabase.instance.client;

      // Sign in as supplier
      await client.auth.signInWithPassword(
        email: 'supplier@example.com',
        password: 'Tabish%%Khan721',
      );

      final container = buildContainer(role: AppUserRole.supplier);
      addTearDown(container.dispose);

      final repository = container.read(supplierLoadRepositoryProvider);

      final loadsResult = await repository.getMyLoads(const LoadFilters(), page: 1);
      debugPrint('Loads result: ${loadsResult.isSuccess ? 'SUCCESS' : 'FAIL: ${loadsResult.failureOrNull}'}');

      if (loadsResult.isSuccess) {
        final loads = loadsResult.valueOrNull!;
        debugPrint('Found ${loads.length} loads');

        for (final load in loads.take(3)) {
          debugPrint('\nLoad: ${load.originLabel} -> ${load.destinationLabel} (${load.status})');

          final detailResult = await repository.getLoadDetail(load.id);
          debugPrint('  Detail: ${detailResult.isSuccess ? 'OK' : 'FAIL: ${detailResult.failureOrNull}'}');

          final bookingsResult = await repository.getBookingRequests(load.id);
          debugPrint('  Bookings: ${bookingsResult.isSuccess ? 'OK' : 'FAIL: ${bookingsResult.failureOrNull}'}');

          final tripsResult = await repository.getLinkedTrips(load.id);
          debugPrint('  Trips: ${tripsResult.isSuccess ? 'OK' : 'FAIL: ${tripsResult.failureOrNull}'}');
        }
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  }, skip: supabaseUrl.isEmpty || supabaseAnonKey.isEmpty ? 'SUPABASE_URL and SUPABASE_ANON_KEY required (run with --dart-define)' : null);
}
