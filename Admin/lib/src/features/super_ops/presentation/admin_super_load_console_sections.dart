part of 'admin_super_load_console_screen.dart';

class _SuperLoadConsoleBody extends StatelessWidget {
  final AdminSuperLoadQueueState state;
  final AdminSuperLoadActionState actionState;
  final AsyncValue<List<AdminSuperLoadPodReviewItem>> podReviewAsync;
  final VoidCallback onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AdminSuperLoadStatusFilter> onStatusChanged;
  final void Function(String loadId) onOpenLoad;
  final void Function(String userId) onOpenUser;
  final Future<void> Function(String loadId) onMarkUnderReview;
  final Future<void> Function(String loadId) onApprove;
  final Future<void> Function(String loadId) onReject;
  final Future<void> Function(String loadId) onActivate;
  final Future<void> Function(String loadId) onShowDispatchDialog;
  final Future<void> Function({required String title, required String? proofUrl}) onOpenProofPreview;

  const _SuperLoadConsoleBody({
    required this.state,
    required this.actionState,
    required this.podReviewAsync,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onOpenLoad,
    required this.onOpenUser,
    required this.onMarkUnderReview,
    required this.onApprove,
    required this.onReject,
    required this.onActivate,
    required this.onShowDispatchDialog,
    required this.onOpenProofPreview,
  });

  @override
  Widget build(BuildContext context) {
    final dispatchItems = state.items
        .where((item) => item.status == 'approved_payment_pending' || item.status == 'active')
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Text(
          'Super Load console',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Review Super Load requests, move them through readiness, and activate approved payment-pending loads using current backend contracts.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            labelText: 'Search Super Loads',
            hintText: 'Load id, supplier or supplier id, route, material, super status, or load status',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FilterChip(
              label: 'All',
              selected: state.query.statusFilter == AdminSuperLoadStatusFilter.all,
              onSelected: () => onStatusChanged(AdminSuperLoadStatusFilter.all),
            ),
            _FilterChip(
              label: 'Requests (${state.counts.requestSubmitted})',
              selected: state.query.statusFilter == AdminSuperLoadStatusFilter.requestSubmitted,
              onSelected: () => onStatusChanged(AdminSuperLoadStatusFilter.requestSubmitted),
            ),
            _FilterChip(
              label: 'Review (${state.counts.underReview})',
              selected: state.query.statusFilter == AdminSuperLoadStatusFilter.underReview,
              onSelected: () => onStatusChanged(AdminSuperLoadStatusFilter.underReview),
            ),
            _FilterChip(
              label: 'Payment (${state.counts.paymentPending})',
              selected: state.query.statusFilter == AdminSuperLoadStatusFilter.paymentPending,
              onSelected: () => onStatusChanged(AdminSuperLoadStatusFilter.paymentPending),
            ),
            _FilterChip(
              label: 'Active (${state.counts.active})',
              selected: state.query.statusFilter == AdminSuperLoadStatusFilter.active,
              onSelected: () => onStatusChanged(AdminSuperLoadStatusFilter.active),
            ),
            _FilterChip(
              label: 'Rejected (${state.counts.rejected})',
              selected: state.query.statusFilter == AdminSuperLoadStatusFilter.rejected,
              onSelected: () => onStatusChanged(AdminSuperLoadStatusFilter.rejected),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SuperLoadQueueSection(
          items: state.items,
          actionState: actionState,
          onRefresh: onRefresh,
          onOpenLoad: onOpenLoad,
          onOpenUser: onOpenUser,
          onMarkUnderReview: onMarkUnderReview,
          onApprove: onApprove,
          onReject: onReject,
          onActivate: onActivate,
          onShowDispatchDialog: onShowDispatchDialog,
        ),
        const SizedBox(height: 16),
        _SuperLoadDispatchReadinessSection(
          items: dispatchItems,
          actionState: actionState,
          onOpenLoad: onOpenLoad,
          onOpenUser: onOpenUser,
          onActivate: onActivate,
          onShowDispatchDialog: onShowDispatchDialog,
        ),
        const SizedBox(height: 16),
        _SuperLoadPodReviewSection(
          podReviewAsync: podReviewAsync,
          onOpenProofPreview: onOpenProofPreview,
          onOpenLoad: onOpenLoad,
          onOpenUser: onOpenUser,
        ),
      ],
    );
  }
}

class _SuperLoadQueueSection extends StatelessWidget {
  final List<AdminSuperLoadItem> items;
  final AdminSuperLoadActionState actionState;
  final VoidCallback onRefresh;
  final void Function(String loadId) onOpenLoad;
  final void Function(String userId) onOpenUser;
  final Future<void> Function(String loadId) onMarkUnderReview;
  final Future<void> Function(String loadId) onApprove;
  final Future<void> Function(String loadId) onReject;
  final Future<void> Function(String loadId) onActivate;
  final Future<void> Function(String loadId) onShowDispatchDialog;

