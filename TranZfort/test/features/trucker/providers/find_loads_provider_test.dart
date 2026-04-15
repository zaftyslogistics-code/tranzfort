import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/features/trucker/providers/find_loads_provider.dart';

class _PagedTruckerMarketplaceBackend implements TruckerMarketplaceBackend {
  final Map<int, List<Map<String, dynamic>>> pages;

  _PagedTruckerMarketplaceBackend(this.pages);

  @override
  Future<List<Map<String, dynamic>>> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    return pages[page] ?? const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async => null;
}

Map<String, dynamic> _loadRow(String id, {bool superLoad = false}) {
  return {
    'id': id,
    'origin_label': 'Chandrapur, Maharashtra',
    'origin_city': 'Chandrapur',
    'origin_state': 'Maharashtra',
    'destination_label': 'Mumbai, Maharashtra',
    'destination_city': 'Mumbai',
    'destination_state': 'Maharashtra',
    'route_distance_km': 820,
    'route_duration_minutes': 780,
    'material': 'Coal',
    'weight_tonnes': 22,
    'required_body_type': 'Open',
    'required_tyres': [10, 12],
    'trucks_needed': 2,
    'trucks_booked': 1,
    'price_amount': 54000,
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
