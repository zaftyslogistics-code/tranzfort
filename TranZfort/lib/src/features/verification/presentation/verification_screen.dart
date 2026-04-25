import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/navigation/app_routes.dart';
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
import '../../trucker/providers/trucker_fleet_provider.dart';
import '../data/verification_repository.dart';
import '../providers/verification_provider.dart';
import '../presentation/components/city_search_sheet.dart';
import 'verification_wizard.dart';

part 'verification_screen_sections.dart';

class VerificationScreen extends ConsumerWidget {
  const VerificationScreen({super.key});

  static Future<ImageSource?> selectImageSource(BuildContext context, String documentLabel) {
    return _selectImageSource(context, documentLabel);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verificationProvider);
    final detail = state.detail;

    // Show wizard for unverified or rejected users
    if (detail != null && (detail.isUnverified || detail.isRejected)) {
      return const VerificationWizard();
    }

    return DetailPageScaffold(
      title: detail == null
          ? l10n.verificationTitle
          : detail.isSupplier
              ? l10n.verificationTitleSupplier
              : l10n.verificationTitleTrucker,
      children: [
        if (state.isLoading && detail == null)
          const LoadingShimmer(height: 104, itemCount: 3)
        else if (!state.isLoading && state.failure != null && detail == null)
          WarningBlock(
            title: l10n.verificationLoadFailureTitle,
            message: l10n.verificationLoadFailureMessage,
            action: OutlineButton(
              label: l10n.commonRetryAction,
              onPressed: () => ref.read(verificationProvider.notifier).load(),
            ),
          )
        else if (!state.isLoading && detail == null)
          EmptyStateView(
            icon: Icons.verified_user_outlined,
            title: l10n.verificationDetailsUnavailableTitle,
            subtitle: l10n.verificationDetailsUnavailableSubtitle,
            actionLabel: l10n.commonRetryAction,
            onAction: () => ref.read(verificationProvider.notifier).load(),
          )
        else if (detail != null) ...[
          _VerificationBannerSection(detail: detail),
          if (detail.isRejected && (detail.rejectionReason ?? '').trim().isNotEmpty)
            WarningBlock(
              title: l10n.verificationLatestRejectionReasonTitle,
              message: _buildRejectionSummary(l10n, detail),
            ),
          if (detail.isRejected && (detail.reviewFeedback.nextStep ?? '').trim().isNotEmpty)
            WarningBlock(
              title: l10n.commonNextStepTitle,
              message: detail.reviewFeedback.nextStep!,
            ),
          if (state.actionFailure != null)
            WarningBlock(
              title: l10n.verificationActionNeedsAttentionTitle,
              message: l10n.verificationActionFailureMessage,
            ),
          if (detail.isPending)
            DetailSectionCard(
              title: l10n.commonWhatHappensNextTitle,
              children: [
                Text(
                  l10n.verificationWhatHappensNextMessage,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                TimelineBlock(
                  events: [
                    TimelineEvent(
                      title: l10n.verificationTimelinePacketSubmittedTitle,
                      timestamp: l10n.commonCompletedLabel,
                      description: l10n.verificationTimelinePacketSubmittedDescription,
                    ),
                    TimelineEvent(
                      title: l10n.verificationTimelineReviewInProgressTitle,
                      timestamp: l10n.verificationTimelineReviewInProgressTimestamp,
                      description: l10n.verificationTimelineReviewInProgressDescription,
                    ),
                    TimelineEvent(
                      title: l10n.verificationTimelineNotifiedTitle,
                      timestamp: l10n.verificationTimelineNotifiedTimestamp,
                      description: l10n.verificationTimelineNotifiedDescription,
                    ),
                  ],
                ),
              ],
            ),
          DetailSectionCard(
            title: detail.isTrucker
                ? 'Step 1: Identity Details'
                : l10n.verificationPacketDetailsSectionTitle,
            children: [
              _VerificationPacketFieldsSection(detail: detail),
            ],
          ),
          if (detail.isSupplier) ...[
            DetailSectionCard(
              title: l10n.verificationLocationTitle,
              children: [
                StandardListCard(
                  accent: detail.hasVerificationLocation ? AppColors.success : AppColors.warning,
                  title: detail.hasVerificationLocation
                      ? l10n.verificationLocationCapturedTitle
                      : l10n.verificationLocationRequiredTitle,
                  subtitle: detail.hasVerificationLocation
                      ? _formatVerificationLocation(detail)
                      : l10n.verificationLocationRequiredMessage,
                  trailing: StatusChip(
                    label: detail.hasVerificationLocation
                        ? l10n.verificationLocationCapturedStatus
                        : l10n.verificationLocationRequiredStatus,
                  ),
                  footer: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.hasVerificationLocation
                            ? l10n.verificationLocationCapturedFooter
                            : l10n.verificationLocationCaptureGuidanceFooter,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (!detail.isPending && !detail.isVerified) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            OutlineButton(
                              label: detail.hasVerificationLocation
                                  ? l10n.verificationRefreshLocationAction
                                  : l10n.verificationCaptureLocationAction,
                              isLoading: state.isCapturingLocation,
                              onPressed: state.isCapturingLocation
                                  ? null
                                  : () async {
                                      final result = await ref.read(verificationProvider.notifier).captureSupplierLocation();
                                      if (!context.mounted) {
                                        return;
                                      }

                                      // Handle typed location failures with specific dialogs
                                      final failure = result.failureOrNull;
                                      if (failure is LocationServiceDisabledFailure) {
                                        final shouldOpen = await _showGpsDisabledDialog(context);
                                        if (shouldOpen && context.mounted) {
                                          await Geolocator.openLocationSettings();
                                          // Auto-retry after user returns from settings
                                          if (context.mounted) {
                                            final retryResult = await ref.read(verificationProvider.notifier).captureSupplierLocation();
                                            if (context.mounted) {
                                              AppSnackbar.show(
                                                context: context,
                                                message: retryResult.isSuccess
                                                    ? l10n.verificationLocationCapturedSuccess
                                                    : l10n.verificationLocationFailureMessage,
                                                variant: retryResult.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                              );
                                            }
                                          }
                                        }
                                      } else if (failure is LocationPermissionDeniedForeverFailure) {
                                        final shouldOpen = await _showPermissionDeniedForeverDialog(context);
                                        if (shouldOpen && context.mounted) {
                                          await Geolocator.openAppSettings();
                                          // Auto-retry after user returns from settings
                                          if (context.mounted) {
                                            final retryResult = await ref.read(verificationProvider.notifier).captureSupplierLocation();
                                            if (context.mounted) {
                                              AppSnackbar.show(
                                                context: context,
                                                message: retryResult.isSuccess
                                                    ? l10n.verificationLocationCapturedSuccess
                                                    : l10n.verificationLocationFailureMessage,
                                                variant: retryResult.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                              );
                                            }
                                          }
                                        }
                                      } else {
                                        // Generic success/failure message for other cases
                                        AppSnackbar.show(
                                          context: context,
                                          message: result.isSuccess
                                              ? l10n.verificationLocationCapturedSuccess
                                              : l10n.verificationLocationFailureMessage,
                                          variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                        );
                                      }
                                    },
                            ),
                            OutlineButton(
                              label: l10n.verificationManualLocationAction,
                              onPressed: state.isCapturingLocation
                                  ? null
                                  : () async {
                                      final manualLocation = await _showManualLocationDialog(
                                        context,
                                        onUseCurrentLocation: () async {
                                          // Trigger GPS capture flow when user taps "Use Current Location"
                                          final result = await ref.read(verificationProvider.notifier).captureSupplierLocation();
                                          if (context.mounted) {
                                            AppSnackbar.show(
                                              context: context,
                                              message: result.isSuccess
                                                  ? l10n.verificationLocationCapturedSuccess
                                                  : l10n.verificationLocationFailureMessage,
                                              variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                            );
                                          }
                                        },
                                      );
                                      if (manualLocation == null || !context.mounted) {
                                        return;
                                      }
                                      final result = await ref.read(verificationProvider.notifier).saveManualSupplierLocation(
                                            city: manualLocation.city,
                                            stateProvince: manualLocation.state,
                                          );
                                      if (!context.mounted) {
                                        return;
                                      }
                                      AppSnackbar.show(
                                        context: context,
                                        message: result.isSuccess
                                            ? l10n.verificationLocationCapturedSuccess
                                            : l10n.verificationLocationFailureMessage,
                                        variant: result.isSuccess ? AppSnackbarVariant.success : AppSnackbarVariant.error,
                                      );
                                    },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            DetailSectionCard(
              title: l10n.verificationDocumentChecklistTitle,
              children: [
                for (var index = 0; index < detail.visibleDocuments.length; index++) ...[
                  if (detail.visibleDocuments[index] != VerificationDocumentType.truckRc &&
                      detail.visibleDocuments[index] != VerificationDocumentType.truckPhoto)
                    _VerificationDocumentCard(
                      detail: detail,
                      type: detail.visibleDocuments[index],
                      isUploading: state.uploadingDocumentType == detail.visibleDocuments[index],
                      onUploadRequested: detail.isPending || detail.isVerified
                          ? null
                          : () async {
                              final source = await _selectImageSource(
                                context,
                                _localizedDocumentTypeLabel(l10n, detail.visibleDocuments[index]),
                              );
                              if (source == null || !context.mounted) {
                                return;
                              }
                              final result = await ref.read(verificationProvider.notifier).uploadDocument(
                                    type: detail.visibleDocuments[index],
                                    source: source,
                                  );
                              if (!context.mounted) {
                                return;
                              }
                              if (result.isSuccess && result.valueOrNull != true) {
                                return;
                              }
                              AppSnackbar.show(
                                context: context,
                                message: result.isSuccess
                                    ? l10n.verificationDocumentUploadedSuccess(
                                        _localizedDocumentTypeLabel(l10n, detail.visibleDocuments[index]),
                                      )
                                    : l10n.verificationDocumentUploadFailureMessage,
                                variant: result.isSuccess
                                    ? AppSnackbarVariant.success
                                    : AppSnackbarVariant.error,
                              );
                            },
                    ),
                  if (index != detail.visibleDocuments.length - 1) const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ],
          if (detail.isTrucker)
            TruckerInlineTruckSection(detail: detail),
          _VerificationSubmitSection(detail: detail, state: state),
        ],
      ],
    );
  }

  static Future<ImageSource?> _selectImageSource(BuildContext context, String documentLabel) {
    final l10n = AppLocalizations.of(context);
    return showAppBottomSheet<ImageSource>(
      context: context,
      title: l10n.verificationUploadSourceTitle(documentLabel),
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

  static String _formatVerificationLocation(VerificationDetail detail) {
    final state = (detail.verificationLocationState ?? '').trim();
    final city = (detail.verificationLocationCity ?? '').trim();
    if (state.isNotEmpty) {
      return '$city, $state';
    }
    return city;
  }

  static Future<_ManualLocationInput?> _showManualLocationDialog(
    BuildContext context, {
    VoidCallback? onUseCurrentLocation,
  }) async {
    // Use CitySearchSheet for autocomplete location selection from JSON database
    final result = await showModalBottomSheet<TruckerCitySuggestion>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CitySearchSheet(
        onCitySelected: (city) => Navigator.pop(context, city),
        onUseCurrentLocation: onUseCurrentLocation,
      ),
    );

    if (result == null) return null;

    return _ManualLocationInput(
      city: result.city,
      state: result.state.isEmpty ? null : result.state,
    );
  }

  static String _buildRejectionSummary(AppLocalizations l10n, VerificationDetail detail) {
    final summary = (detail.reviewFeedback.summary ?? detail.rejectionReason ?? '').trim();
    if (detail.reviewFeedback.hasDocumentFeedback) {
      return l10n.verificationRejectionSummaryWithMarkers(summary);
    }
    return l10n.verificationRejectionSummaryPacketLevel(summary);
  }

  /// Shows dialog when GPS is disabled, returns true if user wants to open settings
  static Future<bool> _showGpsDisabledDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.verificationGpsDisabledTitle),
        content: Text(l10n.verificationGpsDisabledMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.verificationOpenSettingsAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows dialog when location permission is permanently denied
  static Future<bool> _showPermissionDeniedForeverDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.verificationPermissionDeniedTitle),
        content: Text(l10n.verificationPermissionDeniedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.verificationOpenAppSettingsAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ManualLocationInput {
  final String city;
  final String? state;

  const _ManualLocationInput({required this.city, required this.state});
}

String _localizedDocumentTypeLabel(AppLocalizations l10n, VerificationDocumentType type) {
  return switch (type) {
    VerificationDocumentType.aadhaarFront => l10n.verificationDocTypeAadhaarFront,
    VerificationDocumentType.aadhaarBack => l10n.verificationDocTypeAadhaarBack,
    VerificationDocumentType.pan => l10n.verificationDocTypePan,
    VerificationDocumentType.profilePhoto => l10n.verificationDocTypeProfilePhoto,
    VerificationDocumentType.businessLicence => l10n.verificationDocTypeBusinessLicence,
    VerificationDocumentType.gstCertificate => l10n.verificationDocTypeGstCertificate,
    VerificationDocumentType.truckRc => 'Truck RC',
    VerificationDocumentType.truckPhoto => 'Truck photo',
  };
}

class _VerificationDocumentCard extends StatelessWidget {
  final VerificationDetail detail;
  final VerificationDocumentType type;
  final bool isUploading;
  final Future<void> Function()? onUploadRequested;

  const _VerificationDocumentCard({
    required this.detail,
    required this.type,
    required this.isUploading,
    required this.onUploadRequested,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uploaded = detail.isDocumentUploaded(type);
    final requiredDocument = detail.isDocumentRequired(type);
    final reviewFeedback = detail.reviewFeedback.feedbackFor(type);
    final rejectedByReview = reviewFeedback?.isRejected ?? false;
    String documentStatus;
    if (detail.isPending) {
      documentStatus = 'pending';
    } else if (detail.isVerified) {
      documentStatus = 'verified';
    } else if (rejectedByReview) {
      documentStatus = 'rejected';
    } else if (uploaded) {
      documentStatus = 'uploaded';
    } else if (requiredDocument) {
      documentStatus = 'required';
    } else {
      documentStatus = 'optional';
    }
    final statusLabel = l10n.verificationDocumentStatusValue(documentStatus);

    return StandardListCard(
      accent: statusPaletteFor(statusLabel).foreground,
      title: _localizedDocumentTypeLabel(AppLocalizations.of(context), type),
      subtitle: rejectedByReview
          ? (reviewFeedback?.reason ?? l10n.verificationDocumentCorrectionFallback)
          : uploaded
              ? l10n.verificationDocumentUploadedSubtitle
              : requiredDocument
                  ? l10n.verificationDocumentRequiredSubtitle
                  : l10n.verificationDocumentOptionalSubtitle,
      trailing: StatusChip(label: statusLabel),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rejectedByReview)
            Text(
              l10n.verificationReviewNoteLabel(
                reviewFeedback?.reason ?? l10n.verificationDocumentCorrectionFallback,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (uploaded)
            Text(
              l10n.verificationStoredPathLabel(detail.documentPathFor(type) ?? ''),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (!uploaded && requiredDocument)
            Text(
              l10n.verificationDocumentMissingMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (onUploadRequested != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlineButton(
              label: uploaded
                  ? l10n.verificationReplaceDocumentAction
                  : l10n.verificationUploadDocumentAction,
              isLoading: isUploading,
              onPressed: isUploading ? null : () => onUploadRequested!.call(),
            ),
          ],
        ],
      ),
    );
  }
}
