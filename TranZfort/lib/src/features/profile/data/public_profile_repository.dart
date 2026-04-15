import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import 'public_profile_models.dart';

/// Backend interface for public profile operations.
abstract class PublicProfileBackend {
  Future<Map<String, dynamic>?> getPublicProfile({
    required String userId,
    String? viewerId,
  });

  Future<List<Map<String, dynamic>>> getUserPublicLoads({
    required String userId,
    int limit,
    int offset,
    String? statusFilter,
  });
}

/// Supabase implementation of public profile backend.
class SupabasePublicProfileBackend implements PublicProfileBackend {
  final SupabaseClient? _client;

  const SupabasePublicProfileBackend(this._client);

  @override
  Future<Map<String, dynamic>?> getPublicProfile({
    required String userId,
    String? viewerId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final params = <String, dynamic>{'p_user_id': userId};
    if (viewerId != null) {
      params['p_viewer_id'] = viewerId;
    }

    final response = await _client.rpc('get_public_profile', params: params);

    if (response is Map<String, dynamic>) {
      return response;
    }

    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getUserPublicLoads({
    required String userId,
    int limit = 5,
    int offset = 0,
    String? statusFilter,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    // Query loads for this supplier with public visibility
    var query = _client
        .from('loads')
        .select(
          'id, origin_city, destination_city, material, weight_tonnes, price_amount, price_type, pickup_date, status',
        )
        .eq('supplier_id', userId)
        .isFilter('parent_load_id', null);

    // Apply status filter if provided
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    } else {
      // Default: show active and completed loads
      query = query.inFilter('status', const ['active', 'completed', 'assigned_partial', 'assigned_full']);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return response.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}

/// Repository for public profile operations.
class PublicProfileRepository {
  final PublicProfileBackend _backend;

  const PublicProfileRepository(this._backend);

  /// Fetch public profile for any user.
  Future<Result<PublicProfile?>> getPublicProfile(String userId) async {
    if (userId.trim().isEmpty) {
      return const Failure<PublicProfile?>(
        ValidationFailure(
          message: 'User ID is required',
          fieldErrors: {'user_id': 'User ID is required'},
        ),
      );
    }

    try {
      final response = await _backend.getPublicProfile(
        userId: userId.trim(),
        viewerId: null,
      );

      if (response == null) {
        return const Failure<PublicProfile?>(NotFoundFailure());
      }

      return Success<PublicProfile?>(PublicProfile.fromMap(response));
    } catch (error, stackTrace) {
      return Failure<PublicProfile?>(mapSupabaseError(error, stackTrace));
    }
  }

  /// Get paginated public loads for a supplier profile.
  Future<Result<List<PublicLoadPreview>>> getUserPublicLoads({
    required String userId,
    int limit = 5,
    int offset = 0,
    String? statusFilter,
  }) async {
    if (userId.trim().isEmpty) {
      return const Failure<List<PublicLoadPreview>>(
        ValidationFailure(
          message: 'User ID is required',
          fieldErrors: {'user_id': 'User ID is required'},
        ),
      );
    }

    try {
      final rows = await _backend.getUserPublicLoads(
        userId: userId.trim(),
        limit: limit,
        offset: offset,
        statusFilter: statusFilter,
      );

      return Success<List<PublicLoadPreview>>(
        rows.map(PublicLoadPreview.fromMap).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<PublicLoadPreview>>(mapSupabaseError(error, stackTrace));
    }
  }
}

/// Provider for PublicProfileRepository.
final publicProfileRepositoryProvider = Provider<PublicProfileRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PublicProfileRepository(SupabasePublicProfileBackend(client));
});
