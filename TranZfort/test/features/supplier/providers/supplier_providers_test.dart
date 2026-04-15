import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_dashboard_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_profile_repository.dart';
import 'package:tranzfort/src/features/supplier/providers/supplier_providers.dart';

class _ProviderSupplierProfileBackend implements SupplierProfileBackend {
  final SupplierProfile? profile;
  final Object? error;

  _ProviderSupplierProfileBackend({this.profile, this.error});

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (error != null) {
      throw error!;
    }
    if (profile == null) {
      return null;
    }
    return {
      'id': profile!.id,
      'full_name': profile!.fullName,
      'mobile': profile!.mobile,
      'email': profile!.email,
      'verification_status': profile!.verificationStatus,
    };
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async {
    if (error != null) {
      throw error!;
    }
    if (profile == null) {
      return null;
    }
    return {
      'company_name': profile!.companyName,
      'business_licence_number': profile!.businessLicenceNumber,
      'gst_number': profile!.gstNumber,
      'total_loads_posted': profile!.totalLoadsPosted,
      'active_loads_count': profile!.activeLoadsCount,
    };
  }

  @override
  Future<void> updateSupplierExtension(String userId, Map<String, dynamic> values) async {}
}

class _ProviderSupplierDashboardBackend implements SupplierDashboardBackend {
  final SupplierDashboardStats? stats;
  final Object? error;

  _ProviderSupplierDashboardBackend({this.stats, this.error});

  @override
  Future<List<int>> fetchDashboardStats(String supplierId) async {
    if (error != null) {
      throw error!;
    }
    return [
      stats?.activeLoads ?? 0,
      stats?.pendingBookings ?? 0,
      stats?.inTransitTrips ?? 0,
      stats?.completedTrips ?? 0,
    ];
  }
}

void main() {
  group('supplier providers', () {
    test('supplierProfileProvider resolves success state', () async {
      final container = ProviderContainer(
        overrides: [
          supplierProfileRepositoryProvider.overrideWithValue(
            SupplierProfileRepository(
              _ProviderSupplierProfileBackend(
                profile: const SupplierProfile(
                  id: 'supplier-1',
                  fullName: 'Acme',
                  mobile: '+919999999999',
                  email: 'ops@acme.test',
                  verificationStatus: 'pending',
                  companyName: 'Acme Logistics',
                  businessLicenceNumber: 'BL-42',
                  gstNumber: '27ABCDE1234F1Z5',
                  totalLoadsPosted: 10,
                  activeLoadsCount: 4,
                ),
              ),
              () => 'supplier-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await container.read(supplierProfileProvider.future);

      expect(profile?.companyName, 'Acme Logistics');
      expect(profile?.activeLoadsCount, 4);
    });

    test('supplierProfileProvider surfaces app failure as async error', () async {
      final container = ProviderContainer(
        overrides: [
          supplierProfileRepositoryProvider.overrideWithValue(
            SupplierProfileRepository(
              _ProviderSupplierProfileBackend(error: const PermissionFailure()),
              () => 'supplier-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(supplierProfileProvider.future),
        throwsA(isA<PermissionFailure>()),
      );
    });

    test('supplierDashboardProvider resolves success state', () async {
      final container = ProviderContainer(
        overrides: [
          supplierDashboardRepositoryProvider.overrideWithValue(
            SupplierDashboardRepository(
              _ProviderSupplierDashboardBackend(
                stats: const SupplierDashboardStats(
                  activeLoads: 6,
                  pendingBookings: 2,
                  inTransitTrips: 1,
                  completedTrips: 9,
                ),
              ),
              () => 'supplier-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = await container.read(supplierDashboardProvider.future);

      expect(stats.activeLoads, 6);
      expect(stats.completedTrips, 9);
    });

    test('supplierDashboardProvider surfaces async error state', () async {
      final container = ProviderContainer(
        overrides: [
          supplierDashboardRepositoryProvider.overrideWithValue(
            SupplierDashboardRepository(
              _ProviderSupplierDashboardBackend(error: const NetworkFailure()),
              () => 'supplier-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(supplierDashboardProvider.future),
        throwsA(isA<NetworkFailure>()),
      );
    });
  });
}
