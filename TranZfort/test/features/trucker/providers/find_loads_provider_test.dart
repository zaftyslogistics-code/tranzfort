import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/find_loads_provider.dart';

class _PagedTruckerMarketplaceBackend implements TruckerMarketplaceBackend {
  final Map<int, List<Map<String, dynamic>>> pages;

  _PagedTruckerMarketplaceBackend(this.pages);

  @override
  Future<MarketplaceSearchResult> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    final rows = pages[page] ?? const <Map<String, dynamic>>[];
    final items = rows.map((row) => MarketplaceLoadItem(
      id: row['id'] as String,
      supplierId: row['supplier_id'] as String,
      originLabel: row['origin_label'] as String,
      originCity: row['origin_city'] as String,
      originState: row['origin_state'] as String,
      originLat: (row['origin_lat'] as num?)?.toDouble(),
      originLng: (row['origin_lng'] as num?)?.toDouble(),
      destinationLabel: row['destination_label'] as String,
      destinationCity: row['destination_city'] as String,
      destinationState: row['destination_state'] as String,
      destinationLat: (row['destination_lat'] as num?)?.toDouble(),
      destinationLng: (row['destination_lng'] as num?)?.toDouble(),
      routeDistanceKm: (row['route_distance_km'] as num?)?.toDouble(),
      routeDurationMinutes: row['route_duration_minutes'] as int?,
      material: row['material'] as String,
      weightTonnes: (row['weight_tonnes'] as num).toDouble(),
      requiredBodyType: row['required_body_type'] as String?,
      requiredTyres: (row['required_tyres'] as List<dynamic>).cast<int>(),
      trucksNeeded: row['trucks_needed'] as int,
      trucksBooked: row['trucks_booked'] as int,
      priceAmount: (row['price_amount'] as num).toDouble(),
      priceType: row['price_type'] as String,
      advancePercentage: row['advance_percentage'] as int,
      pickupDate: DateTime.parse(row['pickup_date'] as String),
      status: row['status'] as String,
      isSuperLoad: row['is_super_load'] as bool,
      superStatus: row['super_status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    )).toList();
    
    return MarketplaceSearchResult(
      items: items,
      total: items.length,
      hasMore: pages.containsKey(page + 1),
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

Map<String, dynamic> _loadRow(String id, {bool superLoad = false}) {
  return {
    'id': id,
    'supplier_id': 'supplier-1',
    'origin_label': 'Chandrapur, Maharashtra',
    'origin_city': 'Chandrapur',
    'origin_state': 'Maharashtra',
    'origin_lat': 19.95,
    'origin_lng': 79.29,
    'destination_label': 'Mumbai, Maharashtra',
    'destination_city': 'Mumbai',
    'destination_state': 'Maharashtra',
    'destination_lat': 19.07,
    'destination_lng': 72.87,
    'route_distance_km': 820.0,
    'route_duration_minutes': 780,
    'material': 'Coal',
    'weight_tonnes': 22.0,
    'required_body_type': 'Open',
    'required_tyres': [10, 12],
    'trucks_needed': 2,
    'trucks_booked': 1,
    'price_amount': 54000.0,
    'price_type': 'negotiable',
    'advance_percentage': 30,
    'pickup_date': '2026-03-12',
    'status': 'active',
    'is_super_load': superLoad,
    'super_status': superLoad ? 'active' : 'none',
    'created_at': '2026-03-08T12:00:00.000Z',
  };
}

void main() {
  group('FindLoadsController', () {
    test('loads initial marketplace results and paginates', () async {
      final controller = FindLoadsController(
        TruckerMarketplaceRepository(
          _PagedTruckerMarketplaceBackend({
            1: List<Map<String, dynamic>>.generate(
              50,
              (index) => _loadRow('load-${index + 1}'),
            ),
            2: [_loadRow('load-51', superLoad: true)],
          }),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.loads, hasLength(50));
      expect(controller.state.loads.first.id, 'load-1');

      await controller.loadMore();

      expect(controller.state.loads, hasLength(51));
      expect(controller.state.loads.last.id, 'load-51');
    });

    test('switches to super loads tab and reloads', () async {
      final controller = FindLoadsController(
        TruckerMarketplaceRepository(
          _PagedTruckerMarketplaceBackend({
            1: [_loadRow('load-9', superLoad: true)],
          }),
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await controller.selectTab(FindLoadsTab.superLoads);

      expect(controller.state.selectedTab, FindLoadsTab.superLoads);
      expect(controller.state.loads, hasLength(1));
    });

    test('updates filters and reloads', () async {
      final controller = FindLoadsController(
        TruckerMarketplaceRepository(
          _PagedTruckerMarketplaceBackend({
            1: [_loadRow('load-1')],
          }),
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await controller.updateFilters(const MarketplaceSearchFilters(originCity: 'Mumbai'));

      expect(controller.state.filters.originCity, 'Mumbai');
      expect(controller.state.loads, hasLength(1));
    });
  });
}
