import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/load_listing_duration.dart';

/// Listing duration selector for post-load (P1-LOAD Phase B).
class PostLoadListingSection extends StatelessWidget {
  final LoadListingDuration selectedDuration;
  final ValueChanged<LoadListingDuration> onDurationChanged;

  const PostLoadListingSection({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.postLoadListingDurationLabel,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _DurationChip(
              label: l10n.postLoadListingDuration48h,
              selected: selectedDuration == LoadListingDuration.hours48,
              onTap: () => onDurationChanged(LoadListingDuration.hours48),
            ),
            _DurationChip(
              label: l10n.postLoadListingDuration7d,
              selected: selectedDuration == LoadListingDuration.days7,
              onTap: () => onDurationChanged(LoadListingDuration.days7),
            ),
            _DurationChip(
              label: l10n.postLoadListingDuration30d,
              selected: selectedDuration == LoadListingDuration.days30,
              onTap: () => onDurationChanged(LoadListingDuration.days30),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.postLoadListingDurationHelper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.inkTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
    );
  }
}
