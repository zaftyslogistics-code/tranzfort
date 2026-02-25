import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/marketplace_providers.dart';

class MyLoadsScreen extends ConsumerWidget {
  const MyLoadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Loads'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/post-load'),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Post Load',
            ),
          ],
        ),
        body: const TabBarView(
          children: [_LoadsTab(completed: false), _LoadsTab(completed: true)],
        ),
      ),
    );
  }
}

class _LoadsTab extends ConsumerWidget {
  final bool completed;

  const _LoadsTab({required this.completed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loadsAsync = ref.watch(myLoadsProvider(completed));

    return loadsAsync.when(
      data: (loads) {
        if (loads.isEmpty) {
          return EmptyStateView(
            icon: Icons.inventory_2_outlined,
            title: completed ? 'No completed loads' : 'No active loads',
            subtitle: completed
                ? 'Completed/cancelled loads will show here.'
                : 'Post your first load to start getting bookings.',
            cta: completed
                ? null
                : FilledButton(
                    onPressed: () => context.push('/post-load'),
                    child: const Text('Post Load'),
                  ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myLoadsProvider(completed));
            await ref.read(myLoadsProvider(completed).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final load = loads[index];
              final status = (load['status'] ?? '-').toString();
              final trucksNeeded =
                  (load['trucks_needed'] as num?)?.toInt() ?? 1;
              final trucksBooked =
                  (load['trucks_booked'] as num?)?.toInt() ?? 0;
              final progress = trucksNeeded <= 0
                  ? 0.0
                  : trucksBooked / trucksNeeded;

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/load-detail/${load['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${load['origin_city']} → ${load['dest_city']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${load['material']} · ${load['weight_tonnes']}T · ₹${load['price']}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: AppColors.neutralLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$trucksBooked/$trucksNeeded trucks booked',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.neutral),
                              ),
                            ),
                            _statusBadge(status, trucksNeeded, trucksBooked),
                          ],
                        ),
                        if (!completed && status == 'active') ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () async {
                                final success = await ref
                                    .read(loadActionProvider.notifier)
                                    .deactivateLoad(load['id'].toString());
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Load deactivated'
                                          : 'Could not deactivate load',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.cancel_outlined),
                              label: const Text('Deactivate'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder:
                (context, index) => const SizedBox(height: 12),
            itemCount: loads.length,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Failed to load: $error')),
    );
  }

  Widget _statusBadge(String status, int needed, int booked) {
    if (status == 'completed') {
      return const StatusBadge(
        label: 'Completed',
        backgroundColor: Color(0xFFD1FAE5),
        textColor: Color(0xFF065F46),
      );
    }
    if (status == 'cancelled' || status == 'expired') {
      return const StatusBadge(
        label: 'Cancelled',
        backgroundColor: Color(0xFFE5E7EB),
        textColor: Color(0xFF374151),
      );
    }
    if (booked == 0) {
      return const StatusBadge(
        label: 'Waiting',
        backgroundColor: Color(0xFFF3F4F6),
        textColor: Color(0xFF4B5563),
      );
    }
    if (booked >= needed) {
      return const StatusBadge(
        label: 'Fully Booked',
        backgroundColor: Color(0xFFD1FAE5),
        textColor: Color(0xFF065F46),
      );
    }
    return const StatusBadge(
      label: 'Fulfilling',
      backgroundColor: Color(0xFFFEF3C7),
      textColor: Color(0xFF92400E),
    );
  }
}
