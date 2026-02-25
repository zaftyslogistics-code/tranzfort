import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_picker_util.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/trips_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Detail')),
      body: tripAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }

          final load = (trip['load'] as Map<String, dynamic>? ?? const {});
          final truck = (trip['truck'] as Map<String, dynamic>? ?? const {});
          final stage = (trip['stage'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${load['material'] ?? '-'}: ${load['origin_city'] ?? '-'} → ${load['dest_city'] ?? '-'}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _stageBadge(stage),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Truck: ${truck['truck_number'] ?? '-'}'),
                      const SizedBox(height: 6),
                      Text('Weight: ${load['weight_tonnes'] ?? '-'}T'),
                      Text('Distance: ${load['distance_km'] ?? '-'} km'),
                      Text(
                        'Price: ₹${(load['price'] as num?)?.toStringAsFixed(0) ?? '-'}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (stage == 'at_pickup') ...[
                _UploadLrAction(tripId: tripId),
                const SizedBox(height: 10),
                _StartTripAction(tripId: tripId),
              ],
              if (stage == 'in_transit')
                _MarkDeliveredAction(tripId: tripId),
              if (stage == 'delivered')
                _UploadPodAction(tripId: tripId),
              if (stage == 'pod_uploaded')
                const _PodUploadedWaitingSection(),
              if (stage == 'completed')
                _RatingSection(
                  loadId: (load['id'] ?? '').toString(),
                  supplierId: (load['supplier_id'] ?? '').toString(),
                  truckerId: (trip['trucker_id'] ?? '').toString(),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('Could not load trip details. Please try again.')),
      ),
    );
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

class _PodUploadedWaitingSection extends StatelessWidget {
  const _PodUploadedWaitingSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'POD uploaded',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Waiting for supplier to confirm delivery.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.neutral),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatingSection extends ConsumerStatefulWidget {
  final String loadId;
  final String supplierId;
  final String truckerId;

  const _RatingSection({
    required this.loadId,
    required this.supplierId,
    required this.truckerId,
  });

  @override
  ConsumerState<_RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<_RatingSection> {
  int _score = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();
    final existingRatingAsync = ref.watch(existingRatingProvider(widget.loadId));
    final actionState = ref.watch(tripActionProvider);

    if (user == null || role.isEmpty || widget.loadId.isEmpty) {
      return const SizedBox.shrink();
    }

    return existingRatingAsync.when(
      data: (existingRating) {
        if (existingRating != null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Your rating: ${existingRating['score'] ?? '-'}★',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        final isSupplier = role == 'supplier';
        final revieweeId = isSupplier ? widget.truckerId : widget.supplierId;
        final revieweeLabel = isSupplier ? 'Trucker' : 'Supplier';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rate this $revieweeLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(
                    5,
                    (index) {
                      final star = index + 1;
                      return ChoiceChip(
                        label: Text('$star★'),
                        selected: _score == star,
                        onSelected: (_) => setState(() => _score = star),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Submit Rating',
                  isLoading: actionState.isLoading,
                  onPressed: actionState.isLoading || revieweeId.isEmpty
                      ? null
                      : () async {
                          final success = await ref
                              .read(tripActionProvider.notifier)
                              .submitRating(
                                loadId: widget.loadId,
                                revieweeId: revieweeId,
                                reviewerRole: role,
                                score: _score,
                                comment: _commentController.text.trim().isEmpty
                                    ? null
                                    : _commentController.text.trim(),
                              );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Rating submitted.'
                                    : 'Could not submit rating. Please try again.',
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}

class _StartTripAction extends ConsumerWidget {
  final String tripId;

  const _StartTripAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
      label: 'Start Trip',
      color: AppColors.success,
      isLoading: actionState.isLoading,
      onPressed: actionState.isLoading
          ? null
          : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Start Trip'),
                    content: const Text(
                      'Confirm you have loaded the cargo and are ready to start?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Start'),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) {
                return;
              }

              final success = await ref.read(tripActionProvider.notifier).startTrip(tripId);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Trip started successfully.'
                        : 'Could not start trip. Please try again.',
                  ),
                ),
              );
            },
    );
  }
}

class _UploadLrAction extends ConsumerWidget {
  final String tripId;

  const _UploadLrAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
      label: 'Upload LR (Optional)',
      isLoading: actionState.isLoading,
      onPressed: actionState.isLoading
          ? null
          : () async {
              final lrFile = await ImagePickerUtil.pickAndCompressImage(
                context: context,
                source: ImageSource.camera,
                quality: 85,
              );
              if (lrFile == null) {
                return;
              }

              final success = await ref
                  .read(tripActionProvider.notifier)
                  .uploadLr(tripId: tripId, lrFile: lrFile);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'LR uploaded successfully.'
                        : 'Could not upload LR. Please try again.',
                  ),
                ),
              );
            },
    );
  }
}

class _MarkDeliveredAction extends ConsumerWidget {
  final String tripId;

  const _MarkDeliveredAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(tripActionProvider);

    return PrimaryButton(
      label: 'Mark Delivered',
      color: AppColors.success,
      isLoading: actionState.isLoading,
      onPressed: actionState.isLoading
          ? null
          : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Mark Delivered'),
                    content: const Text(
                      'Confirm cargo has been unloaded at destination?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  );
                },
              );

              if (confirm != true) {
                return;
              }

              final success = await ref
                  .read(tripActionProvider.notifier)
                  .markDelivered(tripId);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Marked delivered. Please upload POD next.'
                        : 'Could not mark delivered. Please try again.',
                  ),
                ),
              );
            },
    );
  }
}

class _UploadPodAction extends ConsumerWidget {
  final String tripId;

  const _UploadPodAction({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(tripActionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upload Proof of Delivery',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Upload POD Photo',
          isLoading: actionState.isLoading,
          onPressed: actionState.isLoading
              ? null
              : () async {
                  final podFile = await ImagePickerUtil.pickAndCompressImage(
                    context: context,
                    source: ImageSource.camera,
                    quality: 85,
                  );
                  if (podFile == null) {
                    return;
                  }

                  final success = await ref
                      .read(tripActionProvider.notifier)
                      .uploadPod(tripId: tripId, podFile: podFile);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'POD uploaded. Waiting for supplier confirmation.'
                            : 'Could not upload POD. Please try again.',
                      ),
                    ),
                  );
                },
        ),
      ],
    );
  }
}
