import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'admin_audit_repository.dart';

final adminSuperOpsRepositoryProvider = Provider<AdminSuperOpsRepository>(
  (ref) => AdminSuperOpsRepository(ref),
);

class AdminSuperOpsRepository {
  final Ref _ref;

  AdminSuperOpsRepository(this._ref);

  Future<SuperOpsQueueCounts> fetchQueueCounts() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const SuperOpsQueueCounts();

    final client = Supabase.instance.client;

    final requests = await _safeCount(() {
      return client
          .from('loads')
          .select('id')
          .isFilter('parent_load_id', null)
          .eq('is_super_load', true)
          .eq('super_status', superOpsTabStatus(SuperOpsTab.requests));
    });

    final dispatch = await _safeCount(() {
      return client
          .from('loads')
          .select('id')
          .isFilter('parent_load_id', null)
          .eq('is_super_load', true)
          .inFilter('super_status', ['processing', 'assigned', 'in_transit']);
    });

    final podReview = await _safeCount(() {
      return client
          .from('loads')
          .select('id')
          .isFilter('parent_load_id', null)
          .eq('is_super_load', true)
          .eq('super_status', superOpsTabStatus(SuperOpsTab.podReview));
    });

    final completed = await _safeCount(() {
      return client
          .from('loads')
          .select('id')
          .isFilter('parent_load_id', null)
          .eq('is_super_load', true)
          .eq('super_status', superOpsTabStatus(SuperOpsTab.completed));
    });

