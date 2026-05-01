import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';

class _FakeTruckerMarketplaceBackend implements TruckerMarketplaceBackend {
  List<Map<String, dynamic>> rows = const <Map<String, dynamic>>[];
  Map<String, dynamic>? supplierProfile;
  Object? error;

  @override
  Future<MarketplaceSearchResult> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    if (error != null) {
      throw error!;
    }
    // Convert rows to MarketplaceLoadItem list
    final items = rows.map((row) => MarketplaceLoadItem(
      id: row['id'] as String,
      supplierId: row['supplier_id'] as String,
      originLabel: row['origin_label'] as String,
      originCity: row['origin_city'] as String,
      originState: row['origin_state'] as String,
      originLat: (row['origin_lat'] as num?)?.toDouble(),
      originLng: (row['origin_lng'] as num?)?.toDouble(),
      destinationLabel: row['destination_label'] as String,
      destinationCity: row['destination_city'] as String,
      destinationState: row['destination_state'] as String,
      destinationLat: (row['destination_lat'] as num?)?.toDouble(),
      destinationLng: (row['destination_lng'] as num?)?.toDouble(),
      routeDistanceKm: (row['route_distance_km'] as num?)?.toDouble(),
      routeDurationMinutes: row['route_duration_minutes'] as int?,
      material: row['material'] as String,
      weightTonnes: (row['weight_tonnes'] as num).toDouble(),
      requiredBodyType: row['required_body_type'] as String?,
      requiredTyres: (row['required_tyres'] as List<dynamic>).cast<int>(),
      trucksNeeded: row['trucks_needed'] as int,
      trucksBooked: row['trucks_booked'] as int,
      priceAmount: (row['price_amount'] as num).toDouble(),
      priceType: row['price_type'] as String,
      advancePercentage: row['advance_percentage'] as int,
      pickupDate: DateTime.parse(row['pickup_date'] as String),
      status: row['status'] as String,
      isSuperLoad: row['is_super_load'] as bool,
      superStatus: row['super_status'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    )).toList();
    
    return MarketplaceSearchResult(
      items: items,
      total: items.length,
      hasMore: false,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async {
    if (error != null) {
      throw error!;
    }
    return supplierProfile;
  }

  @override
  Future<Map<String, SupplierInfo>> fetchSupplierInfo(List<String> supplierIds) async {
    return const <String, SupplierInfo>{};
  }
}

void main() {
  group('TruckerMarketplaceRepository', () {
    test('maps marketplace rows into load items', () async {
      final backend = _FakeTruckerMarketplaceBackend()
        ..rows = [
          {
            'id': 'load-1',
            'supplier_id': 'supplier-1',
            'origin_label': 'Chandrapur, Maharashtra',
            'origin_city': 'Chandrapur',
            'origin_state': 'Maharashtra',
            'origin_lat': 19.95,
            'origin_lng': 79.29,
            'destination_label': 'Mumbai, Maharashtra',
            'destination_city': 'Mumbai',
            'destination_state': 'Maharashtra',
            'destination_lat': 19.07,
            'destination_lng': 72.87,
            'route_distance_km': 820.0,
            'route_duration_minutes': 780,
            'material': 'Coal',
            'weight_tonnes': 22.0,
            'required_body_type': 'Open',
            'required_tyres': [10, 12],
            'trucks_needed': 2,
            'trucks_booked': 1,
            'price_amount': 54000.0,
            'price_type': 'negotiable',
            'advance_percentage': 30,
            'pickup_date': '2026-03-12',
            'status': 'active',
            'is_super_load': true,
            'super_status': 'active',
            'created_at': '2026-03-08T12:00:00.000Z',
          },
        ];
      final repository = TruckerMarketplaceRepository(backend);

      final result = await repository.searchLoads(const MarketplaceSearchFilters());

      expect(result.isSuccess, isTrue);
      final loads = result.valueOrNull;
      expect(loads?.items, hasLength(1));
      expect(loads?.items.first.originCity, 'Chandrapur');
      expect(loads?.items.first.requiredTyres, [10, 12]);
      expect(loads?.items.first.isSuperLoad, isTrue);
    });

    test('maps network errors', () async {
      final backend = _FakeTruckerMarketplaceBackend()
        ..error = const SocketException('offline');
      final repository = TruckerMarketplaceRepository(backend);

      final result = await repository.searchLoads(const MarketplaceSearchFilters());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps permission errors', () async {
      final backend = _FakeTruckerMarketplaceBackend()
        ..error = const PostgrestException(message: 'forbidden', code: '42501');
      final repository = TruckerMarketplaceRepository(backend);

      final result = await repository.searchLoads(const MarketplaceSearchFilters());

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });

    test('returns supplier mobile from direct supplier profile lookup', () async {
      final backend = _FakeTruckerMarketplaceBackend()
        ..supplierProfile = {
          'id': 'supplier-1',
          'mobile': '+919876543210',
        };
      final repository = TruckerMarketplaceRepository(backend);

      final result = await repository.getSupplierMobile('supplier-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, '+919876543210');
    });
  });
}
