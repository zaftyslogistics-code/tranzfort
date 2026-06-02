import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../tts_card_speaker_button.dart';
import '../tts_listen_icon.dart';

/// Brand-gradient Super Load badge + white TTS speaker for marketplace card header (top-right).
class MarketplaceSuperLoadHeaderChip extends ConsumerWidget {
  final String message;

  const MarketplaceSuperLoadHeaderChip({
    super.key,
    required this.message,
  });

  static const _chipHeight = 32.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ttsL10n = lookupTtsLocalizations(Localizations.localeOf(context));
    final hasMessage = message.trim().isNotEmpty;

    return Semantics(
      label: l10n.marketplaceSuperLoadBadgeLabel,
      child: Container(
        height: _chipHeight,
        decoration: AppDecorations.brandGradientChipDecoration(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    size: 14,
                    color: AppColors.textOnPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.marketplaceSuperLoadBadgeLabel,
                    style: AppTypography.labelMicro.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            if (hasMessage) ...[
              Container(
                width: 1,
                height: 18,
                color: AppColors.textOnPrimary.withValues(alpha: 0.35),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: _chipHeight,
                ),
                tooltip: ttsL10n.ttsListenToLoadHint,
                onPressed: () => TtsCardSpeakerButton.speak(context, ref, message),
                icon: TtsListenIcon(
                  message: message,
                  size: 18,
                  color: AppColors.textOnPrimary,
                  onDarkSurface: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