    return SuperOpsQueueCounts(
      requests: requests,
      dispatch: dispatch,
      podReview: podReview,
      completed: completed,
    );
  }

  Future<List<SuperOpsLoadSummary>> fetchQueue(SuperOpsQueueQuery query) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      dynamic request = client
          .from('loads')
          .select(
            'id,supplier_id,origin_city,origin_state,dest_city,dest_state,material,weight_tonnes,price,required_truck_type,trucks_needed,trucks_booked,status,super_status,pickup_date,created_at',
          )
          .isFilter('parent_load_id', null)
          .eq('is_super_load', true);

      if (query.tab == SuperOpsTab.dispatch) {
        request = request.inFilter('super_status', [
          'processing',
          'assigned',
          'in_transit',
        ]);
      } else {
        request = request.eq('super_status', superOpsTabStatus(query.tab));
      }

      final rows = await request.order('created_at', ascending: true);
      final loadRows = List<Map<String, dynamic>>.from(rows);
      if (loadRows.isEmpty) return const [];

      final supplierIds = loadRows
          .map((row) => _asString(row['supplier_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final supplierNames = await _loadSupplierNames(client, supplierIds);

      final loweredSearch = query.search.trim().toLowerCase();
      return loadRows
          .map((row) {
            final supplierId = _asString(row['supplier_id']);
            final origin = _asString(row['origin_city']);
            final destination = _asString(row['dest_city']);
            return SuperOpsLoadSummary(
              id: _asString(row['id']),
              routeLabel: '$origin -> $destination',
              material: _asString(row['material']),
              weightTonnes: _asDouble(row['weight_tonnes']),
              price: _asDouble(row['price']),
              requiredTruckType: _asString(row['required_truck_type']),
              trucksNeeded: _asInt(row['trucks_needed']),
              trucksBooked: _asInt(row['trucks_booked']),
              supplierName: supplierNames[supplierId] ?? supplierId,
              status: _asString(row['status']),
              superStatus: _asString(row['super_status']),
              pickupDate: DateTime.tryParse(_asString(row['pickup_date'])),
              createdAt: DateTime.tryParse(_asString(row['created_at'])),
            );
          })
          .where((item) {
            if (loweredSearch.isEmpty) return true;
            return item.routeLabel.toLowerCase().contains(loweredSearch) ||
                item.material.toLowerCase().contains(loweredSearch) ||
                item.supplierName.toLowerCase().contains(loweredSearch) ||
                item.id.toLowerCase().contains(loweredSearch);
          })
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<SuperOpsLoadDetail?> fetchLoadDetail(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return null;

    final client = Supabase.instance.client;

    try {
      final load = await client
          .from('loads')
          .select(
            'id,supplier_id,origin_city,origin_state,origin_lat,origin_lng,dest_city,dest_state,material,weight_tonnes,price,price_type,advance_percentage,pickup_date,required_truck_type,required_tyres,trucks_needed,trucks_booked,status,super_status,pod_photo_url,lr_photo_url,assigned_trucker_id,assigned_truck_id,created_at,updated_at',
          )
          .eq('id', loadId)
          .isFilter('parent_load_id', null)
          .maybeSingle();
      if (load == null) return null;

      final supplierId = _asString(load['supplier_id']);
      final supplierProfile = await client
          .from('profiles')
          .select('full_name,mobile,email,verification_status')
          .eq('id', supplierId)
          .maybeSingle();
      final supplierRecord = await client
          .from('suppliers')
          .select('company_name,gst_number')
          .eq('id', supplierId)
          .maybeSingle();
      final payoutProfile = await client
          .from('payout_profiles')
          .select(
            'account_holder_name,account_number_last4,ifsc_code,bank_name,status',
          )
          .eq('profile_id', supplierId)
          .maybeSingle();

      final childLoads = await client
          .from('loads')
          .select('id,assigned_trucker_id,assigned_truck_id')
          .eq('parent_load_id', loadId);
      final childLoadRows = List<Map<String, dynamic>>.from(childLoads);

      final assignedTruckerIds = childLoadRows
          .map((r) => _asString(r['assigned_trucker_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final assignedTruckIds = childLoadRows
          .map((r) => _asString(r['assigned_truck_id']))
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final truckerNames = await _loadProfileNames(client, assignedTruckerIds);
      final truckNumbers = await _loadTruckNumbers(client, assignedTruckIds);

      final assignments = childLoadRows
          .map(
            (row) => SuperOpsAssignmentSummary(
              childLoadId: _asString(row['id']),
              truckerId: _asString(row['assigned_trucker_id']),
              truckerName:
                  truckerNames[_asString(row['assigned_trucker_id'])] ?? '-',
              truckId: _asString(row['assigned_truck_id']),
              truckNumber:
                  truckNumbers[_asString(row['assigned_truck_id'])] ?? '-',
            ),
          )
          .toList();

      return SuperOpsLoadDetail(
        id: _asString(load['id']),
        routeLabel:
            '${_asString(load['origin_city'])} -> ${_asString(load['dest_city'])}',
        originLat: (load['origin_lat'] as num?)?.toDouble(),
        originLng: (load['origin_lng'] as num?)?.toDouble(),
        material: _asString(load['material']),
        weightTonnes: _asDouble(load['weight_tonnes']),
        price: _asDouble(load['price']),
        priceType: _asString(load['price_type']),
        advancePercentage: _asInt(load['advance_percentage']),
        pickupDate: DateTime.tryParse(_asString(load['pickup_date'])),
        requiredTruckType: _asString(load['required_truck_type']),
        requiredTyres: _asIntList(load['required_tyres']),
        trucksNeeded: _asInt(load['trucks_needed']),
        trucksBooked: _asInt(load['trucks_booked']),
        status: _asString(load['status']),
        superStatus: _asString(load['super_status']),
        podPhotoUrl: _asString(load['pod_photo_url']),
        lrPhotoUrl: _asString(load['lr_photo_url']),
        createdAt: DateTime.tryParse(_asString(load['created_at'])),
        supplier: SuperOpsSupplierInfo(
          id: supplierId,
          fullName: _asString(supplierProfile?['full_name']),
          companyName: _asString(supplierRecord?['company_name']),
          mobile: _asString(supplierProfile?['mobile']),
          email: _asString(supplierProfile?['email']),
          verificationStatus: _asString(
            supplierProfile?['verification_status'],
          ),
          gstNumber: _asString(supplierRecord?['gst_number']),
        ),
        payout: SuperOpsPayoutInfo(
          accountHolderName: _asString(payoutProfile?['account_holder_name']),
          accountNumberLast4: _asString(payoutProfile?['account_number_last4']),
          ifscCode: _asString(payoutProfile?['ifsc_code']),
          bankName: _asString(payoutProfile?['bank_name']),
          status: _asString(payoutProfile?['status']),
        ),
        assignments: assignments,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DispatchTruckerCandidate>> searchDispatchCandidates({
    required String query,
    required String requiredTruckType,
    List<int> requiredTyres = const [],
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      final truckers = await client
          .from('truckers')
          .select('id,rating,completed_trips,super_trucker_status')
          .order('rating', ascending: false)
          .limit(120);
      final truckerRows = List<Map<String, dynamic>>.from(truckers);
      if (truckerRows.isEmpty) return const [];

      final truckerIds = truckerRows.map((t) => _asString(t['id'])).toList();
      final profiles = await client
          .from('profiles')
          .select('id,full_name,mobile,last_known_lat,last_known_lng')
          .inFilter('id', truckerIds);
      final profileMap = {
        for (final row in profiles) _asString(row['id']): row,
      };

      dynamic truckRequest = client
          .from('trucks')
          .select('id,owner_id,truck_number,body_type,tyres,status')
          .eq('status', 'verified')
          .inFilter('owner_id', truckerIds);

      if (requiredTruckType.isNotEmpty) {
        truckRequest = truckRequest.eq('body_type', requiredTruckType);
      }
      if (requiredTyres.isNotEmpty) {
        truckRequest = truckRequest.inFilter('tyres', requiredTyres);
      }

      final strictTrucks = await truckRequest;
      var truckRows = List<Map<String, dynamic>>.from(strictTrucks);
      final usedFallback = truckRows.isEmpty &&
          (requiredTruckType.isNotEmpty || requiredTyres.isNotEmpty);

      if (usedFallback) {
        final fallbackTrucks = await client
            .from('trucks')
            .select('id,owner_id,truck_number,body_type,tyres,status')
            .eq('status', 'verified')
            .inFilter('owner_id', truckerIds);
        truckRows = List<Map<String, dynamic>>.from(fallbackTrucks);
      }

      final trucksByOwner = <String, List<DispatchTruckOption>>{};
      for (final truck in truckRows) {
        final ownerId = _asString(truck['owner_id']);
        trucksByOwner.putIfAbsent(ownerId, () => []);
        trucksByOwner[ownerId]!.add(
          DispatchTruckOption(
            id: _asString(truck['id']),
            truckNumber: _asString(truck['truck_number']),
            bodyType: _asString(truck['body_type']),
            tyres: _asInt(truck['tyres']),
          ),
        );
      }

      final loweredQuery = query.trim().toLowerCase();
      final candidates = <DispatchTruckerCandidate>[];
      for (final trucker in truckerRows) {
        final truckerId = _asString(trucker['id']);
        final options = trucksByOwner[truckerId] ?? const [];
        if (options.isEmpty) continue;

        final profile = profileMap[truckerId];
        final fullName = _asString(profile?['full_name']);
        final mobile = _asString(profile?['mobile']);

        final haystack =
            '$fullName $mobile ${options.map((t) => t.truckNumber).join(' ')}'
                .toLowerCase();
        if (loweredQuery.isNotEmpty && !haystack.contains(loweredQuery)) {
          continue;
        }

        candidates.add(
          DispatchTruckerCandidate(
            truckerId: truckerId,
            truckerName: fullName,
            mobile: mobile,
            rating: _asDouble(trucker['rating']),
            completedTrips: _asInt(trucker['completed_trips']),
            superTruckerStatus: _asString(trucker['super_trucker_status']),
            lastKnownLat: (profile?['last_known_lat'] as num?)?.toDouble(),
            lastKnownLng: (profile?['last_known_lng'] as num?)?.toDouble(),
            trucks: options,
            isFallbackMatch: usedFallback,
          ),
        );
      }

      return candidates;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> acceptRequest(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      await client
          .from('loads')
          .update({
            'super_status': 'processing',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', loadId)
          .eq('is_super_load', true)
          .isFilter('parent_load_id', null);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'super_ops_accept_request',
            entityType: 'load',
            entityId: loadId,
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectRequest(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      await client
          .from('loads')
          .update({
            'is_super_load': false,
            'super_status': 'none',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', loadId)
          .eq('is_super_load', true)
          .isFilter('parent_load_id', null);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'super_ops_reject_request',
            entityType: 'load',
            entityId: loadId,
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> forceAssign({
    required String parentLoadId,
    required String truckerId,
    required String truckId,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      final result = await client.rpc(
        'admin_force_assign_super_load',
        params: {
          'p_parent_load_id': parentLoadId,
          'p_trucker_id': truckerId,
          'p_truck_id': truckId,
          'p_admin_id': adminId,
        },
      );
      final map = Map<String, dynamic>.from(result as Map);
      final success = map['success'] == true;
      if (success) {
        await _ref
            .read(adminAuditRepositoryProvider)
            .logAction(
              action: 'assign_super_load',
              entityType: 'load',
              entityId: parentLoadId,
              metadata: {'trucker_id': truckerId, 'truck_id': truckId},
              adminId: adminId,
            );
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmPayout(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      final now = DateTime.now().toUtc().toIso8601String();

      await client
          .from('loads')
          .update({
            'status': 'completed',
            'super_status': 'completed',
            'completed_at': now,
            'updated_at': now,
          })
          .eq('id', loadId)
          .eq('is_super_load', true)
          .isFilter('parent_load_id', null);

      final childLoads = await client
          .from('loads')
          .select('id')
          .eq('parent_load_id', loadId);
      final childIds = List<Map<String, dynamic>>.from(childLoads)
          .map((row) => _asString(row['id']))
          .where((id) => id.isNotEmpty)
          .toList();

      if (childIds.isNotEmpty) {
        await client
            .from('loads')
            .update({
              'status': 'completed',
              'super_status': 'completed',
              'completed_at': now,
              'updated_at': now,
            })
            .inFilter('id', childIds);

        await client
            .from('trips')
            .update({'stage': 'completed', 'updated_at': now, 'end_time': now})
            .inFilter('load_id', childIds);
      }

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'super_ops_confirm_payout',
            entityType: 'load',
            entityId: loadId,
            metadata: {'child_load_count': childIds.length},
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disputePod(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      await client
          .from('loads')
          .update({
            'super_status': 'in_transit',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', loadId)
          .eq('is_super_load', true)
          .isFilter('parent_load_id', null);

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'super_ops_dispute_pod',
            entityType: 'load',
            entityId: loadId,
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<SuperOpsSupplierOption>> fetchSuppliers() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return const [];

    final client = Supabase.instance.client;

    try {
      final supplierRows = await client
          .from('suppliers')
          .select('id,company_name')
          .order('created_at', ascending: false)
          .limit(200);
      final suppliers = List<Map<String, dynamic>>.from(supplierRows);
      if (suppliers.isEmpty) return const [];

      final profileRows = await client
          .from('profiles')
          .select('id,full_name,mobile')
          .inFilter('id', suppliers.map((s) => _asString(s['id'])).toList());
      final profiles = {
        for (final row in profileRows) _asString(row['id']): row,
      };

      return suppliers
          .map(
            (supplier) => SuperOpsSupplierOption(
              supplierId: _asString(supplier['id']),
              supplierName: _asString(
                profiles[_asString(supplier['id'])]?['full_name'],
              ),
              mobile: _asString(profiles[_asString(supplier['id'])]?['mobile']),
              companyName: _asString(supplier['company_name']),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> postLoadOnBehalf(SuperOpsPostLoadPayload payload) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    try {
      await client.from('loads').insert({
        'supplier_id': payload.supplierId,
        'origin_city': payload.originCity,
        'origin_state': payload.originState,
        'dest_city': payload.destCity,
        'dest_state': payload.destState,
        'material': payload.material,
        'weight_tonnes': payload.weightTonnes,
        'required_truck_type': payload.requiredTruckType,
        'trucks_needed': payload.trucksNeeded,
        'price': payload.price,
        'price_type': payload.priceType,
        'advance_percentage': payload.advancePercentage,
        'pickup_date': payload.pickupDate.toIso8601String().split('T').first,
        'status': 'active',
        'is_super_load': true,
        'super_status': 'requested',
        'assigned_by': adminId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'post_load_on_behalf',
            entityType: 'load',
            entityId: payload.supplierId,
            metadata: {
              'origin_city': payload.originCity,
              'dest_city': payload.destCity,
              'trucks_needed': payload.trucksNeeded,
              'price': payload.price,
            },
            adminId: adminId,
          );

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() call) async {
    try {
      final rows = await call();
      return rows.length;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _currentAdminId(SupabaseClient client) async {
    final authUserId = client.auth.currentUser?.id;
    if (authUserId == null) return null;

    try {
      final row = await client
          .from('admin_users')
          .select('id,is_active')
          .eq('auth_user_id', authUserId)
          .maybeSingle();
      if (row == null || row['is_active'] != true) return null;
      return _asString(row['id']);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _loadSupplierNames(
    SupabaseClient client,
    List<String> supplierIds,
  ) async {
    if (supplierIds.isEmpty) return const {};

    try {
      final profileRows = await client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', supplierIds);
      return {
        for (final row in profileRows)
          _asString(row['id']): _asString(row['full_name']).ifEmpty('Supplier'),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, String>> _loadProfileNames(
    SupabaseClient client,
    List<String> profileIds,
  ) async {
    if (profileIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', profileIds);
      return {
        for (final row in rows)
          _asString(row['id']): _asString(row['full_name']).ifEmpty('User'),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, String>> _loadTruckNumbers(
    SupabaseClient client,
    List<String> truckIds,
  ) async {
    if (truckIds.isEmpty) return const {};

    try {
      final rows = await client
          .from('trucks')
          .select('id,truck_number')
          .inFilter('id', truckIds);
      return {
        for (final row in rows)
          _asString(row['id']): _asString(row['truck_number']).ifEmpty('-'),
      };
    } catch (_) {
      return const {};
    }
  }
}

String _asString(dynamic value) => (value ?? '').toString();

int _asInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? 0;
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

List<int> _asIntList(dynamic value) {
  if (value is List) {
    return value.map(_asInt).toList();
  }
  return const [];
}

enum SuperOpsTab { requests, dispatch, podReview, completed }

String superOpsTabStatus(SuperOpsTab tab) {
  switch (tab) {
    case SuperOpsTab.requests:
      return 'requested';
    case SuperOpsTab.dispatch:
      return 'processing';
    case SuperOpsTab.podReview:
      return 'pod_uploaded';
    case SuperOpsTab.completed:
      return 'completed';
  }
}

class SuperOpsQueueQuery {
  final SuperOpsTab tab;
  final String search;

  const SuperOpsQueueQuery({required this.tab, required this.search});

  @override
  bool operator ==(Object other) {
    return other is SuperOpsQueueQuery &&
        other.tab == tab &&
        other.search == search;
  }

  @override
  int get hashCode => Object.hash(tab, search);
}

class SuperOpsQueueCounts {
  final int requests;
  final int dispatch;
  final int podReview;
  final int completed;

  const SuperOpsQueueCounts({
    this.requests = 0,
    this.dispatch = 0,
    this.podReview = 0,
    this.completed = 0,
  });
}

class SuperOpsLoadSummary {
  final String id;
  final String routeLabel;
  final String material;
  final double weightTonnes;
  final double price;
  final String requiredTruckType;
  final int trucksNeeded;
  final int trucksBooked;
  final String supplierName;
  final String status;
  final String superStatus;
  final DateTime? pickupDate;
  final DateTime? createdAt;

  const SuperOpsLoadSummary({
    required this.id,
    required this.routeLabel,
    required this.material,
    required this.weightTonnes,
    required this.price,
    required this.requiredTruckType,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.supplierName,
    required this.status,
    required this.superStatus,
    required this.pickupDate,
    required this.createdAt,
  });
}

class SuperOpsLoadDetail {
  final String id;
  final String routeLabel;
  final double? originLat;
  final double? originLng;
  final String material;
  final double weightTonnes;
  final double price;
  final String priceType;
  final int advancePercentage;
  final DateTime? pickupDate;
  final String requiredTruckType;
  final List<int> requiredTyres;
  final int trucksNeeded;
  final int trucksBooked;
  final String status;
  final String superStatus;
  final String podPhotoUrl;
  final String lrPhotoUrl;
  final DateTime? createdAt;
  final SuperOpsSupplierInfo supplier;
  final SuperOpsPayoutInfo payout;
  final List<SuperOpsAssignmentSummary> assignments;

  const SuperOpsLoadDetail({
    required this.id,
    required this.routeLabel,
    required this.originLat,
    required this.originLng,
    required this.material,
    required this.weightTonnes,
    required this.price,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
    required this.requiredTruckType,
    required this.requiredTyres,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.status,
    required this.superStatus,
    required this.podPhotoUrl,
    required this.lrPhotoUrl,
    required this.createdAt,
    required this.supplier,
    required this.payout,
    required this.assignments,
  });
}

class SuperOpsSupplierInfo {
  final String id;
  final String fullName;
  final String companyName;
  final String mobile;
  final String email;
  final String verificationStatus;
  final String gstNumber;

  const SuperOpsSupplierInfo({
    required this.id,
    required this.fullName,
    required this.companyName,
    required this.mobile,
    required this.email,
    required this.verificationStatus,
    required this.gstNumber,
  });
}

class SuperOpsPayoutInfo {
  final String accountHolderName;
  final String accountNumberLast4;
  final String ifscCode;
  final String bankName;
  final String status;

  const SuperOpsPayoutInfo({
    required this.accountHolderName,
    required this.accountNumberLast4,
    required this.ifscCode,
    required this.bankName,
    required this.status,
  });
}

class SuperOpsAssignmentSummary {
  final String childLoadId;
  final String truckerId;
  final String truckerName;
  final String truckId;
  final String truckNumber;

  const SuperOpsAssignmentSummary({
    required this.childLoadId,
    required this.truckerId,
    required this.truckerName,
    required this.truckId,
    required this.truckNumber,
  });
}

class DispatchTruckerCandidate {
  final String truckerId;
  final String truckerName;
  final String mobile;
  final double rating;
  final int completedTrips;
  final String superTruckerStatus;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final double? distanceKm;
  final List<DispatchTruckOption> trucks;
  final bool isFallbackMatch;

  const DispatchTruckerCandidate({
    required this.truckerId,
    required this.truckerName,
    required this.mobile,
    required this.rating,
    required this.completedTrips,
    required this.superTruckerStatus,
    this.lastKnownLat,
    this.lastKnownLng,
    this.distanceKm,
    required this.trucks,
    this.isFallbackMatch = false,
  });

  DispatchTruckerCandidate copyWith({
    String? truckerId,
    String? truckerName,
    String? mobile,
    double? rating,
    int? completedTrips,
    String? superTruckerStatus,
    double? lastKnownLat,
    double? lastKnownLng,
    double? distanceKm,
    bool clearDistance = false,
    List<DispatchTruckOption>? trucks,
    bool? isFallbackMatch,
  }) {
    return DispatchTruckerCandidate(
      truckerId: truckerId ?? this.truckerId,
      truckerName: truckerName ?? this.truckerName,
      mobile: mobile ?? this.mobile,
      rating: rating ?? this.rating,
      completedTrips: completedTrips ?? this.completedTrips,
      superTruckerStatus: superTruckerStatus ?? this.superTruckerStatus,
      lastKnownLat: lastKnownLat ?? this.lastKnownLat,
      lastKnownLng: lastKnownLng ?? this.lastKnownLng,
      distanceKm: clearDistance ? null : (distanceKm ?? this.distanceKm),
      trucks: trucks ?? this.trucks,
      isFallbackMatch: isFallbackMatch ?? this.isFallbackMatch,
    );
  }
}

class DispatchTruckOption {
  final String id;
  final String truckNumber;
  final String bodyType;
  final int tyres;

  const DispatchTruckOption({
    required this.id,
    required this.truckNumber,
    required this.bodyType,
    required this.tyres,
  });
}

class SuperOpsSupplierOption {
  final String supplierId;
  final String supplierName;
  final String mobile;
  final String companyName;

  const SuperOpsSupplierOption({
    required this.supplierId,
    required this.supplierName,
    required this.mobile,
    required this.companyName,
  });
}

class SuperOpsPostLoadPayload {
  final String supplierId;
  final String originCity;
  final String originState;
  final String destCity;
  final String destState;
  final String material;
  final double weightTonnes;
  final String requiredTruckType;
  final int trucksNeeded;
  final double price;
  final String priceType;
  final int advancePercentage;
  final DateTime pickupDate;

  const SuperOpsPostLoadPayload({
    required this.supplierId,
    required this.originCity,
    required this.originState,
    required this.destCity,
    required this.destState,
    required this.material,
    required this.weightTonnes,
    required this.requiredTruckType,
    required this.trucksNeeded,
    required this.price,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
  });
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
