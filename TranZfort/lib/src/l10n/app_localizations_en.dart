// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TranZfort';

  @override
  String get authGoogleFailureMessage =>
      'We could not continue with Google right now. Retry shortly or use email sign-in instead.';

  @override
  String get authWelcomeTitle => 'Welcome to TranZfort';

  @override
  String get authWelcomeSubtitle =>
      'Choose Google or email sign-in to continue into your supplier or trucker workspace.';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authForgotPasswordAction => 'Forgot password?';

  @override
  String get authConfigIncompleteSignInMessage =>
      'Supabase is not configured in this build, so sign-in and live account data will remain unavailable until the environment is fixed.';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authOrWithEmail => 'Or continue with email';

  @override
  String get authPasswordTitle => 'Email and password';

  @override
  String get authPasswordSubtitle =>
      'Sign in with your email and password, or create a new TranZfort account to continue.';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordConfirmLabel => 'Confirm password';

  @override
  String get authPasswordHint => 'Enter at least 8 characters';

  @override
  String get authPasswordModeSignIn => 'Sign in';

  @override
  String get commonCreateAccountAction => 'Create account';

  @override
  String get authPasswordSwitchToSignIn => 'Already have an account? Sign in';

  @override
  String get authPasswordSwitchToSignUp => 'New to TranZfort? Create account';

  @override
  String get authPasswordSignInAction => 'Sign in with password';

  @override
  String get authPasswordInvalidEmailMessage => 'Enter a valid email address.';

  @override
  String get authPasswordTooShortMessage =>
      'Enter a password with at least 8 characters.';

  @override
  String get authPasswordConfirmMismatchMessage =>
      'The password confirmation does not match.';

  @override
  String get authPasswordSignInFailureMessage =>
      'We could not sign you in with email and password right now. Retry shortly or use another sign-in method.';

  @override
  String get authPasswordSignUpFailureMessage =>
      'We could not create your account right now. Retry shortly with the same details.';

  @override
  String get authPasswordCheckEmailTitle => 'Check your email';

  @override
  String authPasswordCheckEmailSubtitle(Object email) {
    return 'We sent a verification link to $email. Open that email, finish verification, and then return here to sign in.';
  }

  @override
  String get authPasswordResendVerificationAction =>
      'Resend verification email';

  @override
  String authPasswordResendVerificationSuccessMessage(Object email) {
    return 'We sent a fresh verification email to $email. Open it, finish verification, and then sign in.';
  }

  @override
  String get authPasswordResendVerificationFailureMessage =>
      'We could not resend the verification email right now. Retry shortly or use a different email.';

  @override
  String get commonBackToSignInAction => 'Back to sign in';

  @override
  String get authPasswordUseDifferentEmailAction => 'Use a different email';

  @override
  String get authErrorEmailRequired => 'Email is required';

  @override
  String get authErrorEmailInvalid => 'Please enter a valid email';

  @override
  String get authErrorPasswordRequired => 'Password is required';

  @override
  String get authErrorPasswordTooShort =>
      'Password must be at least 8 characters';

  @override
  String get authErrorUserNotFound => 'User not found';

  @override
  String get authErrorWrongPassword => 'Incorrect password';

  @override
  String get authErrorEmailAlreadyInUse => 'Email already registered';

  @override
  String get authErrorWeakPassword => 'Password is too weak';

  @override
  String get authRoleRequired => 'Select a valid role to continue';

  @override
  String get authNameTooShort => 'Enter your full name';

  @override
  String get authMobileRequired => 'Enter a valid mobile number';

  @override
  String get authLanguageUnsupported => 'Select a supported language';

  @override
  String get authUnexpectedResponse =>
      'Unexpected response format from account deletion request';

  @override
  String get authGoogleNotConfigured =>
      'Google sign-in is not configured. Set GOOGLE_WEB_CLIENT_ID in the app environment and retry.';

  @override
  String get authGoogleSignInCancelled =>
      'Google sign in was cancelled. Please try again.';

  @override
  String get authGoogleTokenFetchFailed =>
      'Unable to fetch Google sign-in token. Please try again.';

  @override
  String get onboardingDiscardRoleTitle => 'Discard role selection?';

  @override
  String get onboardingDiscardRoleMessage => 'Your selected role will be lost';

  @override
  String get onboardingDiscardChangesTitle => 'Discard changes?';

  @override
  String get onboardingDiscardChangesMessage =>
      'Your unsaved changes will be lost';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String get locationPermissionDenied => 'Location permission was denied';

  @override
  String get locationEnableGps => 'Enable GPS';

  @override
  String get locationEnableServicesMessage =>
      'Please enable location services (GPS) to capture your current location.';

  @override
  String get locationGrantPermissionMessage =>
      'Please grant location permission to capture your current location.';

  @override
  String get locationOpenSettings => 'Open Settings';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Location permission was permanently denied. Please enable it in app settings.';

  @override
  String get searchYourLocation => 'Search your location';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get addManually => 'Add manually';

  @override
  String get clearLocation => 'Clear location';

  @override
  String get routePreviewInvalidError => 'Unable to load route preview';

  @override
  String get publicProfileLoadErrorTitle => 'Failed to load profile';

  @override
  String get publicProfileNotFoundTitle => 'Profile not found';

  @override
  String get supplierPostLoadSpecifyMaterialLabel => 'Specify Material';

  @override
  String get supplierPostLoadSpecifyMaterialHint =>
      'e.g., Fruits, Iron Ore, Bricks';

  @override
  String get supplierPostLoadMaterialCoal => 'Coal';

  @override
  String get supplierPostLoadMaterialSteel => 'Steel';

  @override
  String get supplierPostLoadMaterialCement => 'Cement';

  @override
  String get supplierPostLoadMaterialGrains => 'Grains';

  @override
  String get supplierPostLoadMaterialFertilizer => 'Fertilizer';

  @override
  String get supplierPostLoadMaterialMachinery => 'Machinery';

  @override
  String get supplierPostLoadMaterialOther => 'Other';

  @override
  String get supplierPostLoadBodyTypeAny => 'Any';

  @override
  String get supplierPostLoadBodyTypeOpen => 'Open';

  @override
  String get supplierPostLoadBodyTypeContainer => 'Container';

  @override
  String get supplierPostLoadBodyTypeTrailer => 'Trailer';

  @override
  String get supplierPostLoadBodyTypeTanker => 'Tanker';

  @override
  String get supplierPostLoadBodyTypeRefrigerated => 'Refrigerated';

  @override
  String get postLoadValidationCustomMaterialRequired =>
      'Please specify the material';

  @override
  String get supplierLoadSubmissionAlreadyInProgress =>
      'Load submission is already in progress';

  @override
  String get onboardingSelectRoleError =>
      'Select whether you are joining as a supplier or trucker.';

  @override
  String get onboardingRoleWorkspaceFailure =>
      'We could not prepare your role workspace right now. Retry shortly after selecting your role again.';

  @override
  String get onboardingRoleSaveFailure =>
      'We could not save your role right now. Retry shortly.';

  @override
  String get onboardingChooseRoleTitle => 'Choose role';

  @override
  String get onboardingRoleQuestion => 'Which role fits your work?';

  @override
  String get onboardingRoleSubtitle =>
      'Your role decides the tools, dashboard, and workflows TranZfort will prepare for you.';

  @override
  String get onboardingSupplierTitle => 'Supplier';

  @override
  String get onboardingSupplierSubtitle =>
      'Post loads, review bookings, manage trips, and track delivery follow-through.';

  @override
  String get onboardingTruckerTitle => 'Trucker';

  @override
  String get onboardingTruckerSubtitle =>
      'Find loads, manage fleet readiness, and execute active trips from one place.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingProfileSaveFailure =>
      'We could not save your profile right now. Review the details and retry shortly.';

  @override
  String get onboardingCompleteProfileTitle => 'Complete profile';

  @override
  String get onboardingCompleteProfileHeading => 'Finish your basic profile';

  @override
  String get onboardingCompleteProfileSubtitle =>
      'Add the core contact details that will follow you through verification and daily operations.';

  @override
  String get onboardingFullNameLabel => 'Full name';

  @override
  String get onboardingFullNameHint => 'Enter your full name';

  @override
  String get onboardingMobileLabel => 'Mobile number';

  @override
  String get onboardingTermsAcceptance =>
      'By continuing, you confirm that your basic profile details are accurate and that you agree to the platform terms.';

  @override
  String get onboardingSaveAndContinue => 'Save and continue';

  @override
  String get commonRetryAction => 'Retry';

  @override
  String get shellPressBackAgainToExit => 'Press back again to exit';

  @override
  String get commonNotificationsLabel => 'Notifications';

  @override
  String get supplierMyLoadsTitle => 'My loads';

  @override
  String get supplierMyLoadsSubtitle =>
      'Monitor active supplier loads, booking demand, and completed load history from one place.';

  @override
  String get commonActiveLabel => 'Active';

  @override
  String get commonCompletedLabel => 'Completed';

  @override
  String get supplierMyLoadsLoadFailureTitle =>
      'Unable to load your supplier loads';

  @override
  String get supplierMyLoadsFailureMessage =>
      'We could not load your supplier loads right now. Retry shortly to refresh the latest load list.';

  @override
  String get supplierMyLoadsEmptyActiveTitle => 'No active loads yet';

  @override
  String get supplierMyLoadsEmptyCompletedTitle => 'No completed loads yet';

  @override
  String get supplierMyLoadsEmptyActiveSubtitle =>
      'Post your first load to start receiving booking requests and execution updates here.';

  @override
  String get supplierMyLoadsEmptyCompletedSubtitle =>
      'Completed, cancelled, expired, and externally filled loads will appear here once active work is closed out.';

  @override
  String get supplierMyLoadsOpenActiveLoads => 'Open active loads';

  @override
  String get supplierMyLoadsMoreUnavailableTitle =>
      'Unable to load more supplier loads';

  @override
  String get supplierMyLoadsPaginationFailureMessage =>
      'We could not load more supplier loads right now. Retry shortly to refresh the latest load history.';

  @override
  String get supplierMyLoadsLoadingMore => 'Loading more loads...';

  @override
  String get supplierMyLoadsLoadMore => 'Load more loads';

  @override
  String supplierLoadCardPickupDate(Object value) {
    return 'Pickup $value';
  }

  @override
  String supplierLoadCardTrucks(Object booked, Object needed) {
    return '$booked/$needed trucks booked';
  }

  @override
  String get supplierLoadCardTrackLoad => 'Track load';

  @override
  String get supplierLoadCardViewHistory => 'View history';

  @override
  String get commonViewDetailsAction => 'View details';

  @override
  String get supplierRecentLoadsTitle => 'Recent loads';

  @override
  String supplierDashboardWelcomeBack(Object name) {
    return 'Welcome back, $name';
  }

  @override
  String get commonDashboardOverviewTitle => 'Dashboard overview';

  @override
  String get supplierDashboardSuperLoadReadinessTitle => 'Super Load readiness';

  @override
  String get commonQuickActionsTitle => 'Quick actions';

  @override
  String get commonChatLabel => 'Chat';

  @override
  String get commonPostLoadAction => 'Post Load';

  @override
  String get supplierDashboardStatsActiveLoadsLabel => 'Active loads';

  @override
  String get supplierDashboardStatsPendingBookingsLabel => 'Pending bookings';

  @override
  String get supplierDashboardStatsInTransitTripsLabel => 'Trips in transit';

  @override
  String get supplierDashboardStatsCompletedTripsLabel => 'Completed trips';

  @override
  String get commonOpenMyLoadsAction => 'Open my loads';

  @override
  String get supplierDashboardLoadFailureTitle =>
      'Unable to load your supplier dashboard';

  @override
  String get supplierDashboardLoadFailureMessage =>
      'We could not load your supplier dashboard right now. Retry shortly to refresh the latest overview metrics.';

  @override
  String get supplierDashboardAccountStateUnavailableTitle =>
      'Supplier account state unavailable';

  @override
  String get supplierDashboardAccountStateUnavailableMessage =>
      'We could not load your current supplier account state right now. Retry shortly to restore the latest verification and company details.';

  @override
  String get supplierDashboardRecentLoadsUnavailableTitle =>
      'Recent loads unavailable';

  @override
  String get supplierDashboardRecentLoadsUnavailableMessage =>
      'We could not load your recent supplier loads right now. Retry shortly to refresh the latest load list.';

  @override
  String get supplierDashboardNoLoadsPostedTitle => 'No loads posted yet';

  @override
  String get supplierDashboardNoLoadsPostedSubtitle =>
      'Post your first supplier load to start receiving booking requests and linked trip activity.';

  @override
  String get shellTabHome => 'Home';

  @override
  String get shellTitleSupplierDashboard => 'Supplier dashboard';

  @override
  String get shellTabLoads => 'Loads';

  @override
  String get shellTitleMyLoads => 'My Loads';

  @override
  String get commonTripsLabel => 'Trips';

  @override
  String get commonDashboardLabel => 'Dashboard';

  @override
  String get shellTabFind => 'Find';

  @override
  String get shellTitleFindLoads => 'Find Loads';

  @override
  String get shellDrawerSupplierWorkspace => 'Supplier workspace';

  @override
  String get shellDrawerTruckerWorkspace => 'Trucker workspace';

  @override
  String get commonFleetLabel => 'Fleet';

  @override
  String get commonSupportLabel => 'Support';

  @override
  String get commonProfileLabel => 'Profile';

  @override
  String get commonSignOutAction => 'Sign out';

  @override
  String get shellSignOutFailureMessage =>
      'We could not sign you out right now. Retry shortly.';

  @override
  String get shellMessagesTitle => 'Messages';

  @override
  String get shellMessagesSupplierSubtitle =>
      'Track load-linked conversations with truckers and reply quickly from one place.';

  @override
  String get shellMessagesTruckerSubtitle =>
      'Stay on top of supplier updates, route context, and booking follow-through in one inbox.';

  @override
  String get shellMessagesSupplierGroupedInbox => 'Grouped inbox';

  @override
  String get shellMessagesTruckerFlatInbox => 'Flat inbox';

  @override
  String shellMessagesUnreadThreads(int count) {
    return '$count unread threads';
  }

  @override
  String get shellMessagesLoadFailureTitle => 'Could not load messages';

  @override
  String get shellMessagesEmptyTitle => 'No conversations yet';

  @override
  String get shellMessagesSupplierEmptySubtitle =>
      'Load-linked trucker conversations will appear here after the first message arrives.';

  @override
  String get shellMessagesTruckerEmptySubtitle =>
      'Start a chat by booking a load and your supplier conversations will show here.';

  @override
  String shellMessagesActiveConversations(int count, Object preview) {
    return '$count active conversations - $preview';
  }

  @override
  String get shellMessagesUnreadStatus => 'Unread';

  @override
  String get shellMessagesReadStatus => 'Read';

  @override
  String get shellMessagesHideTruckerConversations =>
      'Hide trucker conversations';

  @override
  String shellMessagesLatestBy(Object name, Object timestamp) {
    return 'Latest by $name - $timestamp';
  }

  @override
  String get truckerChatSupplierAction => 'Chat with supplier';

  @override
  String get truckerLoadChatStartFailureMessage =>
      'We could not start this supplier chat right now. Retry shortly from the load detail.';

  @override
  String get truckerTripChatStartFailureMessage =>
      'We could not start this supplier chat right now. Retry shortly from the trip detail.';

  @override
  String truckerChatLockedLabel(Object reason) {
    return 'Chat unavailable: $reason';
  }

  @override
  String get chatTitleFallback => 'Conversation';

  @override
  String get commonCallAction => 'Call';

  @override
  String chatReportSourceLabel(Object source) {
    return 'Chat - $source';
  }

  @override
  String get chatMenuMarkConversationRead => 'Mark conversation read';

  @override
  String get chatMenuRefreshThread => 'Refresh thread';

  @override
  String get commonReportSpamOrAbuseAction => 'Report spam or abuse';

  @override
  String get chatConversationUnavailableTitle => 'Conversation unavailable';

  @override
  String get chatConversationUnavailableSubtitle =>
      'We could not find this conversation right now. Refresh or return to your inbox.';

  @override
  String get chatBackToInboxAction => 'Back to messages';

  @override
  String get chatBookingActionUnavailableTitle => 'Booking action unavailable';

  @override
  String get chatBookingActionFailureMessage =>
      'The latest booking action could not be completed from this chat. Review the booking state and retry shortly.';

  @override
  String get chatApproveBookingDialogTitle => 'Approve booking?';

  @override
  String get chatApproveBookingDialogMessage =>
      'This will approve the trucker booking request from the chat context.';

  @override
  String get chatRejectBookingDialogTitle => 'Reject booking?';

  @override
  String get chatRejectBookingDialogMessage =>
      'This will reject the trucker booking request from the chat context.';

  @override
  String get commonCancelAction => 'Cancel';

  @override
  String get commonDiscardAction => 'Discard';

  @override
  String get chatActionApprove => 'Approve';

  @override
  String get chatActionReject => 'Reject';

  @override
  String get chatBookingApprovedSuccess => 'Booking approved!';

  @override
  String get chatBookingRejectedSuccess => 'Booking rejected.';

  @override
  String get chatTextSendFailureMessage =>
      'We could not send your message right now. Retry shortly from this chat.';

  @override
  String get chatVoiceStartFailureMessage =>
      'We could not start voice recording right now. Retry shortly from this chat.';

  @override
  String get chatVoiceUploadFailureMessage =>
      'We could not upload this voice message right now. Retry shortly from this chat.';

  @override
  String get chatVoiceSendFailureMessage =>
      'We could not send this voice message right now. Retry shortly from this chat.';

  @override
  String get chatApproveBookingFailureMessage =>
      'We could not approve this booking right now. Retry shortly from this chat.';

  @override
  String get chatRejectBookingFailureMessage =>
      'We could not reject this booking right now. Retry shortly from this chat.';

  @override
  String get chatLoadContextTitle => 'Load context';

  @override
  String get chatCollapseLoadContextTooltip => 'Collapse load context';

  @override
  String get chatExpandLoadContextTooltip => 'Expand load context';

  @override
  String chatMaterialLabel(Object value) {
    return 'Material: $value';
  }

  @override
  String chatPriceLabel(Object value) {
    return 'Price: $value';
  }

  @override
  String chatPickupLabel(Object value) {
    return 'Pickup: $value';
  }

  @override
  String get chatBookingStatusApproved => 'Approved';

  @override
  String get commonUnknownLabel => 'Unknown';

  @override
  String get chatMessagesLoadFailureTitle => 'Unable to load messages';

  @override
  String get chatMessagesLoadFailureMessage =>
      'We could not load this conversation right now. Retry shortly to refresh the latest messages and booking context.';

  @override
  String get chatNoMessagesTitle => 'No messages yet';

  @override
  String get chatNoMessagesSubtitle =>
      'Send a message to start this conversation.';

  @override
  String get commonSystemUpdateLabel => 'System update';

  @override
  String get chatSendingLabel => 'sending...';

  @override
  String get chatPauseVoiceMessageTooltip => 'Pause voice message';

  @override
  String get chatPlayVoiceMessageTooltip => 'Play voice message';

  @override
  String get commonVoiceMessageLabel => 'Voice message';

  @override
  String get chatVoicePlaybackUnavailable =>
      'Voice playback is unavailable right now.';

  @override
  String get chatVoicePlaybackFailed =>
      'We could not play this voice message right now.';

  @override
  String get chatLocationSharedFallback => 'Shared location';

  @override
  String get chatMapPreviewUnavailable => 'Map preview unavailable';

  @override
  String get chatOpenInMapsAction => 'Open in Maps';

  @override
  String get chatDocumentSharedFallback => 'Shared document';

  @override
  String get chatAttachmentSavedSubtitle =>
      'Attachment saved to this conversation.';

  @override
  String get chatOpenDocumentAction => 'Open document';

  @override
  String get chatRouteSummaryFallback => 'Route summary';

  @override
  String get chatViewRouteAction => 'View route';

  @override
  String get commonTruckDetailsLabel => 'Truck details';

  @override
  String chatTruckTyresLabel(Object value) {
    return '$value tyres';
  }

  @override
  String get chatTypeMessageHint => 'Type a message...';

  @override
  String get chatStopRecordingTooltip => 'Stop recording';

  @override
  String get chatVoiceRecordingTooltip => 'Voice recording';

  @override
  String get chatSendAction => 'Send';

  @override
  String get commonHearSummary => 'Hear summary';

  @override
  String get commonVoiceMuted => 'Voice guidance is muted on this device.';

  @override
  String get commonVoiceUnavailable =>
      'Voice guidance is unavailable right now.';

  @override
  String get notificationsMarkedAllReadSuccess =>
      'All notifications marked as read';

  @override
  String get notificationsMarkAllRead => 'Mark All Read';

  @override
  String get notificationsLoadFailureTitle => 'Unable to load notifications';

  @override
  String get notificationsMarkAllReadFailureMessage =>
      'We could not mark all notifications as read right now. Retry shortly from the notifications screen.';

  @override
  String get notificationsLoadFailureMessage =>
      'We could not load your notifications right now. Retry shortly to refresh the latest alerts and updates.';

  @override
  String get notificationsEmptyTitle => 'All caught up!';

  @override
  String get notificationsEmptySubtitle => 'No new notifications.';

  @override
  String get notificationsOverviewTitle => 'Overview';

  @override
  String notificationsUnreadCountLabel(int count) {
    return '$count unread';
  }

  @override
  String notificationsHighPriorityCountLabel(int count) {
    return '$count high priority';
  }

  @override
  String get commonLoadMoreAction => 'Load More';

  @override
  String notificationsTtsSummary(int unreadCount, int highPriorityUnreadCount) {
    return 'Notifications screen. You have $unreadCount unread notifications and $highPriorityUnreadCount high priority alerts pending review.';
  }

  @override
  String get notificationsGroupToday => 'Today';

  @override
  String get notificationsGroupYesterday => 'Yesterday';

  @override
  String get notificationsPriorityHighLabel => 'HIGH';

  @override
  String get notificationsBodyFallback =>
      'Open the linked workflow for full context.';

  @override
  String notificationFallbackValue(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'verification_update': 'Verification update',
      'booking_update': 'Booking update',
      'trip_update': 'Trip update',
      'proof_update': 'Proof update',
      'super_load_update': 'Super Load update',
      'message_received': 'New message',
      'support_update': 'Support update',
      'dispute_update': 'Dispute update',
      'account_update': 'Account update',
      'system_notice': 'System notice',
      'load_expiry_warning': 'Load expiry warning',
      'other': 'Notification',
    });
    return '$_temp0';
  }

  @override
  String get navDeleteAccount => 'Delete account';

  @override
  String get deleteAccountRequestedOnLabel => 'Deletion requested on';

  @override
  String get deleteAccountGracePeriodEndsLabel => 'Grace period ends';

  @override
  String get deleteAccountGracePeriodPassedLabel =>
      'Grace-period end date has passed. Permanent deletion processing may happen at any time.';

  @override
  String get deleteAccountGracePeriodLessThanOneDayLabel =>
      'Less than 1 day remains before the grace period ends.';

  @override
  String deleteAccountGracePeriodRemainingDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days remain before the grace period ends.',
      one: '$count day remains before the grace period ends.',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccountLifecycleFailureMessage =>
      'The account deletion lifecycle is temporarily unavailable. Retry shortly to refresh the latest deletion status.';

  @override
  String get deleteAccountCancelFailureMessage =>
      'We could not cancel this deletion request right now. Retry shortly from the deletion lifecycle screen.';

  @override
  String get deleteAccountRequestFailureMessage =>
      'We could not process this deletion request right now. Review the current account status and retry shortly.';

  @override
  String get deleteAccountAcceptedSignOutFailureMessage =>
      'Deletion was accepted, but we could not complete sign out right now. Retry shortly to refresh your account session.';

  @override
  String get deleteAccountBlockedSummaryMessage =>
      'This deletion request cannot proceed yet because another account dependency still needs attention.';

  @override
  String get deleteAccountCancelledMessage =>
      'Your deletion request was cancelled. Account access can be restored while the lifecycle returns to active.';

  @override
  String get deleteAccountAcceptedMessage =>
      'Your deletion request was accepted. You have been signed out while the account enters pending cleanup.';

  @override
  String get deleteAccountBlockerRecoveryGuidanceActiveTrips =>
      'Finish or cancel every active trip first, then retry the deletion request.';

  @override
  String get deleteAccountBlockerRecoveryGuidanceDispute =>
      'Wait until the unresolved dispute is reviewed or resolved before requesting deletion again.';

  @override
  String get deleteAccountBlockerRecoveryGuidanceCompliance =>
      'Some records still need to stay on the platform for compliance or retention policy. Use support if you need clarification on the hold.';

  @override
  String get deleteAccountBlockerRecoveryGuidanceDefault =>
      'Resolve the blocking dependency first, then request deletion again.';

  @override
  String get deleteAccountBlockerActionOpenTrips => 'Open trips';

  @override
  String get commonOpenSupportAction => 'Open support';

  @override
  String get deleteAccountBlockerTitleActiveTrips =>
      'Finish active trips first';

  @override
  String get deleteAccountBlockerTitleDispute =>
      'Resolve the open dispute first';

  @override
  String get deleteAccountBlockerTitleCompliance =>
      'Wait for the compliance hold to clear';

  @override
  String get deleteAccountBlockerTitleDefault => 'Resolve the blocker first';

  @override
  String get deleteAccountBlockerBodyActiveTrips =>
      'This account still has active trip work attached to it. Review the current trip list, complete any legitimate active work, and then retry the deletion request.';

  @override
  String get deleteAccountBlockerBodyDispute =>
      'This account still has an unresolved dispute or review dependency. Use support to follow the current case until the blocking dispute is resolved.';

  @override
  String get deleteAccountBlockerBodyCompliance =>
      'This account is still under a compliance or retention hold. Support can clarify the current hold, but the platform cannot bypass the retention requirement.';

  @override
  String get deleteAccountBlockerBodyDefault =>
      'Review the current blocker carefully and resolve it before retrying the deletion request.';

  @override
  String get deleteAccountSupportTitle => 'Need help first?';

  @override
  String get deleteAccountSupportBodyPendingCleanup =>
      'Use support if you need clarification on the pending-cleanup status, the grace-period timeline, or whether cancellation is the right next step for this account.';

  @override
  String get deleteAccountSupportBodyDefault =>
      'Use support if you expect blockers like active trips, unresolved disputes, or compliance holds and need clarification before retrying the deletion request.';

  @override
  String get deleteAccountSupportDetailPendingCleanup =>
      'Support can clarify the current lifecycle state, but they may still need to follow retention and compliance policy before permanent deletion is processed.';

  @override
  String get deleteAccountSupportDetailDefault =>
      'Support can explain the current blocker or retention requirement, but they cannot bypass required cleanup, dispute review, or compliance policy.';

  @override
  String get commonWhatHappensNextTitle => 'What happens next';

  @override
  String get deleteAccountWhatHappensNextBodyPendingCleanup =>
      'Your account is already in the pending-cleanup state. Cancel the request if you want to restore the account to active before permanent deletion is processed.';

  @override
  String get deleteAccountWhatHappensNextBodyDefault =>
      'If no blockers exist, your account is moved to deactivated pending cleanup and you are signed out safely.';

  @override
  String get deleteAccountWhatHappensNextDetailPendingCleanup =>
      'If you cancel now, the account deletion status returns to active and normal access is restored.';

  @override
  String get deleteAccountWhatHappensNextDetailDefault =>
      'If blockers exist, the platform keeps your account active and tells you which dependency must be resolved first.';

  @override
  String get deleteAccountWhatHappensNextFootnotePendingCleanup =>
      'Support may still retain internal records according to policy, but the user-facing deletion request will be cancelled.';

  @override
  String get deleteAccountWhatHappensNextFootnoteDefault =>
      'The deletion request can now be cancelled while the account is in the pending-cleanup lifecycle before permanent deletion is processed.';

  @override
  String get deleteAccountLifecycleUnavailableTitle =>
      'Account deletion lifecycle unavailable';

  @override
  String get deleteAccountCancelledTitle => 'Deletion request cancelled';

  @override
  String get deleteAccountAlreadyRequestedTitle => 'Deletion already requested';

  @override
  String get deleteAccountAlreadyRequestedMessage =>
      'This account is currently deactivated pending cleanup. Cancel the request below if you need to restore access during the grace-period lifecycle.';

  @override
  String get commonCancelDeletionRequestAction => 'Cancel deletion request';

  @override
  String get deleteAccountCancellingButton => 'Cancelling deletion...';

  @override
  String get deleteAccountUnavailableTitle => 'Account deletion unavailable';

  @override
  String get deleteAccountBlockedTitle => 'Deletion blocked';

  @override
  String get deleteAccountConfirmRequestTitle => 'Confirm deletion request';

  @override
  String get deleteAccountRequestingButton => 'Requesting deletion...';

  @override
  String get deleteAccountScreenTitle => 'Delete Account';

  @override
  String get deleteAccountHeroTitlePendingCleanup =>
      'Account deletion pending cleanup';

  @override
  String get deleteAccountHeroTitleDefault => 'Request account deletion';

  @override
  String get deleteAccountHeroSubtitlePendingCleanup =>
      'Your account is currently deactivated pending cleanup. You can still cancel this request during the grace-period lifecycle while the account is not permanently deleted.';

  @override
  String get deleteAccountHeroSubtitleDefault =>
      'This action can deactivate your account immediately if no active blockers exist. Review the consequences carefully before continuing.';

  @override
  String get deleteAccountHeroBodyPendingCleanup =>
      'The deletion request has already been accepted and the account is in pending-cleanup state. Cancel the request if you want to restore normal account access before permanent deletion is processed.';

  @override
  String get deleteAccountHeroBodyDefault =>
      'Before deletion can proceed, the platform checks for active trips, unresolved disputes, and compliance or verification records that still require retention.';

  @override
  String get accountSignOutFailureMessage =>
      'We could not sign you out right now. Retry shortly from this screen.';

  @override
  String accountRoleValue(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'supplier': 'Supplier',
      'trucker': 'Trucker',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get accountStatusTitle => 'Account status';

  @override
  String get accountProfileStatusLabel => 'Profile status';

  @override
  String get accountProfileStatusComplete => 'Complete';

  @override
  String get accountProfileStatusNeedsAttention => 'Needs attention';

  @override
  String get accountAccountStateLabel => 'Account state';

  @override
  String accountStateValue(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'deactivated_pending_cleanup': 'Deactivated pending cleanup',
      'restricted': 'Restricted',
      'active': 'Active',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get accountLoadFailureTitle => 'Account details unavailable';

  @override
  String get accountLoadFailureMessage =>
      'We could not load your account details right now. Retry shortly from this screen.';

  @override
  String get accountManageTitle => 'Manage account';

  @override
  String get accountVerificationLabel => 'Verification';

  @override
  String get accountSettingsLabel => 'Settings';

  @override
  String get accountSessionTitle => 'Current session';

  @override
  String get accountSignedInAsLabel => 'Signed in as';

  @override
  String get accountCurrentAuthenticatedSession =>
      'Current authenticated session';

  @override
  String get profileLoadFailureTitle => 'Profile unavailable';

  @override
  String get profileLoadFailureMessage =>
      'We could not load your profile right now. Retry shortly from this screen.';

  @override
  String get profileSummaryTitle => 'Profile summary';

  @override
  String get profileNameLabel => 'Name';

  @override
  String get profileValueNotSet => 'Not set';

  @override
  String get profilePhoneLabel => 'Phone';

  @override
  String get profileValueNotProvided => 'Not provided';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileLocationLabel => 'Location';

  @override
  String get profileLocationNotSet => 'Not set';

  @override
  String get profileReadinessTitle => 'Profile readiness';

  @override
  String get profileCompletenessLabel => 'Completeness';

  @override
  String get profileCompletenessComplete => 'Complete';

  @override
  String get profileCompletenessNeedsUpdates => 'Needs updates';

  @override
  String get profileDeletionStatusLabel => 'Deletion status';

  @override
  String get profileOpenFleetReadiness => 'Open fleet readiness';

  @override
  String get profileRequestAccountDeletion => 'Request account deletion';

  @override
  String profileTtsSummary(
    Object roleLabel,
    Object trustStatus,
    Object deletionStatus,
  ) {
    return 'Profile screen. Role is $roleLabel. Trust and safety status is $trustStatus. Account deletion status is $deletionStatus. You can open deletion follow-up or support guidance from this screen if needed.';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPreferencesTitle => 'Preferences';

  @override
  String get settingsRoleContextLabel => 'Role context';

  @override
  String settingsTtsSummary(Object selectedLanguageLabel, Object roleSentence) {
    return 'Settings screen. Language is set to $selectedLanguageLabel. Voice guidance is manual right now. Notifications are enabled through the in-app inbox.$roleSentence';
  }

  @override
  String get settingsVoiceAssistanceLabel => 'Voice assistance';

  @override
  String get settingsVoiceAssistanceValue =>
      'Manual contextual summaries are available from supported screens.';

  @override
  String get settingsNotificationsValue =>
      'In-app inbox and push status controls are available here.';

  @override
  String get settingsConnectedSurfacesTitle => 'Connected surfaces';

  @override
  String get settingsPushNotificationsTitle => 'Push notifications';

  @override
  String get settingsPushStatusLabel => 'Status';

  @override
  String get settingsPushRequestPermission => 'Request permission';

  @override
  String get settingsPushRefreshStatus => 'Refresh status';

  @override
  String get settingsPushStatusUnavailableTitle =>
      'Push notification status unavailable';

  @override
  String get settingsPushStatusUnavailableMessage =>
      'Unable to read device notification permission right now. Refresh after Firebase/device support is available.';

  @override
  String settingsPushStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'allowed': 'Allowed',
      'allowed_quietly': 'Allowed quietly',
      'blocked': 'Blocked in system settings',
      'not_requested': 'Not requested yet',
      'unavailable': 'Unavailable on this device/build',
      'other': 'Unavailable',
    });
    return '$_temp0';
  }

  @override
  String settingsPushGuidanceValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'allowed':
          'Foreground and opened push flows are enabled when Firebase delivery is configured.',
      'allowed_quietly':
          'Push is allowed quietly. You can promote alerts in the device notification settings if needed.',
      'blocked':
          'Push notifications are blocked. Open your device notification settings for TranZfort to enable alerts again.',
      'not_requested':
          'Push permission has not been requested yet on this device session.',
      'unavailable':
          'Push runtime is unavailable here until Firebase/device support is fully configured.',
      'other':
          'Push runtime is unavailable here until Firebase/device support is fully configured.',
    });
    return '$_temp0';
  }

  @override
  String supportActiveTicketCount(Object count, Object s) {
    return '$count ticket$s';
  }

  @override
  String get supportScreenTitle => 'Support and dispute follow-up';

  @override
  String get supportHeroTitle => 'Review your latest support activity';

  @override
  String get supportHeroSubtitleSupplier =>
      'Use support to review dispute progress, payment follow-ups, and the latest visible ticket updates linked to your supplier activity.';

  @override
  String get supportHeroSubtitleTrucker =>
      'Use support to review dispute progress, freight follow-ups, and the latest visible ticket updates linked to your trucker activity.';

  @override
  String get supportNoActiveTickets => 'No active tickets';

  @override
  String get supportCreateTicketAction => 'Create support ticket';

  @override
  String get supportIntroMessage =>
      'Follow your latest support and dispute tickets here, review visible workflow updates, and reply with any clarification or proof support requested.';

  @override
  String get supportTicketSummaryTitle => 'Support summary';

  @override
  String get supportEscalationPathLabel => 'Escalation path';

  @override
  String get supportEscalationPathSupplier => 'Supplier support';

  @override
  String get supportEscalationPathTrucker => 'Trucker support';

  @override
  String get supportCurrentTrustStatusLabel => 'Current trust status';

  @override
  String get supportMyTicketsTitle => 'My tickets';

  @override
  String get supportSelectedTicketAndReplyTitle => 'Selected ticket and reply';

  @override
  String get supportSelectTicketTitle => 'Select a ticket';

  @override
  String get supportSelectTicketSubtitle =>
      'Choose a support ticket from the list to review its visible thread, workflow state, and reply options.';

  @override
  String get supportTicketsUnavailableTitle => 'Support tickets unavailable';

  @override
  String get supportNoTicketsTitle => 'No support tickets yet';

  @override
  String get supportNoTicketsSubtitle =>
      'Create a support ticket to start a new support or dispute follow-up and track future updates here.';

  @override
  String get supportLoadingOlderTickets => 'Loading older tickets...';

  @override
  String get supportLoadOlderTickets => 'Load older tickets';

  @override
  String get supportTicketsLoadFailureMessage =>
      'We could not load your support tickets right now. Retry shortly to refresh your latest support and dispute activity.';

  @override
  String get supportOpenTripAction => 'Open trip';

  @override
  String get supportOpenLoadAction => 'Open load';

  @override
  String get supportViewingThisTicket => 'Viewing this ticket';

  @override
  String get supportOpenTicketAction => 'Open ticket';

  @override
  String get supportDetailUnavailableTitle => 'Ticket detail unavailable';

  @override
  String get supportDetailUnavailableMessage =>
      'We could not load this ticket detail right now. Retry shortly to refresh the latest visible thread and workflow status.';

  @override
  String get supportTicketUnavailableTitle => 'Ticket unavailable';

  @override
  String get supportTicketUnavailableSubtitle =>
      'This support ticket is unavailable right now for the current account.';

  @override
  String supportTicketStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'open': 'Open',
      'in_progress': 'In progress',
      'waiting_for_you': 'Waiting for you',
      'resolved': 'Resolved',
      'closed': 'Closed',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String supportTicketPriorityValue(String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'low': 'low',
      'medium': 'medium',
      'high': 'high',
      'urgent': 'urgent',
      'not_set': 'not set',
      'other': 'not set',
    });
    return '$_temp0';
  }

  @override
  String get supportTicketTitleTripDisputeReview => 'Trip dispute review';

  @override
  String get supportTicketTitleLoadedQuantityMismatchReport =>
      'Loaded quantity mismatch report';

  @override
  String get supportTicketTitleUnloadedQuantityMismatchReport =>
      'Unloaded quantity mismatch report';

  @override
  String get supportTicketTitleDocumentMismatchReport =>
      'Document mismatch report';

  @override
  String get supportTicketTitleSpamOrScamReport => 'Spam or scam report';

  @override
  String get supportTicketTitleAbusiveBehaviorReport =>
      'Abusive behavior report';

  @override
  String get supportTicketTitleFakePayoutProofReport =>
      'Fake payout proof report';

  @override
  String get supportTicketTitleNonPaymentReport => 'Non-payment report';

  @override
  String get supportTicketTitleDelayOrNoShowReport => 'Delay or no-show report';

  @override
  String get supportTicketTitleDamageOrShortageReport =>
      'Damage or shortage report';

  @override
  String get supportTicketTitleOtherReport => 'Other report';

  @override
  String get supportDisputeCategoryTripDispute => 'Trip dispute';

  @override
  String get supportDisputeCategoryLoadedQuantityMismatch =>
      'Loaded quantity mismatch';

  @override
  String get supportDisputeCategoryUnloadedQuantityMismatch =>
      'Unloaded quantity mismatch';

  @override
  String get supportDisputeCategoryDocumentMismatch => 'Document mismatch';

  @override
  String get supportDisputeCategoryNonPayment => 'Non-payment';

  @override
  String get supportDisputeCategoryFakePayoutProof => 'Fake payout proof';

  @override
  String get supportDisputeCategoryDelayOrNoShow => 'Delay or no-show';

  @override
  String get supportDisputeCategoryDamageOrShortage => 'Damage or shortage';

  @override
  String get supportDisputeCategoryAbusiveBehavior => 'Abusive behavior';

  @override
  String get supportDisputeCategorySpamOrScam => 'Spam or scam';

  @override
  String get supportDisputeCategoryOther => 'Other';

  @override
  String supportUpdatedAt(Object value) {
    return 'Updated at: $value';
  }

  @override
  String get supportTicketReference => 'Support ticket on record';

  @override
  String get supportTripReference => 'Linked trip';

  @override
  String supportOpenedAt(Object value) {
    return 'Opened at: $value';
  }

  @override
  String supportDisputeCategoryLabel(Object category) {
    return 'Dispute category: $category';
  }

  @override
  String get supportTicketIdValue => 'Support ticket on record';

  @override
  String supportPriorityValue(Object priority) {
    return 'Priority: $priority';
  }

  @override
  String supportLastUpdatedValue(Object value) {
    return 'Last updated: $value';
  }

  @override
  String get supportRelatedTripValue => 'Related trip linked';

  @override
  String get supportRelatedLoadValue => 'Related load linked';

  @override
  String get supportOpenRelatedTripAction => 'Open related trip';

  @override
  String get supportOpenRelatedLoadAction => 'Open related load';

  @override
  String get supportWorkflowGuidanceOpen =>
      'Support has received this ticket and review should begin shortly. Use visible replies to add any missing context if needed.';

  @override
  String get supportWorkflowGuidanceInProgress =>
      'Support or operations are actively reviewing this ticket. Watch for visible replies and be ready to clarify the timeline or proof if more detail is requested.';

  @override
  String get supportWorkflowGuidanceWaitingForUser =>
      'Support is waiting on your clarification or proof. Reply on this ticket so the review can continue without unnecessary delay.';

  @override
  String get supportWorkflowGuidanceResolved =>
      'This ticket has reached a final support outcome. Review the recorded resolution before opening any fresh follow-up.';

  @override
  String get supportWorkflowGuidanceUnknown =>
      'Review the latest visible ticket updates for the current workflow state.';

  @override
  String get commonDisputeReviewClosedTitle => 'Dispute review closed';

  @override
  String get supportDisputeBannerTitleWaiting =>
      'Dispute waiting for your reply';

  @override
  String get supportDisputeBannerTitleInProgress =>
      'Dispute review in progress';

  @override
  String supportDisputeBannerMessageClosed(Object category) {
    return 'Category: $category. This trip dispute has reached a final support outcome. Both sides can still follow the recorded ticket context, but raw evidence access may remain restricted.';
  }

  @override
  String supportDisputeBannerMessageWaiting(Object category) {
    return 'Category: $category. This trip dispute is waiting on your clarification or proof. Both sides can follow visible status updates, but raw evidence access may remain restricted during review.';
  }

  @override
  String supportDisputeBannerMessageInProgress(Object category) {
    return 'Category: $category. This trip dispute is under active support review. Both sides can follow visible status updates, but raw evidence access may remain restricted during review.';
  }

  @override
  String get supportEvidenceVisibilitySummaryClosed =>
      'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this ticket.';

  @override
  String get supportEvidenceVisibilitySummaryInProgress =>
      'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible on this ticket.';

  @override
  String get supportRestrictedEvidenceMessageClosed =>
      'Raw attachments and sensitive proof may remain restricted even after the review outcome is recorded on the ticket.';

  @override
  String get supportRestrictedEvidenceMessageInProgress =>
      'Raw attachments and sensitive proof may remain restricted while this review stays active on the ticket.';

  @override
  String get supportAdditionalProofGuidanceClosed =>
      'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have a genuinely new issue or clarification to raise.';

  @override
  String get supportAdditionalProofGuidanceInProgress =>
      'If your dispute depends on additional documents or screenshots beyond the current single-image flow, describe those missing proofs clearly in your visible reply so support knows what else to review.';

  @override
  String get supportAttachmentVisibilityMessageClosed =>
      'Evidence attached to this reply. Raw file access may remain restricted even after the review outcome is recorded on this ticket.';

  @override
  String get supportAttachmentVisibilityMessageInProgress =>
      'Evidence attached to this reply. Raw file access may remain restricted during review.';

  @override
  String get supportAttachmentGuidanceMessageClosed =>
      'If you still need to reference other supporting proofs after closure, open a fresh follow-up only when you have genuinely new context that was not captured on this ticket.';

  @override
  String get supportAttachmentGuidanceMessageInProgress =>
      'If other supporting proofs are not attached here, summarize them in visible reply text so support can request or review them safely.';

  @override
  String get supportSupportTeamLabel => 'Support team';

  @override
  String get supportYouLabel => 'You';

  @override
  String get supportEmptyThreadSubtitleOpen =>
      'No visible thread has been posted on this support ticket yet.';

  @override
  String get supportEmptyThreadSubtitleInProgress =>
      'No visible thread is available yet while this ticket remains under active review.';

  @override
  String get supportEmptyThreadSubtitleWaiting =>
      'No visible thread is available yet. Reply on this ticket so the review can continue.';

  @override
  String get supportEmptyThreadSubtitleResolved =>
      'No visible thread was recorded before this ticket was resolved or closed.';

  @override
  String get supportEmptyThreadSubtitleUnknown =>
      'No visible thread is available for this support ticket yet.';

  @override
  String get supportEvidenceVisibilityTitle => 'Evidence visibility';

  @override
  String get supportVisibleThreadSummaryTitle => 'Visible thread summary';

  @override
  String supportVisibleRepliesCount(int count) {
    return 'Visible replies: $count';
  }

  @override
  String get supportLastVisibleUpdateNone =>
      'Last visible update: No visible replies yet.';

  @override
  String supportLastVisibleUpdate(Object value) {
    return 'Last visible update: $value';
  }

  @override
  String get supportLatestVisibleSenderNone =>
      'Latest visible sender: No visible sender yet.';

  @override
  String supportLatestVisibleSender(Object value) {
    return 'Latest visible sender: $value';
  }

  @override
  String get supportVisibleAttachmentSummaryPresent =>
      'Visible attachment summary: One or more visible replies include an attachment reference.';

  @override
  String get supportVisibleAttachmentSummaryAbsent =>
      'Visible attachment summary: No visible replies include an attachment reference yet.';

  @override
  String get supportNoVisibleThreadTitle => 'No visible thread yet';

  @override
  String get supportCurrentWorkflowTitle => 'Current workflow';

  @override
  String get supportResolutionOutcomeTitle => 'Resolution outcome';

  @override
  String supportResolvedOn(Object value) {
    return 'Resolved on: $value';
  }

  @override
  String get supportWaitingForReplyTitle => 'Support is waiting for your reply';

  @override
  String get supportWaitingForReplyMessage =>
      'Reply on this ticket with the requested clarification or proof so the review can continue.';

  @override
  String get supportReplyGuidanceTitle => 'Reply guidance';

  @override
  String get supportRepliesClosedTitle => 'Replies are closed for this ticket';

  @override
  String get supportRepliesClosedMessage =>
      'This ticket has reached a final support outcome and does not accept further replies.';

  @override
  String get supportReplyStatusReply => 'Reply';

  @override
  String get supportReplyStatusSubmitted => 'Submitted';

  @override
  String get supportNoMessageTextProvided => 'No message text provided.';

  @override
  String get supportTrustStatusLoading => 'Loading trust status';

  @override
  String supportResolutionValue(Object value) {
    return 'Resolution: $value';
  }

  @override
  String get supportReplyGuidancePrimaryOpenDispute =>
      'Use your visible reply to explain the dispute timeline, what proof is already attached, and what support should review first.';

  @override
  String get supportReplyGuidancePrimaryOpenDefault =>
      'Use your reply to explain the current blocker clearly so support can continue the review.';

  @override
  String get supportReplyGuidancePrimaryInProgressDispute =>
      'Keep your next reply focused on the dispute timeline, proof gaps, and the clearest follow-up support should review.';

  @override
  String get supportReplyGuidancePrimaryInProgressDefault =>
      'Reply with the next operational detail or clarification support asked for so the review can continue.';

  @override
  String get supportReplyGuidancePrimaryWaitingDispute =>
      'Reply with the missing clarification or proof support requested so the dispute review can continue without unnecessary delay.';

  @override
  String get supportReplyGuidancePrimaryWaitingDefault =>
      'Reply with the missing clarification support requested so the ticket can continue moving.';

  @override
  String get supportReplyGuidancePrimaryResolved =>
      'This ticket is already resolved. Start a fresh follow-up only if a genuinely new issue appears.';

  @override
  String get supportReplyGuidancePrimaryUnknown =>
      'Reply with the clearest next detail you can share if support requests more information.';

  @override
  String get supportReplyGuidanceSecondaryOpenInProgressDispute =>
      'If proof is missing from the current single-image flow, summarize the rest clearly in visible text so support knows what else to request or review.';

  @override
  String get supportReplyGuidanceSecondaryOpenInProgressDefault =>
      'Keep the reply concise, specific, and tied to the load or trip context support is reviewing.';

  @override
  String get supportReplyGuidanceSecondaryWaitingDispute =>
      'If more than one proof matters, attach the strongest one first and summarize the remaining context in your visible reply.';

  @override
  String get supportReplyGuidanceSecondaryWaitingDefault =>
      'Answer the latest support prompt directly so the next review step is clear.';

  @override
  String get supportReplyGuidanceSecondaryResolved =>
      'Keep the recorded resolution for reference and use a new ticket only for genuinely new follow-up.';

  @override
  String get supportReplyGuidanceSecondaryUnknown =>
      'Keep your reply clear and limited to the facts support can verify next.';

  @override
  String supportTicketTitleWithPriority(Object title, Object priority) {
    return '$title - $priority priority';
  }

  @override
  String supportTrustStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'normal': 'Normal',
      'warned': 'Warned',
      'restricted': 'Restricted',
      'suspended': 'Suspended',
      'banned': 'Banned',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String supportTrustBadge(Object status) {
    return 'Trust: $status';
  }

  @override
  String get trustSafetyLabel => 'Trust & safety';

  @override
  String get trustSafetyWarningTitle => 'Trust & safety warning active';

  @override
  String get trustSafetyWarningMessage =>
      'Your account has a warning on record. Marketplace and support surfaces remain available, but you should avoid further violations and use support if you need clarification on the warning or next-step expectations.';

  @override
  String get trustSafetyRestrictionTitle => 'Trust & safety restriction active';

  @override
  String get trustSafetyRestrictionFallback =>
      'Some platform actions may be limited while this restriction remains active. Use support to confirm which actions are limited and what changes may be required before the restriction can be reviewed.';

  @override
  String get trustSafetySuspensionTitle => 'Trust & safety suspension active';

  @override
  String get trustSafetySuspensionFallback =>
      'Access to key platform actions may be paused while this suspension remains active. Use support for policy-allowed review updates or reinstatement guidance once the required next steps are complete.';

  @override
  String get trustSafetyBanTitle => 'Trust & safety ban active';

  @override
  String get trustSafetyBanFallback =>
      'This account is blocked from normal platform use. Use support only for policy-allowed clarification or final review outcome questions.';

  @override
  String get trustSafetyHealthyMessageLine1 =>
      'Your account currently has no active trust or safety enforcement. Keep delivery proofs, payout confirmations, and marketplace communication accurate so this status remains normal.';

  @override
  String get trustSafetyHealthyMessageLine2 =>
      'If policy or moderation questions ever appear on this account, open support for clarification before retrying blocked actions.';

  @override
  String trustSafetyCurrentStatus(Object displayLabel, Object fallback) {
    return 'Current status: $displayLabel. $fallback';
  }

  @override
  String trustSafetyCurrentStatusWithReason(
    Object displayLabel,
    Object reasonSummary,
    Object fallback,
  ) {
    return 'Current status: $displayLabel. Reason summary: $reasonSummary. $fallback';
  }

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get settingsLanguageHelper =>
      'Hindi is the launch default. You can switch to English here.';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHindi => 'Hindi';

  @override
  String get settingsLanguageSavedEnglish => 'Language saved: English';

  @override
  String get settingsLanguageSavedHindi => 'Language saved: Hindi';

  @override
  String get settingsLanguageSaveFailed =>
      'We could not save your language preference right now. Retry shortly from settings.';

  @override
  String get settingsLanguageSaving => 'Saving language preference...';

  @override
  String truckerDashboardWelcomeBack(Object fullName) {
    return 'Welcome back, $fullName';
  }

  @override
  String get truckerDashboardTitle => 'Trucker Dashboard';

  @override
  String get truckerDashboardQuickActionTripsLabel => 'My Trips';

  @override
  String get truckerDashboardRecentActivityTitle => 'Recent activity';

  @override
  String get truckerDashboardReadinessNextStepsTitle =>
      'Readiness and next steps';

  @override
  String get truckerDashboardReadinessUnavailableTitle =>
      'Readiness state unavailable';

  @override
  String get truckerDashboardReadinessFailureMessage =>
      'Your trucker readiness state is temporarily unavailable. Retry shortly to refresh verification and fleet readiness.';

  @override
  String get commonVerificationPendingTitle => 'Verification pending';

  @override
  String get commonOpenVerificationAction => 'Open verification';

  @override
  String get commonVerificationNeedsAttentionTitle =>
      'Verification needs attention';

  @override
  String get truckerDashboardFixVerificationAction => 'Fix verification';

  @override
  String get truckerDashboardCompleteFleetVerificationTitle =>
      'Complete fleet and verification setup';

  @override
  String get truckerDashboardOpenFleetVerificationAction =>
      'Open fleet and verification';

  @override
  String get truckerDashboardAddApproveFirstTruckTitle =>
      'Add and approve your first truck';

  @override
  String get truckerDashboardOpenFleetAction => 'Open fleet';

  @override
  String get truckerDashboardCompleteVerificationTitle =>
      'Complete trucker verification';

  @override
  String get truckerDashboardLoadFailureTitle =>
      'Unable to load your trucker dashboard';

  @override
  String get truckerDashboardLoadFailureMessage =>
      'We could not load your trucker dashboard right now. Retry shortly to refresh the latest KPIs and activity summary.';

  @override
  String get truckerDashboardSetupInProgress => 'Setup in progress';

  @override
  String truckerDashboardApprovedTruckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# approved trucks',
      one: '# approved truck',
    );
    return '$_temp0';
  }

  @override
  String get truckerDashboardStatActiveBidsLabel => 'Active bids';

  @override
  String get truckerDashboardStatUpcomingTripsLabel => 'Upcoming trips';

  @override
  String get truckerDashboardStatInTransitLabel => 'In-transit';

  @override
  String get truckerDashboardRecentActivityUnavailableTitle =>
      'Recent activity unavailable';

  @override
  String get truckerDashboardRecentActivityUnavailableMessage =>
      'We could not load your latest booking, trip, and fleet activity right now.';

  @override
  String get truckerDashboardNoRecentActivityTitle => 'No recent activity yet';

  @override
  String get truckerDashboardNoRecentActivitySubtitle =>
      'Your booking requests, trip movement, and fleet review updates will appear here once work begins.';

  @override
  String get truckerDashboardBookingActivityTitle => 'Booking activity';

  @override
  String truckerDashboardBookingActivitySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active bids waiting for supplier review',
      one: '$count active bid waiting for supplier review',
    );
    return '$_temp0';
  }

  @override
  String get truckerDashboardTripActivityTitle => 'Trip activity';

  @override
  String truckerDashboardTripActivitySubtitle(
    int upcomingTrips,
    int inTransitTrips,
    int completedTrips,
  ) {
    return '$upcomingTrips upcoming - $inTransitTrips in transit - $completedTrips completed';
  }

  @override
  String get truckerDashboardFleetReviewActivityTitle =>
      'Fleet review activity';

  @override
  String truckerDashboardFleetReviewActivitySubtitle(
    int pendingTrucks,
    int rejectedTrucks,
    int pendingReapprovalTrucks,
  ) {
    return '$pendingTrucks pending - $rejectedTrucks rejected - $pendingReapprovalTrucks pending reapproval';
  }

  @override
  String truckerDashboardStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'open': 'open',
      'clear': 'clear',
      'moving': 'moving',
      'tracked': 'tracked',
      'attention': 'attention',
      'other': 'attention',
    });
    return '$_temp0';
  }

  @override
  String get truckerDashboardReadinessSummaryUnavailableTitle =>
      'Trucker readiness unavailable';

  @override
  String get truckerDashboardReadinessSummaryUnavailableMessage =>
      'We could not load your readiness summary right now.';

  @override
  String get truckerDashboardProfileSetupInProgressTitle =>
      'Profile setup still in progress';

  @override
  String get truckerDashboardProfileSetupInProgressSubtitle =>
      'Your dashboard will show readiness details once your trucker profile finishes loading.';

  @override
  String get truckerDashboardVerificationStatusTitle => 'Verification status';

  @override
  String truckerDashboardDlLabel(Object value) {
    return 'DL: $value';
  }

  @override
  String get truckerDashboardFleetReadinessTitle => 'Fleet readiness';

  @override
  String truckerDashboardApprovedTrucksSummary(
    int approvedTrucks,
    int totalTrucks,
  ) {
    return '$approvedTrucks/$totalTrucks approved trucks';
  }

  @override
  String get truckerDashboardReadyStatus => 'ready';

  @override
  String get truckerDashboardActionNeededStatus => 'action needed';

  @override
  String truckerDashboardTruckAwaitingReview(int count) {
    return '$count awaiting review';
  }

  @override
  String truckerDashboardTruckRejected(int count) {
    return '$count rejected';
  }

  @override
  String truckerDashboardTruckPendingReapproval(int count) {
    return '$count pending reapproval';
  }

  @override
  String truckerDashboardTruckLifecycleAttention(Object segments) {
    return 'Truck lifecycle attention: $segments. Non-approved trucks stay blocked for new booking workflows until review is cleared.';
  }

  @override
  String get truckerTripsTitle => 'My trips';

  @override
  String get truckerTripsSubtitle =>
      'Track assigned trips, monitor proof deadlines, and hand off the right action at the right trip stage.';

  @override
  String tripStageValue(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'assigned': 'Assigned',
      'pickup_pending': 'Pickup pending',
      'picked_up': 'Picked up',
      'in_transit': 'In transit',
      'delivered': 'Delivered',
      'proof_submitted': 'Proof submitted',
      'completed': 'Completed',
      'disputed': 'Disputed',
      'cancelled': 'Cancelled',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String proofStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pod_uploaded': 'POD uploaded',
      'lr_uploaded': 'LR uploaded',
      'awaiting_pod': 'Awaiting POD',
      'proof_submitted': 'Proof submitted',
      'other': 'Proof pending',
    });
    return '$_temp0';
  }

  @override
  String get truckerTripsLoadFailureTitle => 'Unable to load trips';

  @override
  String get truckerTripsLoadFailureMessage =>
      'We could not load your trips right now. Retry shortly to refresh the latest execution timeline.';

  @override
  String get truckerTripsEmptyActiveTitle => 'No trips yet';

  @override
  String get truckerTripsEmptyCompletedTitle => 'No completed trips yet';

  @override
  String get truckerTripsEmptyActiveSubtitle =>
      'Book a load and wait for supplier approval to start your first trip.';

  @override
  String get truckerTripsEmptyCompletedSubtitle =>
      'Completed and cancelled trips will appear here after execution closes.';

  @override
  String get truckerTripsEmptyActiveAction => 'Find loads';

  @override
  String get truckerTripsEmptyCompletedAction => 'View active trips';

  @override
  String get truckerTripDetailNotFoundTitle => 'Trip not found';

  @override
  String get truckerTripDetailNotFoundSubtitle =>
      'This assigned trip is no longer available or you no longer have access to it.';

  @override
  String get truckerTripDetailBackToTripsAction => 'Back to my trips';

  @override
  String truckerTripsTimeContextAssigned(Object date) {
    return 'Assigned $date';
  }

  @override
  String truckerTripsTimeContextDelivered(Object date) {
    return 'Delivered $date';
  }

  @override
  String truckerTripsTimeContextPodUploaded(Object date) {
    return 'POD uploaded $date';
  }

  @override
  String truckerTripsTimeContextCompleted(Object date) {
    return 'Completed $date';
  }

  @override
  String truckerTripsTruckLabel(Object truckNumber) {
    return 'Truck $truckNumber';
  }

  @override
  String get truckerFleetHeroTitle => 'Manage truck readiness';

  @override
  String get truckerFleetHeroSubtitle =>
      'Track truck approval, review rejection guidance, and keep RC details current so booking-ready trucks stay available.';

  @override
  String get truckerFleetEditingTruckAction => 'Editing truck';

  @override
  String get truckerFleetAddTruckAction => 'Add truck';

  @override
  String truckerFleetTruckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trucks',
      one: '$count truck',
    );
    return '$_temp0';
  }

  @override
  String truckerFleetApprovedCount(int count) {
    return '$count approved';
  }

  @override
  String get truckerFleetActionAttentionTitle => 'Truck action needs attention';

  @override
  String get truckerFleetActionFailureMessage =>
      'The latest truck action could not be completed right now. Review the truck details and retry shortly.';

  @override
  String get truckerFleetEditTruckTitle => 'Edit truck';

  @override
  String get truckerFleetAddOrUpdateTruckTitle => 'Add or update truck';

  @override
  String get commonTruckNumberLabel => 'Truck number';

  @override
  String get truckerFleetTruckNumberHint => 'MH12AB1234';

  @override
  String get truckerFleetBodyTypeLabel => 'Body type';

  @override
  String truckerFleetBodyTypeOption(Object value) {
    return '$value';
  }

  @override
  String get truckerFleetTyresLabel => 'Tyres';

  @override
  String truckerFleetTyresOption(int tyres) {
    return '$tyres tyres';
  }

  @override
  String get truckerFleetCapacityLabel => 'Capacity (tonnes)';

  @override
  String get truckerFleetCapacityHint => '25';

  @override
  String get truckerFleetRcDocumentTitle => 'RC document';

  @override
  String get truckerFleetRcUploadedSubtitle =>
      'RC image uploaded and linked to this truck draft.';

  @override
  String get truckerFleetRcRequiredSubtitle =>
      'Upload the truck RC before saving this truck.';

  @override
  String get truckerFleetUploadedStatus => 'uploaded';

  @override
  String get truckerFleetRequiredStatus => 'required';

  @override
  String truckerFleetStoredPath(Object path) {
    return 'Stored path: $path';
  }

  @override
  String get truckerFleetReplaceRcAction => 'Replace RC document';

  @override
  String get truckerFleetUploadRcAction => 'Upload RC document';

  @override
  String get truckerFleetRcUploadedSuccess => 'RC uploaded successfully';

  @override
  String get truckerFleetRcUpdatedSuccess => 'RC document updated successfully';

  @override
  String get truckerFleetSaveTruckUpdatesAction => 'Save truck updates';

  @override
  String get truckerFleetSaveTruckAction => 'Save truck';

  @override
  String get truckerFleetTruckUpdatedSuccess => 'Truck updated successfully';

  @override
  String get truckerFleetTruckAddedSuccess => 'Truck added successfully';

  @override
  String get truckerFleetMyTrucksTitle => 'My trucks';

  @override
  String get truckerFleetUnavailableTitle => 'Fleet unavailable';

  @override
  String get truckerFleetLoadFailureMessage =>
      'We could not load your fleet right now. Retry shortly to refresh the latest truck readiness and approval state.';

  @override
  String get truckerFleetNoTrucksTitle => 'No trucks added yet';

  @override
  String get truckerFleetNoTrucksSubtitle =>
      'Add your first truck with its RC document so trucker verification can progress toward approval.';

  @override
  String get truckerFleetSelectRcSourceTitle => 'Upload RC document';

  @override
  String get commonTakePhotoAction => 'Take photo';

  @override
  String get commonChooseFromGalleryAction => 'Choose from gallery';

  @override
  String get truckerFleetRcUploadFailureMessage =>
      'We could not upload the RC document right now. Try another image or retry shortly.';

  @override
  String get truckerFleetSaveFailureMessage =>
      'We could not save this truck right now. Review the truck details and retry shortly.';

  @override
  String get truckerFleetTruckNumberConflictMessage =>
      'This truck number is already in use. Check the number and try again.';

  @override
  String truckerFleetTruckCardSubtitle(
    Object bodyType,
    Object tyres,
    Object capacityTonnes,
  ) {
    return '$bodyType - $tyres tyres - ${capacityTonnes}T';
  }

  @override
  String truckerFleetModelLabel(Object value) {
    return 'Model: $value';
  }

  @override
  String truckerFleetReviewSummaryLabel(Object value) {
    return 'Review summary: $value';
  }

  @override
  String truckerFleetNextStepLabel(Object value) {
    return 'Next step: $value';
  }

  @override
  String get truckerFleetBlockedBookingMessage =>
      'This truck is blocked for approval-dependent booking workflows until review clears.';

  @override
  String get truckerFleetFixResubmitAction => 'Fix and resubmit truck';

  @override
  String get truckerFleetEditTruckAction => 'Edit truck';

  @override
  String truckerFleetStatusLabelValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pending': 'Pending review',
      'verified': 'Approved',
      'rejected': 'Rejected',
      'edited_pending_reapproval': 'Pending reapproval',
      'archived': 'Archived',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String truckerFleetStatusMessageValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pending':
          'Your truck is waiting for admin review. Approval is required before this truck can be used for booking.',
      'verified':
          'This truck is approved and available for verification-dependent workflows.',
      'rejected':
          'This truck was rejected. Review the guidance below and update the affected details or RC document.',
      'edited_pending_reapproval':
          'This truck stays visible, but recent edits sent it back for reapproval before it can be used again.',
      'archived':
          'This truck is archived and no longer available for normal booking workflows.',
      'unknown': 'Truck review state is currently unavailable.',
      'other': 'Truck review state is currently unavailable.',
    });
    return '$_temp0';
  }

  @override
  String get truckerFindLoadsHeroSubtitle =>
      'Scan compact freight cards, keep filters tight, and move quickly from route interest to load evaluation.';

  @override
  String get truckerFindLoadsAdvancedFiltersAction => 'Advanced filters';

  @override
  String get truckerFindLoadsOriginHint => 'Origin city';

  @override
  String get truckerFindLoadsDestinationHint => 'Destination city';

  @override
  String get truckerFindLoadsMaterialHint => 'Material';

  @override
  String get truckerFindLoadsSortByLabel => 'Sort by';

  @override
  String get truckerFindLoadsSortNewest => 'Newest';

  @override
  String get truckerFindLoadsSortPriceHighToLow => 'Price High>Low';

  @override
  String get truckerFindLoadsSortPriceLowToHigh => 'Price Low>High';

  @override
  String get truckerFindLoadsSortPickupDate => 'Pickup Date';

  @override
  String get truckerFindLoadsAllLoadsTab => 'All Loads';

  @override
  String get truckerFindLoadsSuperLoadsTab => 'Super Loads';

  @override
  String get truckerFindLoadsLoadFailureTitle => 'Unable to load freight';

  @override
  String get truckerFindLoadsLoadFailureMessage =>
      'We could not load marketplace freight right now. Retry shortly to refresh the latest load search results.';

  @override
  String get truckerFindLoadsEmptyTitle => 'No loads found';

  @override
  String get truckerFindLoadsEmptySubtitle =>
      'Try adjusting your city, material, or advanced filters to widen the marketplace search.';

  @override
  String get truckerFindLoadsLoadMoreFailureTitle => 'More loads unavailable';

  @override
  String get truckerFindLoadsLoadMoreFailureMessage =>
      'We could not load more freight right now. Retry shortly to continue the marketplace search.';

  @override
  String truckerFindLoadsSummaryFrom(Object city) {
    return 'From $city';
  }

  @override
  String truckerFindLoadsSummaryTo(Object city) {
    return 'To $city';
  }

  @override
  String truckerFindLoadsSummaryTyres(Object value) {
    return '$value tyre';
  }

  @override
  String truckerFindLoadsSummaryPriceRange(Object minPrice, Object maxPrice) {
    return '₹$minPrice-$maxPrice';
  }

  @override
  String get truckerFindLoadsSummarySuperLoads => 'Super Loads';

  @override
  String truckerFindLoadsSummaryAllLoads(int resultCount) {
    return 'Showing all loads - $resultCount result(s)';
  }

  @override
  String truckerFindLoadsSummaryFiltered(Object pieces, int resultCount) {
    return '$pieces - $resultCount result(s)';
  }

  @override
  String get truckerFindLoadsResetFiltersAction => 'Reset filters';

  @override
  String get truckerFindLoadsAnyBodyFallback => 'Any body';

  @override
  String truckerFindLoadsStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'Active',
      'assigned_partial': 'Assigned Partial',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get truckerFindLoadsAdvancedFiltersTitle => 'Advanced filters';

  @override
  String get truckerFindLoadsTruckBodyTypeLabel => 'Truck body type';

  @override
  String truckerFindLoadsBodyTypeValue(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'open': 'Open',
      'trailer': 'Trailer',
      'container': 'Container',
      'tanker': 'Tanker',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get truckerFindLoadsTyreRequirementTitle => 'Tyre requirement';

  @override
  String get truckerFindLoadsMinPriceLabel => 'Min price (₹)';

  @override
  String get truckerFindLoadsMaxPriceLabel => 'Max price (₹)';

  @override
  String get truckerFindLoadsApplyFiltersAction => 'Apply filters';

  @override
  String get truckerFindLoadsResetAdvancedFiltersAction =>
      'Reset advanced filters';

  @override
  String get supplierPostLoadHeroTitle => 'Create a supplier load';

  @override
  String get supplierPostLoadHeroSubtitle =>
      'Use one clean scrolling form to define route, cargo, vehicle requirements, pricing, and pickup timing.';

  @override
  String get supplierPostLoadHeroHelper =>
      'Manual city entry still works if route services do not return a preview. Your form data stays intact on validation or submission failure.';

  @override
  String get supplierPostLoadPostingBlockedTitle => 'Posting is blocked';

  @override
  String get supplierPostLoadRouteTimingTitle => 'Route and timing';

  @override
  String get supplierPostLoadOriginCityLabel => 'Origin city';

  @override
  String get supplierPostLoadSearchCityHint => 'Search city';

  @override
  String get supplierPostLoadOriginExactLocationLabel =>
      'Origin exact location';

  @override
  String get supplierPostLoadOriginExactLocationHint =>
      'Warehouse / pickup point';

  @override
  String get supplierPostLoadDestinationCityLabel => 'Destination city';

  @override
  String get supplierPostLoadDestinationExactLocationLabel =>
      'Destination exact location';

  @override
  String get supplierPostLoadDestinationExactLocationHint =>
      'Drop point / delivery point';

  @override
  String get supplierPostLoadPickupDateLabel => 'Pickup date';

  @override
  String get supplierPostLoadRoutePreviewTitle => 'Route preview';

  @override
  String supplierPostLoadDistanceLabel(Object value) {
    return 'Distance: $value km';
  }

  @override
  String supplierPostLoadDriveTimeLabel(int minutes) {
    return 'Est. drive time: $minutes min';
  }

  @override
  String get supplierPostLoadRoutePreviewUnavailableTitle =>
      'Route preview unavailable';

  @override
  String get supplierPostLoadRoutePreviewUnavailableMessage =>
      'Route distance and duration could not be derived right now. You can still continue with manual city-based posting.';

  @override
  String get supplierPostLoadCargoDetailsTitle => 'Cargo details';

  @override
  String get supplierPostLoadMaterialLabel => 'Material';

  @override
  String get supplierPostLoadWeightLabel => 'Weight (tonnes)';

  @override
  String get supplierPostLoadWeightHint => '22';

  @override
  String get supplierPostLoadVehicleRequirementsTitle => 'Vehicle requirements';

  @override
  String get supplierPostLoadTruckBodyTypeLabel => 'Truck body type';

  @override
  String get supplierPostLoadTyreRequirementTitle => 'Tyre requirement';

  @override
  String get commonAnyLabel => 'Any';

  @override
  String get supplierPostLoadTrucksNeededTitle => 'Trucks needed';

  @override
  String get supplierPostLoadTrucksNeededLabel => 'Trucks needed';

  @override
  String get supplierPostLoadTrucksNeededHint => '1';

  @override
  String get supplierPostLoadPricingScheduleTitle => 'Pricing and schedule';

  @override
  String get supplierPostLoadPriceAmountLabel => 'Price amount (₹)';

  @override
  String get supplierPostLoadPriceAmountHint => '54000';

  @override
  String get supplierPostLoadPriceTypeTitle => 'Price type';

  @override
  String supplierPostLoadPriceTypeValue(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'fixed': 'Fixed',
      'per_ton': 'Per Ton',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String supplierPostLoadAdvancePercentageLabel(int value) {
    return 'Advance percentage: $value%';
  }

  @override
  String supplierPostLoadAdvanceBalanceLabel(
    Object advanceAmount,
    Object balanceAmount,
  ) {
    return 'Advance: ₹$advanceAmount - Balance: ₹$balanceAmount';
  }

  @override
  String get supplierPostLoadReviewSummaryTitle => 'Review summary';

  @override
  String get supplierPostLoadOriginPending => 'Origin pending';

  @override
  String get supplierPostLoadDestinationPending => 'Destination pending';

  @override
  String supplierPostLoadRouteSummary(Object origin, Object destination) {
    return '$origin > $destination';
  }

  @override
  String supplierPostLoadCargoSummary(
    Object material,
    Object weightTonnes,
    Object trucksNeeded,
  ) {
    return '$material - ${weightTonnes}T - $trucksNeeded truck(s)';
  }

  @override
  String supplierPostLoadPriceSummary(Object priceAmount, Object priceType) {
    return 'Price: ₹$priceAmount - $priceType';
  }

  @override
  String supplierPostLoadPickupSummary(Object pickupDate) {
    return 'Pickup: $pickupDate';
  }

  @override
  String get supplierPostLoadSubmissionFailedTitle => 'Submission failed';

  @override
  String get supplierPostLoadCompleteVerificationAction =>
      'Complete verification to post load';

  @override
  String get supplierPostLoadCreatedSuccess => 'Load created successfully';

  @override
  String get supplierPostLoadSubmissionFailureMessage =>
      'We could not prepare this load submission right now. Review the load details and retry shortly.';

  @override
  String get supplierPostLoadSubmitFailureMessage =>
      'We could not create this load right now. Review the load details and retry shortly.';

  @override
  String get supplierPostLoadVerificationCheckingMessage =>
      'Checking supplier verification before enabling load posting.';

  @override
  String get supplierPostLoadVerificationUnavailableMessage =>
      'Unable to confirm supplier verification right now. Retry shortly or open verification to review your trust status.';

  @override
  String get supplierPostLoadProfileUnavailableMessage =>
      'Supplier profile is unavailable right now. Retry shortly before posting this load.';

  @override
  String get supplierPostLoadVerificationRequiredMessage =>
      'Complete supplier verification before posting loads. Upload identity and business documents, then submit them for review.';

  @override
  String get commonAadhaarNumberLabel => 'Aadhaar number';

  @override
  String get commonPanNumberLabel => 'PAN number';

  @override
  String get verificationReadinessCheckAadhaarFrontPhoto =>
      'Aadhaar front photo';

  @override
  String get verificationReadinessCheckAadhaarBackPhoto => 'Aadhaar back photo';

  @override
  String get verificationReadinessCheckPanPhoto => 'PAN photo';

  @override
  String get commonCompanyNameLabel => 'Company name';

  @override
  String get verificationReadinessCheckBusinessLicenceNumber =>
      'Business licence number';

  @override
  String get verificationReadinessCheckBusinessLicenceDocument =>
      'Business licence document';

  @override
  String get verificationReadinessCheckLocation => 'Verification location';

  @override
  String get verificationReadinessCheckTruckWithRcDocument =>
      'Truck with RC document';

  @override
  String get verificationSubmitSectionTitle => 'Submit for Verification';

  @override
  String get verificationSubmitSectionTitleTrucker =>
      'Step 3: Submit for Verification';

  @override
  String get verificationSubmitSectionSubtitle =>
      'Complete all items below, then tap Submit to send your documents for admin review.';

  @override
  String verificationReadinessCompletedCount(int doneCount, int totalCount) {
    return '$doneCount / $totalCount completed';
  }

  @override
  String get verificationOpenFleetHint =>
      'Add or manage your truck with RC document from the fleet screen.';

  @override
  String supplierPostLoadSuggestionSubtitle(Object label, Object source) {
    return '$label - $source';
  }

  @override
  String get supplierVerificationPendingMessage =>
      'Your verification is under review. Keep documents ready in case the support team asks for clarification.';

  @override
  String get supplierVerificationNeedsAttentionDescription =>
      'Review the latest verification feedback, update the required documents, and resubmit when you are ready.';

  @override
  String get supplierReviewVerification => 'Review verification';

  @override
  String get supplierFixVerification => 'Fix verification';

  @override
  String get supplierCompleteSetupTitle => 'Complete your supplier setup';

  @override
  String get supplierCompleteSetupMessage =>
      'Complete supplier verification and add your company details before using the full supplier workspace.';

  @override
  String get supplierCompleteVerification => 'Complete verification';

  @override
  String get supplierDashboardSuperLoadVerificationComplete =>
      'Verification complete';

  @override
  String get supplierDashboardSuperLoadBusinessLicenceOnFile =>
      'Business licence on file';

  @override
  String get supplierDashboardSuperLoadBusinessLicenceMissing =>
      'Business licence missing';

  @override
  String get supplierDashboardSuperLoadCompanyAgeUnavailable =>
      'Company-age readiness unavailable in current app data';

  @override
  String supplierLoadStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'Active',
      'assigned_partial': 'Assigned partial',
      'assigned_full': 'Assigned full',
      'in_transit': 'In transit',
      'completed': 'Completed',
      'filled_outside_app': 'Filled outside app',
      'cancelled': 'Cancelled',
      'expired': 'Expired',
      'deactivated': 'Deactivated',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String supplierDashboardTrucksBooked(int booked, int needed) {
    return '$booked/$needed trucks booked';
  }

  @override
  String supplierDashboardLoadPickup(Object value) {
    return 'Pickup $value';
  }

  @override
  String get supplierDashboardOpenLoadsWorkspace => 'Open loads workspace';

  @override
  String supplierDashboardSuperLoadStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'request_submitted': 'Request submitted',
      'under_review': 'Under review',
      'approved_payment_pending': 'Approved - payment pending',
      'rejected': 'Rejected',
      'expired_or_closed': 'Closed',
      'active': 'Active',
      'not_requested': 'Not requested',
      'other': 'Not requested',
    });
    return '$_temp0';
  }

  @override
  String supplierDashboardSuperLoadBadge(Object status) {
    return 'Super Load - $status';
  }

  @override
  String supplierDashboardSuperLoadGuidanceValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'request_submitted':
          'This Super Load request is submitted and waiting for admin review. The dedicated supplier-side eligibility controls are still pending, so current state is admin-managed.',
      'under_review':
          'This Super Load request is under admin review. Keep load details stable while review is in progress.',
      'approved_payment_pending':
          'This Super Load request is approved, but activation still depends on the off-platform payment confirmation step.',
      'rejected':
          'This Super Load request was not approved. Use support if you need follow-up while the dedicated supplier readiness surface is still pending.',
      'expired_or_closed':
          'This Super Load lifecycle is closed. Review the current load status and use support if follow-up is still needed.',
      'active':
          'This load is marked as a Super Load in the current lifecycle. Dedicated supplier-side eligibility controls are still being expanded.',
      'not_requested': 'Super Load state is not active for this load.',
      'other': 'Super Load state is not active for this load.',
    });
    return '$_temp0';
  }

  @override
  String supplierLinkedTripAssignedLabel(Object date) {
    return 'Assigned: $date';
  }

  @override
  String supplierLinkedTripProofLabel(Object status) {
    return 'Proof status: $status';
  }

  @override
  String get supplierLinkedTripTrackAction => 'Track trip';

  @override
  String get supplierTripDetailTitle => 'Trip Detail';

  @override
  String get supplierTripDetailLoadFailureTitle =>
      'Unable to load supplier trip detail';

  @override
  String get supplierTripDetailLoadFailureMessage =>
      'We could not load this supplier trip detail right now. Retry shortly to refresh the latest trip status and proof review context.';

  @override
  String get supplierTripDetailRatingFailureMessage =>
      'The supplier rating state is temporarily unavailable. Retry shortly before submitting a rating.';

  @override
  String get supplierTripDetailRatingSubmitFailureMessage =>
      'We could not submit this supplier rating right now. Review the rating and retry shortly.';

  @override
  String get supplierTripDetailActionFailureMessage =>
      'The latest supplier trip action could not be completed right now. Retry shortly after the trip detail refreshes.';

  @override
  String get supplierTripDetailActionSubmitFailureMessage =>
      'We could not complete that supplier trip action right now. Retry shortly after checking the latest trip status.';

  @override
  String get supplierTripDetailRatingSectionTitle => 'Rate this trip';

  @override
  String get supplierTripDetailRatingAlreadySubmitted =>
      'You already rated this trip.';

  @override
  String supplierTripDetailRatingSubmittedOn(Object date) {
    return 'Submitted on $date';
  }

  @override
  String get supplierTripDetailRatingPrompt =>
      'Delivery is complete. Rate the trucker for this trip.';

  @override
  String get supplierTripDetailCommentLabel => 'Comment (optional)';

  @override
  String get supplierTripDetailCommentHint =>
      'Share anything useful about the trip outcome';

  @override
  String get supplierTripDetailRatingUnavailableTitle => 'Rating unavailable';

  @override
  String get supplierTripDetailSubmitRatingAction => 'Submit Rating';

  @override
  String get supplierTripDetailRatingSubmittedSuccess =>
      'Rating submitted successfully.';

  @override
  String supplierTripDetailRatingStarTooltip(int count, Object s) {
    return '$count star$s';
  }

  @override
  String supplierTripDetailHeroSubtitle(Object truckNumber) {
    return 'Truck $truckNumber';
  }

  @override
  String supplierTripDetailMaterialTruckerSummary(
    Object material,
    Object truckerName,
  ) {
    return '$material - Trucker $truckerName';
  }

  @override
  String get commonNextStepTitle => 'Next step';

  @override
  String get supplierTripDetailNextStepReviewTitle =>
      'Review and confirm delivery';

  @override
  String get supplierTripDetailNextStepReviewMessage =>
      'The trucker has uploaded POD. Review the proof and confirm delivery to close the trip.';

  @override
  String get supplierTripDetailNextStepCompletedTitle => 'Trip completed';

  @override
  String get supplierTripDetailNextStepCompletedMessage =>
      'Delivery has been confirmed. Rating and post-trip follow-up continue from this completed state.';

  @override
  String get commonDisputeInProgressTitle => 'Dispute in progress';

  @override
  String get supplierTripDetailNextStepDisputedMessage =>
      'This trip is under dispute review and awaits support or operations resolution.';

  @override
  String get supplierTripDetailNextStepDefaultTitle => 'Track execution';

  @override
  String get supplierTripDetailNextStepDefaultMessage =>
      'Review the current trip status, timestamps, and proof progress from this supplier execution view.';

  @override
  String get supplierTripDetailDisputeStatusTitle => 'Dispute status';

  @override
  String get supplierTripDetailDisputeStateRaised =>
      'Current state: Dispute raised';

  @override
  String supplierTripDetailDisputeCategorySummary(Object category) {
    return 'Category: $category';
  }

  @override
  String supplierTripDetailDisputeCategoryLabel(Object category) {
    return '$category';
  }

  @override
  String supplierTripDetailDisputeStatusLabel(Object status) {
    return '$status';
  }

  @override
  String supplierTripDetailDisputeCurrentStateLabel(Object status) {
    return 'Current state: $status';
  }

  @override
  String supplierTripDetailDisputeLastUpdatedLabel(Object date) {
    return 'Last updated: $date';
  }

  @override
  String get supplierTripDetailActionUnavailableTitle =>
      'Supplier trip action unavailable';

  @override
  String get supplierTripDetailProofDocumentsTitle => 'Proof documents';

  @override
  String get supplierTripDetailPodPhotoTitle => 'POD photo';

  @override
  String get supplierTripDetailPreviewUnavailable => 'Unable to open preview';

  @override
  String get supplierTripDetailOpenPodPhotoAction => 'Open POD Photo';

  @override
  String get supplierTripDetailOpenLrDocumentAction => 'Open LR Document';

  @override
  String get supplierTripDetailActionsTitle => 'Actions';

  @override
  String get supplierTripDetailConfirmDeliveryAction => 'Confirm Delivery';

  @override
  String get supplierTripDetailConfirmDeliverySuccess =>
      'Delivery confirmed. The trip is now completed.';

  @override
  String get supplierTripDetailDisputePodAction => 'Dispute POD';

  @override
  String supplierTripDetailReportSourceLabel(Object routeLabel) {
    return 'Supplier trip - $routeLabel';
  }

  @override
  String get commonRouteAndScheduleTitle => 'Route and schedule';

  @override
  String supplierTripDetailOriginLabel(Object origin) {
    return 'Origin: $origin';
  }

  @override
  String supplierTripDetailDestinationLabel(Object destination) {
    return 'Destination: $destination';
  }

  @override
  String supplierTripDetailDistanceLabel(Object distance) {
    return 'Distance: $distance km';
  }

  @override
  String supplierTripDetailDriveTimeLabel(int minutes) {
    return 'Drive time: $minutes min';
  }

  @override
  String supplierTripDetailPickupDateLabel(Object date) {
    return 'Pickup date: $date';
  }

  @override
  String supplierTripDetailAssignedLabel(Object dateTime) {
    return 'Assigned: $dateTime';
  }

  @override
  String supplierTripDetailDeliveredLabel(Object dateTime) {
    return 'Delivered: $dateTime';
  }

  @override
  String supplierTripDetailPodUploadedLabel(Object dateTime) {
    return 'POD uploaded: $dateTime';
  }

  @override
  String supplierTripDetailCompletedLabel(Object dateTime) {
    return 'Completed: $dateTime';
  }

  @override
  String get supplierTripDetailTruckerTruckTitle => 'Trucker and truck';

  @override
  String supplierTripDetailTruckerLabel(Object name) {
    return 'Trucker: $name';
  }

  @override
  String supplierTripDetailTruckNumberLabel(Object truckNumber) {
    return 'Truck number: $truckNumber';
  }

  @override
  String supplierTripDetailBodyTypeLabel(Object bodyType) {
    return 'Body type: $bodyType';
  }

  @override
  String supplierTripDetailTyresLabel(Object tyres) {
    return 'Tyres: $tyres';
  }

  @override
  String get commonPendingLabel => 'Pending';

  @override
  String get supplierTripDetailDisputeStatusGuidanceOpen =>
      'Support has received this dispute and review should begin shortly. Keep the related support replies clear if more proof context is needed.';

  @override
  String get supplierTripDetailDisputeStatusGuidanceInProgress =>
      'Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.';

  @override
  String get supplierTripDetailDisputeStatusGuidanceWaitingForUser =>
      'Support is waiting for your clarification or additional context. Reply on the related support ticket so the review can continue.';

  @override
  String get supplierTripDetailDisputeStatusGuidanceResolved =>
      'This dispute has reached a final review state. Check the linked support ticket outcome before raising any fresh follow-up issue.';

  @override
  String get supplierTripDetailDisputeStatusGuidanceDefault =>
      'Keep following the related support ticket for the latest visible review updates.';

  @override
  String get supplierTripDetailDisputeBannerWaitingTitle =>
      'Dispute review waiting for your reply';

  @override
  String get supplierTripDetailDisputeBannerInProgressTitle =>
      'Dispute review in progress';

  @override
  String get supplierTripDetailDisputeBannerNoSummaryMessage =>
      'A dispute has been raised on this trip. Support and operations are reviewing the delivery context, while raw evidence access may remain restricted during review.';

  @override
  String supplierTripDetailDisputeBannerWaitingMessage(Object category) {
    return 'Category: $category. This trip dispute is waiting on your clarification or proof, while raw evidence access may remain restricted during review.';
  }

  @override
  String supplierTripDetailDisputeBannerClosedMessage(Object category) {
    return 'Category: $category. This trip dispute has reached a final review outcome. Recorded status updates remain visible, while raw evidence access may remain restricted.';
  }

  @override
  String supplierTripDetailDisputeBannerInProgressMessage(
    Object category,
    Object status,
  ) {
    return 'Category: $category. Status: $status. Support and operations are reviewing this trip dispute, while raw evidence access may remain restricted during review.';
  }

  @override
  String get supplierTripDetailSharedVisibilityClosed =>
      'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.';

  @override
  String get supplierTripDetailSharedVisibilityInProgress =>
      'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.';

  @override
  String get supplierTripDetailActionGuidanceClosed =>
      'This dispute has reached a final review state. Check the recorded outcome on the linked support ticket before opening any genuinely new follow-up issue.';

  @override
  String get supplierTripDetailActionGuidanceInProgress =>
      'No further delivery-confirmation action is available while this dispute stays under review. Follow the linked support ticket if support requests clarification or additional context.';

  @override
  String get supplierTripDetailProofGuidanceClosed =>
      'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.';

  @override
  String get supplierTripDetailProofGuidanceInProgress =>
      'If this dispute depends on additional documents beyond the current single-image flow, summarize those missing proofs clearly in the related support ticket replies.';

  @override
  String get verificationTitle => 'Verification';

  @override
  String get verificationTitleSupplier => 'Supplier Verification';

  @override
  String get verificationTitleTrucker => 'Trucker Verification';

  @override
  String get verificationLoadFailureTitle =>
      'Unable to load verification state';

  @override
  String get verificationLoadFailureMessage =>
      'We could not load your verification status right now. Retry shortly to refresh the latest verification state.';

  @override
  String get verificationDetailsUnavailableTitle =>
      'Verification details unavailable';

  @override
  String get verificationDetailsUnavailableSubtitle =>
      'We could not find the current verification record for this account. Please retry shortly.';

  @override
  String get verificationResubmitForReviewAction => 'Resubmit for review';

  @override
  String get verificationSubmitForReviewAction => 'Submit for review';

  @override
  String get verificationResubmittedSuccess =>
      'Verification resubmitted for review';

  @override
  String get verificationSubmittedSuccess =>
      'Verification submitted for review';

  @override
  String get verificationSubmitFailureMessage =>
      'We could not submit this verification packet right now. Review the current checklist and retry shortly.';

  @override
  String get verificationWhatHappensNextMessage =>
      'Your verification packet is queued for review. You do not need to resubmit anything unless our team rejects the case with a correction request.';

  @override
  String get verificationTimelinePacketSubmittedTitle => 'Packet submitted';

  @override
  String get verificationTimelinePacketSubmittedDescription =>
      'Your current documents and readiness data are already attached to the verification case.';

  @override
  String get verificationTimelineReviewInProgressTitle => 'Review in progress';

  @override
  String get verificationTimelineReviewInProgressTimestamp => 'Now';

  @override
  String get verificationTimelineReviewInProgressDescription =>
      'Our operations team is reviewing the submitted identity, business, and readiness evidence.';

  @override
  String get verificationTimelineNotifiedTitle => 'You will be notified';

  @override
  String get verificationTimelineNotifiedTimestamp => 'Next';

  @override
  String get verificationTimelineNotifiedDescription =>
      'We will update your verification state here once the review is approved or sent back for corrections.';

  @override
  String get verificationWizardStepPhoto => 'Photo';

  @override
  String get verificationWizardStepIdentity => 'Identity';

  @override
  String get verificationWizardStepTruck => 'Truck';

  @override
  String get verificationWizardStepBusiness => 'Business';

  @override
  String get verificationWizardStepReview => 'Review';

  @override
  String get verificationWizardBackAction => 'Back';

  @override
  String get verificationWizardBackTitle => 'Go Back?';

  @override
  String get verificationWizardBackMessage =>
      'You will lose your progress on this step. Do you want to go back?';

  @override
  String get verificationWizardSaveAndExitAction => 'Save & exit';

  @override
  String get verificationWizardExitTitle => 'Exit verification?';

  @override
  String get verificationWizardExitMessage =>
      'You can leave this flow now and continue later.';

  @override
  String get verificationWizardExitAction => 'Exit';

  @override
  String get verificationWizardProfileTitle => 'Profile photo';

  @override
  String get verificationWizardProfileSubtitle =>
      'Upload a clear profile photo for verification.';

  @override
  String get verificationWizardProfileHint =>
      'Use a clear, front-facing photo with good lighting.';

  @override
  String get verificationWizardIdentityTitle => 'Identity documents';

  @override
  String get verificationWizardIdentitySubtitle =>
      'Add Aadhaar and PAN details with document uploads.';

  @override
  String get verificationWizardPanDocumentLabel => 'PAN document';

  @override
  String get verificationWizardTruckSubtitle =>
      'Add one truck and upload its RC document.';

  @override
  String get verificationWizardTruckInfo =>
      'At least one truck with an RC document is required for trucker verification.';

  @override
  String get verificationWizardBodyTypeLabel => 'Body type';

  @override
  String get verificationWizardTyresLabel => 'Tyres';

  @override
  String get verificationWizardCapacityLabel => 'Capacity';

  @override
  String get verificationWizardCapacityHint => '16';

  @override
  String get verificationWizardRcDocumentLabel => 'RC document';

  @override
  String get verificationWizardRequiredForVerification =>
      'Required for verification';

  @override
  String get verificationWizardTruckPhotoLabel => 'Truck photo';

  @override
  String get verificationWizardTruckPhotoHint => 'Optional photo of your truck';

  @override
  String get verificationWizardBusinessTitle => 'Business details';

  @override
  String get verificationWizardBusinessSubtitle =>
      'Add your company, licence, optional GST, and verification location.';

  @override
  String get verificationWizardCompanyNameHint => 'Enter your company name';

  @override
  String get verificationWizardLicenseNumberLabel => 'License number';

  @override
  String get verificationWizardLicenseNumberHint =>
      'Enter your business licence number';

  @override
  String get verificationWizardLicenseDocumentLabel =>
      'Business licence document';

  @override
  String get verificationWizardGstDetailsTitle => 'GST details';

  @override
  String get verificationWizardGstDetailsAdded => 'GST details added';

  @override
  String get verificationWizardGstOptional => 'GST is optional';

  @override
  String get commonGstNumberLabel => 'GST number';

  @override
  String get verificationWizardGstCertificateLabel => 'GST certificate';

  @override
  String get verificationWizardSearchCityTitle => 'Search city';

  @override
  String get verificationWizardSearchCityHint => 'Type city name';

  @override
  String get verificationWizardUseCurrentLocation => 'Use current location';

  @override
  String verificationWizardNoCitiesFound(Object query) {
    return 'No cities found for \"$query\"';
  }

  @override
  String get verificationWizardTryDifferentSearch =>
      'Try a different search term';

  @override
  String get verificationWizardLocationServicesOffTitle =>
      'Location services are off';

  @override
  String get verificationWizardLocationServicesOffMessage =>
      'Please enable GPS/location services and try again.';

  @override
  String get verificationWizardLocationPermissionTitle =>
      'Location permission needed';

  @override
  String get verificationWizardLocationPermissionMessage =>
      'Please allow location permission in app settings to continue.';

  @override
  String get verificationWizardOpenSettingsAction => 'Open settings';

  @override
  String get verificationWizardCapturedViaGps => 'Captured via GPS';

  @override
  String get verificationWizardAddedManually => 'Added manually';

  @override
  String get verificationWizardReviewTitle => 'Review and submit';

  @override
  String get verificationWizardReviewSubtitle =>
      'Confirm your details before sending the verification packet.';

  @override
  String get verificationWizardReviewProfileUploaded =>
      'Profile photo uploaded';

  @override
  String get verificationWizardReviewProfileMissing => 'Profile photo missing';

  @override
  String get verificationWizardReviewIdentity => 'Identity';

  @override
  String get verificationWizardReviewDocumentsUploaded => 'Documents uploaded';

  @override
  String get verificationWizardReviewTruck => 'Truck';

  @override
  String get verificationWizardReviewRcUploaded => 'RC document uploaded';

  @override
  String get verificationWizardReviewTruckPhotoUploaded =>
      'Truck photo uploaded';

  @override
  String get verificationWizardReviewBusiness => 'Business';

  @override
  String get verificationWizardReviewLicenseNumber => 'License number';

  @override
  String get verificationWizardReviewLocation => 'Location';

  @override
  String get verificationWizardReviewTimelineMessage =>
      'Review usually completes after the submitted packet is checked by the team.';

  @override
  String get verificationWizardTermsText =>
      'I confirm that the information and uploaded documents are accurate and ready for verification review.';

  @override
  String get verificationWizardValidationError =>
      'Please complete the required fields before submitting.';

  @override
  String get verificationWizardUnauthorizedError =>
      'Your session is unavailable. Please sign in again.';

  @override
  String get verificationWizardUnknownError =>
      'Something went wrong while submitting verification.';

  @override
  String get verificationActionNeedsAttentionTitle =>
      'Verification action needs attention';

  @override
  String get verificationActionFailureMessage =>
      'The latest verification action could not be completed right now. Review the current checklist and retry shortly.';

  @override
  String get verificationLatestRejectionReasonTitle =>
      'Latest rejection reason';

  @override
  String get verificationLocationTitle => 'Verification location';

  @override
  String get verificationLocationCapturedTitle => 'Location captured';

  @override
  String get verificationLocationRequiredTitle => 'Location still required';

  @override
  String get verificationLocationRequiredMessage =>
      'Supplier verification needs a city-level location capture before submission can proceed.';

  @override
  String get verificationLocationCapturedStatus => 'captured';

  @override
  String get verificationLocationRequiredStatus => 'required';

  @override
  String get verificationLocationCapturedFooter =>
      'Captured location remains attached to the supplier verification packet for review.';

  @override
  String get verificationLocationCaptureGuidanceFooter =>
      'We attempt GPS capture and resolve to the nearest city-level location when possible.';

  @override
  String get verificationRefreshLocationAction => 'Refresh location';

  @override
  String get verificationCaptureLocationAction => 'Capture location';

  @override
  String get verificationLocationCapturedSuccess =>
      'Verification location captured';

  @override
  String get verificationLocationFailureMessage =>
      'We could not capture the verification location right now. Retry shortly from this verification screen.';

  @override
  String get verificationGpsDisabledTitle => 'GPS is disabled';

  @override
  String get verificationGpsDisabledMessage =>
      'Location services are turned off. Please enable GPS in your device settings to capture your verification location.';

  @override
  String get verificationOpenSettingsAction => 'Open Settings';

  @override
  String get verificationPermissionDeniedTitle =>
      'Location permission required';

  @override
  String get verificationPermissionDeniedMessage =>
      'Location access is permanently denied. Please enable location permission in your app settings to continue.';

  @override
  String get verificationOpenAppSettingsAction => 'Open App Settings';

  @override
  String get verificationManualLocationAction => 'Enter location manually';

  @override
  String get verificationDocTypeAadhaarFront => 'Aadhaar front';

  @override
  String get verificationDocTypeAadhaarBack => 'Aadhaar back';

  @override
  String get verificationDocTypePan => 'PAN card';

  @override
  String get verificationDocTypeProfilePhoto => 'Profile photo';

  @override
  String get verificationDocTypeBusinessLicence => 'Business licence';

  @override
  String get verificationDocTypeGstCertificate => 'GST certificate';

  @override
  String get verificationDocumentChecklistTitle => 'Document checklist';

  @override
  String verificationDocumentUploadedSuccess(Object label) {
    return '$label uploaded successfully';
  }

  @override
  String get verificationDocumentUploadFailureMessage =>
      'We could not upload that verification document right now. Try another image or retry shortly.';

  @override
  String get verificationStatusVerified => 'Verified';

  @override
  String get verificationStatusRejected => 'Rejected';

  @override
  String get verificationStatusUnverified => 'Unverified';

  @override
  String get verificationPacketDetailsSectionTitle =>
      'Verification packet details';

  @override
  String verificationReadyTruckCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trucks',
      one: 'truck',
    );
    return '$count ready $_temp0';
  }

  @override
  String get verificationTruckReadyWithRcFooter =>
      'You already have at least one complete truck packet with RC document attached.';

  @override
  String get verificationTruckPacketStillRequiredTitle =>
      'A truck packet is still required';

  @override
  String get verificationTruckPacketStillRequiredMessage =>
      'Open your fleet to add the first truck or upload the RC document so trucker verification can be submitted as one packet.';

  @override
  String get verificationOpenFleetAction => 'Open fleet';

  @override
  String get verificationChatAndCallGatingBadge => 'Chat and call gating';

  @override
  String verificationUploadSourceTitle(Object documentLabel) {
    return 'Upload $documentLabel';
  }

  @override
  String verificationRejectionSummaryWithMarkers(Object summary) {
    return '$summary\n\nRejected documents are marked below with document-specific correction notes.';
  }

  @override
  String verificationRejectionSummaryPacketLevel(Object summary) {
    return '$summary\n\nCurrent review feedback is returned as one packet-level reason when document-specific review markers are not provided.';
  }

  @override
  String get verificationPendingBannerDescription =>
      'Your verification packet is already under review. You can keep browsing while review is pending.';

  @override
  String get verificationCompleteBannerTitle => 'Verification complete';

  @override
  String get verificationCompleteBannerDescription =>
      'Your account is already verified. You can still review the uploaded document checklist below.';

  @override
  String get verificationNeedsAttentionBannerDescription =>
      'Review the rejection summary, replace any affected documents, and resubmit the packet when ready.';

  @override
  String get verificationNotSubmittedTitle => 'Verification not submitted yet';

  @override
  String get verificationNotSubmittedSupplierMessage =>
      'Upload Aadhaar, PAN, profile photo, and business licence before submitting supplier verification.';

  @override
  String get verificationNotSubmittedTruckerMessage =>
      'Upload Aadhaar, PAN, profile photo, and ensure at least one approved truck exists before submitting trucker verification.';

  @override
  String get verificationLockedStatusSectionTitle => 'Verification status';

  @override
  String verificationLockedStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'verified_title': 'Verified',
      'pending_title': 'Under review',
      'verified_message':
          'Your verification has been approved. No action is needed right now.',
      'pending_message':
          'Your documents are being reviewed. You will be notified once the review is complete.',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get verificationSubmitLockedFooter =>
      'Once submitted, your details stay locked until the admin completes the review.';

  @override
  String verificationDocumentStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pending': 'pending',
      'verified': 'verified',
      'rejected': 'rejected',
      'uploaded': 'uploaded',
      'required': 'required',
      'optional': 'optional',
      'other': 'optional',
    });
    return '$_temp0';
  }

  @override
  String get verificationDocumentCorrectionFallback =>
      'This document needs correction before verification can be resubmitted.';

  @override
  String get verificationDocumentUploadedSubtitle =>
      'Document uploaded and linked to your verification record.';

  @override
  String get verificationDocumentRequiredSubtitle =>
      'Required before verification can be submitted.';

  @override
  String get verificationDocumentOptionalSubtitle =>
      'Optional for the current verification packet.';

  @override
  String verificationReviewNoteLabel(Object reason) {
    return 'Review note: $reason';
  }

  @override
  String verificationStoredPathLabel(Object path) {
    return 'Stored path: $path';
  }

  @override
  String get verificationDocumentMissingMessage =>
      'This document is still missing from the current packet.';

  @override
  String get verificationReplaceDocumentAction => 'Replace document';

  @override
  String get verificationUploadDocumentAction => 'Upload document';

  @override
  String get truckerTripDetailTitle => 'Trip Detail';

  @override
  String get truckerTripDetailLoadFailureTitle => 'Unable to load trip detail';

  @override
  String get truckerTripDetailLoadFailureMessage =>
      'We could not load this trip detail right now. Retry shortly to refresh the latest trip status and actions.';

  @override
  String get truckerTripDetailRatingFailureMessage =>
      'Your trip rating state is temporarily unavailable. Retry shortly before submitting a rating.';

  @override
  String get truckerTripDetailRatingSubmitFailureMessage =>
      'We could not submit your rating right now. Review the rating and retry shortly.';

  @override
  String get truckerTripDetailActionFailureMessage =>
      'The latest trip action could not be completed right now. Retry shortly after the trip detail refreshes.';

  @override
  String get truckerTripDetailActionSubmitFailureMessage =>
      'We could not complete that trip action right now. Retry shortly after checking the latest trip status.';

  @override
  String get truckerTripDetailLrUploadFailureMessage =>
      'We could not upload the LR proof right now. Try another image or retry shortly.';

  @override
  String get truckerTripDetailPodUploadFailureMessage =>
      'We could not upload the POD proof right now. Try another image or retry shortly.';

  @override
  String get truckerTripDetailRatingSectionTitle => 'Rate this trip';

  @override
  String get truckerTripDetailRatingAlreadySubmitted =>
      'You already rated this trip.';

  @override
  String truckerTripDetailRatingSubmittedOn(Object date) {
    return 'Submitted on $date';
  }

  @override
  String get truckerTripDetailRatingPrompt =>
      'Delivery is complete. Rate the supplier for this trip.';

  @override
  String get truckerTripDetailCommentLabel => 'Comment (optional)';

  @override
  String get truckerTripDetailCommentHint =>
      'Share anything useful about the trip outcome';

  @override
  String get truckerTripDetailRatingUnavailableTitle => 'Rating unavailable';

  @override
  String get truckerTripDetailSubmitRatingAction => 'Submit Rating';

  @override
  String get truckerTripDetailRatingSubmittedSuccess =>
      'Rating submitted successfully.';

  @override
  String truckerTripDetailRatingStarTooltip(Object count, Object s) {
    return '$count star$s';
  }

  @override
  String get truckerTripDetailAutoCompleteDueNow => 'Auto-complete is due now.';

  @override
  String truckerTripDetailAutoCompleteDuration(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String truckerTripDetailAutoCompleteIn(Object duration) {
    return 'Auto-complete in: $duration';
  }

  @override
  String truckerTripDetailHeroSubtitle(Object truckNumber) {
    return 'Truck $truckNumber';
  }

  @override
  String truckerTripDetailMaterialPickupSummary(
    Object material,
    Object pickupDate,
  ) {
    return '$material - Pickup $pickupDate';
  }

  @override
  String get truckerTripDetailActionUnavailableTitle =>
      'Trip action unavailable';

  @override
  String get truckerTripDetailActionsTitle => 'Actions';

  @override
  String get truckerTripDetailReplaceLrUploadAction => 'Replace LR Upload';

  @override
  String get truckerTripDetailUploadLrOptionalAction => 'Upload LR (Optional)';

  @override
  String get truckerTripDetailUploadLrImageTitle => 'Upload LR image';

  @override
  String get truckerTripDetailLrUploadedSuccess => 'LR uploaded successfully.';

  @override
  String get truckerTripDetailUploadPodPhotoAction => 'Upload POD Photo';

  @override
  String get truckerTripDetailUploadPodPhotoTitle => 'Upload POD photo';

  @override
  String get truckerTripDetailPodUploadedSuccess =>
      'POD uploaded successfully. Supplier confirmation is now pending.';

  @override
  String get truckerTripDetailCallSupplierAction => 'Call Supplier';

  @override
  String get commonOpenInGoogleMapsAction => 'Open in Google Maps';

  @override
  String truckerTripDetailReportSourceLabel(
    Object destinationLabel,
    Object originLabel,
  ) {
    return 'Trucker trip - $originLabel to $destinationLabel';
  }

  @override
  String get truckerTripDetailReviewCountdownTitle =>
      'Delivery review countdown';

  @override
  String get truckerTripDetailReviewCountdownMessage =>
      'Supplier confirmation is pending. This trip auto-completes 48 hours after POD upload if no action is taken.';

  @override
  String get truckerTripDetailDisputeStatusTitle => 'Dispute status';

  @override
  String get truckerTripDetailDisputeStateRaised =>
      'Current state: Dispute raised';

  @override
  String truckerTripDetailDisputeCurrentStateLabel(Object status) {
    return 'Current state: $status';
  }

  @override
  String truckerTripDetailDisputeCategoryLabel(Object category) {
    return '$category';
  }

  @override
  String truckerTripDetailDisputeLastUpdatedLabel(Object date) {
    return 'Last updated: $date';
  }

  @override
  String get truckerTripDetailDisputeStatusGuidanceOpen =>
      'Support has received this dispute and review should begin shortly. Keep the related support replies clear if more proof context is needed.';

  @override
  String get truckerTripDetailDisputeStatusGuidanceInProgress =>
      'Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.';

  @override
  String get truckerTripDetailDisputeStatusGuidanceWaitingForUser =>
      'Support is waiting for your clarification or additional context. Reply on the related support ticket so the review can continue.';

  @override
  String get truckerTripDetailDisputeStatusGuidanceResolved =>
      'This dispute has reached a final review state. Check the linked support ticket outcome before raising any fresh follow-up issue.';

  @override
  String get truckerTripDetailDisputeStatusGuidanceDefault =>
      'Keep following the related support ticket for the latest visible review updates.';

  @override
  String get truckerTripDetailDisputeBannerWaitingTitle =>
      'Dispute waiting for your reply';

  @override
  String get truckerTripDetailDisputeBannerNoSummaryMessage =>
      'A dispute has been raised on this trip. The trip stays open while support or operations review the submitted proof and delivery context. Both sides can see dispute status, but sensitive evidence may remain restricted during review.';

  @override
  String truckerTripDetailDisputeBannerWaitingMessage(Object category) {
    return 'A dispute has been raised on this trip under $category and is waiting on your clarification or proof. Sensitive evidence may remain restricted during review.';
  }

  @override
  String truckerTripDetailDisputeBannerClosedMessage(Object category) {
    return 'A dispute raised on this trip under $category has reached a final review outcome. Recorded status updates remain visible, while sensitive evidence may remain restricted.';
  }

  @override
  String truckerTripDetailDisputeBannerInProgressMessage(Object category) {
    return 'A dispute has been raised on this trip under $category. The trip stays open while support or operations review the delivery context, and sensitive evidence may remain restricted during review.';
  }

  @override
  String get truckerTripDetailDisputeActionGuidanceClosed =>
      'This dispute has reached a final review state. Keep this trip detail for the recorded outcome and start a fresh follow-up only if a genuinely new issue appears.';

  @override
  String get truckerTripDetailDisputeActionGuidanceInProgress =>
      'No further trip-stage action is available until the dispute is resolved. Keep this trip detail for status updates and follow any support instructions if requested.';

  @override
  String get truckerTripDetailSharedVisibilityClosed =>
      'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.';

  @override
  String get truckerTripDetailSharedVisibilityInProgress =>
      'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.';

  @override
  String get truckerTripDetailProofGuidanceClosed =>
      'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.';

  @override
  String get truckerTripDetailProofGuidanceInProgress =>
      'If additional supporting proofs are not attached in the current single-image flow, keep the related support replies clear so support and operations know what else to review.';

  @override
  String get truckerTripDetailCancelledTitle => 'Trip cancelled';

  @override
  String get truckerTripDetailCancelledMessage =>
      'This trip was cancelled before completion. No further execution actions are available, and this detail now serves as a record of the cancelled movement.';

  @override
  String get truckerTripDetailCancellationSummaryTitle =>
      'Cancellation summary';

  @override
  String get truckerTripDetailCancellationCurrentState =>
      'Current state: cancelled';

  @override
  String truckerTripDetailRouteLabel(Object route) {
    return 'Route: $route';
  }

  @override
  String truckerTripDetailMaterialLabel(Object material) {
    return 'Material: $material';
  }

  @override
  String truckerTripDetailAssignedOnLabel(Object dateTime) {
    return 'Assigned on: $dateTime';
  }

  @override
  String get truckerTripDetailCancellationFollowupMessage =>
      'If support or operations share follow-up instructions, use this trip reference and the existing trip timeline for context.';

  @override
  String get truckerTripDetailTripSummaryTitle => 'Trip summary';

  @override
  String get truckerTripDetailTripSummaryMessage =>
      'This trip is complete and closed out from the execution workflow.';

  @override
  String truckerTripDetailCompletedOnLabel(Object dateTime) {
    return 'Completed on: $dateTime';
  }

  @override
  String truckerTripDetailOriginLabel(Object origin) {
    return 'Origin: $origin';
  }

  @override
  String truckerTripDetailDestinationLabel(Object destination) {
    return 'Destination: $destination';
  }

  @override
  String truckerTripDetailDistanceLabel(Object distance) {
    return 'Distance: $distance km';
  }

  @override
  String truckerTripDetailDriveTimeLabel(Object minutes) {
    return 'Drive time: $minutes min';
  }

  @override
  String truckerTripDetailAssignedLabel(Object dateTime) {
    return 'Assigned: $dateTime';
  }

  @override
  String truckerTripDetailStartedLabel(Object dateTime) {
    return 'Started: $dateTime';
  }

  @override
  String truckerTripDetailDeliveredLabel(Object dateTime) {
    return 'Delivered: $dateTime';
  }

  @override
  String truckerTripDetailPodUploadedLabel(Object dateTime) {
    return 'POD uploaded: $dateTime';
  }

  @override
  String truckerTripDetailCompletedLabel(Object dateTime) {
    return 'Completed: $dateTime';
  }

  @override
  String get truckerTripDetailTruckSupplierTitle => 'Truck and supplier';

  @override
  String truckerTripDetailTruckNumberLabel(Object truckNumber) {
    return 'Truck number: $truckNumber';
  }

  @override
  String truckerTripDetailBodyTypeLabel(Object bodyType) {
    return 'Body type: $bodyType';
  }

  @override
  String truckerTripDetailTyresLabel(Object tyres) {
    return 'Tyres: $tyres';
  }

  @override
  String truckerTripDetailSupplierLabel(Object name) {
    return 'Supplier: $name';
  }

  @override
  String truckerTripDetailCompanyLabel(Object companyName) {
    return 'Company: $companyName';
  }

  @override
  String truckerTripDetailMobileLabel(Object mobile) {
    return 'Mobile: $mobile';
  }

  @override
  String get truckerTripDetailHeadToPickupAction => 'Head to pickup';

  @override
  String get truckerTripDetailHeadToPickupSuccess =>
      'Pickup movement started. The supplier can now see that you are heading to pickup.';

  @override
  String get truckerTripDetailCargoLoadedAction => 'Cargo Loaded';

  @override
  String get truckerTripDetailCargoLoadedSuccess =>
      'Cargo loading has been confirmed for this trip.';

  @override
  String get truckerTripDetailStartTripAction => 'Start Trip';

  @override
  String get truckerTripDetailStartTripSuccess =>
      'Trip started successfully. This load is now in transit.';

  @override
  String get truckerTripDetailMarkDeliveredAction => 'Mark Delivered';

  @override
  String get truckerTripDetailMarkDeliveredSuccess =>
      'Delivery recorded. Upload POD in the next step to complete the proof flow.';

  @override
  String get truckerTripDetailNextStepAssignedTitle => 'Head to pickup';

  @override
  String get truckerTripDetailNextStepAssignedMessage =>
      'This trip is assigned and waiting for the pickup movement to begin.';

  @override
  String get truckerTripDetailNextStepPickupPendingTitle => 'Confirm loading';

  @override
  String get truckerTripDetailNextStepPickupPendingMessage =>
      'The trip is at pickup and waiting for cargo loading confirmation.';

  @override
  String get truckerTripDetailNextStepPickedUpTitle => 'Start the trip';

  @override
  String get truckerTripDetailNextStepPickedUpMessage =>
      'Cargo is loaded and the next operational milestone is moving into transit.';

  @override
  String get truckerTripDetailNextStepInTransitTitle => 'Reach destination';

  @override
  String get truckerTripDetailNextStepInTransitMessage =>
      'The trip is in transit and the next milestone is delivery confirmation.';

  @override
  String get truckerTripDetailNextStepDeliveredTitle => 'Upload POD';

  @override
  String get truckerTripDetailNextStepDeliveredMessage =>
      'Delivery is recorded and proof of delivery is the next required step.';

  @override
  String get truckerTripDetailNextStepProofSubmittedTitle =>
      'Await supplier confirmation';

  @override
  String get truckerTripDetailNextStepProofSubmittedMessage =>
      'Proof is submitted and the trip is waiting for supplier review or auto-completion.';

  @override
  String get truckerTripDetailNextStepCompletedTitle => 'Trip completed';

  @override
  String get truckerTripDetailNextStepCompletedMessage =>
      'Execution is closed and this trip now serves as a historical record.';

  @override
  String get truckerTripDetailNextStepDisputedMessage =>
      'A dispute is active on this trip and operational review is required before closure.';

  @override
  String get truckerTripDetailNextStepCancelledTitle => 'Trip cancelled';

  @override
  String get truckerTripDetailNextStepCancelledMessage =>
      'This trip was cancelled before normal completion and no further execution steps remain.';

  @override
  String get truckerTripDetailNextStepDefaultTitle => 'Check execution status';

  @override
  String get truckerTripDetailNextStepDefaultMessage =>
      'Review the current trip state and recent timestamps to understand the latest movement.';

  @override
  String get supplierRaiseDisputeTitle => 'Raise Dispute';

  @override
  String get supplierRaiseDisputeTripUnavailableTitle =>
      'Trip detail unavailable';

  @override
  String get supplierRaiseDisputeTripLoadFailureMessage =>
      'We could not load this trip detail right now. Retry shortly to review the latest dispute context.';

  @override
  String get supplierRaiseDisputeHeroTitle => 'Dispute delivery proof';

  @override
  String get supplierRaiseDisputeHeroSubtitle =>
      'Explain what is wrong with the submitted POD so the dispute can be opened against the current trip and routed into support review.';

  @override
  String get supplierRaiseDisputeTripBadge => 'Trip under review';

  @override
  String supplierRaiseDisputeHeroSummary(Object material, Object routeLabel) {
    return '$routeLabel - $material';
  }

  @override
  String get supplierRaiseDisputeHeroGuidance =>
      'Select the dispute category that best matches the issue, add a written explanation, and optionally attach one supporting evidence image for support review.';

  @override
  String get supplierRaiseDisputePartialContextUnavailableTitle =>
      'Some trip detail context is unavailable';

  @override
  String get supplierRaiseDisputeTripContextFailureMessage =>
      'Some dispute context is temporarily unavailable. Retry shortly to refresh the latest trip detail and proof review state.';

  @override
  String get supplierRaiseDisputeSummaryTitle => 'Dispute summary';

  @override
  String supplierRaiseDisputeTripRouteLabel(Object routeLabel) {
    return 'Trip route: $routeLabel';
  }

  @override
  String supplierRaiseDisputeTruckLabel(Object truckNumber) {
    return 'Truck: $truckNumber';
  }

  @override
  String supplierRaiseDisputeTruckerLabel(Object truckerName) {
    return 'Trucker: $truckerName';
  }

  @override
  String supplierRaiseDisputeCurrentStageLabel(Object stageLabel) {
    return 'Current stage: $stageLabel';
  }

  @override
  String get supplierRaiseDisputeSubmissionBlockedTitle =>
      'Dispute submission blocked';

  @override
  String get supplierRaiseDisputeSubmissionBlockedMessage =>
      'You can only raise this POD dispute while the trip is in proof submitted state.';

  @override
  String get supplierRaiseDisputeSubmissionUnavailableTitle =>
      'Dispute submission unavailable';

  @override
  String get supplierRaiseDisputeSubmitFailureMessage =>
      'We could not submit this dispute right now. Review the dispute details and retry shortly.';

  @override
  String get supplierRaiseDisputeProblemTitle => 'What is wrong with the POD?';

  @override
  String get supplierRaiseDisputeCategoryLabel => 'Dispute category';

  @override
  String get supplierRaiseDisputeReasonLabel => 'Dispute reason';

  @override
  String get supplierRaiseDisputeReasonHint =>
      'Explain what is wrong with the submitted proof and what support should review.';

  @override
  String get supplierRaiseDisputeHelpfulDetailsTitle =>
      'Helpful details to include';

  @override
  String get supplierRaiseDisputeHelpfulDetailsMessage =>
      'The current dispute flow still accepts one optional image. Use these prompts to capture any second or third proof in your written explanation.';

  @override
  String get supplierRaiseDisputeEvidenceOptionalTitle => 'Evidence (optional)';

  @override
  String get supplierRaiseDisputeNoEvidenceAttached =>
      'No evidence image attached yet. You can attach one supporting image in the current flow.';

  @override
  String get supplierRaiseDisputeEvidenceAttached =>
      'One supporting evidence image is attached for review.';

  @override
  String get supplierRaiseDisputeVisibleToOtherPartyMessage =>
      'Visible to the other party: dispute category and status only. Raw evidence may stay restricted during review.';

  @override
  String get supplierRaiseDisputeUseCameraAction => 'Use camera';

  @override
  String get supplierRaiseDisputeChoosePhotoAction => 'Choose photo';

  @override
  String get supplierRaiseDisputeRemoveEvidenceAction => 'Remove evidence';

  @override
  String get supplierRaiseDisputeSubmitAction => 'Submit dispute';

  @override
  String get supplierRaiseDisputeCategoryError =>
      'Select a valid dispute category';

  @override
  String get supplierRaiseDisputeReasonError =>
      'Explain the POD problem in at least 10 characters';

  @override
  String get supplierRaiseDisputeSubmittedSuccess =>
      'Dispute submitted. Support ticket created for review.';

  @override
  String get supplierRaiseDisputeAttachmentAttachedSuccess =>
      'Evidence attached successfully';

  @override
  String get commonAttachmentFailureMessage =>
      'We could not attach that evidence image right now. Try another image or retry shortly.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceLoadedQuantityMismatch =>
      'Recommended evidence: the loaded bilty or loading proof that shows the dispatched quantity. Only one image can be attached right now.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceUnloadedQuantityMismatch =>
      'Recommended evidence: the unloaded bilty, weighbridge slip, or unloading proof showing the received quantity. Only one image can be attached right now.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceDocumentMismatch =>
      'Recommended evidence: the clearest POD, bilty, or related proof image showing the document mismatch. Only one image can be attached right now.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceNonPayment =>
      'Recommended evidence: one proof image that best supports the non-payment claim. Full payment workflow evidence still remains limited in the current flow.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceFakePayoutProof =>
      'Recommended evidence: one payout-proof image that best shows the fake or inconsistent payment claim.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceDelayOrNoShow =>
      'Recommended evidence: one supporting image or screenshot that best shows the delay or no-show context.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceDamageOrShortage =>
      'Recommended evidence: one image that best shows the damage, shortage, or affected goods at delivery.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceAbusiveBehavior =>
      'Recommended evidence: one supporting image or screenshot if it is safe and relevant to the abusive-behavior claim.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceSpamOrScam =>
      'Recommended evidence: one screenshot or proof image that best supports the spam or scam report.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceOther =>
      'Provide a clear explanation of the dispute and attach the single most relevant supporting image if needed.';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceFallback =>
      'Attach the single most relevant supporting image available for this dispute category.';

  @override
  String get supplierRaiseDisputeBestImageGuidanceDocumentCategory =>
      'Choose the clearest single document image where quantities, signatures, stamps, or POD details are readable in one frame.';

  @override
  String get supplierRaiseDisputeBestImageGuidancePaymentCategory =>
      'Choose the single screenshot or payout-proof image that most clearly shows the mismatch, missing payment, or fake confirmation.';

  @override
  String get supplierRaiseDisputeBestImageGuidanceTimelineCategory =>
      'Choose the single screenshot or photo that gives the strongest timeline or behavior context in one image.';

  @override
  String get supplierRaiseDisputeBestImageGuidanceDamageCategory =>
      'Choose the single image that best shows the damaged goods, shortage, or delivered condition at handover.';

  @override
  String get supplierRaiseDisputeBestImageGuidanceOther =>
      'Choose the one image that gives support the strongest proof of the issue you describe in your written reason.';

  @override
  String get supplierRaiseDisputeBestImageGuidanceFallback =>
      'Choose the one clearest image that gives support the strongest proof to review first.';

  @override
  String get supplierRaiseDisputePromptDispatchQuantityShownOnProof =>
      'Dispatch quantity shown on proof:';

  @override
  String get supplierRaiseDisputePromptQuantityActuallyChallenged =>
      'Quantity actually challenged:';

  @override
  String get supplierRaiseDisputePromptOtherLoadingProofNotAttached =>
      'Other loading proof not attached but reviewed by support:';

  @override
  String get supplierRaiseDisputePromptQuantityReceivedAtUnloading =>
      'Quantity received at unloading:';

  @override
  String get supplierRaiseDisputePromptQuantityExpectedFromDispatchProof =>
      'Quantity expected from dispatch proof:';

  @override
  String get supplierRaiseDisputePromptExtraUnloadProofNotAttached =>
      'Extra unload proof not attached but available:';

  @override
  String get supplierRaiseDisputePromptDocumentFieldDoesNotMatch =>
      'Document field that does not match:';

  @override
  String get supplierRaiseDisputePromptCorrectTripOrPodDetailShouldBe =>
      'Correct trip or POD detail should be:';

  @override
  String get supplierRaiseDisputePromptOtherRelatedDocumentNotAttached =>
      'Other related document not attached but relevant:';

  @override
  String get supplierRaiseDisputePromptAmountStillUnpaid =>
      'Amount still unpaid:';

  @override
  String get supplierRaiseDisputePromptPaymentDueDateOrMilestone =>
      'Payment due date or milestone:';

  @override
  String get supplierRaiseDisputePromptOtherPaymentProofNotAttached =>
      'Other payment proof not attached but relevant:';

  @override
  String get supplierRaiseDisputePromptWhyPayoutProofLooksFake =>
      'Why the payout proof looks fake or inconsistent:';

  @override
  String get supplierRaiseDisputePromptWhatPaymentStatusShouldBe =>
      'What payment status should be instead:';

  @override
  String get supplierRaiseDisputePromptOtherProofOrChatContextNotAttached =>
      'Other proof or chat context not attached:';

  @override
  String get supplierRaiseDisputePromptExpectedReportingOrArrivalTime =>
      'Expected reporting or arrival time:';

  @override
  String get supplierRaiseDisputePromptActualDelayOrNoShowOutcome =>
      'Actual delay or no-show outcome:';

  @override
  String get supplierRaiseDisputePromptOtherTimingProofNotAttached =>
      'Other timing proof not attached but relevant:';

  @override
  String get supplierRaiseDisputePromptGoodsAffectedByDamageOrShortage =>
      'Goods affected by damage or shortage:';

  @override
  String get supplierRaiseDisputePromptQuantityOrConditionDifferenceNoticed =>
      'Quantity or condition difference noticed:';

  @override
  String get supplierRaiseDisputePromptOtherSupportingProofNotAttached =>
      'Other supporting proof not attached but relevant:';

  @override
  String get supplierRaiseDisputePromptWhatHappenedDuringIncident =>
      'What happened during the incident:';

  @override
  String get supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred =>
      'When or where the behavior occurred:';

  @override
  String get supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred =>
      'What scam or spam behavior occurred:';

  @override
  String get supplierRaiseDisputePromptWhatMisleadingClaimWasMade =>
      'What misleading claim was made:';

  @override
  String get supplierRaiseDisputePromptMainIssueSupportShouldReview =>
      'Main issue support should review:';

  @override
  String get supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded =>
      'What outcome or correction is needed:';

  @override
  String get supplierRaiseDisputePromptStrongestMissingProofNotAttached =>
      'Strongest missing proof not attached:';

  @override
  String get supplierRaiseDisputeChecklistLoadedReadableQuantity =>
      'Keep the dispatched quantity readable in the uploaded image.';

  @override
  String get supplierRaiseDisputeChecklistLoadedPreferBilty =>
      'Include the bilty, loading slip, or marked proof instead of a distant photo.';

  @override
  String get supplierRaiseDisputeChecklistLoadedUseWrittenReason =>
      'Use the written reason to describe any additional document context not visible in the image.';

  @override
  String get supplierRaiseDisputeChecklistUnloadedKeepReceivedQuantity =>
      'Keep the received quantity or unload record readable in the image.';

  @override
  String get supplierRaiseDisputeChecklistUnloadedPreferWeighbridge =>
      'Prefer a weighbridge slip, unload bilty, or marked proof over a generic cargo photo.';

  @override
  String get supplierRaiseDisputeChecklistUnloadedUseWrittenReason =>
      'Use the written reason to explain any missing second document that cannot fit in the current single-image flow.';

  @override
  String get supplierRaiseDisputeChecklistDocumentReadableFields =>
      'Make sure key document fields are readable in one frame.';

  @override
  String get supplierRaiseDisputeChecklistDocumentPreferSpecificPage =>
      'Prefer the specific POD or bilty page where the mismatch appears.';

  @override
  String get supplierRaiseDisputeChecklistDocumentUseWrittenReason =>
      'Use the written reason to describe what field or proof does not match the trip.';

  @override
  String get supplierRaiseDisputeChecklistPaymentPreferClearestScreenshot =>
      'Prefer the clearest single payout-related screenshot or proof image.';

  @override
  String get supplierRaiseDisputeChecklistPaymentUseWrittenReason =>
      'Use the written reason to explain what payment is still missing and when it was due.';

  @override
  String get supplierRaiseDisputeChecklistPaymentUploadStrongestFirst =>
      'If multiple proofs exist, upload the strongest one first and summarize the rest in text.';

  @override
  String get supplierRaiseDisputeChecklistFakePreferScreenshot =>
      'Prefer the payout screenshot or proof image that most clearly appears fake or inconsistent.';

  @override
  String get supplierRaiseDisputeChecklistFakeUseWrittenReason =>
      'Use the written reason to explain what is suspicious about the proof.';

  @override
  String get supplierRaiseDisputeChecklistFakeSummarizeChatContext =>
      'If supporting chat context exists, summarize it in text when it cannot fit in the single-image flow.';

  @override
  String get supplierRaiseDisputeChecklistDelayChooseClearestTiming =>
      'Choose the clearest screenshot or photo showing the missed timing or no-show context.';

  @override
  String get supplierRaiseDisputeChecklistDelayUseWrittenReason =>
      'Use the written reason to explain the expected time and the actual outcome.';

  @override
  String get supplierRaiseDisputeChecklistDelayKeepFocusedImage =>
      'Keep the uploaded image focused on timing/location evidence instead of unrelated media.';

  @override
  String get supplierRaiseDisputeChecklistDamageChooseImage =>
      'Choose the image that most clearly shows the damage or shortage at delivery.';

  @override
  String get supplierRaiseDisputeChecklistDamageKeepAffectedGoods =>
      'Keep the affected goods or missing quantity context visible in the frame.';

  @override
  String get supplierRaiseDisputeChecklistDamageUseWrittenReason =>
      'Use the written reason to explain what cannot be shown in the single uploaded image.';

  @override
  String get supplierRaiseDisputeChecklistAbusiveUploadIfSafe =>
      'Upload evidence only if it is safe and relevant to the case.';

  @override
  String get supplierRaiseDisputeChecklistAbusivePreferClearestScreenshot =>
      'Prefer the clearest screenshot or image tied directly to the abusive incident.';

  @override
  String get supplierRaiseDisputeChecklistAbusiveUseWrittenReason =>
      'Use the written reason to explain the sequence of events without adding sensitive internal notes.';

  @override
  String get supplierRaiseDisputeChecklistSpamChooseScreenshot =>
      'Choose the screenshot or image that most clearly shows the scam or spam behavior.';

  @override
  String get supplierRaiseDisputeChecklistSpamPreferStrongestProof =>
      'Prefer the strongest proof of deception instead of a partial conversation fragment.';

  @override
  String get supplierRaiseDisputeChecklistSpamUseWrittenReason =>
      'Use the written reason to summarize any extra scam context that cannot fit in one image.';

  @override
  String get supplierRaiseDisputeChecklistOtherChooseStrongestImage =>
      'Choose the one strongest image that supports your explanation.';

  @override
  String get supplierRaiseDisputeChecklistOtherKeepIssueReadable =>
      'Keep the issue-specific detail readable in the uploaded image.';

  @override
  String get supplierRaiseDisputeChecklistOtherUseWrittenReason =>
      'Use the written reason to explain the rest of the evidence that cannot fit in the current flow.';

  @override
  String get supplierRaiseDisputeChecklistFallbackChooseClearestImage =>
      'Choose the one clearest supporting image available.';

  @override
  String get supplierRaiseDisputeChecklistFallbackKeepReadableProof =>
      'Keep the important proof readable in the frame.';

  @override
  String get supplierRaiseDisputeChecklistFallbackUseWrittenReason =>
      'Use the written reason to describe any additional evidence not visible in the image.';

  @override
  String get reportIssueTitle => 'Report Issue';

  @override
  String get reportIssueHeroTitle => 'Report spam, scam, or abuse';

  @override
  String get reportIssueHeroSubtitle =>
      'Open a trust-safety ticket tied to the current operational context so support can review the issue quickly.';

  @override
  String get reportIssueHeroMessage =>
      'Attach one evidence image if you have it. The report still submits through the live support-ticket workflow using the linked load/trip context, and can also capture fake payout-proof or non-payment issues.';

  @override
  String get reportIssueSubmissionUnavailableTitle =>
      'Report submission unavailable';

  @override
  String get reportIssueFailureMessage =>
      'This report could not be prepared or submitted right now. Review the linked context and try again shortly.';

  @override
  String get reportIssueLinkedContextTitle => 'Linked context';

  @override
  String reportIssueSourceLabel(Object sourceLabel) {
    return 'Source: $sourceLabel';
  }

  @override
  String get reportIssueRelatedLoadLabel => 'Related load linked';

  @override
  String get reportIssueRelatedTripLabel => 'Related trip linked';

  @override
  String get reportIssueNotLinked => 'Not linked';

  @override
  String get reportIssueDetailsTitle => 'Report details';

  @override
  String get reportIssueTypeLabel => 'Issue type';

  @override
  String get reportIssueWhatHappenedLabel => 'What happened?';

  @override
  String get reportIssueWhatHappenedHint =>
      'Explain the spam, fake proof, non-payment, payout deception, or abusive behavior that support should review.';

  @override
  String get reportIssueHelpfulDetailsTitle => 'Helpful details to include';

  @override
  String get reportIssueEvidenceOptionalTitle => 'Evidence (required)';

  @override
  String get reportIssueNoEvidenceAttached =>
      'Attach one evidence image before submitting this report.';

  @override
  String get reportIssueEvidenceAttached =>
      'One evidence image is attached for review.';

  @override
  String get reportIssueUseCameraAction => 'Use camera';

  @override
  String get reportIssueChoosePhotoAction => 'Choose photo';

  @override
  String get reportIssueRemoveEvidenceAction => 'Remove evidence';

  @override
  String get reportIssueSubmitAction => 'Submit report';

  @override
  String get reportIssueSubmittedSuccess => 'Report submitted successfully';

  @override
  String get reportIssueSubmitFailureMessage =>
      'We could not submit this report right now. Review the details and retry shortly.';

  @override
  String get reportIssueAttachmentAttachedSuccess =>
      'Evidence attached successfully';

  @override
  String get reportIssueCategorySpamOrScamLabel => 'Spam or scam';

  @override
  String get reportIssueCategoryAbusiveBehaviorLabel => 'Abusive behavior';

  @override
  String get reportIssueCategoryFakePayoutProofLabel => 'Fake payout proof';

  @override
  String get reportIssueCategoryNonPaymentLabel => 'Non-payment';

  @override
  String get reportIssueCategoryGuidanceSpamOrScam =>
      'Explain the spam, scam, or misleading behavior clearly and attach one evidence image that helps support review the report.';

  @override
  String get reportIssueCategoryGuidanceAbusiveBehavior =>
      'Describe the abusive or unsafe behavior clearly, including where it happened and any context support should review.';

  @override
  String get reportIssueCategoryGuidanceFakePayoutProof =>
      'Explain why the payout proof looks fake or misleading and attach one evidence image with the most useful payment context you can share.';

  @override
  String get reportIssueCategoryGuidanceNonPayment =>
      'Describe the non-payment issue clearly, including what was due, what follow-up already happened, and attach one evidence image with the strongest payment proof you can share.';

  @override
  String get supportCreateTicketScreenTitle => 'Create support ticket';

  @override
  String get supportCreateTicketHeroTitle => 'Open a support request';

  @override
  String get supportCreateTicketHeroSubtitle =>
      'Describe your issue clearly so support can route it faster and keep your follow-up thread linked to the right context.';

  @override
  String get supportCreateTicketHeroMessage =>
      'You can optionally include a related load or trip id if the issue is tied to a specific operational flow. You can also attach one evidence image if it helps support review the issue faster.';

  @override
  String get supportCreateTicketFailureTitle =>
      'Support request needs attention';

  @override
  String get supportCreateTicketFailureMessage =>
      'Your support request could not be prepared or submitted right now. Review the issue details and try again shortly.';

  @override
  String get supportCreateTicketDetailsTitle => 'Ticket details';

  @override
  String get supportComposeCategoryLabel => 'Category';

  @override
  String get supportComposeCategoryGeneral => 'General';

  @override
  String get supportComposeCategoryAccount => 'Account';

  @override
  String get supportComposeCategoryLoad => 'Load';

  @override
  String get supportComposeCategoryTrip => 'Trip';

  @override
  String get supportComposeCategoryPayment => 'Payment';

  @override
  String get supportComposeCategoryTechnical => 'Technical';

  @override
  String get supportComposeCategoryOther => 'Other';

  @override
  String get supportCreateTicketRelatedLoadIdLabel =>
      'Related load id (optional)';

  @override
  String get supportCreateTicketRelatedLoadIdHint => 'load-123';

  @override
  String get supportCreateTicketRelatedTripIdLabel =>
      'Related trip id (optional)';

  @override
  String get supportCreateTicketRelatedTripIdHint => 'trip-123';

  @override
  String get supportCreateTicketDescriptionLabel => 'Describe the issue';

  @override
  String get supportCreateTicketDescriptionHint =>
      'Explain what happened, what is blocked, and what follow-up you need.';

  @override
  String get supportComposeAttachmentOptionalTitle => 'Attachment (optional)';

  @override
  String get supportComposeNoAttachment => 'No evidence image attached yet.';

  @override
  String get supportComposeAttachmentAttached =>
      'One evidence image is attached for support review.';

  @override
  String get supportComposeRemoveAttachmentAction => 'Remove attachment';

  @override
  String get supportComposeAttachmentAddedSuccess =>
      'Attachment added successfully';

  @override
  String get supportCreateTicketInvalidCategoryMessage =>
      'Select a valid support category';

  @override
  String get supportCreateTicketDescriptionTooShortMessage =>
      'Describe the issue in at least 10 characters';

  @override
  String get reportIssueInvalidCategoryMessage =>
      'Select a valid report category';

  @override
  String get reportIssueDescriptionTooShortMessage =>
      'Describe the issue in at least 10 characters';

  @override
  String get reportIssueAttachmentRequiredMessage =>
      'Attach one evidence image before submitting this report';

  @override
  String get supportReplyMessageTooShortMessage =>
      'Reply must contain at least 2 characters';

  @override
  String get supportCreateTicketSubmitAction => 'Submit ticket';

  @override
  String get supportCreateTicketSubmittedSuccess =>
      'Support ticket created successfully';

  @override
  String get supportCreateTicketSubmitFailureMessage =>
      'We could not create this support ticket right now. Review the details and retry shortly.';

  @override
  String get supportReplyFailureTitle => 'Reply needs attention';

  @override
  String get supportReplyFailureMessage =>
      'Your latest support reply could not be prepared or submitted right now. Review the message and try again shortly.';

  @override
  String get supportReplyLabel => 'Reply to support';

  @override
  String get supportReplyHint =>
      'Add the next detail or response support requested.';

  @override
  String get supportReplySendAction => 'Send reply';

  @override
  String get supportReplySentSuccess => 'Reply sent successfully';

  @override
  String get supportReplySubmitFailureMessage =>
      'We could not send your reply right now. Review the message and retry shortly.';

  @override
  String get supplierTripsSectionTitle => 'Supplier trips';

  @override
  String get supplierTripsSectionSubtitle =>
      'Track active movements and recent trip outcomes from one supplier execution surface.';

  @override
  String get supplierTripsLoadFailureTitle => 'Unable to load supplier trips';

  @override
  String get supplierTripsLoadFailureMessage =>
      'We could not load your supplier trips right now. Retry shortly to refresh the latest trip list and statuses.';

  @override
  String get supplierTripsEmptyActiveTitle => 'No active trips yet';

  @override
  String get supplierTripsEmptyCompletedTitle => 'No completed trips yet';

  @override
  String get supplierTripsEmptyActiveSubtitle =>
      'Trips will appear here once a load moves into assigned execution.';

  @override
  String get supplierTripsEmptyCompletedSubtitle =>
      'Completed supplier trips will appear here once deliveries are closed out.';

  @override
  String get supplierTripsEmptyCompletedAction => 'View active trips';

  @override
  String supplierTripsAssignedLabel(Object date) {
    return 'Assigned $date';
  }

  @override
  String supplierTripsTruckerTruckLabel(Object truckId, Object truckerId) {
    return 'Trucker $truckerId - Truck $truckId';
  }

  @override
  String get supplierTripsTrackTripAction => 'Track trip';

  @override
  String get supplierTripDetailNotFoundTitle => 'Trip not found';

  @override
  String get supplierTripDetailNotFoundSubtitle =>
      'This supplier trip is no longer available or you no longer have access to it.';

  @override
  String get supplierTripDetailBackToTripsAction => 'Back to supplier trips';

  @override
  String get shellAccessRestrictedTitle => 'Access restricted';

  @override
  String get shellAccessRestrictedDeactivatedSubtitle =>
      'Your account is deactivated pending cleanup. Signing you out safely...';

  @override
  String get shellAccessRestrictedBannedSubtitle =>
      'Your account access is restricted. Signing you out safely...';

  @override
  String get shellRouteNotFoundTitle => 'Route not found';

  @override
  String get shellMessagesLoadFailureMessage =>
      'We could not load your messages right now. Retry shortly to refresh the latest conversations.';

  @override
  String shellMessagesBookingStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'submitted': 'Submitted',
      'approved': 'Approved',
      'rejected': 'Rejected',
      'pending': 'Pending',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String get truckerLoadDetailTitle => 'Load Detail';

  @override
  String get truckerLoadDetailLoadNotFoundTitle => 'Load not found';

  @override
  String get truckerLoadDetailLoadNotFoundSubtitle =>
      'This marketplace load is no longer available or you no longer have access to it.';

  @override
  String get truckerLoadDetailBackToFindLoadsAction => 'Back to find loads';

  @override
  String get truckerLoadDetailLoadFailureTitle =>
      'Unable to load freight detail';

  @override
  String get truckerLoadDetailLoadFailureMessage =>
      'We could not load this freight detail right now. Retry shortly to refresh the current route, pricing, and booking context.';

  @override
  String get truckerLoadDetailSupportUnavailableTitle =>
      'Some supporting load details are unavailable';

  @override
  String get truckerLoadDetailSupportFailureMessage =>
      'Some supporting load details are temporarily unavailable. Retry shortly to refresh the latest freight context.';

  @override
  String get truckerLoadDetailActionFailureTitle => 'Action unavailable';

  @override
  String get truckerLoadDetailActionFailureMessage =>
      'The latest load action could not be completed right now. Review the current load details and retry shortly.';

  @override
  String get truckerLoadDetailBookingSubmitFailureMessage =>
      'We could not submit this booking request right now. Review the selected truck and retry shortly.';

  @override
  String truckerLoadDetailHeroSubtitle(Object pickupDate) {
    return 'Pickup $pickupDate';
  }

  @override
  String truckerLoadDetailPriceBadge(Object priceAmount, Object priceType) {
    return '₹$priceAmount - $priceType';
  }

  @override
  String get truckerLoadDetailTruckMatchAvailable => 'Truck match available';

  @override
  String truckerLoadDetailMaterialSummary(
    Object advancePercentage,
    Object material,
    Object weightTonnes,
  ) {
    return '$material - ${weightTonnes}T - Advance $advancePercentage%';
  }

  @override
  String get truckerLoadDetailSuperLoadGuarantee =>
      'Super Load - Payment Guarantee';

  @override
  String get truckerLoadDetailRoutePriceSummaryTitle =>
      'Route and price summary';

  @override
  String get truckerLoadDetailRouteMapTitle => 'Route map';

  @override
  String truckerLoadDetailPickupLabel(Object pickupDate) {
    return 'Pickup: $pickupDate';
  }

  @override
  String truckerLoadDetailPriceLabel(Object priceAmount, Object priceType) {
    return 'Price: ₹$priceAmount - $priceType';
  }

  @override
  String truckerLoadDetailDistanceLabel(Object distance) {
    return 'Distance: $distance km';
  }

  @override
  String truckerLoadDetailDriveTimeLabel(Object minutes) {
    return 'Estimated drive time: $minutes min';
  }

  @override
  String get truckerLoadDetailTruckRequirementTitle =>
      'Truck requirement summary';

  @override
  String truckerLoadDetailBodyTypeLabel(Object bodyType) {
    return 'Body type: $bodyType';
  }

  @override
  String truckerLoadDetailTyresLabel(Object tyres) {
    return 'Tyres: $tyres';
  }

  @override
  String truckerLoadDetailTrucksNeededLabel(Object booked, Object needed) {
    return 'Trucks needed: $booked/$needed booked';
  }

  @override
  String truckerLoadDetailPerTruckWeightLabel(Object weight) {
    return 'Per truck: ${weight}T';
  }

  @override
  String truckerLoadDetailCapacityRangeLabel(Object maxT, Object minT) {
    return 'Acceptable truck: ${minT}T – ${maxT}T';
  }

  @override
  String truckerLoadDetailSlotsOpenLabel(Object count) {
    return '$count slots open';
  }

  @override
  String get truckerLoadDetailNoApprovedTruckSelected =>
      'No approved truck selected';

  @override
  String get truckerLoadDetailSelectedTruckMatches =>
      'Selected truck matches this load';

  @override
  String get truckerLoadDetailSelectedTruckMayNotMatch =>
      'Selected truck may not match this load';

  @override
  String get truckerLoadDetailCargoScheduleTitle =>
      'Cargo and schedule details';

  @override
  String truckerLoadDetailMaterialLabel(Object material) {
    return 'Material: $material';
  }

  @override
  String truckerLoadDetailWeightLabel(Object weight) {
    return 'Weight: $weight tonnes';
  }

  @override
  String truckerLoadDetailOriginCityLabel(Object city) {
    return 'Origin city: $city';
  }

  @override
  String truckerLoadDetailDestinationCityLabel(Object city) {
    return 'Destination city: $city';
  }

  @override
  String get truckerLoadDetailTripCostEstimateTitle => 'Trip cost estimate';

  @override
  String get truckerLoadDetailTripCostUnavailableTitle =>
      'Trip cost unavailable';

  @override
  String get truckerLoadDetailTripCostUnavailableMessage =>
      'Distance is unavailable for this load right now, so the trip cost estimate cannot be calculated yet.';

  @override
  String get truckerLoadDetailSupplierSummaryTitle => 'Supplier summary';

  @override
  String get truckerLoadDetailVerifiedSupplier => 'Verified supplier';

  @override
  String get truckerLoadDetailSupplierProfile => 'Supplier profile';

  @override
  String truckerLoadDetailStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'Active',
      'assigned_partial': 'Assigned partial',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String truckerLoadDetailBookingStatusLabel(Object status) {
    return 'Booking status: $status';
  }

  @override
  String get truckerLoadDetailBookingFeedbackTitle => 'Booking feedback';

  @override
  String get truckerLoadDetailBookingBlockedTitle => 'Booking is blocked';

  @override
  String truckerLoadDetailUsingTruckLabel(Object truckNumber) {
    return 'Using $truckNumber';
  }

  @override
  String truckerLoadDetailSelectedTruckSummary(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  ) {
    return 'This load will be booked with $truckNumber - $bodyType - $tyres tyres.';
  }

  @override
  String get truckerLoadDetailApprovedTruckLabel =>
      'Approved truck for this request';

  @override
  String truckerLoadDetailTruckOptionLabel(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  ) {
    return '$truckNumber - $bodyType - $tyres tyres';
  }

  @override
  String get truckerLoadDetailNoApprovedTrucksAvailable =>
      'No approved trucks are available yet.';

  @override
  String get truckerLoadDetailAddTruckFirstAction => 'Add a Truck First';

  @override
  String get truckerLoadDetailRequestSubmittedAction => 'Request Submitted';

  @override
  String get truckerLoadDetailBookedAction => 'Booked';

  @override
  String get truckerLoadDetailBookThisLoadAction => 'Book This Load';

  @override
  String get truckerLoadDetailLoadBookedSuccess =>
      'Load booked! Waiting for supplier approval';

  @override
  String get truckerLoadDetailShareLoadAction => 'Share load';

  @override
  String get truckerLoadDetailShareLoadTitle => 'Share load';

  @override
  String get truckerLoadDetailShareLoadMessage =>
      'Share a safe summary-first load card without exposing direct phone numbers or private operational notes.';

  @override
  String get truckerLoadDetailSystemShareAction => 'System share';

  @override
  String get truckerLoadDetailShareToWhatsAppAction => 'Share to WhatsApp';

  @override
  String get truckerLoadDetailWhatsAppUnavailableMessage =>
      'WhatsApp is unavailable on this device. Use system share instead.';

  @override
  String truckerLoadDetailReportSourceLabel(Object routeLabel) {
    return 'Trucker load - $routeLabel';
  }

  @override
  String get truckerLoadDetailVerificationRequiredMessage =>
      'Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.';

  @override
  String get truckerLoadDetailTruckApprovalRequiredMessage =>
      'Add and approve at least one truck before booking this load or unlocking supplier chat.';

  @override
  String get truckerLoadDetailAddTruckDialogTitle => 'Add a truck first';

  @override
  String get truckerLoadDetailAddTruckDialogMessage =>
      'You need at least one approved truck before you can book this load. Open Fleet now to add or complete truck approval?';

  @override
  String get truckerLoadDetailNotNowAction => 'Not now';

  @override
  String get truckerLoadDetailOpenFleetAction => 'Open Fleet';

  @override
  String get truckerLoadDetailConfirmBookingTitle => 'Confirm load booking';

  @override
  String truckerLoadDetailConfirmBookingMessage(
    Object material,
    Object routeLabel,
    Object truckNumber,
  ) {
    return 'Book $material $routeLabel with $truckNumber?';
  }

  @override
  String get authTtsSplashWelcome =>
      'Welcome to TranZfort. I will help you finish a quick setup before you continue.';

  @override
  String get authSessionRefreshFailureMessage =>
      'We could not refresh your session right now. Please continue and try again if needed.';

  @override
  String get authConfigIncompleteTitle => 'Setup incomplete';

  @override
  String get postLoadValidationOriginCityRequired => 'Select the origin city';

  @override
  String get postLoadValidationOriginLocationRequired =>
      'Enter the pickup location';

  @override
  String get postLoadValidationDestinationCityRequired =>
      'Select the destination city';

  @override
  String get postLoadValidationDestinationLocationRequired =>
      'Enter the drop location';

  @override
  String get postLoadValidationMaterialRequired => 'Enter the material name';

  @override
  String get postLoadValidationWeightRange =>
      'Enter a weight between 0 and 100 tonnes';

  @override
  String get postLoadValidationTrucksNeeded => 'At least one truck is required';

  @override
  String get postLoadValidationPricePositive =>
      'Enter a valid price greater than zero';

  @override
  String get postLoadValidationPriceType => 'Select a valid price type';

  @override
  String get postLoadValidationPickupDatePast =>
      'Pickup date cannot be in the past';

  @override
  String settingsRoleSentenceHi(Object roleLabel) {
    return 'Current role: $roleLabel.';
  }

  @override
  String settingsRoleSentenceEn(Object roleLabel) {
    return 'Current role: $roleLabel.';
  }

  @override
  String get pushIssuePermissionRequestFailed => 'Permission request failed.';

  @override
  String get pushIssueLocalInitFailed => 'Local notification setup failed.';

  @override
  String get pushIssueDisplayFailed => 'Notification display failed.';

  @override
  String get pushIssueTokenSyncFailed => 'Token sync failed.';

  @override
  String get offlineSyncPending => 'pending';

  @override
  String get offlineSyncRetrying => 'retrying';

  @override
  String get offlineSyncFailed => 'failed';

  @override
  String get offlineSyncExhausted => 'exhausted (max retries)';

  @override
  String get validationProfilePhotoRequired => 'Profile photo is required';

  @override
  String get validationAadhaarRequired => 'Aadhaar number is required';

  @override
  String get validationTruckNumberRequired => 'Truck number is required';

  @override
  String get validationTruckCapacityRequired => 'Truck capacity is required';

  @override
  String get validationRcDocumentRequired => 'RC document is required';

  @override
  String get validationCompanyNameRequired => 'Company name is required';

  @override
  String get validationBusinessLicenseNumberRequired =>
      'License number is required';

  @override
  String get validationBusinessLicenseRequired =>
      'License document is required';

  @override
  String get validationVerificationLocationRequired =>
      'Verification location is required';

  @override
  String get validationVerificationCityRequired =>
      'Verification city is required';

  @override
  String get validationDocumentPathRequired => 'Document path is required';

  @override
  String get validationProfileIdRequired => 'Profile id is required';

  @override
  String get validationCameraPermissionRequired =>
      'Camera permission is required. Enable it in app settings.';

  @override
  String get validationPhotoAccessRequired =>
      'Photo access is required. Enable it in app settings.';

  @override
  String get validationTruckRequired => 'Truck is required';

  @override
  String get validationOwnerIdRequired => 'Owner id is required';

  @override
  String get validationTruckIdRequired => 'Truck id is required';

  @override
  String get validationTripIdRequired => 'Trip id is required';

  @override
  String get backendNetworkError =>
      'Network error. Please check your connection.';

  @override
  String get backendServerError => 'Server error. Please try again later.';

  @override
  String get backendTimeoutError => 'Request timed out. Please try again.';

  @override
  String get backendUnknownError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get backendUnauthorizedError => 'Unauthorized. Please log in again.';

  @override
  String get backendForbiddenError =>
      'You don\'t have permission to perform this action.';

  @override
  String get backendNotFoundError => 'The requested resource was not found.';

  @override
  String get backendConflictError =>
      'This action conflicts with existing data.';

  @override
  String get permissionLocationDenied =>
      'Location permission denied. Enable it in app settings.';

  @override
  String get permissionLocationPermanentlyDenied =>
      'Location permission permanently denied. Enable it in app settings.';

  @override
  String get permissionCameraDenied =>
      'Camera permission denied. Enable it in app settings.';

  @override
  String get permissionCameraPermanentlyDenied =>
      'Camera permission permanently denied. Enable it in app settings.';

  @override
  String get permissionStorageDenied =>
      'Storage permission denied. Enable it in app settings.';

  @override
  String get permissionStoragePermanentlyDenied =>
      'Storage permission permanently denied. Enable it in app settings.';

  @override
  String get permissionNotificationsDenied =>
      'Notification permission denied. Enable it in app settings.';

  @override
  String get marketplaceLoadValue => 'LOAD VALUE';

  @override
  String get marketplaceEstProfit => 'EST. PROFIT';

  @override
  String get marketplaceEstLoss => 'EST. LOSS';

  @override
  String get chatNewMessage => 'New message';

  @override
  String get chatToday => 'Today';

  @override
  String get chatYesterday => 'Yesterday';

  @override
  String get truckerFleetReturnToVerificationTitle => 'Return to verification';

  @override
  String get truckerFleetReturnToVerificationMessage =>
      'Add or update your truck, then return to verification to continue.';

  @override
  String get truckerFleetBackToVerificationAction => 'Back to verification';

  @override
  String get truckerFleetTruckSavedReturnMessage =>
      'Truck saved. Return to verification to continue.';

  @override
  String get truckerLoadDetailProfileLoadingMessage =>
      'Checking your profile. Please wait...';

  @override
  String get supplierLoadDetailNotFoundTitle => 'Load not found';

  @override
  String get supplierLoadDetailNotFoundSubtitle =>
      'This load detail is not available right now. Return to My Loads and try again.';

  @override
  String get supplierLoadDetailLoadFailureTitle => 'Unable to load load detail';

  @override
  String get supplierLoadDetailFailureMessage =>
      'Could not load this load detail. Please try again.';

  @override
  String get supplierLoadDetailScreenTitle => 'Load detail';

  @override
  String supplierLoadDetailHeroSubtitle(Object pickupDate) {
    return 'Pickup: $pickupDate';
  }

  @override
  String get supplierLoadDetailLinkedExecutionUnavailableTitle =>
      'Linked execution data unavailable';

  @override
  String get supplierLoadSupportFailureMessage =>
      'Could not refresh bookings or trips right now. Please retry.';

  @override
  String get supplierLoadDetailStatusAndActionsTitle => 'Status and actions';

  @override
  String supplierLoadDetailCurrentStatus(Object status) {
    return 'Current status: $status';
  }

  @override
  String get supplierLoadDetailActionsSubtitle =>
      'Use these actions only after checking the latest status.';

  @override
  String get supplierLoadDetailActionUnavailableTitle => 'Action unavailable';

  @override
  String get supplierLoadActionFailureMessage =>
      'We could not complete that load action right now. Please try again.';

  @override
  String get supplierLoadDetailCancelAction => 'Cancel load';

  @override
  String get supplierLoadDetailCancelledSuccess =>
      'Load cancelled successfully';

  @override
  String get supplierLoadCancelFailureMessage =>
      'Could not cancel this load right now. Please try again.';

  @override
  String get supplierLoadDetailCloseFilledOutsideAction =>
      'Close as filled outside app';

  @override
  String get supplierLoadDetailClosedFilledOutsideSuccess =>
      'Load marked as filled outside the app';

  @override
  String get supplierLoadCloseFailureMessage =>
      'Could not close this load right now. Please try again.';

  @override
  String supplierLoadDetailOriginCity(Object value) {
    return 'Origin city: $value';
  }

  @override
  String supplierLoadDetailOriginPoint(Object value) {
    return 'Origin point: $value';
  }

  @override
  String supplierLoadDetailDestinationCity(Object value) {
    return 'Destination city: $value';
  }

  @override
  String supplierLoadDetailDestinationPoint(Object value) {
    return 'Destination point: $value';
  }

  @override
  String supplierLoadDetailPickupDate(Object value) {
    return 'Pickup date: $value';
  }

  @override
  String supplierLoadDetailDistance(Object value) {
    return 'Distance: $value';
  }

  @override
  String supplierLoadDetailDriveTime(Object value) {
    return 'Drive time: $value';
  }

  @override
  String get supplierLoadDetailRoutePreviewUnavailableTitle =>
      'Route preview unavailable';

  @override
  String get supplierLoadDetailRoutePreviewUnavailableMessage =>
      'Route preview details are unavailable for this load right now.';

  @override
  String get supplierLoadDetailCargoAndRequirementsTitle =>
      'Cargo and requirements';

  @override
  String supplierLoadDetailMaterial(Object value) {
    return 'Material: $value';
  }

  @override
  String supplierLoadDetailWeight(Object value) {
    return 'Weight: $value';
  }

  @override
  String supplierLoadDetailBodyType(Object value) {
    return 'Body type: $value';
  }

  @override
  String supplierLoadDetailTyres(Object value) {
    return 'Tyres: $value';
  }

  @override
  String get supplierLoadDetailBookingAndTripLinkageTitle =>
      'Booking and trip linkage';

  @override
  String get supplierLoadDetailBookingLinkageEmptyDescription =>
      'No booking requests or linked trips are available on this load yet.';

  @override
  String get supplierLoadDetailBookingLinkageDescription =>
      'See booking requests and linked trips together.';

  @override
  String get supplierLoadDetailNoBookingRequestsTitle =>
      'No booking requests yet';

  @override
  String get supplierLoadDetailNoBookingRequestsSubtitle =>
      'Booking requests will appear here once truckers respond to this load.';

  @override
  String get supplierLoadDetailLinkedTripsTitle => 'Linked trips';

  @override
  String get supplierLoadDetailNoLinkedTripsTitle => 'No linked trips yet';

  @override
  String get supplierLoadDetailNoLinkedTripsSubtitle =>
      'Trips will appear here after you approve a booking.';

  @override
  String get supplierLoadDetailActivityTimelineTitle => 'Activity timeline';

  @override
  String get supplierLoadDetailTimelineCreatedTitle => 'Load created';

  @override
  String get supplierLoadDetailTimelineCreatedDescription =>
      'This load was created.';

  @override
  String get supplierLoadDetailTimelinePublishedTitle => 'Load published';

  @override
  String get supplierLoadDetailTimelinePublishedDescription =>
      'This load is published and visible to truckers.';

  @override
  String get supplierLoadDetailTimelineUpdatedTitle => 'Status updated';

  @override
  String supplierLoadDetailTimelineUpdatedDescription(Object status) {
    return 'Current status: $status.';
  }

  @override
  String get supplierBookingVerifiedLabel => 'Verified';

  @override
  String supplierBookingRatingLabel(Object rating) {
    return 'Rating: $rating';
  }

  @override
  String supplierBookingTyres(Object tyres) {
    return '$tyres tyres';
  }

  @override
  String supplierBookingSubmittedAt(Object truckLabel, Object submittedAt) {
    return '$truckLabel - Submitted $submittedAt';
  }

  @override
  String supplierBookingDecisionRecorded(Object decidedAt) {
    return 'Decision recorded $decidedAt';
  }

  @override
  String supplierLinkedTripSubtitle(
    Object material,
    Object truckerId,
    Object truckId,
  ) {
    return '$material - Trucker $truckerId - Truck $truckId';
  }

  @override
  String get supplierBookingApprovedSuccessMessage =>
      'Booking approved successfully';

  @override
  String get supplierLoadApproveBookingFailureMessage =>
      'Could not approve this booking right now. Please try again.';

  @override
  String get supplierBookingRejectedSuccessMessage =>
      'Booking rejected successfully';

  @override
  String get supplierLoadRejectBookingFailureMessage =>
      'Could not reject this booking right now. Please try again.';

  @override
  String get supplierBookingApproveDialogTitle => 'Approve booking';

  @override
  String supplierBookingApproveDialogMessage(
    Object material,
    Object origin,
    Object destination,
  ) {
    return 'Approve booking for $material from $origin to $destination?';
  }

  @override
  String get supplierBookingRejectDialogTitle => 'Reject booking';

  @override
  String get supplierBookingRejectDialogSubtitle =>
      'Add a short reason before rejecting this booking.';

  @override
  String get supplierBookingRejectReasonLabel => 'Reason';

  @override
  String get supplierBookingRejectReasonHint =>
      'Example: vehicle mismatch or route timing issue';

  @override
  String get verificationFieldBusinessLicenceNumber =>
      'Business licence number';

  @override
  String get verificationFieldGstOptional => 'Optional';

  @override
  String get verificationSavePacketAction => 'Save details';

  @override
  String get verificationSaveSuccessMessage => 'Verification details saved';

  @override
  String get verificationSaveFailureMessage =>
      'Could not save verification details';

  @override
  String get verificationLockedVerifiedGuidance =>
      'Your verification is already approved, so these fields are locked.';

  @override
  String get verificationLockedPendingGuidance =>
      'Your verification is under review, so these fields are locked until a decision is made.';

  @override
  String get verificationUnlockedSupplierGuidance =>
      'Enter your business and identity details, then upload the required documents.';

  @override
  String get verificationUnlockedTruckerGuidance =>
      'Enter your identity details and keep at least one truck ready for verification.';

  @override
  String get verificationBlockedAlreadyComplete =>
      'Verification is already complete.';

  @override
  String get verificationBlockedUnderReview =>
      'Your verification is already under review.';

  @override
  String get verificationBlockedMissingIdentity =>
      'Add your Aadhaar and PAN numbers first.';

  @override
  String get verificationBlockedMissingCompanyName =>
      'Enter your company name first.';

  @override
  String get verificationBlockedMissingBusinessNumbers =>
      'Enter your business licence details first.';

  @override
  String verificationBlockedMissingDocument(Object documentType) {
    return 'Upload $documentType to continue.';
  }

  @override
  String get verificationBlockedMissingLocation =>
      'Add your verification location first.';

  @override
  String get verificationBlockedMissingTruck =>
      'Add at least one truck before submitting verification.';

  @override
  String verificationReadyTruckCount(Object count) {
    return 'Verification-ready trucks: $count';
  }

  @override
  String get appBarLanguageToggleTooltip => 'Switch language';

  @override
  String get connectivityOfflineBanner =>
      'You are offline. Features may be limited.';

  @override
  String get connectivityOfflineActionsMessage =>
      'You are offline. Actions that need network access should stay disabled.';

  @override
  String get onboardingGateTimeoutMessage =>
      'Loading is taking longer than expected.';

  @override
  String authPasswordResetSentSuccess(Object email) {
    return 'Password reset link sent to $email. Check your inbox.';
  }

  @override
  String get authPasswordResetSentFailure =>
      'Unable to send reset link. Please try again.';

  @override
  String get chatPreviewLocation => 'Location shared';

  @override
  String get chatPreviewDocument => 'Document shared';

  @override
  String get chatPreviewMapCard => 'Route card shared';

  @override
  String get chatPreviewTruckCard => 'Truck details shared';

  @override
  String reportSourceSupplierLoad(Object routeLabel) {
    return 'Supplier load - $routeLabel';
  }

  @override
  String truckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count truck$_temp0';
  }

  @override
  String get authRecommendedChip => 'RECOMMENDED';

  @override
  String get authFastestMostSecure => 'Fastest · Most secure';

  @override
  String get authOneTapNoPasswordSecure => 'One-tap · No password · Secure';

  @override
  String get commonMuteVoice => 'Mute voice';

  @override
  String get commonTurnVoiceOn => 'Turn voice on';

  @override
  String get commonSuggestionSourceGooglePlaces => 'Google Places';

  @override
  String get commonSuggestionSourceOffline => 'Offline database';

  @override
  String get truckerLoadDetailCostTileDieselLabel => 'DIESEL';

  @override
  String get truckerLoadDetailCostTileTollLabel => 'TOLL (₹11/km)';

  @override
  String get truckerLoadDetailCostTileDriverLabel => 'DRIVER (₹5/km)';

  @override
  String get truckerLoadDetailCostTileMiscLabel => 'MISC (₹2/km)';

  @override
  String get truckerLoadDetailCostTileDisclaimer =>
      'Estimates assume ₹11/km toll, ₹5/km driver, ₹2/km misc. Actual costs vary.';

  @override
  String get truckerLoadDetailEarningsEstimateTitle => 'TRIP EARNINGS ESTIMATE';

  @override
  String get truckerLoadDetailTotalFareLabel => 'TOTAL FARE (LOAD VALUE)';

  @override
  String get truckerLoadDetailTotalExpenseLabel => 'TOTAL EXPENSE';

  @override
  String get truckerLoadDetailEstimatedNetProfitLabel => 'ESTIMATED NET PROFIT';

  @override
  String get truckerLoadDetailEstimatedNetLossLabel => 'ESTIMATED NET LOSS';

  @override
  String get truckerLoadDetailNetProfitSubtitle =>
      'After all expenses deducted from total fare';

  @override
  String get truckerLoadDetailNetLossSubtitle => 'Expenses exceed total fare';

  @override
  String get truckerLoadDetailCostBreakdownLabel => 'COST BREAKDOWN';

  @override
  String get trustScoreTitle => 'Trust & Reviews';

  @override
  String get trustScoreOutOfFive => 'out of 5';

  @override
  String get trustScoreReviews => 'reviews';

  @override
  String get trustScoreNoRatingYet => 'No rating yet';

  @override
  String get trustScoreReviewsReceived => 'Reviews received';

  @override
  String get trustScoreTripsCompleted => 'Trips completed';

  @override
  String get trustScoreLoadsPosted => 'Loads posted';

  @override
  String get trustScoreTrucksInFleet => 'Trucks in fleet';

  @override
  String get trustScoreSuperLoadEligible => 'Super Load eligible';

  @override
  String get loadHistoryFailedToLoad => 'Failed to load history';

  @override
  String get loadHistoryNoLoads => 'No loads to display';

  @override
  String loadHistoryStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'Active',
      'completed': 'Completed',
      'assigned_partial': 'Partial',
      'assigned_full': 'Assigned',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get reviewsTitle => 'Reviews & Comments';

  @override
  String get reviewsAverage => 'average';

  @override
  String get reviewsTotal => 'total';

  @override
  String get reviewsUnableToLoad => 'Unable to load reviews';

  @override
  String get reviewsRetryMessage => 'Please retry to load the latest reviews.';

  @override
  String get reviewsNoReviewsYet => 'No reviews yet';

  @override
  String get reviewsWillAppearHere =>
      'Reviews will appear here after interactions';

  @override
  String get reviewsLoadMore => 'Load More Reviews';

  @override
  String get replyDialogTitle => 'Reply to Review';

  @override
  String get replyDialogDescription =>
      'You can reply to this review once. Your response will be visible to everyone who views your profile.';

  @override
  String replyDialogHint(String name) {
    return 'Write your reply to $name...';
  }

  @override
  String get replyDialogSubmit => 'Submit Reply';

  @override
  String get reviewPromptTitle => 'Rate Your Interaction';

  @override
  String reviewPromptSubtitle(String name) {
    return 'How was your experience with $name?';
  }

  @override
  String get reviewPromptCommentHint => 'Add a comment (optional)...';

  @override
  String get reviewPromptSubmit => 'Submit Review';

  @override
  String get reviewPromptSkip => 'Skip';

  @override
  String get reviewPromptSuccessTitle => 'Review Submitted!';

  @override
  String get reviewPromptSuccessMessage =>
      'Thank you for sharing your experience.';

  @override
  String get reviewPromptDone => 'Done';

  @override
  String get publicProfileScreenTitle => 'Profile';

  @override
  String get truckerProfileTitle => 'Trucker Profile';

  @override
  String get supplierProfileTitle => 'Supplier Profile';

  @override
  String get raiseDisputeDiscardTitle => 'Discard Dispute?';

  @override
  String get raiseDisputeDiscardMessage =>
      'You have unsaved dispute details. Do you want to discard them?';

  @override
  String get postLoadDiscardTitle => 'Discard Changes?';

  @override
  String get postLoadDiscardMessage =>
      'You have unsaved load details. Do you want to discard them?';

  @override
  String get ttsHindiVoice => 'Hindi Voice';

  @override
  String get ttsEnglishVoice => 'English Voice';

  @override
  String get ttsNoHindiVoices => 'No Hindi voices available on this device.';

  @override
  String get ttsNoEnglishVoices =>
      'No English voices available on this device.';

  @override
  String get supplierRatingAlreadySubmitting =>
      'Your rating is already being submitted';

  @override
  String get supplierTripActionAlreadyInProgress =>
      'Another supplier trip action is already in progress';

  @override
  String get truckerRatingAlreadySubmitting =>
      'Your rating is already being submitted';

  @override
  String get truckerTripActionAlreadyInProgress =>
      'Another trip action is already in progress';

  @override
  String get truckerTripCannotAdvanceFromCurrentStage =>
      'This trip can no longer be advanced from its current stage';

  @override
  String get truckerTripPodUploadOnlyAfterDelivery =>
      'POD can only be uploaded after the load has been delivered';

  @override
  String get truckerTripLrUploadOnlyDuringPickup =>
      'LR can only be uploaded during pickup stages';

  @override
  String get truckerLoadDetailUnavailable => 'Load detail is unavailable';

  @override
  String get truckerBookingAlreadyInProgress =>
      'Booking request is already in progress';

  @override
  String get truckerTruckRequired => 'Select a truck to continue';

  @override
  String get truckerTruckSaveAlreadyInProgress =>
      'Truck save is already in progress';

  @override
  String get truckerTruckValidationFailed =>
      'Please correct the highlighted truck details';

  @override
  String get truckerTruckNotFound => 'The selected truck was not found';

  @override
  String get chatVoiceConversationIdRequired => 'Conversation id is required';

  @override
  String get chatVoiceRecordingAlreadyInProgress =>
      'A voice recording is already in progress';

  @override
  String get chatVoiceMicrophonePermissionRequired =>
      'Microphone permission is required to record a voice message';

  @override
  String get chatVoiceNoActiveRecording =>
      'No active voice recording is available for this conversation';

  @override
  String get chatMessageAlreadyBeingSent =>
      'Another message is already being sent';

  @override
  String get notificationNotificationIdRequired =>
      'Notification id is required';

  @override
  String get profileUserIdRequired => 'User ID is required';

  @override
  String get reviewValidationFailed => 'Please correct the review details';

  @override
  String get reviewSubmitFailed => 'Failed to submit review';

  @override
  String get reviewAddReplyFailed =>
      'Failed to add reply. You may have already replied or are not the reviewed user';

  @override
  String get verificationDetailUnavailable =>
      'Verification detail is unavailable';

  @override
  String get verificationActionAlreadyInProgress =>
      'Another verification action is already in progress';

  @override
  String get verificationLocationCaptureOnlySupplier =>
      'Verification location capture is only available for supplier verification';

  @override
  String get verificationLocationCaptureFailed =>
      'Unable to capture your verification location right now. Check location services and try again';

  @override
  String get verificationCityRequired => 'Verification city is required';

  @override
  String get verificationSubmissionBlocked =>
      'Verification submission is blocked';
}
