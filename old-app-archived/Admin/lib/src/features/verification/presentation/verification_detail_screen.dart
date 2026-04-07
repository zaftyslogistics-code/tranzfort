import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/admin_access_repository.dart';
import '../../../core/repositories/admin_verification_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../shared/widgets/error_retry.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../providers/verification_detail_provider.dart';

class VerificationDetailScreen extends ConsumerStatefulWidget {
  final VerificationEntityType type;
  final String id;

  const VerificationDetailScreen({
    super.key,
    required this.type,
    required this.id,
  });

  @override
  ConsumerState<VerificationDetailScreen> createState() =>
      _VerificationDetailScreenState();
}

class _VerificationDetailScreenState
    extends ConsumerState<VerificationDetailScreen> {
  final _reasonController = TextEditingController();
  final Set<String> _selectedReasonCodes = <String>{};

  static const List<({String code, String label})> _reasonOptions = [
    (
      code: 'document_image_blurry',
      label: 'Document image blurry or unreadable',
    ),
    (code: 'document_number_mismatch', label: 'Document number doesn\'t match'),
    (code: 'document_expired', label: 'Document expired'),
    (code: 'company_name_mismatch', label: 'Company name mismatch'),
    (
      code: 'photo_not_required_document',
      label: 'Photo not of the required document',
    ),
    (code: 'other', label: 'Other (specify)'),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      verificationDetailProvider(
        VerificationDetailArgs(widget.type, widget.id),
      ),
    );
    final actionState = ref.watch(verificationActionProvider);
    final role = ref.watch(currentAdminRoleProvider);
    final isSuperAdmin = adminHasAccess(role, {AdminRole.superAdmin});

    return Scaffold(
      appBar: AppBar(
        title: Text('${verificationTypeLabel(widget.type)} verification'),
      ),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Verification details not found.'));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.cardPadding,
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.pagePadding,
            ),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Text('Verification status: ${detail.status}'),
                      if (detail.rejectionReason.isNotEmpty) ...[
                        const SizedBox(height: AdminDesignTokens.gapSm),
                        Text(
                          'Current rejection reason: ${detail.rejectionReason}',
                          style: const TextStyle(color: AdminColors.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      Table(
                        columnWidths: const {
                          0: FixedColumnWidth(150),
                          1: FlexColumnWidth(),
                        },
                        children: detail.metadata.entries
                            .map(
                              (entry) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AdminDesignTokens.gapSm,
                                    ),
                                    child: Text(
                                      entry.key,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AdminColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AdminDesignTokens.gapSm,
                                    ),
                                    child: Text(
                                      entry.value.isEmpty ? '-' : entry.value,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documents',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapSm),
                      ...detail.documents.map(
                        (doc) => _DocumentTile(document: doc),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              if (isSuperAdmin)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection reason (required to reject)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AdminDesignTokens.gapSm),
                        TextField(
                          controller: _reasonController,
                          minLines: 3,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText:
                                'Example: Aadhaar image is unclear. Please re-upload a clearer copy.',
                          ),
                        ),
                        const SizedBox(height: AdminDesignTokens.gapSm),
                        Text(
                          'Select structured rejection reasons',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: AdminDesignTokens.gapXs),
                        ..._reasonOptions.map(
                          (option) {
                            final selected = _selectedReasonCodes.contains(
                              option.code,
                            );
                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AdminDesignTokens.gapXs,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AdminColors.infoTint
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                    color: selected
                                        ? AdminColors.info
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: CheckboxListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                value: selected,
                                title: Text(option.label),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedReasonCodes.add(option.code);
                                    } else {
                                      _selectedReasonCodes.remove(option.code);
                                    }
                                    _syncReasonFromSelectedCodes();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AdminDesignTokens.sectionGap),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: actionState.isLoading ? null : _reject,
                                child: const Text('Reject verification'),
                              ),
                            ),
                            const SizedBox(width: AdminDesignTokens.gapSm),
                            Expanded(
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: actionState.isLoading
                                    ? null
                                    : _approve,
                                child: actionState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Approve verification'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: AdminColors.infoTint,
                  child: Padding(
                    padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AdminColors.info),
                        const SizedBox(width: AdminDesignTokens.gapSm),
                        Expanded(
                          child: Text(
                            'Read-only view. Contact a Super Admin to approve or reject this verification.',
                            style: TextStyle(color: AdminColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorRetry(
          title: 'Unable to load verification details',
          subtitle: 'Please check your connection and try again.',
          onRetry: () => ref.invalidate(verificationDetailProvider(VerificationDetailArgs(widget.type, widget.id))),
        ),
      ),
    );
  }

  Future<void> _approve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final materialL10n = MaterialLocalizations.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminDesignTokens.cardRadius),
          ),
          surfaceTintColor: AdminColors.surface,
          title: const Text('Approve verification'),
          content: const Text('Are you sure you want to approve this verification?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(materialL10n.cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Approve verification'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final ok = await ref
        .read(verificationActionProvider.notifier)
        .approve(type: widget.type, id: widget.id);
    if (!mounted) return;

    showAppSnackBar(
      context,
      message:
          ok ? 'Verification approved successfully.' : 'Could not approve this verification.',
      type: ok ? SnackbarType.success : SnackbarType.error,
    );
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _reject() async {
    final reason = _reasonController.text.trim();
    final requiresOtherNote = _selectedReasonCodes.contains('other');
    if (requiresOtherNote && reason.toLowerCase().endsWith('other:')) {
      showAppSnackBar(
        context,
        message: 'Please add details for "Other".',
        type: SnackbarType.warning,
      );
      return;
    }

    if (reason.length < 10) {
      showAppSnackBar(
        context,
        message: 'Please enter at least 10 characters for the rejection reason.',
        type: SnackbarType.warning,
      );
      return;
    }

    final ok = await ref
        .read(verificationActionProvider.notifier)
        .reject(
          type: widget.type,
          id: widget.id,
          reason: reason,
          reasonCodes: _selectedReasonCodes.toList(),
        );
    if (!mounted) return;

    showAppSnackBar(
      context,
      message:
          ok ? 'Verification rejected successfully.' : 'Could not reject this verification.',
      type: ok ? SnackbarType.success : SnackbarType.error,
    );
    if (ok) Navigator.of(context).pop();
  }

  void _syncReasonFromSelectedCodes() {
    final selected = _reasonOptions
        .where((option) => _selectedReasonCodes.contains(option.code))
        .toList();
    if (selected.isEmpty) {
      _reasonController.clear();
      return;
    }

    final labels = selected
        .where((option) => option.code != 'other')
        .map((option) => option.label)
        .toList();

    final withOther = _selectedReasonCodes.contains('other');
    final base = labels.join('; ');
    final text = withOther
        ? (base.isEmpty ? 'Other: ' : '$base; Other: ')
        : base;

    _reasonController.text = text;
    _reasonController.selection = TextSelection.fromPosition(
      TextPosition(offset: _reasonController.text.length),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final VerificationDocument document;

  const _DocumentTile({required this.document});

  @override
  Widget build(BuildContext context) {
    final hasUrl = document.url.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: AdminDesignTokens.gapSm),
      child: ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(document.label),
        subtitle: Text(
          hasUrl ? 'Tap to view the uploaded document' : 'No document uploaded',
        ),
        trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
        onTap: hasUrl ? () => _openImage(context, document.url) : null,
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminDesignTokens.cardRadius),
        ),
        surfaceTintColor: AdminColors.surface,
        insetPadding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: SizedBox(
          width: 700,
          height: 560,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Text('Unable to load document preview.'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
