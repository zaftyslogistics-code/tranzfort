import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/form_inputs.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import '../../shell/presentation/shell_components.dart';
import '../../../core/error/app_failure.dart';
import '../data/trucker_fleet_repository.dart';
import '../providers/trucker_fleet_provider.dart';
import '../providers/trucker_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_routes.dart';

class TruckerFleetScreen extends ConsumerStatefulWidget {
  final bool returnToVerification;

  const TruckerFleetScreen({super.key, this.returnToVerification = false});

  @override
  ConsumerState<TruckerFleetScreen> createState() => _TruckerFleetScreenState();
}

class _TruckerFleetScreenState extends ConsumerState<TruckerFleetScreen> {
  late final TextEditingController _truckNumberController;
  late final TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(truckerFleetProvider);
    _truckNumberController = TextEditingController(text: state.truckNumberDraft);
    _capacityController = TextEditingController(text: state.capacityTonnesDraft);
  }

  @override
  void dispose() {
    _truckNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(truckerFleetProvider);
    _syncControllers(state);

    return DetailPageScaffold(
      title: l10n.commonFleetLabel,
      children: [
        HeroActionCard(
          title: l10n.truckerFleetHeroTitle,
          subtitle: l10n.truckerFleetHeroSubtitle,
          useDarkTheme: true,
          primaryAction: GradientButton(
            label: state.isEditing ? l10n.truckerFleetEditingTruckAction : l10n.truckerFleetAddTruckAction,
            onPressed: () => ref.read(truckerFleetProvider.notifier).startCreate(),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge(
                label: l10n.truckerFleetTruckCount(state.trucks.length),
                icon: Icons.local_shipping_outlined,
              ),
              StatusBadge(
                label: l10n.truckerFleetApprovedCount(
                  state.trucks.where((truck) => truck.status == TruckerFleetTruckStatus.verified).length,
                ),
                icon: Icons.verified_outlined,
                palette: const StatusPalette(
                  foreground: AppColors.success,
                  background: AppColors.successBg,
                ),
              ),
            ],
          ),
        ),
        if (widget.returnToVerification)
          WarningBlock(
            title: l10n.truckerFleetReturnToVerificationTitle,
            message: l10n.truckerFleetReturnToVerificationMessage,
            action: OutlineButton(
              label: l10n.truckerFleetBackToVerificationAction,
              onPressed: () => context.go(AppRoutes.truckerVerificationPath),
            ),
          ),
        if (state.actionFailure != null)
          WarningBlock(
            title: l10n.truckerFleetActionAttentionTitle,
            message: l10n.truckerFleetActionFailureMessage,
          ),
        DetailSectionCard(
          title: state.isEditing ? l10n.truckerFleetEditTruckTitle : l10n.truckerFleetAddOrUpdateTruckTitle,
          children: [
            AppTextField(
              controller: _truckNumberController,
              label: l10n.commonTruckNumberLabel,
              hintText: l10n.truckerFleetTruckNumberHint,
              errorText: state.fieldErrors['truck_number'],
              onChanged: ref.read(truckerFleetProvider.notifier).updateTruckNumber,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String>(
              label: l10n.truckerFleetBodyTypeLabel,
              value: state.bodyTypeDraft,
              items: truckerFleetBodyTypes
                  .map(
                    (bodyType) => DropdownMenuItem<String>(
                      value: bodyType,
                      child: Text(l10n.truckerFleetBodyTypeOption(bodyType)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: ref.read(truckerFleetProvider.notifier).updateBodyType,
            ),
            const SizedBox(height: AppSpacing.md),
            AppDropdown<String>(
              label: l10n.truckerFleetTyresLabel,
              value: state.tyresDraft,
              items: truckerFleetTyreOptions
                  .map((tyres) => DropdownMenuItem<String>(value: '$tyres', child: Text(l10n.truckerFleetTyresOption(tyres))))
                  .toList(growable: false),
              onChanged: ref.read(truckerFleetProvider.notifier).updateTyres,
              helperText: state.fieldErrors['tyres'],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _capacityController,
              label: l10n.truckerFleetCapacityLabel,
              hintText: l10n.truckerFleetCapacityHint,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              errorText: state.fieldErrors['capacity_tonnes'],
              onChanged: ref.read(truckerFleetProvider.notifier).updateCapacityTonnes,
            ),
            const SizedBox(height: AppSpacing.md),
            StandardListCard(
              accent: (state.rcDocumentPathDraft ?? '').trim().isNotEmpty ? AppColors.success : AppColors.warning,
              title: l10n.truckerFleetRcDocumentTitle,
              subtitle: (state.rcDocumentPathDraft ?? '').trim().isNotEmpty
                  ? l10n.truckerFleetRcUploadedSubtitle
                  : l10n.truckerFleetRcRequiredSubtitle,
              trailing: StatusChip(
                label: (state.rcDocumentPathDraft ?? '').trim().isNotEmpty
                    ? l10n.truckerFleetUploadedStatus
                    : l10n.truckerFleetRequiredStatus,
              ),
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((state.rcDocumentPathDraft ?? '').trim().isNotEmpty)
                    Text(
                      l10n.truckerFleetStoredPath(state.rcDocumentPathDraft!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (state.fieldErrors['rc_document_path'] case final rcError?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      rcError,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  OutlineButton(
                    label: (state.rcDocumentPathDraft ?? '').trim().isNotEmpty
                        ? l10n.truckerFleetReplaceRcAction
                        : l10n.truckerFleetUploadRcAction,
                    isLoading: state.isUploadingDocument,
                    onPressed: state.isUploadingDocument
                        ? null
                        : () async {
                            final source = await _selectImageSource(context);
                            if (source == null || !context.mounted) {
                              return;
                            }
                            final result = await ref.read(truckerFleetProvider.notifier).uploadRcDocument(source);
                            if (!context.mounted) {
                              return;
                            }
                            AppSnackbar.show(
                              context: context,
                              message: result.isSuccess
                                  ? ((state.rcDocumentPathDraft ?? '').trim().isEmpty
                                      ? l10n.truckerFleetRcUploadedSuccess
                                      : l10n.truckerFleetRcUpdatedSuccess)
                                  : l10n.truckerFleetRcUploadFailureMessage,
                              variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                            );
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: state.isEditing ? l10n.truckerFleetSaveTruckUpdatesAction : l10n.truckerFleetSaveTruckAction,
                isLoading: state.isSaving,
                onPressed: state.isSaving
                    ? null
                    : () async {
                        final result = await ref.read(truckerFleetProvider.notifier).save();
                        if (!context.mounted) {
                          return;
                        }
                        if (result.isSuccess) {
                          ref.invalidate(truckerProfileProvider);
                          ref.invalidate(truckerDashboardProvider);
                        }
                        final String snackMessage;
                        if (result.isSuccess) {
                          snackMessage = widget.returnToVerification
                              ? l10n.truckerFleetTruckSavedReturnMessage
                              : (state.isEditing ? l10n.truckerFleetTruckUpdatedSuccess : l10n.truckerFleetTruckAddedSuccess);
                        } else if (result.failureOrNull is ConflictFailure) {
                          snackMessage = l10n.truckerFleetTruckNumberConflictMessage;
                        } else {
                          snackMessage = l10n.truckerFleetSaveFailureMessage;
                        }
                        AppSnackbar.show(
                          context: context,
                          message: snackMessage,
                          variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                        );
                      },
              ),
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.truckerFleetMyTrucksTitle,
          children: [
            if (state.isLoading)
              const LoadingShimmer(height: 110, itemCount: 3)
            else if (state.loadFailure != null)
              WarningBlock(
                title: l10n.truckerFleetUnavailableTitle,
                message: l10n.truckerFleetLoadFailureMessage,
                action: OutlineButton(
                  label: l10n.commonRetryAction,
                  onPressed: () => ref.read(truckerFleetProvider.notifier).load(),
                ),
              )
            else if (state.trucks.isEmpty)
              EmptyStateView(
                icon: Icons.local_shipping_outlined,
                title: l10n.truckerFleetNoTrucksTitle,
                subtitle: l10n.truckerFleetNoTrucksSubtitle,
                actionLabel: l10n.truckerFleetAddTruckAction,
                onAction: () => ref.read(truckerFleetProvider.notifier).startCreate(),
              )
            else
              Column(
                children: [
                  for (var index = 0; index < state.trucks.length; index++) ...[
                    _FleetTruckCard(
                      truck: state.trucks[index],
                      onEdit: () => ref.read(truckerFleetProvider.notifier).startEdit(state.trucks[index]),
                    ),
                    if (index != state.trucks.length - 1) const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
          ],
        ),
      ],
    );
  }

  void _syncControllers(TruckerFleetState state) {
    if (_truckNumberController.text != state.truckNumberDraft) {
      _truckNumberController.value = _truckNumberController.value.copyWith(
        text: state.truckNumberDraft,
        selection: TextSelection.collapsed(offset: state.truckNumberDraft.length),
      );
    }
    if (_capacityController.text != state.capacityTonnesDraft) {
      _capacityController.value = _capacityController.value.copyWith(
        text: state.capacityTonnesDraft,
        selection: TextSelection.collapsed(offset: state.capacityTonnesDraft.length),
      );
    }
  }

  Future<ImageSource?> _selectImageSource(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return showAppBottomSheet<ImageSource>(
      context: context,
      title: l10n.truckerFleetSelectRcSourceTitle,
      child: Column(
        children: [
          PrimaryButton(
            label: l10n.commonTakePhotoAction,
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlineButton(
            label: l10n.commonChooseFromGalleryAction,
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

class _FleetTruckCard extends StatelessWidget {
  final TruckerFleetTruck truck;
  final VoidCallback onEdit;

  const _FleetTruckCard({
    required this.truck,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final capacityLabel = truck.capacityTonnes.toStringAsFixed(
      truck.capacityTonnes.truncateToDouble() == truck.capacityTonnes ? 0 : 1,
    );
    return StandardListCard(
      accent: statusPaletteFor(truck.status.databaseValue).foreground,
      title: truck.truckNumber,
      subtitle: l10n.truckerFleetTruckCardSubtitle(
        l10n.truckerFleetBodyTypeOption(truck.bodyType),
        truck.tyres,
        capacityLabel,
      ),
      trailing: StatusChip(label: _truckStatusLabel(l10n, truck.status)),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((truck.modelLabel ?? '').trim().isNotEmpty)
            Text(
              l10n.truckerFleetModelLabel(truck.modelLabel!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _truckStateMessage(truck, l10n),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if ((truck.rejectionReason ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerFleetReviewSummaryLabel(truck.rejectionReason!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if ((truck.reviewFeedback.nextStep ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerFleetNextStepLabel(truck.reviewFeedback.nextStep!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (truck.status.blocksApprovalDependentUse) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.truckerFleetBlockedBookingMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          TextActionButton(
            label: truck.status == TruckerFleetTruckStatus.rejected
                ? l10n.truckerFleetFixResubmitAction
                : l10n.truckerFleetEditTruckAction,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  String _truckStatusLabel(AppLocalizations l10n, TruckerFleetTruckStatus status) {
    return l10n.truckerFleetStatusLabelValue(status.databaseValue);
  }

  String _truckStateMessage(TruckerFleetTruck truck, AppLocalizations l10n) {
    if (truck.status == TruckerFleetTruckStatus.rejected && (truck.reviewFeedback.summary ?? '').trim().isNotEmpty) {
      return truck.reviewFeedback.summary!;
    }
    return l10n.truckerFleetStatusMessageValue(truck.status.databaseValue);
  }
}
