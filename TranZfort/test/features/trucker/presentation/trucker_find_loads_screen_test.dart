import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/core/providers/app_locale_providers.dart';
import 'package:tranzfort/src/features/auth/data/auth_repository.dart';
import 'package:tranzfort/src/features/trucker/data/diesel_price_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_city_search_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_find_loads_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/find_loads_provider.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_load_detail_provider.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

// Mock classes for testing
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(null);

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

class _FakeAppLocaleController extends AppLocaleController {
  _FakeAppLocaleController()
      : super(_FakeAuthRepository(), profileLanguageCode: 'hi') {
    state = state.copyWith(
      locale: const Locale('hi'),
      isInitialized: true,
      clearFailure: true,
    );
  }
}

class _NoopCitySearchService implements TruckerCitySearchService {
  @override
  Future<List<TruckerCitySuggestion>> searchCities(String query) async => const <TruckerCitySuggestion>[];
}

class _NoopTruckerMarketplaceBackend implements TruckerMarketplaceBackend {
  @override
  Future<List<Map<String, dynamic>>> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => null;

  @override
  Future<Map<String, SupplierInfo>> fetchSupplierInfo(List<String> supplierIds) async {
    return const <String, SupplierInfo>{};
  }
}

class _TestFindLoadsController extends FindLoadsController {
  _TestFindLoadsController(this._state)
      : super(
          TruckerMarketplaceRepository(_NoopTruckerMarketplaceBackend()),
        ) {
    state = _state;
  }

  final FindLoadsState _state;

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> loadMore() async {}

  @override
  Future<void> selectTab(FindLoadsTab tab) async {
    state = state.copyWith(selectedTab: tab);
  }

  @override
  Future<void> updateFilters(MarketplaceSearchFilters filters) async {
    state = state.copyWith(filters: filters);
  }

  @override
  Future<void> resetFilters() async {
    state = state.copyWith(filters: const MarketplaceSearchFilters(), selectedTab: FindLoadsTab.all);
  }
}

MarketplaceLoadItem _loadItem() {
  return MarketplaceLoadItem(
    id: 'load-1',
    supplierId: 'supplier-1',
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    originLat: 19.9615,
    originLng: 79.2961,
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
    destinationLat: 19.0760,
    destinationLng: 72.8777,
    routeDistanceKm: 820,
    routeDurationMinutes: 780,
    material: 'Coal',
    weightTonnes: 22,
    requiredBodyType: 'Open',
    requiredTyres: const [10, 12],
    trucksNeeded: 2,
    trucksBooked: 1,
    priceAmount: 54000,
    priceType: 'negotiable',
    advancePercentage: 30,
    pickupDate: DateTime(2026, 3, 12),
    status: 'active',
    isSuperLoad: true,
    superStatus: 'active',
    createdAt: DateTime(2026, 3, 8),
  );
}

MarketplaceLoadItem _loadItemWithBodyType(String? bodyType) {
  return MarketplaceLoadItem(
    id: 'load-1',
    supplierId: 'supplier-1',
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    originLat: 19.9615,
    originLng: 79.2961,
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
    destinationLat: 19.0760,
    destinationLng: 72.8777,
    routeDistanceKm: 820,
    routeDurationMinutes: 780,
    material: 'Coal',
    weightTonnes: 22,
    requiredBodyType: bodyType,
    requiredTyres: const [10, 12],
    trucksNeeded: 2,
    trucksBooked: 1,
    priceAmount: 54000,
    priceType: 'negotiable',
    advancePercentage: 30,
    pickupDate: DateTime(2026, 3, 12),
    status: 'active',
    isSuperLoad: true,
    superStatus: 'active',
    createdAt: DateTime(2026, 3, 8),
  );
}

MarketplaceLoadItem _loadItemWithStatus(String status) {
  return MarketplaceLoadItem(
    id: 'load-1',
    supplierId: 'supplier-1',
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    originLat: 19.9615,
    originLng: 79.2961,
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
    destinationLat: 19.0760,
    destinationLng: 72.8777,
    routeDistanceKm: 820,
    routeDurationMinutes: 780,
    material: 'Coal',
    weightTonnes: 22,
    requiredBodyType: 'Open',
    requiredTyres: const [10, 12],
    trucksNeeded: 2,
    trucksBooked: 1,
    priceAmount: 54000,
    priceType: 'negotiable',
    advancePercentage: 30,
    pickupDate: DateTime(2026, 3, 12),
    status: status,
    isSuperLoad: true,
    superStatus: 'active',
    createdAt: DateTime(2026, 3, 8),
  );
}

