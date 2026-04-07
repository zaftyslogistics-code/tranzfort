import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../admin_audit_repository.dart';
import 'super_ops_models.dart';

class SuperOpsQueueRepository {
  final Ref _ref;

  SuperOpsQueueRepository(this._ref);

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
    if (!configured) return [];

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return [];

    var q = client
        .from('loads')
        .select('''
          id,
          origin_city,
          destination_city,
          material,
          weight_tonnes,
          price,
          required_truck_type,
          trucks_needed,
          trucks_booked,
          status,
          super_status,
          pickup_date,
          created_at,
          supplier_id,
          profiles!loads_supplier_id_fkey(
            full_name,
            company_name
          )
        ''')
        .isFilter('parent_load_id', null)
        .eq('is_super_load', true)
        .eq('super_status', superOpsTabStatus(query.tab))
        .order('created_at', ascending: false);

    if (query.search.trim().isNotEmpty) {
      final search = query.search.trim().toLowerCase();
      final rawData = await q.limit(50);
      final filtered = rawData.where((row) {
        final originCity = (row['origin_city'] as String? ?? '').toLowerCase();
        final destinationCity = (row['destination_city'] as String? ?? '').toLowerCase();
        final material = (row['material'] as String? ?? '').toLowerCase();
        final profile = row['profiles'] as Map<String, dynamic>? ?? const {};
        final fullName = (profile['full_name'] as String? ?? '').toLowerCase();
        final companyName = (profile['company_name'] as String? ?? '').toLowerCase();
        return originCity.contains(search) ||
            destinationCity.contains(search) ||
            material.contains(search) ||
            fullName.contains(search) ||
            companyName.contains(search);
      }).toList(growable: false);
      final supplierNames = await _loadSupplierNames(
        filtered
            .map((d) => d['supplier_id'] as String?)
            .whereType<String>()
            .toList(),
      );

      return filtered.map((row) {
        final supplierId = row['supplier_id'] as String?;
        final supplier = row['profiles'] as Map<String, dynamic>? ?? {};
        return SuperOpsLoadSummary(
          id: row['id'] as String,
          routeLabel: '${row['origin_city'] as String} → ${row['destination_city'] as String}',
          material: row['material'] as String,
          weightTonnes: (row['weight_tonnes'] as num?)?.toDouble() ?? 0.0,
          price: (row['price'] as num?)?.toDouble() ?? 0.0,
          requiredTruckType: row['required_truck_type'] as String? ?? '',
          trucksNeeded: (row['trucks_needed'] as int?) ?? 0,
          trucksBooked: (row['trucks_booked'] as int?) ?? 0,
          supplierName: supplierNames[supplierId ?? ''] ??
              supplier['full_name'] as String? ??
              supplier['company_name'] as String? ??
              'Unknown',
          status: row['status'] as String? ?? '',
          superStatus: row['super_status'] as String? ?? '',
          pickupDate: DateTime.tryParse(row['pickup_date'] as String? ?? ''),
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
        );
      }).toList();
    }

    final data = await q.limit(50);
    final supplierNames = await _loadSupplierNames(
        data.map((d) => d['supplier_id'] as String).toList());

