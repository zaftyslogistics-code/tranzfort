import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/load_repository.dart';
import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/features/marketplace/models/load_filters.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockLoadRepository extends Mock implements LoadRepository {}

class _FakeFindLoadsNotifier extends FindLoadsNotifier {
  _FakeFindLoadsNotifier(super.ref);

  @override
  Future<void> initialize() async {}
}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'token',
    'token_type': 'bearer',
    'user': {'id': 'trucker-1', 'email': 'trucker@example.com'},
  });
  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadFilters());
  });

  group('LoadActionNotifier', () {
    test('bookLoad fails when unauthenticated', () async {
      final repository = MockLoadRepository();
      when(
        () => repository.bookLoad(
          parentLoadId: any(named: 'parentLoadId'),
          truckerId: any(named: 'truckerId'),
          truckId: any(named: 'truckId'),
        ),
      ).thenAnswer((_) async => const Success(null));

      final container = ProviderContainer(
        overrides: [
          loadRepositoryProvider.overrideWithValue(repository),
          findLoadsProvider.overrideWith(
            (ref) => _FakeFindLoadsNotifier(ref),
          ),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(
              const AuthState(AuthChangeEvent.signedOut, null),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(loadActionProvider.notifier);
      final ok = await notifier.bookLoad('load-1');

      expect(ok, isFalse);
      expect(container.read(loadActionProvider), isA<AsyncError<void>>());
    });

    test('bookLoadWithTruck success returns true', () async {
      final repository = MockLoadRepository();
      when(
        () => repository.bookLoad(
          parentLoadId: 'load-1',
          truckerId: 'trucker-1',
          truckId: 'truck-1',
        ),
      ).thenAnswer((_) async => const Success(null));
      final container = ProviderContainer(
        overrides: [
          loadRepositoryProvider.overrideWithValue(repository),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
          findLoadsProvider.overrideWith(
            (ref) => _FakeFindLoadsNotifier(ref),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(loadActionProvider.notifier);
      final ok = await notifier.bookLoadWithTruck(
        parentLoadId: 'load-1',
        truckId: 'truck-1',
      );

      expect(ok, isTrue);
      expect(container.read(loadActionProvider), isA<AsyncData<void>>());
      verify(
        () => repository.bookLoad(
          parentLoadId: 'load-1',
          truckerId: 'trucker-1',
          truckId: 'truck-1',
        ),
      ).called(1);
    });

    test('deactivateLoad failure sets AsyncError', () async {
      final repository = MockLoadRepository();
      when(
        () => repository.deactivateLoad('load-1'),
      ).thenAnswer((_) async => const Failure(AppFailureType.network));

      final container = ProviderContainer(
        overrides: [loadRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(loadActionProvider.notifier);
      final ok = await notifier.deactivateLoad('load-1');

      expect(ok, isFalse);
      expect(container.read(loadActionProvider), isA<AsyncError<void>>());
    });
  });
}
