import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/result.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/providers/app_state_providers.dart';
import '../../../core/error/app_failure.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/action_buttons.dart';
import '../../../shared/widgets/content_cards.dart';
import '../../../shared/widgets/feedback_components.dart';
import '../../../core/theme/app_spacing.dart';
import 'shell_components.dart';

String _localizedDeletionStatus(AppLocalizations l10n, String value) {
  return switch (value.trim().toLowerCase()) {
    'active' => l10n.accountStateActive,
    'deactivated_pending_cleanup' => l10n.accountStateDeactivatedPendingCleanup,
    'restricted' => l10n.accountStateRestricted,
    _ => l10n.accountStateUnknown,
  };
}

String _blockerRecoveryGuidance(AppLocalizations l10n, String? blocker) {
  final normalized = (blocker ?? '').trim().toLowerCase();

  if (normalized.contains('active trip')) {
    return l10n.deleteAccountBlockerRecoveryGuidanceActiveTrips;
  }
  if (normalized.contains('dispute')) {
    return l10n.deleteAccountBlockerRecoveryGuidanceDispute;
  }
  if (normalized.contains('compliance') || normalized.contains('retention')) {
    return l10n.deleteAccountBlockerRecoveryGuidanceCompliance;
  }
  return l10n.deleteAccountBlockerRecoveryGuidanceDefault;
}

String _blockerActionLabel(AppLocalizations l10n, String? blocker) {
  final normalized = (blocker ?? '').trim().toLowerCase();
  if (normalized.contains('active trip')) {
    return l10n.deleteAccountBlockerActionOpenTrips;
  }
  return l10n.deleteAccountBlockerActionOpenSupport;
}

String _blockerActionRoute({
  required String? blocker,
  required AppUserRole role,
}) {
  final normalized = (blocker ?? '').trim().toLowerCase();
  if (normalized.contains('active trip')) {
    return role == AppUserRole.supplier ? AppRoutes.supplierTripsPath : AppRoutes.tripsPath;
  }
  return AppRoutes.supportPath;
}

String _blockerNextStepTitle(AppLocalizations l10n, String? blocker) {
  final normalized = (blocker ?? '').trim().toLowerCase();
  if (normalized.contains('active trip')) {
    return l10n.deleteAccountBlockerTitleActiveTrips;
  }
  if (normalized.contains('dispute')) {
    return l10n.deleteAccountBlockerTitleDispute;
  }
  if (normalized.contains('compliance') || normalized.contains('retention')) {
    return l10n.deleteAccountBlockerTitleCompliance;
  }
  return l10n.deleteAccountBlockerTitleDefault;
}

String _blockerNextStepBody(AppLocalizations l10n, String? blocker) {
  final normalized = (blocker ?? '').trim().toLowerCase();
  if (normalized.contains('active trip')) {
    return l10n.deleteAccountBlockerBodyActiveTrips;
  }
  if (normalized.contains('dispute')) {
    return l10n.deleteAccountBlockerBodyDispute;
  }
  if (normalized.contains('compliance') || normalized.contains('retention')) {
    return l10n.deleteAccountBlockerBodyCompliance;
  }
  return l10n.deleteAccountBlockerBodyDefault;
}

String _formatLifecycleDate(BuildContext context, DateTime value) {
  return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
}

String _gracePeriodRemainingLabel(AppLocalizations l10n, DateTime requestedAt) {
  final remaining = requestedAt.add(const Duration(days: 30)).difference(DateTime.now());
  if (remaining.isNegative) {
    return l10n.deleteAccountGracePeriodPassedLabel;
  }

  final remainingDays = remaining.inDays;
  if (remainingDays <= 0) {
    return l10n.deleteAccountGracePeriodLessThanOneDayLabel;
  }

  return l10n.deleteAccountGracePeriodRemainingDaysLabel(
    remainingDays,
    remainingDays == 1 ? '' : 's',
  );
}

