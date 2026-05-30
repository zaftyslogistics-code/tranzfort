import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/models/domain_statuses.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/services/maps_launcher_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_load_models.dart';
import '../../../features/supplier/providers/load_detail_provider.dart';
import '../../../features/reviews/utils/review_trigger_helper.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../../l10n/tts_localizations.dart';
import '../../tts/data/load_detail_tts_builder.dart';
import '../../../shared/widgets/tts_read_all_button.dart';
import '../../../features/support/providers/support_compose_providers.dart';
import 'shell_components.dart';
import 'supplier_shell_dashboard_sections.dart';
import 'supplier_shell_shared_helpers.dart';

class SupplierLoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const SupplierLoadDetailScreen({
    super.key,
    required this.loadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(loadDetailProvider(loadId));
    final mapsLauncher = ref.watch(mapsLauncherServiceProvider);
    final detail = state.detail;

    if (state.failure != null) {
      AppLogger.warning(
        'Displaying failure warning in LoadDetail UI',
        scope: 'supplier_shell',
        error: state.failure,
      );
    }

    final ttsL10n = detail != null ? TtsLocalizations.of(context) : null;
    final statusLabel = detail != null
        ? localizedSupplierDashboardLoadStatus(l10n, detail.summary.status)
        : '';
    final readAllMessage = detail != null && ttsL10n != null
        ? const LoadDetailTtsBuilder().buildSupplierAll(
            detail: detail,
            tts: ttsL10n,
            ui: l10n,
            statusLabel: statusLabel,
          )
        : null;

    return DetailPageScaffold(
      title: l10n.supplierLoadDetailScreenTitle,
      ttsSummary: readAllMessage,
      ttsScreenKey: 'supplier-load-detail:$loadId',
      children: [
        if (state.isLoading) const LoadingShimmer(height: 120, itemCount: 4),
        if (!state.isLoading && state.failure != null && detail == null)
          _LoadDetailFailureBlock(
            failure: state.failure!,
            onRetry: () => ref.read(loadDetailProvider(loadId).notifier).load(),
          ),
        if (!state.isLoading && detail != null) ...[
              TtsReadAllButton(message: readAllMessage ?? ''),
              const SizedBox(height: AppSpacing.sectionGap),
              HeroActionCard(
                title: '${detail.summary.originLabel} to ${detail.summary.destinationLabel}',
                subtitle: l10n.supplierLoadDetailHeroSubtitle(
                  formatSupplierShortDate(context, detail.summary.pickupDate),
                ),
                useDarkTheme: true,
                useInkGradient: true,
                titleIcon: Icons.local_shipping_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        StatusBadge(
                          label: localizedSupplierDashboardLoadStatus(l10n, detail.summary.status),
                          icon: Icons.local_shipping_outlined,
                        ),
                        if (hasSuperLoadState(
                          isSuperLoad: detail.summary.isSuperLoad,
                          superStatus: detail.summary.superStatus,
                        ))
                          StatusBadge(
                            label: l10n.supplierDashboardSuperLoadBadge(
                              superLoadStatusLabel(
                                l10n,
                                detail.summary.superStatus,
                                isSuperLoad: detail.summary.isSuperLoad,
                              ),
                            ),
                            icon: Icons.workspace_premium_outlined,
                            palette: const StatusPalette(
                              foreground: AppColors.superLoadText,
                              background: AppColors.superLoadBg,
                            ),
                          ),
                        StatusBadge(
                          label: l10n.supplierDashboardTrucksBooked(
                            detail.summary.trucksBooked,
                            detail.summary.trucksNeeded,
                          ),
                          icon: Icons.inventory_2_outlined,
                          palette: const StatusPalette(
                            foreground: AppColors.primary,
                            background: AppColors.neutralBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${detail.summary.material} - ₹${detail.summary.priceAmount.toStringAsFixed(0)} - ${localizedSupplierPriceType(l10n, detail.summary.priceType)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              if (state.failure != null) ...[
                WarningBlock(
                  title: l10n.supplierLoadDetailLinkedExecutionUnavailableTitle,
                  message: l10n.supplierLoadSupportFailureMessage,
                  action: OutlineButton(
                    label: l10n.commonRetryAction,
                    onPressed: () => ref.read(loadDetailProvider(loadId).notifier).load(),
                  ),
                ),
              ],
              DetailSectionCard(
                title: l10n.supplierLoadDetailStatusAndActionsTitle,
                children: [
                  Text(
                    l10n.supplierLoadDetailCurrentStatus(
                      localizedSupplierDashboardLoadStatus(l10n, detail.summary.status),
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.supplierLoadDetailActionsSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (hasSuperLoadState(
                    isSuperLoad: detail.summary.isSuperLoad,
                    superStatus: detail.summary.superStatus,
                  )) ...[
                    const SizedBox(height: AppSpacing.md),
                    SuperLoadStatusBlock(
                      isSuperLoad: detail.summary.isSuperLoad,
                      superStatus: detail.summary.superStatus,
                    ),
                  ],
                  if (state.actionFailure != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    WarningBlock(
                      title: l10n.supplierLoadDetailActionUnavailableTitle,
                      message: l10n.supplierLoadActionFailureMessage,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  if (_canCancel(detail)) ...[
                    DestructiveButton(
                      label: l10n.supplierLoadDetailCancelAction,
                      isLoading: state.isCancelling,
                      onPressed: state.isCancelling
                          ? null
                          : () async {
                              final result = await ref.read(loadDetailProvider(loadId).notifier).cancelLoad();
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackbar.build(
                                  context: context,
                                  message: result.isSuccess
                                      ? l10n.supplierLoadDetailCancelledSuccess
                                      : l10n.supplierLoadCancelFailureMessage,
                                  variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                ),
                              );
                            },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (_canCloseFilledOutsideApp(detail))
                    OutlineButton(
                      label: l10n.supplierLoadDetailCloseFilledOutsideAction,
                      isLoading: state.isClosingFilledOutsideApp,
                      onPressed: state.isClosingFilledOutsideApp
                          ? null
                          : () async {
                              final assignedTruckerId = detail.assignedTruckerId?.trim() ?? '';
                              String? targetUserName;
                              if (assignedTruckerId.isNotEmpty) {
                                for (final booking in state.bookingRequests) {
                                  if (booking.truckerId == assignedTruckerId) {
                                    targetUserName = booking.displayTruckerName;
                                    break;
                                  }
                                }
                              }
                              final result = await ref.read(loadDetailProvider(loadId).notifier).closeFilledOutsideApp();
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                AppSnackbar.build(
                                  context: context,
                                  message: result.isSuccess
                                      ? l10n.supplierLoadDetailClosedFilledOutsideSuccess
                                      : l10n.supplierLoadCloseFailureMessage,
                                  variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                ),
                              );
                              if (result.isSuccess &&
                                  assignedTruckerId.isNotEmpty &&
                                  (targetUserName ?? '').trim().isNotEmpty) {
                                await ReviewTriggerHelper.showLoadClosedReviewPrompt(
                                  context,
                                  ref,
                                  targetUserId: assignedTruckerId,
                                  targetUserName: targetUserName!.trim(),
                                  loadId: detail.summary.id,
                                );
                              }
                            },
                    ),
                  const SizedBox(height: AppSpacing.md),
                  OutlineButton(
                    label: l10n.commonReportSpamOrAbuseAction,
                    onPressed: () => context.push(
                      AppRoutes.reportIssuePath,
                      extra: ReportIssueContext(
                        initialCategory: 'spam_or_scam',
                        relatedLoadId: detail.summary.id,
                        relatedTripId: '',
                        sourceLabel: l10n.reportSourceSupplierLoad('${detail.summary.originLabel} > ${detail.summary.destinationLabel}'),
                      ),
                    ),
                  ),
                ],
              ),
          DetailSectionCard(
            title: l10n.commonRouteAndScheduleTitle,
            ttsMessage: ttsL10n != null
                ? const LoadDetailTtsBuilder().buildSupplierRouteAndPrice(
                    detail: detail,
                    tts: ttsL10n,
                    ui: l10n,
                    statusLabel: statusLabel,
                  )
                : null,
            children: [
              Text(
                l10n.supplierLoadDetailOriginCity(
                  '${detail.originCity}${detail.originState == null ? '' : ', ${detail.originState}'}',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.supplierLoadDetailOriginPoint(detail.summary.originLabel)),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.supplierLoadDetailDestinationCity(
                  '${detail.destinationCity}${detail.destinationState == null ? '' : ', ${detail.destinationState}'}',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.supplierLoadDetailDestinationPoint(detail.summary.destinationLabel)),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.supplierLoadDetailPickupDate(formatSupplierShortDate(context, detail.summary.pickupDate))),
              if (detail.routeDistanceKm != null && detail.routeDurationMinutes != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(l10n.supplierLoadDetailDistance('${detail.routeDistanceKm!.toStringAsFixed(1)} km')),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.supplierLoadDetailDriveTime('${detail.routeDurationMinutes} min')),
              ] else ...[
                const SizedBox(height: AppSpacing.md),
                WarningBlock(
                  title: l10n.supplierLoadDetailRoutePreviewUnavailableTitle,
                  message: l10n.supplierLoadDetailRoutePreviewUnavailableMessage,
                ),
              ],
              if (mapsLauncher.buildDirectionsUri(
                originLat: detail.originLat,
                originLng: detail.originLng,
                destinationLat: detail.destinationLat,
                destinationLng: detail.destinationLng,
                destinationLabel: detail.summary.destinationLabel,
              ) case final mapsUri?) ...[
                const SizedBox(height: AppSpacing.md),
                OutlineButton(
                  label: l10n.commonOpenInGoogleMapsAction,
                  onPressed: () async {
                    await mapsLauncher.launchDirectionsUri(mapsUri);
                  },
                ),
              ],
            ],
          ),
          DetailSectionCard(
            title: l10n.supplierLoadDetailCargoAndRequirementsTitle,
            ttsMessage: ttsL10n != null
                ? const LoadDetailTtsBuilder().buildSupplierMaterialAndTrucks(
                    detail: detail,
                    tts: ttsL10n,
                  )
                : null,
            children: [
              Text(l10n.supplierLoadDetailMaterial(detail.summary.material)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.supplierLoadDetailWeight(
                  '${detail.summary.weightTonnes.toStringAsFixed(detail.summary.weightTonnes % 1 == 0 ? 0 : 1)} tonnes',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.supplierLoadDetailBodyType(detail.summary.requiredBodyType ?? l10n.commonAnyLabel)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.supplierLoadDetailTyres(
                  detail.summary.requiredTyres.isEmpty
                      ? l10n.commonAnyLabel
                      : detail.summary.requiredTyres.join(', '),
                ),
              ),
            ],
          ),
          DetailSectionCard(
            title: l10n.supplierLoadDetailBookingAndTripLinkageTitle,
            children: [
              Text(
                state.bookingRequests.isEmpty
                    ? l10n.supplierLoadDetailBookingLinkageEmptyDescription
                    : l10n.supplierLoadDetailBookingLinkageDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.bookingRequests.isEmpty)
                EmptyStateView(
                  icon: Icons.assignment_outlined,
                  title: l10n.supplierLoadDetailNoBookingRequestsTitle,
                  subtitle: l10n.supplierLoadDetailNoBookingRequestsSubtitle,
                )
              else
                Column(
                  children: [
                    for (var index = 0; index < state.bookingRequests.length; index++) ...[
                      BookingRequestCard(
                        booking: state.bookingRequests[index],
                        isApproving: state.approvingBookingId == state.bookingRequests[index].id,
                        isRejecting: state.rejectingBookingId == state.bookingRequests[index].id,
                        onApprove: state.bookingRequests[index].isSubmitted
                            ? () async {
                                final confirmed = await _confirmApproveBooking(
                                  context,
                                  detail.summary,
                                );
                                if (confirmed != true || !context.mounted) {
                                  return;
                                }

                                final result = await ref.read(loadDetailProvider(loadId).notifier).approveBookingRequest(
                                      state.bookingRequests[index].id,
                                    );
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppSnackbar.build(
                                    context: context,
                                    message: result.isSuccess
                                        ? l10n.supplierBookingApprovedSuccessMessage
                                        : l10n.supplierLoadApproveBookingFailureMessage,
                                    variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                  ),
                                );
                              }
                            : null,
                        onReject: state.bookingRequests[index].isSubmitted
                            ? () async {
                                final reason = await _promptRejectReason(
                                  context,
                                  state.bookingRequests[index],
                                );
                                if (reason == null || !context.mounted) {
                                  return;
                                }

                                final result = await ref.read(loadDetailProvider(loadId).notifier).rejectBookingRequest(
                                      state.bookingRequests[index].id,
                                      reason: reason,
                                    );
                                if (!context.mounted) {
                                  return;
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  AppSnackbar.build(
                                    context: context,
                                    message: result.isSuccess
                                        ? l10n.supplierBookingRejectedSuccessMessage
                                        : l10n.supplierLoadRejectBookingFailureMessage,
                                    variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                  ),
                                );
                              }
                            : null,
                      ),
                      if (index != state.bookingRequests.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.supplierLoadDetailLinkedTripsTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              if (state.linkedTrips.isEmpty)
                EmptyStateView(
                  icon: Icons.alt_route_outlined,
                  title: l10n.supplierLoadDetailNoLinkedTripsTitle,
                  subtitle: l10n.supplierLoadDetailNoLinkedTripsSubtitle,
                )
              else
                Column(
                  children: [
                    for (var index = 0; index < state.linkedTrips.length; index++) ...[
                      LinkedTripCard(trip: state.linkedTrips[index]),
                      if (index != state.linkedTrips.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
            ],
          ),
          DetailSectionCard(
            title: l10n.supplierLoadDetailActivityTimelineTitle,
            children: [
              TimelineBlock(
                events: [
                  TimelineEvent(
                    title: l10n.supplierLoadDetailTimelineCreatedTitle,
                    timestamp: formatSupplierDateTime(context, detail.createdAt),
                    description: l10n.supplierLoadDetailTimelineCreatedDescription,
                  ),
                  if (detail.summary.publishedAt != null)
                    TimelineEvent(
                      title: l10n.supplierLoadDetailTimelinePublishedTitle,
                      timestamp: formatSupplierDateTime(context, detail.summary.publishedAt!),
                      description: l10n.supplierLoadDetailTimelinePublishedDescription,
                    ),
                  TimelineEvent(
                    title: l10n.supplierLoadDetailTimelineUpdatedTitle,
                    timestamp: formatSupplierDateTime(context, detail.updatedAt),
                    description: l10n.supplierLoadDetailTimelineUpdatedDescription(
                      localizedSupplierDashboardLoadStatus(l10n, detail.summary.status),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _canCancel(LoadDetail detail) {
    final status = LoadStatus.fromDatabase(detail.summary.status);
    return status == LoadStatus.active ||
        status == LoadStatus.assignedPartial ||
        status == LoadStatus.assignedFull;
  }

  bool _canCloseFilledOutsideApp(LoadDetail detail) {
    final status = LoadStatus.fromDatabase(detail.summary.status);
    return status == LoadStatus.active ||
        status == LoadStatus.assignedPartial ||
        status == LoadStatus.assignedFull;
  }

  Future<bool?> _confirmApproveBooking(
    BuildContext context,
    Load load,
  ) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.supplierBookingApproveDialogTitle),
        content: Text(
          l10n.supplierBookingApproveDialogMessage(
            load.material,
            load.originLabel,
            load.destinationLabel,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancelAction),
          ),
          PrimaryButton(
            label: l10n.chatActionApprove,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRejectReason(
    BuildContext context,
    LoadBookingRequest booking,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: booking.decisionReason ?? '');
    try {
      return await showDialog<String?>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.supplierBookingRejectDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.supplierBookingRejectDialogSubtitle),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: l10n.supplierBookingRejectReasonLabel,
                  hintText: l10n.supplierBookingRejectReasonHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(l10n.commonCancelAction),
            ),
            PrimaryButton(
              label: l10n.chatActionReject,
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }
}

class _LoadDetailFailureBlock extends StatelessWidget {
  final AppFailure failure;
  final VoidCallback onRetry;

  const _LoadDetailFailureBlock({
    required this.failure,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (failure is NotFoundFailure) {
      return EmptyStateView(
        icon: Icons.inventory_2_outlined,
        title: l10n.supplierLoadDetailNotFoundTitle,
        subtitle: l10n.supplierLoadDetailNotFoundSubtitle,
        actionLabel: l10n.commonRetryAction,
        onAction: () => context.go(AppRoutes.myLoadsPath),
      );
    }

    return WarningBlock(
      title: l10n.supplierLoadDetailLoadFailureTitle,
      message: l10n.supplierLoadDetailFailureMessage,
      action: OutlineButton(label: l10n.commonRetryAction, onPressed: onRetry),
    );
  }
}
