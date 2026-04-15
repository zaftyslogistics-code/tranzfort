import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/content_cards.dart';
import '../../../../shared/widgets/layout_components.dart';
import '../../data/review_models.dart';
import '../../data/review_repository.dart';
import 'star_rating_input.dart';

/// Bottom sheet to prompt user to review after interaction.
class ReviewPromptSheet extends ConsumerStatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String contextType;
  final String contextId;
  final VoidCallback? onReviewSubmitted;

  const ReviewPromptSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.contextType,
    required this.contextId,
    this.onReviewSubmitted,
  });

  /// Shows the review prompt sheet.
  static Future<void> show(
    BuildContext context, {
    required String targetUserId,
    required String targetUserName,
    required String contextType,
    required String contextId,
    VoidCallback? onReviewSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ReviewPromptSheet(
        targetUserId: targetUserId,
        targetUserName: targetUserName,
        contextType: contextType,
        contextId: contextId,
        onReviewSubmitted: onReviewSubmitted,
      ),
    );
  }

  @override
  ConsumerState<ReviewPromptSheet> createState() => _ReviewPromptSheetState();
}

class _ReviewPromptSheetState extends ConsumerState<ReviewPromptSheet> {
  int _rating = 0;
  String _comment = '';
  bool _isSubmitting = false;
  bool _submitted = false;

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) return;

    setState(() => _isSubmitting = true);

    final result = await ref.read(reviewRepositoryProvider).submitReview(
      reviewedUserId: widget.targetUserId,
      contextType: widget.contextType,
      contextId: widget.contextId,
      rating: _rating,
      comment: _comment.isEmpty ? null : _comment,
    );

    result.when(
      success: (_) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
        widget.onReviewSubmitted?.call();
      },
      failure: (failure) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
    );
  }

  void _skip() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _submitted ? _buildSuccessState(theme, colorScheme) : _buildFormState(theme, colorScheme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormState(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Title
        Text(
          'Rate Your Interaction',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'How was your experience with ${widget.targetUserName}?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Star rating
        Center(
          child: StarRatingInput(
            rating: _rating,
            onRatingChanged: (rating) => setState(() => _rating = rating),
            starSize: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Comment field
        TextField(
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Add a comment (optional)...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _comment = value,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Submit button
        PrimaryButton(
          label: 'Submit Review',
          onPressed: _rating > 0 ? _submit : null,
          isLoading: _isSubmitting,
        ),
        const SizedBox(height: AppSpacing.md),

        // Skip button
        OutlineButton(
          label: 'Skip',
          onPressed: _skip,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Review Submitted!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Thank you for sharing your experience.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          label: 'Done',
          onPressed: () => context.pop(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
