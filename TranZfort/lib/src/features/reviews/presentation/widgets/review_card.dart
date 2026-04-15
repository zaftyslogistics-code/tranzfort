import 'package:flutter/material.dart';
import '../../data/review_models.dart';
import 'reviewer_mini_card.dart';
import 'star_rating_input.dart';

/// Single review card with visible reviewer identity.
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool canAddReply;
  final VoidCallback? onReplyTap;
  final VoidCallback? onReviewerTap;

  const ReviewCard({
    super.key,
    required this.review,
    this.canAddReply = false,
    this.onReplyTap,
    this.onReviewerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Star rating
            StarRatingDisplay(
              rating: review.rating.toDouble(),
              starSize: 20,
              showCount: false,
            ),
            const SizedBox(height: 12),

            // Context label (if available)
            if (review.contextLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getContextIcon(review.contextType),
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      review.contextLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Route info (for trip ratings)
            if (review.originCity != null && review.destinationCity != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.route,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${review.originCity} → ${review.destinationCity}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Comment text
            if (review.comment != null && review.comment!.isNotEmpty)
              Text(
                review.comment!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),

            // Reply section (if exists)
            if (review.hasReply) ...[
              const SizedBox(height: 12),
              _buildReplySection(context),
            ],

            // Reply button (if can add reply and no reply exists)
            if (canAddReply && !review.hasReply) ...[
              const SizedBox(height: 12),
              _buildReplyButton(context),
            ],

            const SizedBox(height: 16),

            // Reviewer mini-card
            ReviewerMiniCard(
              review: review,
              onTap: onReviewerTap,
            ),

            const SizedBox(height: 8),

            // Timestamp
            Text(
              review.timeAgo,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplySection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Reply',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.reply!,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
          if (review.replyAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatReplyTime(review.replyAt!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OutlinedButton.icon(
      onPressed: onReplyTap,
      icon: Icon(
        Icons.reply,
        size: 18,
        color: colorScheme.primary,
      ),
      label: Text(
        'Reply to this review',
        style: TextStyle(color: colorScheme.primary),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _formatReplyTime(DateTime replyAt) {
    final now = DateTime.now();
    final diff = now.difference(replyAt);

    if (diff.inDays > 365) {
      return 'Replied ${(diff.inDays / 365).floor()}y ago';
    } else if (diff.inDays > 30) {
      return 'Replied ${(diff.inDays / 30).floor()}mo ago';
    } else if (diff.inDays > 0) {
      return 'Replied ${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return 'Replied ${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return 'Replied ${diff.inMinutes}m ago';
    } else {
      return 'Replied just now';
    }
  }

  IconData _getContextIcon(String? contextType) {
    switch (contextType) {
      case 'trip_completed':
        return Icons.check_circle_outline;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'load_closed':
        return Icons.inventory_2_outlined;
      default:
        return Icons.star_outline;
    }
  }
}
