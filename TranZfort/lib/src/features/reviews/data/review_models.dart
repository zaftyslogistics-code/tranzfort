library;

/// Review models for the User Rating & Comments System.
/// Plain Dart classes with fromMap factories (NOT freezed).

class Review {
  final String id;
  final String reviewedUserId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerRole;
  final double? reviewerAvgRating;
  final int reviewerReviewCount;
  final String? reviewerLocation;
  final String? reviewerAvatarUrl;
  final DateTime? reviewerMemberSince;
  final String contextType;
  final String? contextId;
  final String? contextLabel;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? replyAt;
  final DateTime createdAt;
  final String? originCity;
  final String? destinationCity;

  const Review({
    required this.id,
    required this.reviewedUserId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerRole,
    required this.reviewerAvgRating,
    required this.reviewerReviewCount,
    required this.reviewerLocation,
    this.reviewerAvatarUrl,
    required this.reviewerMemberSince,
    required this.contextType,
    required this.contextId,
    this.contextLabel,
    required this.rating,
    required this.comment,
    required this.reply,
    required this.replyAt,
    required this.createdAt,
    this.originCity,
    this.destinationCity,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: (map['id'] ?? '').toString(),
      reviewedUserId: (map['reviewed_user_id'] ?? '').toString(),
      reviewerId: (map['reviewer_id'] ?? '').toString(),
      reviewerName: (map['reviewer_name'] ?? '').toString(),
      reviewerRole: (map['reviewer_role'] ?? '').toString(),
      reviewerAvgRating: _readDoubleNullable(map['reviewer_avg_rating']),
      reviewerReviewCount: _readInt(map['reviewer_review_count']),
      reviewerLocation: _nullableString(map['reviewer_location']),
      reviewerAvatarUrl: _nullableString(map['reviewer_avatar_url']),
      reviewerMemberSince: _readDateTime(map['reviewer_member_since']),
      contextType: (map['context_type'] ?? '').toString(),
      contextId: map['context_id']?.toString(),
      contextLabel: _nullableString(map['context_label']),
      rating: _readInt(map['rating']),
      comment: _nullableString(map['comment']),
      reply: _nullableString(map['reply']),
      replyAt: _readDateTime(map['reply_at']),
      createdAt: _readDateTime(map['created_at']) ?? DateTime.now(),
      originCity: _nullableString(map['origin_city']),
      destinationCity: _nullableString(map['destination_city']),
    );
  }

  /// Whether this review has a reply from the reviewed user.
  bool get hasReply => reply != null && reply!.isNotEmpty;

  /// Formatted time ago string for display.
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class CanReviewStatus {
  final bool canReview;
  final bool alreadyReviewed;
  final bool requiresInteraction;
  final String? reason;

  const CanReviewStatus({
    required this.canReview,
    required this.alreadyReviewed,
    required this.requiresInteraction,
    this.reason,
  });

  factory CanReviewStatus.fromMap(Map<String, dynamic> map) {
    return CanReviewStatus(
      canReview: map['can_review'] == true,
      alreadyReviewed: map['already_reviewed'] == true,
      requiresInteraction: map['requires_interaction'] == true,
      reason: _nullableString(map['reason']),
    );
  }
}

/// Submit review request DTO.
class SubmitReviewRequest {
  final String reviewedUserId;
  final String contextType;
  final String contextId;
  final int rating;
  final String? comment;

  const SubmitReviewRequest({
    required this.reviewedUserId,
    required this.contextType,
    required this.contextId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toRpcParams() {
    return {
      'p_reviewed_user_id': reviewedUserId,
      'p_context_type': contextType,
      'p_context_id': contextId,
      'p_rating': rating,
      'p_comment': comment,
    };
  }
}

/// Add reply request DTO.
class AddReplyRequest {
  final String reviewId;
  final String reply;

  const AddReplyRequest({
    required this.reviewId,
    required this.reply,
  });

  Map<String, dynamic> toRpcParams() {
    return {
      'p_review_id': reviewId,
      'p_reply': reply,
    };
  }
}

/// Pagination parameters for reviews.
class ReviewPaginationParams {
  final int limit;
  final int offset;

  const ReviewPaginationParams({
    this.limit = 5,
    this.offset = 0,
  });

  ReviewPaginationParams nextPage() {
    return ReviewPaginationParams(
      limit: limit,
      offset: offset + limit,
    );
  }
}

// Private helper functions

String? _nullableString(Object? value) {
  final raw = (value ?? '').toString().trim();
  return raw.isEmpty ? null : raw;
}

double? _readDoubleNullable(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int _readInt(Object? value) {
  if (value is int) return value;
  return int.tryParse((value ?? '0').toString()) ?? 0;
}

DateTime? _readDateTime(Object? value) {
  final raw = _nullableString(value);
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}
