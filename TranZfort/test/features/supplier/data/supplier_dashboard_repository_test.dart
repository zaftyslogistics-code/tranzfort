import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_dashboard_repository.dart';

class _FakeSupplierDashboardBackend implements SupplierDashboardBackend {
  int activeLoads = 0;
  int pendingBookings = 0;
  int inTransitTrips = 0;
  int completedTrips = 0;
  Object? error;

  @override
  Future<int> countLoadsByStatuses(String supplierId, List<String> statuses) async {
    if (error != null) {
      throw error!;
    }
    return activeLoads;
  }

  @override
  Future<int> countPendingBookings(String supplierId) async {
    if (error != null) {
      throw error!;
    }
    return pendingBookings;
  }

  @override
  Future<int> countTripsByStages(String supplierId, List<String> stages) async {
    if (error != null) {
      throw error!;
    }
    if (stages.contains('completed')) {
      return completedTrips;
    }
    return inTransitTrips;
  }
}

void main() {
  group('SupplierDashboardRepository', () {
    test('returns dashboard stats from backend counts', () async {
      final backend = _FakeSupplierDashboardBackend()
        ..activeLoads = 5
        ..pendingBookings = 3
        ..inTransitTrips = 2
        ..completedTrips = 11;
      final repository = SupplierDashboardRepository(backend, () => 'supplier-1');

      final result = await repository.fetchDashboardStats();

      expect(result.isSuccess, isTrue);
      final stats = result.valueOrNull;
      expect(stats?.activeLoads, 5);
      expect(stats?.pendingBookings, 3);
      expect(stats?.inTransitTrips, 2);
      expect(stats?.completedTrips, 11);
    });

    test('returns unauthorized when there is no supplier session', () async {
      final repository = SupplierDashboardRepository(
        _FakeSupplierDashboardBackend(),
        () => null,
      );

      final result = await repository.fetchDashboardStats();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('maps network errors', () async {
      final backend = _FakeSupplierDashboardBackend()
        ..error = const SocketException('offline');
      final repository = SupplierDashboardRepository(backend, () => 'supplier-1');

      final result = await repository.fetchDashboardStats();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps permission errors', () async {
      final backend = _FakeSupplierDashboardBackend()
        ..error = const PostgrestException(
          message: 'forbidden',
          code: '42501',
        );
      final repository = SupplierDashboardRepository(backend, () => 'supplier-1');

      final result = await repository.fetchDashboardStats();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
