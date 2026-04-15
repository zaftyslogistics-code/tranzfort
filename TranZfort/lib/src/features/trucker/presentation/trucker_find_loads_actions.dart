part of 'trucker_find_loads_screen.dart';

Future<void> _startChatFromFeedAction(
  BuildContext context,
  WidgetRef ref,
  MarketplaceLoadItem load,
) async {
  final l10n = AppLocalizations.of(context);
  final profileAsync = ref.read(truckerProfileProvider);
  final profile = profileAsync.valueOrNull;

  if (profileAsync.isLoading) {
    AppSnackbar.show(
      context: context,
      message: 'Loading profile...',
      variant: AppSnackbarVariant.info,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) {
      return;
    }
    final updatedProfile = ref.read(truckerProfileProvider).valueOrNull;
    if (updatedProfile == null || !updatedProfile.isVerified) {
      AppSnackbar.show(
        context: context,
        message: l10n.truckerLoadDetailVerificationRequiredMessage,
        variant: AppSnackbarVariant.info,
      );
      return;
    }
  } else if (profile == null || !profile.isVerified) {
    AppSnackbar.show(
      context: context,
      message: l10n.truckerLoadDetailVerificationRequiredMessage,
      variant: AppSnackbarVariant.info,
    );
    return;
  }

  if (!context.mounted) {
    return;
  }
  final truckerId = profile?.id ?? ref.read(truckerProfileProvider).valueOrNull?.id ?? '';
  if (truckerId.isEmpty) {
    AppSnackbar.show(
      context: context,
      message: l10n.truckerLoadDetailVerificationRequiredMessage,
      variant: AppSnackbarVariant.info,
    );
    return;
  }

  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
        supplierId: load.supplierId,
        truckerId: truckerId,
        loadId: load.id,
      );
  if (!context.mounted) {
    return;
  }
  result.when(
    success: (conversationId) {
      context.push('${AppRoutes.chatPath}/$conversationId');
    },
    failure: (failure) {
      AppSnackbar.show(
        context: context,
        message: l10n.truckerLoadChatStartFailureMessage,
        variant: AppSnackbarVariant.error,
      );
    },
  );
}

Future<void> _callSupplierFromFeedAction(
  BuildContext context,
  WidgetRef ref,
  MarketplaceLoadItem load,
) async {
  final l10n = AppLocalizations.of(context);
  final profileAsync = ref.read(truckerProfileProvider);
  final profile = profileAsync.valueOrNull;

  if (profileAsync.isLoading) {
    AppSnackbar.show(
      context: context,
      message: 'Loading profile...',
      variant: AppSnackbarVariant.info,
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (!context.mounted) {
      return;
    }
    final updatedProfile = ref.read(truckerProfileProvider).valueOrNull;
    if (updatedProfile == null || !updatedProfile.isVerified) {
      AppSnackbar.show(
        context: context,
        message: l10n.truckerLoadDetailVerificationRequiredMessage,
        variant: AppSnackbarVariant.info,
      );
      return;
    }
  } else if (profile == null || !profile.isVerified) {
    AppSnackbar.show(
      context: context,
      message: l10n.truckerLoadDetailVerificationRequiredMessage,
      variant: AppSnackbarVariant.info,
    );
    return;
  }

  if (!context.mounted) {
    return;
  }
  final truckerId = profile?.id ?? ref.read(truckerProfileProvider).valueOrNull?.id ?? '';
  if (truckerId.isEmpty) {
    AppSnackbar.show(
      context: context,
      message: l10n.truckerLoadDetailVerificationRequiredMessage,
      variant: AppSnackbarVariant.info,
    );
    return;
  }

  final result = await ref.read(chatRepositoryProvider).createOrGetConversation(
        supplierId: load.supplierId,
        truckerId: truckerId,
        loadId: load.id,
      );
  if (!context.mounted) {
    return;
  }
  result.when(
    success: (conversationId) async {
      final mobileResult = await ref.read(truckerMarketplaceRepositoryProvider).getSupplierMobile(load.supplierId);
      if (!context.mounted) {
        return;
      }
      mobileResult.when(
        success: (mobile) async {
          if (mobile != null && mobile.isNotEmpty) {
            final uri = Uri.parse('tel:$mobile');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (!context.mounted) {
                return;
              }
              AppSnackbar.show(
                context: context,
                message: 'Unable to make phone calls on this device',
                variant: AppSnackbarVariant.info,
              );
            }
          } else {
            AppSnackbar.show(
              context: context,
              message: 'Supplier phone number not available',
              variant: AppSnackbarVariant.info,
            );
          }
        },
        failure: (failure) {
          AppSnackbar.show(
            context: context,
            message: 'Failed to get supplier number',
            variant: AppSnackbarVariant.error,
          );
        },
      );
    },
    failure: (failure) {
      AppSnackbar.show(
        context: context,
        message: 'Failed to start conversation',
        variant: AppSnackbarVariant.error,
      );
    },
  );
}
