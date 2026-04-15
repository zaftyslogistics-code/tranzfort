import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/reviews/data/review_models.dart';

void main() {
  group('Review Model', () {
    test('Review.fromMap parses correctly', () {
      final map = {
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'reviewed_user_id': '123e4567-e89b-12d3-a456-426614174001',
        'reviewer_id': '123e4567-e89b-12d3-a456-426614174002',
        'reviewer_name': 'John Doe',
        'reviewer_role': 'trucker',
        'reviewer_avg_rating': 4.5,
        'reviewer_review_count': 10,
        'reviewer_location': 'Mumbai',
        'reviewer_member_since': '2024-01-01T00:00:00Z',
        'context_type': 'chat',
        'context_id': '123e4567-e89b-12d3-a456-426614174003',
        'rating': 5,
        'comment': 'Great experience!',
        'reply': null,
        'reply_at': null,
        'created_at': '2024-04-11T10:00:00Z',
      };

      final review = Review.fromMap(map);

      expect(review.id, '123e4567-e89b-12d3-a456-426614174000');
      expect(review.rating, 5);
      expect(review.comment, 'Great experience!');
      expect(review.hasReply, false);
    });

    test('Review.timeAgo returns correct format', () {
      final review = Review(
        id: '1',
        reviewedUserId: '2',
        reviewerId: '3',
        reviewerName: 'Test',
        reviewerRole: 'trucker',
        reviewerAvgRating: 4.0,
        reviewerReviewCount: 5,
        reviewerLocation: null,
        reviewerMemberSince: null,
        contextType: 'chat',
        contextId: null,
        rating: 5,
        comment: null,
        reply: null,
        replyAt: null,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(review.timeAgo, '2h ago');
    });
  });

  group('CanReviewStatus', () {
    test('CanReviewStatus.fromMap parses correctly', () {
      final map = {
        'can_review': true,
        'already_reviewed': false,
        'requires_interaction': true,
        'reason': null,
      };

      final status = CanReviewStatus.fromMap(map);

      expect(status.canReview, true);
      expect(status.alreadyReviewed, false);
      expect(status.requiresInteraction, true);
    });
  });

  group('SubmitReviewRequest', () {
    test('toRpcParams returns correct format', () {
      final request = SubmitReviewRequest(
        reviewedUserId: 'user-123',
        contextType: 'chat',
        contextId: 'chat-456',
        rating: 5,
        comment: 'Great!',
      );

      final params = request.toRpcParams();

      expect(params['p_reviewed_user_id'], 'user-123');
      expect(params['p_rating'], 5);
      expect(params['p_comment'], 'Great!');
    });
  });
}
