import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/action_buttons.dart';
import '../../../../shared/widgets/form_inputs.dart';
import '../../data/load_listing_duration.dart';
import '../../data/supplier_load_repost.dart';
import 'post_load_listing_section.dart';

/// Bottom sheet to repost (clone) an off-marketplace load.
Future<String?> showRepostLoadSheet({
  required BuildContext context,
  required String sourceLoadId,
  required Future<Result<String>> Function(RepostLoadRequest request) onSubmit,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _RepostLoadSheet(
      sourceLoadId: sourceLoadId,
      onSubmit: onSubmit,
    ),
  );
}

class _RepostLoadSheet extends ConsumerStatefulWidget {
  final String sourceLoadId;
  final Future<Result<String>> Function(RepostLoadRequest request) onSubmit;

  const _RepostLoadSheet({
    required this.sourceLoadId,
    required this.onSubmit,
  });

  @override
  ConsumerState<_RepostLoadSheet> createState() => _RepostLoadSheetState();
}

class _RepostLoadSheetState extends ConsumerState<_RepostLoadSheet> {
  LoadListingDuration _duration = LoadListingDuration.defaultDuration;
  DateTime _pickupDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.supplierLoadRepostSheetTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          AppDatePicker(
            label: l10n.supplierPostLoadPickupDateLabel,
            value: _pickupDate,
            firstDate: DateTime.now(),
            onChanged: (value) => setState(() => _pickupDate = value),
          ),
          const SizedBox(height: AppSpacing.md),
          PostLoadListingSection(
            selectedDuration: _duration,
            onDurationChanged: (value) => setState(() => _duration = value),
          ),
          const SizedBox(height: AppSpacing.lg),
          GradientButton(
            label: l10n.supplierLoadRepostAction,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    final request = RepostLoadRequest(
                      sourceLoadId: widget.sourceLoadId,
                      pickupDate: DateTime(
                        _pickupDate.year,
                        _pickupDate.month,
                        _pickupDate.day,
                      ),
                      listingDuration: _duration,
                    );
                    final result = await widget.onSubmit(request);
                    if (!context.mounted) {
                      return;
                    }
                    setState(() => _isSubmitting = false);
                    result.when(
                      success: (newLoadId) => Navigator.of(context).pop(newLoadId),
                      failure: (_) => Navigator.of(context).pop(),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
