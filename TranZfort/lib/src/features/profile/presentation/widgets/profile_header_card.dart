import 'package:flutter/material.dart';

import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/public_profile_models.dart';

/// Profile header card displaying user identity with new user states.
class ProfileHeaderCard extends StatelessWidget {
  final PublicProfile profile;
  final VoidCallback? onAvatarTap;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildAvatar(context),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.companyName != null && profile.companyName != profile.fullName)
                        Text(
                          profile.fullName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildLocationRow(context),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildRatingChip(context),
                _buildVerificationChip(context),
                if (profile.newUserBadge != null)
                  _buildNewUserChip(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVerified = profile.verificationStatus == 'verified';
    final radius = 28.0;

    return UserAvatar(
      avatarUrl: profile.avatarUrl,
      userId: profile.id,
      initials: _getInitials(),
      radius: radius,
      onTap: onAvatarTap,
      fallback: _buildVerifiedFallback(context, colorScheme, isVerified, radius),
    );
  }

  Widget _buildVerifiedFallback(BuildContext context, ColorScheme colorScheme, bool isVerified, double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: isVerified
            ? Border.all(color: colorScheme.primary, width: 2)
            : Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      child: Center(
        child: Text(
          _getInitials(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            profile.displayLocation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasRating = profile.hasReviews;

    return Chip(
      avatar: Icon(
        Icons.star,
        size: 16,
        color: hasRating ? Colors.amber : colorScheme.onSurfaceVariant,
      ),
      label: Text(
        hasRating
            ? '${profile.avgRating.toStringAsFixed(1)} (${profile.reviewCount})'
            : 'No rating yet',
        style: TextStyle(
          fontSize: 12,
          color: hasRating ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
        ),
      ),
      backgroundColor: hasRating
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildVerificationChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isVerified = profile.verificationStatus == 'verified';
    final isPending = profile.verificationStatus == 'pending';

    final bgColor = isVerified
        ? Colors.green.withValues(alpha: 0.1)
        : isPending
            ? Colors.orange.withValues(alpha: 0.1)
            : colorScheme.surfaceContainerHighest;

    final iconColor = isVerified
        ? Colors.green
        : isPending
            ? Colors.orange
            : colorScheme.onSurfaceVariant;

    return Chip(
      avatar: Icon(
        isVerified ? Icons.verified : Icons.pending_outlined,
        size: 16,
        color: iconColor,
      ),
      label: Text(
        profile.verificationBadge,
        style: TextStyle(
          fontSize: 12,
          color: iconColor,
        ),
      ),
      backgroundColor: bgColor,
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildNewUserChip(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        Icons.person_add_outlined,
        size: 16,
        color: colorScheme.primary,
      ),
      label: Text(
        profile.newUserBadge!,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.primary,
        ),
      ),
      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _getInitials() {
    final name = profile.displayName;
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
