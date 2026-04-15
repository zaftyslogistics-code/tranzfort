part of 'trucker_trip_detail_screen.dart';

class _TripChatButton extends ConsumerStatefulWidget {
  final String supplierId;
  final String truckerId;
  final String loadId;

  const _TripChatButton({
    required this.supplierId,
    required this.truckerId,
    required this.loadId,
  });

  @override
  ConsumerState<_TripChatButton> createState() => _TripChatButtonState();
}

class _TripChatButtonState extends ConsumerState<_TripChatButton> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final truckerProfileAsync = ref.watch(truckerProfileProvider);
    final truckerProfile = truckerProfileAsync.valueOrNull;
    final chatBlockedMessage = _tripChatBlockedMessage(l10n, truckerProfileAsync, truckerProfile);
    final chatBlocked = chatBlockedMessage != null;
    final showOpenVerification = !truckerProfileAsync.isLoading && truckerAsyncFailure(truckerProfileAsync) == null && (truckerProfile == null || !truckerProfile.isVerified);
    final showOpenFleet = !showOpenVerification && truckerProfile != null && !truckerProfile.hasApprovedTruck;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlineButton(
          label: l10n.truckerChatSupplierAction,
          isLoading: _isStarting,
          onPressed: _isStarting || chatBlocked
              ? null
              : () async {
                  setState(() {
                    _isStarting = true;
                  });
                  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
                        supplierId: widget.supplierId,
                        truckerId: widget.truckerId,
                        loadId: widget.loadId,
                      );
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _isStarting = false;
                  });
                  result.when(
                    success: (conversationId) {
                      context.push('${AppRoutes.chatPath}/$conversationId');
                    },
                    failure: (failure) {
                      AppSnackbar.show(
                        context: context,
                        message: l10n.truckerTripChatStartFailureMessage,
                        variant: AppSnackbarVariant.error,
                      );
                    },
                  );
                },
        ),
        if (chatBlockedMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            chatBlockedMessage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (showOpenVerification) ...[
            const SizedBox(height: 8),
            TextActionButton(
              label: l10n.truckerDashboardOpenVerificationAction,
              onPressed: () => context.go(AppRoutes.truckerVerificationPath),
            ),
          ] else if (showOpenFleet) ...[
            const SizedBox(height: 8),
            TextActionButton(
              label: l10n.truckerDashboardOpenFleetAction,
              onPressed: () => context.go(AppRoutes.fleetPath),
            ),
          ],
        ],
      ],
    );
  }
}

String? _tripChatBlockedMessage(
  AppLocalizations l10n,
  AsyncValue<TruckerProfile?> truckerProfileAsync,
  TruckerProfile? truckerProfile,
) {
  if (truckerProfileAsync.isLoading) {
    return l10n.truckerLoadDetailProfileLoadingMessage;
  }
  if (truckerAsyncFailure(truckerProfileAsync) != null) {
    return l10n.truckerLoadDetailProfileLoadingMessage;
  }
  if (truckerProfile == null || !truckerProfile.isVerified) {
    return l10n.truckerLoadDetailVerificationRequiredMessage;
  }
  if (!truckerProfile.hasApprovedTruck) {
    return l10n.truckerLoadDetailTruckApprovalRequiredMessage;
  }
  return null;
}
