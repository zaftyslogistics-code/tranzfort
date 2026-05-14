import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/providers/app_state_providers.dart';
import '../../core/theme/app_shadows.dart';

/// Shared user avatar widget with caching, shimmer loading, and stable Hero tags.
/// Replaces duplicate _AvatarCircle implementations across the app.
class UserAvatar extends ConsumerWidget {
  final String? avatarUrl;
  final String? userId;
  final String? initials;
  final double radius;
  final VoidCallback? onTap;
  final Widget? fallback;
  final IconData? fallbackIcon;
  final Color? fallbackColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.userId,
    this.initials,
    required this.radius,
    this.onTap,
    this.fallback,
    this.fallbackIcon,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final avatarService = ref.watch(avatarUrlServiceProvider);
    final url = avatarUrl?.trim();

    // If no URL provided, show fallback immediately
    if (url == null || url.isEmpty) {
      return _buildFallback(context, colorScheme);
    }

    // If URL is already HTTP, use CachedNetworkImage directly
    if (url.startsWith('http')) {
      return _buildAvatarWithUrl(context, url);
    }

    // If URL is a storage path, use FutureBuilder to get signed URL
    return FutureBuilder<String?>(
      future: avatarService.getSignedUrl(url),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data;
        if (resolvedUrl == null || resolvedUrl.isEmpty) {
          return _buildFallback(context, colorScheme);
        }
        return _buildAvatarWithUrl(context, resolvedUrl);
      },
    );
  }

  Widget _buildAvatarWithUrl(BuildContext context, String url) {
    final heroTag = userId != null ? 'user_avatar_$userId' : null;

    Widget avatar = SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildShimmerPlaceholder(context),
          errorWidget: (context, url, error) => _buildFallback(context, Theme.of(context).colorScheme),
          fadeInDuration: const Duration(milliseconds: 200),
        ),
      ),
    );

    if (heroTag != null && onTap != null) {
      avatar = Hero(
        tag: heroTag,
        child: GestureDetector(
          onTap: onTap,
          child: avatar,
        ),
      );
    } else if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    } else if (heroTag != null) {
      avatar = Hero(tag: heroTag, child: avatar);
    }

    return avatar;
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context, ColorScheme colorScheme) {
    // Use custom fallback if provided
    if (fallback != null) {
      return SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: fallback,
      );
    }

    // Build default fallback with initials or icon
    final displayInitials = initials ?? (userId?.substring(0, 1).toUpperCase() ?? '?');
    final displayColor = fallbackColor ?? colorScheme.primaryContainer;

    Widget fallbackWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: displayColor,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2),
        boxShadow: AppShadows.card,
      ),
      child: fallbackIcon != null
          ? Icon(
              fallbackIcon,
              size: radius,
              color: colorScheme.onPrimaryContainer,
            )
          : Center(
              child: Text(
                displayInitials,
                style: TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
    );

    if (onTap != null) {
      fallbackWidget = GestureDetector(
        onTap: onTap,
        child: fallbackWidget,
      );
    }

    return fallbackWidget;
  }
}
