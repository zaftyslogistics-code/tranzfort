import 'package:flutter/material.dart';

/// Star rating input widget for 1-5 star selection.
class StarRatingInput extends StatelessWidget {
  final int rating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final bool allowClear;

  const StarRatingInput({
    super.key,
    required this.rating,
    this.onRatingChanged,
    this.starSize = 40,
    this.allowClear = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating;

        return GestureDetector(
          onTap: onRatingChanged != null
              ? () {
                  // Allow clearing by tapping the same rating again
                  if (allowClear && rating == starIndex) {
                    onRatingChanged!(0);
                  } else {
                    onRatingChanged!(starIndex);
                  }
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: starSize,
              color: isFilled ? Colors.amber : Colors.grey,
            ),
          ),
        );
      }),
    );
  }
}

/// Display-only star rating widget.
class StarRatingDisplay extends StatelessWidget {
  final double rating;
  final double starSize;
  final int reviewCount;
  final bool showCount;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starSize = 16,
    this.reviewCount = 0,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            final isFilled = rating >= starValue;
            final isHalf = rating > index && rating < starValue;

            return Icon(
              isFilled
                  ? Icons.star
                  : isHalf
                      ? Icons.star_half
                      : Icons.star_border,
              size: starSize,
              color: isFilled || isHalf ? Colors.amber : Colors.grey,
            );
          }),
        ),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '(${rating.toStringAsFixed(1)})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (reviewCount > 0)
            Text(
              ' $reviewCount reviews',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}
