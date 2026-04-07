import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/trips_providers.dart';

class RatingSection extends ConsumerStatefulWidget {
  final String loadId;
  final String supplierId;
  final String truckerId;

  const RatingSection({
    super.key,
    required this.loadId,
    required this.supplierId,
    required this.truckerId,
  });

  @override
  ConsumerState<RatingSection> createState() => _RatingSectionState();
}

class _RatingSectionState extends ConsumerState<RatingSection> {
  int _score = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(authSessionProvider).value?.session?.user;
    final role = (ref.watch(userProfileProvider).value?['user_role_type'] ?? '')
        .toString();
    final existingRatingAsync = ref.watch(
      existingRatingProvider(widget.loadId),
    );
    final actionState = ref.watch(tripActionProvider);

    if (user == null || role.isEmpty || widget.loadId.isEmpty) {
      return const SizedBox.shrink();
    }

    return existingRatingAsync.when(
      data: (existingRating) {
        if (existingRating != null) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              side: const BorderSide(color: AppColors.neutralLight),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              child: Text(
                '${l10n.tripYourRatingPrefix}: ${existingRating['score'] ?? '-'}★',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        final isSupplier = role == 'supplier';
        final revieweeId = isSupplier ? widget.truckerId : widget.supplierId;
        final revieweeLabel = isSupplier
            ? l10n.chatTruckerFallbackName
            : l10n.chatSupplierFallbackName;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: const BorderSide(color: AppColors.neutralLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.tripRateThisPrefix} $revieweeLabel',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final selected = _score >= star;
                    return IconButton(
                      onPressed: () => setState(() => _score = star),
                      icon: Icon(
                        selected ? Icons.star_rounded : Icons.star_border_rounded,
                        color: selected ? AppColors.secondaryAmber : AppColors.textTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.tripCommentOptional,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: l10n.tripSubmitRating,
                  isLoading: actionState.isLoading,
                  onPressed: actionState.isLoading || revieweeId.isEmpty
                      ? null
                      : () async {
                          final success = await ref
                              .read(tripActionProvider.notifier)
                              .submitRating(
                                loadId: widget.loadId,
                                revieweeId: revieweeId,
                                reviewerRole: role,
                                score: _score,
                                comment: _commentController.text.trim().isEmpty
                                    ? null
                                    : _commentController.text.trim(),
                              );
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? l10n.tripRatingSubmitted
                                    : l10n.tripRatingSubmitError,
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const SizedBox.shrink(),
    );
  }
}
