import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class LifecycleTimeline extends StatelessWidget {
  final List<String> stages;
  final int currentStageIndex;
  final List<String> stageLabels;
  final List<IconData> stageIcons;

  const LifecycleTimeline({
    super.key,
    required this.stages,
    required this.currentStageIndex,
    required this.stageLabels,
    required this.stageIcons,
  });

  @override
  Widget build(BuildContext context) {
    final count = [stages.length, stageLabels.length, stageIcons.length].reduce(
      (a, b) => a < b ? a : b,
    );
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(count, (index) {
            final isDone = currentStageIndex >= 0 && index < currentStageIndex;
            final isCurrent = currentStageIndex == index;
            final isFuture = index > currentStageIndex || currentStageIndex < 0;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StageDot(
                      icon: stageIcons[index],
                      isDone: isDone,
                      isCurrent: isCurrent,
                      isFuture: isFuture,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SizedBox(
                      width: 72,
                      child: Text(
                        stageLabels[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDone || isCurrent
                              ? AppColors.onSurface
                              : AppColors.textSecondary,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (index < count - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      width: 22,
                      height: 2,
                      color: currentStageIndex > index
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isFuture;

  const _StageDot({
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isFuture,
  });

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }

    if (isCurrent) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.92, end: 1.08),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
        ),
        onEnd: () {},
      );
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isFuture ? AppColors.background : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textTertiary, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 16, color: AppColors.textTertiary),
    );
  }
}
