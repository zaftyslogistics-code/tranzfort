import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

enum AdminSuperLoadStatusFilter { all, requestSubmitted, underReview, paymentPending, active, rejected }

class AdminSuperLoadQuery {
  final AdminSuperLoadStatusFilter statusFilter;
  final String search;

  const AdminSuperLoadQuery({required this.statusFilter, required this.search});

  AdminSuperLoadQuery copyWith({
    AdminSuperLoadStatusFilter? statusFilter,
    String? search,
  }) {
    return AdminSuperLoadQuery(
      statusFilter: statusFilter ?? this.statusFilter,
      search: search ?? this.search,
    );
  }
}

class AdminSuperLoadCounts {
  final int requestSubmitted;
  final int underReview;
  final int paymentPending;
  final int active;
  final int rejected;

  const AdminSuperLoadCounts({
    required this.requestSubmitted,
    required this.underReview,
    required this.paymentPending,
    required this.active,
    required this.rejected,
  });

  factory AdminSuperLoadCounts.empty() {
    return const AdminSuperLoadCounts(requestSubmitted: 0, underReview: 0, paymentPending: 0, active: 0, rejected: 0);
  }
}

class AdminSuperLoadItem {
  final String id;
  final String supplierId;
  final String supplierName;
  final String routeLabel;
  final String material;
  final String status;
  final String loadStatus;
  final int trucksNeeded;
  final int trucksBooked;
  final double? priceAmount;
  final DateTime? pickupDate;
  final DateTime? updatedAt;

  const AdminSuperLoadItem({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.routeLabel,
    required this.material,
    required this.status,
    required this.loadStatus,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.priceAmount,
    required this.pickupDate,
    required this.updatedAt,
  });
}

class AdminSuperLoadPage {
  final List<AdminSuperLoadItem> items;
  final AdminSuperLoadCounts counts;

  const AdminSuperLoadPage({required this.items, required this.counts});
}

class AdminSuperLoadDispatchCandidate {
  final String truckerId;
  final String truckId;
  final String truckerName;
  final String mobile;
  final String truckNumber;
  final String bodyType;
  final String rating;
  final String completedTrips;
  final String superTruckerStatus;

  const AdminSuperLoadDispatchCandidate({
    required this.truckerId,
    required this.truckId,
    required this.truckerName,
    required this.mobile,
    required this.truckNumber,
    required this.bodyType,
    required this.rating,
    required this.completedTrips,
    required this.superTruckerStatus,
  });
}

class AdminSuperLoadPodReviewItem {
  final String tripId;
  final String loadId;
  final String supplierId;
  final String supplierName;
  final String truckerId;
  final String truckerName;
  final String truckId;
  final String truckNumber;
  final String routeLabel;
  final String material;
  final DateTime? deliveredAt;
  final DateTime? podUploadedAt;
  final double? deliveredGpsLat;
  final double? deliveredGpsLng;
  final double? podGpsLat;
  final double? podGpsLng;
  final String? podSignedUrl;
  final String? lrSignedUrl;

  const AdminSuperLoadPodReviewItem({
    required this.tripId,
    required this.loadId,
    required this.supplierId,
    required this.supplierName,
    required this.truckerId,
    required this.truckerName,
    required this.truckId,
    required this.truckNumber,
    required this.routeLabel,
    required this.material,
    required this.deliveredAt,
    required this.podUploadedAt,
    required this.deliveredGpsLat,
    required this.deliveredGpsLng,
    required this.podGpsLat,
    required this.podGpsLng,
    required this.podSignedUrl,
    required this.lrSignedUrl,
  });
}

abstract class AdminSuperLoadBackend {
  Future<List<Map<String, dynamic>>> fetchSuperLoads();

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids);

  Future<List<Map<String, dynamic>>> fetchSuperLoadPodReviewTrips();

  Future<List<Map<String, dynamic>>> fetchVerifiedTruckerProfiles();

  Future<List<Map<String, dynamic>>> fetchVerifiedTruckerStats(List<String> ids);

  Future<List<Map<String, dynamic>>> fetchVerifiedTrucks();

  Future<String?> createTripProofSignedUrl(String path);

  Future<bool> markUnderReview(String loadId);

  Future<bool> approveRequest(String loadId);

  Future<bool> rejectRequest(String loadId, {String? reason});

  Future<bool> activateSuperLoad(String loadId);

  Future<bool> forceAssignSuperLoad({
    required String loadId,
    required String truckerId,
    required String truckId,
  });
}

