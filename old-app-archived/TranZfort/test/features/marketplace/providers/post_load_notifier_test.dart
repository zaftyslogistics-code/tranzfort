import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/config/maps_config.dart';
import 'package:app/src/core/repositories/load_repository.dart';
import 'package:app/src/core/services/city_search_service.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeLoadRepository extends LoadRepository {
  _FakeLoadRepository()
      : super(
          SupabaseClient(
            'http://127.0.0.1:1',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dGVzdA.sig',
          ),
        );

  Map<String, dynamic>? lastPayload;
  String? lastSupplierId;

  @override
  Future<Result<Map<String, dynamic>>> createLoad({
    required String supplierId,
    required Map<String, dynamic> payload,
  }) async {
    lastSupplierId = supplierId;
    lastPayload = payload;
    return Success({'id': 'load-1'});
  }
}

class _FakeCitySearchService extends CitySearchService {
  const _FakeCitySearchService()
      : super(
          const MapsConfig(
            apiKey: '',
            enableGooglePlaces: false,
            enableGoogleRoutes: false,
            enableGoogleGeocoding: false,
            enableOsrmFallback: true,
          ),
        );

  @override
  Future<CitySearchResult> search(String query, {int limit = 8}) async {
    final normalized = query.toLowerCase().trim();
    if (normalized == 'mumbai') {
      return const CitySearchResult(
        suggestions: [
          CitySuggestion(city: 'Mumbai', state: 'MH', lat: 19.076, lng: 72.8777),
        ],
        mode: CitySearchMode.offline,
      );
    }
    if (normalized == 'pune') {
      return const CitySearchResult(
        suggestions: [
          CitySuggestion(city: 'Pune', state: 'MH', lat: 18.5204, lng: 73.8567),
        ],
        mode: CitySearchMode.offline,
      );
    }

    return const CitySearchResult(suggestions: [], mode: CitySearchMode.offline);
  }
}

AuthState _signedInAuthState() {
  final session = Session.fromJson({
    'access_token': 'test-access-token',
    'token_type': 'bearer',
    'user': {
      'id': 'supplier-1',
      'email': 'supplier@example.com',
    },
  });

  return AuthState(AuthChangeEvent.signedIn, session);
}

void main() {
  group('PostLoadNotifier', () {
    test('nextStep requires route cities and previousStep does not go below zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postLoadProvider.notifier);
      expect(container.read(postLoadProvider).currentStep, 0);

      notifier.nextStep();
      expect(container.read(postLoadProvider).currentStep, 0);

      notifier.setOrigin('Mumbai');
      notifier.setDestination('Pune');
      notifier.nextStep();
      notifier.nextStep();
      expect(container.read(postLoadProvider).currentStep, 2);

      notifier.previousStep();
      notifier.previousStep();
      notifier.previousStep();
      expect(container.read(postLoadProvider).currentStep, 0);
    });

    test('origin and destination setters persist string values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postLoadProvider.notifier);
      notifier.setOrigin('Mumbai');
      notifier.setDestination('Pune');

      final state = container.read(postLoadProvider);
      expect(state.originCity, 'Mumbai');
      expect(state.destinationCity, 'Pune');
    });

    test('toggleTyre maintains unique selection through toggle behavior', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postLoadProvider.notifier);

      notifier.toggleTyre(12);
      notifier.toggleTyre(10);
      expect(container.read(postLoadProvider).requiredTyres, [12, 10]);

      notifier.toggleTyre(12);
      expect(container.read(postLoadProvider).requiredTyres, [10]);
    });

    test('setAdvance stores provided value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postLoadProvider.notifier);

      notifier.setAdvance(130);
      expect(container.read(postLoadProvider).advancePercentage, 130);

      notifier.setAdvance(65);
      expect(container.read(postLoadProvider).advancePercentage, 65);
    });

    test('submitLoad requires origin and destination', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
          userProfileProvider.overrideWith(
            (ref) async => {
              'id': 'supplier-1',
              'verification_status': 'verified',
              'user_role_type': 'supplier',
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(postLoadProvider.notifier);
      final ok = await notifier.submitLoad();

      expect(ok, isFalse);
    });

    test('submitLoad succeeds with signed-in user and resolvable cities', () async {
      final fakeRepository = _FakeLoadRepository();
      final container = ProviderContainer(
        overrides: [
          loadRepositoryProvider.overrideWithValue(fakeRepository),
          citySearchServiceProvider.overrideWithValue(const _FakeCitySearchService()),
          authSessionProvider.overrideWith(
            (ref) => Stream<AuthState>.value(_signedInAuthState()),
          ),
          userProfileProvider.overrideWith(
            (ref) async => {
              'id': 'supplier-1',
              'verification_status': 'verified',
              'user_role_type': 'supplier',
            },
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionProvider.future);

      final notifier = container.read(postLoadProvider.notifier);
      notifier.setOrigin('Mumbai');
      notifier.setDestination('Pune');
      notifier.setMaterial('Steel');
      notifier.setTruckType('open');
      notifier.toggleTyre(12);
      notifier.setWeight(18);
      notifier.setPrice(50000);

      notifier.nextStep();
      final ok = await notifier.submitLoad();

      expect(ok, isTrue);
      expect(fakeRepository.lastSupplierId, 'supplier-1');
      expect(fakeRepository.lastPayload?['origin_city'], 'Mumbai');
      expect(fakeRepository.lastPayload?['required_tyres'], [12]);
      expect(container.read(postLoadProvider).isSubmitting, isFalse);
    });
  });
}
