import 'package:admin/src/core/repositories/admin_super_load_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdminSuperLoadBackend implements AdminSuperLoadBackend {
  List<Map<String, dynamic>> superLoads = const [];
  List<Map<String, dynamic>> podReviewTrips = const [];
  Map<String, Map<String, dynamic>> profilesById = const {};
  List<Map<String, dynamic>> verifiedTruckerProfiles = const [];
  List<Map<String, dynamic>> verifiedTruckerStats = const [];
  List<Map<String, dynamic>> verifiedTrucks = const [];
  String? lastReviewLoadId;
  String? lastApproveLoadId;
  String? lastRejectLoadId;
  String? lastRejectReason;
  String? lastActivateLoadId;
  String? lastForceAssignLoadId;
  String? lastForceAssignTruckerId;
  String? lastForceAssignTruckId;

  @override
  Future<List<Map<String, dynamic>>> fetchSuperLoads() async => superLoads;

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async => ids
      .map((id) => profilesById[id])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);

  @override
  Future<List<Map<String, dynamic>>> fetchSuperLoadPodReviewTrips() async => podReviewTrips;

  @override
  Future<List<Map<String, dynamic>>> fetchVerifiedTruckerProfiles() async => verifiedTruckerProfiles;

  @override
  Future<List<Map<String, dynamic>>> fetchVerifiedTruckerStats(List<String> ids) async {
    final items = <Map<String, dynamic>>[];
    for (final id in ids) {
      for (final row in verifiedTruckerStats) {
        if (row['id'] == id) {
          items.add(row);
          break;
        }
      }
    }
    return items;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerifiedTrucks() async => verifiedTrucks;

  @override
  Future<String?> createTripProofSignedUrl(String path) async => 'https://example.test/$path';

  @override
  Future<bool> markUnderReview(String loadId) async {
    lastReviewLoadId = loadId;
    return true;
  }

  @override
  Future<bool> approveRequest(String loadId) async {
    lastApproveLoadId = loadId;
    return true;
  }

  @override
  Future<bool> rejectRequest(String loadId, {String? reason}) async {
    lastRejectLoadId = loadId;
    lastRejectReason = reason;
    return true;
  }

  @override
  Future<bool> activateSuperLoad(String loadId) async {
    lastActivateLoadId = loadId;
    return true;
  }

  @override
  Future<bool> forceAssignSuperLoad({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) async {
    lastForceAssignLoadId = loadId;
    lastForceAssignTruckerId = truckerId;
    lastForceAssignTruckId = truckId;
    return true;
  }
}

void main() {
  test('getSuperLoads maps supplier context, supports stable search, and action methods route to backend', () async {
    final backend = _FakeAdminSuperLoadBackend()
      ..superLoads = [
        {
          'id': 'load-1',
          'supplier_id': 'supplier-1',
          'origin_city': 'Mumbai',
          'destination_city': 'Pune',
          'material': 'Steel',
          'status': 'active',
          'super_status': 'request_submitted',
          'trucks_needed': 2,
          'trucks_booked': 0,
          'price_amount': 42000,
          'pickup_date': '2026-03-12',
          'updated_at': '2026-03-11T09:00:00.000Z',
          'parent_load_id': null,
          'is_super_load': true,
        },
        {
          'id': 'load-2',
          'supplier_id': 'supplier-2',
          'origin_city': 'Delhi',
          'destination_city': 'Jaipur',
          'material': 'Cement',
          'status': 'draft',
          'super_status': 'approved_payment_pending',
          'trucks_needed': 1,
          'trucks_booked': 0,
          'price_amount': 28000,
          'pickup_date': '2026-03-13',
          'updated_at': '2026-03-11T10:00:00.000Z',
          'parent_load_id': null,
          'is_super_load': true,
        },
      ]
      ..profilesById = {
        'supplier-1': {'id': 'supplier-1', 'full_name': 'Supplier One'},
        'supplier-2': {'id': 'supplier-2', 'full_name': 'Supplier Two'},
      };

    final container = ProviderContainer(overrides: [adminSuperLoadBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminSuperLoadRepositoryProvider);
    final page = await repository.getSuperLoads(const AdminSuperLoadQuery(statusFilter: AdminSuperLoadStatusFilter.all, search: 'mumbai'));
    final supplierIdPage = await repository.getSuperLoads(
      const AdminSuperLoadQuery(statusFilter: AdminSuperLoadStatusFilter.all, search: 'supplier-2'),
    );
    final loadStatusPage = await repository.getSuperLoads(
      const AdminSuperLoadQuery(statusFilter: AdminSuperLoadStatusFilter.all, search: 'draft'),
    );
    final reviewOk = await repository.markUnderReview('load-1');
    final approveOk = await repository.approveRequest('load-1');
    final rejectOk = await repository.rejectRequest('load-1', reason: 'Missing readiness');
    final activateOk = await repository.activateSuperLoad('load-1');

    expect(page.items, hasLength(1));
    expect(page.items.single.supplierName, 'Supplier One');
    expect(supplierIdPage.items, hasLength(1));
    expect(supplierIdPage.items.single.id, 'load-2');
    expect(loadStatusPage.items, hasLength(1));
    expect(loadStatusPage.items.single.id, 'load-2');
    expect(page.counts.requestSubmitted, 1);
    expect(reviewOk, isTrue);
    expect(approveOk, isTrue);
    expect(rejectOk, isTrue);
    expect(activateOk, isTrue);
    expect(backend.lastReviewLoadId, 'load-1');
    expect(backend.lastApproveLoadId, 'load-1');
    expect(backend.lastRejectReason, 'Missing readiness');
    expect(backend.lastActivateLoadId, 'load-1');
  });

  test('getDispatchCandidates and forceAssignSuperLoad route to backend', () async {
    final backend = _FakeAdminSuperLoadBackend()
      ..verifiedTruckerProfiles = const [
        {
          'id': 'trucker-1',
          'full_name': 'Trucker One',
          'mobile': '9999999999',
          'verification_status': 'verified',
          'user_role_type': 'trucker',
        },
      ]
      ..verifiedTruckerStats = const [
        {
          'id': 'trucker-1',
          'rating': 4.8,
          'completed_trips': 12,
          'super_trucker_status': 'eligible',
        },
      ]
      ..verifiedTrucks = const [
        {
          'id': 'truck-1',
          'owner_id': 'trucker-1',
          'truck_number': 'MH12AB1234',
          'body_type': 'Open',
          'status': 'verified',
        },
      ];

    final container = ProviderContainer(overrides: [adminSuperLoadBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminSuperLoadRepositoryProvider);
    final candidates = await repository.getDispatchCandidates('mh12');
    final truckerIdCandidates = await repository.getDispatchCandidates('trucker-1');
    final truckIdCandidates = await repository.getDispatchCandidates('truck-1');
    final bodyTypeCandidates = await repository.getDispatchCandidates('open');
    final superStatusCandidates = await repository.getDispatchCandidates('eligible');
    final ok = await repository.forceAssignSuperLoad(loadId: 'load-1', truckerId: 'trucker-1', truckId: 'truck-1');

    expect(candidates, hasLength(1));
    expect(candidates.single.truckerName, 'Trucker One');
    expect(candidates.single.rating, '4.8');
    expect(candidates.single.completedTrips, '12');
    expect(candidates.single.superTruckerStatus, 'eligible');
    expect(truckerIdCandidates, hasLength(1));
    expect(truckIdCandidates, hasLength(1));
    expect(bodyTypeCandidates, hasLength(1));
    expect(superStatusCandidates, hasLength(1));
    expect(ok, isTrue);
    expect(backend.lastForceAssignLoadId, 'load-1');
    expect(backend.lastForceAssignTruckId, 'truck-1');
  });

  test('getPodReviewItems maps proof submitted Super Load trips with signed urls', () async {
    final backend = _FakeAdminSuperLoadBackend()
      ..podReviewTrips = const [
        {
          'id': 'trip-1',
          'load_id': 'child-load-1',
          'supplier_id': 'supplier-1',
          'trucker_id': 'trucker-1',
          'truck_id': 'truck-1',
          'stage': 'proof_submitted',
          'delivered_at': '2026-03-12T00:30:00.000Z',
          'pod_uploaded_at': '2026-03-12T01:00:00.000Z',
          'gps_delivered_lat': 18.5204,
          'gps_delivered_lng': 73.8567,
          'gps_pod_lat': 18.5210,
          'gps_pod_lng': 73.8571,
          'pod_document_path': 'trip-1/pod.jpg',
          'lr_document_path': 'trip-1/lr.jpg',
          'loads': {
            'id': 'child-load-1',
            'parent_load_id': 'parent-load-1',
            'origin_city': 'Mumbai',
            'destination_city': 'Pune',
            'material': 'Steel',
            'is_super_load': true,
          },
          'trucks': {
            'truck_number': 'MH12AB1234',
          },
        },
      ]
      ..profilesById = {
        'supplier-1': {'id': 'supplier-1', 'full_name': 'Supplier One'},
        'trucker-1': {'id': 'trucker-1', 'full_name': 'Trucker One'},
      };

    final container = ProviderContainer(overrides: [adminSuperLoadBackendProvider.overrideWithValue(backend)]);
    addTearDown(container.dispose);

    final repository = container.read(adminSuperLoadRepositoryProvider);
    final items = await repository.getPodReviewItems();

    expect(items, hasLength(1));
    expect(items.single.supplierName, 'Supplier One');
    expect(items.single.truckerName, 'Trucker One');
    expect(items.single.truckId, 'truck-1');
    expect(items.single.deliveredAt, DateTime.parse('2026-03-12T00:30:00.000Z'));
    expect(items.single.deliveredGpsLat, 18.5204);
    expect(items.single.deliveredGpsLng, 73.8567);
    expect(items.single.podGpsLat, 18.5210);
    expect(items.single.podGpsLng, 73.8571);
    expect(items.single.podSignedUrl, 'https://example.test/trip-1/pod.jpg');
  });
}
