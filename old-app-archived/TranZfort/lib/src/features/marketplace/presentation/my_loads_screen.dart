import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/scroll_to_top_fab.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../utils/load_pricing.dart';
import '../providers/marketplace_providers.dart';

class MyLoadsScreen extends ConsumerStatefulWidget {
  const MyLoadsScreen({super.key});

  @override
  ConsumerState<MyLoadsScreen> createState() => _MyLoadsScreenState();
}

class _MyLoadsScreenState extends ConsumerState<MyLoadsScreen> {
  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeLoadsAsync = ref.watch(myLoadsProvider(false));
    final activeLoads = activeLoadsAsync.valueOrNull ?? const [];
    final inTransitLoads = activeLoads
        .where((load) => (load['status'] ?? '').toString() == 'in_transit')
        .length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        drawer: const AppDrawer(role: 'supplier'),
        appBar: AppBar(
          title: Text(l10n.myLoadsTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.activeTab),
              Tab(text: l10n.completedTab),
            ],
          ),
          actions: [
            AppBarUtilityActions(ttsPreviewText: l10n.myLoadsDashboardTts),
          ],
        ),
        body: NestedScrollView(
          controller: _pageScrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    TtsAnnounce(
                      text: l10n.myLoadsScreenTtsContextDetailed(
                        activeLoads.length,
                        inTransitLoads,
                      ),
                    ),
                    const _LoadsHeader(),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _LoadsTab(completed: false),
              _LoadsTab(completed: true),
            ],
          ),
        ),
        floatingActionButton: ScrollToTopFab(
          controller: _pageScrollController,
        ),
        bottomNavigationBar: const BottomNavBar(currentRole: 'supplier'),
      ),
    );
  }

}

class _LoadsHeader extends ConsumerWidget {
  const _LoadsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final activeLoads =
        ref.watch(myLoadsProvider(false)).valueOrNull ?? const [];
    final completedLoads =
        ref.watch(myLoadsProvider(true)).valueOrNull ??
        const <Map<String, dynamic>>[];
    final activeCount = activeLoads.length;
    final inTransitCount = activeLoads
        .where((load) => (load['status'] ?? '').toString() == 'in_transit')
        .length;
    final completedCount = completedLoads.length;
    final tabController = DefaultTabController.of(context);
    final verificationStatus = (profile?['verification_status'] ?? '')
        .toString()
        .toLowerCase();
    final rejectionReason = (profile?['verification_rejection_reason'] ?? '')
        .toString()
        .trim();
    final verificationSummary = switch (verificationStatus) {
      'verified' => l10n.dashboardVerificationStatusVerified,
      'pending' => l10n.dashboardVerificationStatusPending,
      'rejected' => rejectionReason.isEmpty
          ? l10n.dashboardVerificationStatusRejected
          : l10n.dashboardVerificationRejectedReason(rejectionReason),
      'unverified' || '' => l10n.dashboardVerificationStatusUnverified,
      _ => l10n.dashboardVerificationStatusUnknown,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingH,
        AppSpacing.screenPaddingV,
        AppSpacing.screenPaddingH,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.kpiChipBorder),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: AppSpacing.tileLeadingSize,
                      height: AppSpacing.tileLeadingSize,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.verified_user_outlined,
                        size: AppSpacing.iconMd,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.supplierOverview,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            verificationSummary,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/verification/supplier'),
                      child: Text(l10n.appDrawerVerification),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.myLoadsOverviewSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: l10n.myLoadsActiveLabel,
                        value: activeCount,
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        variant: StatCardVariant.hero,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatCard(
                        label: l10n.myLoadsInTransitLabel,
                        value: inTransitCount,
                        icon: Icons.local_shipping_outlined,
                        color: AppColors.warning,
                        variant: StatCardVariant.hero,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: StatCard(
                        label: l10n.completedTab,
                        value: completedCount,
                        icon: Icons.task_alt_outlined,
                        color: AppColors.success,
                        variant: StatCardVariant.hero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                GradientButton(
                  label: l10n.postLoadAction,
                  onPressed: () => context.push('/post-load'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _LoadsQuickActions(
            onGoToActive: () => tabController.animateTo(0),
            onGoToCompleted: () => tabController.animateTo(1),
          ),
        ],
      ),
    );
  }
}

