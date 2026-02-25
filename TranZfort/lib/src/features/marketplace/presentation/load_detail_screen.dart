import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/rich_load_card.dart';

class LoadDetailScreen extends ConsumerWidget {
  final String loadId;

  const LoadDetailScreen({super.key, required this.loadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(loadDetailProvider(loadId));
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Load Detail')),
      body: detailAsync.when(
        data: (detail) {
          final load = (detail['load'] as Map<String, dynamic>? ?? const {});
          if (load.isEmpty) {
            return const Center(child: Text('Load not found'));
          }

          final children = (detail['children'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          final tripCost =
              (detail['trip_cost'] as Map<String, dynamic>? ?? const {});

          final role = (profileAsync.value?['user_role_type'] ?? '').toString();
          final isSupplier = role == 'supplier';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              RichLoadCard(load: load, showActions: false),
              const SizedBox(height: 16),
              OutlineButton(
                label: 'View Route Map',
                onPressed: () => context.push('/route-preview/$loadId'),
              ),
              const SizedBox(height: 16),
              _TripCostBreakdown(tripCost: tripCost),
              const SizedBox(height: 16),
              if (isSupplier)
                _SupplierSection(
                  parentLoadId: (load['parent_load_id'] ?? load['id'])
                      .toString(),
                  children: children,
                )
              else
                _TruckerActions(
                  parentLoadId: (load['parent_load_id'] ?? load['id'])
                      .toString(),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load detail: $error')),
      ),
    );
  }
}

class _TripCostBreakdown extends StatelessWidget {
  final Map<String, dynamic> tripCost;

  const _TripCostBreakdown({required this.tripCost});

  @override
  Widget build(BuildContext context) {
    if (tripCost.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Trip cost unavailable'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Cost Breakdown',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Diesel: ₹${(tripCost['diesel'] as num).toStringAsFixed(0)}'),
            Text('Tolls: ₹${(tripCost['toll'] as num).toStringAsFixed(0)}'),
            const Divider(height: 16),
            Text(
              'Total: ₹${(tripCost['total'] as num).toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
            ),
            Text(
              'Mileage: ${(tripCost['mileage'] as num).toStringAsFixed(1)} km/L',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierSection extends ConsumerWidget {
  final String parentLoadId;
  final List<Map<String, dynamic>> children;

  const _SupplierSection({required this.parentLoadId, required this.children});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = children
        .where((item) => item['status'] == 'pending_approval')
        .toList();
    final inTransit = children
        .where((item) => item['status'] == 'in_transit')
        .toList();
    final podUploaded = children
        .where((item) => item['status'] == 'pod_uploaded')
        .toList();
    final delivered = children
        .where(
          (item) => item['status'] == 'completed' || item['status'] == 'booked',
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Approval (${pending.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...pending.map(
          (booking) => _BookingCard(
            booking: booking,
            onApprove: () async {
              final success = await ref
                  .read(loadActionProvider.notifier)
                  .approveBooking(booking['id'].toString(), parentLoadId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success ? 'Booking approved' : 'Approve failed',
                  ),
                ),
              );
            },
            onReject: () async {
              final success = await ref
                  .read(loadActionProvider.notifier)
                  .rejectBooking(booking['id'].toString(), parentLoadId);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Booking rejected' : 'Reject failed'),
                ),
              );
            },
          ),
        ),
        if (pending.isEmpty) const Text('No pending bookings.'),
        const SizedBox(height: 16),
        Text(
          'In Transit (${inTransit.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...inTransit.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Truck: ${item['booking_truck_snapshot']?['truck_number'] ?? '-'}',
            ),
            subtitle: const Text('Trip is in transit'),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'POD Uploaded (${podUploaded.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...podUploaded.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Truck: ${item['booking_truck_snapshot']?['truck_number'] ?? '-'}',
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: 'Confirm Delivery',
                    color: AppColors.success,
                    onPressed: () async {
                      final success = await ref
                          .read(loadActionProvider.notifier)
                          .confirmDelivery(item['id'].toString(), parentLoadId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Delivery confirmed.'
                                : 'Could not confirm delivery.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Delivered (${delivered.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ...delivered.map(
          (item) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Truck: ${item['booking_truck_snapshot']?['truck_number'] ?? '-'}',
            ),
            subtitle: Text('Status: ${item['status']}'),
          ),
        ),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _BookingCard({
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final truckSnapshot =
        booking['booking_truck_snapshot'] as Map<String, dynamic>? ?? const {};

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Truck: ${truckSnapshot['truck_number'] ?? '-'}'),
            Text(
              '${truckSnapshot['body_type'] ?? '-'} · ${truckSnapshot['tyres'] ?? '-'} tyres · ${truckSnapshot['capacity_tonnes'] ?? '-'}T',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.neutral),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(label: 'Approve', onPressed: onApprove),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlineButton(label: 'Reject', onPressed: onReject),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TruckerActions extends ConsumerWidget {
  final String parentLoadId;

  const _TruckerActions({required this.parentLoadId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        OutlineButton(
          label: 'Chat with Supplier',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat feature in Sprint 7')),
            );
          },
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Book This Load',
          color: AppColors.success,
          onPressed: () async {
            final success = await ref
                .read(loadActionProvider.notifier)
                .bookLoad(parentLoadId);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Load booked! Waiting for supplier approval.'
                      : 'Booking failed. Ensure you have a verified truck.',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
