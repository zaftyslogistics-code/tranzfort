import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'tts_card_speaker_button.dart';

class HeroActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget child;
  final Widget? primaryAction;
  final bool compact;
  final bool useDarkTheme; // Phase 4: use dark radial mesh
  final bool useInkGradient; // Load-detail style ink gradient (earnings card)
  final IconData? titleIcon;

  const HeroActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.primaryAction,
    this.compact = false,
    this.useDarkTheme = false,
    this.useInkGradient = false,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle.trim().isNotEmpty;

    if (useDarkTheme) {
      if (useInkGradient) {
        return Container(
          padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
          decoration: AppDecorations.inkHeroCard(),
          child: Column(
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
                    child: Icon(
                      titleIcon ?? Icons.search_outlined,
                      color: AppColors.primaryOnDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: AppTypography.labelMicro.copyWith(
                            color: AppColors.primaryOnDark,
                            letterSpacing: 1.3,
                          ),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(height: 2),
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
                ],
              ),
              if (leading != null) ...[
                const SizedBox(height: AppSpacing.md),
                leading!,
              ],
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
              child,
              if (primaryAction != null) ...[
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                primaryAction!,
              ],
            ],
          ),
        );
      }

      // Phase 4 Dark Hero (radial mesh)
      return Container(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.inkSurface,
          borderRadius: BorderRadius.circular(AppRadius.hero),
          boxShadow: AppShadows.elevation3,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.hero),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.heroDark,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.hero),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.heroDarkGlow,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                ],
                Text(
                  title,
                  style: (compact ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.titleLarge)?.copyWith(
                        color: AppColors.inkTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (hasSubtitle) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkTextSecondary,
                        ),
                  ),
                ],
                SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                child,
                if (primaryAction != null) ...[
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                  primaryAction!,
                ],
              ],
            ),
          ],
        ),
      );
    }

    // Original light hero (backward compatibility)
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardWash,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.hero,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
          ],
          Text(title, style: compact ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.titleLarge),
          if (hasSubtitle) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
          SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
          child,
          if (primaryAction != null) ...[
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            primaryAction!,
          ],
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final String? helperText;
  final String? delta; // e.g., "+12%"

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
    this.helperText,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: AppShadows.elevation2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: AppTypography.labelMicro.copyWith(
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (delta != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          delta!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  value,
                  style: AppTypography.displayHero.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (helperText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helperText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
          ),
          // Gradient wash at bottom (8% alpha)
          Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.card),
                bottomRight: Radius.circular(AppRadius.card),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.08),
                  accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StandardListCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String subtitle;
  final Widget? leading; // Legacy: custom leading widget
  final IconData? leadingIcon; // Phase 4: icon for LeadingIconChip
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final bool useLegacyStyle; // Phase 4: false = new LeadingIconChip, true = old 4px bar

  const StandardListCard({
    super.key,
    required this.accent,
    required this.title,
    required this.subtitle,
    this.leading,
    this.leadingIcon,
    this.trailing,
    this.footer,
    this.onTap,
    this.useLegacyStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    // If legacy leading widget is provided, use legacy style
    if (leading != null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
          border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.card),
                        bottomLeft: Radius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (leading != null) ...[
                            leading!,
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: AppSpacing.md),
                            trailing!,
                          ],
                        ],
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If useLegacyStyle is explicitly true
    if (useLegacyStyle) {
      // Legacy style with 4px left bar (backward compatibility)
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
          border: Border.all(
            color: AppColors.primaryDark.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.card),
                        bottomLeft: Radius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (trailing != null) ...[
                            const SizedBox(width: AppSpacing.md),
                            trailing!,
                          ],
                        ],
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Phase 4: LeadingIconChip style
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBase,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.elevation2,
        border: Border.all(
          color: AppColors.primaryDark.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leadingIcon != null)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.iconChip),
                        ),
                        child: Icon(
                          leadingIcon,
                          color: accent,
                          size: 24,
                        ),
                      ),
                    if (leadingIcon != null) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      trailing!,
                    ],
                  ],
                ),
                if (footer != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DetailSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? ttsMessage;
  final bool useInkGradient;
  final IconData? sectionIcon;

  const DetailSectionCard({
    super.key,
    required this.title,
    required this.children,
    this.ttsMessage,
    this.useInkGradient = false,
    this.sectionIcon,
  });

  @override
  Widget build(BuildContext context) {
    final spokenMessage = ttsMessage?.trim();

    if (useInkGradient) {
      return Container(
        width: double.infinity,
        decoration: AppDecorations.inkHeroCard(
          borderRadius: BorderRadius.circular(AppRadius.hero),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sectionIcon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOnDark.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.iconChip),
                    ),
                    child: Icon(
                      sectionIcon,
                      color: AppColors.primaryOnDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.primaryOnDark,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                if (spokenMessage != null && spokenMessage.isNotEmpty)
                  TtsCardSpeakerButton(message: spokenMessage),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (spokenMessage != null && spokenMessage.isNotEmpty)
                  TtsCardSpeakerButton(message: spokenMessage),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class WarningBlock extends StatelessWidget {
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  const WarningBlock({
    super.key,
    required this.title,
    required this.message,
    this.action,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasMessage = message.trim().isNotEmpty;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: (compact ? Theme.of(context).textTheme.titleSmall : Theme.of(context).textTheme.titleMedium)?.copyWith(
                  color: AppColors.warning,
                ),
          ),
          if (hasMessage) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.superLoadText,
                  ),
            ),
          ],
          if (action != null) ...[
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

// ─── Phase 4 New Widgets ───

class SectionHeader extends StatelessWidget {
  final String label;
  final String title;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.label,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.labelMicro.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class EmptyStateIllustration extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateIllustration({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryChipBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
