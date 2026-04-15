import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_failure.dart';
import '../data/review_models.dart';
import '../data/review_repository.dart';

/// Provider for reviews list for a profile (initial fetch only).
final profileReviewsProvider = FutureProvider.family<List<Review>, String>((ref, userId) async {
  final result = await ref.watch(reviewRepositoryProvider).getProfileReviews(
    userId: userId,
    limit: 5,
    offset: 0,
  );
  
  return result.when(
    success: (value) => value,
    failure: (failure) => throw failure,
  );
});

/// Provider for checking if user can review another user.
final canReviewProvider = FutureProvider.family<CanReviewStatus, CanReviewParams>((ref, params) async {
  final result = await ref.watch(reviewRepositoryProvider).canReviewUser(
    targetUserId: params.targetUserId,
    contextType: params.contextType,
    contextId: params.contextId,
  );
  
  return result.when(
    success: (value) => value,
    failure: (failure) => CanReviewStatus(
      canReview: false,
      alreadyReviewed: false,
      requiresInteraction: true,
      reason: failure.message,
    ),
  );
});

/// Parameter class for canReviewProvider.
class CanReviewParams {
  final String targetUserId;
  final String? contextType;
  final String? contextId;

  const CanReviewParams({
    required this.targetUserId,
    this.contextType,
    this.contextId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanReviewParams &&
          runtimeType == other.runtimeType &&
          targetUserId == other.targetUserId &&
          contextType == other.contextType &&
          contextId == other.contextId;

  @override
  int get hashCode => targetUserId.hashCode ^ contextType.hashCode ^ contextId.hashCode;
}

/// Helper to extract failure from AsyncValue.
AppFailure? reviewAsyncFailure(AsyncValue<Object?> value) {
  final error = value.asError?.error;
  if (error is AppFailure) return error;
  return null;
}
