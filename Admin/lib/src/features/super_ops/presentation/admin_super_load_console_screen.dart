import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_super_load_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_super_load_providers.dart';

part 'admin_super_load_console_sections.dart';

class AdminSuperLoadConsoleScreen extends ConsumerStatefulWidget {
  const AdminSuperLoadConsoleScreen({super.key});

  @override
  ConsumerState<AdminSuperLoadConsoleScreen> createState() => _AdminSuperLoadConsoleScreenState();
}

class _AdminSuperLoadConsoleScreenState extends ConsumerState<AdminSuperLoadConsoleScreen> {
  final _rejectReasonController = TextEditingController();
  final _dispatchSearchController = TextEditingController();

  @override
  void dispose() {
    _rejectReasonController.dispose();
    _dispatchSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(adminSuperLoadQueueProvider);
    final actionState = ref.watch(adminSuperLoadActionProvider);
    final podReviewAsync = ref.watch(adminSuperLoadPodReviewProvider);

    return queueAsync.when(
      data: (state) => _SuperLoadConsoleBody(
        state: state,
        actionState: actionState,
        podReviewAsync: podReviewAsync,
        onRefresh: () => ref.read(adminSuperLoadQueueProvider.notifier).refresh(),
        onSearchChanged: (value) => ref.read(adminSuperLoadQueueProvider.notifier).updateSearch(value),
        onStatusChanged: (filter) => ref.read(adminSuperLoadQueueProvider.notifier).updateStatusFilter(filter),
        onOpenLoad: (loadId) => context.go(AdminRoutes.loadDetailPathFor(loadId)),
        onOpenUser: (userId) => context.go(AdminRoutes.userDetailPathFor(userId)),
        onMarkUnderReview: _markUnderReview,
        onApprove: _approve,
        onReject: _showRejectDialog,
        onActivate: _activate,
        onShowDispatchDialog: _showDispatchDialog,
        onOpenProofPreview: _openProofPreview,
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const Center(child: Text('Unable to load the Super Load console right now.')),
    );
  }

  Future<void> _markUnderReview(String loadId) async {
    final ok = await ref.read(adminSuperLoadActionProvider.notifier).markUnderReview(loadId);
    _showResult(ok ? 'Super Load moved under review.' : 'Could not update this Super Load right now.');
  }

  Future<void> _approve(String loadId) async {
    final ok = await ref.read(adminSuperLoadActionProvider.notifier).approveRequest(loadId);
    _showResult(ok ? 'Super Load approved and marked payment pending.' : 'Could not approve this Super Load right now.');
  }

  Future<void> _activate(String loadId) async {
    final ok = await ref.read(adminSuperLoadActionProvider.notifier).activateSuperLoad(loadId);
    _showResult(ok ? 'Super Load activated after payment confirmation.' : 'Could not activate this Super Load right now.');
  }

  Future<void> _showRejectDialog(String loadId) async {
    _rejectReasonController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Super Load request'),
        content: TextField(
          key: const ValueKey('super-reject-reason-field'),
          controller: _rejectReasonController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Optional rejection reason',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(
            key: const ValueKey('super-reject-confirm-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final ok = await ref.read(adminSuperLoadActionProvider.notifier).rejectRequest(
          loadId,
          reason: _rejectReasonController.text.trim(),
        );
    _showResult(ok ? 'Super Load request rejected.' : 'Could not reject this Super Load right now.');
  }

  Future<void> _showDispatchDialog(String loadId) async {
    _dispatchSearchController.clear();
    final selected = await showDialog<AdminSuperLoadDispatchCandidate>(
      context: context,
      builder: (context) {
        String search = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Consumer(
              builder: (context, ref, child) {
                final candidatesAsync = ref.watch(adminSuperLoadDispatchCandidatesProvider(search));
                return AlertDialog(
                  title: const Text('Force assign Super Load'),
                  content: SizedBox(
                    width: 560,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          key: const ValueKey('super-dispatch-search-field'),
                          controller: _dispatchSearchController,
                          onChanged: (value) {
                            setDialogState(() {
                              search = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Search trucker or truck',
                            hintText: 'Name, trucker/truck id, mobile, truck number, body type, or status',
                          ),
                        ),
                        const SizedBox(height: 12),
                        candidatesAsync.when(
                          data: (candidates) => SizedBox(
                            height: 240,
                            child: candidates.isEmpty
                                ? const Center(child: Text('No verified trucker/truck matches found.'))
                                : ListView(
                                    children: candidates
                                        .map(
                                          (candidate) => ListTile(
                                            key: ValueKey('super-dispatch-candidate-${candidate.truckId}'),
                                            title: Text('${candidate.truckerName.isEmpty ? 'Trucker' : candidate.truckerName} • ${candidate.truckNumber}'),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${candidate.mobile.isEmpty ? '-' : candidate.mobile} • ${candidate.bodyType.isEmpty ? '-' : candidate.bodyType}'),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Trucker ID ${candidate.truckerId.isEmpty ? '-' : candidate.truckerId}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Truck ID ${candidate.truckId.isEmpty ? '-' : candidate.truckId}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rating ${candidate.rating.isEmpty ? '-' : candidate.rating} • Completed trips ${candidate.completedTrips.isEmpty ? '-' : candidate.completedTrips}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Super trucker ${candidate.superTruckerStatus.isEmpty ? '-' : _titleCaseWords(candidate.superTruckerStatus)}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                                                ),
                                                const SizedBox(height: 8),
                                                Align(
                                                  alignment: Alignment.centerLeft,
                                                  child: OutlinedButton(
                                                    key: ValueKey('super-open-dispatch-trucker-${candidate.truckId}'),
                                                    onPressed: () => context.go(AdminRoutes.userDetailPathFor(candidate.truckerId)),
                                                    child: const Text('Open trucker'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            onTap: () => Navigator.of(context).pop(candidate),
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                          ),
                          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                          error: (error, stackTrace) => const SizedBox(height: 120, child: Center(child: Text('Unable to load dispatch candidates right now.'))),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                  ],
                );
              },
            );
          },
        );
      },
    );
    if (selected == null) {
      return;
    }
    final ok = await ref.read(adminSuperLoadActionProvider.notifier).forceAssignSuperLoad(
          loadId: loadId,
          truckerId: selected.truckerId,
          truckId: selected.truckId,
        );
    _showResult(ok ? 'Super Load force-assigned successfully.' : 'Could not force-assign this Super Load right now.');
  }

  void _showResult(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    ref.invalidate(adminSuperLoadQueueProvider);
  }

  Future<void> _openProofPreview({
    required String title,
    required String? proofUrl,
  }) {
    final normalized = (proofUrl ?? '').trim();
    if (normalized.isEmpty) {
      _showResult('Proof link is not available right now.');
      return Future<void>.value();
    }
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
                          title,
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
                  Text(
                    normalized,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          child: Image.network(
                            normalized,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Unable to preview this proof right now.',
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
