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
  String get splashTagline => 'Trusted load movement across India.';

  @override
  String get splashFirstOpenGreeting => 'Welcome to TranZfort.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsScreenTtsContext =>
      'Settings screen. Manage language, voice guidance, notifications, and account options.';

  @override
  String get appBarTtsMutedSnack => 'Voice guidance muted';

  @override
  String get appBarTtsEnabledSnack => 'Voice guidance enabled';

  @override
  String get appBarLanguageChangedHindi => 'Language changed: Hindi';

  @override
  String get appBarLanguageChangedEnglish => 'Language changed: English';

  @override
  String appBarTtsTooltipMute(Object screen) {
    return 'Mute voice guidance ($screen)';
  }

  @override
  String get appBarTtsTooltipEnable => 'Enable voice guidance';

  @override
  String get appBarLanguageToggleTooltip => 'Toggle language';

  @override
  String get appBarNotificationsTooltip => 'Notifications';

  @override
  String get appDrawerProfileTitle => 'Profile';

  @override
  String get appDrawerSupplierWorkspace => 'Supplier workspace';

  @override
  String get appDrawerTruckerWorkspace => 'Trucker workspace';

  @override
  String get appDrawerHome => 'Home';

  @override
  String get appDrawerDashboard => 'Dashboard';

  @override
  String get appDrawerVerification => 'Verification';

  @override
  String get appDrawerBotChat => 'Bot Chat';

  @override
  String get dashboardVerificationStatusVerified => 'Verification complete';

  @override
  String get dashboardVerificationStatusPending => 'Verification under review';

  @override
  String get dashboardVerificationStatusUnverified =>
      'Verification not started';

  @override
  String get dashboardVerificationStatusRejected =>
      'Verification needs updates';

  @override
  String get dashboardVerificationStatusUnknown =>
      'Verification status unavailable';

  @override
  String dashboardVerificationRejectedReason(Object reason) {
    return 'Update needed: $reason';
  }

  @override
  String get sharedLoadingSuffix => 'loading';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'Hindi';

  @override
  String get postLoadTitle => 'Post Load';

  @override
  String get loadDetailTitle => 'Load Detail';

  @override
  String get viewRouteMap => 'View Route Map';

  @override
  String get actionsTitle => 'Actions';

  @override
  String get loadNotFound => 'Load not found';

  @override
  String get couldNotStartChatRetry => 'Could not start chat. Please retry.';

  @override
  String get verifyAction => 'Verify';

  @override
  String get completeTruckerVerificationToChat =>
      'Complete trucker verification to start chat with suppliers.';

  @override
  String get createLoadQuickSteps => 'Create a load in 4 quick steps';

  @override
  String get createLoadSubtitle =>
      'Add route, cargo, truck requirement and pricing details.';

  @override
  String get postLoadSuperLoadReadinessTitle => 'Super Load readiness';

  @override
  String get postLoadSuperLoadReadinessSubtitle =>
      'Super Load support requires supplier verification and a ready payout profile.';

  @override
  String get loadPostedSuccess => 'Load posted successfully';

  @override
  String get loadPostFailure => 'Failed to post load. Please try again.';

  @override
  String get postLoadSubmitAction => 'Post Load';

  @override
  String get nextAction => 'Next';

  @override
  String get backAction => 'Back';

  @override
  String get postLoadStepRouteTitle => 'Route';

  @override
  String get postLoadStepCargoTitle => 'Cargo';

  @override
  String get postLoadStepVehicleTitle => 'Vehicle';

  @override
  String get postLoadStepPriceScaleTitle => 'Price & Scale';

  @override
  String postLoadStepSummary(Object current, Object total, Object label) {
    return 'Step $current of $total — $label';
  }

  @override
  String get postLoadOriginCityLabel => 'Origin City';

  @override
  String get postLoadDestinationCityLabel => 'Destination City';

  @override
  String postLoadApproxRouteInfo(Object km, Object hours) {
    return 'Approx route: $km km · ${hours}h';
  }

  @override
  String get postLoadDistanceUnavailableFallback =>
      'Distance unavailable (offline fallback in use)';

  @override
  String get postLoadMaterialLabel => 'Material';

  @override
  String get postLoadWeightPerTruckLabel => 'Weight per Truck (Tonnes)';

  @override
  String get postLoadTruckBodyTypeLabel => 'Truck Body Type';

  @override
  String get postLoadTruckTypeAny => 'Any';

  @override
  String get postLoadTruckTypeOpen => 'Open';

  @override
  String get postLoadTruckTypeContainer => 'Container';

  @override
  String get postLoadTruckTypeTrailer => 'Trailer';

  @override
  String get postLoadTruckTypeTanker => 'Tanker';

  @override
  String get postLoadTruckTypeRefrigerated => 'Refrigerated';

  @override
  String get postLoadPriceTotalLabel => 'Total Price (₹)';

  @override
  String get postLoadPriceTypeFixed => 'Fixed';

  @override
  String get postLoadPriceTypeNegotiable => 'Per ton';

  @override
  String postLoadAdvanceLabel(int percentage) {
    return 'Advance: $percentage%';
  }

  @override
  String get postLoadPickupDateLabel => 'Pickup Date';

  @override
  String get postLoadChangeAction => 'Change';

  @override
  String get postLoadTrucksNeededLabel => 'How many trucks needed?';

  @override
  String get findLoadsTitle => 'Find Loads';

  @override
  String get searchLoads => 'Search Loads';

  @override
  String get resetAction => 'Reset';

  @override
  String get editAction => 'Edit';

  @override
  String get loadsFound => 'loads found';

  @override
  String get mapViewComingSoonTitle => 'Map view is coming soon';

  @override
  String get mapViewComingSoonSubtitle =>
      'Switch back to list view to continue booking available loads.';

  @override
  String get noLoadsFoundTitle => 'No loads found';

  @override
  String get noLoadsFoundSubtitle =>
      'Try changing your filters or check back later.';

  @override
  String get myLoadsTitle => 'My Loads';

  @override
  String get myLoadsDashboardTts => 'My loads dashboard';

  @override
  String get myLoadsScreenTtsContext =>
      'My loads dashboard. Review active and completed loads, booking activity, and fulfillment progress.';

  @override
  String myLoadsScreenTtsContextDetailed(int active, int inTransit) {
    return 'Your loads dashboard. $active active loads, $inTransit in transit.';
  }

  @override
  String get supplierOverview => 'Supplier overview';

  @override
  String get myLoadsOverviewSubtitle =>
      'Track active loads, bookings, and fulfillment progress.';

  @override
  String get myLoadsActiveLabel => 'Active loads';

  @override
  String get myLoadsInTransitLabel => 'In transit';

  @override
  String myLoadsRequiresActionBanner(int count) {
    return '$count load(s) need your action.';
  }

  @override
  String get activeTab => 'Active';

  @override
  String get completedTab => 'Completed';

  @override
  String get postLoadAction => 'Post Load';

  @override
  String get noCompletedLoads => 'No completed loads';

  @override
  String get noActiveLoads => 'No active loads';

  @override
  String get completedLoadsHere => 'Completed/cancelled loads will show here.';

  @override
  String get postFirstLoadPrompt =>
      'Post your first load to start getting bookings.';

  @override
  String get loadDeactivated => 'Load deactivated';

  @override
  String get couldNotDeactivateLoad => 'Could not deactivate load';

  @override
  String get deactivateAction => 'Deactivate';

  @override
  String myLoadsTrucksBookedSummary(int booked, int needed) {
    return '$booked/$needed trucks booked';
  }

  @override
  String get myLoadsLoadErrorPrefix => 'Could not load your loads';

  @override
  String get myLoadsStatusCompleted => 'Completed';

  @override
  String get myLoadsStatusCancelled => 'Cancelled';

  @override
  String get myLoadsStatusWaiting => 'Waiting';

  @override
  String get myLoadsStatusFullyBooked => 'Fully booked';

  @override
  String get myLoadsStatusFulfilling => 'Fulfilling';

  @override
  String get loadBookedAwaitingApproval =>
      'Load booked! Waiting for supplier approval.';

  @override
  String get bookingFailedTryAgain => 'Booking failed. Please try again.';

  @override
  String get loadBookTtsSuccess =>
      'Booking request sent. Awaiting supplier approval.';

  @override
  String get loadBookTtsFailure => 'Booking failed. Please try again.';

  @override
  String get authTtsPromptGoogleOrPhone =>
      'Continue with Google or phone number.';

  @override
  String get authErrorNetwork => 'Please check your internet connection.';

  @override
  String get authErrorAuthFailed => 'Authentication failed. Please try again.';

  @override
  String get authErrorConflict =>
      'This account is already registered. Try signing in.';

  @override
  String get authErrorValidation => 'Please review the entered details.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authOneFinalStep => 'One final step';

  @override
  String get authWelcomeTitle => 'Welcome to TranZfort';

  @override
  String get authGoogleDoneAddMobile =>
      'Google sign-in done. Add your mobile number to continue.';

  @override
  String get authWelcomeSubtitle =>
      'India\'s trusted load matching platform for suppliers and truckers.';

  @override
  String get authContinueJourney => 'Continue your journey';

  @override
  String get authChooseSignInMethod => 'Choose your preferred sign-in method.';

  @override
  String get authOr => 'OR';

  @override
  String get authContinueWithPhone => 'Continue with Phone';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authTermsAgreement =>
      'By continuing, you agree to our Terms of Service and Privacy Policy.';

  @override
  String get phoneInvalidNumber => 'Please enter a valid phone number';

  @override
  String get phoneSaveErrorAuth =>
      'Could not save mobile number. Please try again.';

  @override
  String get phoneSaveErrorConflict =>
      'This number is already linked to another account. Try a different number.';

  @override
  String get phoneSaveErrorValidation => 'Please enter a valid mobile number.';

  @override
  String get phoneEnterMobileTitle => 'Enter your mobile number';

  @override
  String get phoneEnterMobileSubtitle =>
      'Add your number to continue. OTP verification is deferred for now.';

  @override
  String get phoneVerificationSetup => 'Mobile verification setup';

  @override
  String get phoneVerificationSetupSubtitle =>
      'Use your active number to receive booking and trip alerts.';

  @override
  String get phoneLabelMobileNumber => 'Mobile Number';

  @override
  String get commonContinue => 'Continue';

  @override
  String get otpTtsPrompt => 'Enter the 6-digit OTP sent to your phone.';

  @override
  String get otpVerificationDeferredMessage =>
      'OTP verification is deferred for now. Please continue with mobile capture flow.';

  @override
  String get otpVerificationDeferredTitle =>
      'OTP verification is currently deferred';

  @override
  String get otpVerificationDeferredSubtitle =>
      'Use mobile capture flow to continue onboarding.';

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpResendDeferred => 'OTP resend is deferred for now.';

  @override
  String get otpResendCode => 'Resend Code';

  @override
  String get roleTtsPrompt => 'Are you a supplier or trucker? Please choose.';

  @override
  String get roleErrorAuth => 'Your session expired. Please sign in again.';

  @override
  String get roleErrorConflict => 'Role setup was already completed.';

  @override
  String get roleErrorValidation => 'Please choose a valid role.';

  @override
  String get roleErrorGeneric => 'Could not save role. Please try again.';

  @override
  String get roleTitle => 'How will you use TranZfort?';

  @override
  String get roleSubtitle =>
      'Select your role to personalize your dashboard and actions.';

  @override
  String get roleSupplierTitle => 'I am a Supplier / Consignor';

  @override
  String get roleSupplierSubtitle => 'I want to post loads and find trucks';

  @override
  String get roleTruckerTitle => 'I am a Trucker / Transporter';

  @override
  String get roleTruckerSubtitle => 'I want to find loads and manage my fleet';

  @override
  String get roleCompleteSetup => 'Complete Setup';

  @override
  String get myTripsTitle => 'My Trips';

  @override
  String get myTripsDashboardTts => 'My trips dashboard';

  @override
  String get myTripsScreenTtsContext =>
      'My trips dashboard. Track current trips, completed deliveries, and stage updates.';

  @override
  String myTripsScreenTtsContextDetailed(
    int active,
    Object origin,
    Object destination,
  ) {
    return 'Your trips. $active active. Current trip: $origin to $destination.';
  }

  @override
  String get truckerOverview => 'Trucker overview';

  @override
  String get truckerDashboardActiveBidsLabel => 'Active bids';

  @override
  String get truckerDashboardUpcomingTripsLabel => 'Upcoming trips';

  @override
  String get truckerDashboardPendingBidsTitle => 'Pending bids';

  @override
  String get truckerDashboardUpcomingActiveTripsTitle =>
      'Upcoming & active trips';

  @override
  String get tripOverviewSubtitle =>
      'Stay on top of active trips and stage progress.';

  @override
  String get activeTripStatus => 'Active Trip Status';

  @override
  String get tripMilestonesSubtitle =>
      'See the next stage and keep documents ready.';

  @override
  String get noCompletedTrips => 'No completed trips';

  @override
  String get noActiveTrips => 'No active trips';

  @override
  String get completedTripsHere => 'Completed trips will appear here.';

  @override
  String get bookLoadPrompt =>
      'Book a load from Find Loads to start your first trip.';

  @override
  String get findLoadsAction => 'Find Loads';

  @override
  String get tripsLoadError => 'Could not load trips. Please try again.';

  @override
  String get tripRecentlyUpdated => 'Recently updated';

  @override
  String get tripCompletedPrefix => 'Completed';

  @override
  String get tripStartedPrefix => 'Started';

  @override
  String get tripApprovedPrefix => 'Approved';

  @override
  String get tripDeliveredPrefix => 'Delivered';

  @override
  String get tripPodUploadedPrefix => 'POD uploaded';

  @override
  String get tripUpdatedPrefix => 'Updated';

  @override
  String get tripStageCompleted => 'Completed';

  @override
  String get tripStageInTransit => 'In Transit';

  @override
  String get tripStageAtPickup => 'At Pickup';

  @override
  String get tripStageDelivered => 'Delivered';

  @override
  String get tripStagePodUploaded => 'POD Uploaded';

  @override
  String get tripStageUnknown => 'Unknown';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get chatInboxTts => 'Messages inbox';

  @override
  String get chatInboxScreenTtsContext =>
      'Messages inbox. Open conversations with suppliers and truckers and track recent updates.';

  @override
  String chatInboxScreenTtsContextCount(int count) {
    return 'Your messages. $count conversations.';
  }

  @override
  String get chatNoMessagesTitle => 'No messages yet';

  @override
  String get chatSupplierInboxSubtitle =>
      'Start a chat by engaging with a load.';

  @override
  String get chatTruckerInboxSubtitle => 'Start a chat by booking a load.';

  @override
  String get chatTapToOpenConversation => 'Tap to open conversation';

  @override
  String get chatTapToViewConversation => 'Tap to view conversation';

  @override
  String get chatConversationsSuffix => 'trucker conversation(s)';

  @override
  String get chatFailedLoadMessages => 'Failed to load messages';

  @override
  String get chatTruckerFallbackName => 'Trucker';

  @override
  String get chatSupplierFallbackName => 'Supplier';

  @override
  String get chatOpenConversationPrefix => 'Open conversation';

  @override
  String get tripDetailTitle => 'Trip Detail';

  @override
  String get tripNotFound => 'Trip not found';

  @override
  String get tripSnapshotTitle => 'Trip Snapshot';

  @override
  String get tripSnapshotTruck => 'Truck';

  @override
  String get tripSnapshotWeight => 'Weight';

  @override
  String get tripSnapshotDistance => 'Distance';

  @override
  String get tripSnapshotPrice => 'Price';

  @override
  String get tripPickupActions => 'Pickup actions';

  @override
  String get tripTransitAction => 'Transit action';

  @override
  String get tripDeliveryProof => 'Delivery proof';

  @override
  String get tripLoadError => 'Could not load trip details. Please try again.';

  @override
  String get tripPodUploaded => 'POD uploaded';

  @override
  String get tripPodUploadedWaiting =>
      'Waiting for supplier to confirm delivery.';

  @override
  String get tripTimelinePickup => 'Pickup';

  @override
  String get tripTimelineTransit => 'Transit';

  @override
  String get tripTimelineDelivered => 'Delivered';

  @override
  String get tripTimelinePodUploaded => 'POD Uploaded';

  @override
  String get tripTimelineCompleted => 'Completed';

  @override
  String get tripRouteToolsTitle => 'Route tools';

  @override
  String get tripViewRoutePreviewAction => 'View Route Preview';

  @override
  String get tripOpenNavigationAction => 'Open Navigation';

  @override
  String get tripNavigateToPickupAction => 'Navigate to Pickup';

  @override
  String get tripNavigateToDestinationAction => 'Navigate to Destination';

  @override
  String get tripNavigationUnavailable =>
      'Destination coordinates are unavailable for navigation.';

  @override
  String get tripLocationCaptured => 'Location captured.';

  @override
  String tripLocationCapturedAt(Object location) {
    return 'Location captured at $location.';
  }

  @override
  String get tripYourRatingPrefix => 'Your rating';

  @override
  String get tripRateThisPrefix => 'Rate this';

  @override
  String get tripCommentOptional => 'Comment (optional)';

  @override
  String get tripSubmitRating => 'Submit Rating';

  @override
  String get tripRatingSubmitted => 'Rating submitted.';

  @override
  String get tripRatingSubmitError =>
      'Could not submit rating. Please try again.';

  @override
  String get tripStartAction => 'Start';

  @override
  String get tripStartDialogTitle => 'Start Trip';

  @override
  String get tripStartDialogMessage =>
      'Confirm you have loaded the cargo and are ready to start?';

  @override
  String get tripCancelAction => 'Cancel';

  @override
  String get tripStartSuccess => 'Trip started successfully.';

  @override
  String get tripStartError => 'Could not start trip. Please try again.';

  @override
  String get tripStartTtsSuccess => 'Trip started successfully.';

  @override
  String get tripStartTtsFailure => 'Trip start failed. Please try again.';

  @override
  String get tripUploadLrOptional => 'Upload LR (Optional)';

  @override
  String get tripLrUploadSuccess => 'LR uploaded successfully.';

  @override
  String get tripLrUploadError => 'Could not upload LR. Please try again.';

  @override
  String get tripMarkDelivered => 'Mark Delivered';

  @override
  String get tripMarkDeliveredDialogTitle => 'Mark Delivered';

  @override
  String get tripMarkDeliveredDialogMessage =>
      'Confirm cargo has been unloaded at destination?';

  @override
  String get tripConfirmAction => 'Confirm';

  @override
  String get tripMarkedDeliveredNextPod =>
      'Marked delivered. Please upload POD next.';

  @override
  String get tripMarkDeliveredError =>
      'Could not mark delivered. Please try again.';

  @override
  String get tripEmergencySosAction => 'Emergency SOS';

  @override
  String get tripEmergencySosPreparing =>
      'Preparing SOS message with your current location...';

  @override
  String get tripEmergencySosLocationUnavailable =>
      'Could not capture your current location for SOS.';

  @override
  String get tripEmergencySosLaunchFailed =>
      'Could not open SMS app for SOS message.';

  @override
  String tripEmergencySosMessage(Object lat, Object lng, Object route) {
    return 'Emergency alert from TranZfort trip. Current location: $lat, $lng. Route: $route. Please assist immediately.';
  }

  @override
  String get tripUploadProofOfDelivery => 'Upload Proof of Delivery';

  @override
  String get tripUploadPodPhoto => 'Upload POD Photo';

  @override
  String get tripPodUploadSuccessWaiting =>
      'POD uploaded. Waiting for supplier confirmation.';

  @override
  String get tripPodUploadError => 'Could not upload POD. Please try again.';

  @override
  String get tripPodUploadTtsSuccess =>
      'Proof of delivery uploaded. Waiting for confirmation.';

  @override
  String get tripPodUploadTtsFailure =>
      'Proof of delivery upload failed. Please try again.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatMicrophonePermissionRequired =>
      'Microphone permission is required';

  @override
  String get chatVoiceRecordingEmpty => 'Voice recording was empty';

  @override
  String get chatCouldNotReadRecordedFile => 'Could not read recorded file';

  @override
  String get chatVoiceMessageSent => 'Voice message sent';

  @override
  String get chatVoiceMessageSendFailed => 'Failed to send voice message';

  @override
  String get chatVoiceFileUnavailable => 'Voice file unavailable';

  @override
  String get chatUnablePlayVoiceMessage => 'Unable to play voice message';

  @override
  String get chatLocationShared => 'Location shared';

  @override
  String get chatCouldNotShareLocation => 'Could not share location';

  @override
  String get chatBookingActionShared => 'Booking action shared';

  @override
  String get chatCouldNotShareBookingAction => 'Could not share booking action';

  @override
  String get chatBookingRequestSentFromChat =>
      'Booking request sent from chat.';

  @override
  String get chatCouldNotBookFromChat => 'Could not book from chat.';

  @override
  String get chatAttachShareLocation => 'Share current location (Map card)';

  @override
  String get chatAttachShareBookingAction => 'Share booking action';

  @override
  String get chatMapCardTitleLocationShared => 'Location shared';

  @override
  String get chatMapCoordinatesUnavailable => 'Coordinates unavailable';

  @override
  String chatMapLatLng(Object lat, Object lng) {
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get chatBookThisLoad => 'Book This Load';

  @override
  String get chatBookingActionDescription =>
      'Tap below to send booking request from this chat.';

  @override
  String get chatFailedSendMessage => 'Failed to send message';

  @override
  String get chatNoMessagesYet => 'No messages yet.';

  @override
  String get chatAttach => 'Attach';

  @override
  String get chatTypeMessageHint => 'Type a message...';

  @override
  String get chatSendMessageTooltip => 'Send message';

  @override
  String get chatStopRecordingTooltip => 'Stop recording';

  @override
  String get chatStartRecordingTooltip => 'Start recording';

  @override
  String get chatVoiceLabel => 'Voice';

  @override
  String get chatPlayAction => 'Play';

  @override
  String get chatStopAction => 'Stop';

  @override
  String get chatOpenMap => 'Open Map';

  @override
  String get verificationSupplierPrompt => 'Complete supplier verification';

  @override
  String get verificationTruckerPrompt => 'Complete trucker verification';

  @override
  String get verificationRequired => 'Verification Required';

  @override
  String get verificationPendingReview => 'Verification Pending Review';

  @override
  String get verificationPendingMessage =>
      'Your account is under review. Load posting is enabled once verification is approved.';

  @override
  String get verificationRequiredMessage =>
      'Complete supplier verification to post loads and access full marketplace actions.';

  @override
  String get completeVerification => 'Complete Verification';

  @override
  String get chatWithSupplier => 'Chat with Supplier';

  @override
  String get callSupplierAction => 'Call Supplier';

  @override
  String get callSupplierUnavailable =>
      'Supplier phone number is unavailable right now.';

  @override
  String get callSupplierLaunchFailed =>
      'Could not open the phone app. Please try again.';

  @override
  String get postedByPrefix => 'Posted by';

  @override
  String get settingsTtsPreviewText => 'Settings screen';

  @override
  String get settingsHeroTitle => 'Personalize your TranZfort workspace';

  @override
  String get settingsHeroSubtitle =>
      'Control language, voice, notifications, and account access in one place.';

  @override
  String get settingsGeneralSection => 'General';

  @override
  String get settingsLanguageSubtitle =>
      'Interface language for app labels and prompts.';

  @override
  String get settingsVoiceNotificationsSection => 'Voice & notifications';

  @override
  String get settingsTtsSpeedLabel => 'Speech speed';

  @override
  String settingsTtsSpeedValue(Object speed) {
    return 'Current speed: ${speed}x';
  }

  @override
  String get settingsTtsLanguageLabel => 'TTS language';

  @override
  String get settingsTtsLanguageAuto => 'Auto (match app language)';

  @override
  String get settingsTtsPreviewAction => 'Preview voice';

  @override
  String get settingsTtsMuteTitle => 'TTS mute';

  @override
  String get settingsTtsMuteSubtitle => 'Mutes all automatic speech';

  @override
  String get settingsPushNotificationsTitle => 'Push notifications';

  @override
  String get settingsPushNotificationsSubtitle =>
      'Keep updates on loads, trips, and verification status.';

  @override
  String get settingsAccountSupportSection => 'Account & support';

  @override
  String get settingsMyProfileTitle => 'My profile';

  @override
  String get settingsMyProfileSubtitle =>
      'View your role details and verification status.';

  @override
  String get settingsPayoutProfileTitle => 'Payout profile';

  @override
  String get settingsPayoutProfileSubtitle =>
      'Manage account and payout details.';

  @override
  String get payoutAccountHolderLabel => 'Account holder';

  @override
  String get payoutAccountLast4Label => 'Account ending';

  @override
  String get payoutIfscLabel => 'IFSC';

  @override
  String get payoutStatusLabel => 'Status';

  @override
  String get payoutNoProfileTitle => 'No payout profile yet';

  @override
  String get payoutNoProfileSubtitle =>
      'Payout details will appear here once your financial profile is available.';

  @override
  String get payoutLoadError => 'Failed to load payout profile.';

  @override
  String get settingsHelpSupportTitle => 'Help & support';

  @override
  String get settingsHelpSupportSubtitle =>
      'Get support for app issues and account guidance.';

  @override
  String get supportScreenTtsContext =>
      'Support screen. Create tickets, track updates, and reply to the support team.';

  @override
  String get supportHeroTitle => 'Get help from the TranZfort support team';

  @override
  String get supportHeroSubtitle =>
      'Create a ticket for booking, trip, verification, account, or payout issues and track replies here.';

  @override
  String get supportCreateTicketTitle => 'Create a support ticket';

  @override
  String get supportCategoryLabel => 'Category';

  @override
  String get supportCategoryTechnicalBug => 'Technical bug';

  @override
  String get supportCategoryBookingIssue => 'Booking issue';

  @override
  String get supportCategoryTripIssue => 'Trip issue';

  @override
  String get supportCategoryPaymentPayout => 'Payment or payout';

  @override
  String get supportCategoryVerification => 'Verification';

  @override
  String get supportCategoryAccountAccess => 'Account access';

  @override
  String get supportCategoryOther => 'Other';

  @override
  String get supportSubjectLabel => 'Subject';

  @override
  String get supportSubjectHint => 'Short summary of the issue';

  @override
  String get supportDescriptionLabel => 'Description';

  @override
  String get supportDescriptionHint =>
      'Describe what happened and what help you need.';

  @override
  String get supportSubmitTicketAction => 'Submit Ticket';

  @override
  String get supportMyTicketsTitle => 'My tickets';

  @override
  String get supportEmptyTitle => 'No support tickets yet';

  @override
  String get supportEmptySubtitle =>
      'Create your first ticket and you can track updates from the support team here.';

  @override
  String get supportLoadError =>
      'Could not load support tickets. Please try again.';

  @override
  String get supportSubjectRequired =>
      'Please enter a subject for your ticket.';

  @override
  String get supportDescriptionRequired =>
      'Please enter a description for your ticket.';

  @override
  String get supportCreateFailed =>
      'Could not submit the support ticket. Please try again.';

  @override
  String get supportTicketSubmitted => 'Support ticket submitted successfully.';

  @override
  String get supportCreatedLabel => 'Created';

  @override
  String get supportResolvedLabel => 'Resolved';

  @override
  String get supportTicketIdLabel => 'Ticket ID';

  @override
  String get supportStatusOpen => 'Open';

  @override
  String get supportStatusInProgress => 'In Progress';

  @override
  String get supportStatusResolved => 'Resolved';

  @override
  String get supportPriorityLow => 'Low';

  @override
  String get supportPriorityMedium => 'Medium';

  @override
  String get supportPriorityHigh => 'High';

  @override
  String get supportPriorityUrgent => 'Urgent';

  @override
  String get supportTicketDetailTitle => 'Support Ticket';

  @override
  String get supportTicketNotFoundTitle => 'Support ticket not found';

  @override
  String get supportTicketNotFoundSubtitle =>
      'This ticket is unavailable or no longer accessible from your account.';

  @override
  String get supportResolutionNotesTitle => 'Resolution notes';

  @override
  String get supportConversationTitle => 'Conversation';

  @override
  String get supportNoMessagesYet =>
      'No replies yet. The support team will respond here.';

  @override
  String get supportReplySectionTitle => 'Send a reply';

  @override
  String get supportTicketResolvedReplyClosed =>
      'This ticket is resolved. Replies are closed for now.';

  @override
  String get supportReplyHint =>
      'Add more details or reply to the support team';

  @override
  String get supportSendReplyAction => 'Send Reply';

  @override
  String get supportResolvedTicketReadOnlyAction => 'Resolved ticket';

  @override
  String get supportReplyRequired => 'Please enter a reply before sending.';

  @override
  String get supportReplyFailed =>
      'Could not send your reply. Please try again.';

  @override
  String get supportReplySent => 'Reply sent successfully.';

  @override
  String get supportYouLabel => 'You';

  @override
  String get supportSupportTeamLabel => 'Support Team';

  @override
  String get settingsSupportPending => 'Support screen pending in Sprint 9';

  @override
  String get settingsAppVersionTitle => 'App version';

  @override
  String get settingsCurrentBuildPrefix => 'Current build';

  @override
  String get settingsDangerZone => 'Danger zone';

  @override
  String get settingsDeleteAccountTitle => 'Delete account permanently';

  @override
  String get settingsDeleteAccountSubtitle =>
      'This marks your account for deletion and signs you out immediately.';

  @override
  String get settingsDeleteAccountAction => 'Delete Account';

  @override
  String get settingsDeleteAccountDialogTitle => 'Delete Account?';

  @override
  String get settingsDeleteAccountDialogContent =>
      'This will permanently delete your account and all data. This cannot be undone.';

  @override
  String get settingsDeleteAction => 'Delete';

  @override
  String get settingsDeleteAccountFailed =>
      'Failed to request account deletion';

  @override
  String get settingsSignOutAction => 'Sign Out';

  @override
  String get verificationSubmitSuccess =>
      'Verification submitted successfully!';

  @override
  String get verificationLoadError =>
      'Could not load verification details. Please try again.';

  @override
  String get retryAction => 'Retry';

  @override
  String get verificationUploadMandatory =>
      'Please upload all mandatory documents.';

  @override
  String get verificationSupplierTitle => 'Supplier Verification';

  @override
  String get verificationTruckerTitle => 'Trucker Verification';

  @override
  String get verificationSupplierSubtitle =>
      'Submit business and identity documents to unlock full marketplace access.';

  @override
  String get verificationTruckerSubtitle =>
      'Upload identity and driving documents to activate trip execution privileges.';

  @override
  String verificationDocumentsUploadedSummary(int uploaded, int total) {
    return '$uploaded of $total documents uploaded';
  }

  @override
  String get verificationChooseImageSourceTitle => 'Choose image source';

  @override
  String get verificationUseCamera => 'Use Camera';

  @override
  String get verificationUseGallery => 'Use Gallery';

  @override
  String get verificationAadhaarHelper =>
      'Enter all 12 digits exactly as on your Aadhaar.';

  @override
  String get verificationPanHelper => 'PAN format: ABCDE1234F';

  @override
  String get verificationPanInvalid => 'Enter a valid PAN (e.g., ABCDE1234F)';

  @override
  String get verificationDlHelper =>
      'Use your driving licence number exactly as printed.';

  @override
  String get verificationTruckRequiredMessage =>
      'Add at least one truck with number, body type, tyres, capacity, and RC photo before verification.';

  @override
  String get verificationVerifiedLockedTitle => 'Verification already approved';

  @override
  String get verificationVerifiedLockedBody =>
      'Your details are locked because your verification is approved. Edit only if you need to resubmit for re-verification.';

  @override
  String get verificationEditAndResubmitAction => 'Edit & Re-submit';

  @override
  String get verificationReverificationNotice =>
      'After updates, your profile will move to pending for re-verification.';

  @override
  String get verificationImageQualityHint =>
      'Make sure the photo is clear, readable, and fully visible.';

  @override
  String get documentAttachedTapReplace => 'Document attached. Tap to replace.';

  @override
  String get documentTapUploadRequired => 'Tap to upload required document';

  @override
  String get retakeAction => 'Retake';

  @override
  String get uploadAction => 'Upload';

  @override
  String get findLoadsVerifiedTruckRequiredTitle => 'Verified truck required';

  @override
  String get findLoadsVerifiedTruckRequiredBody =>
      'You need a verified truck to book loads. Add a truck now?';

  @override
  String get findLoadsNotNow => 'Not now';

  @override
  String get findLoadsAddTruck => 'Add Truck';

  @override
  String get findLoadsAnyMaterial => 'Any material';

  @override
  String get findLoadsSelectedTruck => 'Selected Truck';

  @override
  String get findLoadsConfirmBookingTitle => 'Confirm Booking';

  @override
  String get findLoadsBookConfirmPrefix => 'Book';

  @override
  String get findLoadsBookConfirmFrom => 'load from';

  @override
  String get findLoadsBookConfirmTo => 'to';

  @override
  String get findLoadsBookConfirmWith => 'with';

  @override
  String get findLoadsAllRoutes => 'All routes';

  @override
  String get findLoadsAny => 'Any';

  @override
  String get findLoadsAnyTruck => 'Any truck';

  @override
  String get findLoadsSelectTruckForLoad => 'Select a truck for this load';

  @override
  String get findLoadsUnknownTruckType => 'Unknown type';

  @override
  String get findLoadsTyresSuffix => 'tyres';

  @override
  String get findLoadsMatchLabel => 'MATCH';

  @override
  String get findLoadsMismatchLabel => 'MISMATCH';

  @override
  String get findLoadsDashboardTts => 'Find loads dashboard';

  @override
  String get findLoadsScreenTtsContext =>
      'Find loads dashboard. Search available loads, apply route filters, and review best matches.';

  @override
  String findLoadsScreenTtsContextCount(int count) {
    return 'Load marketplace. $count loads found.';
  }

  @override
  String get findLoadsHeroTitle => 'Find the right load quickly';

  @override
  String get findLoadsHeroSubtitle =>
      'Use route, cargo and truck filters to discover best matches.';

  @override
  String get findLoadsFromLabel => 'From';

  @override
  String get findLoadsToLabel => 'To';

  @override
  String get findLoadsAdvancedFilters => 'Advanced Filters';

  @override
  String get findLoadsListViewLabel => 'List';

  @override
  String get findLoadsMapViewLabel => 'Map';

  @override
  String get botCancelResponse =>
      'Okay, I\'m cancelling the process. Anything else?';

  @override
  String get botMyLoadsResponse => 'Here are your loads.';

  @override
  String get botViewLoadsAction => 'View Loads';

  @override
  String get botMyTripsResponse => 'Here are your trips.';

  @override
  String get botViewTripsAction => 'View Trips';

  @override
  String get botCheckStatusResponse => 'Check your booking status here.';

  @override
  String get botCheckStatusAction => 'Check Status';

  @override
  String get botHelpResponse =>
      'I can help you find loads, post loads, and check trips. Try saying \'find load\'.';

  @override
  String get botGreetingResponse =>
      'Namaste! I am the TranZfort bot. How can I help you today?';

  @override
  String get botUnknownResponse =>
      'I didn\'t understand that. You can say \'find load\', \'post load\', or \'trip status\'.';

  @override
  String get botAskOrigin => 'From where? (Tell me the origin city)';

  @override
  String get botAskDestination => 'To where? (Tell me the destination city)';

  @override
  String botFindLoadSummary(String origin, String dest) {
    return 'Looking for loads from $origin to $dest. View them?';
  }

  @override
  String get botAskPostOrigin => 'From where are you sending the load?';

  @override
  String get botAskPostDestination => 'Where are you sending it to?';

  @override
  String get botAskPostMaterial =>
      'What material are you sending? (e.g., Coal, Steel)';

  @override
  String botPostLoadSummary(String material, String origin, String dest) {
    return 'Post a load for $material from $origin to $dest?';
  }

  @override
  String get supplierDashboardTitle => 'Supplier Dashboard';

  @override
  String get supplierDashboardTts => 'Supplier dashboard';

  @override
  String get supplierDashboardTtsContext =>
      'Supplier dashboard. Review active loads, pending bookings, and overall fulfillment.';

  @override
  String get supplierDashboardPendingBookingsLabel => 'Pending bookings';

  @override
  String get supplierDashboardNeedsActionTitle => 'Needs your action';

  @override
  String get supplierDashboardRecentLoadsTitle => 'Recent load updates';

  @override
  String get supplierDashboardNoRecentLoads => 'No recent load updates yet.';

  @override
  String get truckerDashboardTitle => 'Trucker Dashboard';

  @override
  String get truckerDashboardTts => 'Trucker dashboard';

  @override
  String get truckerDashboardTtsContext =>
      'Trucker dashboard. Track active bids, upcoming trips, and overall fulfillment.';

  @override
  String get findLoadsOriginCity => 'Origin City';

  @override
  String get findLoadsSortByLabel => 'Sort by';

  @override
  String get findLoadsSortNewest => 'Newest';

  @override
  String get findLoadsSortPriceHighLow => 'Price High-Low';

  @override
  String get findLoadsSortPriceLowHigh => 'Price Low-High';

  @override
  String get findLoadsSortPickupDate => 'Pickup Date';

  @override
  String get findLoadsMaterialLabel => 'Material';

  @override
  String get findLoadsTruckLabel => 'Truck';

  @override
  String findLoadsActiveFiltersSummary(int count) {
    return '$count filters active';
  }

  @override
  String get findLoadsMaterialCoal => 'Coal';

  @override
  String get findLoadsMaterialSteel => 'Steel';

  @override
  String get findLoadsMaterialCement => 'Cement';

  @override
  String get findLoadsMaterialSand => 'Sand';

  @override
  String get findLoadsViewListLabel => 'List';

  @override
  String get findLoadsViewMapLabel => 'Map';

  @override
  String get findLoadsSaveSearchAction => 'Save Search';

  @override
  String get findLoadsSavedSearchesLabel => 'Saved searches';

  @override
  String get findLoadsSavedSearchSaved => 'Search saved.';

  @override
  String get findLoadsSavedSearchSaveFailed => 'Could not save search.';

  @override
  String get findLoadsSavedSearchDeleted => 'Saved search removed.';

  @override
  String get findLoadsSavedSearchDeleteFailed =>
      'Could not remove saved search.';

  @override
  String get myFleetTitle => 'My Fleet';

  @override
  String get myFleetAddTruckTooltip => 'Add Truck';

  @override
  String get myFleetDashboardTts => 'Fleet dashboard';

  @override
  String get myFleetScreenTtsContext =>
      'Fleet dashboard. Manage trucks, compliance details, and current availability.';

  @override
  String myFleetScreenTtsContextCount(int count) {
    return 'Your fleet. $count trucks.';
  }

  @override
  String get myFleetEmptyTitle => 'No trucks yet';

  @override
  String get myFleetEmptySubtitle => 'Tap + to add your first truck.';

  @override
  String get myFleetLoadError => 'Failed to load fleet';

  @override
  String get myFleetHeroTitle => 'Keep your fleet verification-ready';

  @override
  String get myFleetHeroSubtitle =>
      'Review status, rejection remarks, and truck details before booking loads.';

  @override
  String myFleetBodyLabel(Object body) {
    return 'Body: $body';
  }

  @override
  String myFleetTyresLabel(Object tyres) {
    return 'Tyres: $tyres';
  }

  @override
  String myFleetCapacityLabel(Object capacity) {
    return 'Capacity: $capacity T';
  }

  @override
  String myFleetRejectionReasonLabel(Object reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String get myFleetRcExpiredWarning =>
      'RC expired. Renew this truck document to avoid dispatch issues.';

  @override
  String myFleetRcExpiryWarningDays(int days) {
    return 'RC expires in $days day(s). Please renew soon.';
  }

  @override
  String get addTruckTitle => 'Add Truck';

  @override
  String get addTruckHeroTitle => 'Add your truck details';

  @override
  String get addTruckHeroSubtitle =>
      'Keep fleet information complete to improve booking confidence.';

  @override
  String get addTruckIdentitySection => 'Truck identity';

  @override
  String get addTruckNumberLabel => 'Truck Number';

  @override
  String get addTruckNumberRequired => 'Truck number is required';

  @override
  String get addTruckBodyTypeLabel => 'Body Type';

  @override
  String get addTruckModelManualEntryOption => 'Not in list / manual entry';

  @override
  String get addTruckModelOptionalLabel => 'Truck Model (optional)';

  @override
  String get addTruckCatalogLoadError =>
      'Failed to load truck catalog. Please try again.';

  @override
  String get addTruckSpecificationsSection => 'Specifications';

  @override
  String get addTruckTyresLabel => 'Tyres';

  @override
  String get addTruckTyresRangeError => 'Enter tyres between 4 and 22';

  @override
  String get addTruckCapacityLabel => 'Capacity (T)';

  @override
  String get addTruckCapacityInvalid => 'Enter a valid capacity';

  @override
  String get addTruckDocumentsSection => 'Documents';

  @override
  String get addTruckUploadRcPhoto => 'Upload RC Photo';

  @override
  String get addTruckRcExpiryDateLabel => 'RC expiry date';

  @override
  String get addTruckSelectDateAction => 'Select Date';

  @override
  String get addTruckRcUploadedReplace => 'RC uploaded. Tap to replace.';

  @override
  String get addTruckRcRequired =>
      'RC photo is required to keep truck details complete.';

  @override
  String get addTruckSaveAction => 'Save Truck';

  @override
  String get addTruckSelectBodyTypeError => 'Please select body type';

  @override
  String get addTruckSaveFailed => 'Failed to add truck. Please try again.';

  @override
  String get loadDetailLoadError => 'Failed to load detail';

  @override
  String get loadDetailTripCostUnavailable => 'Trip cost unavailable';

  @override
  String get loadDetailTripCostBreakdown => 'Trip Cost Breakdown';

  @override
  String get loadDetailTripCostDiesel => 'Diesel';

  @override
  String get loadDetailTripCostTolls => 'Tolls';

  @override
  String get loadDetailTripCostTotal => 'Total';

  @override
  String get loadDetailTripCostMileage => 'Mileage';

  @override
  String get loadDetailPendingApproval => 'Pending Approval';

  @override
  String get loadDetailBookingApproved => 'Booking approved';

  @override
  String get loadDetailApproveFailed => 'Approve failed';

  @override
  String get loadDetailBookingRejected => 'Booking rejected';

  @override
  String get loadDetailRejectFailed => 'Reject failed';

  @override
  String get loadDetailNoPendingBookings => 'No pending bookings.';

  @override
  String get loadDetailInTransit => 'In Transit';

  @override
  String get loadDetailTripInTransit => 'Trip is in transit';

  @override
  String get loadDetailPodUploaded => 'POD Uploaded';

  @override
  String get loadDetailConfirmDelivery => 'Confirm Delivery';

  @override
  String get loadDetailDeliveryConfirmed => 'Delivery confirmed.';

  @override
  String get loadDetailDeliveryConfirmFailed => 'Could not confirm delivery.';

  @override
  String get loadDetailDelivered => 'Delivered';

  @override
  String get loadDetailTruckLabel => 'Truck';

  @override
  String get loadDetailApproveAction => 'Approve';

  @override
  String get loadDetailRejectAction => 'Reject';

  @override
  String get loadDetailStatusPrefix => 'Status';

  @override
  String richLoadCardTripCostEstimate(Object amount) {
    return 'Est. Trip Cost: $amount';
  }

  @override
  String get richLoadCardSuperLoadLabel => 'Super Load';

  @override
  String get richLoadCardVerifiedSupplierFallback => 'Verified Supplier';

  @override
  String get richLoadCardPickupPrefix => 'Pickup';

  @override
  String richLoadCardTrucksNeededSummary(int needed, int booked) {
    return '$needed trucks needed · $booked booked';
  }

  @override
  String get richLoadCardAdvanceUnavailable => 'Advance: -';

  @override
  String richLoadCardAdvanceLabel(int percentage, Object amount) {
    return 'Advance: $percentage% ($amount)';
  }

  @override
  String get richLoadCardJustNow => 'Just now';

  @override
  String get profileScreenTts => 'Profile screen';

  @override
  String get profileNotFound => 'No profile found.';

  @override
  String get profileDefaultUserName => 'TranZfort User';

  @override
  String get profileVerifiedChip => 'VERIFIED';

  @override
  String profileVerificationChip(Object status) {
    return 'VERIFICATION $status';
  }

  @override
  String get profileSummaryTitle => 'Profile summary';

  @override
  String get profileRoleLabel => 'Role';

  @override
  String get profileStatusLabel => 'Status';

  @override
  String get profileMobileLabel => 'Mobile';

  @override
  String get profileValueNa => 'NA';

  @override
  String get profileValueSet => 'SET';

  @override
  String get profileIdentityDetailsTitle => 'Identity details';

  @override
  String get profileFullNameLabel => 'Full name';

  @override
  String get profileVerificationLabel => 'Verification';

  @override
  String get profileQuickActionsTitle => 'Quick actions';

  @override
  String get profileDocumentExpiryTitle => 'Document expiry alerts';

  @override
  String get profileDlExpiredWarning =>
      'Driving licence has expired. Update verification documents now.';

  @override
  String profileDlExpiryWarningDays(int days) {
    return 'Driving licence expires in $days day(s). Please renew and re-upload.';
  }

  @override
  String get profileSupplierVerificationAction => 'Supplier verification';

  @override
  String get profileTruckerVerificationAction => 'Trucker verification';

  @override
  String get profileVerificationActionSubtitle =>
      'Review and manage your verification documents.';

  @override
  String get profileSettingsActionSubtitle =>
      'Open app preferences and account controls.';

  @override
  String get profileLoadError => 'Failed to load profile.';

  @override
  String get notificationsMarkAllAsRead => 'Mark all as read';

  @override
  String get notificationsScreenTts => 'Notifications screen';

  @override
  String notificationsScreenTtsCount(int count) {
    return '$count new notifications.';
  }

  @override
  String get notificationsAllCaughtUpTitle => 'All caught up!';

  @override
  String get notificationsAllCaughtUpSubtitle =>
      'You have no new notifications.';

  @override
  String notificationsUnreadUpdates(int count) {
    return '$count unread updates';
  }

  @override
  String get notificationsCaughtUpBanner => 'You are all caught up';

  @override
  String get notificationsRealtimeHint =>
      'Trip, load, and chat alerts appear here in real time.';

  @override
  String get notificationsLoadError => 'Failed to load notifications';

  @override
  String notificationsTimeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String notificationsTimeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String notificationsTimeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get notificationsTimeJustNow => 'Just now';

  @override
  String get routePreviewOpenMapsFailed => 'Could not open Google Maps';

  @override
  String get routePreviewTitle => 'Route Preview';

  @override
  String get routePreviewDetailsUnavailable => 'Route details not available.';

  @override
  String get routePreviewFallbackWarning =>
      'Showing direct line. Real route calculation failed.';

  @override
  String get routePreviewStartNavigation => 'Start Navigation in Google Maps';

  @override
  String get routePreviewLoadError => 'Error loading route.';

  @override
  String routePreviewScreenTtsContext(Object origin, Object destination) {
    return 'Route from $origin to $destination.';
  }

  @override
  String get postLoadStepTtsRoute =>
      'Step 1: Enter pickup and delivery cities.';

  @override
  String get postLoadStepTtsCargo =>
      'Step 2: Select material and enter weight.';

  @override
  String get postLoadStepTtsSchedule =>
      'Step 3: Choose truck type and tyre size.';

  @override
  String get postLoadStepTtsPricing =>
      'Step 4: Set your price, advance, and pickup date.';

  @override
  String get postLoadTtsSuccess => 'Load posted successfully.';

  @override
  String get postLoadTtsFailure => 'Load posting failed. Please try again.';

  @override
  String loadDetailScreenTtsContext(
    Object origin,
    Object destination,
    Object material,
    Object weight,
    Object price,
  ) {
    return 'Load from $origin to $destination. $material, ${weight}T. Price: rupees $price.';
  }

  @override
  String tripDetailScreenTtsContext(
    Object origin,
    Object destination,
    Object stage,
    Object nextAction,
  ) {
    return 'Trip from $origin to $destination. Stage: $stage. Next: $nextAction.';
  }

  @override
  String get verificationCompanyDetailsSection => 'Company details';

  @override
  String get verificationProfilePhotoLabel => 'Upload Profile Photo';

  @override
  String get verificationCompanyNameLabel => 'Company Name';

  @override
  String get verificationGstNumberLabel => 'GST Number';

  @override
  String get verificationUploadGstCertificate => 'Upload GST Certificate';

  @override
  String get verificationTaxDetailsSection => 'Tax details';

  @override
  String get verificationIdentityDetailsSection => 'Identity details';

  @override
  String get verificationPanNumberLabel => 'PAN Number';

  @override
  String get verificationUploadPanCard => 'Upload PAN Card';

  @override
  String get verificationTanNumberLabel => 'TAN Number';

  @override
  String get verificationTanHelper => 'TAN format: 10 characters alphanumeric';

  @override
  String get verificationTanInvalid => 'Enter a valid TAN (10 characters)';

  @override
  String get verificationGstInvalid =>
      'Enter a valid GST number (15 characters)';

  @override
  String get verificationUploadTanCard => 'Upload TAN Card';

  @override
  String get verificationAadhaarNumberLabel => 'Aadhaar Number';

  @override
  String get verificationUploadAadhaarFront => 'Upload Aadhaar Front';

  @override
  String get verificationUploadAadhaarBack => 'Upload Aadhaar Back';

  @override
  String get verificationOptionalBusinessProofSection =>
      'Optional business proof';

  @override
  String get verificationBusinessLicenceNumberLabel =>
      'Business Licence Number';

  @override
  String get verificationUploadBusinessLicence => 'Upload Business Licence';

  @override
  String get verificationDrivingLicenseSection => 'Driving license details';

  @override
  String get verificationDlNumberLabel => 'DL Number';

  @override
  String get verificationDlExpiryDateLabel => 'DL expiry date';

  @override
  String get verificationSelectDateAction => 'Select Date';

  @override
  String get verificationUploadDlFront => 'Upload DL Front';

  @override
  String get verificationUploadDlBack => 'Upload DL Back';

  @override
  String get verificationSupplierTtsProfilePhoto =>
      'Upload your supplier profile photo.';

  @override
  String get verificationSupplierTtsCompanyName =>
      'Enter your company name as registered.';

  @override
  String get verificationSupplierTtsGstNumber => 'Enter your GST number.';

  @override
  String get verificationSupplierTtsTanNumber => 'Enter your TAN number.';

  @override
  String get verificationSupplierTtsGstCertificate =>
      'Upload your GST certificate image.';

  @override
  String get verificationSupplierTtsTanCard => 'Upload your TAN card photo.';

  @override
  String get verificationSupplierTtsPanNumber =>
      'Enter your PAN number in the format A B C D E 1 2 3 4 F.';

  @override
  String get verificationSupplierTtsPanCard => 'Upload your PAN card image.';

  @override
  String get verificationSupplierTtsAadhaarNumber =>
      'Enter your 12-digit Aadhaar number.';

  @override
  String get verificationSupplierTtsAadhaarFront =>
      'Upload the front side of your Aadhaar card.';

  @override
  String get verificationSupplierTtsAadhaarBack =>
      'Upload the back side of your Aadhaar card.';

  @override
  String get verificationSupplierTtsBusinessLicenceNumber =>
      'Enter your business licence number if available.';

  @override
  String get verificationSupplierTtsBusinessLicenceDoc =>
      'Upload your business licence document if available.';

  @override
  String get verificationTruckerTtsProfilePhoto =>
      'Upload your trucker profile photo.';

  @override
  String get verificationTruckerTtsAadhaarNumber =>
      'Enter your 12-digit Aadhaar number.';

  @override
  String get verificationTruckerTtsAadhaarFront =>
      'Upload the front side of your Aadhaar card.';

  @override
  String get verificationTruckerTtsAadhaarBack =>
      'Upload the back side of your Aadhaar card.';

  @override
  String get verificationTruckerTtsPanNumber =>
      'Enter your PAN number in the format A B C D E 1 2 3 4 F.';

  @override
  String get verificationTruckerTtsPanCard => 'Upload your PAN card image.';

  @override
  String get verificationTruckerTtsDlNumber =>
      'Enter your driving licence number exactly as printed.';

  @override
  String get verificationTruckerTtsDlFront =>
      'Upload the front side of your driving licence.';

  @override
  String get verificationTruckerTtsDlBack =>
      'Upload the back side of your driving licence.';
}
