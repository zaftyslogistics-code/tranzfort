import 'package:flutter/material.dart';

import '../../../../core/theme/admin_colors.dart';

Future<bool> showAdminVerificationApproveDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => const _AdminVerificationApproveDialog(),
  ).then((value) => value == true);
}

class _AdminVerificationApproveDialog extends StatefulWidget {
  const _AdminVerificationApproveDialog();

  @override
  State<_AdminVerificationApproveDialog> createState() => _AdminVerificationApproveDialogState();
}

class _AdminVerificationApproveDialogState extends State<_AdminVerificationApproveDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Platform access review'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You are granting marketplace access after an internal document review. '
              'This is not government KYC, employment verification, or a guarantee of '
              'counterparty payment or delivery performance.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: (value) => setState(() => _acknowledged = value == true),
              title: const Text(
                'I confirm this approval is platform access review only and the user must still verify counterparties off-platform.',
                style: TextStyle(fontSize: 14),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _acknowledged ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: AdminColors.success),
          child: const Text('Approve access'),
        ),
      ],
    );
  }
}
