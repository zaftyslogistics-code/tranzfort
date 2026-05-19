import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/route_snapshot_service.dart';
import '../../../core/utils/map_readers.dart';
import '../../../core/utils/type_safety.dart';

const int truckerMarketplacePageSize = 20;

class SupplierInfo {
  final String name;
  final String? avatarUrl;

  const SupplierInfo({
    required this.name,
    this.avatarUrl,
  });

  factory SupplierInfo.fromMap(Map<String, dynamic> map) {
    final avatarUrl = safeString(map['avatar_url']);
    final profilePhotoPath = safeString(map['profile_photo_document_path']);
    return SupplierInfo(
      name: safeString(map['full_name']),
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : (profilePhotoPath.isNotEmpty ? profilePhotoPath : null),
    );
  }

  /// Parse from the `supplier_summary` JSONB object returned by `get_marketplace_feed` RPC.
  factory SupplierInfo.fromRpcSummary(Map<String, dynamic> summary) {
    final avatarUrl = safeString(summary['supplier_avatar_url']);
    final photoPath = safeString(summary['supplier_photo_path']);
    return SupplierInfo(
      name: safeString(summary['supplier_name']),
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : (photoPath.isNotEmpty ? photoPath : null),
    );
  }
}

class MarketplaceLoadItem {
  final String id;
  final String supplierId;
  final String? supplierName;
  final String? supplierAvatarUrl;
  final String originLabel;
  final String originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String destinationLabel;
  final String destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final double? routeDistanceKm;
  final int? routeDurationMinutes;
  final String? routeSnapshotSource;
  final String material;
  final double weightTonnes;
  final String? requiredBodyType;
  final List<int> requiredTyres;
  final int trucksNeeded;
  final int trucksBooked;
  final double priceAmount;
  final String priceType;
  final int advancePercentage;
  final DateTime pickupDate;
  final String status;
  final bool isSuperLoad;
  final String superStatus;
  final DateTime createdAt;

  const MarketplaceLoadItem({
    required this.id,
    required this.supplierId,
    this.supplierName,
    this.supplierAvatarUrl,
    required this.originLabel,
    required this.originCity,
    required this.originState,
    required this.originLat,
    required this.originLng,
    required this.destinationLabel,
    required this.destinationCity,
    required this.destinationState,
    required this.destinationLat,
    required this.destinationLng,
    required this.routeDistanceKm,
    required this.routeDurationMinutes,
    this.routeSnapshotSource,
    required this.material,
    required this.weightTonnes,
    required this.requiredBodyType,
    required this.requiredTyres,
    required this.trucksNeeded,
    required this.trucksBooked,
    required this.priceAmount,
    required this.priceType,
    required this.advancePercentage,
    required this.pickupDate,
    required this.status,
    required this.isSuperLoad,
    required this.superStatus,
    required this.createdAt,
  });

  MarketplaceLoadItem copyWith({
    String? supplierName,
    String? supplierAvatarUrl,
  }) {
    return MarketplaceLoadItem(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierAvatarUrl: supplierAvatarUrl ?? this.supplierAvatarUrl,
      originLabel: originLabel,
      originCity: originCity,
      originState: originState,
      originLat: originLat,
      originLng: originLng,
      destinationLabel: destinationLabel,
      destinationCity: destinationCity,
      destinationState: destinationState,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      routeDistanceKm: routeDistanceKm,
      routeDurationMinutes: routeDurationMinutes,
      routeSnapshotSource: routeSnapshotSource,
      material: material,
      weightTonnes: weightTonnes,
      requiredBodyType: requiredBodyType,
      requiredTyres: requiredTyres,
      trucksNeeded: trucksNeeded,
      trucksBooked: trucksBooked,
      priceAmount: priceAmount,
      priceType: priceType,
      advancePercentage: advancePercentage,
      pickupDate: pickupDate,
      status: status,
      isSuperLoad: isSuperLoad,
      superStatus: superStatus,
      createdAt: createdAt,
    );
  }

