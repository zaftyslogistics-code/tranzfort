import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/tts_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/trips_providers.dart';

class StartTripAction extends ConsumerWidget {
  final String tripId;

  const StartTripAction({super.key, required this.tripId});

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
