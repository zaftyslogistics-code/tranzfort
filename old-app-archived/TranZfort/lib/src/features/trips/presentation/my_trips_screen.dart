import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/utils/animations.dart';
import '../../../core/utils/ist_time.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_bar_utility_actions.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/fade_content_switcher.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/lifecycle_timeline.dart';
import '../../../shared/widgets/meta_chip.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/scroll_to_top_fab.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../providers/trips_providers.dart';

class MyTripsScreen extends ConsumerStatefulWidget {
  const MyTripsScreen({super.key});

  @override
  ConsumerState<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends ConsumerState<MyTripsScreen> {
  final ScrollController _activeScrollController = ScrollController();
  final ScrollController _completedScrollController = ScrollController();
  int _currentTabIndex = 0;
  TabController? _tabController;

  ScrollController get _currentScrollController => _currentTabIndex == 0
      ? _activeScrollController
      : _completedScrollController;

  void _handleTabChange() {
    if (_tabController == null || _tabController!.indexIsChanging || !mounted) {
      return;
    }
    setState(() => _currentTabIndex = _tabController!.index);
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    _activeScrollController.dispose();
    _completedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeTripsAsync = ref.watch(myTripsProvider(false));
    final activeTrips = activeTripsAsync.valueOrNull ?? const [];
    final currentLoad = activeTrips.isEmpty
        ? null
        : (activeTrips.first['load'] as Map<String, dynamic>? ?? const {});
    final currentOrigin = (currentLoad?['origin_city'] ?? l10n.findLoadsAny)
        .toString();
    final currentDestination = (currentLoad?['dest_city'] ?? l10n.findLoadsAny)
        .toString();

    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
          if (_tabController != tabController) {
            _tabController?.removeListener(_handleTabChange);
            _tabController = tabController;
            _tabController?.addListener(_handleTabChange);
          }

          return Scaffold(
            backgroundColor: AppColors.scaffoldBg,
            drawer: const AppDrawer(role: 'trucker'),
            appBar: AppBar(
              title: Text(l10n.myTripsTitle),
              bottom: TabBar(
                dividerHeight: 1,
                dividerColor: AppColors.borderDefault,
                tabs: [
                  Tab(text: l10n.activeTab),
                  Tab(text: l10n.completedTab),
                ],
              ),
              actions: [
                AppBarUtilityActions(ttsPreviewText: l10n.myTripsDashboardTts),
              ],
            ),
            body: ScreenScrollContainer(
              scrollable: false,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  TtsAnnounce(
                    text: l10n.myTripsScreenTtsContextDetailed(
                      activeTrips.length,
                      currentOrigin,
                      currentDestination,
                    ),
                  ),
                  const _TripsHeader(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _TripsTab(
                          completed: false,
                          scrollController: _activeScrollController,
                        ),
                        _TripsTab(
                          completed: true,
                          scrollController: _completedScrollController,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScrollToTopFab(controller: _currentScrollController),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton(
                  heroTag: 'trucker-dashboard-bot-fab',
                  onPressed: () => context.push('/bot-chat'),
                  tooltip: l10n.appDrawerBotChat,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/images/bot-avatar.webp',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.smart_toy, color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: const BottomNavBar(currentRole: 'trucker'),
          );
        },
      ),
    );
  }
}

class _TripsHeader extends ConsumerWidget {
  const _TripsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activeTrips =
        ref.watch(myTripsProvider(false)).valueOrNull ?? const [];
    final completedTrips =
        ref.watch(myTripsProvider(true)).valueOrNull ?? const [];
    final activeTrip = activeTrips.isEmpty ? null : activeTrips.first;
    final activeLoad =
        activeTrip?['load'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    final routeLabel = activeTrip == null
        ? l10n.bookLoadPrompt
        : '${activeLoad['origin_city'] ?? '-'} → ${activeLoad['dest_city'] ?? '-'}';
    final currentStage = (activeTrip?['stage'] ?? '').toString();
    final stageLabel = _stageTitle(context, currentStage);
    final tabController = DefaultTabController.of(context);

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
                Text(
                  l10n.truckerOverview,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.tripOverviewSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                    border: Border.all(color: AppColors.kpiChipBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.activeTripStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        stageLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        routeLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activeTrip == null) ...[
                  const SizedBox(height: AppSpacing.md),
                  GradientButton(
                    label: l10n.findLoadsAction,
                    onPressed: () => context.push('/find-loads'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TripsQuickActions(
            activeCount: activeTrips.length,
            completedCount: completedTrips.length,
            showUploadPod: activeTrip != null,
            onOpenActiveTrips: () => tabController.animateTo(0),
            onOpenCompletedTrips: () => tabController.animateTo(1),
            onOpenFleet: () => context.push('/my-fleet'),
            onUploadPod: () {
              if (activeTrip != null) {
                context.push('/trip-detail/${activeTrip['id']}');
                return;
              }
              context.push('/find-loads');
            },
          ),
        ],
      ),
    );
  }

  String _stageTitle(BuildContext context, String stage) {
    final l10n = AppLocalizations.of(context);
    return switch (stage) {
      'completed' => l10n.tripStageCompleted,
      'in_transit' => l10n.tripStageInTransit,
      'at_pickup' => l10n.tripStageAtPickup,
      'delivered' => l10n.tripStageDelivered,
      'pod_uploaded' => l10n.tripStagePodUploaded,
      _ => l10n.tripMilestonesSubtitle,
    };
  }
}

class _TripsQuickActions extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final bool showUploadPod;
  final VoidCallback onOpenActiveTrips;
  final VoidCallback onOpenCompletedTrips;
  final VoidCallback onOpenFleet;
  final VoidCallback onUploadPod;

  const _TripsQuickActions({
    required this.activeCount,
    required this.completedCount,
    required this.showUploadPod,
    required this.onOpenActiveTrips,
    required this.onOpenCompletedTrips,
    required this.onOpenFleet,
    required this.onUploadPod,
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
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _ExecutionChip(
            icon: Icons.local_shipping_outlined,
            label: '${l10n.myTripsTitle} · $activeCount',
            onTap: onOpenActiveTrips,
          ),
          _ExecutionChip(
            icon: Icons.task_alt_outlined,
            label: '${l10n.completedTab} · $completedCount',
            onTap: onOpenCompletedTrips,
          ),
          _ExecutionChip(
            icon: Icons.fire_truck_outlined,
            label: l10n.myFleetTitle,
            onTap: onOpenFleet,
          ),
          if (showUploadPod)
            _ExecutionChip(
              icon: Icons.upload_file_outlined,
              label: l10n.tripUploadProofOfDelivery,
              onTap: onUploadPod,
            ),
        ],
      ),
    );
  }
}

