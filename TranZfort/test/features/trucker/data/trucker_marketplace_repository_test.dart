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
  Future<List<Map<String, dynamic>>> searchLoads(
    MarketplaceSearchFilters filters, {
    required int page,
    required int pageSize,
  }) async {
    if (error != null) {
      throw error!;
    }
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierProfile(String supplierId) async {
    if (error != null) {
      throw error!;
    }
    return supplierProfile;
  }
}

void main() {
  group('TruckerMarketplaceRepository', () {
    test('maps marketplace rows into load items', () async {
      final backend = _FakeTruckerMarketplaceBackend()
        ..rows = [
          {
            'id': 'load-1',
            'origin_label': 'Chandrapur, Maharashtra',
            'origin_city': 'Chandrapur',
            'origin_state': 'Maharashtra',
            'destination_label': 'Mumbai, Maharashtra',
            'destination_city': 'Mumbai',
            'destination_state': 'Maharashtra',
            'route_distance_km': 820,
            'route_duration_minutes': 780,
            'material': 'Coal',
            'weight_tonnes': 22,
            'required_body_type': 'Open',
            'required_tyres': [10, 12],
            'trucks_needed': 2,
            'trucks_booked': 1,
            'price_amount': 54000,
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
      expect(loads, hasLength(1));
      expect(loads?.first.originCity, 'Chandrapur');
      expect(loads?.first.requiredTyres, [10, 12]);
      expect(loads?.first.isSuperLoad, isTrue);
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
