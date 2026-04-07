import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/lifecycle_timeline.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/trips_providers.dart';
import '../widgets/index.dart';
import 'trip_detail_controller.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    final user = ref.watch(authSessionProvider).value?.session?.user;
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripDetailTitle),
        actions: [
          if (user != null && role.isNotEmpty)
            IconButton(
              onPressed: () async {
                final controller = TripDetailController(
                  ref: ref,
                  context: context,
                );
                await controller.triggerSos(tripId);
              },
              icon: const Icon(Icons.emergency),
              tooltip: l10n.tripEmergencySosAction,
            ),
        ],
      ),
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(l10n.tripLoadError),
        ),
        data: (trip) {
          final load = trip?['load'] as Map<String, dynamic>?;
          final route = trip?['route'] as Map<String, dynamic>?;
          final lifecycle = trip?['lifecycle'] as List<dynamic>?;
          final lrUrl = trip?['lr_url'] as String?;
          final podUrl = trip?['pod_url'] as String?;
          final status = (trip?['trip_status'] ?? '').toString();
          final isSupplier = role == 'supplier';

          if (trip == null || load == null) {
            return Center(
              child: Text(l10n.tripLoadError),
            );
          }

          final controller = TripDetailController(
            ref: ref,
            context: context,
          );

          return ScreenScrollContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TtsAnnounce(
                  text: l10n.tripDetailScreenTtsContext(
                    (load['origin_city'] ?? '').toString(),
                    (load['dest_city'] ?? '').toString(),
                    _stageLabelForContext(l10n, status),
                    _nextActionLabel(l10n, status, isSupplier),
                  ),
                ),
                Container(
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  '${load['material'] ?? '-'} · ${_weightText(load)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          StatusBadge.fromTripStage(context, status),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _priceText(load),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (_routeSummaryText(l10n, route).isNotEmpty)
                            Flexible(
                              child: Text(
                                _routeSummaryText(l10n, route),
                                textAlign: TextAlign.end,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (_showsActionSection(status, isSupplier)) ...[
                  ActionCard(
                    title: _nextActionLabel(l10n, status, isSupplier),
                    child: _buildActionButtons(status, tripId, isSupplier),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                        // Load Details Card
                        ActionCard(
                          title: l10n.tripSnapshotTitle,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(
                                l10n.loadDetailTitle,
                                load['load_id']?.toString() ?? '-',
                              ),
                              _buildDetailRow(
                                l10n.postLoadMaterialLabel,
                                load['material']?.toString() ?? '-',
                              ),
                              _buildDetailRow(
                                l10n.tripSnapshotWeight,
                                _weightText(load),
                              ),
                              _buildDetailRow(
                                l10n.tripSnapshotTruck,
                                (trip['truck']?['truck_number'] ?? load['truck_type'] ?? '-')
                                    .toString(),
                              ),
                              _buildDetailRow(
                                l10n.tripSnapshotPrice,
                                _priceText(load),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Route Details Card
                        if (route != null) ...[
                          ActionCard(
                            title: l10n.tripRouteToolsTitle,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  l10n.postLoadOriginCityLabel,
                                  route['origin_city']?.toString() ?? '-',
                                ),
                                _buildDetailRow(
                                  l10n.postLoadDestinationCityLabel,
                                  route['dest_city']?.toString() ?? '-',
                                ),
                                _buildDetailRow(
                                  l10n.tripSnapshotDistance,
                                  '${route['distance_km'] ?? '-'} km',
                                ),
                                _buildDetailRow(
                                  l10n.activeTripStatus,
                                  _routeSummaryText(l10n, route),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => controller.openNavigation(load),
                                    icon: const Icon(Icons.navigation),
                                    label: Text(l10n.tripOpenNavigationAction),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Status Badge
                        if (lifecycle != null && lifecycle.isNotEmpty) ...[
                          ActionCard(
                            title: l10n.activeTripStatus,
                            child: LifecycleTimeline(
                              stages: lifecycle.map((e) => e['stage'].toString()).toList(),
                              currentStageIndex: lifecycle.indexWhere((e) => e['stage'] == status),
                              stageLabels: lifecycle.map((e) => e['title'].toString()).toList(),
                              stageIcons: lifecycle.map((e) => _getStageIcon(e['stage'].toString())).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Document Uploads
                        ActionCard(
                          title: l10n.addTruckDocumentsSection,
                          child: Column(
                            children: [
                              SnapshotRow(
                                label: 'LR',
                                imageUrl: lrUrl,
                                onTap: lrUrl != null
                                    ? () => _showFullScreenImage(context, lrUrl)
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SnapshotRow(
                                label: 'POD',
                                imageUrl: podUrl,
                                onTap: podUrl != null
                                    ? () => _showFullScreenImage(context, podUrl)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // POD Uploaded Waiting Section
                        if (status == 'pod_uploaded')
                          const PodUploadedWaitingSection(),

                        // Rating Section
                        if (status == 'completed' &&
                            load['supplier_id'] != null &&
                            load['trucker_id'] != null)
                          RatingSection(
                            loadId: load['id'].toString(),
                            supplierId: load['supplier_id'].toString(),
                            truckerId: load['trucker_id'].toString(),
                          ),
                        const SizedBox(height: AppSpacing.md),

                        // Action Buttons
                        if (!_showsActionSection(status, isSupplier))
                          _buildActionButtons(status, tripId, isSupplier),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _weightText(Map<String, dynamic> load) {
    final weight = CoordinateUtils.parseDouble(
      load['weight_tonnes'] ?? load['weight_tons'],
    );
    if (weight == null) {
      return '-';
    }
    if (weight == weight.roundToDouble()) {
      return '${weight.toStringAsFixed(0)}T';
    }
    return '${weight.toStringAsFixed(1)}T';
  }

  String _priceText(Map<String, dynamic> load) {
    final price = CoordinateUtils.parseDouble(load['price']);
    if (price == null) {
      return '₹-';
    }
    return '₹${price.toStringAsFixed(0)}';
  }

  String _routeSummaryText(
    AppLocalizations l10n,
    Map<String, dynamic>? route,
  ) {
    if (route == null) {
      return '';
    }
    final km = CoordinateUtils.parseDouble(route['distance_km']);
    final hours = CoordinateUtils.parseDouble(route['estimated_hours']);
    if (km == null || hours == null) {
      return '';
    }
    return l10n.postLoadApproxRouteInfo(
      km.toStringAsFixed(0),
      hours.toStringAsFixed(hours == hours.roundToDouble() ? 0 : 1),
    );
  }

  IconData _getStageIcon(String stage) {
    switch (stage) {
      case 'assigned':
        return Icons.assignment;
      case 'at_pickup':
        return Icons.location_on;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.circle;
    }
  }

  bool _showsActionSection(String status, bool isSupplier) {
    if (isSupplier) {
      return false;
    }
    return status == 'assigned' ||
        status == 'in_transit' ||
        status == 'delivered';
  }

  String _stageLabelForContext(AppLocalizations l10n, String stage) {
    return switch (stage) {
      'assigned' => l10n.tripApprovedPrefix,
      'at_pickup' => l10n.tripTimelinePickup,
      'in_transit' => l10n.tripTimelineTransit,
      'delivered' => l10n.tripTimelineDelivered,
      'pod_uploaded' => l10n.tripTimelinePodUploaded,
      'completed' => l10n.tripTimelineCompleted,
      _ => stage,
    };
  }

  String _nextActionLabel(
    AppLocalizations l10n,
    String stage,
    bool isSupplier,
  ) {
    if (isSupplier) {
      return l10n.tripRouteToolsTitle;
    }
    return switch (stage) {
      'assigned' => l10n.tripStartAction,
      'at_pickup' => l10n.tripPickupActions,
      'in_transit' => l10n.tripTransitAction,
      'delivered' => l10n.tripDeliveryProof,
      'pod_uploaded' => l10n.tripPodUploadedWaiting,
      'completed' => l10n.tripYourRatingPrefix,
      _ => l10n.tripRouteToolsTitle,
    };
  }

  Widget _buildActionButtons(String status, String tripId, bool isSupplier) {
    switch (status) {
      case 'assigned':
        if (!isSupplier) {
          return StartTripAction(tripId: tripId);
        }
        break;
      case 'in_transit':
        if (!isSupplier) {
          return Column(
            children: [
              UploadLrAction(tripId: tripId),
              const SizedBox(height: AppSpacing.sm),
              MarkDeliveredAction(tripId: tripId),
            ],
          );
        }
        break;
      case 'delivered':
        if (!isSupplier) {
          return UploadPodAction(tripId: tripId);
        }
        break;
    }
    return const SizedBox.shrink();
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        );
      },
    );
  }
}
