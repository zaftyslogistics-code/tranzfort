import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/models/domain_statuses.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/services/maps_launcher_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../features/supplier/data/supplier_dashboard_repository.dart';
import '../../../features/supplier/data/supplier_load_models.dart';
import '../../../features/supplier/data/supplier_profile_repository.dart';
import '../../../features/supplier/data/supplier_trip_repository.dart';
import '../../../features/supplier/providers/load_detail_provider.dart';
import '../../../features/supplier/providers/my_loads_provider.dart';
import '../../../features/supplier/providers/supplier_trips_provider.dart';
import '../../../features/supplier/providers/supplier_providers.dart';
import '../../../features/support/providers/support_compose_providers.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../shared/widgets/layout_components.dart';
import '../../../shared/widgets/status_components.dart';
import 'shell_components.dart';

part 'supplier_shell_dashboard_sections.dart';
part 'supplier_shell_load_detail_sections.dart';
part 'supplier_shell_my_loads_sections.dart';
part 'supplier_shell_trip_sections.dart';

class SupplierDashboardScreen extends ConsumerWidget {
  const SupplierDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(supplierProfileProvider);
    final dashboardAsync = ref.watch(supplierDashboardProvider);
    final recentLoadsAsync = ref.watch(supplierRecentLoadsProvider);
    final profile = profileAsync.valueOrNull;
    final profileResolved = !profileAsync.isLoading && !profileAsync.hasError && profile != null;
    final canPostLoads = _canPostLoads(profile);
    final Widget? topBanner = _buildTopBanner(context, ref, profileAsync);
    final List<Widget>? topBannerSection = topBanner == null ? null : <Widget>[topBanner];

