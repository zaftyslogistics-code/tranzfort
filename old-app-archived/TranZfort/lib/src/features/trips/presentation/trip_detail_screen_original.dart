import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../core/utils/coordinate_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/map_navigation_utils.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/lifecycle_timeline.dart';
import '../../../shared/widgets/skeleton_loader.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tts_announce.dart';
import '../../../shared/widgets/screen_scroll_container.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/trips_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  static const _defaultEmergencyContact = '112';

  const TripDetailScreen({super.key, required this.tripId});

  Future<void> _openNavigation(BuildContext context, Map<String, dynamic> load) async {
    final l10n = AppLocalizations.of(context);
    final destination = CoordinateUtils.parseLatLngFromMap(
      load,
      latKey: 'dest_lat',
      lngKey: 'dest_lng',
    );
    if (destination == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tripNavigationUnavailable)),
        );
      }
      return;
    }

    await openGoogleMapsNavigation(
      context: context,
      lat: destination.lat,
      lng: destination.lng,
    );
  }

  Future<void> _openStageNavigation(
    BuildContext context, {
    required double? lat,
    required double? lng,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (lat == null || lng == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tripNavigationUnavailable)),
        );
      }
      return;
    }

    await openGoogleMapsNavigation(context: context, lat: lat, lng: lng);
  }

  Future<void> _triggerEmergencySos(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> load,
  ) async {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.tripEmergencySosPreparing)));

    final captured = await ref.read(locationServiceProvider).captureCurrentLocation();
    if (captured == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.tripEmergencySosLocationUnavailable)),
        );
      }
      return;
    }

    final routeLabel =
        '${load['origin_city'] ?? '-'} -> ${load['dest_city'] ?? '-'}';
    final message = l10n.tripEmergencySosMessage(
      captured.lat.toStringAsFixed(5),
      captured.lng.toStringAsFixed(5),
      routeLabel,
    );

    final smsUri = Uri.parse(
      'sms:$_defaultEmergencyContact?body=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.tripEmergencySosLaunchFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripDetailTitle)),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return Center(child: Text(l10n.tripNotFound));
          }

          final load = (trip['load'] as Map<String, dynamic>? ?? const {});
          final truck = (trip['truck'] as Map<String, dynamic>? ?? const {});
          final stage = (trip['stage'] ?? '').toString();
          final origin = CoordinateUtils.parseLatLngFromMap(
            load,
            latKey: 'origin_lat',
            lngKey: 'origin_lng',
          );
          final destination = CoordinateUtils.parseLatLngFromMap(
            load,
            latKey: 'dest_lat',
            lngKey: 'dest_lng',
          );

          return ScreenScrollContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TtsAnnounce(
                  text: l10n.tripDetailScreenTtsContext(
                    (load['origin_city'] ?? l10n.findLoadsAny).toString(),
                    (load['dest_city'] ?? l10n.findLoadsAny).toString(),
                    _stageLabelForContext(l10n, stage),
                    _nextActionLabel(l10n, stage),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
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
                            '${load['material'] ?? '-'} · ${load['weight_tonnes'] ?? '-'}T',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _stageBadge(context, stage),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
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
                      Text(
                        l10n.tripSnapshotTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _SnapshotRow(
                        label: l10n.tripSnapshotTruck,
                        value: '${truck['truck_number'] ?? '-'}',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _SnapshotRow(
                        label: l10n.tripSnapshotWeight,
                        value: '${load['weight_tonnes'] ?? '-'}T',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _SnapshotRow(
                        label: l10n.tripSnapshotDistance,
                        value: '${load['distance_km'] ?? '-'} km',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _SnapshotRow(
                        label: l10n.tripSnapshotPrice,
                        value:
                            '₹${(load['price'] as num?)?.toStringAsFixed(0) ?? '-'}',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1, color: AppColors.borderDefault),
                      const SizedBox(height: AppSpacing.sm),
                      LifecycleTimeline(
                        stages: _timelineStages,
                        currentStageIndex: _timelineStages.indexOf(stage),
                        stageLabels: _timelineLabels(l10n),
                        stageIcons: _timelineIcons,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionCard(
                title: l10n.tripRouteToolsTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButton(
                            label: l10n.tripViewRoutePreviewAction,
                            onPressed: () =>
                                context.push('/route-preview/${load['id'] ?? ''}'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openNavigation(context, load),
                            child: Text(l10n.tripOpenNavigationAction),
                          ),
                        ),
                      ],
                    ),
                    if (stage == 'at_pickup') ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => _openStageNavigation(
                          context,
                          lat: origin?.lat,
                          lng: origin?.lng,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(l10n.tripNavigateToPickupAction),
                          ],
                        ),
                      ),
                    ],
                    if (stage == 'in_transit') ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(
                        onPressed: () => _openStageNavigation(
                          context,
                          lat: destination?.lat,
                          lng: destination?.lng,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.place_outlined, size: 18),
                            const SizedBox(width: AppSpacing.xs),
                            Text(l10n.tripNavigateToDestinationAction),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (stage == 'at_pickup') ...[
                _ActionCard(
                  title: l10n.tripPickupActions,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UploadLrAction(tripId: tripId),
                      const SizedBox(height: AppSpacing.sm),
                      _StartTripAction(tripId: tripId),
                    ],
                  ),
                ),
              ],
              if (stage == 'in_transit')
                _ActionCard(
                  title: l10n.tripTransitAction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MarkDeliveredAction(tripId: tripId),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: () => _triggerEmergencySos(context, ref, load),
                        icon: const Icon(Icons.sos_outlined),
                        label: Text(l10n.tripEmergencySosAction),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.errorTint,
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              if (stage == 'delivered')
                _ActionCard(
                  title: l10n.tripDeliveryProof,
                  child: _UploadPodAction(tripId: tripId),
                ),
              if (stage == 'pod_uploaded') const _PodUploadedWaitingSection(),
              if (stage == 'completed')
                _RatingSection(
                  loadId: (load['id'] ?? '').toString(),
                  supplierId: (load['supplier_id'] ?? '').toString(),
                  truckerId: (trip['trucker_id'] ?? '').toString(),
                ),
            ],
          ),
        );
        },
        loading: () => SkeletonLoader.list(
          count: 3,
          itemHeight: 128,
        ),
        error: (error, _) => Center(child: Text(l10n.tripLoadError)),
      ),
    );
  }

  Widget _stageBadge(BuildContext context, String stage) {
    return StatusBadge.fromTripStage(context, stage);
  }

  String _stageLabelForContext(AppLocalizations l10n, String stage) {
    return switch (stage) {
      'at_pickup' => l10n.tripTimelinePickup,
      'in_transit' => l10n.tripTimelineTransit,
      'delivered' => l10n.tripTimelineDelivered,
      'pod_uploaded' => l10n.tripTimelinePodUploaded,
      'completed' => l10n.tripTimelineCompleted,
      _ => stage,
    };
  }

  String _nextActionLabel(AppLocalizations l10n, String stage) {
    return switch (stage) {
      'at_pickup' => l10n.tripPickupActions,
      'in_transit' => l10n.tripTransitAction,
      'delivered' => l10n.tripDeliveryProof,
      'pod_uploaded' => l10n.tripPodUploadedWaiting,
      'completed' => l10n.tripYourRatingPrefix,
      _ => l10n.tripRouteToolsTitle,
    };
  }

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