  factory MarketplaceLoadItem.fromMap(Map<String, dynamic> map) {
    // Prefer embedded supplier_summary from consolidated RPC, fall back to top-level fields
    final supplierSummary = safeMap(map['supplier_summary']);
    final supplierInfo = supplierSummary != null
        ? SupplierInfo.fromRpcSummary(supplierSummary)
        : null;

    return MarketplaceLoadItem(
      id: (map['id'] ?? '').toString(),
      supplierId: (map['supplier_id'] ?? '').toString(),
      supplierName: supplierInfo?.name ?? nullableString(map['supplier_name']),
      supplierAvatarUrl: supplierInfo?.avatarUrl ?? nullableString(map['supplier_avatar_url']),
      originLabel: (map['origin_label'] ?? '').toString(),
      originCity: (map['origin_city'] ?? '').toString(),
      originState: nullableString(map['origin_state']),
      originLat: readDoubleNullable(map['origin_lat']),
      originLng: readDoubleNullable(map['origin_lng']),
      destinationLabel: (map['destination_label'] ?? '').toString(),
      destinationCity: (map['destination_city'] ?? '').toString(),
      destinationState: nullableString(map['destination_state']),
      destinationLat: readDoubleNullable(map['destination_lat']),
      destinationLng: readDoubleNullable(map['destination_lng']),
      routeDistanceKm: readDoubleNullable(map['route_distance_km']),
      routeDurationMinutes: readInt(map['route_duration_minutes']),
      routeSnapshotSource: nullableString(map['route_snapshot_source']),
      material: (map['material'] ?? '').toString(),
      weightTonnes: readDoubleNullable(map['weight_tonnes']) ?? 0.0,
      requiredBodyType: nullableString(map['required_body_type']),
      requiredTyres: _readTyres(map['required_tyres']),
      trucksNeeded: readInt(map['trucks_needed']),
      trucksBooked: readInt(map['trucks_booked']),
      priceAmount: readDoubleNullable(map['price_amount']) ?? 0.0,
      priceType: (map['price_type'] ?? 'fixed').toString(),
      advancePercentage: readInt(map['advance_percentage']),
      pickupDate: readDate(map['pickup_date']) ?? DateTime.now(),
      status: (map['status'] ?? 'active').toString(),
      isSuperLoad: map['is_super_load'] == true,
      superStatus: (map['super_status'] ?? 'none').toString(),
      createdAt: readDate(map['created_at']) ?? DateTime.now(),
    );
  }

  RouteSnapshot? get routeSnapshot {
    if (routeDistanceKm == null || routeDurationMinutes == null) {
      return null;
    }
    return RouteSnapshot.fromStoredFields(
      distanceKm: routeDistanceKm,
      durationMinutes: routeDurationMinutes,
      source: routeSnapshotSource,
    );
  }

  /// Derived acceptable truck capacity range from selected tyre counts.
  /// Based on Indian CMVR payload norms (typical usable payload, not GVW).
  static const Map<int, ({double min, double max})> _tyreToPayloadRange = {
    10: (min: 18.0, max: 21.0),
    12: (min: 21.0, max: 24.0),
    14: (min: 28.0, max: 32.0),
    16: (min: 31.0, max: 35.0),
    18: (min: 34.0, max: 42.0),
    22: (min: 42.0, max: 42.0),
  };

  /// Minimum truck capacity acceptable for this load, derived from selected tyre counts.
  /// Returns a wide fallback (7T) when any tyre count is selected.
  double? get derivedMinTruckCapacityTonnes {
    if (requiredTyres.isEmpty) return 7.0;
    final mins = requiredTyres
        .map((t) => _tyreToPayloadRange[t]?.min)
        .whereType<double>();
    return mins.isEmpty ? null : mins.reduce((a, b) => a < b ? a : b);
  }

  /// Maximum truck capacity acceptable for this load, derived from selected tyre counts.
  /// Returns a wide fallback (42T) when any tyre count is selected.
  double? get derivedMaxTruckCapacityTonnes {
    if (requiredTyres.isEmpty) return 42.0;
    final maxs = requiredTyres
        .map((t) => _tyreToPayloadRange[t]?.max)
        .whereType<double>();
    return maxs.isEmpty ? null : maxs.reduce((a, b) => a > b ? a : b);
  }

  /// Per-truck weight this load expects.
  double get perTruckWeightTonnes => weightTonnes / trucksNeeded;

  // Private helpers removed - using shared map_readers.dart helpers where applicable
  // _readTyres remains as it's used internally
  static List<int> _readTyres(Object? value) {
    if (value is List) {
      return value.map((item) => int.tryParse(item.toString()) ?? 0).where((item) => item > 0).toList(growable: false);
    }
    return const <int>[];
  }
}

enum MarketplaceSortOption {
  newest,
  priceHighToLow,
  priceLowToHigh,
  pickupDate,
}

class MarketplaceSearchFilters {
  final String originCity;
  final String destinationCity;
  final String material;
  final String truckBodyType;
  final List<int> tyres;
  final double? minPrice;
  final double? maxPrice;
  final bool superLoadsOnly;
  final MarketplaceSortOption sortOption;

  const MarketplaceSearchFilters({
    this.originCity = '',
    this.destinationCity = '',
    this.material = '',
    this.truckBodyType = '',
    this.tyres = const <int>[],
    this.minPrice,
    this.maxPrice,
    this.superLoadsOnly = false,
    this.sortOption = MarketplaceSortOption.newest,
  });

