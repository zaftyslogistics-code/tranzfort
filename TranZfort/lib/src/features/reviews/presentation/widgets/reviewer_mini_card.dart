import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/review_models.dart';
import 'star_rating_input.dart';

/// Clickable reviewer mini-card for review cards.
class ReviewerMiniCard extends ConsumerWidget {
  final Review review;
  final VoidCallback? onTap;

  const ReviewerMiniCard({
    super.key,
    required this.review,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.publicProfileLocation(review.reviewerId)),
              borderRadius: BorderRadius.circular(20),
              child: UserAvatar(
                avatarUrl: review.reviewerAvatarUrl,
                userId: review.reviewerId,
                initials: _getInitials(),
                radius: 20,
                fallbackColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.reviewerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  _buildReviewerInfo(context),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewerInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<Widget> children = [];

    // Rating display
    if (review.reviewerReviewCount > 0) {
      children.add(
        StarRatingDisplay(
          rating: review.reviewerAvgRating ?? 0,
          starSize: 12,
          reviewCount: review.reviewerReviewCount,
          showCount: false,
        ),
      );
    } else {
      children.add(
        Text(
          'No rating yet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Location if available
    if (review.reviewerLocation != null) {
      children.add(const SizedBox(width: 8));
      children.add(
        Text(
          '•',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
      children.add(const SizedBox(width: 4));
      children.add(
        Expanded(
          child: Text(
            review.reviewerLocation!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return Row(
      children: children,
    );
  }

  String _getInitials() {
    final name = review.reviewerName;
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