class _PodUploadedWaitingSection extends StatelessWidget {
  const _PodUploadedWaitingSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
            Text(
              l10n.tripPodUploaded,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.tripPodUploadedWaiting,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final String label;
  final String value;

  const _SnapshotRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          value,
          textAlign: TextAlign.right,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ActionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _RatingSection extends ConsumerStatefulWidget {
  final String loadId;
  final String supplierId;
  final String truckerId;

  const _RatingSection({
    required this.loadId,
    required this.supplierId,
    required this.truckerId,
  });

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  int _score = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).value?.session?.user;
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();
    final existingRatingAsync = ref.watch(
      existingRatingProvider(widget.loadId),
    );
    final actionState = ref.watch(tripActionProvider);

    if (user == null || role.isEmpty || widget.loadId.isEmpty) {
      return const SizedBox.shrink();
    }

    return existingRatingAsync.when(
      data: (existingRating) {
        if (existingRating != null) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: const BorderSide(color: AppColors.neutralLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Text(
                '${l10n.tripYourRatingPrefix}: ${existingRating['score'] ?? '-'}★',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        final isSupplier = role == 'supplier';
        final revieweeId = isSupplier ? widget.truckerId : widget.supplierId;
        final revieweeLabel = isSupplier
            ? l10n.chatTruckerFallbackName
            : l10n.chatSupplierFallbackName;

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
                Text(
                  '${l10n.tripRateThisPrefix} $revieweeLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final selected = _score >= star;
                    return IconButton(
                      onPressed: () => setState(() => _score = star),
                      icon: Icon(
                        selected ? Icons.star_rounded : Icons.star_border_rounded,
                        color: selected ? AppColors.secondaryAmber : AppColors.textTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.tripCommentOptional,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: l10n.tripSubmitRating,
                  isLoading: actionState.isLoading,
                  onPressed: actionState.isLoading || revieweeId.isEmpty
                      ? null
                      : () async {
                          final success = await ref
                              .read(tripActionProvider.notifier)
                              .submitRating(
                                loadId: widget.loadId,
                                revieweeId: revieweeId,
                                reviewerRole: role,
                                score: _score,
                                comment: _commentController.text.trim().isEmpty
                                    ? null
                                    : _commentController.text.trim(),
                              );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? l10n.tripRatingSubmitted
                                    : l10n.tripRatingSubmitError,
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}

class _StartTripAction extends ConsumerWidget {
  final String tripId;

  const _StartTripAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
      label: l10n.tripStartAction,
      color: AppColors.success,
      isLoading: actionState.isLoading,
      onPressed: actionState.isLoading
          ? null
          : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.play_circle_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(l10n.tripStartDialogTitle),
                      ],
                    ),
                    content: Text(l10n.tripStartDialogMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.tripCancelAction),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.tripStartAction),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) {
                return;
              }

              final success = await ref
                  .read(tripActionProvider.notifier)
                  .startTrip(tripId);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? l10n.tripStartSuccess : l10n.tripStartError),
                ),
              );
              final tts = ref.read(ttsServiceProvider);
              final notifier = ref.read(tripActionProvider.notifier);
              if (success) {
                final capturedLabel = notifier.lastCapturedLocationLabel;
                final capturedMessage = capturedLabel == null || capturedLabel.isEmpty
                    ? l10n.tripLocationCaptured
                    : l10n.tripLocationCapturedAt(capturedLabel);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(capturedMessage)),
                );
                await tts.speak(l10n.tripStartTtsSuccess);
              } else {
                await tts.speak(l10n.tripStartTtsFailure);
              }
            },
    );
  }
}

