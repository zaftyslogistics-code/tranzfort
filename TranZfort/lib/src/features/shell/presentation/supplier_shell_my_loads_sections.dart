import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_load_models.dart';
import '../../../features/supplier/data/supplier_load_repost.dart';
import '../../../features/supplier/data/supplier_load_repository.dart';
import '../../../features/supplier/presentation/widgets/repost_load_sheet.dart';
import '../../../features/supplier/providers/post_load_quota_provider.dart';
import '../../../features/supplier/data/supplier_profile_repository.dart';
import '../../../features/supplier/providers/my_loads_provider.dart';
import '../../../features/supplier/providers/supplier_providers.dart';
import '../../../features/support/providers/support_compose_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/supplier_load_compact_card.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../../shared/widgets/tts_card_speaker_button.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/supplier_load_list_card_tts_builder.dart';
import 'supplier_shell_shared_helpers.dart';

class SupplierMyLoadsScreen extends ConsumerStatefulWidget {
  const SupplierMyLoadsScreen({super.key});

  @override
  ConsumerState<SupplierMyLoadsScreen> createState() => _SupplierMyLoadsScreenState();
}

class _SupplierMyLoadsScreenState extends ConsumerState<SupplierMyLoadsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(myLoadsProvider);
    final supplierProfileAsync = ref.watch(supplierProfileProvider);
    final supplierProfile = supplierProfileAsync.valueOrNull;
    final profileResolved = !supplierProfileAsync.isLoading && !supplierProfileAsync.hasError && supplierProfile != null;
    final canPostLoads = _supplierCanPostLoads(supplierProfile);

    return RefreshIndicator(
      onRefresh: () => ref.read(myLoadsProvider.notifier).loadInitial(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.sectionGap,
            ),
            sliver: SliverToBoxAdapter(
              child: HeroActionCard(
                title: l10n.supplierMyLoadsTitle,
                subtitle: l10n.supplierMyLoadsSubtitle,
                compact: true,
                useDarkTheme: true,
                useInkGradient: true,
                titleIcon: Icons.inventory_2_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilterChipBar(
                      items: [
                        FilterChipItem(
                          label: l10n.commonActiveLabel,
                          selected: state.selectedTab == MyLoadsTab.active,
                          onTap: () => ref.read(myLoadsProvider.notifier).selectTab(MyLoadsTab.active),
                        ),
                        FilterChipItem(
                          label: l10n.commonCompletedLabel,
                          selected: state.selectedTab == MyLoadsTab.completed,
                          onTap: () => ref.read(myLoadsProvider.notifier).selectTab(MyLoadsTab.completed),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppSearchField(
                      controller: _searchController,
                      hintText: l10n.supplierMyLoadsSearchHint,
                      onDarkSurface: true,
                      onChanged: ref.read(myLoadsProvider.notifier).updateSearchQuery,
                      onClear: () {
                        _searchController.clear();
                        ref.read(myLoadsProvider.notifier).clearSearchQuery();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          ..._buildMyLoadsSlivers(
            context,
            state: state,
            canPostLoads: canPostLoads,
            hasResolvedSupplierProfile: profileResolved,
            onRetry: () => ref.read(myLoadsProvider.notifier).loadInitial(),
            onLoadMore: () => ref.read(myLoadsProvider.notifier).loadMore(),
          ),
        ],
      ),
    );
  }

  bool _supplierCanPostLoads(SupplierProfile? profile) {
    return profile?.canAccessWorkspace == true;
  }
}

List<Widget> _buildMyLoadsSlivers(
  BuildContext context, {
  required MyLoadsState state,
  required bool canPostLoads,
  required bool hasResolvedSupplierProfile,
  required VoidCallback onRetry,
  required VoidCallback onLoadMore,
}) {
  final l10n = AppLocalizations.of(context);
  if (state.isInitialLoading) {
    return const <Widget>[
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.bottomNavSafe + AppSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: LoadingShimmer(height: 110, itemCount: 4),
        ),
      ),
    ];
  }

  if (state.failure != null && state.loads.isEmpty) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.bottomNavSafe + AppSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: WarningBlock(
            title: l10n.supplierMyLoadsLoadFailureTitle,
            message: l10n.supplierMyLoadsFailureMessage,
            action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
          ),
        ),
      ),
    ];
  }

  if (state.loads.isEmpty) {
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.bottomNavSafe + AppSpacing.xl,
        ),
        sliver: SliverToBoxAdapter(
          child: EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: state.selectedTab == MyLoadsTab.active
                ? l10n.supplierMyLoadsEmptyActiveTitle
                : l10n.supplierMyLoadsEmptyCompletedTitle,
            subtitle: state.selectedTab == MyLoadsTab.active
                ? l10n.supplierMyLoadsEmptyActiveSubtitle
                : l10n.supplierMyLoadsEmptyCompletedSubtitle,
            actionLabel: state.selectedTab == MyLoadsTab.active
                ? (!hasResolvedSupplierProfile
                      ? l10n.commonSupportLabel
                      : canPostLoads
                      ? l10n.commonPostLoadAction
                      : l10n.supplierCompleteVerification)
                : l10n.supplierMyLoadsOpenActiveLoads,
            onAction: () => context.go(
              state.selectedTab == MyLoadsTab.active
                  ? (!hasResolvedSupplierProfile
                        ? AppRoutes.supportPath
                        : canPostLoads
                        ? AppRoutes.postLoadPath
                        : AppRoutes.supplierVerificationPath)
                  : AppRoutes.myLoadsPath,
            ),
          ),
        ),
      ),
    ];
  }

  return <Widget>[
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index == state.loads.length - 1 ? 0 : AppSpacing.md),
            child: _SupplierLoadListCard(load: state.loads[index]),
          );
        }, childCount: state.loads.length),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.bottomNavSafe + AppSpacing.xl,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            if (state.failure != null)
              WarningBlock(
                title: l10n.supplierMyLoadsMoreUnavailableTitle,
                message: l10n.supplierMyLoadsPaginationFailureMessage,
                action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
              ),
            if (state.failure != null && state.hasMore) const SizedBox(height: AppSpacing.md),
            if (state.hasMore)
              OutlineButton(
                label: state.isLoadingMore ? l10n.supplierMyLoadsLoadingMore : l10n.supplierMyLoadsLoadMore,
                onPressed: state.isLoadingMore ? null : onLoadMore,
              ),
          ],
        ),
      ),
    ),
  ];
}

