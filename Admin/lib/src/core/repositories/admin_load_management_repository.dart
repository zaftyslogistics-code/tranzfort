import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/admin_app_state_providers.dart';

enum AdminLoadFilter { all, active, draft, cancelled, completed, superLoads }

class AdminLoadManagementQuery {
  final AdminLoadFilter filter;
  final String search;

  const AdminLoadManagementQuery({required this.filter, required this.search});

  AdminLoadManagementQuery copyWith({AdminLoadFilter? filter, String? search}) {
    return AdminLoadManagementQuery(
      filter: filter ?? this.filter,
      search: search ?? this.search,
    );
  }
}

class AdminLoadListItem {
  final String id;
  final String supplierId;
  final String supplierName;
  final String routeLabel;
  final String material;
  final double? priceAmount;
  final int trucksNeeded;
  final int trucksBooked;
  final String status;
  final bool isSuperLoad;
  final String superStatus;
  final DateTime? pickupDate;
  final DateTime? createdAt;

  const AdminLoadListItem({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.routeLabel,
    required this.material,
    required this.priceAmount,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.status,
    required this.isSuperLoad,
    required this.superStatus,
    required this.pickupDate,
    required this.createdAt,
  });
}

class AdminLoadDetail {
  final String id;
  final String supplierId;
  final String supplierName;
  final String originLabel;
  final String destinationLabel;
  final String routeLabel;
  final String material;
  final double? weightTonnes;
  final String requiredBodyType;
  final List<int> requiredTyres;
  final int trucksNeeded;
  final int trucksBooked;
  final double? priceAmount;
  final String priceType;
  final int? advancePercentage;
  final String status;
  final bool isSuperLoad;
  final String superStatus;
  final DateTime? pickupDate;
  final DateTime? publishedAt;
  final DateTime? createdAt;

  const AdminLoadDetail({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.originLabel,
    required this.destinationLabel,
    required this.routeLabel,
    required this.material,
    required this.weightTonnes,
    required this.requiredBodyType,
    required this.requiredTyres,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.priceAmount,
    required this.priceType,
    required this.advancePercentage,
    required this.status,
    required this.isSuperLoad,
    required this.superStatus,
    required this.pickupDate,
    required this.publishedAt,
    required this.createdAt,
  });
}

abstract class AdminLoadManagementBackend {
  Future<List<Map<String, dynamic>>> fetchLoads();

  Future<Map<String, dynamic>?> fetchLoadById(String loadId);

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids);

  Future<bool> cancelLoad(String loadId);
}

class SupabaseAdminLoadManagementBackend implements AdminLoadManagementBackend {
  final SupabaseClient? client;

  const SupabaseAdminLoadManagementBackend(this.client);

