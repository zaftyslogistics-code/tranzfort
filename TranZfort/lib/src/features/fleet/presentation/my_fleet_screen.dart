import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/fleet_providers.dart';

class MyFleetScreen extends ConsumerWidget {
  const MyFleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetAsync = ref.watch(fleetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Fleet'),
        actions: [
          IconButton(
            onPressed: () => context.push('/my-fleet/add'),
            icon: const Icon(Icons.add),
            tooltip: 'Add Truck',
          ),
        ],
      ),
      body: fleetAsync.when(
        data: (trucks) {
          if (trucks.isEmpty) {
            return const Center(
              child: Text('No trucks yet. Tap + to add your first truck.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(fleetProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trucks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final truck = trucks[index];
                final status = (truck['status'] ?? 'pending').toString();
                final truckNumber = (truck['truck_number'] ?? '-').toString();
                final bodyType = (truck['body_type'] ?? '-').toString();
                final tyres = (truck['tyres'] ?? '-').toString();
                final capacity = (truck['capacity_tonnes'] ?? '-').toString();

                return Card(
                  child: ListTile(
                    title: Text(truckNumber),
                    subtitle: Text(
                      'Body: $bodyType | Tyres: $tyres | Capacity: $capacity T',
                    ),
                    trailing: _StatusChip(status: status),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load fleet: $e')),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'verified':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.35)),
    );
  }
}
