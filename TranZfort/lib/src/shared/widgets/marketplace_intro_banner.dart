import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/marketplace_intro_preferences.dart';
import '../../core/services/user_consent_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_state_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/platform_reviewed_badge.dart';
import '../widgets/action_buttons.dart';
import 'content_cards.dart';

class MarketplaceIntroBanner extends ConsumerWidget {
  final MarketplaceIntroSurface surface;

  const MarketplaceIntroBanner({
    super.key,
    required this.surface,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(marketplaceIntroVisibleProvider(surface));

    return visibility.when(
      data: (visible) {
        if (!visible) {
          return const SizedBox.shrink();
        }
        return _MarketplaceIntroBannerCard(
          onDismiss: () => _dismiss(context, ref),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    final consentSource = switch (surface) {
      MarketplaceIntroSurface.truckerFindLoads => 'marketplace_intro_trucker_find_loads',
      MarketplaceIntroSurface.supplierPostLoad => 'marketplace_intro_supplier_post_load',
    };

    try {
      await UserConsentService(client).record(
        consentType: 'marketplace_introduction',
        sourceContext: consentSource,
      );
    } catch (_) {
      // Banner dismiss still proceeds if consent RPC fails offline.
    }

    await ref.read(marketplaceIntroPreferencesProvider).markSeen(surface);
    ref.invalidate(marketplaceIntroVisibleProvider(surface));
  }
}

class _MarketplaceIntroBannerCard extends StatelessWidget {
  final VoidCallback onDismiss;

  const _MarketplaceIntroBannerCard({
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: WarningBlock(
        title: l10n.marketplaceIntroBannerTitle,
        message: l10n.marketplaceIntroBannerMessage,
        action: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => showPlatformReviewedDisclaimerSheet(context),
                child: Text(l10n.verificationSubmissionLearnMoreAction),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.marketplaceIntroBannerDismissAction,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}