  @override
  Future<List<Map<String, dynamic>>> fetchLoads() async {
    final activeClient = client;
    if (activeClient == null) {
      return const [];
    }
    final rows = await activeClient
        .from('loads')
        .select('id, supplier_id, origin_city, destination_city, material, price_amount, trucks_needed, trucks_booked, status, is_super_load, super_status, pickup_date, created_at, parent_load_id')
        .isFilter('parent_load_id', null)
        .order('created_at', ascending: false);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> fetchLoadById(String loadId) async {
    final activeClient = client;
    if (activeClient == null) {
      return null;
    }
    final row = await activeClient
        .from('loads')
        .select('id, supplier_id, origin_label, origin_city, destination_label, destination_city, material, weight_tonnes, required_body_type, required_tyres, trucks_needed, trucks_booked, price_amount, price_type, advance_percentage, status, is_super_load, super_status, pickup_date, published_at, created_at')
        .eq('id', loadId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfilesByIds(List<String> ids) async {
    final activeClient = client;
    if (activeClient == null || ids.isEmpty) {
      return const [];
    }
    final rows = await activeClient.from('profiles').select('id, full_name').inFilter('id', ids);
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList(growable: false);
  }

  @override
  Future<bool> cancelLoad(String loadId) async {
    final activeClient = client;
    if (activeClient == null) {
      return false;
    }
    await activeClient.rpc('cancel_load', params: {'p_load_id': loadId});
    return true;
  }
}

class AdminLoadManagementRepository {
  final AdminLoadManagementBackend backend;

  const AdminLoadManagementRepository({required this.backend});

  Future<List<AdminLoadListItem>> getLoads(AdminLoadManagementQuery query) async {
    final rows = await backend.fetchLoads();
    final supplierIds = rows.map((row) => _asString(row['supplier_id'])).where((id) => id.isNotEmpty).toSet().toList(growable: false);
    final profileRows = await backend.fetchProfilesByIds(supplierIds);
    final profileById = {for (final row in profileRows) _asString(row['id']): row};
    return rows
        .map((row) {
          final supplierId = _asString(row['supplier_id']);
          return AdminLoadListItem(
            id: _asString(row['id']),
            supplierId: supplierId,
            supplierName: _asString(profileById[supplierId]?['full_name']),
            routeLabel: '${_asString(row['origin_city'])} → ${_asString(row['destination_city'])}',
            material: _asString(row['material']),
            priceAmount: _asDouble(row['price_amount']),
            trucksNeeded: _asInt(row['trucks_needed']),
            trucksBooked: _asInt(row['trucks_booked']),
            status: _asString(row['status']),
            isSuperLoad: row['is_super_load'] == true,
            superStatus: _asString(row['super_status']),
            pickupDate: DateTime.tryParse(_asString(row['pickup_date'])),
            createdAt: DateTime.tryParse(_asString(row['created_at'])),
          );
        })
        .where((item) => _matchesFilter(item, query.filter))
        .where((item) => _matchesSearch(item, query.search))
        .toList(growable: false);
  }

  Future<AdminLoadDetail?> getLoadDetail(String loadId) async {
    final row = await backend.fetchLoadById(loadId);
    if (row == null) {
      return null;
    }
    final supplierId = _asString(row['supplier_id']);
    final profiles = await backend.fetchProfilesByIds([supplierId]);
    final supplier = profiles.isEmpty ? null : profiles.first;
    return AdminLoadDetail(
      id: _asString(row['id']),
      supplierId: supplierId,
      supplierName: _asString(supplier?['full_name']),
      originLabel: _asString(row['origin_label']),
      destinationLabel: _asString(row['destination_label']),
      routeLabel: '${_asString(row['origin_city'])} → ${_asString(row['destination_city'])}',
      material: _asString(row['material']),
      weightTonnes: _asDouble(row['weight_tonnes']),
      requiredBodyType: _asString(row['required_body_type']),
      requiredTyres: _asIntList(row['required_tyres']),
      trucksNeeded: _asInt(row['trucks_needed']),
      trucksBooked: _asInt(row['trucks_booked']),
      priceAmount: _asDouble(row['price_amount']),
      priceType: _asString(row['price_type']),
      advancePercentage: int.tryParse(_asString(row['advance_percentage'])),
      status: _asString(row['status']),
      isSuperLoad: row['is_super_load'] == true,
      superStatus: _asString(row['super_status']),
      pickupDate: DateTime.tryParse(_asString(row['pickup_date'])),
      publishedAt: DateTime.tryParse(_asString(row['published_at'])),
      createdAt: DateTime.tryParse(_asString(row['created_at'])),
    );
  }

  Future<bool> cancelLoad(String loadId) => backend.cancelLoad(loadId);
}

bool _matchesFilter(AdminLoadListItem item, AdminLoadFilter filter) {
  return switch (filter) {
    AdminLoadFilter.all => true,
    AdminLoadFilter.active => item.status == 'active',
    AdminLoadFilter.draft => item.status == 'draft',
    AdminLoadFilter.cancelled => item.status == 'cancelled',
    AdminLoadFilter.completed => item.status == 'completed',
    AdminLoadFilter.superLoads => item.isSuperLoad,
  };
}

bool _matchesSearch(AdminLoadListItem item, String search) {
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
      item.superStatus.toLowerCase().contains(normalized);
}

String _asString(dynamic value) => (value ?? '').toString();
int _asInt(dynamic value) => int.tryParse((value ?? '').toString()) ?? 0;
double? _asDouble(dynamic value) => double.tryParse((value ?? '').toString());
List<int> _asIntList(dynamic value) {
  if (value is List) {
    return value.map((entry) => int.tryParse((entry ?? '').toString()) ?? 0).where((entry) => entry > 0).toList(growable: false);
  }
  return const [];
}

final adminLoadManagementBackendProvider = Provider<AdminLoadManagementBackend>((ref) {
  return SupabaseAdminLoadManagementBackend(ref.watch(adminSupabaseClientProvider));
});

final adminLoadManagementRepositoryProvider = Provider<AdminLoadManagementRepository>((ref) {
  return AdminLoadManagementRepository(backend: ref.watch(adminLoadManagementBackendProvider));
});
