import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.inkHeroCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile != null) ...[
            _DashboardWelcomeHeader(profile: profile),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Text(
              l10n.truckerDashboardWelcomeLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.inkTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
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
          const SizedBox(height: AppSpacing.md),
          GradientButton(
            label: l10n.truckerDashboardSearchLoadsAction,
            onPressed: _searchLoads,
          ),
        ],
      ),
    );
  }
}

class _DashboardWelcomeHeader extends StatelessWidget {
  final TruckerProfile profile;

  const _DashboardWelcomeHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final lightTitleStyle = theme.textTheme.titleMedium?.copyWith(
      color: AppColors.inkTextSecondary,
      fontWeight: FontWeight.w500,
    );
    final lightNameStyle = theme.textTheme.titleMedium?.copyWith(
      color: AppColors.inkTextPrimary,
      fontWeight: FontWeight.w600,
    );
    final lightMetaStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppColors.inkTextSecondary,
      fontWeight: FontWeight.w500,
    );

    final fullName = profile.fullName.trim();
    final verified = profile.isVerified;
    final approvedTrucks = profile.approvedTrucks;
    final trucksLabel = l10n.truckerDashboardApprovedTruckCount(approvedTrucks);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.truckerDashboardWelcomeLabel,
                style: lightTitleStyle,
              ),
              if (fullName.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  fullName,
                  style: lightNameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            _VerificationStatusGlyph(
              verified: verified,
              tooltip: verified
                  ? l10n.verificationStatusVerified
                  : _verificationTooltip(l10n, profile.verificationStatus),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 15,
                  color: approvedTrucks > 0 ? AppColors.primaryOnDark : AppColors.inkTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  trucksLabel,
                  style: lightMetaStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
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

class _VerificationStatusGlyph extends StatelessWidget {
  final bool verified;
  final String tooltip;

  const _VerificationStatusGlyph({
    required this.verified,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppColors.success : AppColors.inkTextSecondary;

    return Tooltip(
      message: tooltip,
      child: Icon(
        verified ? Icons.verified : Icons.verified_outlined,
        size: 22,
        color: color,
      ),
    );
  }
}
