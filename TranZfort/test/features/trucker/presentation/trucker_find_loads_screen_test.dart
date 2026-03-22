import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tranzfort/src/core/navigation/app_routes.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/diesel_price_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_city_search_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/features/trucker/presentation/trucker_find_loads_screen.dart';
import 'package:tranzfort/src/features/trucker/providers/find_loads_provider.dart';
import 'package:tranzfort/src/features/trucker/providers/trucker_load_detail_provider.dart';
import 'package:tranzfort/src/l10n/app_localizations.dart';

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
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
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
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
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
    originLabel: 'Chandrapur, Maharashtra',
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    destinationLabel: 'Mumbai, Maharashtra',
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
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

    expect(find.text('Reset filters'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Reset filters'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();

    expect(controller.state.filters.hasActiveFilters, isFalse);
    expect(controller.state.selectedTab, FindLoadsTab.all);
    expect(find.text('Reset filters'), findsNothing);
  });

  testWidgets('renders marketplace success state', (tester) async {
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
    expect(find.text('Marketplace tabs'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Chandrapur → Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chandrapur → Mumbai'), findsOneWidget);
    expect(find.text('Super Load • Payment Guarantee'), findsOneWidget);
    expect(find.text('Coal • 22T • Open'), findsOneWidget);
    expect(find.text('ACTIVE'), findsWidgets);
  });

  testWidgets('find loads view details action opens load detail route', (tester) async {
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
      find.textContaining('Chandrapur → Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('UNKNOWN'), findsWidgets);
    expect(find.text('Needs Manual Review'), findsNothing);
  });

  testWidgets('renders unknown fallback for unsupported body type on find loads card', (tester) async {
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
      find.textContaining('Chandrapur → Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Coal • 22T • Unknown'), findsOneWidget);
    expect(find.text('mega_flatbed'), findsNothing);
  });

  testWidgets('find loads load card tap opens load detail route', (tester) async {
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
      find.textContaining('Chandrapur → Mumbai'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Chandrapur → Mumbai').first);
    await tester.pumpAndSettle();

    expect(find.text('Load detail opened: load-1'), findsOneWidget);
  });

  testWidgets('renders empty state', (tester) async {
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

    expect(find.text('Marketplace tabs'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('Marketplace tabs'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();

    expect(find.text('Marketplace tabs'), findsOneWidget);
  });
}
