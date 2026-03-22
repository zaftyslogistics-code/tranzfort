import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';

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
      mobile: _nullableString(profileMap['mobile']),
      email: _nullableString(profileMap['email']),
      verificationStatus: (profileMap['verification_status'] ?? 'unverified').toString(),
      dlNumber: _nullableString(truckerMap?['dl_number']),
      rating: _readDouble(truckerMap?['rating']),
      totalTrips: _readInt(truckerMap?['total_trips']),
      completedTrips: _readInt(truckerMap?['completed_trips']),
      totalTrucks: totalTrucks,
      approvedTrucks: approvedTrucks,
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  static double _readDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse((value ?? '0').toString()) ?? 0;
  }

  static String? _nullableString(Object? value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    return raw;
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

    final response = await _client
        .from('profiles')
        .select('id, full_name, mobile, email, verification_status')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  @override
  Future<Map<String, dynamic>?> fetchTruckerExtension(String userId) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client
        .from('truckers')
        .select('id, dl_number, rating, total_trips, completed_trips')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }

  @override
  Future<int> countTrucksByStatuses(String userId, List<String> statuses) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    var query = _client.from('trucks').select('id').eq('owner_id', userId);
    if (statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    }

    final response = await query;
    return response.length;
  }

  @override
  Future<void> updateTruckerExtension(String userId, Map<String, dynamic> values) async {
    if (_client == null) {
      throw const AuthException('Trucker session is not available');
    }

    await _client.from('truckers').update(values).eq('id', userId);
  }
}

class TruckerProfileRepository {
  final TruckerProfileBackend _backend;
  final String? Function() _currentUserId;

  const TruckerProfileRepository(this._backend, this._currentUserId);

  Future<Result<TruckerProfile?>> fetchCurrentTruckerProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return const Success<TruckerProfile?>(null);
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
