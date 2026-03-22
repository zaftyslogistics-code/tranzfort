import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tranzfort/main.dart' as app;
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_providers.dart';
import 'package:tranzfort/src/core/providers/app_state_providers.dart';

/// DEBUG: Check supplier loads through repository
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> _init() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  ProviderContainer _buildContainer({required AppUserRole role}) {
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

  group('DEBUG: Supplier loads via repository', () {
    testWidgets('Check loads and their errors', (tester) async {
      await _init();
      final client = Supabase.instance.client;

      // Sign in as supplier
      await client.auth.signInWithPassword(
        email: 'supplier@example.com',
        password: 'Tabish%%Khan721',
      );

      final container = _buildContainer(role: AppUserRole.supplier);
      addTearDown(container.dispose);

      final repository = container.read(supplierLoadRepositoryProvider);

      // Get loads
      final loadsResult = await repository.getMyLoads(const LoadFilters(), page: 1);
      print('Loads result: ${loadsResult.isSuccess ? 'SUCCESS' : 'FAIL: ${loadsResult.failureOrNull}'}');

      if (loadsResult.isSuccess) {
        final loads = loadsResult.valueOrNull!;
        print('Found ${loads.length} loads');

        for (final load in loads.take(3)) {
          print('\nLoad: ${load.originLabel} -> ${load.destinationCity} (${load.status})');

          // Try detail
          final detailResult = await repository.getLoadDetail(load.id);
          print('  Detail: ${detailResult.isSuccess ? 'OK' : 'FAIL: ${detailResult.failureOrNull}'}');

          // Try bookings
          final bookingsResult = await repository.getBookingRequests(load.id);
          print('  Bookings: ${bookingsResult.isSuccess ? 'OK' : 'FAIL: ${bookingsResult.failureOrNull}'}');

          // Try trips
          final tripsResult = await repository.getLinkedTrips(load.id);
          print('  Trips: ${tripsResult.isSuccess ? 'OK' : 'FAIL: ${tripsResult.failureOrNull}'}');
        }
      }

      await client.auth.signOut();
      expect(true, isTrue);
    });
  });
}
