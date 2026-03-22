import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_verification_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_verification_providers.dart';

part 'admin_verification_detail_sections.dart';

class AdminVerificationDetailScreen extends ConsumerStatefulWidget {
  final String caseId;

  const AdminVerificationDetailScreen({super.key, required this.caseId});

  @override
  ConsumerState<AdminVerificationDetailScreen> createState() => _AdminVerificationDetailScreenState();
}

class _AdminVerificationDetailScreenState extends ConsumerState<AdminVerificationDetailScreen> {
  final _rejectionReasonController = TextEditingController();
  final _feedbackSummaryController = TextEditingController();
  final _feedbackNextStepController = TextEditingController();
  final Map<String, TextEditingController> _documentFeedbackControllers = <String, TextEditingController>{};
  String? _syncedCaseId;

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    _feedbackSummaryController.dispose();
    _feedbackNextStepController.dispose();
    for (final controller in _documentFeedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(adminVerificationDetailProvider(widget.caseId));
    final actionState = ref.watch(adminVerificationActionProvider);

    return detailAsync.when(
      data: (detail) {
        if (detail == null) {
          return const Center(child: Text('Verification case not found.'));
        }

        _syncFeedbackControllers(detail);

        return _AdminVerificationDetailContent(
          detail: detail,
          actionState: actionState,
          rejectionReasonController: _rejectionReasonController,
          feedbackSummaryController: _feedbackSummaryController,
          feedbackNextStepController: _feedbackNextStepController,
          documentFeedbackControllers: _documentFeedbackControllers,
          onOpenDocumentPreview: _openDocumentPreview,
          onSubmitDecision: _submitDecision,
          onOpenPath: (path) => context.go(path),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 36, color: AdminColors.error),
              const SizedBox(height: 12),
              const Text('Unable to load verification case details right now.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(adminVerificationDetailProvider(widget.caseId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitDecision({
    required AdminVerificationDetail detail,
    required VerificationReviewDecision decision,
  }) async {
    final rejectionReason = _rejectionReasonController.text.trim();
    if (decision == VerificationReviewDecision.reject && rejectionReason.length < 10) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Enter at least 10 characters so the rejection reason is properly recorded.')),
        );
      return;
    }

    final feedback = decision == VerificationReviewDecision.reject
        ? _buildFeedbackPayload(rejectionReason)
        : null;

    final ok = await ref.read(adminVerificationActionProvider.notifier).submitReviewDecision(
          detail: detail,
          decision: decision,
          reason: rejectionReason,
          feedback: feedback,
        );
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (decision == VerificationReviewDecision.approve
                    ? 'Verification approved successfully.'
                    : 'Verification rejected successfully.')
                : 'Could not update this verification case right now. Try again shortly.',
          ),
        ),
      );
    if (ok) {
      _rejectionReasonController.clear();
      _feedbackSummaryController.clear();
      _feedbackNextStepController.clear();
      for (final controller in _documentFeedbackControllers.values) {
        controller.clear();
      }
      _syncedCaseId = null;
      ref.invalidate(adminVerificationDetailProvider(widget.caseId));
      ref.invalidate(adminVerificationQueueProvider);
    }
  }

  void _syncFeedbackControllers(AdminVerificationDetail detail) {
    if (_syncedCaseId == detail.caseId) {
      return;
    }
    _syncedCaseId = detail.caseId;
    _rejectionReasonController.text = detail.decisionSummary;
    _feedbackSummaryController.text = detail.reviewFeedbackSummary;
    _feedbackNextStepController.text = detail.reviewFeedbackNextStep;

    final activeKeys = detail.documents.map((document) => document.backendKey).toSet();
    final keysToRemove = _documentFeedbackControllers.keys.where((key) => !activeKeys.contains(key)).toList(growable: false);
    for (final key in keysToRemove) {
      _documentFeedbackControllers.remove(key)?.dispose();
    }
    for (final document in detail.documents) {
      final existing = _documentFeedbackControllers[document.backendKey];
      if (existing != null) {
        existing.text = document.feedbackReason;
        continue;
      }
      _documentFeedbackControllers[document.backendKey] = TextEditingController(text: document.feedbackReason);
    }
  }

  VerificationReviewFeedbackPayload _buildFeedbackPayload(String rejectionReason) {
    final documentReasons = <String, String>{};
    for (final entry in _documentFeedbackControllers.entries) {
      final reason = entry.value.text.trim();
      if (reason.isNotEmpty) {
        documentReasons[entry.key] = reason;
      }
    }
    return VerificationReviewFeedbackPayload(
      summary: _feedbackSummaryController.text.trim().isEmpty ? rejectionReason : _feedbackSummaryController.text.trim(),
      nextStep: _feedbackNextStepController.text.trim(),
      documentReasons: documentReasons,
    );
  }

  Future<void> _openDocumentPreview(VerificationDocument document) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.label,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(document.path, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          child: Image.network(
                            document.signedUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Unable to preview this document right now.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
