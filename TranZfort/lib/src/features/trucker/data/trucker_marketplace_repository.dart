import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/services/route_snapshot_service.dart';
import '../../../core/utils/map_readers.dart';

const int truckerMarketplacePageSize = 50;

class MarketplaceLoadItem {
  final String id;
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

  factory MarketplaceLoadItem.fromMap(Map<String, dynamic> map) {
    return MarketplaceLoadItem(
      id: (map['id'] ?? '').toString(),
      originLabel: (map['origin_label'] ?? '').toString(),
      originCity: (map['origin_city'] ?? '').toString(),
      originState: nullableString(map['origin_state']),
      originLat: readDouble(map['origin_lat']),
      originLng: readDouble(map['origin_lng']),
      destinationLabel: (map['destination_label'] ?? '').toString(),
      destinationCity: (map['destination_city'] ?? '').toString(),
      destinationState: nullableString(map['destination_state']),
      destinationLat: readDouble(map['destination_lat']),
      destinationLng: readDouble(map['destination_lng']),
      routeDistanceKm: readDouble(map['route_distance_km']),
      routeDurationMinutes: readInt(map['route_duration_minutes']),
      routeSnapshotSource: nullableString(map['route_snapshot_source']),
      material: (map['material'] ?? '').toString(),
      weightTonnes: readDouble(map['weight_tonnes']),
      requiredBodyType: nullableString(map['required_body_type']),
      requiredTyres: _readTyres(map['required_tyres']),
      trucksNeeded: readInt(map['trucks_needed']),
      trucksBooked: readInt(map['trucks_booked']),
      priceAmount: readDouble(map['price_amount']),
      priceType: (map['price_type'] ?? 'fixed').toString(),
      advancePercentage: readInt(map['advance_percentage']),
      pickupDate: DateTime.parse((map['pickup_date'] ?? '').toString()),
      status: (map['status'] ?? 'active').toString(),
      isSuperLoad: map['is_super_load'] == true,
      superStatus: (map['super_status'] ?? 'none').toString(),
      createdAt: DateTime.parse((map['created_at'] ?? '').toString()),
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

abstract class TruckerMarketplaceBackend {
  Future<List<Map<String, dynamic>>> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  });
}

class SupabaseTruckerMarketplaceBackend implements TruckerMarketplaceBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerMarketplaceBackend(this._client);

  @override
  Future<List<Map<String, dynamic>>> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    var filteredQuery = _client
        .from('loads')
        .select(
          'id, origin_label, origin_city, origin_state, origin_lat, origin_lng, destination_label, destination_city, destination_state, destination_lat, destination_lng, route_distance_km, route_duration_minutes, route_snapshot_source, material, weight_tonnes, required_body_type, required_tyres, trucks_needed, trucks_booked, price_amount, price_type, advance_percentage, pickup_date, status, is_super_load, super_status, created_at, parent_load_id',
        )
        .isFilter('parent_load_id', null)
        .inFilter('status', const ['active', 'assigned_partial']);

    // Escape SQL LIKE wildcard characters to prevent injection
    String escapeLike(String s) => s.replaceAll(r'%', r'\%').replaceAll(r'_', r'\_');

    final origin = escapeLike(filters.originCity.trim());
    final destination = escapeLike(filters.destinationCity.trim());
    final material = escapeLike(filters.material.trim());
    final bodyType = filters.truckBodyType.trim();
    final minPrice = filters.minPrice;
    final maxPrice = filters.maxPrice;

    if (origin.isNotEmpty) {
      filteredQuery = filteredQuery.ilike('origin_city', '%$origin%');
    }
    if (destination.isNotEmpty) {
      filteredQuery = filteredQuery.ilike('destination_city', '%$destination%');
    }
    if (material.isNotEmpty) {
      filteredQuery = filteredQuery.ilike('material', '%$material%');
    }
    if (bodyType.isNotEmpty) {
      filteredQuery = filteredQuery.eq('required_body_type', bodyType);
    }
    if (filters.superLoadsOnly) {
      filteredQuery = filteredQuery.eq('is_super_load', true);
    }
    if (filters.tyres.isNotEmpty) {
      filteredQuery = filteredQuery.overlaps('required_tyres', filters.tyres);
    }
    if (minPrice != null) {
      filteredQuery = filteredQuery.gte('price_amount', minPrice);
    }
    if (maxPrice != null) {
      filteredQuery = filteredQuery.lte('price_amount', maxPrice);
    }

    final sortedQuery = switch (filters.sortOption) {
      MarketplaceSortOption.newest => filteredQuery.order('created_at', ascending: false),
      MarketplaceSortOption.priceHighToLow => filteredQuery.order('price_amount', ascending: false),
      MarketplaceSortOption.priceLowToHigh => filteredQuery.order('price_amount', ascending: true),
      MarketplaceSortOption.pickupDate => filteredQuery.order('pickup_date', ascending: true),
    };

    final response = await sortedQuery.range(from, to);
    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

class TruckerMarketplaceRepository {
  final TruckerMarketplaceBackend _backend;

  const TruckerMarketplaceRepository(this._backend);

  Future<Result<List<MarketplaceLoadItem>>> searchLoads(
    MarketplaceSearchFilters filters, {
    int page = 1,
    int pageSize = truckerMarketplacePageSize,
  }) async {
    try {
      final rows = await _backend.searchLoads(filters, page: page, pageSize: pageSize);
      return Success<List<MarketplaceLoadItem>>(
        rows.map(MarketplaceLoadItem.fromMap).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<MarketplaceLoadItem>>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);
}

final truckerMarketplaceRepositoryProvider = Provider<TruckerMarketplaceRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerMarketplaceRepository(SupabaseTruckerMarketplaceBackend(client));
});
