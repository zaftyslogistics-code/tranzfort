import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/trucker/data/diesel_price_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_city_search_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_find_loads_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/find_loads_provider.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_load_detail_provider.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

class _SmokeAuthRepository extends AuthRepository {
  _SmokeAuthRepository() : super(null);

  Stream<AuthState> get authStateChanges => Stream.value(
        AuthState(
          AuthChangeEvent.signedIn,
          Session(
            accessToken: 'test-token',
            tokenType: 'bearer',
            user: User(
              id: 'test-user',
              email: 'test@test.com',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              createdAt: DateTime.now().toIso8601String(),
            ),
          ),
        ),
      );

  Future<String?> get currentUserId async => 'test-user';

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> updatePreferredLanguage(String languageCode) async => const Success(null);
}

class _SmokeLocaleController extends AppLocaleController {
  _SmokeLocaleController()
      : super(_SmokeAuthRepository(), profileLanguageCode: 'hi') {
    state = state.copyWith(
      locale: const Locale('hi'),
      isInitialized: true,
      clearFailure: true,
    );
  }
}

class _SmokeCitySearchService implements TruckerCitySearchService {
  @override
  Future<List<TruckerCitySuggestion>> searchCities(String query) async => const <TruckerCitySuggestion>[];
}

class _SmokeMarketplaceBackend implements TruckerMarketplaceBackend {
  @override
  Future<MarketplaceSearchResult> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    return MarketplaceSearchResult(
      items: const <MarketplaceLoadItem>[],
      total: 0,
      hasMore: false,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => null;

  @override
  Future<Map<String, SupplierInfo>> fetchSupplierInfo(List<String> supplierIds) async {
    return const <String, SupplierInfo>{};
  }
}

class _SmokeFindLoadsController extends FindLoadsController {
  _SmokeFindLoadsController()
      : super(
          TruckerMarketplaceRepository(_SmokeMarketplaceBackend()),
        ) {
    state = FindLoadsState.initial().copyWith(
      isInitialLoading: false,
      loads: const <MarketplaceLoadItem>[],
      hasMore: false,
      clearFailure: true,
    );
  }

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}
}

void main() {
  testWidgets('refactored trucker find loads screen renders smoke state', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLocaleProvider.overrideWith((ref) => _SmokeLocaleController()),
          authRepositoryProvider.overrideWith((ref) => _SmokeAuthRepository()),
          findLoadsProvider.overrideWith((ref) => _SmokeFindLoadsController()),
          truckerCitySearchServiceProvider.overrideWithValue(_SmokeCitySearchService()),
          truckerApprovedTrucksProvider.overrideWith((ref) async => const <TruckerApprovedTruck>[]),
          dieselPriceMapProvider.overrideWith((ref) async => const <String, double>{}),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TruckerFindLoadsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find Loads'), findsWidgets);
    expect(find.text('All Loads'), findsOneWidget);
    expect(find.text('Super Loads'), findsOneWidget);
    expect(find.text('No loads found'), findsOneWidget);
  });
}
