import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String roleLabel;
  final bool verified;
  final String verifiedLabel;
  final String unverifiedLabel;
  final double? rating;
  final String? subtitle;
  final Widget? trailing;

  const ProfileCard({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.verified,
    required this.verifiedLabel,
    required this.unverifiedLabel,
    this.rating,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final stars = (rating ?? 0).clamp(0, 5).floor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.avatarLarge / 2,
            backgroundColor: AppColors.brandTealLight,
            child: Text(
              name.isEmpty ? 'T' : name[0].toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    _Badge(
                      label: roleLabel,
                      background: AppColors.brandTealLight,
                      foreground: AppColors.primary,
                    ),
                    _Badge(
                      label: verified ? verifiedLabel : unverifiedLabel,
                      background:
                          verified ? AppColors.successTint : AppColors.warningTint,
                      foreground:
                          verified ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                if (rating != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          size: AppSpacing.iconSm,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        rating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
