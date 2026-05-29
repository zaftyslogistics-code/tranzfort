import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/language_toggle_action.dart';
import '../../../shared/widgets/tts_action_button.dart';
import '../data/public_profile_models.dart';
import '../providers/public_profile_providers.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/trust_score_card.dart';
import '../../reviews/presentation/reviews_section.dart';

/// Public profile screen for truckers.
class TruckerPublicProfileScreen extends ConsumerWidget {
  final String truckerId;

  const TruckerPublicProfileScreen({
    super.key,
    required this.truckerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(truckerId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).truckerProfileTitle),
        actions: const [
          TtsActionButton(),
          LanguageToggleAction(),
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
        ref.invalidate(publicProfileProvider(truckerId));
        await ref.read(publicProfileProvider(truckerId).future);
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
          // Fleet Section (for truckers)
          if (profile.fleet?.isNotEmpty == true)
            SliverToBoxAdapter(
              child: _buildFleetSection(context, profile),
            ),
          if (profile.fleet?.isNotEmpty == true)
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
          // Reviews Section (PRIMARY CONTENT)
          SliverToBoxAdapter(
            child: ReviewsSection(
              userId: truckerId,
              summaryAvgRating: profile.avgRating,
              summaryReviewCount: profile.reviewCount,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetSection(BuildContext context, PublicProfile profile) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fleet = profile.fleet!;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fleet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${fleet.length} truck${fleet.length > 1 ? 's' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...fleet.map((truck) => _buildTruckTile(context, truck)),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckTile(BuildContext context, PublicTruckPreview truck) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  truck.truckNumber,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${truck.bodyType} • ${truck.tyres} tyres • ${truck.capacityTonnes}T',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (truck.status == 'verified')
            Icon(
              Icons.verified,
              size: 20,
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppFailure failure, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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
              l10n.publicProfileLoadErrorTitle,
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
                ref.invalidate(publicProfileProvider(truckerId));
                await ref.read(publicProfileProvider(truckerId).future);
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).commonRetryAction),
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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