class _LoadsQuickActions extends StatelessWidget {
  final VoidCallback onGoToActive;
  final VoidCallback onGoToCompleted;

  const _LoadsQuickActions({
    required this.onGoToActive,
    required this.onGoToCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceLevel1,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _QuickActionTile(
                width: itemWidth,
                icon: Icons.inventory_2_outlined,
                label: l10n.activeTab,
                onTap: onGoToActive,
              ),
              _QuickActionTile(
                width: itemWidth,
                icon: Icons.task_alt_outlined,
                label: l10n.completedTab,
                onTap: onGoToCompleted,
              ),
              _QuickActionTile(
                width: itemWidth,
                icon: Icons.chat_bubble_outline,
                label: l10n.messagesTitle,
                onTap: () => context.push('/messages'),
              ),
              _QuickActionTile(
                width: itemWidth,
                icon: Icons.verified_user_outlined,
                label: l10n.appDrawerVerification,
                onTap: () => context.push('/verification/supplier'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLevel2,
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppSpacing.iconMd, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMetaTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _LoadMetaTile({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        border: Border.all(color: AppColors.neutralLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LoadsTab extends ConsumerWidget {
  final bool completed;

  const _LoadsTab({required this.completed});

  String _priceSummary(Map<String, dynamic> load) {
    final price = LoadPricing.priceValue(load['price']);
    if (price == null) {
      return '₹-';
    }
    final formatted = price.truncateToDouble() == price
        ? '₹${price.toStringAsFixed(0)}'
        : '₹${price.toStringAsFixed(1)}';
    if (LoadPricing.isPerTon(load['price_type'])) {
      return '$formatted/T';
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final loadsAsync = ref.watch(myLoadsProvider(completed));

    return loadsAsync.when(
      data: (loads) {
        if (loads.isEmpty) {
          return EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: completed ? l10n.noCompletedLoads : l10n.noActiveLoads,
            subtitle: completed
                ? l10n.completedLoadsHere
                : l10n.postFirstLoadPrompt,
            cta: completed
                ? null
                : PrimaryButton(
                    label: l10n.postLoadAction,
                    onPressed: () => context.push('/post-load'),
                  ),
          );
        }

        final requiresActionCount = completed
            ? 0
            : loads
                  .where(
                    (load) =>
                        (load['status'] ?? '').toString().contains('pending'),
                  )
                  .length;
        final showBanner = !completed && requiresActionCount > 0;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myLoadsProvider(completed));
            await ref.read(myLoadsProvider(completed).future);
          },
          child: ListView.separated(
            key: PageStorageKey<String>('my_loads_${completed ? 'completed' : 'active'}'),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.sm,
              AppSpacing.screenPaddingH,
              AppSpacing.safeBottomPadding(context),
            ),
            addAutomaticKeepAlives: false,
            itemBuilder: (context, index) {
              if (showBanner && index == 0) {
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.myLoadsRequiresActionBanner(requiresActionCount),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final load = loads[showBanner ? index - 1 : index];
              final status = (load['status'] ?? '-').toString();
              final trucksNeeded =
                  (load['trucks_needed'] as num?)?.toInt() ?? 1;
              final trucksBooked =
                  (load['trucks_booked'] as num?)?.toInt() ?? 0;
              final progress = trucksNeeded <= 0
                  ? 0.0
                  : trucksBooked / trucksNeeded;
              final normalizedProgress = progress.clamp(0, 1).toDouble();
              final progressColor = status == 'completed'
                  ? AppColors.success
                  : normalizedProgress >= 1
                  ? AppColors.success
                  : normalizedProgress > 0
                  ? AppColors.warning
                  : AppColors.primary;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: const BorderSide(color: AppColors.neutralLight),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: () => context.push('/load-detail/${load['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${load['origin_city']} → ${load['dest_city']}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            _statusBadge(
                              context,
                              status,
                              trucksNeeded,
                              trucksBooked,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final itemWidth =
                                (constraints.maxWidth - AppSpacing.sm) / 2;
                            return Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                _LoadMetaTile(
                                  width: itemWidth,
                                  label: l10n.postLoadMaterialLabel,
                                  value: '${load['material'] ?? '-'}',
                                ),
                                _LoadMetaTile(
                                  width: itemWidth,
                                  label: l10n.tripSnapshotWeight,
                                  value: '${load['weight_tonnes'] ?? '-'}T',
                                ),
                                _LoadMetaTile(
                                  width: itemWidth,
                                  label: l10n.tripSnapshotPrice,
                                  value: _priceSummary(load),
                                ),
                                _LoadMetaTile(
                                  width: itemWidth,
                                  label: l10n.richLoadCardPickupPrefix,
                                  value: '${load['pickup_date'] ?? '-'}',
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                            border: Border.all(color: AppColors.neutralLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      l10n.myLoadsTrucksBookedSummary(
                                        trucksBooked,
                                        trucksNeeded,
                                      ),
                                      style: Theme.of(context).textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    '${(normalizedProgress * 100).toStringAsFixed(0)}%',
                                    style: Theme.of(context).textTheme.labelSmall
                                        ?.copyWith(
                                          color: progressColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.sm),
                                child: LinearProgressIndicator(
                                  value: normalizedProgress,
                                  minHeight: 10,
                                  backgroundColor: AppColors.neutralLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progressColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!completed && status == 'active') ...[
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 132,
                              child: PrimaryButton(
                                label: l10n.deactivateAction,
                                color: AppColors.error,
                                onPressed: () async {
                                  final success = await ref
                                      .read(loadActionProvider.notifier)
                                      .deactivateLoad(load['id'].toString());
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? l10n.loadDeactivated
                                            : l10n.couldNotDeactivateLoad,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                        if (completed || status == 'completed') ...[
                          const SizedBox(height: AppSpacing.md),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 132,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  context.push(
                                    '/post-load',
                                    extra: {
                                      'origin_city': load['origin_city'],
                                      'origin_state': load['origin_state'],
                                      'dest_city': load['dest_city'],
                                      'dest_state': load['dest_state'],
                                      'material': load['material'],
                                      'weight_tonnes': load['weight_tonnes'],
                                      'required_truck_type':
                                          load['required_truck_type'],
                                      'required_tyres': load['required_tyres'],
                                      'price': load['price'],
                                      'price_type': load['price_type'],
                                      'advance_percentage':
                                          load['advance_percentage'],
                                      'pickup_date': load['pickup_date'],
                                      'trucks_needed': load['trucks_needed'],
                                    },
                                  );
                                },
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.postLoadAction),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.listItemGap),
            itemCount: loads.length + (showBanner ? 1 : 0),
          ),
        );
      },
      loading: () => SkeletonLoader.list(count: 3, itemHeight: 120),
      error: (error, _) => Center(child: Text(l10n.myLoadsLoadErrorPrefix)),
    );
  }

  Widget _statusBadge(
    BuildContext context,
    String status,
    int needed,
    int booked,
  ) {
    final l10n = AppLocalizations.of(context);
    if (status == 'completed') {
      return StatusBadge(
        label: l10n.myLoadsStatusCompleted,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      );
    }
    if (status == 'cancelled' || status == 'expired') {
      return StatusBadge(
        label: l10n.myLoadsStatusCancelled,
        backgroundColor: AppColors.neutralLight,
        textColor: AppColors.neutral,
      );
    }
    if (booked == 0) {
      return StatusBadge(
        label: l10n.myLoadsStatusWaiting,
        backgroundColor: AppColors.background,
        textColor: AppColors.textSecondary,
      );
    }
    if (booked >= needed) {
      return StatusBadge(
        label: l10n.myLoadsStatusFullyBooked,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      );
    }
    return StatusBadge(
      label: l10n.myLoadsStatusFulfilling,
      backgroundColor: AppColors.warningTint,
      textColor: AppColors.warning,
    );
  }
}
