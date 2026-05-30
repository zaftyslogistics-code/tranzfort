import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/content_cards.dart';
import '../../data/trucker_profile_repository.dart';
import '../../providers/find_loads_provider.dart';
import 'marketplace_route_search_fields.dart';

class DashboardRouteSearchHero extends ConsumerStatefulWidget {
  final TruckerProfile? profile;

  const DashboardRouteSearchHero({super.key, required this.profile});

  @override
  ConsumerState<DashboardRouteSearchHero> createState() => _DashboardRouteSearchHeroState();
}

class _DashboardRouteSearchHeroState extends ConsumerState<DashboardRouteSearchHero> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController();
    _destinationController = TextEditingController();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _searchLoads() {
    ref.read(marketplaceRoutePrefillProvider.notifier).state = MarketplaceRoutePrefill(
      originCity: _originController.text.trim(),
      destinationCity: _destinationController.text.trim(),
    );
    context.go(AppRoutes.findLoadsPath);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final profile = widget.profile;
    final greeting = _heroGreeting(profile, l10n);

    return HeroActionCard(
      title: l10n.shellTitleFindLoads,
      subtitle: greeting,
      compact: true,
      useDarkTheme: true,
      useInkGradient: true,
      titleIcon: Icons.search_outlined,
      primaryAction: GradientButton(
        label: l10n.truckerDashboardSearchLoadsAction,
        onPressed: _searchLoads,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile != null) ...[
            _DashboardTrustIconRow(profile: profile),
            const SizedBox(height: AppSpacing.md),
          ],
          MarketplaceRouteSearchFields(
            originController: _originController,
            destinationController: _destinationController,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.truckerDashboardFiltersOnFindLoadsHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.inkTextSecondary,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  String _heroGreeting(TruckerProfile? profile, AppLocalizations l10n) {
    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return l10n.truckerDashboardHeroGreeting(fullName);
    }
    return '';
  }
}

class _DashboardTrustIconRow extends StatelessWidget {
  final TruckerProfile profile;

  const _DashboardTrustIconRow({required this.profile});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final verified = profile.isVerified;
    final approvedTrucks = profile.approvedTrucks;

    return Row(
      children: [
        _TrustIconChip(
          icon: verified ? Icons.verified : Icons.verified_outlined,
          color: verified ? AppColors.success : AppColors.inkTextSecondary,
          tooltip: verified ? l10n.verificationStatusVerified : _verificationTooltip(l10n, profile.verificationStatus),
        ),
        if (approvedTrucks > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          _TrustIconChip(
            icon: Icons.local_shipping_outlined,
            color: AppColors.primaryOnDark,
            tooltip: l10n.truckerDashboardApprovedTruckCount(approvedTrucks),
            badge: '$approvedTrucks',
          ),
        ],
      ],
    );
  }

  String _verificationTooltip(AppLocalizations l10n, String status) {
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'pending':
        return l10n.commonPendingLabel;
      case 'rejected':
        return l10n.verificationStatusRejected;
      case 'unverified':
        return l10n.verificationStatusUnverified;
      case '':
        return l10n.truckerDashboardSetupInProgress;
      default:
        return l10n.commonUnknownLabel;
    }
  }
}

class _TrustIconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final String? badge;

  const _TrustIconChip({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primaryOnDark.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Text(
                badge!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
