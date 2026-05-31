import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../shell/presentation/shell_components.dart';
import '../../../shared/widgets/content_cards.dart';

class CounterpartyChecklistScreen extends StatelessWidget {
  const CounterpartyChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = <String>[
      l10n.counterpartyChecklistStep1,
      l10n.counterpartyChecklistStep2,
      l10n.counterpartyChecklistStep3,
      l10n.counterpartyChecklistStep4,
      l10n.counterpartyChecklistStep5,
    ];

    return DetailPageScaffold(
      title: l10n.counterpartyChecklistTitle,
      children: [
        HeroActionCard(
          title: l10n.counterpartyChecklistTitle,
          subtitle: l10n.counterpartyChecklistSubtitle,
          child: Text(
            l10n.verificationSubmissionMarketplaceNotice,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        SectionCard(
          title: l10n.counterpartyChecklistTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}.',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        steps[index],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
