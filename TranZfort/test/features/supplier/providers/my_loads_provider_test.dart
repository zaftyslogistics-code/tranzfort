import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/my_loads_provider.dart';

class _FakeSupplierLoadBackend implements SupplierLoadBackend {
  final Map<String, List<List<Map<String, dynamic>>>> pagesByStatusKey;
  Object? error;

  _FakeSupplierLoadBackend(this.pagesByStatusKey);

  @override
  Future<String> createLoad(Map<String, dynamic> params) async => 'load-new';

  @override
  Future<void> cancelLoad(String loadId) async {}

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {}

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({required String supplierId, required String loadId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({
    required String supplierId,
    required String loadId,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({
    required String supplierId,
    required String loadId,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({required String supplierId, required LoadFilters filters, required int page, required int pageSize}) async {
    if (error != null) {
      throw error!;
    }
    final key = filters.statuses.join('|');
    final pages = pagesByStatusKey[key] ?? const <List<Map<String, dynamic>>>[];
    if (page - 1 >= pages.length) {
      return const <Map<String, dynamic>>[];
    }
    return pages[page - 1];
  }

  @override
  Future<String> approveBookingRequest(String bookingId) async => 'trip-1';

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {}
}

Map<String, dynamic> _loadRow(String id, String status) {
  return {
    'id': id,
    'origin_label': 'Chandrapur, Maharashtra',
    'destination_label': 'Mumbai, Maharashtra',
    'material': 'Coal',
    'weight_tonnes': 22,
    'trucks_needed': 2,
    'trucks_booked': 1,
    'price_amount': 54000,
    'price_type': 'negotiable',
    'pickup_date': '2026-03-10',
    'status': status,
    'required_body_type': 'Open',
    'required_tyres': [10, 12],
    'is_super_load': false,
    'super_status': 'none',
    'published_at': '2026-03-08T12:00:00.000Z',
  };
}

void main() {
  test('my loads provider loads active tab initially and paginates', () async {
    final backend = _FakeSupplierLoadBackend({
      supplierActiveLoadStatuses.join('|'): [
        [_loadRow('load-1', 'active')],
        [_loadRow('load-2', 'assigned_partial')],
      ],
    });
    final controller = MyLoadsController(
      SupplierLoadRepository(backend, () => 'supplier-1', pageSize: 1),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.selectedTab, MyLoadsTab.active);
    expect(controller.state.loads, hasLength(1));
    expect(controller.state.loads.first.id, 'load-1');

    await controller.loadMore();

    expect(controller.state.loads, hasLength(2));
    expect(controller.state.loads.last.id, 'load-2');
  });

  test('my loads provider switches tabs and reloads completed items', () async {
    final backend = _FakeSupplierLoadBackend({
      supplierActiveLoadStatuses.join('|'): [
        [_loadRow('load-1', 'active')],
      ],
      supplierCompletedLoadStatuses.join('|'): [
        [_loadRow('load-9', 'completed')],
      ],
    });
    final controller = MyLoadsController(
      SupplierLoadRepository(backend, () => 'supplier-1', pageSize: 1),
    );

    await Future<void>.delayed(Duration.zero);
    await controller.selectTab(MyLoadsTab.completed);

    expect(controller.state.selectedTab, MyLoadsTab.completed);
    expect(controller.state.loads, hasLength(1));
    expect(controller.state.loads.first.status, 'completed');
  });

  test('my loads provider surfaces repository failure', () async {
    final backend = _FakeSupplierLoadBackend({})
      ..error = Exception('network issue');
    final controller = MyLoadsController(
      SupplierLoadRepository(backend, () => 'supplier-1', pageSize: 1),
    );

    await Future<void>.delayed(Duration.zero);

    expect(controller.state.failure, isA<ServerFailure>());
    expect(controller.state.isInitialLoading, isFalse);
  });
}
