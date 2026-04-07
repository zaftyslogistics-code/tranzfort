import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/auth_repository.dart';
import 'package:app/src/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

User _buildUser() {
  return User.fromJson({
    'id': 'user-1',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'test@example.com',
    'created_at': '2024-01-01T00:00:00.000Z',
  })!;
}

void main() {
  group('Auth action notifiers', () {
    test('AuthEntryNotifier continueWithGoogle success updates state', () async {
      final repository = MockAuthRepository();
      when(() => repository.signInWithGoogle())
          .thenAnswer((_) async => Success(_buildUser()));

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authEntryProvider.notifier);
      final result = await notifier.continueWithGoogle();

      expect(result, isA<Success<void>>());
      expect(container.read(authEntryProvider).isLoading, isFalse);
      expect(container.read(authEntryProvider).lastError, isNull);
    });

    test('AuthEntryNotifier continueWithGoogle failure exposes error', () async {
      final repository = MockAuthRepository();
      when(() => repository.signInWithGoogle())
          .thenAnswer((_) async => Failure(AppFailureType.network));

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authEntryProvider.notifier);
      final result = await notifier.continueWithGoogle();

      expect(result, isA<Failure<void>>());
      expect(container.read(authEntryProvider).lastError, AppFailureType.network);
    });

    test('AuthEntryNotifier sendOtp success clears errors', () async {
      final repository = MockAuthRepository();
      when(() => repository.sendOtp('+911234567890'))
          .thenAnswer((_) async => const Success(null));

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authEntryProvider.notifier);
      final result = await notifier.sendOtp('+911234567890');

      expect(result, isA<Success<void>>());
      expect(container.read(authEntryProvider).lastError, isNull);
    });

    test('AuthEntryNotifier saveMobileWithoutOtp forwards failure', () async {
      final repository = MockAuthRepository();
      when(() => repository.saveMobileNumber('+911234567890'))
          .thenAnswer((_) async => Failure(AppFailureType.auth));

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authEntryProvider.notifier);
      final result = await notifier.saveMobileWithoutOtp('+911234567890');

      expect(result, isA<Failure<void>>());
      expect(container.read(authEntryProvider).lastError, AppFailureType.auth);
    });

    test('OtpVerificationNotifier verifyOtp success clears errors', () async {
      final repository = MockAuthRepository();
      when(() => repository.verifyOtp('+911234567890', '123456'))
          .thenAnswer((_) async => Success(_buildUser()));

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authOtpVerificationProvider.notifier);
      final result = await notifier.verifyOtp('+911234567890', '123456');

      expect(result, isA<Success<void>>());
      expect(container.read(authOtpVerificationProvider).lastError, isNull);
    });

    test('OtpVerificationNotifier verifyOtp failure sets error', () async {
      final repository = MockAuthRepository();
      when(() => repository.verifyOtp('+911234567890', '123456'))
          .thenAnswer((_) async => Failure(AppFailureType.network));

      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authOtpVerificationProvider.notifier);
      final result = await notifier.verifyOtp('+911234567890', '123456');

      expect(result, isA<Failure<void>>());
      expect(
        container.read(authOtpVerificationProvider).lastError,
        AppFailureType.network,
      );
    });

    test('RoleSetupNotifier returns auth failure with no user session', () async {
      final client = MockSupabaseClient();
      final auth = MockGoTrueClient();
      when(() => client.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authRoleSetupProvider.notifier);
      final result = await notifier.submitRole('supplier');

      expect(result, isA<Failure<void>>());
      expect(container.read(authRoleSetupProvider).lastError, AppFailureType.auth);
    });
  });
}
