import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/error/result.dart';
import '../data/public_profile_models.dart';
import '../data/public_profile_repository.dart';
import '../providers/public_profile_providers.dart';
import 'widgets/load_history_section.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/trust_score_card.dart';
import '../../reviews/presentation/reviews_section.dart';

/// Public profile screen for suppliers.
class SupplierPublicProfileScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierPublicProfileScreen({
    super.key,
    required this.supplierId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(supplierId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share profile functionality
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (result) => result.when(
          success: (profile) => _buildProfileContent(context, profile, ref),
          failure: (failure) => _buildErrorState(context, failure, ref),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(
          context,
          UnknownFailure(message: error.toString()),
          ref,
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, PublicProfile? profile, WidgetRef ref) {
    if (profile == null) {
      return _buildNotFoundState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(publicProfileProvider(supplierId));
        await ref.read(publicProfileProvider(supplierId).future);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ProfileHeaderCard(profile: profile),
          ),
          SliverToBoxAdapter(
            child: TrustScoreCard(profile: profile),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          // Reviews Section (PRIMARY CONTENT)
          SliverToBoxAdapter(
            child: ReviewsSection(
              userId: supplierId,
              summaryAvgRating: profile.avgRating,
              summaryReviewCount: profile.reviewCount,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
          // Load History
          SliverToBoxAdapter(
            child: LoadHistorySection(
              userId: supplierId,
              title: 'Recent Loads',
              statusFilter: 'active',
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppFailure failure, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                ref.invalidate(publicProfileProvider(supplierId));
                await ref.read(publicProfileProvider(supplierId).future);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This user may have been removed or does not exist.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