  MarketplaceSearchFilters copyWith({
    String? originCity,
    String? destinationCity,
    String? material,
    String? truckBodyType,
    List<int>? tyres,
    double? minPrice,
    double? maxPrice,
    bool? superLoadsOnly,
    MarketplaceSortOption? sortOption,
  }) {
    return MarketplaceSearchFilters(
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      material: material ?? this.material,
      truckBodyType: truckBodyType ?? this.truckBodyType,
      tyres: tyres ?? this.tyres,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      superLoadsOnly: superLoadsOnly ?? this.superLoadsOnly,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  bool get hasActiveFilters {
    return originCity.trim().isNotEmpty ||
        destinationCity.trim().isNotEmpty ||
        material.trim().isNotEmpty ||
        truckBodyType.trim().isNotEmpty ||
        tyres.isNotEmpty ||
        minPrice != null ||
        maxPrice != null ||
        superLoadsOnly;
  }

  int get activeFilterCount {
    var count = 0;
    if (originCity.trim().isNotEmpty) count += 1;
    if (destinationCity.trim().isNotEmpty) count += 1;
    if (material.trim().isNotEmpty) count += 1;
    if (truckBodyType.trim().isNotEmpty) count += 1;
    if (tyres.isNotEmpty) count += 1;
    if (minPrice != null || maxPrice != null) count += 1;
    if (superLoadsOnly) count += 1;
    return count;
  }
}

class MarketplaceSearchResult {
  final List<MarketplaceLoadItem> items;
  final int total;
  final bool hasMore;
  final int page;
  final int pageSize;

  const MarketplaceSearchResult({
    required this.items,
    required this.total,
    required this.hasMore,
    required this.page,
    required this.pageSize,
  });
}

abstract class TruckerMarketplaceBackend {
  Future<MarketplaceSearchResult> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  });

  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId);
}

class SupabaseTruckerMarketplaceBackend implements TruckerMarketplaceBackend {
  final SupabaseClient? _client;

  SupabaseTruckerMarketplaceBackend(this._client);

  @override
  Future<MarketplaceSearchResult> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    // Use consolidated RPC that returns load + supplier summary + ranking metadata in one call
    final response = await _client.rpc(
      'get_marketplace_feed',
      params: <String, dynamic>{
        'p_origin_city': _nullableString(filters.originCity.trim()),
        'p_destination_city': _nullableString(filters.destinationCity.trim()),
        'p_material': _nullableString(filters.material.trim()),
        'p_body_type': _nullableString(filters.truckBodyType.trim()),
        'p_min_price': filters.minPrice,
        'p_max_price': filters.maxPrice,
        'p_super_loads_only': filters.superLoadsOnly,
        'p_required_tyres': filters.tyres.isEmpty ? null : filters.tyres,
        'p_sort_by': _sortByParam(filters.sortOption),
        'p_page_size': pageSize,
        'p_page': page,
      },
    );

    final resultMap = response is Map<String, dynamic> ? response : <String, dynamic>{};
    final loadsList = resultMap['loads'];
    final rawItems = loadsList is List ? loadsList : <dynamic>[];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceLoadItem.fromMap)
        .toList(growable: false);

    return MarketplaceSearchResult(
      items: items,
      total: readInt(resultMap['total']),
      hasMore: resultMap['has_more'] == true,
      page: page,
      pageSize: pageSize,
    );
  }

  String? _nullableString(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _sortByParam(MarketplaceSortOption sort) {
    return switch (sort) {
      MarketplaceSortOption.newest => 'newest',
      MarketplaceSortOption.priceHighToLow => 'price_desc',
      MarketplaceSortOption.priceLowToHigh => 'price_asc',
      MarketplaceSortOption.pickupDate => 'pickup_date',
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    return _client
        .from('profiles')
        .select('id, mobile')
        .eq('id', supplierId)
        .maybeSingle();
  }
}

class TruckerMarketplaceRepository {
  final TruckerMarketplaceBackend _backend;

  const TruckerMarketplaceRepository(this._backend);

  Future<Result<MarketplaceSearchResult>> searchLoads(
    MarketplaceSearchFilters filters, {
    int page = 1,
    int pageSize = truckerMarketplacePageSize,
  }) async {
    final result = await _backend.searchLoads(filters, page: page, pageSize: pageSize);
    return Success<MarketplaceSearchResult>(result);
  }

  Future<Result<String?>> getSupplierMobile(String supplierId) async {
    final normalizedSupplierId = supplierId.trim();
    if (normalizedSupplierId.isEmpty) {
      return const Failure<String?>(
        ValidationFailure(
          message: 'Supplier id is required',
          fieldErrors: {'supplier_id': 'Supplier id is required'},
        ),
      );
    }

    try {
      final profile = await _backend.fetchSupplierProfile(normalizedSupplierId);
      if (profile == null) {
        return const Failure<String?>(NotFoundFailure());
      }
      return Success<String?>(nullableString(profile['mobile']));
    } catch (error, stackTrace) {
      return Failure<String?>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);
}

final truckerMarketplaceRepositoryProvider = Provider<TruckerMarketplaceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerMarketplaceRepository(SupabaseTruckerMarketplaceBackend(client));
});
