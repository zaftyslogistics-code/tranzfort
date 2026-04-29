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

    throw FormatException(
      'Unexpected RPC response type for get_public_profile: ${response.runtimeType}',
    );
  }

  @override
  Future<Map<String, dynamic>> getUserPublicLoads({
    required String userId,
    int limit = 5,
    int offset = 0,
    String? statusFilter,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc(
      'get_public_load_previews',
      params: <String, dynamic>{
        'p_supplier_id': userId,
        'p_limit': limit,
        'p_offset': offset,
        if (statusFilter != null && statusFilter.isNotEmpty)
          'p_status_filter': statusFilter,
      },
    );

    if (response is Map<String, dynamic>) {
      return response;
    }

    if (response is List && response.isNotEmpty && response.first is Map<String, dynamic>) {
      return response.first as Map<String, dynamic>;
    }

    throw FormatException(
      'Unexpected RPC response type for get_public_load_previews: ${response.runtimeType}',
    );
  }
}

/// Repository for public profile operations.
class PublicProfileRepository {
  final PublicProfileBackend _backend;

  const PublicProfileRepository(this._backend);

  /// Fetch public profile for any user.
  /// [viewerId] is the current user's ID; backend uses it to determine
  /// capability flags (canViewContact, canReview, canMessage).
  Future<Result<PublicProfile?>> getPublicProfile(String userId, {String? viewerId}) async {
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
        viewerId: viewerId?.trim(),
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
