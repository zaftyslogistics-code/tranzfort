import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/fade_content_switcher.dart';
import '../../../shared/widgets/meta_chip.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../providers/fleet_providers.dart';

class MyFleetScreen extends ConsumerWidget {
  const MyFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fleetAsync = ref.watch(fleetProvider);
    final fleetCount = fleetAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      drawer: const AppDrawer(role: 'trucker'),
      appBar: AppBar(
        title: Text(l10n.myFleetTitle),
        actions: [
          IconButton(
            onPressed: () => context.push('/my-fleet/add'),
            icon: const Icon(Icons.add),
            tooltip: l10n.myFleetAddTruckTooltip,
          ),
          AppBarUtilityActions(ttsPreviewText: l10n.myFleetDashboardTts),
        ],
      ),
      body: Column(
        children: [
          TtsAnnounce(text: l10n.myFleetScreenTtsContextCount(fleetCount)),
          Expanded(
            child: FadeContentSwitcher(
              child: KeyedSubtree(
                key: ValueKey('my-fleet-${fleetAsync.isLoading}-${fleetAsync.hasError}'),
                child: fleetAsync.when(
              data: (trucks) {
                if (trucks.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.local_shipping_outlined,
                    title: l10n.myFleetEmptyTitle,
                    subtitle: l10n.myFleetEmptySubtitle,
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.refresh(fleetProvider.future),
                  child: ListView.separated(
                    addAutomaticKeepAlives: false,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenPaddingH,
                      AppSpacing.screenPaddingV,
                      AppSpacing.screenPaddingH,
                      AppSpacing.safeBottomPadding(context),
                    ),
                    itemCount: trucks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            const _FleetHeader(),
                            const SizedBox(height: AppSpacing.md),
                            _TruckCard(truck: trucks[index]),
                          ],
                        ).staggeredFadeSlide(index: index);
                      }
                      return _TruckCard(
                        truck: trucks[index],
                      ).staggeredFadeSlide(index: index);
                    },
                  ),
                );
              },
              loading: () => SkeletonLoader.list(
                count: 3,
                itemHeight: 120,
              ),
              error: (e, _) => Center(child: Text(l10n.myFleetLoadError)),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentRole: 'trucker'),
    );
  }
}

class _FleetHeader extends StatelessWidget {
  const _FleetHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.myFleetHeroTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.myFleetHeroSubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

}

class _TruckCard extends StatelessWidget {
  final Map<String, dynamic> truck;

  const _TruckCard({required this.truck});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = (truck['status'] ?? 'pending').toString();
    final truckNumber = (truck['truck_number'] ?? '-').toString();
    final bodyType = (truck['body_type'] ?? '-').toString();
    final tyres = (truck['tyres'] ?? '-').toString();
    final capacity = (truck['capacity_tonnes'] ?? '-').toString();
    final model = (truck['truck_model']?['model'] ?? '').toString();
    final make = (truck['truck_model']?['make'] ?? '').toString();
    final rejectionReason = (truck['rejection_reason'] ?? '').toString();
    final rcExpiryDate = DateTime.tryParse((truck['rc_expiry_date'] ?? '').toString());
    final rcExpiryDays = rcExpiryDate == null
        ? null
        : IstTime.toIst(rcExpiryDate).difference(IstTime.nowIst()).inDays;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: const BorderSide(color: AppColors.neutralLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        truckNumber,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (make.isNotEmpty || model.isNotEmpty)
                        Text(
                          '${make.isEmpty ? '' : '$make '}$model',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                StatusBadge.fromVerificationStatus(context, status),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                MetaChip(
                  label: l10n.myFleetBodyLabel(_bodyTypeLabel(l10n, bodyType)),
                ),
                MetaChip(label: l10n.myFleetTyresLabel(tyres)),
                MetaChip(label: l10n.myFleetCapacityLabel(capacity)),
              ],
            ),
            if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorTint,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.error,
                      width: 4,
                    ),
                  ),
                ),
                child: Text(
                  l10n.myFleetRejectionReasonLabel(rejectionReason),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.error),
                ),
              ),
            ],
            if (rcExpiryDays != null && rcExpiryDays <= 30) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warningTint,
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                  border: Border(
                    left: BorderSide(
                      color: AppColors.warning,
                      width: 4,
                    ),
                  ),
                ),
                child: Text(
                  rcExpiryDays <= 0
                      ? l10n.myFleetRcExpiredWarning
                      : l10n.myFleetRcExpiryWarningDays(rcExpiryDays),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _bodyTypeLabel(AppLocalizations l10n, String bodyType) {
    return switch (bodyType.toLowerCase()) {
      'open' => l10n.postLoadTruckTypeOpen,
      'container' => l10n.postLoadTruckTypeContainer,
      'trailer' => l10n.postLoadTruckTypeTrailer,
      'tanker' => l10n.postLoadTruckTypeTanker,
      'refrigerated' => l10n.postLoadTruckTypeRefrigerated,
      _ => bodyType,
    };
  }
}