String _deleteLifecycleFailureMessage(AppLocalizations l10n) {
  return l10n.deleteAccountLifecycleFailureMessage;
}

String _cancelDeletionFailureMessage(AppLocalizations l10n) {
  return l10n.deleteAccountCancelFailureMessage;
}

String _deleteRequestFailureMessage(AppLocalizations l10n) {
  return l10n.deleteAccountRequestFailureMessage;
}

String _deleteAcceptedSignOutFailureMessage(AppLocalizations l10n) {
  return l10n.deleteAccountAcceptedSignOutFailureMessage;
}

String _deleteBlockedSummaryMessage(AppLocalizations l10n) {
  return l10n.deleteAccountBlockedSummaryMessage;
}

String _deleteCancelledMessage(AppLocalizations l10n) {
  return l10n.deleteAccountCancelledMessage;
}

String _deleteAcceptedMessage(AppLocalizations l10n) {
  return l10n.deleteAccountAcceptedMessage;
}

class DeleteAccountState {
  final bool isSubmitting;
  final AppFailure? failure;
  final AccountDeletionRequestOutcome? outcome;

  const DeleteAccountState({
    required this.isSubmitting,
    required this.failure,
    required this.outcome,
  });

  factory DeleteAccountState.initial() {
    return const DeleteAccountState(
      isSubmitting: false,
      failure: null,
      outcome: null,
    );
  }

  DeleteAccountState copyWith({
    bool? isSubmitting,
    AppFailure? failure,
    bool? clearFailure,
    AccountDeletionRequestOutcome? outcome,
    bool? clearOutcome,
  }) {
    return DeleteAccountState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      failure: clearFailure == true ? null : failure ?? this.failure,
      outcome: clearOutcome == true ? null : outcome ?? this.outcome,
    );
  }
}

class DeleteAccountController extends StateNotifier<DeleteAccountState> {
  final AuthRepository _repository;

  DeleteAccountController(this._repository) : super(DeleteAccountState.initial());

  Future<Result<AccountDeletionRequestOutcome>> submit() async {
    if (state.isSubmitting) {
      return const Failure<AccountDeletionRequestOutcome>(
        BusinessRuleFailure(message: 'Account deletion request is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearOutcome: true,
    );

    final result = await _repository.requestAccountDeletion();
    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      outcome: result.valueOrNull,
    );
    return result;
  }

  Future<Result<AccountDeletionRequestOutcome>> cancelDeletion() async {
    if (state.isSubmitting) {
      return const Failure<AccountDeletionRequestOutcome>(
        BusinessRuleFailure(message: 'Account deletion request is already in progress.'),
      );
    }

    state = state.copyWith(
      isSubmitting: true,
      clearFailure: true,
      clearOutcome: true,
    );

    final result = await _repository.cancelAccountDeletion();
    state = state.copyWith(
      isSubmitting: false,
      failure: result.failureOrNull,
      outcome: result.valueOrNull,
    );
    return result;
  }
}

final deleteAccountProvider =
    StateNotifierProvider.autoDispose<DeleteAccountController, DeleteAccountState>((ref) {
  return DeleteAccountController(ref.watch(authRepositoryProvider));
});

class DeleteAccountScreen extends ConsumerWidget {
  const DeleteAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentProfileProvider);
    final authState = ref.watch(currentAuthStateProvider);
    final state = ref.watch(deleteAccountProvider);
    final deletionStatus = profileAsync.valueOrNull?.accountDeletionStatus ?? 'active';
    final alreadyPendingCleanup = deletionStatus == 'deactivated_pending_cleanup' || authState.isDeactivated;
    final deletionRequestedAt = profileAsync.valueOrNull?.dataDeletionRequestedAt;
    final gracePeriodEndsAt = deletionRequestedAt?.add(const Duration(days: 30));
    final isGracePeriodExpired = gracePeriodEndsAt != null && DateTime.now().isAfter(gracePeriodEndsAt);
    final canCancelPendingDeletion = !alreadyPendingCleanup ||
        deletionRequestedAt == null ||
        !DateTime.now().isAfter(gracePeriodEndsAt!);

