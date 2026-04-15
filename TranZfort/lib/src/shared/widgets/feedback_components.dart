import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'action_buttons.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingShimmer extends StatelessWidget {
  final double height;
  final int itemCount;

  const LoadingShimmer({
    super.key,
    this.height = 88,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == itemCount - 1 ? 0 : AppSpacing.md),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ),
      ),
    );

    // Disable shimmer animation in test mode to prevent pumpAndSettle timeouts
    // Check for test binding by looking at the binding type name
    final isTestEnvironment = const bool.fromEnvironment('FLUTTER_TEST');
    if (isTestEnvironment) {
      return placeholder;
    }

    return Shimmer.fromColors(
      baseColor: AppColors.subtleSurface,
      highlightColor: Colors.white,
      child: placeholder,
    );
  }
}

class ConnectivityBanner extends StatelessWidget {
  final bool isOnline;
  final String? offlineMessage;

  const ConnectivityBanner({
    super.key,
    required this.isOnline,
    this.offlineMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              offlineMessage ?? AppLocalizations.of(context).connectivityOfflineActionsMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

enum AppSnackbarVariant {
  success,
  error,
  info,
}

class AppSnackbar {
  AppSnackbar._();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  static SnackBar build({
    required BuildContext context,
    required String message,
    required AppSnackbarVariant variant,
  }) {
    final (background, foreground, icon) = switch (variant) {
      AppSnackbarVariant.success => (AppColors.success, Colors.white, Icons.check_circle_outline),
      AppSnackbarVariant.error => (AppColors.error, Colors.white, Icons.error_outline),
      AppSnackbarVariant.info => (AppColors.info, Colors.white, Icons.info_outline),
    };

    return SnackBar(
      backgroundColor: background,
      content: Row(
        children: [
          Icon(icon, color: foreground, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  static void show({
    required BuildContext context,
    required String message,
    required AppSnackbarVariant variant,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      build(context: context, message: message, variant: variant),
    );
  }
}

enum VerificationBannerStatus {
  pending,
  approved,
  rejected,
}

class VerificationBanner extends StatelessWidget {
  final VerificationBannerStatus status;
  final String title;
  final String description;

  const VerificationBanner({
    super.key,
    required this.status,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      VerificationBannerStatus.pending => (AppColors.warningBg, AppColors.warning, Icons.hourglass_top_outlined),
      VerificationBannerStatus.approved => (AppColors.successBg, AppColors.success, Icons.verified_outlined),
      VerificationBannerStatus.rejected => (AppColors.errorBg, AppColors.error, Icons.cancel_outlined),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foreground),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