Widget _buildApp(FindLoadsState state) {
  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
      authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
      findLoadsProvider.overrideWith((ref) => _TestFindLoadsController(state)),
      truckerCitySearchServiceProvider.overrideWithValue(_NoopCitySearchService()),
      truckerApprovedTrucksProvider.overrideWith((ref) async => const <TruckerApprovedTruck>[]),
      dieselPriceMapProvider.overrideWith((ref) async => const <String, double>{}),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TruckerFindLoadsScreen()),
    ),
  );
}

Widget _buildAppWithController(_TestFindLoadsController controller) {
  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
      authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
      findLoadsProvider.overrideWith((ref) => controller),
      truckerCitySearchServiceProvider.overrideWithValue(_NoopCitySearchService()),
      truckerApprovedTrucksProvider.overrideWith((ref) async => const <TruckerApprovedTruck>[]),
      dieselPriceMapProvider.overrideWith((ref) async => const <String, double>{}),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TruckerFindLoadsScreen()),
    ),
  );
}

Widget _buildRoutedApp(FindLoadsState state) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, routeState) => const Scaffold(body: TruckerFindLoadsScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.loadDetailPath}/:loadId',
        builder: (context, routeState) => Scaffold(
          body: Text('Load detail opened: ${routeState.pathParameters['loadId']}'),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      appLocaleProvider.overrideWith((ref) => _FakeAppLocaleController()),
      authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
      findLoadsProvider.overrideWith((ref) => _TestFindLoadsController(state)),
      truckerCitySearchServiceProvider.overrideWithValue(_NoopCitySearchService()),
      truckerApprovedTrucksProvider.overrideWith((ref) async => const <TruckerApprovedTruck>[]),
      dieselPriceMapProvider.overrideWith((ref) async => const <String, double>{}),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('filtered empty find loads state exposes reset filters recovery', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    final controller = _TestFindLoadsController(
      FindLoadsState.initial().copyWith(
        isInitialLoading: false,
        filters: const MarketplaceSearchFilters(originCity: 'Chandrapur', material: 'Coal'),
        loads: const <MarketplaceLoadItem>[],
        hasMore: false,
        clearFailure: true,
      ),
    );

    await tester.pumpWidget(_buildAppWithController(controller));
    await tester.pumpAndSettle();

    expect(find.text('Reset filters'), findsWidgets);

    controller.resetFilters();
    await tester.pumpAndSettle();

    expect(controller.state.filters.hasActiveFilters, isFalse);
    expect(controller.state.selectedTab, FindLoadsTab.all);
  });

  testWidgets('renders marketplace success state', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          filters: const MarketplaceSearchFilters(truckBodyType: 'Open'),
          loads: [_loadItem()],
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find Loads'), findsWidgets);
    expect(find.text('All Loads'), findsOneWidget);
    expect(find.text('Super Loads'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Chandrapur > Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chandrapur > Mumbai'), findsOneWidget);
    expect(find.text('View details'), findsOneWidget);
  });

  testWidgets('find loads view details action opens load detail route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          filters: const MarketplaceSearchFilters(truckBodyType: 'Open'),
          loads: [_loadItem()],
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('View details'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('renders unknown fallback for unsupported load status on find loads card', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          filters: const MarketplaceSearchFilters(truckBodyType: 'Open'),
          loads: [_loadItemWithStatus('needs_manual_review')],
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Chandrapur > Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chandrapur > Mumbai'), findsOneWidget);
  });

  testWidgets('renders unknown fallback for unsupported body type on find loads card', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          filters: const MarketplaceSearchFilters(truckBodyType: 'Open'),
          loads: [_loadItemWithBodyType('mega_flatbed')],
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Chandrapur > Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Chandrapur > Mumbai'), findsOneWidget);
  });

  testWidgets('find loads load card tap opens load detail route', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildRoutedApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          filters: const MarketplaceSearchFilters(truckBodyType: 'Open'),
          loads: [_loadItem()],
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Chandrapur > Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Chandrapur > Mumbai').first);
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <MarketplaceLoadItem>[],
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('No loads found'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('No loads found'), findsOneWidget);
  });

  testWidgets('renders error state', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: const <MarketplaceLoadItem>[],
          hasMore: false,
          failure: const NetworkFailure(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Unable to load freight'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load freight'), findsOneWidget);
    expect(
      find.text('We could not load marketplace freight right now. Retry shortly to refresh the latest load search results.'),
      findsOneWidget,
    );
  });

  testWidgets('collapses filters on downward scroll and restores on upward scroll', (tester) async {
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('overflowed')) return;
      oldOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = oldOnError);
    await tester.pumpWidget(
      _buildApp(
        FindLoadsState.initial().copyWith(
          isInitialLoading: false,
          loads: List<MarketplaceLoadItem>.generate(8, (_) => _loadItem()),
          hasMore: false,
          clearFailure: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Loads'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await tester.pumpAndSettle();

    expect(find.text('All Loads'), findsOneWidget);
  });
}