    return DetailPageScaffold(
      title: l10n.deleteAccountScreenTitle,
      children: [
        HeroActionCard(
          title: alreadyPendingCleanup
              ? l10n.deleteAccountHeroTitlePendingCleanup
              : l10n.deleteAccountHeroTitleDefault,
          subtitle: alreadyPendingCleanup
              ? l10n.deleteAccountHeroSubtitlePendingCleanup
              : l10n.deleteAccountHeroSubtitleDefault,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alreadyPendingCleanup
                    ? l10n.deleteAccountHeroBodyPendingCleanup
                    : l10n.deleteAccountHeroBodyDefault,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              InfoRow(
                label: l10n.accountAccountStateLabel,
                value: _localizedDeletionStatus(l10n, deletionStatus),
              ),
              if (alreadyPendingCleanup && deletionRequestedAt != null) ...[
                const SizedBox(height: AppSpacing.sm),
                InfoRow(
                  label: l10n.deleteAccountRequestedOnLabel,
                  value: _formatLifecycleDate(context, deletionRequestedAt),
                ),
                InfoRow(
                  label: l10n.deleteAccountGracePeriodEndsLabel,
                  value: _formatLifecycleDate(context, gracePeriodEndsAt!),
                ),
              ],
            ],
          ),
        ),
        DetailSectionCard(
          title: l10n.deleteAccountWhatHappensNextTitle,
          children: [
            Text(
              alreadyPendingCleanup
                  ? l10n.deleteAccountWhatHappensNextBodyPendingCleanup
                  : l10n.deleteAccountWhatHappensNextBodyDefault,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alreadyPendingCleanup
                  ? l10n.deleteAccountWhatHappensNextDetailPendingCleanup
                  : l10n.deleteAccountWhatHappensNextDetailDefault,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alreadyPendingCleanup
                  ? l10n.deleteAccountWhatHappensNextFootnotePendingCleanup
                  : l10n.deleteAccountWhatHappensNextFootnoteDefault,
            ),
            if (alreadyPendingCleanup && deletionRequestedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _gracePeriodRemainingLabel(l10n, deletionRequestedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        DetailSectionCard(
          title: l10n.deleteAccountSupportTitle,
          children: [
            Text(
              alreadyPendingCleanup
                  ? l10n.deleteAccountSupportBodyPendingCleanup
                  : l10n.deleteAccountSupportBodyDefault,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alreadyPendingCleanup
                  ? l10n.deleteAccountSupportDetailPendingCleanup
                  : l10n.deleteAccountSupportDetailDefault,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlineButton(
                label: l10n.deleteAccountBlockerActionOpenSupport,
                onPressed: () => context.go(AppRoutes.supportPath),
              ),
            ),
          ],
        ),
        if (alreadyPendingCleanup) ...[
          if (state.failure != null)
            WarningBlock(
              title: l10n.deleteAccountLifecycleUnavailableTitle,
              message: _deleteLifecycleFailureMessage(l10n),
            ),
          if (state.outcome?.isCancelled == true)
            WarningBlock(
              title: l10n.deleteAccountCancelledTitle,
              message: _deleteCancelledMessage(l10n),
            )
          else
            WarningBlock(
              title: l10n.deleteAccountAlreadyRequestedTitle,
              message: isGracePeriodExpired
                  ? l10n.deleteAccountGracePeriodPassedLabel
                  : l10n.deleteAccountAlreadyRequestedMessage,
            ),
          if (canCancelPendingDeletion)
            DetailSectionCard(
              title: l10n.deleteAccountCancelRequestTitle,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlineButton(
                    label: state.isSubmitting
                        ? l10n.deleteAccountCancellingButton
                        : l10n.deleteAccountCancelRequestButton,
                    onPressed: state.isSubmitting
                        ? null
                        : () async {
                            final result = await ref.read(deleteAccountProvider.notifier).cancelDeletion();
                            if (!context.mounted) {
                              return;
                            }
                            result.when(
                              success: (outcome) {
                                ref.invalidate(authStateProvider);
                                ref.invalidate(currentAuthStateProvider);
                                ref.invalidate(profileCompletenessProvider);
                                AppSnackbar.show(
                                  context: context,
                                  message: _deleteCancelledMessage(l10n),
                                  variant: AppSnackbarVariant.success,
                                );
                              },
                              failure: (failure) {
                                AppSnackbar.show(
                                  context: context,
                                  message: _cancelDeletionFailureMessage(l10n),
                                  variant: AppSnackbarVariant.error,
                                );
                              },
                            );
                          },
                  ),
                ),
              ],
            ),
        ] else ...[
          if (state.failure != null)
            WarningBlock(
              title: l10n.deleteAccountUnavailableTitle,
              message: _deleteRequestFailureMessage(l10n),
            ),
          if (state.outcome != null && state.outcome!.blocked)
            WarningBlock(
              title: l10n.deleteAccountBlockedTitle,
              message:
                  '${_deleteBlockedSummaryMessage(l10n)} ${_blockerRecoveryGuidance(l10n, state.outcome!.blocker)}',
              action: OutlineButton(
                label: _blockerActionLabel(l10n, state.outcome!.blocker),
                onPressed: () => context.go(
                  _blockerActionRoute(
                    blocker: state.outcome!.blocker,
                    role: authState.role,
                  ),
                ),
              ),
            ),
          if (state.outcome != null && state.outcome!.blocked) ...[
            DetailSectionCard(
              title: _blockerNextStepTitle(l10n, state.outcome!.blocker),
              children: [
                Text(
                  _blockerNextStepBody(l10n, state.outcome!.blocker),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlineButton(
                    label: _blockerActionLabel(l10n, state.outcome!.blocker),
                    onPressed: () => context.go(
                      _blockerActionRoute(
                        blocker: state.outcome!.blocker,
                        role: authState.role,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          DetailSectionCard(
            title: l10n.deleteAccountConfirmRequestTitle,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  label: state.isSubmitting ? l10n.deleteAccountRequestingButton : l10n.navDeleteAccount,
                  onPressed: state.isSubmitting
                      ? null
                      : () async {
                          final result = await ref.read(deleteAccountProvider.notifier).submit();
                          if (!context.mounted) {
                            return;
                          }
                          result.when(
                            success: (outcome) async {
                              if (outcome.blocked) {
                                AppSnackbar.show(
                                  context: context,
                                  message: _deleteBlockedSummaryMessage(l10n),
                                  variant: AppSnackbarVariant.error,
                                );
                                return;
                              }

                              final signOutResult = await ref.read(authRepositoryProvider).signOutAndClearLocalState();
                              if (!context.mounted) {
                                return;
                              }
                              if (signOutResult.isFailure) {
                                AppSnackbar.show(
                                  context: context,
                                  message: _deleteAcceptedSignOutFailureMessage(l10n),
                                  variant: AppSnackbarVariant.error,
                                );
                                return;
                              }

                              ref.invalidate(authStateProvider);
                              ref.invalidate(currentAuthStateProvider);
                              ref.invalidate(profileCompletenessProvider);
                              context.go(AppRoutes.authPath);
                              AppSnackbar.show(
                                context: context,
                                message: _deleteAcceptedMessage(l10n),
                                variant: AppSnackbarVariant.success,
                              );
                            },
                            failure: (failure) {
                              AppSnackbar.show(
                                context: context,
                                message: _deleteRequestFailureMessage(l10n),
                                variant: AppSnackbarVariant.error,
                              );
                            },
                          );
                        },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
