import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_profile_repository.dart';

class _FakeSupplierProfileBackend implements SupplierProfileBackend {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? supplier;
  Object? fetchError;
  Object? updateError;
  String? updatedUserId;
  Map<String, dynamic>? updatedValues;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return profile;
  }

  @override
  Future<Map<String, dynamic>?> fetchSupplierExtension(String userId) async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return supplier;
  }

  @override
  Future<void> updateSupplierExtension(String userId, Map<String, dynamic> values) async {
    if (updateError != null) {
      throw updateError!;
    }
    updatedUserId = userId;
    updatedValues = values;
  }
}

void main() {
  group('SupplierProfileRepository', () {
    test('maps profile and supplier extension into supplier profile', () async {
      final backend = _FakeSupplierProfileBackend()
        ..profile = {
          'id': 'supplier-1',
          'full_name': 'Acme Logistics',
          'mobile': '+919999999999',
          'email': 'ops@acme.test',
          'verification_status': 'pending',
        }
        ..supplier = {
          'company_name': 'Acme Logistics Pvt Ltd',
          'business_licence_number': 'BL-42',
          'gst_number': '27ABCDE1234F1Z5',
          'total_loads_posted': 12,
          'active_loads_count': 4,
        };
      final repository = SupplierProfileRepository(backend, () => 'supplier-1');

      final result = await repository.fetchCurrentSupplierProfile();

      expect(result.isSuccess, isTrue);
      final profile = result.valueOrNull;
      expect(profile, isNotNull);
      expect(profile?.fullName, 'Acme Logistics');
      expect(profile?.companyName, 'Acme Logistics Pvt Ltd');
      expect(profile?.businessLicenceNumber, 'BL-42');
      expect(profile?.gstNumber, '27ABCDE1234F1Z5');
      expect(profile?.activeLoadsCount, 4);
    });

    test('returns validation failure when company name is empty', () async {
      final repository = SupplierProfileRepository(
        _FakeSupplierProfileBackend(),
        () => 'supplier-1',
      );

      final result = await repository.updateBusinessFields(companyName: '   ');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('maps network errors during fetch', () async {
      final backend = _FakeSupplierProfileBackend()
        ..fetchError = const SocketException('offline');
      final repository = SupplierProfileRepository(backend, () => 'supplier-1');

      final result = await repository.fetchCurrentSupplierProfile();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps permission errors during update', () async {
      final backend = _FakeSupplierProfileBackend()
        ..updateError = const PostgrestException(
          message: 'forbidden',
          code: '42501',
        );
      final repository = SupplierProfileRepository(backend, () => 'supplier-1');

      final result = await repository.updateBusinessFields(companyName: 'Acme');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
