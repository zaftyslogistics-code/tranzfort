import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_audit_log_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_load_management_providers.dart';

class AdminLoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const AdminLoadDetailScreen({super.key, required this.loadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(adminLoadDetailProvider(loadId));
    final auditTrailAsync = ref.watch(adminLoadAuditTrailProvider(loadId));
    final actionState = ref.watch(adminLoadActionProvider);
    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AdminColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading load detail',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(adminLoadDetailProvider(loadId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Load not found.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              Text('Load detail', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Inspect the load state, supplier context, and current requirements. Admin cancellation uses the existing shared backend contract only where status allows it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current load management contract',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This detail view is currently inspection-first. Supplier follow-through and load-linked audit visibility are live, and admin cancellation is only available through the shared backend contract when the load is still draft or active. The shared cancellation path is now audited, while broader admin mutations and any claim that every load action is audited remain intentionally out of scope here.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${detail.routeLabel} • ${detail.material}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      _InfoRow(label: 'Load id', value: loadId),
                      _InfoRow(label: 'Supplier id', value: detail.supplierId.isEmpty ? '-' : detail.supplierId),
                      _InfoRow(label: 'Supplier', value: detail.supplierName.isEmpty ? detail.supplierId : detail.supplierName),
                      _InfoRow(label: 'Origin', value: detail.originLabel),
                      _InfoRow(label: 'Destination', value: detail.destinationLabel),
                      _InfoRow(label: 'Status', value: detail.status),
                      _InfoRow(label: 'Super Load', value: detail.isSuperLoad ? detail.superStatus : 'No'),
                      _InfoRow(label: 'Weight tonnes', value: detail.weightTonnes?.toStringAsFixed(1) ?? '-'),
                      _InfoRow(label: 'Body type', value: detail.requiredBodyType.isEmpty ? '-' : detail.requiredBodyType),
                      _InfoRow(label: 'Tyres', value: detail.requiredTyres.isEmpty ? '-' : detail.requiredTyres.join(', ')),
                      _InfoRow(label: 'Price', value: detail.priceAmount == null ? '-' : '₹${detail.priceAmount!.toStringAsFixed(0)}'),
                      _InfoRow(label: 'Price type', value: detail.priceType.isEmpty ? '-' : detail.priceType),
                      _InfoRow(label: 'Advance %', value: detail.advancePercentage?.toString() ?? '-'),
                      _InfoRow(label: 'Trucks', value: '${detail.trucksBooked}/${detail.trucksNeeded}'),
                      _InfoRow(label: 'Pickup', value: _dateTimeLabel(detail.pickupDate)),
                      _InfoRow(label: 'Published', value: _dateTimeLabel(detail.publishedAt)),
                      _InfoRow(label: 'Created', value: _dateTimeLabel(detail.createdAt)),
                      if (detail.supplierId.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          key: const ValueKey('admin-load-open-supplier-button'),
                          onPressed: () => context.go(AdminRoutes.userDetailPathFor(detail.supplierId)),
                          icon: const Icon(Icons.person_outline),
                          label: const Text('Open supplier'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent audit trail',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Read-only visibility into current audit log entries already linked to this load, including the shared audited cancellation path. This still does not claim that every load action is audited yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      auditTrailAsync.when(
                        data: (entries) {
                          if (entries.isEmpty) {
                            return const Text('No load-linked audit entries are visible yet.');
                          }
                          return Column(
                            children: entries
                                .map((entry) => _AuditRow(entry: entry))
                                .toList(growable: false),
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (error, stackTrace) => const Text('Could not load linked audit entries right now.'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (detail.status == 'active' || detail.status == 'draft')
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: actionState.isLoading ? null : () => _cancelLoad(context, ref),
                    style: FilledButton.styleFrom(backgroundColor: AdminColors.error),
                    child: const Text('Cancel load'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _cancelLoad(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(adminLoadActionProvider.notifier).cancelLoad(loadId);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ok ? 'Load cancelled.' : 'Could not cancel this load right now.')));
    ref.invalidate(adminLoadDetailProvider(loadId));
    ref.invalidate(adminLoadManagementProvider);
  }
}

class _AuditRow extends StatelessWidget {
  final AdminAuditLogEntry entry;

  const _AuditRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('admin-load-audit-entry-${entry.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_toggle_off_outlined),
      title: Text(entry.summary.isEmpty ? entry.actionType : entry.summary),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.actionType.isEmpty ? '-' : entry.actionType,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Visibility ${entry.visibilityClass.isEmpty ? 'visible' : entry.visibilityClass}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Actor ${entry.actorAdminUserId.isEmpty ? '-' : (entry.actorAdminLabel.isEmpty ? entry.actorAdminUserId : '${entry.actorAdminLabel} • ${entry.actorAdminUserId}')} • ${entry.actorRole.isEmpty ? '-' : entry.actorRole}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Audit ${entry.id.isEmpty ? '-' : entry.id}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Created ${_dateLabel(entry.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
          ),
        ],
      ),
      trailing: Text(_dateLabel(entry.createdAt), style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

String _dateLabel(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final local = value.toLocal();
  final month = _monthLabel(local.month);
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} $month ${local.hour}:$minute';
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

String _monthLabel(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month < 1 || month > 12) {
    return '-';
  }
  return months[month - 1];
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 132, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary))),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }
}
