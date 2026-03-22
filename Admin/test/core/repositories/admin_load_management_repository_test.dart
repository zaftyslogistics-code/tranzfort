import 'package:admin/src/core/repositories/admin_load_management_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminLoadManagementBackend implements AdminLoadManagementBackend {
  List<Map<String, dynamic>> loads = const [];
  Map<String, Map<String, dynamic>> profilesById = const {};
  Map<String, Map<String, dynamic>> loadDetailsById = const {};
  String? lastCancelledLoadId;

  @override
  Future<List<Map<String, dynamic>>> fetchLoads() async => loads;

  @override
  Future<Map<String, dynamic>?> fetchLoadById(String loadId) async => loadDetailsById[loadId];

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async => ids
      .map((id) => profilesById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<bool> cancelLoad(String loadId) async {
    lastCancelledLoadId = loadId;
    return true;
  }
}

void main() {
  test('getLoads maps rows, supports stable id/status search, and cancelLoad routes to backend', () async {
    final backend = _FakeAdminLoadManagementBackend()
      ..loads = const [
        {
          'id': 'load-1',
          'supplier_id': 'supplier-1',
          'origin_city': 'Mumbai',
          'destination_city': 'Pune',
          'material': 'Steel',
          'price_amount': 42000,
          'trucks_needed': 2,
          'trucks_booked': 1,
          'status': 'active',
          'is_super_load': false,
          'super_status': 'none',
          'pickup_date': '2026-03-12',
          'created_at': '2026-03-11T09:00:00.000Z',
        },
        {
          'id': 'load-2',
          'supplier_id': 'supplier-2',
          'origin_city': 'Delhi',
          'destination_city': 'Jaipur',
          'material': 'Cement',
          'price_amount': 28000,
          'trucks_needed': 1,
          'trucks_booked': 0,
          'status': 'draft',
          'is_super_load': true,
          'super_status': 'approved_payment_pending',
          'pickup_date': '2026-03-13',
          'created_at': '2026-03-11T10:00:00.000Z',
        },
      ]
      ..loadDetailsById = {
        'load-1': {
          'id': 'load-1',
          'supplier_id': 'supplier-1',
          'origin_label': 'Mumbai Yard',
          'origin_city': 'Mumbai',
          'destination_label': 'Pune Site',
          'destination_city': 'Pune',
          'material': 'Steel',
          'weight_tonnes': 18,
          'required_body_type': 'Open',
          'required_tyres': [10, 12],
          'trucks_needed': 2,
          'trucks_booked': 1,
          'price_amount': 42000,
          'price_type': 'fixed',
          'advance_percentage': 20,
          'status': 'active',
          'is_super_load': false,
          'super_status': 'none',
          'pickup_date': '2026-03-12',
          'published_at': '2026-03-11T06:00:00.000Z',
          'created_at': '2026-03-11T05:00:00.000Z',
        },
      }
      ..profilesById = {
        'supplier-1': {'id': 'supplier-1', 'full_name': 'Supplier One'},
        'supplier-2': {'id': 'supplier-2', 'full_name': 'Supplier Two'},
      };

    final container = ProviderContainer(overrides: [adminLoadManagementBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminLoadManagementRepositoryProvider);
    final items = await repository.getLoads(const AdminLoadManagementQuery(filter: AdminLoadFilter.all, search: 'mumbai'));
    final supplierIdItems = await repository.getLoads(const AdminLoadManagementQuery(filter: AdminLoadFilter.all, search: 'supplier-2'));
    final superStatusItems = await repository.getLoads(
      const AdminLoadManagementQuery(filter: AdminLoadFilter.all, search: 'approved_payment_pending'),
    );
    final detail = await repository.getLoadDetail('load-1');
    final cancelled = await repository.cancelLoad('load-1');

    expect(items, hasLength(1));
    expect(items.single.supplierName, 'Supplier One');
    expect(supplierIdItems, hasLength(1));
    expect(supplierIdItems.single.id, 'load-2');
    expect(superStatusItems, hasLength(1));
    expect(superStatusItems.single.id, 'load-2');
    expect(detail?.supplierName, 'Supplier One');
    expect(detail?.requiredTyres, [10, 12]);
    expect(cancelled, isTrue);
    expect(backend.lastCancelledLoadId, 'load-1');
  });
}
