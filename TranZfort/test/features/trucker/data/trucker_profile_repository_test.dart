import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_profile_repository.dart';

class _FakeTruckerProfileBackend implements TruckerProfileBackend {
  Map<String, dynamic>? profile;
  Map<String, dynamic>? trucker;
  Object? fetchError;
  Object? updateError;
  String? updatedUserId;
  Map<String, dynamic>? updatedValues;
  int totalTrucks = 0;
  int approvedTrucks = 0;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return profile;
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerExtension(String userId) async {
    if (fetchError != null) {
      throw fetchError!;
    }
    return trucker;
  }

  @override
  Future<int> countTrucksByStatuses(String userId, List<String> statuses) async {
    if (fetchError != null) {
      throw fetchError!;
    }
    if (statuses.contains('verified')) {
      return approvedTrucks;
    }
    return totalTrucks;
  }

  @override
  Future<void> updateTruckerExtension(String userId, Map<String, dynamic> values) async {
    if (updateError != null) {
      throw updateError!;
    }
    updatedUserId = userId;
    updatedValues = values;
  }
}

void main() {
  group('TruckerProfileRepository', () {
    test('maps profile and trucker extension into trucker profile', () async {
      final backend = _FakeTruckerProfileBackend()
        ..profile = {
          'id': 'trucker-1',
          'full_name': 'Ravi Trucker',
          'mobile': '+919999999999',
          'email': 'ravi@example.com',
          'verification_status': 'pending',
        }
        ..trucker = {
          'dl_number': 'DL-0099',
          'rating': 4.7,
          'total_trips': 23,
          'completed_trips': 19,
        }
        ..totalTrucks = 3
        ..approvedTrucks = 1;
      final repository = TruckerProfileRepository(backend, () => 'trucker-1');

      final result = await repository.fetchCurrentTruckerProfile();

      expect(result.isSuccess, isTrue);
      final profile = result.valueOrNull;
      expect(profile, isNotNull);
      expect(profile?.fullName, 'Ravi Trucker');
      expect(profile?.dlNumber, 'DL-0099');
      expect(profile?.rating, 4.7);
      expect(profile?.totalTrucks, 3);
      expect(profile?.approvedTrucks, 1);
    });

    test('returns success null when there is no profile row', () async {
      final repository = TruckerProfileRepository(
        _FakeTruckerProfileBackend(),
        () => 'trucker-1',
      );

      final result = await repository.fetchCurrentTruckerProfile();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('maps network errors during fetch', () async {
      final backend = _FakeTruckerProfileBackend()
        ..fetchError = const SocketException('offline');
      final repository = TruckerProfileRepository(backend, () => 'trucker-1');

      final result = await repository.fetchCurrentTruckerProfile();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('maps permission errors during update', () async {
      final backend = _FakeTruckerProfileBackend()
        ..updateError = const PostgrestException(
          message: 'forbidden',
          code: '42501',
        );
      final repository = TruckerProfileRepository(backend, () => 'trucker-1');

      final result = await repository.updateLicenceNumber('DL-0099');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<PermissionFailure>());
    });
  });
}