class _SupplierLoadListCard extends ConsumerWidget {
  final Load load;

  const _SupplierLoadListCard({required this.load});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = TtsLocalizations.of(context);
    final palette = statusPaletteFor(load.status);
    final statusLabel = localizedSupplierDashboardLoadStatus(l10n, load.status);
    final utterance = const SupplierLoadListCardTtsBuilder().build(
      load: load,
      tts: ttsL10n,
      statusLabel: statusLabel,
    );
    final supplierId = ref.watch(supplierProfileProvider).valueOrNull?.id ?? '';

    return SupplierLoadCompactCard.fromLoad(
      load: load,
      supplierId: supplierId,
      statusChips: [
        StatusChip(label: statusLabel, palette: palette),
        StatusChip(
          label: localizedLoadMarketplaceStatus(
            l10n,
            isOnMarketplace: load.isOnMarketplace,
            trucksBooked: load.trucksBooked,
            trucksNeeded: load.trucksNeeded,
          ),
        ),
        if (hasSuperLoadState(isSuperLoad: load.isSuperLoad, superStatus: load.superStatus))
          StatusBadge(
            label: l10n.supplierDashboardSuperLoadBadge(
              superLoadStatusLabel(l10n, load.superStatus, isSuperLoad: load.isSuperLoad),
            ),
            icon: Icons.workspace_premium_outlined,
          ),
      ],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.supplierLoadCardPickupDate(formatSupplierShortDate(context, load.pickupDate)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextSecondary),
                ),
              ),
              TtsCardSpeakerButton(message: utterance, onDarkSurface: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.supplierLoadCardTrucks('${load.trucksBooked}', '${load.trucksNeeded}'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.inkTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!load.isOnMarketplace) ...[
            TextActionButton(
              label: l10n.supplierLoadRepostAction,
              onPressed: () => _openRepostSheet(context, ref, load),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextActionButton(
            label: _primaryActionLabel(context, load.status),
            onPressed: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextActionButton(
            label: l10n.commonReportSpamOrAbuseAction,
            onPressed: () => context.push(
              AppRoutes.reportIssuePath,
              extra: ReportIssueContext(
                initialCategory: 'fake_listing',
                relatedLoadId: load.id,
                relatedTripId: '',
                sourceLabel: l10n.reportSourceSupplierLoad(
                  '${load.originLabel} > ${load.destinationLabel}',
                ),
              ),
            ),
          ),
        ],
      ),
      onTap: () => context.push('${AppRoutes.loadDetailPath}/${load.id}'),
    );
  }

  Future<void> _openRepostSheet(BuildContext context, WidgetRef ref, Load load) async {
    final l10n = AppLocalizations.of(context);
    final newLoadId = await showRepostLoadSheet(
      context: context,
      sourceLoadId: load.id,
      onSubmit: (request) => ref.read(supplierLoadRepositoryProvider).cloneLoadForRepost(request),
    );
    if (!context.mounted || newLoadId == null || newLoadId.isEmpty) {
      return;
    }
    ref.invalidate(myLoadsProvider);
    ref.invalidate(supplierRecentLoadsProvider);
    ref.invalidate(supplierDashboardProvider);
    ref.invalidate(postLoadQuotaProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackbar.build(
        context: context,
        message: l10n.supplierLoadRepostSuccess,
        variant: AppSnackbarVariant.success,
      ),
    );
    context.push('${AppRoutes.loadDetailPath}/$newLoadId');
  }

  String _primaryActionLabel(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case 'assigned_full':
      case 'assigned_partial':
      case 'in_transit':
        return l10n.supplierLoadCardTrackLoad;
      case 'completed':
      case 'filled_outside_app':
        return l10n.supplierLoadCardViewHistory;
      default:
        return l10n.commonViewDetailsAction;
    }
  }
}
