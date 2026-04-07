import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'TranZfort'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Trusted load movement across India.'**
  String get splashTagline;

  /// No description provided for @splashFirstOpenGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TranZfort.'**
  String get splashFirstOpenGreeting;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Settings screen. Manage language, voice guidance, notifications, and account options.'**
  String get settingsScreenTtsContext;

  /// No description provided for @appBarTtsMutedSnack.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance muted'**
  String get appBarTtsMutedSnack;

  /// No description provided for @appBarTtsEnabledSnack.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance enabled'**
  String get appBarTtsEnabledSnack;

  /// No description provided for @appBarLanguageChangedHindi.
  ///
  /// In en, this message translates to:
  /// **'Language changed: Hindi'**
  String get appBarLanguageChangedHindi;

  /// No description provided for @appBarLanguageChangedEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language changed: English'**
  String get appBarLanguageChangedEnglish;

  /// No description provided for @appBarTtsTooltipMute.
  ///
  /// In en, this message translates to:
  /// **'Mute voice guidance ({screen})'**
  String appBarTtsTooltipMute(Object screen);

  /// No description provided for @appBarTtsTooltipEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable voice guidance'**
  String get appBarTtsTooltipEnable;

  /// No description provided for @appBarLanguageToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle language'**
  String get appBarLanguageToggleTooltip;

  /// No description provided for @appBarNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get appBarNotificationsTooltip;

  /// No description provided for @appDrawerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get appDrawerProfileTitle;

  /// No description provided for @appDrawerSupplierWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Supplier workspace'**
  String get appDrawerSupplierWorkspace;

  /// No description provided for @appDrawerTruckerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Trucker workspace'**
  String get appDrawerTruckerWorkspace;

  /// No description provided for @appDrawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get appDrawerHome;

  /// No description provided for @appDrawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get appDrawerDashboard;

  /// No description provided for @appDrawerVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get appDrawerVerification;

  /// No description provided for @appDrawerBotChat.
  ///
  /// In en, this message translates to:
  /// **'Bot Chat'**
  String get appDrawerBotChat;

  /// No description provided for @dashboardVerificationStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get dashboardVerificationStatusVerified;

  /// No description provided for @dashboardVerificationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Verification under review'**
  String get dashboardVerificationStatusPending;

  /// No description provided for @dashboardVerificationStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Verification not started'**
  String get dashboardVerificationStatusUnverified;

  /// No description provided for @dashboardVerificationStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Verification needs updates'**
  String get dashboardVerificationStatusRejected;

  /// No description provided for @dashboardVerificationStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Verification status unavailable'**
  String get dashboardVerificationStatusUnknown;

  /// No description provided for @dashboardVerificationRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Update needed: {reason}'**
  String dashboardVerificationRejectedReason(Object reason);

  /// No description provided for @sharedLoadingSuffix.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get sharedLoadingSuffix;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get languageHindi;

  /// No description provided for @postLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get postLoadTitle;

  /// No description provided for @loadDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Detail'**
  String get loadDetailTitle;

  /// No description provided for @viewRouteMap.
  ///
  /// In en, this message translates to:
  /// **'View Route Map'**
  String get viewRouteMap;

  /// No description provided for @actionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTitle;

  /// No description provided for @loadNotFound.
  ///
  /// In en, this message translates to:
  /// **'Load not found'**
  String get loadNotFound;

  /// No description provided for @couldNotStartChatRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not start chat. Please retry.'**
  String get couldNotStartChatRetry;

  /// No description provided for @verifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyAction;

  /// No description provided for @completeTruckerVerificationToChat.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker verification to start chat with suppliers.'**
  String get completeTruckerVerificationToChat;

  /// No description provided for @createLoadQuickSteps.
  ///
  /// In en, this message translates to:
  /// **'Create a load in 4 quick steps'**
  String get createLoadQuickSteps;

  /// No description provided for @createLoadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add route, cargo, truck requirement and pricing details.'**
  String get createLoadSubtitle;

  /// No description provided for @postLoadSuperLoadReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Super Load readiness'**
  String get postLoadSuperLoadReadinessTitle;

  /// No description provided for @postLoadSuperLoadReadinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Super Load support requires supplier verification and a ready payout profile.'**
  String get postLoadSuperLoadReadinessSubtitle;

  /// No description provided for @loadPostedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load posted successfully'**
  String get loadPostedSuccess;

  /// No description provided for @loadPostFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to post load. Please try again.'**
  String get loadPostFailure;

  /// No description provided for @postLoadSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get postLoadSubmitAction;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @postLoadStepRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get postLoadStepRouteTitle;

  /// No description provided for @postLoadStepCargoTitle.
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get postLoadStepCargoTitle;

  /// No description provided for @postLoadStepVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get postLoadStepVehicleTitle;

  /// No description provided for @postLoadStepPriceScaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Price & Scale'**
  String get postLoadStepPriceScaleTitle;

  /// No description provided for @postLoadStepSummary.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total} — {label}'**
  String postLoadStepSummary(Object current, Object total, Object label);

  /// No description provided for @postLoadOriginCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin City'**
  String get postLoadOriginCityLabel;

  /// No description provided for @postLoadDestinationCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination City'**
  String get postLoadDestinationCityLabel;

  /// No description provided for @postLoadApproxRouteInfo.
  ///
  /// In en, this message translates to:
  /// **'Approx route: {km} km · {hours}h'**
  String postLoadApproxRouteInfo(Object km, Object hours);

  /// No description provided for @postLoadDistanceUnavailableFallback.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable (offline fallback in use)'**
  String get postLoadDistanceUnavailableFallback;

  /// No description provided for @postLoadMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get postLoadMaterialLabel;

  /// No description provided for @postLoadWeightPerTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight per Truck (Tonnes)'**
  String get postLoadWeightPerTruckLabel;

  /// No description provided for @postLoadTruckBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck Body Type'**
  String get postLoadTruckBodyTypeLabel;

  /// No description provided for @postLoadTruckTypeAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get postLoadTruckTypeAny;

  /// No description provided for @postLoadTruckTypeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get postLoadTruckTypeOpen;

  /// No description provided for @postLoadTruckTypeContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get postLoadTruckTypeContainer;

  /// No description provided for @postLoadTruckTypeTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get postLoadTruckTypeTrailer;

  /// No description provided for @postLoadTruckTypeTanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get postLoadTruckTypeTanker;

  /// No description provided for @postLoadTruckTypeRefrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated'**
  String get postLoadTruckTypeRefrigerated;

  /// No description provided for @postLoadPriceTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Price (₹)'**
  String get postLoadPriceTotalLabel;

  /// No description provided for @postLoadPriceTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get postLoadPriceTypeFixed;

  /// No description provided for @postLoadPriceTypeNegotiable.
  ///
  /// In en, this message translates to:
  /// **'Per ton'**
  String get postLoadPriceTypeNegotiable;

  /// No description provided for @postLoadAdvanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance: {percentage}%'**
  String postLoadAdvanceLabel(int percentage);

  /// No description provided for @postLoadPickupDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get postLoadPickupDateLabel;

  /// No description provided for @postLoadChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get postLoadChangeAction;

  /// No description provided for @postLoadTrucksNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'How many trucks needed?'**
  String get postLoadTrucksNeededLabel;

  /// No description provided for @findLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Loads'**
  String get findLoadsTitle;

  /// No description provided for @searchLoads.
  ///
  /// In en, this message translates to:
  /// **'Search Loads'**
  String get searchLoads;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @editAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// No description provided for @loadsFound.
  ///
  /// In en, this message translates to:
  /// **'loads found'**
  String get loadsFound;

  /// No description provided for @mapViewComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Map view is coming soon'**
  String get mapViewComingSoonTitle;

  /// No description provided for @mapViewComingSoonSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch back to list view to continue booking available loads.'**
  String get mapViewComingSoonSubtitle;

  /// No description provided for @noLoadsFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'No loads found'**
  String get noLoadsFoundTitle;

  /// No description provided for @noLoadsFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try changing your filters or check back later.'**
  String get noLoadsFoundSubtitle;

  /// No description provided for @myLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Loads'**
  String get myLoadsTitle;

  /// No description provided for @myLoadsDashboardTts.
  ///
  /// In en, this message translates to:
  /// **'My loads dashboard'**
  String get myLoadsDashboardTts;

  /// No description provided for @myLoadsScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'My loads dashboard. Review active and completed loads, booking activity, and fulfillment progress.'**
  String get myLoadsScreenTtsContext;

  /// No description provided for @myLoadsScreenTtsContextDetailed.
  ///
  /// In en, this message translates to:
  /// **'Your loads dashboard. {active} active loads, {inTransit} in transit.'**
  String myLoadsScreenTtsContextDetailed(int active, int inTransit);

  /// No description provided for @supplierOverview.
  ///
  /// In en, this message translates to:
  /// **'Supplier overview'**
  String get supplierOverview;

  /// No description provided for @myLoadsOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track active loads, bookings, and fulfillment progress.'**
  String get myLoadsOverviewSubtitle;

  /// No description provided for @myLoadsActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active loads'**
  String get myLoadsActiveLabel;

  /// No description provided for @myLoadsInTransitLabel.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get myLoadsInTransitLabel;

  /// No description provided for @myLoadsRequiresActionBanner.
  ///
  /// In en, this message translates to:
  /// **'{count} load(s) need your action.'**
  String myLoadsRequiresActionBanner(int count);

  /// No description provided for @activeTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTab;

  /// No description provided for @completedTab.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTab;

  /// No description provided for @postLoadAction.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get postLoadAction;

  /// No description provided for @noCompletedLoads.
  ///
  /// In en, this message translates to:
  /// **'No completed loads'**
  String get noCompletedLoads;

  /// No description provided for @noActiveLoads.
  ///
  /// In en, this message translates to:
  /// **'No active loads'**
  String get noActiveLoads;

  /// No description provided for @completedLoadsHere.
  ///
  /// In en, this message translates to:
  /// **'Completed/cancelled loads will show here.'**
  String get completedLoadsHere;

  /// No description provided for @postFirstLoadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Post your first load to start getting bookings.'**
  String get postFirstLoadPrompt;

  /// No description provided for @loadDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Load deactivated'**
  String get loadDeactivated;

  /// No description provided for @couldNotDeactivateLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not deactivate load'**
  String get couldNotDeactivateLoad;

  /// No description provided for @deactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivateAction;

  /// No description provided for @myLoadsTrucksBookedSummary.
  ///
  /// In en, this message translates to:
  /// **'{booked}/{needed} trucks booked'**
  String myLoadsTrucksBookedSummary(int booked, int needed);

  /// No description provided for @myLoadsLoadErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Could not load your loads'**
  String get myLoadsLoadErrorPrefix;

  /// No description provided for @myLoadsStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get myLoadsStatusCompleted;

  /// No description provided for @myLoadsStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get myLoadsStatusCancelled;

  /// No description provided for @myLoadsStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get myLoadsStatusWaiting;

  /// No description provided for @myLoadsStatusFullyBooked.
  ///
  /// In en, this message translates to:
  /// **'Fully booked'**
  String get myLoadsStatusFullyBooked;

  /// No description provided for @myLoadsStatusFulfilling.
  ///
  /// In en, this message translates to:
  /// **'Fulfilling'**
  String get myLoadsStatusFulfilling;

  /// No description provided for @loadBookedAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Load booked! Waiting for supplier approval.'**
  String get loadBookedAwaitingApproval;

  /// No description provided for @bookingFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Booking failed. Please try again.'**
  String get bookingFailedTryAgain;

  /// No description provided for @loadBookTtsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent. Awaiting supplier approval.'**
  String get loadBookTtsSuccess;

  /// No description provided for @loadBookTtsFailure.
  ///
  /// In en, this message translates to:
  /// **'Booking failed. Please try again.'**
  String get loadBookTtsFailure;

  /// No description provided for @authTtsPromptGoogleOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google or phone number.'**
  String get authTtsPromptGoogleOrPhone;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorAuthFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authErrorAuthFailed;

  /// No description provided for @authErrorConflict.
  ///
  /// In en, this message translates to:
  /// **'This account is already registered. Try signing in.'**
  String get authErrorConflict;

  /// No description provided for @authErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please review the entered details.'**
  String get authErrorValidation;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authOneFinalStep.
  ///
  /// In en, this message translates to:
  /// **'One final step'**
  String get authOneFinalStep;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TranZfort'**
  String get authWelcomeTitle;

  /// No description provided for @authGoogleDoneAddMobile.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in done. Add your mobile number to continue.'**
  String get authGoogleDoneAddMobile;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'India\'s trusted load matching platform for suppliers and truckers.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authContinueJourney.
  ///
  /// In en, this message translates to:
  /// **'Continue your journey'**
  String get authContinueJourney;

  /// No description provided for @authChooseSignInMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred sign-in method.'**
  String get authChooseSignInMethod;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authOr;

  /// No description provided for @authContinueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get authContinueWithPhone;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authTermsAgreement.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy.'**
  String get authTermsAgreement;

  /// No description provided for @phoneInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get phoneInvalidNumber;

  /// No description provided for @phoneSaveErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Could not save mobile number. Please try again.'**
  String get phoneSaveErrorAuth;

  /// No description provided for @phoneSaveErrorConflict.
  ///
  /// In en, this message translates to:
  /// **'This number is already linked to another account. Try a different number.'**
  String get phoneSaveErrorConflict;

  /// No description provided for @phoneSaveErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number.'**
  String get phoneSaveErrorValidation;

  /// No description provided for @phoneEnterMobileTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get phoneEnterMobileTitle;

  /// No description provided for @phoneEnterMobileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your number to continue. OTP verification is deferred for now.'**
  String get phoneEnterMobileSubtitle;

  /// No description provided for @phoneVerificationSetup.
  ///
  /// In en, this message translates to:
  /// **'Mobile verification setup'**
  String get phoneVerificationSetup;

  /// No description provided for @phoneVerificationSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your active number to receive booking and trip alerts.'**
  String get phoneVerificationSetupSubtitle;

  /// No description provided for @phoneLabelMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Number'**
  String get phoneLabelMobileNumber;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @otpTtsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit OTP sent to your phone.'**
  String get otpTtsPrompt;

  /// No description provided for @otpVerificationDeferredMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP verification is deferred for now. Please continue with mobile capture flow.'**
  String get otpVerificationDeferredMessage;

  /// No description provided for @otpVerificationDeferredTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP verification is currently deferred'**
  String get otpVerificationDeferredTitle;

  /// No description provided for @otpVerificationDeferredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use mobile capture flow to continue onboarding.'**
  String get otpVerificationDeferredSubtitle;

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpResendDeferred.
  ///
  /// In en, this message translates to:
  /// **'OTP resend is deferred for now.'**
  String get otpResendDeferred;

  /// No description provided for @otpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get otpResendCode;

  /// No description provided for @roleTtsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Are you a supplier or trucker? Please choose.'**
  String get roleTtsPrompt;

  /// No description provided for @roleErrorAuth.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again.'**
  String get roleErrorAuth;

  /// No description provided for @roleErrorConflict.
  ///
  /// In en, this message translates to:
  /// **'Role setup was already completed.'**
  String get roleErrorConflict;

  /// No description provided for @roleErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please choose a valid role.'**
  String get roleErrorValidation;

  /// No description provided for @roleErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not save role. Please try again.'**
  String get roleErrorGeneric;

  /// No description provided for @roleTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use TranZfort?'**
  String get roleTitle;

  /// No description provided for @roleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your role to personalize your dashboard and actions.'**
  String get roleSubtitle;

  /// No description provided for @roleSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'I am a Supplier / Consignor'**
  String get roleSupplierTitle;

  /// No description provided for @roleSupplierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I want to post loads and find trucks'**
  String get roleSupplierSubtitle;

  /// No description provided for @roleTruckerTitle.
  ///
  /// In en, this message translates to:
  /// **'I am a Trucker / Transporter'**
  String get roleTruckerTitle;

  /// No description provided for @roleTruckerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I want to find loads and manage my fleet'**
  String get roleTruckerSubtitle;

  /// No description provided for @roleCompleteSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get roleCompleteSetup;

  /// No description provided for @myTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get myTripsTitle;

  /// No description provided for @myTripsDashboardTts.
  ///
  /// In en, this message translates to:
  /// **'My trips dashboard'**
  String get myTripsDashboardTts;

  /// No description provided for @myTripsScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'My trips dashboard. Track current trips, completed deliveries, and stage updates.'**
  String get myTripsScreenTtsContext;

  /// No description provided for @myTripsScreenTtsContextDetailed.
  ///
  /// In en, this message translates to:
  /// **'Your trips. {active} active. Current trip: {origin} to {destination}.'**
  String myTripsScreenTtsContextDetailed(
    int active,
    Object origin,
    Object destination,
  );

  /// No description provided for @truckerOverview.
  ///
  /// In en, this message translates to:
  /// **'Trucker overview'**
  String get truckerOverview;

  /// No description provided for @truckerDashboardActiveBidsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active bids'**
  String get truckerDashboardActiveBidsLabel;

  /// No description provided for @truckerDashboardUpcomingTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trips'**
  String get truckerDashboardUpcomingTripsLabel;

  /// No description provided for @truckerDashboardPendingBidsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending bids'**
  String get truckerDashboardPendingBidsTitle;

  /// No description provided for @truckerDashboardUpcomingActiveTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming & active trips'**
  String get truckerDashboardUpcomingActiveTripsTitle;

  /// No description provided for @tripOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of active trips and stage progress.'**
  String get tripOverviewSubtitle;

  /// No description provided for @activeTripStatus.
  ///
  /// In en, this message translates to:
  /// **'Active Trip Status'**
  String get activeTripStatus;

  /// No description provided for @tripMilestonesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the next stage and keep documents ready.'**
  String get tripMilestonesSubtitle;

  /// No description provided for @noCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'No completed trips'**
  String get noCompletedTrips;

  /// No description provided for @noActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'No active trips'**
  String get noActiveTrips;

  /// No description provided for @completedTripsHere.
  ///
  /// In en, this message translates to:
  /// **'Completed trips will appear here.'**
  String get completedTripsHere;

  /// No description provided for @bookLoadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Book a load from Find Loads to start your first trip.'**
  String get bookLoadPrompt;

  /// No description provided for @findLoadsAction.
  ///
  /// In en, this message translates to:
  /// **'Find Loads'**
  String get findLoadsAction;

  /// No description provided for @tripsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load trips. Please try again.'**
  String get tripsLoadError;

  /// No description provided for @tripRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get tripRecentlyUpdated;

  /// No description provided for @tripCompletedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripCompletedPrefix;

  /// No description provided for @tripStartedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get tripStartedPrefix;

  /// No description provided for @tripApprovedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get tripApprovedPrefix;

  /// No description provided for @tripDeliveredPrefix.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get tripDeliveredPrefix;

  /// No description provided for @tripPodUploadedPrefix.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded'**
  String get tripPodUploadedPrefix;

  /// No description provided for @tripUpdatedPrefix.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get tripUpdatedPrefix;

  /// No description provided for @tripStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStageCompleted;

  /// No description provided for @tripStageInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get tripStageInTransit;

  /// No description provided for @tripStageAtPickup.
  ///
  /// In en, this message translates to:
  /// **'At Pickup'**
  String get tripStageAtPickup;

  /// No description provided for @tripStageDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get tripStageDelivered;

  /// No description provided for @tripStagePodUploaded.
  ///
  /// In en, this message translates to:
  /// **'POD Uploaded'**
  String get tripStagePodUploaded;

  /// No description provided for @tripStageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get tripStageUnknown;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @chatInboxTts.
  ///
  /// In en, this message translates to:
  /// **'Messages inbox'**
  String get chatInboxTts;

  /// No description provided for @chatInboxScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Messages inbox. Open conversations with suppliers and truckers and track recent updates.'**
  String get chatInboxScreenTtsContext;

  /// No description provided for @chatInboxScreenTtsContextCount.
  ///
  /// In en, this message translates to:
  /// **'Your messages. {count} conversations.'**
  String chatInboxScreenTtsContextCount(int count);

  /// No description provided for @chatNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesTitle;

  /// No description provided for @chatSupplierInboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a chat by engaging with a load.'**
  String get chatSupplierInboxSubtitle;

  /// No description provided for @chatTruckerInboxSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a chat by booking a load.'**
  String get chatTruckerInboxSubtitle;

  /// No description provided for @chatTapToOpenConversation.
  ///
  /// In en, this message translates to:
  /// **'Tap to open conversation'**
  String get chatTapToOpenConversation;

  /// No description provided for @chatTapToViewConversation.
  ///
  /// In en, this message translates to:
  /// **'Tap to view conversation'**
  String get chatTapToViewConversation;

  /// No description provided for @chatConversationsSuffix.
  ///
  /// In en, this message translates to:
  /// **'trucker conversation(s)'**
  String get chatConversationsSuffix;

  /// No description provided for @chatFailedLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get chatFailedLoadMessages;

  /// No description provided for @chatTruckerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Trucker'**
  String get chatTruckerFallbackName;

  /// No description provided for @chatSupplierFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get chatSupplierFallbackName;

  /// No description provided for @chatOpenConversationPrefix.
  ///
  /// In en, this message translates to:
  /// **'Open conversation'**
  String get chatOpenConversationPrefix;

  /// No description provided for @tripDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Detail'**
  String get tripDetailTitle;

  /// No description provided for @tripNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get tripNotFound;

  /// No description provided for @tripSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Snapshot'**
  String get tripSnapshotTitle;

  /// No description provided for @tripSnapshotTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get tripSnapshotTruck;

  /// No description provided for @tripSnapshotWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get tripSnapshotWeight;

  /// No description provided for @tripSnapshotDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get tripSnapshotDistance;

  /// No description provided for @tripSnapshotPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get tripSnapshotPrice;

  /// No description provided for @tripPickupActions.
  ///
  /// In en, this message translates to:
  /// **'Pickup actions'**
  String get tripPickupActions;

  /// No description provided for @tripTransitAction.
  ///
  /// In en, this message translates to:
  /// **'Transit action'**
  String get tripTransitAction;

  /// No description provided for @tripDeliveryProof.
  ///
  /// In en, this message translates to:
  /// **'Delivery proof'**
  String get tripDeliveryProof;

  /// No description provided for @tripLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load trip details. Please try again.'**
  String get tripLoadError;

  /// No description provided for @tripPodUploaded.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded'**
  String get tripPodUploaded;

  /// No description provided for @tripPodUploadedWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for supplier to confirm delivery.'**
  String get tripPodUploadedWaiting;

  /// No description provided for @tripTimelinePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get tripTimelinePickup;

  /// No description provided for @tripTimelineTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get tripTimelineTransit;

  /// No description provided for @tripTimelineDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get tripTimelineDelivered;

  /// No description provided for @tripTimelinePodUploaded.
  ///
  /// In en, this message translates to:
  /// **'POD Uploaded'**
  String get tripTimelinePodUploaded;

  /// No description provided for @tripTimelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripTimelineCompleted;

  /// No description provided for @tripRouteToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Route tools'**
  String get tripRouteToolsTitle;

  /// No description provided for @tripViewRoutePreviewAction.
  ///
  /// In en, this message translates to:
  /// **'View Route Preview'**
  String get tripViewRoutePreviewAction;

  /// No description provided for @tripOpenNavigationAction.
  ///
  /// In en, this message translates to:
  /// **'Open Navigation'**
  String get tripOpenNavigationAction;

  /// No description provided for @tripNavigateToPickupAction.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Pickup'**
  String get tripNavigateToPickupAction;

  /// No description provided for @tripNavigateToDestinationAction.
  ///
  /// In en, this message translates to:
  /// **'Navigate to Destination'**
  String get tripNavigateToDestinationAction;

  /// No description provided for @tripNavigationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Destination coordinates are unavailable for navigation.'**
  String get tripNavigationUnavailable;

  /// No description provided for @tripLocationCaptured.
  ///
  /// In en, this message translates to:
  /// **'Location captured.'**
  String get tripLocationCaptured;

  /// No description provided for @tripLocationCapturedAt.
  ///
  /// In en, this message translates to:
  /// **'Location captured at {location}.'**
  String tripLocationCapturedAt(Object location);

  /// No description provided for @tripYourRatingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get tripYourRatingPrefix;

  /// No description provided for @tripRateThisPrefix.
  ///
  /// In en, this message translates to:
  /// **'Rate this'**
  String get tripRateThisPrefix;

  /// No description provided for @tripCommentOptional.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get tripCommentOptional;

  /// No description provided for @tripSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get tripSubmitRating;

  /// No description provided for @tripRatingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted.'**
  String get tripRatingSubmitted;

  /// No description provided for @tripRatingSubmitError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit rating. Please try again.'**
  String get tripRatingSubmitError;

  /// No description provided for @tripStartAction.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get tripStartAction;

  /// No description provided for @tripStartDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get tripStartDialogTitle;

  /// No description provided for @tripStartDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm you have loaded the cargo and are ready to start?'**
  String get tripStartDialogMessage;

  /// No description provided for @tripCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get tripCancelAction;

  /// No description provided for @tripStartSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip started successfully.'**
  String get tripStartSuccess;

  /// No description provided for @tripStartError.
  ///
  /// In en, this message translates to:
  /// **'Could not start trip. Please try again.'**
  String get tripStartError;

  /// No description provided for @tripStartTtsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip started successfully.'**
  String get tripStartTtsSuccess;

  /// No description provided for @tripStartTtsFailure.
  ///
  /// In en, this message translates to:
  /// **'Trip start failed. Please try again.'**
  String get tripStartTtsFailure;

  /// No description provided for @tripUploadLrOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload LR (Optional)'**
  String get tripUploadLrOptional;

  /// No description provided for @tripLrUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'LR uploaded successfully.'**
  String get tripLrUploadSuccess;

  /// No description provided for @tripLrUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload LR. Please try again.'**
  String get tripLrUploadError;

  /// No description provided for @tripMarkDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get tripMarkDelivered;

  /// No description provided for @tripMarkDeliveredDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get tripMarkDeliveredDialogTitle;

  /// No description provided for @tripMarkDeliveredDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm cargo has been unloaded at destination?'**
  String get tripMarkDeliveredDialogMessage;

  /// No description provided for @tripConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get tripConfirmAction;

  /// No description provided for @tripMarkedDeliveredNextPod.
  ///
  /// In en, this message translates to:
  /// **'Marked delivered. Please upload POD next.'**
  String get tripMarkedDeliveredNextPod;

  /// No description provided for @tripMarkDeliveredError.
  ///
  /// In en, this message translates to:
  /// **'Could not mark delivered. Please try again.'**
  String get tripMarkDeliveredError;

  /// No description provided for @tripEmergencySosAction.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get tripEmergencySosAction;

  /// No description provided for @tripEmergencySosPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing SOS message with your current location...'**
  String get tripEmergencySosPreparing;

  /// No description provided for @tripEmergencySosLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not capture your current location for SOS.'**
  String get tripEmergencySosLocationUnavailable;

  /// No description provided for @tripEmergencySosLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open SMS app for SOS message.'**
  String get tripEmergencySosLaunchFailed;

  /// No description provided for @tripEmergencySosMessage.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert from TranZfort trip. Current location: {lat}, {lng}. Route: {route}. Please assist immediately.'**
  String tripEmergencySosMessage(Object lat, Object lng, Object route);

  /// No description provided for @tripUploadProofOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Upload Proof of Delivery'**
  String get tripUploadProofOfDelivery;

  /// No description provided for @tripUploadPodPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload POD Photo'**
  String get tripUploadPodPhoto;

  /// No description provided for @tripPodUploadSuccessWaiting.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded. Waiting for supplier confirmation.'**
  String get tripPodUploadSuccessWaiting;

  /// No description provided for @tripPodUploadError.
  ///
  /// In en, this message translates to:
  /// **'Could not upload POD. Please try again.'**
  String get tripPodUploadError;

  /// No description provided for @tripPodUploadTtsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery uploaded. Waiting for confirmation.'**
  String get tripPodUploadTtsSuccess;

  /// No description provided for @tripPodUploadTtsFailure.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery upload failed. Please try again.'**
  String get tripPodUploadTtsFailure;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @chatMicrophonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required'**
  String get chatMicrophonePermissionRequired;

  /// No description provided for @chatVoiceRecordingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Voice recording was empty'**
  String get chatVoiceRecordingEmpty;

  /// No description provided for @chatCouldNotReadRecordedFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read recorded file'**
  String get chatCouldNotReadRecordedFile;

  /// No description provided for @chatVoiceMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Voice message sent'**
  String get chatVoiceMessageSent;

  /// No description provided for @chatVoiceMessageSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send voice message'**
  String get chatVoiceMessageSendFailed;

  /// No description provided for @chatVoiceFileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice file unavailable'**
  String get chatVoiceFileUnavailable;

  /// No description provided for @chatUnablePlayVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to play voice message'**
  String get chatUnablePlayVoiceMessage;

  /// No description provided for @chatLocationShared.
  ///
  /// In en, this message translates to:
  /// **'Location shared'**
  String get chatLocationShared;

  /// No description provided for @chatCouldNotShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not share location'**
  String get chatCouldNotShareLocation;

  /// No description provided for @chatBookingActionShared.
  ///
  /// In en, this message translates to:
  /// **'Booking action shared'**
  String get chatBookingActionShared;

  /// No description provided for @chatCouldNotShareBookingAction.
  ///
  /// In en, this message translates to:
  /// **'Could not share booking action'**
  String get chatCouldNotShareBookingAction;

  /// No description provided for @chatBookingRequestSentFromChat.
  ///
  /// In en, this message translates to:
  /// **'Booking request sent from chat.'**
  String get chatBookingRequestSentFromChat;

  /// No description provided for @chatCouldNotBookFromChat.
  ///
  /// In en, this message translates to:
  /// **'Could not book from chat.'**
  String get chatCouldNotBookFromChat;

  /// No description provided for @chatAttachShareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share current location (Map card)'**
  String get chatAttachShareLocation;

  /// No description provided for @chatAttachShareBookingAction.
  ///
  /// In en, this message translates to:
  /// **'Share booking action'**
  String get chatAttachShareBookingAction;

  /// No description provided for @chatMapCardTitleLocationShared.
  ///
  /// In en, this message translates to:
  /// **'Location shared'**
  String get chatMapCardTitleLocationShared;

  /// No description provided for @chatMapCoordinatesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Coordinates unavailable'**
  String get chatMapCoordinatesUnavailable;

  /// No description provided for @chatMapLatLng.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat}, Lng {lng}'**
  String chatMapLatLng(Object lat, Object lng);

  /// No description provided for @chatBookThisLoad.
  ///
  /// In en, this message translates to:
  /// **'Book This Load'**
  String get chatBookThisLoad;

  /// No description provided for @chatBookingActionDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap below to send booking request from this chat.'**
  String get chatBookingActionDescription;

  /// No description provided for @chatFailedSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get chatFailedSendMessage;

  /// No description provided for @chatNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get chatNoMessagesYet;

  /// No description provided for @chatAttach.
  ///
  /// In en, this message translates to:
  /// **'Attach'**
  String get chatAttach;

  /// No description provided for @chatTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessageHint;

  /// No description provided for @chatSendMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get chatSendMessageTooltip;

  /// No description provided for @chatStopRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get chatStopRecordingTooltip;

  /// No description provided for @chatStartRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get chatStartRecordingTooltip;

  /// No description provided for @chatVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get chatVoiceLabel;

  /// No description provided for @chatPlayAction.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get chatPlayAction;

  /// No description provided for @chatStopAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get chatStopAction;

  /// No description provided for @chatOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get chatOpenMap;

  /// No description provided for @verificationSupplierPrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier verification'**
  String get verificationSupplierPrompt;

  /// No description provided for @verificationTruckerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker verification'**
  String get verificationTruckerPrompt;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification Required'**
  String get verificationRequired;

  /// No description provided for @verificationPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending Review'**
  String get verificationPendingReview;

  /// No description provided for @verificationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is under review. Load posting is enabled once verification is approved.'**
  String get verificationPendingMessage;

  /// No description provided for @verificationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier verification to post loads and access full marketplace actions.'**
  String get verificationRequiredMessage;

  /// No description provided for @completeVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete Verification'**
  String get completeVerification;

  /// No description provided for @chatWithSupplier.
  ///
  /// In en, this message translates to:
  /// **'Chat with Supplier'**
  String get chatWithSupplier;

  /// No description provided for @callSupplierAction.
  ///
  /// In en, this message translates to:
  /// **'Call Supplier'**
  String get callSupplierAction;

  /// No description provided for @callSupplierUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Supplier phone number is unavailable right now.'**
  String get callSupplierUnavailable;

  /// No description provided for @callSupplierLaunchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app. Please try again.'**
  String get callSupplierLaunchFailed;

  /// No description provided for @postedByPrefix.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get postedByPrefix;

  /// No description provided for @settingsTtsPreviewText.
  ///
  /// In en, this message translates to:
  /// **'Settings screen'**
  String get settingsTtsPreviewText;

  /// No description provided for @settingsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize your TranZfort workspace'**
  String get settingsHeroTitle;

  /// No description provided for @settingsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control language, voice, notifications, and account access in one place.'**
  String get settingsHeroSubtitle;

  /// No description provided for @settingsGeneralSection.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsGeneralSection;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Interface language for app labels and prompts.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsVoiceNotificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Voice & notifications'**
  String get settingsVoiceNotificationsSection;

  /// No description provided for @settingsTtsSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speech speed'**
  String get settingsTtsSpeedLabel;

  /// No description provided for @settingsTtsSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'Current speed: {speed}x'**
  String settingsTtsSpeedValue(Object speed);

  /// No description provided for @settingsTtsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'TTS language'**
  String get settingsTtsLanguageLabel;

  /// No description provided for @settingsTtsLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (match app language)'**
  String get settingsTtsLanguageAuto;

  /// No description provided for @settingsTtsPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview voice'**
  String get settingsTtsPreviewAction;

  /// No description provided for @settingsTtsMuteTitle.
  ///
  /// In en, this message translates to:
  /// **'TTS mute'**
  String get settingsTtsMuteTitle;

  /// No description provided for @settingsTtsMuteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mutes all automatic speech'**
  String get settingsTtsMuteSubtitle;

  /// No description provided for @settingsPushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotificationsTitle;

  /// No description provided for @settingsPushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep updates on loads, trips, and verification status.'**
  String get settingsPushNotificationsSubtitle;

  /// No description provided for @settingsAccountSupportSection.
  ///
  /// In en, this message translates to:
  /// **'Account & support'**
  String get settingsAccountSupportSection;

  /// No description provided for @settingsMyProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get settingsMyProfileTitle;

  /// No description provided for @settingsMyProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your role details and verification status.'**
  String get settingsMyProfileSubtitle;

  /// No description provided for @settingsPayoutProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Payout profile'**
  String get settingsPayoutProfileTitle;

  /// No description provided for @settingsPayoutProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage account and payout details.'**
  String get settingsPayoutProfileSubtitle;

  /// No description provided for @payoutAccountHolderLabel.
  ///
  /// In en, this message translates to:
  /// **'Account holder'**
  String get payoutAccountHolderLabel;

  /// No description provided for @payoutAccountLast4Label.
  ///
  /// In en, this message translates to:
  /// **'Account ending'**
  String get payoutAccountLast4Label;

  /// No description provided for @payoutIfscLabel.
  ///
  /// In en, this message translates to:
  /// **'IFSC'**
  String get payoutIfscLabel;

  /// No description provided for @payoutStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get payoutStatusLabel;

  /// No description provided for @payoutNoProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'No payout profile yet'**
  String get payoutNoProfileTitle;

  /// No description provided for @payoutNoProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Payout details will appear here once your financial profile is available.'**
  String get payoutNoProfileSubtitle;

  /// No description provided for @payoutLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load payout profile.'**
  String get payoutLoadError;

  /// No description provided for @settingsHelpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get settingsHelpSupportTitle;

  /// No description provided for @settingsHelpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get support for app issues and account guidance.'**
  String get settingsHelpSupportSubtitle;

  /// No description provided for @supportScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Support screen. Create tickets, track updates, and reply to the support team.'**
  String get supportScreenTtsContext;

  /// No description provided for @supportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Get help from the TranZfort support team'**
  String get supportHeroTitle;

  /// No description provided for @supportHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a ticket for booking, trip, verification, account, or payout issues and track replies here.'**
  String get supportHeroSubtitle;

  /// No description provided for @supportCreateTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a support ticket'**
  String get supportCreateTicketTitle;

  /// No description provided for @supportCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportCategoryLabel;

  /// No description provided for @supportCategoryTechnicalBug.
  ///
  /// In en, this message translates to:
  /// **'Technical bug'**
  String get supportCategoryTechnicalBug;

  /// No description provided for @supportCategoryBookingIssue.
  ///
  /// In en, this message translates to:
  /// **'Booking issue'**
  String get supportCategoryBookingIssue;

  /// No description provided for @supportCategoryTripIssue.
  ///
  /// In en, this message translates to:
  /// **'Trip issue'**
  String get supportCategoryTripIssue;

  /// No description provided for @supportCategoryPaymentPayout.
  ///
  /// In en, this message translates to:
  /// **'Payment or payout'**
  String get supportCategoryPaymentPayout;

  /// No description provided for @supportCategoryVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get supportCategoryVerification;

  /// No description provided for @supportCategoryAccountAccess.
  ///
  /// In en, this message translates to:
  /// **'Account access'**
  String get supportCategoryAccountAccess;

  /// No description provided for @supportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportCategoryOther;

  /// No description provided for @supportSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubjectLabel;

  /// No description provided for @supportSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'Short summary of the issue'**
  String get supportSubjectHint;

  /// No description provided for @supportDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get supportDescriptionLabel;

  /// No description provided for @supportDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened and what help you need.'**
  String get supportDescriptionHint;

  /// No description provided for @supportSubmitTicketAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get supportSubmitTicketAction;

  /// No description provided for @supportMyTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get supportMyTicketsTitle;

  /// No description provided for @supportEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get supportEmptyTitle;

  /// No description provided for @supportEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first ticket and you can track updates from the support team here.'**
  String get supportEmptySubtitle;

  /// No description provided for @supportLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load support tickets. Please try again.'**
  String get supportLoadError;

  /// No description provided for @supportSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject for your ticket.'**
  String get supportSubjectRequired;

  /// No description provided for @supportDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description for your ticket.'**
  String get supportDescriptionRequired;

  /// No description provided for @supportCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit the support ticket. Please try again.'**
  String get supportCreateFailed;

  /// No description provided for @supportTicketSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Support ticket submitted successfully.'**
  String get supportTicketSubmitted;

  /// No description provided for @supportCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get supportCreatedLabel;

  /// No description provided for @supportResolvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportResolvedLabel;

  /// No description provided for @supportTicketIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Ticket ID'**
  String get supportTicketIdLabel;

  /// No description provided for @supportStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportStatusOpen;

  /// No description provided for @supportStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get supportStatusInProgress;

  /// No description provided for @supportStatusResolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportStatusResolved;

  /// No description provided for @supportPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get supportPriorityLow;

  /// No description provided for @supportPriorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get supportPriorityMedium;

  /// No description provided for @supportPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get supportPriorityHigh;

  /// No description provided for @supportPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get supportPriorityUrgent;

  /// No description provided for @supportTicketDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Ticket'**
  String get supportTicketDetailTitle;

  /// No description provided for @supportTicketNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Support ticket not found'**
  String get supportTicketNotFoundTitle;

  /// No description provided for @supportTicketNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This ticket is unavailable or no longer accessible from your account.'**
  String get supportTicketNotFoundSubtitle;

  /// No description provided for @supportResolutionNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolution notes'**
  String get supportResolutionNotesTitle;

  /// No description provided for @supportConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get supportConversationTitle;

  /// No description provided for @supportNoMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies yet. The support team will respond here.'**
  String get supportNoMessagesYet;

  /// No description provided for @supportReplySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a reply'**
  String get supportReplySectionTitle;

  /// No description provided for @supportTicketResolvedReplyClosed.
  ///
  /// In en, this message translates to:
  /// **'This ticket is resolved. Replies are closed for now.'**
  String get supportTicketResolvedReplyClosed;

  /// No description provided for @supportReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Add more details or reply to the support team'**
  String get supportReplyHint;

  /// No description provided for @supportSendReplyAction.
  ///
  /// In en, this message translates to:
  /// **'Send Reply'**
  String get supportSendReplyAction;

  /// No description provided for @supportResolvedTicketReadOnlyAction.
  ///
  /// In en, this message translates to:
  /// **'Resolved ticket'**
  String get supportResolvedTicketReadOnlyAction;

  /// No description provided for @supportReplyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reply before sending.'**
  String get supportReplyRequired;

  /// No description provided for @supportReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send your reply. Please try again.'**
  String get supportReplyFailed;

  /// No description provided for @supportReplySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent successfully.'**
  String get supportReplySent;

  /// No description provided for @supportYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYouLabel;

  /// No description provided for @supportSupportTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Support Team'**
  String get supportSupportTeamLabel;

  /// No description provided for @settingsSupportPending.
  ///
  /// In en, this message translates to:
  /// **'Support screen pending in Sprint 9'**
  String get settingsSupportPending;

  /// No description provided for @settingsAppVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersionTitle;

  /// No description provided for @settingsCurrentBuildPrefix.
  ///
  /// In en, this message translates to:
  /// **'Current build'**
  String get settingsCurrentBuildPrefix;

  /// No description provided for @settingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get settingsDangerZone;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account permanently'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This marks your account for deletion and signs you out immediately.'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsDeleteAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccountAction;

  /// No description provided for @settingsDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get settingsDeleteAccountDialogTitle;

  /// No description provided for @settingsDeleteAccountDialogContent.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all data. This cannot be undone.'**
  String get settingsDeleteAccountDialogContent;

  /// No description provided for @settingsDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteAction;

  /// No description provided for @settingsDeleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to request account deletion'**
  String get settingsDeleteAccountFailed;

  /// No description provided for @settingsSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutAction;

  /// No description provided for @verificationSubmitSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification submitted successfully!'**
  String get verificationSubmitSuccess;

  /// No description provided for @verificationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load verification details. Please try again.'**
  String get verificationLoadError;

  /// No description provided for @retryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// No description provided for @verificationUploadMandatory.
  ///
  /// In en, this message translates to:
  /// **'Please upload all mandatory documents.'**
  String get verificationUploadMandatory;

  /// No description provided for @verificationSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Verification'**
  String get verificationSupplierTitle;

  /// No description provided for @verificationTruckerTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucker Verification'**
  String get verificationTruckerTitle;

  /// No description provided for @verificationSupplierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit business and identity documents to unlock full marketplace access.'**
  String get verificationSupplierSubtitle;

  /// No description provided for @verificationTruckerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload identity and driving documents to activate trip execution privileges.'**
  String get verificationTruckerSubtitle;

  /// No description provided for @verificationDocumentsUploadedSummary.
  ///
  /// In en, this message translates to:
  /// **'{uploaded} of {total} documents uploaded'**
  String verificationDocumentsUploadedSummary(int uploaded, int total);

  /// No description provided for @verificationChooseImageSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose image source'**
  String get verificationChooseImageSourceTitle;

  /// No description provided for @verificationUseCamera.
  ///
  /// In en, this message translates to:
  /// **'Use Camera'**
  String get verificationUseCamera;

  /// No description provided for @verificationUseGallery.
  ///
  /// In en, this message translates to:
  /// **'Use Gallery'**
  String get verificationUseGallery;

  /// No description provided for @verificationAadhaarHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter all 12 digits exactly as on your Aadhaar.'**
  String get verificationAadhaarHelper;

  /// No description provided for @verificationPanHelper.
  ///
  /// In en, this message translates to:
  /// **'PAN format: ABCDE1234F'**
  String get verificationPanHelper;

  /// No description provided for @verificationPanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid PAN (e.g., ABCDE1234F)'**
  String get verificationPanInvalid;

  /// No description provided for @verificationDlHelper.
  ///
  /// In en, this message translates to:
  /// **'Use your driving licence number exactly as printed.'**
  String get verificationDlHelper;

  /// No description provided for @verificationTruckRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Add at least one truck with number, body type, tyres, capacity, and RC photo before verification.'**
  String get verificationTruckRequiredMessage;

  /// No description provided for @verificationVerifiedLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification already approved'**
  String get verificationVerifiedLockedTitle;

  /// No description provided for @verificationVerifiedLockedBody.
  ///
  /// In en, this message translates to:
  /// **'Your details are locked because your verification is approved. Edit only if you need to resubmit for re-verification.'**
  String get verificationVerifiedLockedBody;

  /// No description provided for @verificationEditAndResubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Edit & Re-submit'**
  String get verificationEditAndResubmitAction;

  /// No description provided for @verificationReverificationNotice.
  ///
  /// In en, this message translates to:
  /// **'After updates, your profile will move to pending for re-verification.'**
  String get verificationReverificationNotice;

  /// No description provided for @verificationImageQualityHint.
  ///
  /// In en, this message translates to:
  /// **'Make sure the photo is clear, readable, and fully visible.'**
  String get verificationImageQualityHint;

  /// No description provided for @documentAttachedTapReplace.
  ///
  /// In en, this message translates to:
  /// **'Document attached. Tap to replace.'**
  String get documentAttachedTapReplace;

  /// No description provided for @documentTapUploadRequired.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload required document'**
  String get documentTapUploadRequired;

  /// No description provided for @retakeAction.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakeAction;

  /// No description provided for @uploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadAction;

  /// No description provided for @findLoadsVerifiedTruckRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Verified truck required'**
  String get findLoadsVerifiedTruckRequiredTitle;

  /// No description provided for @findLoadsVerifiedTruckRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'You need a verified truck to book loads. Add a truck now?'**
  String get findLoadsVerifiedTruckRequiredBody;

  /// No description provided for @findLoadsNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get findLoadsNotNow;

  /// No description provided for @findLoadsAddTruck.
  ///
  /// In en, this message translates to:
  /// **'Add Truck'**
  String get findLoadsAddTruck;

  /// No description provided for @findLoadsAnyMaterial.
  ///
  /// In en, this message translates to:
  /// **'Any material'**
  String get findLoadsAnyMaterial;

  /// No description provided for @findLoadsSelectedTruck.
  ///
  /// In en, this message translates to:
  /// **'Selected Truck'**
  String get findLoadsSelectedTruck;

  /// No description provided for @findLoadsConfirmBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get findLoadsConfirmBookingTitle;

  /// No description provided for @findLoadsBookConfirmPrefix.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get findLoadsBookConfirmPrefix;

  /// No description provided for @findLoadsBookConfirmFrom.
  ///
  /// In en, this message translates to:
  /// **'load from'**
  String get findLoadsBookConfirmFrom;

  /// No description provided for @findLoadsBookConfirmTo.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get findLoadsBookConfirmTo;

  /// No description provided for @findLoadsBookConfirmWith.
  ///
  /// In en, this message translates to:
  /// **'with'**
  String get findLoadsBookConfirmWith;

  /// No description provided for @findLoadsAllRoutes.
  ///
  /// In en, this message translates to:
  /// **'All routes'**
  String get findLoadsAllRoutes;

  /// No description provided for @findLoadsAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get findLoadsAny;

  /// No description provided for @findLoadsAnyTruck.
  ///
  /// In en, this message translates to:
  /// **'Any truck'**
  String get findLoadsAnyTruck;

  /// No description provided for @findLoadsSelectTruckForLoad.
  ///
  /// In en, this message translates to:
  /// **'Select a truck for this load'**
  String get findLoadsSelectTruckForLoad;

  /// No description provided for @findLoadsUnknownTruckType.
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get findLoadsUnknownTruckType;

  /// No description provided for @findLoadsTyresSuffix.
  ///
  /// In en, this message translates to:
  /// **'tyres'**
  String get findLoadsTyresSuffix;

  /// No description provided for @findLoadsMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'MATCH'**
  String get findLoadsMatchLabel;

  /// No description provided for @findLoadsMismatchLabel.
  ///
  /// In en, this message translates to:
  /// **'MISMATCH'**
  String get findLoadsMismatchLabel;

  /// No description provided for @findLoadsDashboardTts.
  ///
  /// In en, this message translates to:
  /// **'Find loads dashboard'**
  String get findLoadsDashboardTts;

  /// No description provided for @findLoadsScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Find loads dashboard. Search available loads, apply route filters, and review best matches.'**
  String get findLoadsScreenTtsContext;

  /// No description provided for @findLoadsScreenTtsContextCount.
  ///
  /// In en, this message translates to:
  /// **'Load marketplace. {count} loads found.'**
  String findLoadsScreenTtsContextCount(int count);

  /// No description provided for @findLoadsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Find the right load quickly'**
  String get findLoadsHeroTitle;

  /// No description provided for @findLoadsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use route, cargo and truck filters to discover best matches.'**
  String get findLoadsHeroSubtitle;

  /// No description provided for @findLoadsFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get findLoadsFromLabel;

  /// No description provided for @findLoadsToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get findLoadsToLabel;

  /// No description provided for @findLoadsAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filters'**
  String get findLoadsAdvancedFilters;

  /// No description provided for @findLoadsListViewLabel.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get findLoadsListViewLabel;

  /// No description provided for @findLoadsMapViewLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get findLoadsMapViewLabel;

  /// No description provided for @botCancelResponse.
  ///
  /// In en, this message translates to:
  /// **'Okay, I\'m cancelling the process. Anything else?'**
  String get botCancelResponse;

  /// No description provided for @botMyLoadsResponse.
  ///
  /// In en, this message translates to:
  /// **'Here are your loads.'**
  String get botMyLoadsResponse;

  /// No description provided for @botViewLoadsAction.
  ///
  /// In en, this message translates to:
  /// **'View Loads'**
  String get botViewLoadsAction;

  /// No description provided for @botMyTripsResponse.
  ///
  /// In en, this message translates to:
  /// **'Here are your trips.'**
  String get botMyTripsResponse;

  /// No description provided for @botViewTripsAction.
  ///
  /// In en, this message translates to:
  /// **'View Trips'**
  String get botViewTripsAction;

  /// No description provided for @botCheckStatusResponse.
  ///
  /// In en, this message translates to:
  /// **'Check your booking status here.'**
  String get botCheckStatusResponse;

  /// No description provided for @botCheckStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get botCheckStatusAction;

  /// No description provided for @botHelpResponse.
  ///
  /// In en, this message translates to:
  /// **'I can help you find loads, post loads, and check trips. Try saying \'find load\'.'**
  String get botHelpResponse;

  /// No description provided for @botGreetingResponse.
  ///
  /// In en, this message translates to:
  /// **'Namaste! I am the TranZfort bot. How can I help you today?'**
  String get botGreetingResponse;

  /// No description provided for @botUnknownResponse.
  ///
  /// In en, this message translates to:
  /// **'I didn\'t understand that. You can say \'find load\', \'post load\', or \'trip status\'.'**
  String get botUnknownResponse;

  /// No description provided for @botAskOrigin.
  ///
  /// In en, this message translates to:
  /// **'From where? (Tell me the origin city)'**
  String get botAskOrigin;

  /// No description provided for @botAskDestination.
  ///
  /// In en, this message translates to:
  /// **'To where? (Tell me the destination city)'**
  String get botAskDestination;

  /// No description provided for @botFindLoadSummary.
  ///
  /// In en, this message translates to:
  /// **'Looking for loads from {origin} to {dest}. View them?'**
  String botFindLoadSummary(String origin, String dest);

  /// No description provided for @botAskPostOrigin.
  ///
  /// In en, this message translates to:
  /// **'From where are you sending the load?'**
  String get botAskPostOrigin;

  /// No description provided for @botAskPostDestination.
  ///
  /// In en, this message translates to:
  /// **'Where are you sending it to?'**
  String get botAskPostDestination;

  /// No description provided for @botAskPostMaterial.
  ///
  /// In en, this message translates to:
  /// **'What material are you sending? (e.g., Coal, Steel)'**
  String get botAskPostMaterial;

  /// No description provided for @botPostLoadSummary.
  ///
  /// In en, this message translates to:
  /// **'Post a load for {material} from {origin} to {dest}?'**
  String botPostLoadSummary(String material, String origin, String dest);

  /// No description provided for @supplierDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Dashboard'**
  String get supplierDashboardTitle;

  /// No description provided for @supplierDashboardTts.
  ///
  /// In en, this message translates to:
  /// **'Supplier dashboard'**
  String get supplierDashboardTts;

  /// No description provided for @supplierDashboardTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Supplier dashboard. Review active loads, pending bookings, and overall fulfillment.'**
  String get supplierDashboardTtsContext;

  /// No description provided for @supplierDashboardPendingBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending bookings'**
  String get supplierDashboardPendingBookingsLabel;

  /// No description provided for @supplierDashboardNeedsActionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs your action'**
  String get supplierDashboardNeedsActionTitle;

  /// No description provided for @supplierDashboardRecentLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent load updates'**
  String get supplierDashboardRecentLoadsTitle;

  /// No description provided for @supplierDashboardNoRecentLoads.
  ///
  /// In en, this message translates to:
  /// **'No recent load updates yet.'**
  String get supplierDashboardNoRecentLoads;

  /// No description provided for @truckerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucker Dashboard'**
  String get truckerDashboardTitle;

  /// No description provided for @truckerDashboardTts.
  ///
  /// In en, this message translates to:
  /// **'Trucker dashboard'**
  String get truckerDashboardTts;

  /// No description provided for @truckerDashboardTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Trucker dashboard. Track active bids, upcoming trips, and overall fulfillment.'**
  String get truckerDashboardTtsContext;

  /// No description provided for @findLoadsOriginCity.
  ///
  /// In en, this message translates to:
  /// **'Origin City'**
  String get findLoadsOriginCity;

  /// No description provided for @findLoadsSortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get findLoadsSortByLabel;

  /// No description provided for @findLoadsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get findLoadsSortNewest;

  /// No description provided for @findLoadsSortPriceHighLow.
  ///
  /// In en, this message translates to:
  /// **'Price High-Low'**
  String get findLoadsSortPriceHighLow;

  /// No description provided for @findLoadsSortPriceLowHigh.
  ///
  /// In en, this message translates to:
  /// **'Price Low-High'**
  String get findLoadsSortPriceLowHigh;

  /// No description provided for @findLoadsSortPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get findLoadsSortPickupDate;

  /// No description provided for @findLoadsMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get findLoadsMaterialLabel;

  /// No description provided for @findLoadsTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get findLoadsTruckLabel;

  /// No description provided for @findLoadsActiveFiltersSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} filters active'**
  String findLoadsActiveFiltersSummary(int count);

  /// No description provided for @findLoadsMaterialCoal.
  ///
  /// In en, this message translates to:
  /// **'Coal'**
  String get findLoadsMaterialCoal;

  /// No description provided for @findLoadsMaterialSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get findLoadsMaterialSteel;

  /// No description provided for @findLoadsMaterialCement.
  ///
  /// In en, this message translates to:
  /// **'Cement'**
  String get findLoadsMaterialCement;

  /// No description provided for @findLoadsMaterialSand.
  ///
  /// In en, this message translates to:
  /// **'Sand'**
  String get findLoadsMaterialSand;

  /// No description provided for @findLoadsViewListLabel.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get findLoadsViewListLabel;

  /// No description provided for @findLoadsViewMapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get findLoadsViewMapLabel;

  /// No description provided for @findLoadsSaveSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Save Search'**
  String get findLoadsSaveSearchAction;

  /// No description provided for @findLoadsSavedSearchesLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved searches'**
  String get findLoadsSavedSearchesLabel;

  /// No description provided for @findLoadsSavedSearchSaved.
  ///
  /// In en, this message translates to:
  /// **'Search saved.'**
  String get findLoadsSavedSearchSaved;

  /// No description provided for @findLoadsSavedSearchSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save search.'**
  String get findLoadsSavedSearchSaveFailed;

  /// No description provided for @findLoadsSavedSearchDeleted.
  ///
  /// In en, this message translates to:
  /// **'Saved search removed.'**
  String get findLoadsSavedSearchDeleted;

  /// No description provided for @findLoadsSavedSearchDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove saved search.'**
  String get findLoadsSavedSearchDeleteFailed;

  /// No description provided for @myFleetTitle.
  ///
  /// In en, this message translates to:
  /// **'My Fleet'**
  String get myFleetTitle;

  /// No description provided for @myFleetAddTruckTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Truck'**
  String get myFleetAddTruckTooltip;

  /// No description provided for @myFleetDashboardTts.
  ///
  /// In en, this message translates to:
  /// **'Fleet dashboard'**
  String get myFleetDashboardTts;

  /// No description provided for @myFleetScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Fleet dashboard. Manage trucks, compliance details, and current availability.'**
  String get myFleetScreenTtsContext;

  /// No description provided for @myFleetScreenTtsContextCount.
  ///
  /// In en, this message translates to:
  /// **'Your fleet. {count} trucks.'**
  String myFleetScreenTtsContextCount(int count);

  /// No description provided for @myFleetEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trucks yet'**
  String get myFleetEmptyTitle;

  /// No description provided for @myFleetEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first truck.'**
  String get myFleetEmptySubtitle;

  /// No description provided for @myFleetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load fleet'**
  String get myFleetLoadError;

  /// No description provided for @myFleetHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your fleet verification-ready'**
  String get myFleetHeroTitle;

  /// No description provided for @myFleetHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review status, rejection remarks, and truck details before booking loads.'**
  String get myFleetHeroSubtitle;

  /// No description provided for @myFleetBodyLabel.
  ///
  /// In en, this message translates to:
  /// **'Body: {body}'**
  String myFleetBodyLabel(Object body);

  /// No description provided for @myFleetTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {tyres}'**
  String myFleetTyresLabel(Object tyres);

  /// No description provided for @myFleetCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity: {capacity} T'**
  String myFleetCapacityLabel(Object capacity);

  /// No description provided for @myFleetRejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason: {reason}'**
  String myFleetRejectionReasonLabel(Object reason);

  /// No description provided for @myFleetRcExpiredWarning.
  ///
  /// In en, this message translates to:
  /// **'RC expired. Renew this truck document to avoid dispatch issues.'**
  String get myFleetRcExpiredWarning;

  /// No description provided for @myFleetRcExpiryWarningDays.
  ///
  /// In en, this message translates to:
  /// **'RC expires in {days} day(s). Please renew soon.'**
  String myFleetRcExpiryWarningDays(int days);

  /// No description provided for @addTruckTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Truck'**
  String get addTruckTitle;

  /// No description provided for @addTruckHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your truck details'**
  String get addTruckHeroTitle;

  /// No description provided for @addTruckHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep fleet information complete to improve booking confidence.'**
  String get addTruckHeroSubtitle;

  /// No description provided for @addTruckIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'Truck identity'**
  String get addTruckIdentitySection;

  /// No description provided for @addTruckNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck Number'**
  String get addTruckNumberLabel;

  /// No description provided for @addTruckNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Truck number is required'**
  String get addTruckNumberRequired;

  /// No description provided for @addTruckBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body Type'**
  String get addTruckBodyTypeLabel;

  /// No description provided for @addTruckModelManualEntryOption.
  ///
  /// In en, this message translates to:
  /// **'Not in list / manual entry'**
  String get addTruckModelManualEntryOption;

  /// No description provided for @addTruckModelOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck Model (optional)'**
  String get addTruckModelOptionalLabel;

  /// No description provided for @addTruckCatalogLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load truck catalog. Please try again.'**
  String get addTruckCatalogLoadError;

  /// No description provided for @addTruckSpecificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Specifications'**
  String get addTruckSpecificationsSection;

  /// No description provided for @addTruckTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres'**
  String get addTruckTyresLabel;

  /// No description provided for @addTruckTyresRangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter tyres between 4 and 22'**
  String get addTruckTyresRangeError;

  /// No description provided for @addTruckCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity (T)'**
  String get addTruckCapacityLabel;

  /// No description provided for @addTruckCapacityInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid capacity'**
  String get addTruckCapacityInvalid;

  /// No description provided for @addTruckDocumentsSection.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get addTruckDocumentsSection;

  /// No description provided for @addTruckUploadRcPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload RC Photo'**
  String get addTruckUploadRcPhoto;

  /// No description provided for @addTruckRcExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'RC expiry date'**
  String get addTruckRcExpiryDateLabel;

  /// No description provided for @addTruckSelectDateAction.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get addTruckSelectDateAction;

  /// No description provided for @addTruckRcUploadedReplace.
  ///
  /// In en, this message translates to:
  /// **'RC uploaded. Tap to replace.'**
  String get addTruckRcUploadedReplace;

  /// No description provided for @addTruckRcRequired.
  ///
  /// In en, this message translates to:
  /// **'RC photo is required to keep truck details complete.'**
  String get addTruckRcRequired;

  /// No description provided for @addTruckSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save Truck'**
  String get addTruckSaveAction;

  /// No description provided for @addTruckSelectBodyTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select body type'**
  String get addTruckSelectBodyTypeError;

  /// No description provided for @addTruckSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add truck. Please try again.'**
  String get addTruckSaveFailed;

  /// No description provided for @loadDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load detail'**
  String get loadDetailLoadError;

  /// No description provided for @loadDetailTripCostUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Trip cost unavailable'**
  String get loadDetailTripCostUnavailable;

  /// No description provided for @loadDetailTripCostBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Trip Cost Breakdown'**
  String get loadDetailTripCostBreakdown;

  /// No description provided for @loadDetailTripCostDiesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get loadDetailTripCostDiesel;

  /// No description provided for @loadDetailTripCostTolls.
  ///
  /// In en, this message translates to:
  /// **'Tolls'**
  String get loadDetailTripCostTolls;

  /// No description provided for @loadDetailTripCostTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get loadDetailTripCostTotal;

  /// No description provided for @loadDetailTripCostMileage.
  ///
  /// In en, this message translates to:
  /// **'Mileage'**
  String get loadDetailTripCostMileage;

  /// No description provided for @loadDetailPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get loadDetailPendingApproval;

  /// No description provided for @loadDetailBookingApproved.
  ///
  /// In en, this message translates to:
  /// **'Booking approved'**
  String get loadDetailBookingApproved;

  /// No description provided for @loadDetailApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Approve failed'**
  String get loadDetailApproveFailed;

  /// No description provided for @loadDetailBookingRejected.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected'**
  String get loadDetailBookingRejected;

  /// No description provided for @loadDetailRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Reject failed'**
  String get loadDetailRejectFailed;

  /// No description provided for @loadDetailNoPendingBookings.
  ///
  /// In en, this message translates to:
  /// **'No pending bookings.'**
  String get loadDetailNoPendingBookings;

  /// No description provided for @loadDetailInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get loadDetailInTransit;

  /// No description provided for @loadDetailTripInTransit.
  ///
  /// In en, this message translates to:
  /// **'Trip is in transit'**
  String get loadDetailTripInTransit;

  /// No description provided for @loadDetailPodUploaded.
  ///
  /// In en, this message translates to:
  /// **'POD Uploaded'**
  String get loadDetailPodUploaded;

  /// No description provided for @loadDetailConfirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get loadDetailConfirmDelivery;

  /// No description provided for @loadDetailDeliveryConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Delivery confirmed.'**
  String get loadDetailDeliveryConfirmed;

  /// No description provided for @loadDetailDeliveryConfirmFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm delivery.'**
  String get loadDetailDeliveryConfirmFailed;

  /// No description provided for @loadDetailDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get loadDetailDelivered;

  /// No description provided for @loadDetailTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get loadDetailTruckLabel;

  /// No description provided for @loadDetailApproveAction.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get loadDetailApproveAction;

  /// No description provided for @loadDetailRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get loadDetailRejectAction;

  /// No description provided for @loadDetailStatusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get loadDetailStatusPrefix;

  /// No description provided for @richLoadCardTripCostEstimate.
  ///
  /// In en, this message translates to:
  /// **'Est. Trip Cost: {amount}'**
  String richLoadCardTripCostEstimate(Object amount);

  /// No description provided for @richLoadCardSuperLoadLabel.
  ///
  /// In en, this message translates to:
  /// **'Super Load'**
  String get richLoadCardSuperLoadLabel;

  /// No description provided for @richLoadCardVerifiedSupplierFallback.
  ///
  /// In en, this message translates to:
  /// **'Verified Supplier'**
  String get richLoadCardVerifiedSupplierFallback;

  /// No description provided for @richLoadCardPickupPrefix.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get richLoadCardPickupPrefix;

  /// No description provided for @richLoadCardTrucksNeededSummary.
  ///
  /// In en, this message translates to:
  /// **'{needed} trucks needed · {booked} booked'**
  String richLoadCardTrucksNeededSummary(int needed, int booked);

  /// No description provided for @richLoadCardAdvanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Advance: -'**
  String get richLoadCardAdvanceUnavailable;

  /// No description provided for @richLoadCardAdvanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance: {percentage}% ({amount})'**
  String richLoadCardAdvanceLabel(int percentage, Object amount);

  /// No description provided for @richLoadCardJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get richLoadCardJustNow;

  /// No description provided for @profileScreenTts.
  ///
  /// In en, this message translates to:
  /// **'Profile screen'**
  String get profileScreenTts;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'No profile found.'**
  String get profileNotFound;

  /// No description provided for @profileDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'TranZfort User'**
  String get profileDefaultUserName;

  /// No description provided for @profileVerifiedChip.
  ///
  /// In en, this message translates to:
  /// **'VERIFIED'**
  String get profileVerifiedChip;

  /// No description provided for @profileVerificationChip.
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION {status}'**
  String profileVerificationChip(Object status);

  /// No description provided for @profileSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile summary'**
  String get profileSummaryTitle;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get profileStatusLabel;

  /// No description provided for @profileMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get profileMobileLabel;

  /// No description provided for @profileValueNa.
  ///
  /// In en, this message translates to:
  /// **'NA'**
  String get profileValueNa;

  /// No description provided for @profileValueSet.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get profileValueSet;

  /// No description provided for @profileIdentityDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity details'**
  String get profileIdentityDetailsTitle;

  /// No description provided for @profileFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get profileFullNameLabel;

  /// No description provided for @profileVerificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get profileVerificationLabel;

  /// No description provided for @profileQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get profileQuickActionsTitle;

  /// No description provided for @profileDocumentExpiryTitle.
  ///
  /// In en, this message translates to:
  /// **'Document expiry alerts'**
  String get profileDocumentExpiryTitle;

  /// No description provided for @profileDlExpiredWarning.
  ///
  /// In en, this message translates to:
  /// **'Driving licence has expired. Update verification documents now.'**
  String get profileDlExpiredWarning;

  /// No description provided for @profileDlExpiryWarningDays.
  ///
  /// In en, this message translates to:
  /// **'Driving licence expires in {days} day(s). Please renew and re-upload.'**
  String profileDlExpiryWarningDays(int days);

  /// No description provided for @profileSupplierVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Supplier verification'**
  String get profileSupplierVerificationAction;

  /// No description provided for @profileTruckerVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Trucker verification'**
  String get profileTruckerVerificationAction;

  /// No description provided for @profileVerificationActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage your verification documents.'**
  String get profileVerificationActionSubtitle;

  /// No description provided for @profileSettingsActionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open app preferences and account controls.'**
  String get profileSettingsActionSubtitle;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile.'**
  String get profileLoadError;

  /// No description provided for @notificationsMarkAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllAsRead;

  /// No description provided for @notificationsScreenTts.
  ///
  /// In en, this message translates to:
  /// **'Notifications screen'**
  String get notificationsScreenTts;

  /// No description provided for @notificationsScreenTtsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new notifications.'**
  String notificationsScreenTtsCount(int count);

  /// No description provided for @notificationsAllCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get notificationsAllCaughtUpTitle;

  /// No description provided for @notificationsAllCaughtUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have no new notifications.'**
  String get notificationsAllCaughtUpSubtitle;

  /// No description provided for @notificationsUnreadUpdates.
  ///
  /// In en, this message translates to:
  /// **'{count} unread updates'**
  String notificationsUnreadUpdates(int count);

  /// No description provided for @notificationsCaughtUpBanner.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get notificationsCaughtUpBanner;

  /// No description provided for @notificationsRealtimeHint.
  ///
  /// In en, this message translates to:
  /// **'Trip, load, and chat alerts appear here in real time.'**
  String get notificationsRealtimeHint;

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load notifications'**
  String get notificationsLoadError;

  /// No description provided for @notificationsTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String notificationsTimeDaysAgo(int days);

  /// No description provided for @notificationsTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String notificationsTimeHoursAgo(int hours);

  /// No description provided for @notificationsTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String notificationsTimeMinutesAgo(int minutes);

  /// No description provided for @notificationsTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationsTimeJustNow;

  /// No description provided for @routePreviewOpenMapsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Google Maps'**
  String get routePreviewOpenMapsFailed;

  /// No description provided for @routePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Route Preview'**
  String get routePreviewTitle;

  /// No description provided for @routePreviewDetailsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Route details not available.'**
  String get routePreviewDetailsUnavailable;

  /// No description provided for @routePreviewFallbackWarning.
  ///
  /// In en, this message translates to:
  /// **'Showing direct line. Real route calculation failed.'**
  String get routePreviewFallbackWarning;

  /// No description provided for @routePreviewStartNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation in Google Maps'**
  String get routePreviewStartNavigation;

  /// No description provided for @routePreviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading route.'**
  String get routePreviewLoadError;

  /// No description provided for @routePreviewScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Route from {origin} to {destination}.'**
  String routePreviewScreenTtsContext(Object origin, Object destination);

  /// No description provided for @postLoadStepTtsRoute.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Enter pickup and delivery cities.'**
  String get postLoadStepTtsRoute;

  /// No description provided for @postLoadStepTtsCargo.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Select material and enter weight.'**
  String get postLoadStepTtsCargo;

  /// No description provided for @postLoadStepTtsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Choose truck type and tyre size.'**
  String get postLoadStepTtsSchedule;

  /// No description provided for @postLoadStepTtsPricing.
  ///
  /// In en, this message translates to:
  /// **'Step 4: Set your price, advance, and pickup date.'**
  String get postLoadStepTtsPricing;

  /// No description provided for @postLoadTtsSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load posted successfully.'**
  String get postLoadTtsSuccess;

  /// No description provided for @postLoadTtsFailure.
  ///
  /// In en, this message translates to:
  /// **'Load posting failed. Please try again.'**
  String get postLoadTtsFailure;

  /// No description provided for @loadDetailScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Load from {origin} to {destination}. {material}, {weight}T. Price: rupees {price}.'**
  String loadDetailScreenTtsContext(
    Object origin,
    Object destination,
    Object material,
    Object weight,
    Object price,
  );

  /// No description provided for @tripDetailScreenTtsContext.
  ///
  /// In en, this message translates to:
  /// **'Trip from {origin} to {destination}. Stage: {stage}. Next: {nextAction}.'**
  String tripDetailScreenTtsContext(
    Object origin,
    Object destination,
    Object stage,
    Object nextAction,
  );

  /// No description provided for @verificationCompanyDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Company details'**
  String get verificationCompanyDetailsSection;

  /// No description provided for @verificationProfilePhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Photo'**
  String get verificationProfilePhotoLabel;

  /// No description provided for @verificationCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get verificationCompanyNameLabel;

  /// No description provided for @verificationGstNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'GST Number'**
  String get verificationGstNumberLabel;

  /// No description provided for @verificationUploadGstCertificate.
  ///
  /// In en, this message translates to:
  /// **'Upload GST Certificate'**
  String get verificationUploadGstCertificate;

  /// No description provided for @verificationTaxDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Tax details'**
  String get verificationTaxDetailsSection;

  /// No description provided for @verificationIdentityDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Identity details'**
  String get verificationIdentityDetailsSection;

  /// No description provided for @verificationPanNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get verificationPanNumberLabel;

  /// No description provided for @verificationUploadPanCard.
  ///
  /// In en, this message translates to:
  /// **'Upload PAN Card'**
  String get verificationUploadPanCard;

  /// No description provided for @verificationTanNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'TAN Number'**
  String get verificationTanNumberLabel;

  /// No description provided for @verificationTanHelper.
  ///
  /// In en, this message translates to:
  /// **'TAN format: 10 characters alphanumeric'**
  String get verificationTanHelper;

  /// No description provided for @verificationTanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid TAN (10 characters)'**
  String get verificationTanInvalid;

  /// No description provided for @verificationGstInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid GST number (15 characters)'**
  String get verificationGstInvalid;

  /// No description provided for @verificationUploadTanCard.
  ///
  /// In en, this message translates to:
  /// **'Upload TAN Card'**
  String get verificationUploadTanCard;

  /// No description provided for @verificationAadhaarNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Number'**
  String get verificationAadhaarNumberLabel;

  /// No description provided for @verificationUploadAadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar Front'**
  String get verificationUploadAadhaarFront;

  /// No description provided for @verificationUploadAadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar Back'**
  String get verificationUploadAadhaarBack;

  /// No description provided for @verificationOptionalBusinessProofSection.
  ///
  /// In en, this message translates to:
  /// **'Optional business proof'**
  String get verificationOptionalBusinessProofSection;

  /// No description provided for @verificationBusinessLicenceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Licence Number'**
  String get verificationBusinessLicenceNumberLabel;

  /// No description provided for @verificationUploadBusinessLicence.
  ///
  /// In en, this message translates to:
  /// **'Upload Business Licence'**
  String get verificationUploadBusinessLicence;

  /// No description provided for @verificationDrivingLicenseSection.
  ///
  /// In en, this message translates to:
  /// **'Driving license details'**
  String get verificationDrivingLicenseSection;

  /// No description provided for @verificationDlNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'DL Number'**
  String get verificationDlNumberLabel;

  /// No description provided for @verificationDlExpiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'DL expiry date'**
  String get verificationDlExpiryDateLabel;

  /// No description provided for @verificationSelectDateAction.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get verificationSelectDateAction;

  /// No description provided for @verificationUploadDlFront.
  ///
  /// In en, this message translates to:
  /// **'Upload DL Front'**
  String get verificationUploadDlFront;

  /// No description provided for @verificationUploadDlBack.
  ///
  /// In en, this message translates to:
  /// **'Upload DL Back'**
  String get verificationUploadDlBack;

  /// No description provided for @verificationSupplierTtsProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload your supplier profile photo.'**
  String get verificationSupplierTtsProfilePhoto;

  /// No description provided for @verificationSupplierTtsCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Enter your company name as registered.'**
  String get verificationSupplierTtsCompanyName;

  /// No description provided for @verificationSupplierTtsGstNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your GST number.'**
  String get verificationSupplierTtsGstNumber;

  /// No description provided for @verificationSupplierTtsTanNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your TAN number.'**
  String get verificationSupplierTtsTanNumber;

  /// No description provided for @verificationSupplierTtsGstCertificate.
  ///
  /// In en, this message translates to:
  /// **'Upload your GST certificate image.'**
  String get verificationSupplierTtsGstCertificate;

  /// No description provided for @verificationSupplierTtsTanCard.
  ///
  /// In en, this message translates to:
  /// **'Upload your TAN card photo.'**
  String get verificationSupplierTtsTanCard;

  /// No description provided for @verificationSupplierTtsPanNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your PAN number in the format A B C D E 1 2 3 4 F.'**
  String get verificationSupplierTtsPanNumber;

  /// No description provided for @verificationSupplierTtsPanCard.
  ///
  /// In en, this message translates to:
  /// **'Upload your PAN card image.'**
  String get verificationSupplierTtsPanCard;

  /// No description provided for @verificationSupplierTtsAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-digit Aadhaar number.'**
  String get verificationSupplierTtsAadhaarNumber;

  /// No description provided for @verificationSupplierTtsAadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Upload the front side of your Aadhaar card.'**
  String get verificationSupplierTtsAadhaarFront;

  /// No description provided for @verificationSupplierTtsAadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Upload the back side of your Aadhaar card.'**
  String get verificationSupplierTtsAadhaarBack;

  /// No description provided for @verificationSupplierTtsBusinessLicenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your business licence number if available.'**
  String get verificationSupplierTtsBusinessLicenceNumber;

  /// No description provided for @verificationSupplierTtsBusinessLicenceDoc.
  ///
  /// In en, this message translates to:
  /// **'Upload your business licence document if available.'**
  String get verificationSupplierTtsBusinessLicenceDoc;

  /// No description provided for @verificationTruckerTtsProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload your trucker profile photo.'**
  String get verificationTruckerTtsProfilePhoto;

  /// No description provided for @verificationTruckerTtsAadhaarNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your 12-digit Aadhaar number.'**
  String get verificationTruckerTtsAadhaarNumber;

  /// No description provided for @verificationTruckerTtsAadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Upload the front side of your Aadhaar card.'**
  String get verificationTruckerTtsAadhaarFront;

  /// No description provided for @verificationTruckerTtsAadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Upload the back side of your Aadhaar card.'**
  String get verificationTruckerTtsAadhaarBack;

  /// No description provided for @verificationTruckerTtsPanNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your PAN number in the format A B C D E 1 2 3 4 F.'**
  String get verificationTruckerTtsPanNumber;

  /// No description provided for @verificationTruckerTtsPanCard.
  ///
  /// In en, this message translates to:
  /// **'Upload your PAN card image.'**
  String get verificationTruckerTtsPanCard;

  /// No description provided for @verificationTruckerTtsDlNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your driving licence number exactly as printed.'**
  String get verificationTruckerTtsDlNumber;

  /// No description provided for @verificationTruckerTtsDlFront.
  ///
  /// In en, this message translates to:
  /// **'Upload the front side of your driving licence.'**
  String get verificationTruckerTtsDlFront;

  /// No description provided for @verificationTruckerTtsDlBack.
  ///
  /// In en, this message translates to:
  /// **'Upload the back side of your driving licence.'**
  String get verificationTruckerTtsDlBack;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
