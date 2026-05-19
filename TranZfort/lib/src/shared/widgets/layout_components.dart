import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AppBottomSheet(
        title: title,
        child: child,
      );
    },
  );
}

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
        boxShadow: AppShadows.bottomSheet,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChipBar extends StatelessWidget {
  final List<FilterChipItem> items;
  final VoidCallback? onReset;

  const FilterChipBar({
    super.key,
    required this.items,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + (onReset == null ? 0 : 1),
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (onReset != null && index == items.length) {
            return ActionChip(
              label: Text(l10n.truckerFindLoadsResetFiltersAction),
              onPressed: onReset,
            );
          }

          final item = items[index];
          return FilterChip(
            label: Text(item.label),
            selected: item.selected,
            onSelected: (_) => item.onTap(),
          );
        },
      ),
    );
  }
}

class FilterChipItem {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class QuickActionGrid extends StatelessWidget {
  final List<QuickActionItem> items;

  const QuickActionGrid({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : (screenWidth > 400 ? 2 : 2);
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.md),
                    Text(item.label, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class QuickActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class TimelineBlock extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineBlock({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        color: AppColors.divider,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(event.timestamp, style: Theme.of(context).textTheme.bodySmall),
                      if (event.description != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(event.description!, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class TimelineEvent {
  final String title;
  final String timestamp;
  final String? description;

  const TimelineEvent({
    required this.title,
    required this.timestamp,
    this.description,
  });
}

// ─── Phase 18.3: Load Card Chip System ───

/// Load info chip with primary/secondary hierarchy for marketplace cards.
class LoadInfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final LoadChipLevel level;
  final Color? accentColor;

  const LoadInfoChip({
    super.key,
    this.icon,
    required this.label,
    this.level = LoadChipLevel.primary,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = accentColor ?? (level == LoadChipLevel.primary
        ? AppColors.textPrimary
        : AppColors.textSecondary);
    
    return Container(
      padding: level == LoadChipLevel.primary
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: level == LoadChipLevel.primary
            ? AppColors.surfaceSoft
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: level == LoadChipLevel.primary
            ? Border.all(color: AppColors.divider, width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: level == LoadChipLevel.primary ? 16 : 14,
              color: fg,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: level == LoadChipLevel.primary
                      ? FontWeight.w700
                      : FontWeight.w600,
                  fontSize: 12, // Minimum 12px for decision-critical content
                ),
          ),
        ],
      ),
    );
  }
}

enum LoadChipLevel {
  primary,
  secondary,
  status,
}

/// Responsive chip layout for load cards with automatic wrapping.
class LoadChipWrap extends StatelessWidget {
  final List<Widget> chips;
  final double spacing;
  final double runSpacing;

  const LoadChipWrap({
    super.key,
    required this.chips,
    this.spacing = AppSpacing.sm,
    this.runSpacing = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: chips,
    );
  }
}
