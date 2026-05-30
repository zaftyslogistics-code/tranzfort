import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/tts_card_speaker_button.dart';

/// Brand-gradient bordered section for onboarding forms (matches role cards).
class OnboardingFieldSection extends ConsumerWidget {
  final String label;
  final String ttsMessage;
  final Widget child;

  const OnboardingFieldSection({
    super.key,
    required this.label,
    required this.ttsMessage,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardRadius = BorderRadius.circular(AppRadius.card);

    return BrandGradientBorder(
      borderRadius: cardRadius,
      innerColor: AppColors.cardSurface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                TtsCardSpeakerButton(
                  message: ttsMessage,
                  onDarkSurface: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}
