import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/splitted/super_ops_models.dart';
import '../../../core/theme/admin_colors.dart';
import '../../../core/theme/admin_design_tokens.dart';
import '../../../core/utils/ist_time.dart';
import '../../../shared/widgets/error_retry.dart';
import '../providers/super_ops_detail_provider.dart';

class SuperOpsLoadDetailScreen extends ConsumerStatefulWidget {
  final String loadId;

  const SuperOpsLoadDetailScreen({super.key, required this.loadId});

  @override
  ConsumerState<SuperOpsLoadDetailScreen> createState() =>
      _SuperOpsLoadDetailScreenState();
}

class _SuperOpsLoadDetailScreenState
    extends ConsumerState<SuperOpsLoadDetailScreen> {
  final _dispatchSearchController = TextEditingController();
  DispatchTruckerCandidate? _selectedTrucker;
  DispatchTruckOption? _selectedTruck;

  @override
  void dispose() {
    _dispatchSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(superOpsLoadDetailProvider(widget.loadId));
    final actionState = ref.watch(superOpsActionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Super load details')),
      body: detailAsync.when(
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Super load not found.'));
          }

          final dispatchQuery = SuperOpsDispatchSearchQuery(
            loadId: detail.id,
            text: _dispatchSearchController.text,
            requiredTruckType: detail.requiredTruckType,
            requiredTyres: detail.requiredTyres,
          );
          final candidateAsync = ref.watch(
            superOpsDispatchCandidatesProvider(dispatchQuery),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.cardPadding,
              AdminDesignTokens.pagePadding,
              AdminDesignTokens.pagePadding,
            ),
            children: [
              _StageSummaryCard(detail: detail),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              if (detail.superStatus == 'requested') ...[
                _RequestActionsCard(
                  loading: actionState.isLoading,
                  onAccept: () => _accept(detail.id),
                  onReject: () => _reject(detail.id),
                ),
                const SizedBox(height: AdminDesignTokens.sectionGap),
              ],
              if ([
                'processing',
                'assigned',
                'in_transit',
              ].contains(detail.superStatus)) ...[
                _DispatchCard(
                  searchController: _dispatchSearchController,
                  candidatesAsync: candidateAsync,
                  selectedTrucker: _selectedTrucker,
                  selectedTruck: _selectedTruck,
                  onSearchChanged: () => setState(() {}),
                  onSelectTrucker: (candidate) {
                    setState(() {
                      _selectedTrucker = candidate;
                      _selectedTruck = null;
                    });
                  },
                  onSelectTruck: (truck) {
                    setState(() => _selectedTruck = truck);
                  },
                  onForceAssign: actionState.isLoading
                      ? null
                      : () => _forceAssign(detail.id),
                ),
                const SizedBox(height: AdminDesignTokens.sectionGap),
              ],
              if (detail.superStatus == 'pod_uploaded') ...[
                _PodReviewCard(
                  detail: detail,
                  loading: actionState.isLoading,
                  onConfirm: () => _confirmPayout(detail.id),
                  onDispute: () => _disputePod(detail.id),
                ),
                const SizedBox(height: AdminDesignTokens.sectionGap),
              ],
              if (!_isActionableStage(detail.superStatus)) ...[
                _ReadOnlyInfoCard(message: _readOnlyMessage(detail.superStatus)),
                const SizedBox(height: AdminDesignTokens.sectionGap),
              ],
              _SectionCard(
                title: 'Load Summary',
                child: _LoadInfoTable(detail: detail),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              _SectionCard(
                title: 'Current Assignments',
                child: detail.assignments.isEmpty
                    ? const Text('No assignments have been created yet.')
                    : Column(
                        children: detail.assignments
                            .map(
                              (a) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(a.truckerName),
                                subtitle: Text('Truck: ${a.truckNumber}'),
                                trailing: Text(
                                  a.childLoadId.substring(0, 8),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: AdminColors.textSecondary,
                                      ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              _SectionCard(
                title: 'Supplier Info',
                child: _SupplierInfoTable(detail: detail),
              ),
              const SizedBox(height: AdminDesignTokens.sectionGap),
              _SectionCard(
                title: 'Payout Info',
                child: _PayoutInfoTable(detail: detail),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorRetry(
          title: 'Unable to load super load detail',
          subtitle: 'Please check your connection and try again.',
          onRetry: () => ref.invalidate(superOpsLoadDetailProvider(widget.loadId)),
        ),
      ),
    );
  }

  Future<void> _accept(String loadId) async {
    final ok = await ref
        .read(superOpsActionProvider.notifier)
        .acceptRequest(loadId);
    if (!mounted) return;
    _toast(
      ok,
      'Request accepted for dispatch.',
      'Could not accept dispatch request.',
    );
  }

  Future<void> _reject(String loadId) async {
    final ok = await ref
        .read(superOpsActionProvider.notifier)
        .rejectRequest(loadId);
    if (!mounted) return;
    _toast(ok, 'Request rejected.', 'Could not reject dispatch request.');
  }

  Future<void> _forceAssign(String loadId) async {
    final trucker = _selectedTrucker;
    final truck = _selectedTruck;
    if (trucker == null || truck == null) {
      _toast(false, '', 'Select both a trucker and a truck before force assignment.');
      return;
    }

    final ok = await ref
        .read(superOpsActionProvider.notifier)
        .forceAssign(
          loadId: loadId,
          truckerId: trucker.truckerId,
          truckId: truck.id,
        );
    if (!mounted) return;
    _toast(ok, 'Force assignment completed.', 'Could not complete force assignment.');
  }

  Future<void> _confirmPayout(String loadId) async {
    final ok = await ref
        .read(superOpsActionProvider.notifier)
        .confirmPayout(loadId);
    if (!mounted) return;
    _toast(
      ok,
      'Marked completed and payout confirmed.',
      'Could not confirm payout.',
    );
  }

  Future<void> _disputePod(String loadId) async {
    final ok = await ref
        .read(superOpsActionProvider.notifier)
        .disputePod(loadId);
    if (!mounted) return;
    _toast(
      ok,
      'POD disputed and moved back to in-transit.',
      'Could not dispute POD.',
    );
  }

  void _toast(bool ok, String success, String fail) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(ok ? success : fail)));
  }

  bool _isActionableStage(String status) {
    return status == 'requested' ||
        status == 'processing' ||
        status == 'assigned' ||
        status == 'in_transit' ||
        status == 'pod_uploaded';
  }

  String _readOnlyMessage(String status) {
    switch (status) {
      case 'completed':
        return 'This load is complete. Review the operational summary and assignment history below.';
      default:
        return 'This load is currently in a review-only stage. Summary and audit information are shown below.';
    }
  }
}

class _StageSummaryCard extends StatelessWidget {
  final SuperOpsLoadDetail detail;

  const _StageSummaryCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final remaining = detail.trucksNeeded - detail.trucksBooked;
    final mode = switch (detail.superStatus) {
      'requested' => 'Action required',
      'processing' || 'assigned' || 'in_transit' => 'Dispatch control',
      'pod_uploaded' => 'POD review required',
      _ => 'Read-only summary',
    };
    final subtitle = switch (detail.superStatus) {
      'requested' => 'Accept or reject this request before dispatch execution continues.',
      'processing' || 'assigned' || 'in_transit' => 'Use dispatch tools below to select a trucker, choose a truck, and complete force assignment.',
      'pod_uploaded' => 'Review uploaded delivery proof and either confirm payout or dispute the POD.',
      _ => 'No direct action is required right now. Review the operational record below.',
    };

    return Card(
      color: AdminColors.brandTealLightMuted,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminDesignTokens.cardRadius),
        side: BorderSide(color: AdminColors.primary.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.routeLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AdminDesignTokens.gapXs),
                      Text(
                        '${detail.material} • ${detail.weightTonnes.toStringAsFixed(1)}T • Supplier ${detail.supplier.fullName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AdminDesignTokens.gapSm),
                _StageBadge(status: detail.superStatus),
              ],
            ),
            const SizedBox(height: AdminDesignTokens.sectionGap),
            Text(
              mode,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AdminColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AdminDesignTokens.gapXs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: AdminDesignTokens.sectionGap),
            Wrap(
              spacing: AdminDesignTokens.gapSm,
              runSpacing: AdminDesignTokens.gapSm,
              children: [
                _Pill(
                  text: '₹${detail.price.toStringAsFixed(0)}',
                  color: AdminColors.primary,
                ),
                _Pill(
                  text: 'Needed ${detail.trucksNeeded}',
                  color: AdminColors.brandOrange,
                ),
                _Pill(
                  text: 'Booked ${detail.trucksBooked}',
                  color: AdminColors.textSecondary,
                ),
                _Pill(
                  text: 'Remaining ${remaining < 0 ? 0 : remaining}',
                  color: remaining <= 0 ? Colors.green : AdminColors.error,
                  backgroundColor: remaining <= 0
                      ? Colors.green.withValues(alpha: 0.12)
                      : null,
                ),
                _Pill(
                  text: 'Pickup ${_formatDate(detail.pickupDate)}',
                  color: AdminColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyInfoCard extends StatelessWidget {
  final String message;

  const _ReadOnlyInfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminColors.infoTint,
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AdminColors.info),
            const SizedBox(width: AdminDesignTokens.gapSm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  final String status;

  const _StageBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final (bg, fg) = switch (normalized) {
      'requested' => (AdminColors.warningTint, AdminColors.brandOrange),
      'processing' || 'assigned' || 'in_transit' => (
        AdminColors.infoTint,
        AdminColors.info,
      ),
      'pod_uploaded' => (AdminColors.warningTint, AdminColors.brandOrange),
      'completed' => (AdminColors.successTint, Colors.green.shade700),
      _ => (AdminColors.scaffoldBg, AdminColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;

  const _Pill({required this.text, required this.color, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _RequestActionsCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _RequestActionsCard({
    required this.loading,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : onReject,
                child: const Text('Reject Request'),
              ),
            ),
            const SizedBox(width: AdminDesignTokens.gapSm),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: loading ? null : onAccept,
                child: const Text('Accept Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final TextEditingController searchController;
  final AsyncValue<List<DispatchTruckerCandidate>> candidatesAsync;
  final DispatchTruckerCandidate? selectedTrucker;
  final DispatchTruckOption? selectedTruck;
  final VoidCallback onSearchChanged;
  final ValueChanged<DispatchTruckerCandidate> onSelectTrucker;
  final ValueChanged<DispatchTruckOption> onSelectTruck;
  final VoidCallback? onForceAssign;

  const _DispatchCard({
    required this.searchController,
    required this.candidatesAsync,
    required this.selectedTrucker,
    required this.selectedTruck,
    required this.onSearchChanged,
    required this.onSelectTrucker,
    required this.onSelectTruck,
    required this.onForceAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dispatch Assignment',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Suggested truckers are ranked by proximity',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: searchController,
              onChanged: (_) => onSearchChanged(),
              decoration: const InputDecoration(
                hintText: 'Search trucker by name, phone, or truck number',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            candidatesAsync.when(
              data: (candidates) {
                if (candidates.isEmpty) {
                  return const Text(
                    'No verified truckers with matching trucks are available.',
                  );
                }

                return Column(
                  children: candidates
                      .map(
                        (candidate) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${candidate.truckerName} • ${candidate.mobile}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          if (candidate.isFallbackMatch)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Text(
                                                'Fallback match (relaxed truck filters)',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: AdminColors.brandOrange,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          onSelectTrucker(candidate),
                                      icon: Icon(
                                        selectedTrucker?.truckerId ==
                                                candidate.truckerId
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color:
                                            selectedTrucker?.truckerId ==
                                                candidate.truckerId
                                            ? AdminColors.primary
                                            : AdminColors.textSecondary,
                                      ),
                                      tooltip: 'Select trucker',
                                    ),
                                  ],
                                ),
                                Text(
                                  'Rating ${candidate.rating.toStringAsFixed(2)} • Trips ${candidate.completedTrips} • Super ${candidate.superTruckerStatus.ifEmpty('-')}${candidate.distanceKm == null ? '' : ' • ${candidate.distanceKm!.toStringAsFixed(1)} km away'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 6),
                                ...candidate.trucks.map(
                                  (truck) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      '${truck.truckNumber} • ${truck.bodyType} • ${truck.tyres} tyres',
                                    ),
                                    leading: IconButton(
                                      onPressed:
                                          selectedTrucker?.truckerId ==
                                              candidate.truckerId
                                          ? () => onSelectTruck(truck)
                                          : null,
                                      icon: Icon(
                                        selectedTruck?.id == truck.id
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: selectedTruck?.id == truck.id
                                            ? AdminColors.primary
                                            : AdminColors.textSecondary,
                                      ),
                                      tooltip: 'Select truck',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Unable to load dispatch candidates right now.'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.brandOrange,
                  foregroundColor: Colors.white,
                ),
                onPressed: onForceAssign,
                child: const Text('Force assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodReviewCard extends StatelessWidget {
  final SuperOpsLoadDetail detail;
  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;

  const _PodReviewCard({
    required this.detail,
    required this.loading,
    required this.onConfirm,
    required this.onDispute,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AdminDesignTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POD Review',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _PreviewRow(label: 'POD Photo', url: detail.podPhotoUrl),
            _PreviewRow(label: 'LR Photo', url: detail.lrPhotoUrl),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading ? null : onDispute,
                    child: const Text('Dispute POD review'),
                  ),
                ),
                const SizedBox(width: AdminDesignTokens.gapSm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: loading ? null : onConfirm,
                    child: const Text('Confirm POD and payout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String url;

  const _PreviewRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(hasUrl ? 'Tap to preview the uploaded document' : 'No document uploaded'),
      trailing: hasUrl ? const Icon(Icons.open_in_new) : null,
      onTap: hasUrl
          ? () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                insetPadding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: 760,
                  height: 560,
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(child: Text('Unable to load the document preview.')),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

String _formatDate(DateTime? dateTime) {
  if (dateTime == null) return '-';
  return IstTime.formatDate(dateTime, 'dd MMM yyyy');
}

class _LoadInfoTable extends StatelessWidget {
  final SuperOpsLoadDetail detail;
  const _LoadInfoTable({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(140),
        1: FlexColumnWidth(),
      },
      children: [
        _tableRow('Route', detail.routeLabel),
        _tableRow('Material', '${detail.material} • ${detail.weightTonnes.toStringAsFixed(1)}T'),
        _tableRow('Price', '₹${detail.price.toStringAsFixed(0)}'),
        _tableRow('Truck Type', detail.requiredTruckType.ifEmpty('-')),
        _tableRow('Tyres', detail.requiredTyres.isEmpty ? '-' : detail.requiredTyres.join('/')),
        _tableRow('Trucks', '${detail.trucksBooked}/${detail.trucksNeeded}'),
        _tableRow('Status', detail.superStatus),
        _tableRow('Pickup', _formatDate(detail.pickupDate)),
      ],
    );
  }
}

class _SupplierInfoTable extends StatelessWidget {
  final SuperOpsLoadDetail detail;
  const _SupplierInfoTable({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(140),
        1: FlexColumnWidth(),
      },
      children: [
        _tableRow('Name', detail.supplier.fullName),
        _tableRow('Company', detail.supplier.companyName.ifEmpty('No company')),
        _tableRow('Contact', '${detail.supplier.mobile} • ${detail.supplier.email}'),
        _tableRow('Verification', detail.supplier.verificationStatus.ifEmpty('-')),
        _tableRow('GST', detail.supplier.gstNumber.ifEmpty('-')),
      ],
    );
  }
}

class _PayoutInfoTable extends StatelessWidget {
  final SuperOpsLoadDetail detail;
  const _PayoutInfoTable({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(140),
        1: FlexColumnWidth(),
      },
      children: [
        _tableRow('Holder', detail.payout.accountHolderName.ifEmpty('-')),
        _tableRow('Bank', detail.payout.bankName.ifEmpty('-')),
        _tableRow('Account', '****${detail.payout.accountNumberLast4.ifEmpty('----')}'),
        _tableRow('IFSC', detail.payout.ifscCode.ifEmpty('-')),
        _tableRow('Profile Status', detail.payout.status.ifEmpty('-')),
      ],
    );
  }
}

TableRow _tableRow(String label, String value) {
  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: AdminDesignTokens.gapSm),
        child: Text(
          label,
          style: const TextStyle(color: AdminColors.textSecondary),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: AdminDesignTokens.gapSm),
        child: Text(value),
      ),
    ],
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
