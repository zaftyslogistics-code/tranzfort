import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Dialog for adding a one-time reply to a review.
class ReplyDialog extends StatefulWidget {
  final String reviewerName;

  const ReplyDialog({
    super.key,
    required this.reviewerName,
  });

  @override
  State<ReplyDialog> createState() => _ReplyDialogState();

  /// Shows the reply dialog and returns the reply text if submitted.
  static Future<String?> show(BuildContext context, {required String reviewerName}) {
    return showDialog<String>(
      context: context,
      builder: (context) => ReplyDialog(reviewerName: reviewerName),
    );
  }
}

class _ReplyDialogState extends State<ReplyDialog> {
  final _controller = TextEditingController();
  int _charCount = 0;
  static const int _maxLength = 500;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _charCount = _controller.text.length;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.replyDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.replyDialogDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            maxLength: _maxLength,
            decoration: InputDecoration(
              hintText: l10n.replyDialogHint(widget.reviewerName),
              border: const OutlineInputBorder(),
              counterText: '$_charCount / $_maxLength',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.replyDialogCancel),
        ),
        FilledButton(
          onPressed: _charCount > 0 ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: Text(l10n.replyDialogSubmit),
        ),
      ],
    );
  }
}
