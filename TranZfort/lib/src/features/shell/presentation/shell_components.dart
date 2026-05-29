import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/navigation/route_metadata_helper.dart';
import '../../../core/widgets/tts_screen_summary_effect.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/tts_action_button.dart';

/// Pops when the router has a stack entry; otherwise [context.go] to dashboard.
///
/// Avoids [Navigator.pop] on routes opened via [GoRouter.go], which crashes.
void popShellDetailRoute(BuildContext context) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  final location = GoRouterState.of(context).matchedLocation;
  if (location == AppRoutes.supplierVerificationPath ||
      location.startsWith('${AppRoutes.supplierVerificationPath}/')) {
    context.go(AppRoutes.supplierDashboardPath);
    return;
  }
  if (location == AppRoutes.truckerVerificationPath ||
      location.startsWith('${AppRoutes.truckerVerificationPath}/')) {
    context.go(AppRoutes.truckerDashboardPath);
  }
}

class DetailPageScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? ttsSummary;
  final String? ttsScreenKey;
  final bool? showBackArrow;
  final Widget? bottomWidget;

  const DetailPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.ttsSummary,
    this.ttsScreenKey,
    this.showBackArrow,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedSummary = (ttsSummary ?? title).trim();
    // Determine if back arrow should be shown
    // If explicitly provided, use that value
    // Otherwise, check route metadata
    final shouldShowBackArrow = showBackArrow ?? RouteMetadataHelper.shouldShowBackArrow(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(title),
        leading: shouldShowBackArrow
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => popShellDetailRoute(context),
              )
            : null,
        actions: [
          const TtsActionButton(),
          const LanguageToggleAction(),
        ],
      ),
      body: Stack(
        children: [
          ShellScrollView(
            bottomWidgetHeight: bottomWidget != null ? AppSpacing.bottomNavSafe + 80 : null,
            children: children,
          ),
          TtsScreenSummaryEffect(
            summary: resolvedSummary,
            screenKey: ttsScreenKey ?? title,
          ),
        ],
      ),
      bottomNavigationBar: bottomWidget != null
          ? SafeArea(
              minimum: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: bottomWidget!,
            )
          : null,
    );
  }
}

class ShellScrollView extends StatelessWidget {
  final List<Widget> children;
  final double? bottomWidgetHeight;

  const ShellScrollView({super.key, required this.children, this.bottomWidgetHeight});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = bottomWidgetHeight ?? AppSpacing.bottomNavSafe;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        bottomPadding + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1)
              const SizedBox(height: AppSpacing.sectionGap),
          ],
        ],
      ),
    );
  }
}

class StandaloneStateScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const StandaloneStateScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppColors.primary),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const HeroPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroCardWash,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppColors.heroShadow,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 152,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class FilterChipPill extends StatelessWidget {
  final String label;

  const FilterChipPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.subtleSurface,
      side: const BorderSide(color: AppColors.divider),
      visualDensity: VisualDensity.compact,
    );
  }
}

class LoadPreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;

  const LoadPreviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    status,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.info,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NavListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const NavListTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