    return data.map((row) {
      final supplierId = row['supplier_id'] as String?;
      final supplier = row['profiles'] as Map<String, dynamic>? ?? {};
      return SuperOpsLoadSummary(
        id: row['id'] as String,
        routeLabel: '${row['origin_city'] as String} → ${row['destination_city'] as String}',
        material: row['material'] as String,
        weightTonnes: (row['weight_tonnes'] as num?)?.toDouble() ?? 0.0,
        price: (row['price'] as num?)?.toDouble() ?? 0.0,
        requiredTruckType: row['required_truck_type'] as String? ?? '',
        trucksNeeded: (row['trucks_needed'] as int?) ?? 0,
        trucksBooked: (row['trucks_booked'] as int?) ?? 0,
        supplierName: supplierNames[supplierId ?? ''] ??
            supplier['full_name'] as String? ??
            supplier['company_name'] as String? ??
            'Unknown',
        status: row['status'] as String? ?? '',
        superStatus: row['super_status'] as String? ?? '',
        pickupDate: DateTime.tryParse(row['pickup_date'] as String? ?? ''),
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
      );
    }).toList();
  }

  Future<SuperOpsLoadDetail?> fetchLoadDetail(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return null;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return null;

    final data = await client
        .from('loads')
        .select('''
          id,
          origin_city,
          origin_state,
          destination_city,
          destination_state,
          origin_lat,
          origin_lng,
          material,
          weight_tonnes,
          price,
          price_type,
          advance_percentage,
          pickup_date,
          required_truck_type,
          required_tyres,
          trucks_needed,
          trucks_booked,
          status,
          super_status,
          pod_photo_url,
          lr_photo_url,
          created_at,
          supplier_id,
          profiles!loads_supplier_id_fkey(
            id,
            full_name,
            company_name,
            mobile,
            email,
            verification_status,
            gst_number
          ),
          child_loads(
            id,
            trucker_id,
            truck_id,
            status,
            profiles!child_loads_trucker_id_fkey(
              full_name
            ),
            trucks!child_loads_truck_id_fkey(
              truck_number
            )
          ),
          supplier_payouts(
            account_holder_name,
            account_number,
            ifsc_code,
            bank_name,
            status
          )
        ''')
        .eq('id', loadId)
        .isFilter('parent_load_id', null)
        .eq('is_super_load', true)
        .maybeSingle();

    if (data == null) return null;

    final supplier = data['profiles'] as Map<String, dynamic>? ?? {};
    final childLoads = data['child_loads'] as List<dynamic>? ?? [];
    final payout = data['supplier_payouts'] as Map<String, dynamic>? ?? {};

    return SuperOpsLoadDetail(
      id: data['id'] as String,
      routeLabel: '${data['origin_city'] as String} → ${data['destination_city'] as String}',
      originLat: (data['origin_lat'] as num?)?.toDouble(),
      originLng: (data['origin_lng'] as num?)?.toDouble(),
      material: data['material'] as String,
      weightTonnes: (data['weight_tonnes'] as num?)?.toDouble() ?? 0.0,
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      priceType: data['price_type'] as String? ?? 'per_ton',
      advancePercentage: (data['advance_percentage'] as int?) ?? 0,
      pickupDate: DateTime.tryParse(data['pickup_date'] as String? ?? ''),
      requiredTruckType: data['required_truck_type'] as String? ?? '',
      requiredTyres: (data['required_tyres'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      trucksNeeded: (data['trucks_needed'] as int?) ?? 0,
      trucksBooked: (data['trucks_booked'] as int?) ?? 0,
      status: data['status'] as String? ?? '',
      superStatus: data['super_status'] as String? ?? '',
      podPhotoUrl: data['pod_photo_url'] as String? ?? '',
      lrPhotoUrl: data['lr_photo_url'] as String? ?? '',
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? ''),
      supplier: SuperOpsSupplierInfo(
        id: supplier['id'] as String? ?? '',
        fullName: supplier['full_name'] as String? ?? '',
        companyName: supplier['company_name'] as String? ?? '',
        mobile: supplier['mobile'] as String? ?? '',
        email: supplier['email'] as String? ?? '',
        verificationStatus: supplier['verification_status'] as String? ?? '',
        gstNumber: supplier['gst_number'] as String? ?? '',
      ),
      payout: SuperOpsPayoutInfo(
        accountHolderName: payout['account_holder_name'] as String? ?? '',
        accountNumberLast4: (payout['account_number'] as String?)?.substring(
                payout['account_number']!.length - 4) ??
            '',
        ifscCode: payout['ifsc_code'] as String? ?? '',
        bankName: payout['bank_name'] as String? ?? '',
        status: payout['status'] as String? ?? '',
      ),
      assignments: childLoads.map((child) {
        final trucker = child['profiles'] as Map<String, dynamic>? ?? {};
        final truck = child['trucks'] as Map<String, dynamic>? ?? {};
        return SuperOpsAssignmentSummary(
          childLoadId: child['id'] as String,
          truckerId: child['trucker_id'] as String,
          truckerName: trucker['full_name'] as String? ?? '',
          truckId: child['truck_id'] as String,
          truckNumber: truck['truck_number'] as String? ?? '',
        );
      }).toList(),
    );
  }

  Future<bool> acceptRequest(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    final result = await client.rpc('admin_accept_super_load_request', params: {
      'p_load_id': loadId,
      'p_admin_id': adminId,
    });

    if (result != null && result['success'] == true) {
      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'accept_request',
            entityType: 'super_ops',
            entityId: loadId,
            metadata: {'load_id': loadId, 'admin_id': adminId},
            adminId: adminId,
          );
      return true;
    }
    return false;
  }

  Future<bool> rejectRequest(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    final result = await client.rpc('admin_reject_super_load_request', params: {
      'p_load_id': loadId,
      'p_admin_id': adminId,
    });

    if (result != null && result['success'] == true) {
      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'reject_request',
            entityType: 'super_ops',
            entityId: loadId,
            metadata: {'load_id': loadId, 'admin_id': adminId},
            adminId: adminId,
          );
      return true;
    }
    return false;
  }

  Future<bool> confirmPayout(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    final result = await client.rpc('admin_confirm_super_load_payout', params: {
      'p_load_id': loadId,
      'p_admin_id': adminId,
    });

    if (result != null && result['success'] == true) {
      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'confirm_payout',
            entityType: 'super_ops',
            entityId: loadId,
            metadata: {'load_id': loadId, 'admin_id': adminId},
            adminId: adminId,
          );
      return true;
    }
    return false;
  }

  Future<bool> disputePod(String loadId) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    final result = await client.rpc('admin_dispute_super_load_pod', params: {
      'p_load_id': loadId,
      'p_admin_id': adminId,
    });

    if (result != null && result['success'] == true) {
      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'dispute_pod',
            entityType: 'super_ops',
            entityId: loadId,
            metadata: {'load_id': loadId, 'admin_id': adminId},
            adminId: adminId,
          );
      return true;
    }
    return false;
  }

  Future<int> _safeCount(Future<List<dynamic>> Function() call) async {
    try {
      final result = await call();
      return result.length;
    } catch (_) {
      return 0;
    }
  }

  Future<String?> _currentAdminId(SupabaseClient client) async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return null;

      final admin = await client
          .from('admin_users')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return admin?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _loadSupplierNames(List<String> supplierIds) async {
    if (supplierIds.isEmpty) return {};

    final client = Supabase.instance.client;
    final data = await client
        .from('profiles')
        .select('id, full_name, company_name')
        .inFilter('id', supplierIds);

    return {
      for (final row in data)
        row['id'] as String: _coalesceText(
          row['full_name'] as String?,
          row['company_name'] as String?,
          'Unknown Supplier',
        )
    };
  }

  String _coalesceText(String? primary, String? secondary, String fallback) {
    final first = (primary ?? '').trim();
    if (first.isNotEmpty) return first;
    final second = (secondary ?? '').trim();
    if (second.isNotEmpty) return second;
    return fallback;
  }
}
