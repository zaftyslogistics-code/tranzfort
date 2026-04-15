import 'package:flutter/material.dart';

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

    return AlertDialog(
      title: const Text('Reply to Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can reply to this review once. Your response will be visible to everyone who views your profile.',
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
              hintText: 'Write your reply to ${widget.reviewerName}...',
              border: const OutlineInputBorder(),
              counterText: '$_charCount / $_maxLength',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _charCount > 0 ? () => Navigator.of(context).pop(_controller.text.trim()) : null,
          child: const Text('Submit Reply'),
        ),
      ],
    );
  }
}
