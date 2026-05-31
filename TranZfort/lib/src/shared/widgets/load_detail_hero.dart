import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'content_cards.dart';
import 'tts_card_speaker_button.dart';

/// Shared load-detail hero (supplier + trucker) — ink gradient, route title, badges, facts.
class LoadDetailHero extends StatelessWidget {
  final String routeLine;
  final String subtitle;
  final String? eyebrowLabel;
  final IconData titleIcon;
  final List<Widget> badges;
  final Widget? factsLine;
  final String? ttsMessage;

  /// When true, wraps content in [HeroActionCard] (supplier detail layout).
  final bool wrapInHeroActionCard;

  /// Header + badges only (no ink shell) — for trucker detail inner column.
  final bool headerOnly;

  const LoadDetailHero({
    super.key,
    required this.routeLine,
    required this.subtitle,
    this.eyebrowLabel,
    this.titleIcon = Icons.local_shipping_outlined,
    this.badges = const [],
    this.factsLine,
    this.ttsMessage,
    this.wrapInHeroActionCard = false,
    this.headerOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final header = _InkHeroHeader(
      routeLine: routeLine,
      subtitle: subtitle,
      eyebrowLabel: eyebrowLabel,
      titleIcon: titleIcon,
      badges: badges,
      ttsMessage: ttsMessage,
    );

    if (headerOnly) {
      return header;
    }

    final body = _InkHeroBody(
      header: header,
      factsLine: factsLine,
    );

    if (!wrapInHeroActionCard) {
      return body;
    }

    return HeroActionCard(
      title: routeLine,
      subtitle: subtitle,
      useDarkTheme: true,
      useInkGradient: true,
      titleIcon: titleIcon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badges.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: badges,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (factsLine != null) factsLine!,
        ],
      ),
    );
  }
}

class _InkHeroHeader extends StatelessWidget {
  final String routeLine;
  final String subtitle;
  final String? eyebrowLabel;
  final IconData titleIcon;
  final List<Widget> badges;
  final String? ttsMessage;

  const _InkHeroHeader({
    required this.routeLine,
    required this.subtitle,
    this.eyebrowLabel,
    required this.titleIcon,
    required this.badges,
    this.ttsMessage,
  });

  @override
  Widget build(BuildContext context) {
    final label = (eyebrowLabel ?? '').trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryOnDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.iconChip),
              ),
              child: Icon(titleIcon, color: AppColors.primaryOnDark, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: AppTypography.labelMicro.copyWith(
                        color: AppColors.primaryOnDark,
                        letterSpacing: 1.3,
                      ),
                    ),
                  if (label.isNotEmpty) const SizedBox(height: 2),
                  Text(
                    routeLine,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.inkTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkTextSecondary,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if ((ttsMessage ?? '').trim().isNotEmpty)
              TtsCardSpeakerButton(message: ttsMessage!.trim()),
          ],
        ),
        if (badges.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: badges,
          ),
        ],
      ],
    );
  }
}

class _InkHeroBody extends StatelessWidget {
  final Widget header;
  final Widget? factsLine;

  const _InkHeroBody({
    required this.header,
    this.factsLine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.inkSurface, AppColors.inkMid, AppColors.inkDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.hero),
        boxShadow: AppShadows.elevation3,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          if (factsLine != null) ...[
            const SizedBox(height: AppSpacing.md),
            factsLine!,
          ],
        ],
      ),
    );
  }
}