class SupabaseAdminSuperLoadBackend implements AdminSuperLoadBackend {
  final SupabaseClient? client;

  const SupabaseAdminSuperLoadBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchSuperLoads() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('loads')
          .select('id, supplier_id, origin_city, destination_city, material, status, super_status, trucks_needed, trucks_booked, price_amount, pickup_date, updated_at, parent_load_id, is_super_load')
          .isFilter('parent_load_id', null)
          .or('super_status.in.(request_submitted,under_review,approved_payment_pending,active,rejected),is_super_load.eq.true')
          .order('updated_at', ascending: false);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchSuperLoadPodReviewTrips() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('trips')
          .select('id, load_id, supplier_id, trucker_id, truck_id, stage, delivered_at, pod_uploaded_at, gps_delivered_lat, gps_delivered_lng, gps_pod_lat, gps_pod_lng, pod_document_path, lr_document_path, loads!inner(id, parent_load_id, origin_city, destination_city, material, is_super_load), trucks(truck_number)')
          .eq('stage', 'proof_submitted');
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<String?> createTripProofSignedUrl(String path) async {
    final activeClient = client;
    final normalizedPath = path.trim();
    if (activeClient == null || normalizedPath.isEmpty) {
      return null;
    }
    try {
      return await activeClient.storage.from('trip-proof-documents').createSignedUrl(normalizedPath, 3600);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerifiedTruckerProfiles() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('profiles')
          .select('id, full_name, mobile, verification_status, user_role_type')
          .eq('user_role_type', 'trucker')
          .eq('verification_status', 'verified');
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerifiedTruckerStats(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('truckers')
          .select('id, rating, completed_trips, super_trucker_status')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchVerifiedTrucks() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('trucks')
          .select('id, owner_id, truck_number, body_type, status')
          .eq('status', 'verified');
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    try {
      final rows = await activeClient
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', ids);
      return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> markUnderReview(String loadId) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    try {
      await activeClient.rpc('mark_super_load_under_review', params: {'p_load_id': loadId});
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> approveRequest(String loadId) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    try {
      await activeClient.rpc('approve_super_load_request', params: {'p_load_id': loadId});
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> rejectRequest(String loadId, {String? reason}) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    try {
      await activeClient.rpc('reject_super_load_request', params: {
        'p_load_id': loadId,
        'p_reason': (reason ?? '').trim().isEmpty ? null : reason!.trim(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> activateSuperLoad(String loadId) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    try {
      await activeClient.rpc('activate_super_load', params: {'p_load_id': loadId});
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> forceAssignSuperLoad({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    try {
      await activeClient.rpc(
        'admin_force_assign_super_load',
        params: {
          'p_parent_load_id': loadId,
          'p_trucker_id': truckerId,
          'p_truck_id': truckId,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

class AdminSuperLoadRepository {
  final AdminSuperLoadBackend backend;

  const AdminSuperLoadRepository({required this.backend});

  Future<AdminSuperLoadPage> getSuperLoads(AdminSuperLoadQuery query) async {
    final rows = await backend.fetchSuperLoads();
    final profileIds = rows.map((row) => _asString(row['supplier_id'])).where((id) => id.isNotEmpty).toSet().toList(growable: false);
    final profileRows = await backend.fetchProfilesByIds(profileIds);
    final profileById = {for (final row in profileRows) _asString(row['id']): row};

    final counts = AdminSuperLoadCounts(
      requestSubmitted: rows.where((row) => _asString(row['super_status']) == 'request_submitted').length,
      underReview: rows.where((row) => _asString(row['super_status']) == 'under_review').length,
      paymentPending: rows.where((row) => _asString(row['super_status']) == 'approved_payment_pending').length,
      active: rows.where((row) => _asString(row['super_status']) == 'active').length,
      rejected: rows.where((row) => _asString(row['super_status']) == 'rejected').length,
    );

    final items = rows
        .map((row) {
          final supplierId = _asString(row['supplier_id']);
          final supplier = profileById[supplierId];
          return AdminSuperLoadItem(
            id: _asString(row['id']),
            supplierId: supplierId,
            supplierName: _asString(supplier?['full_name']),
            routeLabel: '${_asString(row['origin_city'])} → ${_asString(row['destination_city'])}',
            material: _asString(row['material']),
            status: _asString(row['super_status']),
            loadStatus: _asString(row['status']),
            trucksNeeded: _asInt(row['trucks_needed']),
            trucksBooked: _asInt(row['trucks_booked']),
            priceAmount: _asDouble(row['price_amount']),
            pickupDate: DateTime.tryParse(_asString(row['pickup_date'])),
            updatedAt: DateTime.tryParse(_asString(row['updated_at'])),
          );
        })
        .where((item) => _matchesFilter(item, query.statusFilter))
        .where((item) => _matchesSearch(item, query.search))
        .toList(growable: false)
      ..sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

    return AdminSuperLoadPage(items: items, counts: counts);
  }

  Future<bool> markUnderReview(String loadId) => backend.markUnderReview(loadId);

  Future<bool> approveRequest(String loadId) => backend.approveRequest(loadId);

  Future<bool> rejectRequest(String loadId, {String? reason}) => backend.rejectRequest(loadId, reason: reason);

  Future<bool> activateSuperLoad(String loadId) => backend.activateSuperLoad(loadId);

  Future<List<AdminSuperLoadDispatchCandidate>> getDispatchCandidates(String search) async {
    final profiles = await backend.fetchVerifiedTruckerProfiles();
    final truckerStats = await backend.fetchVerifiedTruckerStats(
      profiles.map((profile) => _asString(profile['id'])).where((id) => id.isNotEmpty).toList(growable: false),
    );
    final trucks = await backend.fetchVerifiedTrucks();
    final profileById = {for (final row in profiles) _asString(row['id']): row};
    final truckerStatsById = {for (final row in truckerStats) _asString(row['id']): row};
    final normalized = search.trim().toLowerCase();
    return trucks
        .where((truck) => profileById.containsKey(_asString(truck['owner_id'])))
        .map((truck) {
          final profile = profileById[_asString(truck['owner_id'])]!;
          final truckerStat = truckerStatsById[_asString(profile['id'])];
          return AdminSuperLoadDispatchCandidate(
            truckerId: _asString(profile['id']),
            truckId: _asString(truck['id']),
            truckerName: _asString(profile['full_name']),
            mobile: _asString(profile['mobile']),
            truckNumber: _asString(truck['truck_number']),
            bodyType: _asString(truck['body_type']),
            rating: _asString(truckerStat?['rating']),
            completedTrips: _asString(truckerStat?['completed_trips']),
            superTruckerStatus: _asString(truckerStat?['super_trucker_status']),
          );
        })
        .where((candidate) {
          if (normalized.isEmpty) {
            return true;
          }
          return candidate.truckerName.toLowerCase().contains(normalized) ||
              candidate.truckerId.toLowerCase().contains(normalized) ||
              candidate.truckId.toLowerCase().contains(normalized) ||
              candidate.mobile.toLowerCase().contains(normalized) ||
              candidate.truckNumber.toLowerCase().contains(normalized) ||
              candidate.bodyType.toLowerCase().contains(normalized) ||
              candidate.superTruckerStatus.toLowerCase().contains(normalized);
        })
        .toList(growable: false);
  }

  Future<bool> forceAssignSuperLoad({
    required String loadId,
    required String truckerId,
    required String truckId,
  }) {
    return backend.forceAssignSuperLoad(
      loadId: loadId,
      truckerId: truckerId,
      truckId: truckId,
    );
  }

  Future<List<AdminSuperLoadPodReviewItem>> getPodReviewItems() async {
    final rows = await backend.fetchSuperLoadPodReviewTrips();
    final filteredRows = rows.where((row) {
      final load = row['loads'];
      if (load is! Map<String, dynamic>) {
        return false;
      }
      return _asString(load['parent_load_id']).isNotEmpty && load['is_super_load'] == true;
    }).toList(growable: false);
    final profileIds = filteredRows
        .expand((row) => [_asString(row['supplier_id']), _asString(row['trucker_id'])])
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final profiles = await backend.fetchProfilesByIds(profileIds);
    final profileById = {for (final row in profiles) _asString(row['id']): row};

    final items = <AdminSuperLoadPodReviewItem>[];
    for (final row in filteredRows) {
      final load = Map<String, dynamic>.from(row['loads'] as Map);
      final truckMap = row['trucks'] is Map ? Map<String, dynamic>.from(row['trucks'] as Map) : const <String, dynamic>{};
      final podPath = _asString(row['pod_document_path']);
      final lrPath = _asString(row['lr_document_path']);
      final podUrl = podPath.isEmpty ? null : await backend.createTripProofSignedUrl(podPath);
      final lrUrl = lrPath.isEmpty ? null : await backend.createTripProofSignedUrl(lrPath);
      items.add(
        AdminSuperLoadPodReviewItem(
          tripId: _asString(row['id']),
          loadId: _asString(row['load_id']),
          supplierId: _asString(row['supplier_id']),
          supplierName: _asString(profileById[_asString(row['supplier_id'])]?['full_name']),
          truckerId: _asString(row['trucker_id']),
          truckerName: _asString(profileById[_asString(row['trucker_id'])]?['full_name']),
          truckId: _asString(row['truck_id']),
          truckNumber: _asString(truckMap['truck_number']),
          routeLabel: '${_asString(load['origin_city'])} → ${_asString(load['destination_city'])}',
          material: _asString(load['material']),
          deliveredAt: DateTime.tryParse(_asString(row['delivered_at'])),
          podUploadedAt: DateTime.tryParse(_asString(row['pod_uploaded_at'])),
          deliveredGpsLat: _asDouble(row['gps_delivered_lat']),
          deliveredGpsLng: _asDouble(row['gps_delivered_lng']),
          podGpsLat: _asDouble(row['gps_pod_lat']),
          podGpsLng: _asDouble(row['gps_pod_lng']),
          podSignedUrl: podUrl,
          lrSignedUrl: lrUrl,
        ),
      );
    }
    items.sort((a, b) => (b.podUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
        .compareTo(a.podUploadedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return items;
  }
}

bool _matchesFilter(AdminSuperLoadItem item, AdminSuperLoadStatusFilter filter) {
  return switch (filter) {
    AdminSuperLoadStatusFilter.all => true,
    AdminSuperLoadStatusFilter.requestSubmitted => item.status == 'request_submitted',
    AdminSuperLoadStatusFilter.underReview => item.status == 'under_review',
    AdminSuperLoadStatusFilter.paymentPending => item.status == 'approved_payment_pending',
    AdminSuperLoadStatusFilter.active => item.status == 'active',
    AdminSuperLoadStatusFilter.rejected => item.status == 'rejected',
  };
}

bool _matchesSearch(AdminSuperLoadItem item, String search) {
  final normalized = search.trim().toLowerCase();
  if (normalized.isEmpty) {
    return true;
  }
  return item.id.toLowerCase().contains(normalized) ||
      item.supplierId.toLowerCase().contains(normalized) ||
      item.supplierName.toLowerCase().contains(normalized) ||
      item.routeLabel.toLowerCase().contains(normalized) ||
      item.material.toLowerCase().contains(normalized) ||
      item.status.toLowerCase().contains(normalized) ||
      item.loadStatus.toLowerCase().contains(normalized);
}

String _asString(dynamic value) => (value ?? '').toString();
int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
double? _asDouble(dynamic value) => double.tryParse((value ?? '').toString());

final adminSuperLoadBackendProvider = Provider<AdminSuperLoadBackend>((ref) {
  return SupabaseAdminSuperLoadBackend(ref.watch(adminSupabaseClientProvider));
});

final adminSuperLoadRepositoryProvider = Provider<AdminSuperLoadRepository>((ref) {
  return AdminSuperLoadRepository(backend: ref.watch(adminSuperLoadBackendProvider));
});
