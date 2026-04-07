import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/services/database_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/fleet/providers/fleet_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'token',
    'token_type': 'bearer',
    'user': {'id': 'user-1', 'email': 'user@example.com'},
  });
  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  group('FleetProvider', () {
    test('returns fleet on success', () async {
      final db = MockDatabaseService();
      when(
        () => db.get('trucks', filterColumn: 'owner_id', filterValue: 'user-1'),
      ).thenAnswer((_) async => Success([
            {'id': 'truck-1'}
          ]));

      final container = ProviderContainer(
        overrides: [
          fleetDatabaseServiceProvider.overrideWithValue(db),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);
      final fleet = await container.read(fleetProvider.future);

      expect(fleet.length, 1);
      expect(fleet.first['id'], 'truck-1');
    });

    test('returns empty list on failure', () async {
      final db = MockDatabaseService();
      when(
        () => db.get('trucks', filterColumn: 'owner_id', filterValue: 'user-1'),
      ).thenAnswer((_) async => Failure(AppFailureType.network));

      final container = ProviderContainer(
        overrides: [
          fleetDatabaseServiceProvider.overrideWithValue(db),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);
      final fleet = await container.read(fleetProvider.future);

      expect(fleet, isEmpty);
    });
  });
}
