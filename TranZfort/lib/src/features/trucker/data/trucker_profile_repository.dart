import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/utils/map_readers.dart';

class TruckerProfile {
  final String id;
  final String fullName;
  final String? mobile;
  final String? email;
  final String verificationStatus;
  final String? dlNumber;
  final double rating;
  final int totalTrips;
  final int completedTrips;
  final int totalTrucks;
  final int approvedTrucks;

  const TruckerProfile({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.verificationStatus,
    required this.dlNumber,
    required this.rating,
    required this.totalTrips,
    required this.completedTrips,
    required this.totalTrucks,
    required this.approvedTrucks,
  });

  bool get hasApprovedTruck => approvedTrucks > 0;
  bool get isVerified => verificationStatus.trim().toLowerCase() == 'verified';

  factory TruckerProfile.fromMaps(
    Map<String, dynamic> profileMap,
    Map<String, dynamic>? truckerMap, {
    required int totalTrucks,
    required int approvedTrucks,
  }) {
    return TruckerProfile(
      id: (profileMap['id'] ?? '').toString(),
      fullName: (profileMap['full_name'] ?? '').toString(),
      mobile: nullableString(profileMap['mobile']),
      email: nullableString(profileMap['email']),
      verificationStatus: (profileMap['verification_status'] ?? 'unverified').toString(),
      dlNumber: nullableString(truckerMap?['dl_number']),
      rating: readDouble(truckerMap?['rating']),
      totalTrips: readInt(truckerMap?['total_trips']),
      completedTrips: readInt(truckerMap?['completed_trips']),
      totalTrucks: totalTrucks,
      approvedTrucks: approvedTrucks,
    );
  }

}

abstract class TruckerProfileBackend {
  Future<Map<String, dynamic>?> fetchProfile(String userId);

  Future<Map<String, dynamic>?> fetchTruckerExtension(String userId);

  Future<int> countTrucksByStatuses(String userId, List<String> statuses);

  Future<void> updateTruckerExtension(String userId, Map<String, dynamic> values);
}

class SupabaseTruckerProfileBackend implements TruckerProfileBackend {
  final SupabaseClient? _client;

  const SupabaseTruckerProfileBackend(this._client);

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to read trucker profile');
    }

    final response = await _client.rpc('get_current_user_profile');
    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerExtension(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to read trucker workspace profile');
    }

    final response = await _client.rpc('get_trucker_workspace_profile');
    if (response is Map<String, dynamic> && response.isNotEmpty) {
      return response;
    }
    return null;
  }

  @override
  Future<int> countTrucksByStatuses(String userId, List<String> statuses) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to read truck counts');
    }

    final response = await _client.rpc('get_trucker_truck_verification_counts');
    if (response is! Map<String, dynamic>) {
      return 0;
    }

    if (statuses.isEmpty) {
      return _readCount(response['total_count']);
    }
    if (statuses.length == 1 && statuses.first == 'verified') {
      return _readCount(response['approved_count']);
    }

    return 0;
  }

  static int _readCount(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Future<void> updateTruckerExtension(String userId, Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Trucker session is not available');
    }

    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId != userId) {
      throw const AuthException('Not authorized to update trucker profile');
    }

    if (values.containsKey('dl_number')) {
      await _client.rpc(
        'update_trucker_dl_number',
        params: <String, dynamic>{
          'p_dl_number': values['dl_number']?.toString(),
        },
      );
    }
  }
}

class TruckerProfileRepository {
  final TruckerProfileBackend _backend;
  final String? Function() _currentUserId;

  const TruckerProfileRepository(this._backend, this._currentUserId);

  Future<Result<TruckerProfile?>> fetchCurrentTruckerProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<TruckerProfile?>(UnauthorizedFailure());
    }

    try {
      final profileMap = await _backend.fetchProfile(userId);
      if (profileMap == null) {
        return const Success<TruckerProfile?>(null);
      }

      final truckerMap = await _backend.fetchTruckerExtension(userId);
      final totalTrucks = await _backend.countTrucksByStatuses(userId, const <String>[]);
      final approvedTrucks = await _backend.countTrucksByStatuses(userId, const ['verified']);

      return Success<TruckerProfile?>(
        TruckerProfile.fromMaps(
          profileMap,
          truckerMap,
          totalTrucks: totalTrucks,
          approvedTrucks: approvedTrucks,
        ),
      );
    } catch (error, stackTrace) {
      return Failure<TruckerProfile?>(_mapError(error, stackTrace));
    }
  }

  Future<Result<void>> updateLicenceNumber(String? dlNumber) async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Failure<void>(UnauthorizedFailure());
    }

    try {
      await _backend.updateTruckerExtension(userId, {
        'dl_number': _nullableString(dlNumber?.trim()),
      });
      return const Success<void>(null);
    } catch (error, stackTrace) {
      return Failure<void>(_mapError(error, stackTrace));
    }
  }

  AppFailure _mapError(Object error, StackTrace stackTrace) =>
      mapSupabaseError(error, stackTrace);

  static String? _nullableString(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}

final truckerProfileRepositoryProvider = Provider<TruckerProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TruckerProfileRepository(
    SupabaseTruckerProfileBackend(client),
    () => client?.auth.currentUser?.id,
  );
});
