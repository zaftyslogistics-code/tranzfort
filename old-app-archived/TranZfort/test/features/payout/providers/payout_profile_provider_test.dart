import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/services/database_service.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:app/src/features/payout/providers/payout_profile_provider.dart';
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
  group('PayoutProfileProvider', () {
    test('returns profile on success', () async {
      final db = MockDatabaseService();
      when(
        () => db.getSingle(
          'payout_profiles',
          filterColumn: 'profile_id',
          filterValue: 'user-1',
        ),
      ).thenAnswer((_) async => Success({'status': 'verified'}));

      final container = ProviderContainer(
        overrides: [
          payoutDbProvider.overrideWithValue(db),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final profile = await container.read(payoutProfileProvider.future);
      expect(profile?['status'], 'verified');
    });

    test('returns null on failure', () async {
      final db = MockDatabaseService();
      when(
        () => db.getSingle(
          'payout_profiles',
          filterColumn: 'profile_id',
          filterValue: 'user-1',
        ),
      ).thenAnswer((_) async => Failure(AppFailureType.network));

      final container = ProviderContainer(
        overrides: [
          payoutDbProvider.overrideWithValue(db),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final profile = await container.read(payoutProfileProvider.future);
      expect(profile, isNull);
    });
  });
}
