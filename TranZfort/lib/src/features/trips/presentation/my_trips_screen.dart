import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../providers/trips_providers.dart';

class MyTripsScreen extends ConsumerWidget {
  const MyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TripsTab(completed: false),
            _TripsTab(completed: true),
          ],
        ),
      ),
    );
  }
}

class _TripsTab extends ConsumerWidget {
  final bool completed;

  const _TripsTab({required this.completed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider(completed));

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return EmptyStateView(
            icon: Icons.route_outlined,
            title: completed ? 'No completed trips' : 'No active trips',
            subtitle: completed
                ? 'Completed trips will appear here.'
                : 'Book a load from Find Loads to start your first trip.',
            cta: completed
                ? null
                : FilledButton(
                    onPressed: () => context.push('/find-loads'),
                    child: const Text('Find Loads'),
                  ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myTripsProvider(completed));
            await ref.read(myTripsProvider(completed).future);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final trip = trips[index];
              final load = (trip['load'] as Map<String, dynamic>? ?? const {});
              final truck =
                  (trip['truck'] as Map<String, dynamic>? ?? const <String, dynamic>{});
              final stage = (trip['stage'] ?? '').toString();

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.push('/trip-detail/${trip['id']}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${load['material'] ?? '-'} · ${load['weight_tonnes'] ?? '-'}T · ${truck['truck_number'] ?? '-'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _timeContext(trip),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.neutral),
                              ),
                            ),
                            _stageBadge(stage),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemCount: trips.length,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          const Center(child: Text('Could not load trips. Please try again.')),
    );
  }

  String _timeContext(Map<String, dynamic> trip) {
    final stage = (trip['stage'] ?? '').toString();
    final startedAt = DateTime.tryParse((trip['start_time'] ?? '').toString());
    final createdAt = DateTime.tryParse((trip['created_at'] ?? '').toString());

    final reference = startedAt ?? createdAt;
    if (reference == null) {
      return 'Recently updated';
    }

    final diff = DateTime.now().difference(reference);
    final value = diff.inHours > 0 ? '${diff.inHours}h ago' : '${diff.inMinutes}m ago';

    return switch (stage) {
      'completed' => 'Completed $value',
      'in_transit' => 'Started $value',
      'at_pickup' => 'Approved $value',
      'delivered' => 'Delivered $value',
      'pod_uploaded' => 'POD uploaded $value',
      _ => 'Updated $value',
    };
  }

  Widget _stageBadge(String stage) {
    return switch (stage) {
      'completed' => const StatusBadge(
          label: 'Completed',
          backgroundColor: Color(0xFFD1FAE5),
          textColor: Color(0xFF065F46),
        ),
      'in_transit' => const StatusBadge(
          label: 'In Transit',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFF92400E),
        ),
      'at_pickup' => const StatusBadge(
          label: 'At Pickup',
          backgroundColor: Color(0xFFFEF3C7),
          textColor: Color(0xFF92400E),
        ),
      'delivered' => const StatusBadge(
          label: 'Delivered',
          backgroundColor: Color(0xFFD1FAE5),
          textColor: Color(0xFF065F46),
        ),
      'pod_uploaded' => const StatusBadge(
          label: 'POD Uploaded',
          backgroundColor: Color(0xFFEFF6FF),
          textColor: Color(0xFF1D4ED8),
        ),
      _ => StatusBadge.neutral('Unknown'),
    };
  }
}
