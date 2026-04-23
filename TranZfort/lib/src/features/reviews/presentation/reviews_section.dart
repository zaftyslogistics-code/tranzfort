import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../data/review_models.dart';
import '../data/review_repository.dart';
import 'widgets/reply_dialog.dart';
import 'widgets/review_card.dart';
import 'widgets/star_rating_input.dart';

/// Reviews section for profile screens with pagination.
class ReviewsSection extends ConsumerStatefulWidget {
  final String userId;
  final bool showTitle;
  final double? summaryAvgRating;
  final int? summaryReviewCount;

  const ReviewsSection({
    super.key,
    required this.userId,
    this.showTitle = true,
    this.summaryAvgRating,
    this.summaryReviewCount,
  });

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  final List<Review> _reviews = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  double _avgRating = 0;
  AppFailure? _loadFailure;

  static const int _initialLimit = 3;
  static const int _batchSize = 5;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void didUpdateWidget(ReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _reviews.clear();
      _offset = 0;
      _hasMore = true;
      _loadInitial();
    }
  }

  Future<void> _loadInitial() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadFailure = null;
    });

    final result = await ref.read(reviewRepositoryProvider).getAllUserFeedback(
      userId: widget.userId,
      limit: _initialLimit,
      offset: 0,
    );

    result.when(
      success: (reviews) {
        setState(() {
          _reviews
            ..clear()
            ..addAll(reviews);
          _offset = reviews.length;
          _hasMore = reviews.length == _initialLimit;
          _isLoading = false;
          _loadFailure = null;
          _calculateAvgRating();
        });
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _loadFailure = failure;
        });
      },
    );
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _loadFailure = null;
    });

    final result = await ref.read(reviewRepositoryProvider).getAllUserFeedback(
      userId: widget.userId,
      limit: _batchSize,
      offset: _offset,
    );

    result.when(
      success: (reviews) {
        setState(() {
          _reviews.addAll(reviews);
          _offset += reviews.length;
          _hasMore = reviews.length == _batchSize;
          _isLoading = false;
          _loadFailure = null;
        });
      },
      failure: (failure) {
        setState(() {
          _isLoading = false;
          _loadFailure = failure;
        });
      },
    );
  }

  void _calculateAvgRating() {
    if (_reviews.isEmpty) {
      _avgRating = 0;
      return;
    }
    final total = _reviews.fold<int>(0, (sum, r) => sum + r.rating);
    _avgRating = total / _reviews.length;
  }

  Future<void> _handleReply(Review review) async {
    final reply = await ReplyDialog.show(
      context,
      reviewerName: review.reviewerName,
    );

    if (reply != null && reply.isNotEmpty) {
      final result = await ref.read(reviewRepositoryProvider).addReply(
        reviewId: review.id,
        reply: reply,
      );

      result.when(
        success: (_) {
          // Refresh reviews to show the new reply
          _reviews.clear();
          _offset = 0;
          _hasMore = true;
          _loadInitial();
        },
        failure: (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          }
        },
      );
    }
  }

  void _navigateToReviewerProfile(String reviewerId) {
    // Navigate to public profile
    context.push(AppRoutes.publicProfileLocation(reviewerId));
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = ref.watch(currentProfileProvider).valueOrNull;
    final currentUserId = currentProfile?.id;
    final isOwner = currentUserId == widget.userId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle)
          _buildHeader(context),
        if (_loadFailure != null && _reviews.isEmpty && !_isLoading)
          _buildErrorState(context)
        else if (_reviews.isEmpty && !_isLoading)
          _buildEmptyState(context)
        else
          _buildReviewsList(context, isOwner),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasSummaryOverride = widget.summaryReviewCount != null;
    final displayedReviewCount = widget.summaryReviewCount ?? _reviews.length;
    final displayedAvgRating = hasSummaryOverride
        ? (widget.summaryAvgRating ?? 0)
        : _avgRating;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.reviewsTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_reviews.isNotEmpty || displayedReviewCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                StarRatingDisplay(
                  rating: displayedAvgRating,
                  starSize: 20,
                  showCount: false,
                ),
                const SizedBox(width: 8),
                Text(
                  '${displayedAvgRating.toStringAsFixed(1)} ${l10n.reviewsAverage}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '($displayedReviewCount ${l10n.reviewsTotal})',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.reviewsUnableToLoad,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadFailure?.message ?? l10n.reviewsRetryMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _loadInitial,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.loadHistoryRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.reviewsNoReviewsYet,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reviewsWillAppearHere,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsList(BuildContext context, bool isOwner) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            final review = _reviews[index];
            return ReviewCard(
              review: review,
              canAddReply: isOwner && !review.hasReply,
              onReplyTap: () => _handleReply(review),
              onReviewerTap: () => _navigateToReviewerProfile(review.reviewerId),
            );
          },
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          )
        else if (_hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more),
              label: Text(l10n.reviewsLoadMore),
            ),
          ),
      ],
    );
  }
}
