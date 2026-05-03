import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/supabase_error_mapper.dart';
import '../../../core/error/result.dart';
import '../../../core/providers/app_state_providers.dart';
import 'review_models.dart';

// R-004: Error codes for localization (UI should map these to AppLocalizations)
class ReviewErrorCodes {
  static const String validationFailed = 'review.validation_failed';
  static const String submitFailed = 'review.submit_failed';
  static const String addReplyFailed = 'review.add_reply_failed';
}

/// Backend interface for review operations.
abstract class ReviewBackend {
  Future<Map<String, dynamic>> submitReview({
    required String reviewedUserId,
    required String contextType,
    required String contextId,
    required int rating,
    String? comment,
  });

  Future<bool> addReply({
    required String reviewId,
    required String reply,
  });

  Future<List<Map<String, dynamic>>> getProfileReviews({
    required String userId,
    int limit,
    int offset,
  });

  Future<List<Map<String, dynamic>>> getAllUserFeedback({
    required String userId,
    int limit,
    int offset,
  });

  Future<Map<String, dynamic>> canReviewUser({
    required String targetUserId,
    String? contextType,
    String? contextId,
  });
}

/// Supabase implementation of review backend.
class SupabaseReviewBackend implements ReviewBackend {
  final SupabaseClient? _client;

  const SupabaseReviewBackend(this._client);

  @override
  Future<Map<String, dynamic>> submitReview({
    required String reviewedUserId,
    required String contextType,
    required String contextId,
    required int rating,
    String? comment,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc('submit_review', params: {
      'p_reviewed_user_id': reviewedUserId,
      'p_context_type': contextType,
      'p_context_id': contextId,
      'p_rating': rating,
      'p_comment': comment,
    });

    return response is Map<String, dynamic>
        ? response
        : {'success': false, 'error': 'Invalid response format'};
  }

  @override
  Future<bool> addReply({
    required String reviewId,
    required String reply,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc('add_reply_to_review', params: {
      'p_review_id': reviewId,
      'p_reply': reply,
    });

    return response == true;
  }

  @override
  Future<List<Map<String, dynamic>>> getProfileReviews({
    required String userId,
    int limit = 5,
    int offset = 0,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc('get_profile_reviews', params: {
      'p_user_id': userId,
      'p_limit': limit,
      'p_offset': offset,
    });

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    throw FormatException('Unexpected RPC response type: ${response.runtimeType}');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllUserFeedback({
    required String userId,
    int limit = 10,
    int offset = 0,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc('get_all_user_feedback', params: {
      'p_user_id': userId,
      'p_limit': limit,
      'p_offset': offset,
    });

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    throw FormatException('Unexpected RPC response type: ${response.runtimeType}');
  }

  @override
  Future<Map<String, dynamic>> canReviewUser({
    required String targetUserId,
    String? contextType,
    String? contextId,
  }) async {
    if (_client == null) {
      throw const AuthException('Session unavailable');
    }

    final response = await _client.rpc('can_review_user', params: {
      'p_target_user_id': targetUserId,
      'p_context_type': contextType,
      'p_context_id': contextId,
    });

    return response is Map<String, dynamic>
        ? response
        : {'can_review': false, 'already_reviewed': false, 'requires_interaction': true};
  }
}

/// Repository for review operations.
class ReviewRepository {
  final ReviewBackend _backend;

  const ReviewRepository(this._backend);

  /// Submit a review for another user.
  Future<Result<String?>> submitReview({
    required String reviewedUserId,
    required String contextType,
    required String contextId,
    required int rating,
    String? comment,
  }) async {
    final fieldErrors = <String, String>{};
    if (rating < 1 || rating > 5) {
      fieldErrors['rating'] = 'Rating must be between 1 and 5.';
    }
    if (contextId.trim().isEmpty) {
      fieldErrors['context_id'] = 'Context ID is required.';
    }
    final trimmedComment = comment?.trim();
    if (trimmedComment != null && trimmedComment.length > 500) {
      fieldErrors['comment'] = 'Comment must not exceed 500 characters.';
    }
    if (fieldErrors.isNotEmpty) {
      return Failure<String?>(
        ValidationFailure(
          // TODO: Map to ReviewErrorCodes.validationFailed in UI layer
          message: 'Please correct the review details.',
          fieldErrors: fieldErrors,
        ),
      );
    }

    try {
      final response = await _backend.submitReview(
        reviewedUserId: reviewedUserId,
        contextType: contextType,
        contextId: contextId,
        rating: rating,
        comment: trimmedComment,
      );

      if (response['success'] == true) {
        return Success<String?>(response['review_id']?.toString());
      }

      return Failure<String?>(
        ValidationFailure(
          // TODO: Map to ReviewErrorCodes.submitFailed in UI layer
          message: response['error']?.toString() ?? 'Failed to submit review',
        ),
      );
    } catch (error, stackTrace) {
      return Failure<String?>(mapSupabaseError(error, stackTrace));
    }
  }

  /// Add a one-time reply to a review.
  Future<Result<bool>> addReply({
    required String reviewId,
    required String reply,
  }) async {
    try {
      final success = await _backend.addReply(
        reviewId: reviewId,
        reply: reply,
      );

      if (success) {
        return const Success<bool>(true);
      }

      return const Failure<bool>(
        ValidationFailure(
          // TODO: Map to ReviewErrorCodes.addReplyFailed in UI layer
          message: 'Failed to add reply. You may have already replied or are not the reviewed user.',
        ),
      );
    } catch (error, stackTrace) {
      return Failure<bool>(mapSupabaseError(error, stackTrace));
    }
  }

  /// Get paginated reviews for a user profile.
  Future<Result<List<Review>>> getProfileReviews({
    required String userId,
    int limit = 5,
    int offset = 0,
  }) async {
    try {
      final rows = await _backend.getProfileReviews(
        userId: userId,
        limit: limit,
        offset: offset,
      );

      return Success<List<Review>>(
        rows.map(Review.fromMap).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<Review>>(mapSupabaseError(error, stackTrace));
    }
  }

  /// Get all user feedback (unified view combining ratings and reviews).
  Future<Result<List<Review>>> getAllUserFeedback({
    required String userId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final rows = await _backend.getAllUserFeedback(
        userId: userId,
        limit: limit,
        offset: offset,
      );

      return Success<List<Review>>(
        rows.map(Review.fromMap).toList(growable: false),
      );
    } catch (error, stackTrace) {
      return Failure<List<Review>>(mapSupabaseError(error, stackTrace));
    }
  }

  /// Check if current user can review a target user.
  Future<Result<CanReviewStatus>> canReviewUser({
    required String targetUserId,
    String? contextType,
    String? contextId,
  }) async {
    try {
      final response = await _backend.canReviewUser(
        targetUserId: targetUserId,
        contextType: contextType,
        contextId: contextId,
      );

      return Success<CanReviewStatus>(CanReviewStatus.fromMap(response));
    } catch (error, stackTrace) {
      return Failure<CanReviewStatus>(mapSupabaseError(error, stackTrace));
    }
  }
}

/// Provider for ReviewRepository.
final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReviewRepository(SupabaseReviewBackend(client));
});
