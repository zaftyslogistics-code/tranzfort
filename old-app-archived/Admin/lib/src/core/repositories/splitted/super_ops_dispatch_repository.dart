import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../admin_audit_repository.dart';
import 'super_ops_models.dart';

class SuperOpsDispatchRepository {
  final Ref _ref;

  SuperOpsDispatchRepository(this._ref);

  Future<List<DispatchTruckerCandidate>> searchDispatchCandidates({
    required String loadId,
    double? originLat,
    double? originLng,
    String? requiredTruckType,
    List<int>? requiredTyres,
    int? trucksNeeded,
    bool fallback = false,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return [];

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return [];

    final data = await client.rpc('admin_find_super_load_candidates', params: {
      'p_load_id': loadId,
      'p_origin_lat': originLat,
      'p_origin_lng': originLng,
      'p_required_truck_type': requiredTruckType,
      'p_required_tyres': requiredTyres,
      'p_trucks_needed': trucksNeeded,
      'p_fallback': fallback,
    });

    if (data == null) return [];

    final profileIds = <String>[];
    final truckIds = <String>[];
    for (final row in data) {
      profileIds.add(row['trucker_id'] as String);
      if (row['truck_id'] != null) {
        truckIds.add(row['truck_id'] as String);
      }
    }

    final [profileNames, truckNumbers] = await Future.wait([
      _loadProfileNames(profileIds),
      _loadTruckNumbers(truckIds),
    ]);

    return data.map((row) {
      final truckerId = row['trucker_id'] as String;
      return DispatchTruckerCandidate(
        truckerId: truckerId,
        truckerName: profileNames[truckerId] ?? 'Unknown',
        mobile: row['mobile'] as String? ?? '',
        rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
        completedTrips: (row['completed_trips'] as int?) ?? 0,
        superTruckerStatus: row['super_trucker_status'] as String? ?? '',
        lastKnownLat: (row['last_known_lat'] as num?)?.toDouble(),
        lastKnownLng: (row['last_known_lng'] as num?)?.toDouble(),
        distanceKm: (row['distance_km'] as num?)?.toDouble(),
        trucks: [
          if (row['truck_id'] != null)
            DispatchTruckOption(
              id: row['truck_id'] as String,
              truckNumber: truckNumbers[row['truck_id'] as String] ?? '',
              bodyType: row['truck_body_type'] as String? ?? '',
              tyres: (row['truck_tyres'] as int?) ?? 0,
            ),
        ],
        isFallbackMatch: fallback,
      );
    }).toList();
  }

  Future<bool> forceAssign({
    required String loadId,
    required String truckerId,
    required String truckId,
    int? truckCount = 1,
  }) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    final result = await client.rpc('admin_force_assign_super_load', params: {
      'p_load_id': loadId,
      'p_trucker_id': truckerId,
      'p_truck_id': truckId,
      'p_truck_count': truckCount ?? 1,
      'p_admin_id': adminId,
    });

    if (result != null && result['success'] == true) {
      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'force_assign',
            entityType: 'super_ops',
            entityId: loadId,
            metadata: {
              'load_id': loadId,
              'trucker_id': truckerId,
              'truck_id': truckId,
              'truck_count': truckCount,
              'admin_id': adminId,
            },
            adminId: adminId,
          );
      return true;
    }
    return false;
  }

  Future<List<SuperOpsSupplierOption>> fetchSuppliers() async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return [];

    final client = Supabase.instance.client;

    final data = await client
        .from('profiles')
        .select('id, full_name, mobile, company_name')
        .eq('role', 'supplier')
        .eq('verification_status', 'verified')
        .order('company_name');

    return data.map((row) => SuperOpsSupplierOption(
      supplierId: row['id'] as String,
      supplierName: row['full_name'] as String? ?? '',
      mobile: row['mobile'] as String? ?? '',
      companyName: row['company_name'] as String? ?? '',
    )).toList();
  }

  Future<bool> postLoadOnBehalf(SuperOpsPostLoadPayload payload) async {
    final configured = _ref.read(supabaseConfiguredProvider);
    if (!configured) return false;

    final client = Supabase.instance.client;
    final adminId = await _currentAdminId(client);
    if (adminId == null) return false;

    final result = await client.rpc('admin_post_super_load', params: {
      'p_supplier_id': payload.supplierId,
      'p_origin_city': payload.originCity,
      'p_origin_state': payload.originState,
      'p_dest_city': payload.destCity,
      'p_dest_state': payload.destState,
      'p_material': payload.material,
      'p_weight_tonnes': payload.weightTonnes,
      'p_required_truck_type': payload.requiredTruckType,
      'p_trucks_needed': payload.trucksNeeded,
      'p_price': payload.price,
      'p_price_type': payload.priceType,
      'p_advance_percentage': payload.advancePercentage,
      'p_pickup_date': payload.pickupDate.toIso8601String(),
      'p_admin_id': adminId,
    });

    if (result != null && result['success'] == true) {
      await _ref
          .read(adminAuditRepositoryProvider)
          .logAction(
            action: 'post_load',
            entityType: 'super_ops',
            entityId: result['load_id'] as String,
            metadata: {
              'supplier_id': payload.supplierId,
              'origin': '${payload.originCity}, ${payload.originState}',
              'destination': '${payload.destCity}, ${payload.destState}',
              'material': payload.material,
              'weight': payload.weightTonnes,
              'trucks_needed': payload.trucksNeeded,
              'price': payload.price,
              'admin_id': adminId,
            },
            adminId: adminId,
          );
      return true;
    }
    return false;
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

  Future<Map<String, String>> _loadProfileNames(List<String> profileIds) async {
    if (profileIds.isEmpty) return {};

    final client = Supabase.instance.client;
    final data = await client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', profileIds);

    return {
      for (final row in data)
        row['id'] as String: _fallbackText(row['full_name'] as String?, 'Unknown')
    };
  }

  Future<Map<String, String>> _loadTruckNumbers(List<String> truckIds) async {
    if (truckIds.isEmpty) return {};

    final client = Supabase.instance.client;
    final data = await client
        .from('trucks')
        .select('id, truck_number')
        .inFilter('id', truckIds);

    return {
      for (final row in data)
        row['id'] as String: _fallbackText(
          row['truck_number'] as String?,
          'Unknown',
        )
    };
  }

  String _fallbackText(String? value, String fallback) {
    final text = (value ?? '').trim();
    return text.isEmpty ? fallback : text;
  }
}