class _UploadLrAction extends ConsumerWidget {
  final String tripId;

  const _UploadLrAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
      label: l10n.tripUploadLrOptional,
      isLoading: actionState.isLoading,
      onPressed: actionState.isLoading
          ? null
          : () async {
              final lrFile = await ImagePickerUtil.pickAndCompressImage(
                context: context,
                source: ImageSource.camera,
                quality: 85,
              );
              if (lrFile == null) {
                return;
              }

              final success = await ref
                  .read(tripActionProvider.notifier)
                  .uploadLr(tripId: tripId, lrFile: lrFile);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.tripLrUploadSuccess
                        : l10n.tripLrUploadError,
                  ),
                ),
              );
            },
    );
  }
}

class _MarkDeliveredAction extends ConsumerWidget {
  final String tripId;

  const _MarkDeliveredAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
      label: l10n.tripMarkDelivered,
      color: AppColors.success,
      isLoading: actionState.isLoading,
      onPressed: actionState.isLoading
          ? null
          : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(l10n.tripMarkDeliveredDialogTitle),
                      ],
                    ),
                    content: Text(l10n.tripMarkDeliveredDialogMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(l10n.tripCancelAction),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(l10n.tripConfirmAction),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) {
                return;
              }

              final success = await ref
                  .read(tripActionProvider.notifier)
                  .markDelivered(tripId);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.tripMarkedDeliveredNextPod
                        : l10n.tripMarkDeliveredError,
                  ),
                ),
              );
              final notifier = ref.read(tripActionProvider.notifier);
              if (success) {
                final capturedLabel = notifier.lastCapturedLocationLabel;
                final capturedMessage = capturedLabel == null || capturedLabel.isEmpty
                    ? l10n.tripLocationCaptured
                    : l10n.tripLocationCapturedAt(capturedLabel);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(capturedMessage)),
                );
              }
            },
    );
  }
}

class _UploadPodAction extends ConsumerWidget {
  final String tripId;

  const _UploadPodAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionState = ref.watch(tripActionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.tripUploadProofOfDelivery,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: l10n.tripUploadPodPhoto,
          isLoading: actionState.isLoading,
          onPressed: actionState.isLoading
              ? null
              : () async {
                  final podFile = await ImagePickerUtil.pickAndCompressImage(
                    context: context,
                    source: ImageSource.camera,
                    quality: 85,
                  );
                  if (podFile == null) {
                    return;
                  }

                  final success = await ref
                      .read(tripActionProvider.notifier)
                      .uploadPod(tripId: tripId, podFile: podFile);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? l10n.tripPodUploadSuccessWaiting
                            : l10n.tripPodUploadError,
                      ),
                    ),
                  );
                  final tts = ref.read(ttsServiceProvider);
                  if (success) {
                    await tts.speak(l10n.tripPodUploadTtsSuccess);
                  } else {
                    await tts.speak(l10n.tripPodUploadTtsFailure);
                  }
                },
        ),
      ],
    );
  }
}