    return ShellScrollView(
      children: [
        ...?topBannerSection,
        HeroActionCard(
          title: _heroTitle(context, profile),
          subtitle: l10n.supplierDashboardHeroSubtitle,
          primaryAction: GradientButton(
            label: !profileResolved
                ? l10n.navSupport
                : canPostLoads
                ? l10n.supplierDashboardPostLoadAction
                : l10n.supplierCompleteVerification,
            onPressed: () => context.go(
              !profileResolved
                  ? AppRoutes.supportPath
                  : canPostLoads
                  ? AppRoutes.postLoadPath
                  : AppRoutes.supplierVerificationPath,
            ),
          ),
          child: _HeroSummary(profile: profile),
        ),
        DetailSectionCard(
          title: l10n.supplierDashboardOverviewTitle,
          children: [
            _DashboardStatsSection(
              dashboardAsync: dashboardAsync,
              onRetry: () => ref.refresh(supplierDashboardProvider),
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierDashboardSuperLoadReadinessTitle,
          children: [
            if (profileResolved)
              _SuperLoadReadinessSection(profile: profile)
            else
              WarningBlock(
                title: l10n.supplierDashboardAccountStateUnavailableTitle,
                message: l10n.supplierDashboardAccountStateUnavailableMessage,
                action: OutlineButton(
                  label: l10n.navSupport,
                  onPressed: () => context.go(AppRoutes.supportPath),
                ),
              ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierDashboardQuickActionsTitle,
          children: [
            QuickActionGrid(
              items: [
                QuickActionItem(
                  icon: Icons.inventory_2_outlined,
                  label: l10n.shellTitleMyLoads,
                  onTap: () => context.go(AppRoutes.myLoadsPath),
                ),
                QuickActionItem(
                  icon: Icons.alt_route_outlined,
                  label: l10n.shellQuickActionTrips,
                  onTap: () => context.go(AppRoutes.supplierTripsPath),
                ),
                QuickActionItem(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.supplierDashboardQuickActionChatLabel,
                  onTap: () => context.go(AppRoutes.messagesPath),
                ),
                QuickActionItem(
                  icon: Icons.notifications_outlined,
                  label: l10n.navNotifications,
                  onTap: () => context.go(AppRoutes.notificationsPath),
                ),
              ],
            ),
          ],
        ),
        DetailSectionCard(
          title: l10n.supplierRecentLoadsTitle,
          children: [
            _RecentLoadsSection(
              recentLoadsAsync: recentLoadsAsync,
              onRetry: () => ref.refresh(supplierRecentLoadsProvider),
            ),
          ],
        ),
      ],
    );
  }

  String _heroTitle(BuildContext context, SupplierProfile? profile) {
    final l10n = AppLocalizations.of(context);
    final businessName = (profile?.companyName ?? '').trim();
    if (businessName.isNotEmpty) {
      return l10n.supplierDashboardWelcomeBack(businessName);
    }

    final fullName = profile?.fullName.trim() ?? '';
    if (fullName.isNotEmpty) {
      return l10n.supplierDashboardWelcomeBack(fullName);
    }

    return l10n.shellTitleSupplierDashboard;
  }

  Widget? _buildTopBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SupplierProfile?> profileAsync,
  ) {
    final l10n = AppLocalizations.of(context);
    final profile = profileAsync.valueOrNull;
    final verificationStatus = (profile?.verificationStatus ?? '').trim().toLowerCase();

    if (profileAsync.hasError) {
      return WarningBlock(
        title: l10n.supplierDashboardAccountStateUnavailableTitle,
        message: supplierAsyncFailure(profileAsync)?.message ?? l10n.supplierDashboardAccountStateUnavailableMessage,
        action: OutlineButton(
          label: l10n.commonRetry,
          onPressed: () => ref.refresh(supplierProfileProvider),
        ),
      );
    }

    if (profileAsync.isLoading) {
      return const LoadingShimmer(height: 92, itemCount: 1);
    }

    if (profile == null) {
      return WarningBlock(
        title: l10n.supplierDashboardAccountStateUnavailableTitle,
        message: l10n.supplierDashboardAccountStateUnavailableMessage,
        action: OutlineButton(
          label: l10n.commonRetry,
          onPressed: () => ref.refresh(supplierProfileProvider),
        ),
      );
    }

    if (verificationStatus == 'pending') {
      return _SupplierVerificationBannerWithAction(
        banner: VerificationBanner(
          status: VerificationBannerStatus.pending,
          title: l10n.supplierVerificationPendingTitle,
          description: l10n.supplierVerificationPendingMessage,
        ),
        actionLabel: l10n.supplierOpenVerification,
        onTap: () => context.go(AppRoutes.supplierVerificationPath),
      );
    }

    if (verificationStatus == 'verified' && profile.hasCompanyName) {
      return _SupplierVerificationBannerWithAction(
        banner: VerificationBanner(
          status: VerificationBannerStatus.approved,
          title: l10n.supplierDashboardVerificationStatusVerified,
          description: l10n.supplierVerificationCompleteDescription,
        ),
        actionLabel: l10n.supplierReviewVerification,
        onTap: () => context.go(AppRoutes.supplierVerificationPath),
      );
    }

    if (verificationStatus == 'rejected') {
      return _SupplierVerificationBannerWithAction(
        banner: VerificationBanner(
          status: VerificationBannerStatus.rejected,
          title: l10n.supplierVerificationNeedsAttentionTitle,
          description: l10n.supplierVerificationNeedsAttentionDescription,
        ),
        actionLabel: l10n.supplierFixVerification,
        onTap: () => context.go(AppRoutes.supplierVerificationPath),
      );
    }

    if (verificationStatus == 'unverified' || !profile.hasCompanyName) {
      return WarningBlock(
        title: l10n.supplierCompleteSetupTitle,
        message: l10n.supplierCompleteSetupMessage,
        action: OutlineButton(
          label: l10n.supplierOpenVerification,
          onPressed: () => context.go(AppRoutes.supplierVerificationPath),
        ),
      );
    }

    return null;
  }

  bool _canPostLoads(SupplierProfile? profile) {
    return profile?.canAccessWorkspace == true;
  }
}

