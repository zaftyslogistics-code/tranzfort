import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/reviews/data/review_models.dart';
import 'package:tranzfort/src/features/reviews/data/review_repository.dart';

class _FakeReviewBackend implements ReviewBackend {
  Map<String, dynamic> canReviewResponse = const <String, dynamic>{};
  Object? canReviewError;

  @override
  Future<bool> addReply({
    required String reviewId,
    required String reply,
  }) async {
    return true;
  }

  @override
  Future<Map<String, dynamic>> canReviewUser({
    required String targetUserId,
    String? contextType,
    String? contextId,
  }) async {
    if (canReviewError != null) {
      throw canReviewError!;
    }
    return canReviewResponse;
  }

  @override
  Future<List<Map<String, dynamic>>> getProfileReviews({
    required String userId,
    int limit = 5,
    int offset = 0,
  }) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<Map<String, dynamic>> submitReview({
    required String reviewedUserId,
    required String contextType,
    required String contextId,
    required int rating,
    String? comment,
  }) async {
    return const <String, dynamic>{'success': true};
  }
}

void main() {
  group('ReviewRepository.canReviewUser', () {
    test('maps self-review blocking response from backend', () async {
      final backend = _FakeReviewBackend()
        ..canReviewResponse = const <String, dynamic>{
          'can_review': false,
          'already_reviewed': false,
          'requires_interaction': false,
          'reason': 'Cannot review yourself',
        };
      final repository = ReviewRepository(backend);

      final result = await repository.canReviewUser(
        targetUserId: 'user-self',
        contextType: 'chat',
        contextId: 'chat-1',
      );

      expect(result, isA<Success<CanReviewStatus>>());
      final status = result.valueOrNull!;
      expect(status.canReview, false);
      expect(status.alreadyReviewed, false);
      expect(status.requiresInteraction, false);
      expect(status.reason, 'Cannot review yourself');
    });

    test('maps already-reviewed response from backend', () async {
      final backend = _FakeReviewBackend()
        ..canReviewResponse = const <String, dynamic>{
          'can_review': false,
          'already_reviewed': true,
          'requires_interaction': false,
          'reason': 'You have already reviewed this user',
        };
      final repository = ReviewRepository(backend);

      final result = await repository.canReviewUser(
        targetUserId: 'reviewed-user',
        contextType: 'trip_completed',
        contextId: 'trip-1',
      );

      expect(result, isA<Success<CanReviewStatus>>());
      final status = result.valueOrNull!;
      expect(status.canReview, false);
      expect(status.alreadyReviewed, true);
      expect(status.requiresInteraction, false);
      expect(status.reason, 'You have already reviewed this user');
    });

    test('maps interaction-required response from backend', () async {
      final backend = _FakeReviewBackend()
        ..canReviewResponse = const <String, dynamic>{
          'can_review': false,
          'already_reviewed': false,
          'requires_interaction': true,
          'reason': 'Interaction required before reviewing',
        };
      final repository = ReviewRepository(backend);

      final result = await repository.canReviewUser(
        targetUserId: 'target-user',
        contextType: 'load_closed',
        contextId: 'load-1',
      );

      expect(result, isA<Success<CanReviewStatus>>());
      final status = result.valueOrNull!;
      expect(status.canReview, false);
      expect(status.alreadyReviewed, false);
      expect(status.requiresInteraction, true);
      expect(status.reason, 'Interaction required before reviewing');
    });

    test('maps backend exceptions to AppFailure', () async {
      final backend = _FakeReviewBackend()
        ..canReviewError = const AuthException('Session unavailable');
      final repository = ReviewRepository(backend);

      final result = await repository.canReviewUser(
        targetUserId: 'target-user',
        contextType: 'chat',
        contextId: 'chat-1',
      );

      expect(result, isA<Failure<CanReviewStatus>>());
      expect(result.failureOrNull, isA<AppFailure>());
    });
  });
}