class _ExecutionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ExecutionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceLevel2,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.iconSm, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripsTab extends ConsumerWidget {
  final bool completed;
  final ScrollController scrollController;

  const _TripsTab({required this.completed, required this.scrollController});

  static const List<String> _timelineStages = [
    'at_pickup',
    'in_transit',
    'delivered',
    'pod_uploaded',
    'completed',
  ];

  static const List<IconData> _timelineIcons = [
    Icons.warehouse_outlined,
    Icons.local_shipping_outlined,
    Icons.inventory_2_outlined,
    Icons.upload_file_outlined,
    Icons.check_circle_outline,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripsAsync = ref.watch(myTripsProvider(completed));

    final content = tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return EmptyStateView(
            icon: Icons.route_outlined,
            title: completed ? l10n.noCompletedTrips : l10n.noActiveTrips,
            subtitle: completed ? l10n.completedTripsHere : l10n.bookLoadPrompt,
            cta: completed
                ? null
                : PrimaryButton(
                    label: l10n.findLoadsAction,
                    onPressed: () => context.push('/find-loads'),
                  ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(myTripsProvider(completed));
            await ref.read(myTripsProvider(completed).future);
          },
          child: ListView.separated(
            addAutomaticKeepAlives: false,
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingH,
              AppSpacing.sm,
              AppSpacing.screenPaddingH,
              AppSpacing.safeBottomPadding(context),
            ),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final load = (trip['load'] as Map<String, dynamic>? ?? const {});
              final truck =
                  (trip['truck'] as Map<String, dynamic>? ??
                  const <String, dynamic>{});
              final stage = (trip['stage'] ?? '').toString();

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  side: const BorderSide(color: AppColors.neutralLight),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  onTap: () => context.push('/trip-detail/${trip['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                '${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _stageBadge(context, stage),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            MetaChip(label: '${load['material'] ?? '-'}'),
                            MetaChip(label: '${load['weight_tonnes'] ?? '-'}T'),
                            MetaChip(label: '${truck['truck_number'] ?? '-'}'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LifecycleTimeline(
                          stages: _timelineStages,
                          currentStageIndex: _timelineStages.indexOf(stage),
                          stageLabels: _timelineLabels(l10n),
                          stageIcons: _timelineIcons,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LinearProgressIndicator(
                          value: _stageProgress(stage),
                          minHeight: 4,
                          backgroundColor: AppColors.neutralLight,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _timeContext(context, trip),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.neutral),
                              ),
                            ),
                            Text(
                              '${(_stageProgress(stage) * 100).toStringAsFixed(0)}%',
                              style: AppTypography.number.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ).staggeredFadeSlide(
                index: index,
                baseDelay: const Duration(milliseconds: 50),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.cardGap),
            itemCount: trips.length,
          ),
        );
      },
      loading: () => SkeletonLoader.list(count: 3, itemHeight: 128),
      error: (error, _) => Center(child: Text(l10n.tripsLoadError)),
    );

    return FadeContentSwitcher(
      child: KeyedSubtree(
        key: ValueKey(
          'my-trips-$completed-${tripsAsync.isLoading}-${tripsAsync.hasError}',
        ),
        child: content,
      ),
    );
  }

  String _timeContext(BuildContext context, Map<String, dynamic> trip) {
    final l10n = AppLocalizations.of(context);
    final stage = (trip['stage'] ?? '').toString();
    final startedAt = DateTime.tryParse((trip['start_time'] ?? '').toString());
    final createdAt = DateTime.tryParse((trip['created_at'] ?? '').toString());

    final reference = startedAt ?? createdAt;
    if (reference == null) {
      return l10n.tripRecentlyUpdated;
    }

    final diff = IstTime.age(reference);
    final value = diff.inHours > 0
        ? '${diff.inHours}h ago'
        : '${diff.inMinutes}m ago';

    return switch (stage) {
      'completed' => '${l10n.tripCompletedPrefix} $value',
      'in_transit' => '${l10n.tripStartedPrefix} $value',
      'at_pickup' => '${l10n.tripApprovedPrefix} $value',
      'delivered' => '${l10n.tripDeliveredPrefix} $value',
      'pod_uploaded' => '${l10n.tripPodUploadedPrefix} $value',
      _ => '${l10n.tripUpdatedPrefix} $value',
    };
  }

  Widget _stageBadge(BuildContext context, String stage) {
    final l10n = AppLocalizations.of(context);
    return switch (stage) {
      'completed' => StatusBadge(
        label: l10n.tripStageCompleted,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      ),
      'in_transit' => StatusBadge(
        label: l10n.tripStageInTransit,
        backgroundColor: AppColors.warningTint,
        textColor: AppColors.warning,
      ),
      'at_pickup' => StatusBadge(
        label: l10n.tripStageAtPickup,
        backgroundColor: AppColors.warningTint,
        textColor: AppColors.warning,
      ),
      'delivered' => StatusBadge(
        label: l10n.tripStageDelivered,
        backgroundColor: AppColors.successTint,
        textColor: AppColors.success,
      ),
      'pod_uploaded' => StatusBadge(
        label: l10n.tripStagePodUploaded,
        backgroundColor: AppColors.infoTint,
        textColor: AppColors.info,
      ),
      _ => StatusBadge.neutral(l10n.tripStageUnknown),
    };
  }

  double _stageProgress(String stage) {
    return switch (stage) {
      'at_pickup' => 0.25,
      'in_transit' => 0.55,
      'delivered' => 0.75,
      'pod_uploaded' => 0.9,
      'completed' => 1.0,
      _ => 0.15,
    };
  }

  List<String> _timelineLabels(AppLocalizations l10n) {
    return [
      l10n.tripTimelinePickup,
      l10n.tripTimelineTransit,
      l10n.tripTimelineDelivered,
      l10n.tripTimelinePodUploaded,
      l10n.tripTimelineCompleted,
    ];
  }
}
