import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/image_picker_util.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/trips_providers.dart';

class UploadLrAction extends ConsumerWidget {
  final String tripId;

  const UploadLrAction({super.key, required this.tripId});

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

class MarkDeliveredAction extends ConsumerWidget {
  final String tripId;

  const MarkDeliveredAction({super.key, required this.tripId});

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
            },
    );
  }
}

class UploadPodAction extends ConsumerWidget {
  final String tripId;

  const UploadPodAction({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
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
            },
    );
  }
}
