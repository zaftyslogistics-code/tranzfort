import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/admin_routes.dart';
import '../../../core/repositories/admin_load_management_repository.dart';
import '../../../core/theme/admin_colors.dart';
import '../providers/admin_load_management_providers.dart';

class AdminLoadManagementScreen extends ConsumerWidget {
  const AdminLoadManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadsAsync = ref.watch(adminLoadManagementProvider);
    return loadsAsync.when(
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
                'Error loading load management list',
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
                onPressed: () => ref.read(adminLoadManagementProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (state) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          Text('Load management', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Review marketplace loads, inspect supplier context, and use the existing shared cancel contract where the backend authorizes admin callers.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'This surface is currently read-heavy: list/detail inspection and supplier follow-through are live, while broader admin load mutations remain outside this screen except for the shared cancel path where status and backend authority allow it.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => ref.read(adminLoadManagementProvider.notifier).updateSearch(value),
            decoration: const InputDecoration(
              labelText: 'Search loads',
              hintText: 'Load id, supplier or supplier id, route, material, status, or super status',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AdminLoadFilter.values
                .map(
                  (filter) => ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: state.query.filter == filter,
                    onSelected: (_) => ref.read(adminLoadManagementProvider.notifier).updateFilter(filter),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Loads', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: () => ref.read(adminLoadManagementProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.items.isEmpty)
                    const Text('No loads matched the current filter.')
                  else
                    ...state.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(item.isSuperLoad ? Icons.hub_outlined : Icons.local_shipping_outlined),
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
                              'Load ${item.id.isEmpty ? '-' : item.id}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                            if (item.isSuperLoad) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Super status ${item.superStatus.isEmpty ? '-' : _titleCaseWords(item.superStatus)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              '₹${item.priceAmount?.toStringAsFixed(0) ?? '-'} • Trucks ${item.trucksBooked}/${item.trucksNeeded}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                            Text(
                              'Pickup ${_dateTimeLabel(item.pickupDate)} • Created ${_dateTimeLabel(item.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AdminColors.textSecondary),
                            ),
                            if (item.supplierId.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              OutlinedButton(
                                key: ValueKey('admin-load-list-open-supplier-${item.id}'),
                                onPressed: () => context.go(AdminRoutes.userDetailPathFor(item.supplierId)),
                                child: const Text('Open supplier'),
                              ),
                            ],
                          ],
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => context.go(AdminRoutes.loadDetailPathFor(item.id)),
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _filterLabel(AdminLoadFilter filter) {
  return switch (filter) {
    AdminLoadFilter.all => 'All',
    AdminLoadFilter.active => 'Active',
    AdminLoadFilter.draft => 'Draft',
    AdminLoadFilter.cancelled => 'Cancelled',
    AdminLoadFilter.completed => 'Completed',
    AdminLoadFilter.superLoads => 'Super Loads',
  };
}

String _titleCaseWords(String value) {
  final normalized = value.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) {
    return '-';
  }
  return normalized.split(' ').where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
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