  const _SuperLoadQueueSection({
    required this.items,
    required this.actionState,
    required this.onRefresh,
    required this.onOpenLoad,
    required this.onOpenUser,
    required this.onMarkUnderReview,
    required this.onApprove,
    required this.onReject,
    required this.onActivate,
    required this.onShowDispatchDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Super Load items', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('No Super Load items matched the current filter.')
            else
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.hub_outlined),
                  title: Text('${item.routeLabel} • ${item.material}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.supplierName.isEmpty ? 'Supplier' : item.supplierName} • ${_titleCaseWords(item.status)}'),
                      const SizedBox(height: 4),
                      Text(
                        'Supplier ${item.supplierId.isEmpty ? '-' : item.supplierId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Super status ${_titleCaseWords(item.status)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Load ${_titleCaseWords(item.loadStatus)} • Trucks ${item.trucksBooked}/${item.trucksNeeded}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Load ID ${item.id.isEmpty ? '-' : item.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      if (item.priceAmount != null || item.pickupDate != null)
                        Text(
                          '${item.priceAmount == null ? '' : '₹${item.priceAmount!.toStringAsFixed(0)}'}${item.priceAmount != null && item.pickupDate != null ? ' • ' : ''}${item.pickupDate == null ? '' : _dateLabel(item.pickupDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        'Pickup ${_dateTimeLabel(item.pickupDate)} • Updated ${_dateTimeLabel(item.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            key: ValueKey('super-open-load-row-${item.id}'),
                            onPressed: () => onOpenLoad(item.id),
                            child: const Text('Open load'),
                          ),
                          if (item.supplierId.isNotEmpty)
                            OutlinedButton(
                              key: ValueKey('super-open-supplier-row-${item.id}'),
                              onPressed: () => onOpenUser(item.supplierId),
                              child: const Text('Open supplier'),
                            ),
                          if (item.status == 'request_submitted')
                            OutlinedButton(
                              key: ValueKey('super-review-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onMarkUnderReview(item.id),
                              child: const Text('Mark In Review'),
                            ),
                          if (item.status == 'request_submitted' || item.status == 'under_review')
                            FilledButton(
                              key: ValueKey('super-approve-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onApprove(item.id),
                              child: const Text('Approve'),
                            ),
                          if (item.status == 'request_submitted' || item.status == 'under_review' || item.status == 'approved_payment_pending')
                            OutlinedButton(
                              key: ValueKey('super-reject-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onReject(item.id),
                              child: const Text('Reject'),
                            ),
                          if (item.status == 'approved_payment_pending')
                            FilledButton(
                              key: ValueKey('super-activate-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onActivate(item.id),
                              style: FilledButton.styleFrom(backgroundColor: AdminColors.success),
                              child: const Text('Confirm Payment'),
                            ),
                          if (item.status == 'active')
                            FilledButton(
                              key: ValueKey('super-dispatch-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onShowDispatchDialog(item.id),
                              child: const Text('Force Assign'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuperLoadDispatchReadinessSection extends StatelessWidget {
  final List<AdminSuperLoadItem> items;
  final AdminSuperLoadActionState actionState;
  final void Function(String loadId) onOpenLoad;
  final void Function(String userId) onOpenUser;
  final Future<void> Function(String loadId) onActivate;
  final Future<void> Function(String loadId) onShowDispatchDialog;

  const _SuperLoadDispatchReadinessSection({
    required this.items,
    required this.actionState,
    required this.onOpenLoad,
    required this.onOpenUser,
    required this.onActivate,
    required this.onShowDispatchDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dispatch readiness', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Focus the current dispatch lane on payment-pending loads that need activation and active loads that are ready for trucker assignment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Current dispatch authority here is limited to payment confirmation and force-assign for eligible active loads. Route/trip-level follow-through still stays read-side through the existing load and user detail surfaces.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No Super Load items in the current result set are waiting for dispatch follow-through.')
            else
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.status == 'approved_payment_pending' ? Icons.payments_outlined : Icons.local_shipping_outlined,
                  ),
                  title: Text('${item.routeLabel} • ${item.material}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.supplierName.isEmpty ? 'Supplier' : item.supplierName} • ${_titleCaseWords(item.status)}'),
                      const SizedBox(height: 4),
                      Text(
                        'Load ${item.id.isEmpty ? '-' : item.id} • Trucks ${item.trucksBooked}/${item.trucksNeeded}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            key: ValueKey('super-dispatch-readiness-open-load-${item.id}'),
                            onPressed: () => onOpenLoad(item.id),
                            child: const Text('Open load'),
                          ),
                          if (item.supplierId.isNotEmpty)
                            OutlinedButton(
                              key: ValueKey('super-dispatch-readiness-open-supplier-${item.id}'),
                              onPressed: () => onOpenUser(item.supplierId),
                              child: const Text('Open supplier'),
                            ),
                          if (item.status == 'approved_payment_pending')
                            FilledButton(
                              key: ValueKey('super-dispatch-readiness-activate-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onActivate(item.id),
                              style: FilledButton.styleFrom(backgroundColor: AdminColors.success),
                              child: const Text('Confirm Payment'),
                            ),
                          if (item.status == 'active')
                            FilledButton(
                              key: ValueKey('super-dispatch-readiness-force-${item.id}'),
                              onPressed: actionState.isLoading ? null : () => onShowDispatchDialog(item.id),
                              child: const Text('Force Assign'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuperLoadPodReviewSection extends StatelessWidget {
  final AsyncValue<List<AdminSuperLoadPodReviewItem>> podReviewAsync;
  final Future<void> Function({required String title, required String? proofUrl}) onOpenProofPreview;
  final void Function(String loadId) onOpenLoad;
  final void Function(String userId) onOpenUser;

  const _SuperLoadPodReviewSection({
    required this.podReviewAsync,
    required this.onOpenProofPreview,
    required this.onOpenLoad,
    required this.onOpenUser,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POD review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Read-only proof review is available from current backend authority. Payout completion stays deferred until an admin-specific mutation exists.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Trip ids and proof uploads are visible here for review, but a dedicated admin trip-detail route is not available in the current shell yet, so POD/LR review remains read-only alongside the existing load/supplier/trucker follow-through.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
            ),
            const SizedBox(height: 12),
            podReviewAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text('No Super Load trips are currently waiting for POD review.');
                }
                return Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text('${item.routeLabel} • ${item.material}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.supplierName.isEmpty ? 'Supplier' : item.supplierName} • ${item.truckerName.isEmpty ? 'Trucker' : item.truckerName} • ${item.truckNumber.isEmpty ? '-' : item.truckNumber}'),
                              const SizedBox(height: 4),
                              Text(
                                'Delivered ${_dateTimeLabel(item.deliveredAt)} • Proof uploaded ${_dateTimeLabel(item.podUploadedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trip ${item.tripId} • Proof uploaded ${_dateTimeLabel(item.podUploadedAt)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Load ${item.loadId.isEmpty ? '-' : item.loadId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Supplier ${item.supplierId.isEmpty ? '-' : item.supplierId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trucker ${item.truckerId.isEmpty ? '-' : item.truckerId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Truck ${item.truckId.isEmpty ? '-' : item.truckId}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Proofs POD ${item.podSignedUrl == null ? 'Missing' : 'Available'} • LR ${item.lrSignedUrl == null ? 'Missing' : 'Available'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Delivery GPS ${_gpsSummary(item.deliveredGpsLat, item.deliveredGpsLng)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'POD GPS ${_gpsSummary(item.podGpsLat, item.podGpsLng)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (item.podSignedUrl != null)
                                    OutlinedButton(
                                      key: ValueKey('super-open-pod-${item.tripId}'),
                                      onPressed: () => onOpenProofPreview(
                                        title: 'POD proof',
                                        proofUrl: item.podSignedUrl,
                                      ),
                                      child: const Text('Open POD'),
                                    ),
                                  if (item.lrSignedUrl != null)
                                    OutlinedButton(
                                      key: ValueKey('super-open-lr-${item.tripId}'),
                                      onPressed: () => onOpenProofPreview(
                                        title: 'LR proof',
                                        proofUrl: item.lrSignedUrl,
                                      ),
                                      child: const Text('Open LR'),
                                    ),
                                  OutlinedButton(
                                    key: ValueKey('super-open-load-${item.tripId}'),
                                    onPressed: () => onOpenLoad(item.loadId),
                                    child: const Text('Open load'),
                                  ),
                                  if (item.supplierId.isNotEmpty)
                                    OutlinedButton(
                                      key: ValueKey('super-open-supplier-${item.tripId}'),
                                      onPressed: () => onOpenUser(item.supplierId),
                                      child: const Text('Open supplier'),
                                    ),
                                  if (item.truckerId.isNotEmpty)
                                    OutlinedButton(
                                      key: ValueKey('super-open-trucker-${item.tripId}'),
                                      onPressed: () => onOpenUser(item.truckerId),
                                      child: const Text('Open trucker'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => const Text('Unable to load Super Load POD review items right now.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected());
  }
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _dateTimeLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _titleCaseWords(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _gpsSummary(double? lat, double? lng) {
  if (lat == null || lng == null) {
    return '-';
  }
  return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
