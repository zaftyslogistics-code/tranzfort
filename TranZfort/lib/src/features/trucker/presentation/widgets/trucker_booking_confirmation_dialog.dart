import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../core/theme/app_spacing.dart';

Future<bool> showTruckerBookingConfirmationDialog({
  required BuildContext context,
  required String material,
  required String routeLabel,
  required String truckLabel,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => _TruckerBookingConfirmationDialog(
      material: material,
      routeLabel: routeLabel,
      truckLabel: truckLabel,
    ),
  ).then((value) => value == true);
}

class _TruckerBookingConfirmationDialog extends StatefulWidget {
  final String material;
  final String routeLabel;
  final String truckLabel;

  const _TruckerBookingConfirmationDialog({
    required this.material,
    required this.routeLabel,
    required this.truckLabel,
  });

  @override
  State<_TruckerBookingConfirmationDialog> createState() => _TruckerBookingConfirmationDialogState();
}

class _TruckerBookingConfirmationDialogState extends State<_TruckerBookingConfirmationDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.truckerLoadDetailConfirmBookingTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.truckerLoadDetailConfirmBookingMessage(
                widget.material,
                widget.routeLabel,
                widget.truckLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.truckerBookingOffPlatformPaymentAck,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: (value) => setState(() => _acknowledged = value == true),
              title: Text(
                l10n.truckerBookingAcknowledgementCheckboxLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancelAction),
        ),
        PrimaryButton(
          label: l10n.truckerLoadDetailBookThisLoadAction,
          onPressed: _acknowledged ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}
