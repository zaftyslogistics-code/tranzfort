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

  /// App Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'TranZfort'**
  String get appTitle;

  /// Splash Loading Workspace - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loading your workspace...'**
  String get splashLoadingWorkspace;

  /// Auth Google Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not continue with Google right now. Retry shortly or use email sign-in instead.'**
  String get authGoogleFailureMessage;

  /// Auth Welcome Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TranZfort'**
  String get authWelcomeTitle;

  /// Auth Welcome Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose Google or email sign-in to continue into your supplier or trucker workspace.'**
  String get authWelcomeSubtitle;

  /// Auth Email Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// Auth Sign In Divider Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get authSignInDividerLabel;

  /// Auth Forgot Password Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordAction;

  /// Auth Config Incomplete Sign In Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured in this build, so sign-in and live account data will remain unavailable until the environment is fixed.'**
  String get authConfigIncompleteSignInMessage;

  /// Splash Setup Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Set up device access'**
  String get splashSetupTitle;

  /// Splash Setup Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications, voice guidance, and location access now so your first login and verification flow can continue smoothly.'**
  String get splashSetupSubtitle;

  /// Splash Setup Enable Voice Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enable voice guidance'**
  String get splashSetupEnableVoiceAction;

  /// Splash Setup Open Location Settings Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open location settings'**
  String get splashSetupOpenLocationSettingsAction;

  /// Auth Continue With Google - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Auth Continue With Password - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Continue with email and password'**
  String get authContinueWithPassword;

  /// Auth Terms Of Service - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get authTermsOfService;

  /// Auth Terms Info Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'TranZfort access is currently limited to verified supplier and trucker workflows. Continue only if you agree to the platform terms.'**
  String get authTermsInfoMessage;

  /// Auth Password Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Email and password'**
  String get authPasswordTitle;

  /// Auth Password Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email and password, or create a new TranZfort account to continue.'**
  String get authPasswordSubtitle;

  /// Auth Password Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Auth Password Confirm Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authPasswordConfirmLabel;

  /// Auth Password Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 8 characters'**
  String get authPasswordHint;

  /// Auth Password Mode Sign In - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authPasswordModeSignIn;

  /// Auth Password Mode Sign Up - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authPasswordModeSignUp;

  /// Auth Password Switch To Sign In - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authPasswordSwitchToSignIn;

  /// Auth Password Switch To Sign Up - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'New to TranZfort? Create account'**
  String get authPasswordSwitchToSignUp;

  /// Auth Password Sign In Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get authPasswordSignInAction;

  /// Auth Password Sign Up Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authPasswordSignUpAction;

  /// Auth Password Invalid Email Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authPasswordInvalidEmailMessage;

  /// Auth Password Too Short Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter a password with at least 8 characters.'**
  String get authPasswordTooShortMessage;

  /// Auth Password Confirm Mismatch Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The password confirmation does not match.'**
  String get authPasswordConfirmMismatchMessage;

  /// Auth Password Sign In Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you in with email and password right now. Retry shortly or use another sign-in method.'**
  String get authPasswordSignInFailureMessage;

  /// Auth Password Sign Up Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not create your account right now. Retry shortly with the same details.'**
  String get authPasswordSignUpFailureMessage;

  /// Auth Password Sign Up Success Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account was created. If email confirmation is required, finish that step and then sign in with your new password.'**
  String get authPasswordSignUpSuccessMessage;

  /// Auth Password Check Email Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authPasswordCheckEmailTitle;

  /// Instruction for user to check their email for verification link. Placeholder {email} is the user's email address.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Open that email, finish verification, and then return here to sign in.'**
  String authPasswordCheckEmailSubtitle(Object email);

  /// Auth Password Resend Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get authPasswordResendVerificationAction;

  /// Success message after resending verification email. Placeholder {email} is the recipient's email address.
  ///
  /// In en, this message translates to:
  /// **'We sent a fresh verification email to {email}. Open it, finish verification, and then sign in.'**
  String authPasswordResendVerificationSuccessMessage(Object email);

  /// Auth Password Resend Verification Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not resend the verification email right now. Retry shortly or use a different email.'**
  String get authPasswordResendVerificationFailureMessage;

  /// Auth Password Back To Sign In Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authPasswordBackToSignInAction;

  /// Auth Password Use Different Email Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get authPasswordUseDifferentEmailAction;

  /// Onboarding Select Role Error - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select whether you are joining as a supplier or trucker.'**
  String get onboardingSelectRoleError;

  /// Onboarding Role Workspace Failure - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not prepare your role workspace right now. Retry shortly after selecting your role again.'**
  String get onboardingRoleWorkspaceFailure;

  /// Onboarding Role Save Failure - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not save your role right now. Retry shortly.'**
  String get onboardingRoleSaveFailure;

  /// Onboarding Choose Role Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose role'**
  String get onboardingChooseRoleTitle;

  /// Onboarding Role Question - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Which role fits your work?'**
  String get onboardingRoleQuestion;

  /// Explains that user's role determines available tools and dashboard.
  ///
  /// In en, this message translates to:
  /// **'Your role decides the tools, dashboard, and workflows TranZfort will prepare for you.'**
  String get onboardingRoleSubtitle;

  /// Onboarding Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get onboardingSupplierTitle;

  /// Onboarding Supplier Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Post loads, review bookings, manage trips, and track delivery follow-through.'**
  String get onboardingSupplierSubtitle;

  /// Onboarding Trucker Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker'**
  String get onboardingTruckerTitle;

  /// Onboarding Trucker Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Find loads, manage fleet readiness, and execute active trips from one place.'**
  String get onboardingTruckerSubtitle;

  /// Onboarding Continue - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Onboarding Profile Save Failure - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not save your profile right now. Review the details and retry shortly.'**
  String get onboardingProfileSaveFailure;

  /// Onboarding Complete Profile Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get onboardingCompleteProfileTitle;

  /// Onboarding Complete Profile Heading - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Finish your basic profile'**
  String get onboardingCompleteProfileHeading;

  /// Onboarding Complete Profile Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add the core contact details that will follow you through verification and daily operations.'**
  String get onboardingCompleteProfileSubtitle;

  /// Onboarding Full Name Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get onboardingFullNameLabel;

  /// Onboarding Full Name Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get onboardingFullNameHint;

  /// Onboarding Mobile Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get onboardingMobileLabel;

  /// Onboarding Terms Acceptance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you confirm that your basic profile details are accurate and that you agree to the platform terms.'**
  String get onboardingTermsAcceptance;

  /// Onboarding Save And Continue - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get onboardingSaveAndContinue;

  /// Common Retry - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Shell Tooltip Voice Assistance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice assistance'**
  String get shellTooltipVoiceAssistance;

  /// Supplier Quick Action Notifications - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get supplierQuickActionNotifications;

  /// Supplier My Loads Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'My loads'**
  String get supplierMyLoadsTitle;

  /// Supplier My Loads Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Monitor active supplier loads, booking demand, and completed load history from one place.'**
  String get supplierMyLoadsSubtitle;

  /// Supplier My Loads Tab Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get supplierMyLoadsTabActive;

  /// Supplier My Loads Tab Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get supplierMyLoadsTabCompleted;

  /// Supplier My Loads Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your supplier loads'**
  String get supplierMyLoadsLoadFailureTitle;

  /// Supplier My Loads Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your supplier loads right now. Retry shortly to refresh the latest load list.'**
  String get supplierMyLoadsFailureMessage;

  /// Supplier My Loads Empty Active Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No active loads yet'**
  String get supplierMyLoadsEmptyActiveTitle;

  /// Supplier My Loads Empty Completed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No completed loads yet'**
  String get supplierMyLoadsEmptyCompletedTitle;

  /// Supplier My Loads Empty Active Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Post your first load to start receiving booking requests and execution updates here.'**
  String get supplierMyLoadsEmptyActiveSubtitle;

  /// Supplier My Loads Empty Completed Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed, cancelled, expired, and externally filled loads will appear here once active work is closed out.'**
  String get supplierMyLoadsEmptyCompletedSubtitle;

  /// Supplier My Loads Open Active Loads - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open active loads'**
  String get supplierMyLoadsOpenActiveLoads;

  /// Supplier My Loads More Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load more supplier loads'**
  String get supplierMyLoadsMoreUnavailableTitle;

  /// Supplier My Loads Pagination Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load more supplier loads right now. Retry shortly to refresh the latest load history.'**
  String get supplierMyLoadsPaginationFailureMessage;

  /// Supplier My Loads Loading More - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loading more loads...'**
  String get supplierMyLoadsLoadingMore;

  /// Supplier My Loads Load More - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load more loads'**
  String get supplierMyLoadsLoadMore;

  /// Supplier Load Card Pickup Date - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup {value}'**
  String supplierLoadCardPickupDate(Object value);

  /// Supplier Load Card Trucks - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{booked}/{needed} trucks booked'**
  String supplierLoadCardTrucks(Object booked, Object needed);

  /// Supplier Load Card Track Load - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track load'**
  String get supplierLoadCardTrackLoad;

  /// Supplier Load Card View History - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get supplierLoadCardViewHistory;

  /// Supplier Load Card View Details - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get supplierLoadCardViewDetails;

  /// Supplier Recent Loads Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recent loads'**
  String get supplierRecentLoadsTitle;

  /// Welcome message on supplier dashboard. Placeholder {name} is the user's display name.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String supplierDashboardWelcomeBack(Object name);

  /// Supplier Dashboard Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track supplier verification, review Super Load readiness, and keep your latest loads and execution activity in view.'**
  String get supplierDashboardHeroSubtitle;

  /// Supplier Dashboard Overview Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dashboard overview'**
  String get supplierDashboardOverviewTitle;

  /// Supplier Dashboard Super Load Readiness Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Load readiness'**
  String get supplierDashboardSuperLoadReadinessTitle;

  /// Supplier Dashboard Quick Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get supplierDashboardQuickActionsTitle;

  /// Supplier Dashboard Quick Action Chat Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get supplierDashboardQuickActionChatLabel;

  /// Supplier Dashboard Post Load Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get supplierDashboardPostLoadAction;

  /// Supplier Dashboard Hero Summary Body - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep your supplier verification current, monitor active loads, and follow the latest Super Load readiness signals visible in this workspace.'**
  String get supplierDashboardHeroSummaryBody;

  /// Supplier Dashboard Stats Active Loads Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active loads'**
  String get supplierDashboardStatsActiveLoadsLabel;

  /// Supplier Dashboard Stats Active Loads Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loads currently open for supplier-side tracking.'**
  String get supplierDashboardStatsActiveLoadsHelper;

  /// Supplier Dashboard Stats Pending Bookings Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending bookings'**
  String get supplierDashboardStatsPendingBookingsLabel;

  /// Supplier Dashboard Stats Pending Bookings Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking requests that still need supplier attention.'**
  String get supplierDashboardStatsPendingBookingsHelper;

  /// Supplier Dashboard Stats In Transit Trips Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips in transit'**
  String get supplierDashboardStatsInTransitTripsLabel;

  /// Supplier Dashboard Stats In Transit Trips Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Linked trips currently moving against your loads.'**
  String get supplierDashboardStatsInTransitTripsHelper;

  /// Supplier Dashboard Stats Completed Trips Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed trips'**
  String get supplierDashboardStatsCompletedTripsLabel;

  /// Supplier Dashboard Stats Completed Trips Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips that have reached their recorded completion state.'**
  String get supplierDashboardStatsCompletedTripsHelper;

  /// Supplier Dashboard Open My Loads Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open my loads'**
  String get supplierDashboardOpenMyLoadsAction;

  /// Supplier Dashboard Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your supplier dashboard'**
  String get supplierDashboardLoadFailureTitle;

  /// Supplier Dashboard Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your supplier dashboard right now. Retry shortly to refresh the latest overview metrics.'**
  String get supplierDashboardLoadFailureMessage;

  /// Supplier Dashboard Account State Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier account state unavailable'**
  String get supplierDashboardAccountStateUnavailableTitle;

  /// Supplier Dashboard Account State Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your current supplier account state right now. Retry shortly to restore the latest verification and company details.'**
  String get supplierDashboardAccountStateUnavailableMessage;

  /// Supplier Dashboard Recent Loads Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recent loads unavailable'**
  String get supplierDashboardRecentLoadsUnavailableTitle;

  /// Supplier Dashboard Recent Loads Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your recent supplier loads right now. Retry shortly to refresh the latest load list.'**
  String get supplierDashboardRecentLoadsUnavailableMessage;

  /// Supplier Dashboard No Loads Posted Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No loads posted yet'**
  String get supplierDashboardNoLoadsPostedTitle;

  /// Supplier Dashboard No Loads Posted Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Post your first supplier load to start receiving booking requests and linked trip activity.'**
  String get supplierDashboardNoLoadsPostedSubtitle;

  /// Shell Tab Home - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellTabHome;

  /// Shell Title Supplier Dashboard - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier dashboard'**
  String get shellTitleSupplierDashboard;

  /// Shell Tab Loads - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loads'**
  String get shellTabLoads;

  /// Shell Title My Loads - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'My Loads'**
  String get shellTitleMyLoads;

  /// Shell Tab Trips - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get shellTabTrips;

  /// Shell Quick Action Trips - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get shellQuickActionTrips;

  /// Shell Dashboard Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get shellDashboardTitle;

  /// Shell Tab Find - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get shellTabFind;

  /// Shell Title Find Loads - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Find Loads'**
  String get shellTitleFindLoads;

  /// Shell Drawer Supplier Workspace - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier workspace'**
  String get shellDrawerSupplierWorkspace;

  /// Shell Drawer Trucker Workspace - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker workspace'**
  String get shellDrawerTruckerWorkspace;

  /// Shell Drawer Dashboard - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get shellDrawerDashboard;

  /// Shell Drawer Assistant - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Guided help'**
  String get shellDrawerAssistant;

  /// Shell Drawer Fleet - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get shellDrawerFleet;

  /// Shell Drawer Messages - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get shellDrawerMessages;

  /// Nav Notifications - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotifications;

  /// Shell Drawer Support - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get shellDrawerSupport;

  /// Shell Drawer Profile - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get shellDrawerProfile;

  /// Shell Drawer Language - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get shellDrawerLanguage;

  /// Shell Drawer Sign Out - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get shellDrawerSignOut;

  /// Shell Sign Out Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you out right now. Retry shortly.'**
  String get shellSignOutFailureMessage;

  /// Shell Messages Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get shellMessagesTitle;

  /// Shell Messages Supplier Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track load-linked conversations with truckers and reply quickly from one place.'**
  String get shellMessagesSupplierSubtitle;

  /// Shell Messages Trucker Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of supplier updates, route context, and booking follow-through in one inbox.'**
  String get shellMessagesTruckerSubtitle;

  /// Shell Messages Supplier Grouped Inbox - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Grouped inbox'**
  String get shellMessagesSupplierGroupedInbox;

  /// Shell Messages Trucker Flat Inbox - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Flat inbox'**
  String get shellMessagesTruckerFlatInbox;

  /// Shows count of unread conversation threads. Placeholder {count} is the number of unread threads.
  ///
  /// In en, this message translates to:
  /// **'{count} unread threads'**
  String shellMessagesUnreadThreads(int count);

  /// Shell Messages Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get shellMessagesLoadFailureTitle;

  /// Shell Messages Empty Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get shellMessagesEmptyTitle;

  /// Shell Messages Supplier Empty Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load-linked trucker conversations will appear here after the first message arrives.'**
  String get shellMessagesSupplierEmptySubtitle;

  /// Shell Messages Trucker Empty Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Start a chat by booking a load and your supplier conversations will show here.'**
  String get shellMessagesTruckerEmptySubtitle;

  /// No description provided for @shellMessagesActiveConversations.
  ///
  /// In en, this message translates to:
  /// **'{count} active conversations - {preview}'**
  String shellMessagesActiveConversations(int count, Object preview);

  /// Shell Messages Unread Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get shellMessagesUnreadStatus;

  /// Shell Messages Read Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get shellMessagesReadStatus;

  /// Shell Messages Hide Trucker Conversations - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Hide trucker conversations'**
  String get shellMessagesHideTruckerConversations;

  /// No description provided for @shellMessagesLatestBy.
  ///
  /// In en, this message translates to:
  /// **'Latest by {name} - {timestamp}'**
  String shellMessagesLatestBy(Object name, Object timestamp);

  /// Trucker Chat Supplier Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Chat with supplier'**
  String get truckerChatSupplierAction;

  /// Trucker Load Chat Start Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not start this supplier chat right now. Retry shortly from the load detail.'**
  String get truckerLoadChatStartFailureMessage;

  /// Trucker Trip Chat Start Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not start this supplier chat right now. Retry shortly from the trip detail.'**
  String get truckerTripChatStartFailureMessage;

  /// Message shown when chat is unavailable. Placeholder {reason} explains why chat is locked.
  ///
  /// In en, this message translates to:
  /// **'Chat unavailable: {reason}'**
  String truckerChatLockedLabel(Object reason);

  /// Chat Title Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get chatTitleFallback;

  /// Chat Tooltip Call - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get chatTooltipCall;

  /// Label for reporting chat source. Placeholder {source} is the chat context source.
  ///
  /// In en, this message translates to:
  /// **'Chat - {source}'**
  String chatReportSourceLabel(Object source);

  /// Chat Menu Mark Conversation Read - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Mark conversation read'**
  String get chatMenuMarkConversationRead;

  /// Chat Menu Refresh Thread - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Refresh thread'**
  String get chatMenuRefreshThread;

  /// Chat Menu Report Spam Or Abuse - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report spam or abuse'**
  String get chatMenuReportSpamOrAbuse;

  /// Chat Conversation Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Conversation unavailable'**
  String get chatConversationUnavailableTitle;

  /// Chat Conversation Unavailable Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not find this conversation right now. Refresh or return to your inbox.'**
  String get chatConversationUnavailableSubtitle;

  /// Chat Back To Inbox Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to messages'**
  String get chatBackToInboxAction;

  /// Chat Booking Action Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking action unavailable'**
  String get chatBookingActionUnavailableTitle;

  /// Chat Booking Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The latest booking action could not be completed from this chat. Review the booking state and retry shortly.'**
  String get chatBookingActionFailureMessage;

  /// Chat Approve Booking Dialog Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approve booking?'**
  String get chatApproveBookingDialogTitle;

  /// Chat Approve Booking Dialog Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This will approve the trucker booking request from the chat context.'**
  String get chatApproveBookingDialogMessage;

  /// Chat Reject Booking Dialog Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reject booking?'**
  String get chatRejectBookingDialogTitle;

  /// Chat Reject Booking Dialog Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This will reject the trucker booking request from the chat context.'**
  String get chatRejectBookingDialogMessage;

  /// Chat Action Cancel - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chatActionCancel;

  /// Chat Action Approve - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get chatActionApprove;

  /// Chat Action Reject - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get chatActionReject;

  /// Chat Booking Approved Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking approved!'**
  String get chatBookingApprovedSuccess;

  /// Chat Booking Rejected Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected.'**
  String get chatBookingRejectedSuccess;

  /// Chat Text Send Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not send your message right now. Retry shortly from this chat.'**
  String get chatTextSendFailureMessage;

  /// Chat Voice Start Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not start voice recording right now. Retry shortly from this chat.'**
  String get chatVoiceStartFailureMessage;

  /// Chat Voice Upload Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not upload this voice message right now. Retry shortly from this chat.'**
  String get chatVoiceUploadFailureMessage;

  /// Chat Voice Send Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not send this voice message right now. Retry shortly from this chat.'**
  String get chatVoiceSendFailureMessage;

  /// Chat Approve Booking Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not approve this booking right now. Retry shortly from this chat.'**
  String get chatApproveBookingFailureMessage;

  /// Chat Reject Booking Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not reject this booking right now. Retry shortly from this chat.'**
  String get chatRejectBookingFailureMessage;

  /// Chat Load Context Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load context'**
  String get chatLoadContextTitle;

  /// Chat Collapse Load Context Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Collapse load context'**
  String get chatCollapseLoadContextTooltip;

  /// Chat Expand Load Context Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Expand load context'**
  String get chatExpandLoadContextTooltip;

  /// Label showing load material in chat context. Placeholder {value} is the material name.
  ///
  /// In en, this message translates to:
  /// **'Material: {value}'**
  String chatMaterialLabel(Object value);

  /// Label showing load price in chat context. Placeholder {value} is the formatted price.
  ///
  /// In en, this message translates to:
  /// **'Price: {value}'**
  String chatPriceLabel(Object value);

  /// Label showing pickup location in chat context. Placeholder {value} is the pickup location name.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {value}'**
  String chatPickupLabel(Object value);

  /// Chat Load Status Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get chatLoadStatusActive;

  /// Chat Booking Status Approved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get chatBookingStatusApproved;

  /// Chat Booking Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get chatBookingStatusUnknown;

  /// Chat Messages Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load messages'**
  String get chatMessagesLoadFailureTitle;

  /// Chat Messages Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load this conversation right now. Retry shortly to refresh the latest messages and booking context.'**
  String get chatMessagesLoadFailureMessage;

  /// Chat No Messages Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesTitle;

  /// Chat No Messages Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start this conversation.'**
  String get chatNoMessagesSubtitle;

  /// Chat System Update Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get chatSystemUpdateFallback;

  /// Chat Sending Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'sending...'**
  String get chatSendingLabel;

  /// Chat Pause Voice Message Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pause voice message'**
  String get chatPauseVoiceMessageTooltip;

  /// Chat Play Voice Message Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get chatPlayVoiceMessageTooltip;

  /// Chat Voice Message Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatVoiceMessageLabel;

  /// Chat Voice Playback Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice playback is unavailable right now.'**
  String get chatVoicePlaybackUnavailable;

  /// Chat Voice Playback Failed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not play this voice message right now.'**
  String get chatVoicePlaybackFailed;

  /// Chat Location Shared Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Shared location'**
  String get chatLocationSharedFallback;

  /// Chat Map Preview Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get chatMapPreviewUnavailable;

  /// Chat Open In Maps Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get chatOpenInMapsAction;

  /// Chat Document Shared Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Shared document'**
  String get chatDocumentSharedFallback;

  /// Chat Attachment Saved Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attachment saved to this conversation.'**
  String get chatAttachmentSavedSubtitle;

  /// Chat Open Document Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get chatOpenDocumentAction;

  /// Chat Route Summary Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route summary'**
  String get chatRouteSummaryFallback;

  /// Chat View Route Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'View route'**
  String get chatViewRouteAction;

  /// Chat Truck Details Shared Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck details'**
  String get chatTruckDetailsSharedFallback;

  /// No description provided for @chatTruckTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} tyres'**
  String chatTruckTyresLabel(Object value);

  /// Chat Type Message Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessageHint;

  /// Chat Stop Recording Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get chatStopRecordingTooltip;

  /// Chat Voice Recording Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice recording'**
  String get chatVoiceRecordingTooltip;

  /// Chat Send Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSendAction;

  /// Common Hear Summary - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Hear summary'**
  String get commonHearSummary;

  /// Common Voice Muted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance is muted on this device.'**
  String get commonVoiceMuted;

  /// Common Voice Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance is unavailable right now.'**
  String get commonVoiceUnavailable;

  /// Notifications Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Notifications Marked All Read Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsMarkedAllReadSuccess;

  /// Notifications Mark All Read - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get notificationsMarkAllRead;

  /// Notifications Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications'**
  String get notificationsLoadFailureTitle;

  /// Notifications Mark All Read Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not mark all notifications as read right now. Retry shortly from the notifications screen.'**
  String get notificationsMarkAllReadFailureMessage;

  /// Notifications Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your notifications right now. Retry shortly to refresh the latest alerts and updates.'**
  String get notificationsLoadFailureMessage;

  /// Notifications Empty Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get notificationsEmptyTitle;

  /// Notifications Empty Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No new notifications.'**
  String get notificationsEmptySubtitle;

  /// Notifications Overview Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get notificationsOverviewTitle;

  /// Label showing number of unread notifications. Placeholder {count} is the unread count.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notificationsUnreadCountLabel(int count);

  /// Label showing number of high priority notifications. Placeholder {count} is the high priority count.
  ///
  /// In en, this message translates to:
  /// **'{count} high priority'**
  String notificationsHighPriorityCountLabel(int count);

  /// Notifications Load More - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get notificationsLoadMore;

  /// No description provided for @notificationsTtsSummary.
  ///
  /// In en, this message translates to:
  /// **'Notifications screen. You have {unreadCount} unread notifications and {highPriorityUnreadCount} high priority alerts pending review.'**
  String notificationsTtsSummary(int unreadCount, int highPriorityUnreadCount);

  /// Notifications Group Today - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsGroupToday;

  /// Notifications Group Yesterday - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationsGroupYesterday;

  /// Notifications Priority High Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get notificationsPriorityHighLabel;

  /// Notifications Body Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open the linked workflow for full context.'**
  String get notificationsBodyFallback;

  /// Notification Fallback Verification Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification update'**
  String get notificationFallbackVerificationUpdate;

  /// Notification Fallback Booking Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking update'**
  String get notificationFallbackBookingUpdate;

  /// Notification Fallback Trip Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip update'**
  String get notificationFallbackTripUpdate;

  /// Notification Fallback Proof Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof update'**
  String get notificationFallbackProofUpdate;

  /// Notification Fallback Super Load Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Load update'**
  String get notificationFallbackSuperLoadUpdate;

  /// Notification Fallback Message Received - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationFallbackMessageReceived;

  /// Notification Fallback Support Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support update'**
  String get notificationFallbackSupportUpdate;

  /// Notification Fallback Dispute Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute update'**
  String get notificationFallbackDisputeUpdate;

  /// Notification Fallback Account Update - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account update'**
  String get notificationFallbackAccountUpdate;

  /// Notification Fallback System Notice - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'System notice'**
  String get notificationFallbackSystemNotice;

  /// Notification Fallback Load Expiry Warning - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load expiry warning'**
  String get notificationFallbackLoadExpiryWarning;

  /// Nav Profile - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Nav Support - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get navSupport;

  /// Nav Delete Account - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get navDeleteAccount;

  /// Delete Account Requested On Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deletion requested on'**
  String get deleteAccountRequestedOnLabel;

  /// Delete Account Grace Period Ends Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Grace period ends'**
  String get deleteAccountGracePeriodEndsLabel;

  /// Delete Account Grace Period Passed Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Grace-period end date has passed. Permanent deletion processing may happen at any time.'**
  String get deleteAccountGracePeriodPassedLabel;

  /// Delete Account Grace Period Less Than One Day Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 day remains before the grace period ends.'**
  String get deleteAccountGracePeriodLessThanOneDayLabel;

  /// ICU plural message showing remaining days in grace period before account deletion. Placeholder {count} is the number of days remaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} day remains before the grace period ends.} other {{count} days remain before the grace period ends.}}'**
  String deleteAccountGracePeriodRemainingDaysLabel(int count);

  /// Delete Account Lifecycle Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The account deletion lifecycle is temporarily unavailable. Retry shortly to refresh the latest deletion status.'**
  String get deleteAccountLifecycleFailureMessage;

  /// Delete Account Cancel Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not cancel this deletion request right now. Retry shortly from the deletion lifecycle screen.'**
  String get deleteAccountCancelFailureMessage;

  /// Delete Account Request Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not process this deletion request right now. Review the current account status and retry shortly.'**
  String get deleteAccountRequestFailureMessage;

  /// Delete Account Accepted Sign Out Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deletion was accepted, but we could not complete sign out right now. Retry shortly to refresh your account session.'**
  String get deleteAccountAcceptedSignOutFailureMessage;

  /// Delete Account Blocked Summary Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This deletion request cannot proceed yet because another account dependency still needs attention.'**
  String get deleteAccountBlockedSummaryMessage;

  /// Delete Account Cancelled Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request was cancelled. Account access can be restored while the lifecycle returns to active.'**
  String get deleteAccountCancelledMessage;

  /// Delete Account Accepted Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request was accepted. You have been signed out while the account enters pending cleanup.'**
  String get deleteAccountAcceptedMessage;

  /// Delete Account Blocker Recovery Guidance Active Trips - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Finish or cancel every active trip first, then retry the deletion request.'**
  String get deleteAccountBlockerRecoveryGuidanceActiveTrips;

  /// Delete Account Blocker Recovery Guidance Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Wait until the unresolved dispute is reviewed or resolved before requesting deletion again.'**
  String get deleteAccountBlockerRecoveryGuidanceDispute;

  /// Delete Account Blocker Recovery Guidance Compliance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some records still need to stay on the platform for compliance or retention policy. Use support if you need clarification on the hold.'**
  String get deleteAccountBlockerRecoveryGuidanceCompliance;

  /// Delete Account Blocker Recovery Guidance Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resolve the blocking dependency first, then request deletion again.'**
  String get deleteAccountBlockerRecoveryGuidanceDefault;

  /// Delete Account Blocker Action Open Trips - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open trips'**
  String get deleteAccountBlockerActionOpenTrips;

  /// Delete Account Blocker Action Open Support - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open support'**
  String get deleteAccountBlockerActionOpenSupport;

  /// Delete Account Blocker Title Active Trips - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Finish active trips first'**
  String get deleteAccountBlockerTitleActiveTrips;

  /// Delete Account Blocker Title Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resolve the open dispute first'**
  String get deleteAccountBlockerTitleDispute;

  /// Delete Account Blocker Title Compliance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Wait for the compliance hold to clear'**
  String get deleteAccountBlockerTitleCompliance;

  /// Delete Account Blocker Title Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resolve the blocker first'**
  String get deleteAccountBlockerTitleDefault;

  /// Delete Account Blocker Body Active Trips - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This account still has active trip work attached to it. Review the current trip list, complete any legitimate active work, and then retry the deletion request.'**
  String get deleteAccountBlockerBodyActiveTrips;

  /// Delete Account Blocker Body Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This account still has an unresolved dispute or review dependency. Use support to follow the current case until the blocking dispute is resolved.'**
  String get deleteAccountBlockerBodyDispute;

  /// Delete Account Blocker Body Compliance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This account is still under a compliance or retention hold. Support can clarify the current hold, but the platform cannot bypass the retention requirement.'**
  String get deleteAccountBlockerBodyCompliance;

  /// Delete Account Blocker Body Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the current blocker carefully and resolve it before retrying the deletion request.'**
  String get deleteAccountBlockerBodyDefault;

  /// Delete Account Support Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Need help first?'**
  String get deleteAccountSupportTitle;

  /// Delete Account Support Body Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use support if you need clarification on the pending-cleanup status, the grace-period timeline, or whether cancellation is the right next step for this account.'**
  String get deleteAccountSupportBodyPendingCleanup;

  /// Delete Account Support Body Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use support if you expect blockers like active trips, unresolved disputes, or compliance holds and need clarification before retrying the deletion request.'**
  String get deleteAccountSupportBodyDefault;

  /// Delete Account Support Detail Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support can clarify the current lifecycle state, but they may still need to follow retention and compliance policy before permanent deletion is processed.'**
  String get deleteAccountSupportDetailPendingCleanup;

  /// Delete Account Support Detail Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support can explain the current blocker or retention requirement, but they cannot bypass required cleanup, dispute review, or compliance policy.'**
  String get deleteAccountSupportDetailDefault;

  /// Delete Account What Happens Next Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get deleteAccountWhatHappensNextTitle;

  /// Delete Account What Happens Next Body Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account is already in the pending-cleanup state. Cancel the request if you want to restore the account to active before permanent deletion is processed.'**
  String get deleteAccountWhatHappensNextBodyPendingCleanup;

  /// Delete Account What Happens Next Body Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If no blockers exist, your account is moved to deactivated pending cleanup and you are signed out safely.'**
  String get deleteAccountWhatHappensNextBodyDefault;

  /// Delete Account What Happens Next Detail Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If you cancel now, the account deletion status returns to active and normal access is restored.'**
  String get deleteAccountWhatHappensNextDetailPendingCleanup;

  /// Delete Account What Happens Next Detail Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If blockers exist, the platform keeps your account active and tells you which dependency must be resolved first.'**
  String get deleteAccountWhatHappensNextDetailDefault;

  /// Delete Account What Happens Next Footnote Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support may still retain internal records according to policy, but the user-facing deletion request will be cancelled.'**
  String get deleteAccountWhatHappensNextFootnotePendingCleanup;

  /// Delete Account What Happens Next Footnote Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The deletion request can now be cancelled while the account is in the pending-cleanup lifecycle before permanent deletion is processed.'**
  String get deleteAccountWhatHappensNextFootnoteDefault;

  /// Delete Account Lifecycle Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account deletion lifecycle unavailable'**
  String get deleteAccountLifecycleUnavailableTitle;

  /// Delete Account Cancelled Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deletion request cancelled'**
  String get deleteAccountCancelledTitle;

  /// Delete Account Already Requested Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deletion already requested'**
  String get deleteAccountAlreadyRequestedTitle;

  /// Delete Account Already Requested Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This account is currently deactivated pending cleanup. Cancel the request below if you need to restore access during the grace-period lifecycle.'**
  String get deleteAccountAlreadyRequestedMessage;

  /// Delete Account Cancel Request Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion request'**
  String get deleteAccountCancelRequestTitle;

  /// Delete Account Cancelling Button - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelling deletion...'**
  String get deleteAccountCancellingButton;

  /// Delete Account Cancel Request Button - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion request'**
  String get deleteAccountCancelRequestButton;

  /// Delete Account Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account deletion unavailable'**
  String get deleteAccountUnavailableTitle;

  /// Delete Account Blocked Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deletion blocked'**
  String get deleteAccountBlockedTitle;

  /// Delete Account Confirm Request Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion request'**
  String get deleteAccountConfirmRequestTitle;

  /// Delete Account Requesting Button - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Requesting deletion...'**
  String get deleteAccountRequestingButton;

  /// Delete Account Screen Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountScreenTitle;

  /// Delete Account Hero Title Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account deletion pending cleanup'**
  String get deleteAccountHeroTitlePendingCleanup;

  /// Delete Account Hero Title Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get deleteAccountHeroTitleDefault;

  /// Delete Account Hero Subtitle Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently deactivated pending cleanup. You can still cancel this request during the grace-period lifecycle while the account is not permanently deleted.'**
  String get deleteAccountHeroSubtitlePendingCleanup;

  /// Delete Account Hero Subtitle Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This action can deactivate your account immediately if no active blockers exist. Review the consequences carefully before continuing.'**
  String get deleteAccountHeroSubtitleDefault;

  /// Delete Account Hero Body Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The deletion request has already been accepted and the account is in pending-cleanup state. Cancel the request if you want to restore normal account access before permanent deletion is processed.'**
  String get deleteAccountHeroBodyPendingCleanup;

  /// Delete Account Hero Body Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Before deletion can proceed, the platform checks for active trips, unresolved disputes, and compliance or verification records that still require retention.'**
  String get deleteAccountHeroBodyDefault;

  /// Account Sign Out Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you out right now. Retry shortly from this screen.'**
  String get accountSignOutFailureMessage;

  /// Account Role Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get accountRoleSupplier;

  /// Account Role Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker'**
  String get accountRoleTrucker;

  /// Account Role Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get accountRoleUnknown;

  /// Account Status Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatusTitle;

  /// Account Profile Status Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile status'**
  String get accountProfileStatusLabel;

  /// Account Profile Status Complete - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get accountProfileStatusComplete;

  /// Account Profile Status Needs Attention - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get accountProfileStatusNeedsAttention;

  /// Account Account State Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account state'**
  String get accountAccountStateLabel;

  /// Account State Deactivated Pending Cleanup - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deactivated pending cleanup'**
  String get accountStateDeactivatedPendingCleanup;

  /// Account State Restricted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get accountStateRestricted;

  /// Account State Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get accountStateActive;

  /// Account State Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get accountStateUnknown;

  /// Account Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account details unavailable'**
  String get accountLoadFailureTitle;

  /// Account Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your account details right now. Retry shortly from this screen.'**
  String get accountLoadFailureMessage;

  /// Account Manage Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get accountManageTitle;

  /// Account Verification Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get accountVerificationLabel;

  /// Account Fleet Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get accountFleetLabel;

  /// Account Settings Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettingsLabel;

  /// Account Session Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get accountSessionTitle;

  /// Account Signed In As Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get accountSignedInAsLabel;

  /// Account Current Authenticated Session - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current authenticated session'**
  String get accountCurrentAuthenticatedSession;

  /// Account Sign Out Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOutAction;

  /// Profile Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get profileLoadFailureTitle;

  /// Profile Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile right now. Retry shortly from this screen.'**
  String get profileLoadFailureMessage;

  /// Profile Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile summary'**
  String get profileSummaryTitle;

  /// Profile Name Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// Profile Value Not Set - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileValueNotSet;

  /// Profile Phone Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// Profile Value Not Provided - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileValueNotProvided;

  /// Profile Email Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// Profile Role Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// Profile Readiness Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile readiness'**
  String get profileReadinessTitle;

  /// Profile Completeness Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completeness'**
  String get profileCompletenessLabel;

  /// Profile Completeness Complete - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get profileCompletenessComplete;

  /// Profile Completeness Needs Updates - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Needs updates'**
  String get profileCompletenessNeedsUpdates;

  /// Profile Deletion Status Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deletion status'**
  String get profileDeletionStatusLabel;

  /// Profile Open Fleet Readiness - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open fleet readiness'**
  String get profileOpenFleetReadiness;

  /// Profile Request Account Deletion - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get profileRequestAccountDeletion;

  /// TTS summary for profile screen. Placeholders {roleLabel}, {trustStatus}, {deletionStatus} describe user's account state.
  ///
  /// In en, this message translates to:
  /// **'Profile screen. Role is {roleLabel}. Trust and safety status is {trustStatus}. Account deletion status is {deletionStatus}. You can open deletion follow-up or support guidance from this screen if needed.'**
  String profileTtsSummary(
    Object roleLabel,
    Object trustStatus,
    Object deletionStatus,
  );

  /// Settings Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings Preferences Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesTitle;

  /// Settings Role Context Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Role context'**
  String get settingsRoleContextLabel;

  /// TTS summary for settings screen. Placeholders {selectedLanguageLabel} and {roleSentence} describe current settings.
  ///
  /// In en, this message translates to:
  /// **'Settings screen. Language is set to {selectedLanguageLabel}. Voice guidance is manual right now. Notifications are enabled through the in-app inbox.{roleSentence}'**
  String settingsTtsSummary(Object selectedLanguageLabel, Object roleSentence);

  /// Settings Voice Assistance Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice assistance'**
  String get settingsVoiceAssistanceLabel;

  /// Settings Voice Assistance Value - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Manual contextual summaries are available from supported screens.'**
  String get settingsVoiceAssistanceValue;

  /// Settings Notifications Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsLabel;

  /// Settings Notifications Value - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In-app inbox and push status controls are available here.'**
  String get settingsNotificationsValue;

  /// Settings Connected Surfaces Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Connected surfaces'**
  String get settingsConnectedSurfacesTitle;

  /// Settings Push Notifications Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotificationsTitle;

  /// Settings Push Status Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsPushStatusLabel;

  /// Settings Push Request Permission - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get settingsPushRequestPermission;

  /// Settings Push Refresh Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get settingsPushRefreshStatus;

  /// Settings Push Status Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Push notification status unavailable'**
  String get settingsPushStatusUnavailableTitle;

  /// Settings Push Status Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to read device notification permission right now. Refresh after Firebase/device support is available.'**
  String get settingsPushStatusUnavailableMessage;

  /// Settings Push Status Allowed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get settingsPushStatusAllowed;

  /// Settings Push Status Allowed Quietly - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Allowed quietly'**
  String get settingsPushStatusAllowedQuietly;

  /// Settings Push Status Blocked - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Blocked in system settings'**
  String get settingsPushStatusBlocked;

  /// Settings Push Status Not Requested - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Not requested yet'**
  String get settingsPushStatusNotRequested;

  /// Settings Push Status Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device/build'**
  String get settingsPushStatusUnavailable;

  /// Settings Push Guidance Allowed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Foreground and opened push flows are enabled when Firebase delivery is configured.'**
  String get settingsPushGuidanceAllowed;

  /// Settings Push Guidance Allowed Quietly - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Push is allowed quietly. You can promote alerts in the device notification settings if needed.'**
  String get settingsPushGuidanceAllowedQuietly;

  /// Settings Push Guidance Blocked - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Push notifications are blocked. Open your device notification settings for TranZfort to enable alerts again.'**
  String get settingsPushGuidanceBlocked;

  /// Settings Push Guidance Not Requested - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Push permission has not been requested yet on this device session.'**
  String get settingsPushGuidanceNotRequested;

  /// Settings Push Guidance Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Push runtime is unavailable here until Firebase/device support is fully configured.'**
  String get settingsPushGuidanceUnavailable;

  /// Shows count of active support tickets with pluralization. Placeholder {count} is the ticket count, {s} is plural suffix.
  ///
  /// In en, this message translates to:
  /// **'{count} ticket{s}'**
  String supportActiveTicketCount(Object count, Object s);

  /// Support Screen Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support and dispute follow-up'**
  String get supportScreenTitle;

  /// Support Hero Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review your latest support activity'**
  String get supportHeroTitle;

  /// Support Hero Subtitle Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use support to review dispute progress, payment follow-ups, and the latest visible ticket updates linked to your supplier activity.'**
  String get supportHeroSubtitleSupplier;

  /// Support Hero Subtitle Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use support to review dispute progress, freight follow-ups, and the latest visible ticket updates linked to your trucker activity.'**
  String get supportHeroSubtitleTrucker;

  /// Support No Active Tickets - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No active tickets'**
  String get supportNoActiveTickets;

  /// Support Create Ticket Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Create support ticket'**
  String get supportCreateTicketAction;

  /// Support Intro Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Follow your latest support and dispute tickets here, review visible workflow updates, and reply with any clarification or proof support requested.'**
  String get supportIntroMessage;

  /// Support Ticket Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support summary'**
  String get supportTicketSummaryTitle;

  /// Support Escalation Path Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Escalation path'**
  String get supportEscalationPathLabel;

  /// Support Escalation Path Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier support'**
  String get supportEscalationPathSupplier;

  /// Support Escalation Path Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker support'**
  String get supportEscalationPathTrucker;

  /// Support Current Trust Status Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current trust status'**
  String get supportCurrentTrustStatusLabel;

  /// Support My Tickets Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get supportMyTicketsTitle;

  /// Support Selected Ticket And Reply Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Selected ticket and reply'**
  String get supportSelectedTicketAndReplyTitle;

  /// Support Select Ticket Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket'**
  String get supportSelectTicketTitle;

  /// Support Select Ticket Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose a support ticket from the list to review its visible thread, workflow state, and reply options.'**
  String get supportSelectTicketSubtitle;

  /// Support Tickets Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support tickets unavailable'**
  String get supportTicketsUnavailableTitle;

  /// Support No Tickets Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get supportNoTicketsTitle;

  /// Support No Tickets Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Create a support ticket to start a new support or dispute follow-up and track future updates here.'**
  String get supportNoTicketsSubtitle;

  /// Support Loading Older Tickets - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loading older tickets...'**
  String get supportLoadingOlderTickets;

  /// Support Load Older Tickets - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load older tickets'**
  String get supportLoadOlderTickets;

  /// Support Tickets Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your support tickets right now. Retry shortly to refresh your latest support and dispute activity.'**
  String get supportTicketsLoadFailureMessage;

  /// Support Open Trip Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open trip'**
  String get supportOpenTripAction;

  /// Support Open Load Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open load'**
  String get supportOpenLoadAction;

  /// Support Viewing This Ticket - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Viewing this ticket'**
  String get supportViewingThisTicket;

  /// Support Open Ticket Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open ticket'**
  String get supportOpenTicketAction;

  /// Support Detail Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Ticket detail unavailable'**
  String get supportDetailUnavailableTitle;

  /// Support Detail Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load this ticket detail right now. Retry shortly to refresh the latest visible thread and workflow status.'**
  String get supportDetailUnavailableMessage;

  /// Support Ticket Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Ticket unavailable'**
  String get supportTicketUnavailableTitle;

  /// Support Ticket Unavailable Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This support ticket is unavailable right now for the current account.'**
  String get supportTicketUnavailableSubtitle;

  /// Support Ticket Status Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportTicketStatusOpen;

  /// Support Ticket Status In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get supportTicketStatusInProgress;

  /// Support Ticket Status Waiting For You - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Waiting for you'**
  String get supportTicketStatusWaitingForYou;

  /// Support Ticket Status Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get supportTicketStatusResolved;

  /// Support Ticket Status Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportTicketStatusClosed;

  /// Support Ticket Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supportTicketStatusUnknown;

  /// Support Ticket Priority Low - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'low'**
  String get supportTicketPriorityLow;

  /// Support Ticket Priority Medium - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'medium'**
  String get supportTicketPriorityMedium;

  /// Support Ticket Priority High - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'high'**
  String get supportTicketPriorityHigh;

  /// Support Ticket Priority Urgent - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'urgent'**
  String get supportTicketPriorityUrgent;

  /// Support Ticket Priority Not Set - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get supportTicketPriorityNotSet;

  /// Support Ticket Title Trip Dispute Review - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip dispute review'**
  String get supportTicketTitleTripDisputeReview;

  /// Support Ticket Title Loaded Quantity Mismatch Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loaded quantity mismatch report'**
  String get supportTicketTitleLoadedQuantityMismatchReport;

  /// Support Ticket Title Unloaded Quantity Mismatch Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unloaded quantity mismatch report'**
  String get supportTicketTitleUnloadedQuantityMismatchReport;

  /// Support Ticket Title Document Mismatch Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Document mismatch report'**
  String get supportTicketTitleDocumentMismatchReport;

  /// Support Ticket Title Spam Or Scam Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam report'**
  String get supportTicketTitleSpamOrScamReport;

  /// Support Ticket Title Abusive Behavior Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior report'**
  String get supportTicketTitleAbusiveBehaviorReport;

  /// Support Ticket Title Fake Payout Proof Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof report'**
  String get supportTicketTitleFakePayoutProofReport;

  /// Support Ticket Title Non Payment Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Non-payment report'**
  String get supportTicketTitleNonPaymentReport;

  /// Support Ticket Title Delay Or No Show Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delay or no-show report'**
  String get supportTicketTitleDelayOrNoShowReport;

  /// Support Ticket Title Damage Or Shortage Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Damage or shortage report'**
  String get supportTicketTitleDamageOrShortageReport;

  /// Support Ticket Title Other Report - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other report'**
  String get supportTicketTitleOtherReport;

  /// Support Dispute Category Trip Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip dispute'**
  String get supportDisputeCategoryTripDispute;

  /// Support Dispute Category Loaded Quantity Mismatch - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loaded quantity mismatch'**
  String get supportDisputeCategoryLoadedQuantityMismatch;

  /// Support Dispute Category Unloaded Quantity Mismatch - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unloaded quantity mismatch'**
  String get supportDisputeCategoryUnloadedQuantityMismatch;

  /// Support Dispute Category Document Mismatch - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Document mismatch'**
  String get supportDisputeCategoryDocumentMismatch;

  /// Support Dispute Category Non Payment - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Non-payment'**
  String get supportDisputeCategoryNonPayment;

  /// Support Dispute Category Fake Payout Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof'**
  String get supportDisputeCategoryFakePayoutProof;

  /// Support Dispute Category Delay Or No Show - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delay or no-show'**
  String get supportDisputeCategoryDelayOrNoShow;

  /// Support Dispute Category Damage Or Shortage - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Damage or shortage'**
  String get supportDisputeCategoryDamageOrShortage;

  /// Support Dispute Category Abusive Behavior - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior'**
  String get supportDisputeCategoryAbusiveBehavior;

  /// Support Dispute Category Spam Or Scam - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get supportDisputeCategorySpamOrScam;

  /// Support Dispute Category Other - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportDisputeCategoryOther;

  /// No description provided for @supportUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at: {value}'**
  String supportUpdatedAt(Object value);

  /// No description provided for @supportTicketReference.
  ///
  /// In en, this message translates to:
  /// **'Ticket reference: {value}'**
  String supportTicketReference(Object value);

  /// No description provided for @supportTripReference.
  ///
  /// In en, this message translates to:
  /// **'Trip reference: {value}'**
  String supportTripReference(Object value);

  /// No description provided for @supportOpenedAt.
  ///
  /// In en, this message translates to:
  /// **'Opened at: {value}'**
  String supportOpenedAt(Object value);

  /// No description provided for @supportDisputeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Dispute category: {category}'**
  String supportDisputeCategoryLabel(Object category);

  /// No description provided for @supportTicketIdValue.
  ///
  /// In en, this message translates to:
  /// **'Ticket id: {id}'**
  String supportTicketIdValue(Object id);

  /// No description provided for @supportPriorityValue.
  ///
  /// In en, this message translates to:
  /// **'Priority: {priority}'**
  String supportPriorityValue(Object priority);

  /// No description provided for @supportLastUpdatedValue.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {value}'**
  String supportLastUpdatedValue(Object value);

  /// No description provided for @supportRelatedTripValue.
  ///
  /// In en, this message translates to:
  /// **'Related trip: {value}'**
  String supportRelatedTripValue(Object value);

  /// No description provided for @supportRelatedLoadValue.
  ///
  /// In en, this message translates to:
  /// **'Related load: {value}'**
  String supportRelatedLoadValue(Object value);

  /// Support Open Related Trip Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open related trip'**
  String get supportOpenRelatedTripAction;

  /// Support Open Related Load Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open related load'**
  String get supportOpenRelatedLoadAction;

  /// Support Workflow Guidance Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support has received this ticket and review should begin shortly. Use visible replies to add any missing context if needed.'**
  String get supportWorkflowGuidanceOpen;

  /// Support Workflow Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support or operations are actively reviewing this ticket. Watch for visible replies and be ready to clarify the timeline or proof if more detail is requested.'**
  String get supportWorkflowGuidanceInProgress;

  /// Support Workflow Guidance Waiting For User - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting on your clarification or proof. Reply on this ticket so the review can continue without unnecessary delay.'**
  String get supportWorkflowGuidanceWaitingForUser;

  /// Support Workflow Guidance Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This ticket has reached a final support outcome. Review the recorded resolution before opening any fresh follow-up.'**
  String get supportWorkflowGuidanceResolved;

  /// Support Workflow Guidance Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the latest visible ticket updates for the current workflow state.'**
  String get supportWorkflowGuidanceUnknown;

  /// Support Dispute Banner Title Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute review closed'**
  String get supportDisputeBannerTitleClosed;

  /// Support Dispute Banner Title Waiting - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute waiting for your reply'**
  String get supportDisputeBannerTitleWaiting;

  /// Support Dispute Banner Title In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute review in progress'**
  String get supportDisputeBannerTitleInProgress;

  /// No description provided for @supportDisputeBannerMessageClosed.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}. This trip dispute has reached a final support outcome. Both sides can still follow the recorded ticket context, but raw evidence access may remain restricted.'**
  String supportDisputeBannerMessageClosed(Object category);

  /// No description provided for @supportDisputeBannerMessageWaiting.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}. This trip dispute is waiting on your clarification or proof. Both sides can follow visible status updates, but raw evidence access may remain restricted during review.'**
  String supportDisputeBannerMessageWaiting(Object category);

  /// No description provided for @supportDisputeBannerMessageInProgress.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}. This trip dispute is under active support review. Both sides can follow visible status updates, but raw evidence access may remain restricted during review.'**
  String supportDisputeBannerMessageInProgress(Object category);

  /// Support Evidence Visibility Summary Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this ticket.'**
  String get supportEvidenceVisibilitySummaryClosed;

  /// Support Evidence Visibility Summary In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible on this ticket.'**
  String get supportEvidenceVisibilitySummaryInProgress;

  /// Support Restricted Evidence Message Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Raw attachments and sensitive proof may remain restricted even after the review outcome is recorded on the ticket.'**
  String get supportRestrictedEvidenceMessageClosed;

  /// Support Restricted Evidence Message In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Raw attachments and sensitive proof may remain restricted while this review stays active on the ticket.'**
  String get supportRestrictedEvidenceMessageInProgress;

  /// Support Additional Proof Guidance Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have a genuinely new issue or clarification to raise.'**
  String get supportAdditionalProofGuidanceClosed;

  /// Support Additional Proof Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If your dispute depends on additional documents or screenshots beyond the current single-image flow, describe those missing proofs clearly in your visible reply so support knows what else to review.'**
  String get supportAdditionalProofGuidanceInProgress;

  /// Support Attachment Visibility Message Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached to this reply. Raw file access may remain restricted even after the review outcome is recorded on this ticket.'**
  String get supportAttachmentVisibilityMessageClosed;

  /// Support Attachment Visibility Message In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached to this reply. Raw file access may remain restricted during review.'**
  String get supportAttachmentVisibilityMessageInProgress;

  /// Support Attachment Guidance Message Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If you still need to reference other supporting proofs after closure, open a fresh follow-up only when you have genuinely new context that was not captured on this ticket.'**
  String get supportAttachmentGuidanceMessageClosed;

  /// Support Attachment Guidance Message In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If other supporting proofs are not attached here, summarize them in visible reply text so support can request or review them safely.'**
  String get supportAttachmentGuidanceMessageInProgress;

  /// Support Support Team Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support team'**
  String get supportSupportTeamLabel;

  /// Support You Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYouLabel;

  /// Support Empty Thread Subtitle Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No visible thread has been posted on this support ticket yet.'**
  String get supportEmptyThreadSubtitleOpen;

  /// Support Empty Thread Subtitle In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No visible thread is available yet while this ticket remains under active review.'**
  String get supportEmptyThreadSubtitleInProgress;

  /// Support Empty Thread Subtitle Waiting - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No visible thread is available yet. Reply on this ticket so the review can continue.'**
  String get supportEmptyThreadSubtitleWaiting;

  /// Support Empty Thread Subtitle Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No visible thread was recorded before this ticket was resolved or closed.'**
  String get supportEmptyThreadSubtitleResolved;

  /// Support Empty Thread Subtitle Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No visible thread is available for this support ticket yet.'**
  String get supportEmptyThreadSubtitleUnknown;

  /// Support Evidence Visibility Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence visibility'**
  String get supportEvidenceVisibilityTitle;

  /// Support Visible Thread Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Visible thread summary'**
  String get supportVisibleThreadSummaryTitle;

  /// No description provided for @supportVisibleRepliesCount.
  ///
  /// In en, this message translates to:
  /// **'Visible replies: {count}'**
  String supportVisibleRepliesCount(int count);

  /// Support Last Visible Update None - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Last visible update: No visible replies yet.'**
  String get supportLastVisibleUpdateNone;

  /// No description provided for @supportLastVisibleUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last visible update: {value}'**
  String supportLastVisibleUpdate(Object value);

  /// Support Latest Visible Sender None - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Latest visible sender: No visible sender yet.'**
  String get supportLatestVisibleSenderNone;

  /// No description provided for @supportLatestVisibleSender.
  ///
  /// In en, this message translates to:
  /// **'Latest visible sender: {value}'**
  String supportLatestVisibleSender(Object value);

  /// Support Visible Attachment Summary Present - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Visible attachment summary: One or more visible replies include an attachment reference.'**
  String get supportVisibleAttachmentSummaryPresent;

  /// Support Visible Attachment Summary Absent - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Visible attachment summary: No visible replies include an attachment reference yet.'**
  String get supportVisibleAttachmentSummaryAbsent;

  /// Support No Visible Thread Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No visible thread yet'**
  String get supportNoVisibleThreadTitle;

  /// Support Current Workflow Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current workflow'**
  String get supportCurrentWorkflowTitle;

  /// Support Resolution Outcome Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resolution outcome'**
  String get supportResolutionOutcomeTitle;

  /// No description provided for @supportResolvedOn.
  ///
  /// In en, this message translates to:
  /// **'Resolved on: {value}'**
  String supportResolvedOn(Object value);

  /// Support Waiting For Reply Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting for your reply'**
  String get supportWaitingForReplyTitle;

  /// Support Waiting For Reply Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply on this ticket with the requested clarification or proof so the review can continue.'**
  String get supportWaitingForReplyMessage;

  /// Support Reply Guidance Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply guidance'**
  String get supportReplyGuidanceTitle;

  /// Support Replies Closed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Replies are closed for this ticket'**
  String get supportRepliesClosedTitle;

  /// Support Replies Closed Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This ticket has reached a final support outcome and does not accept further replies.'**
  String get supportRepliesClosedMessage;

  /// Support Reply Status Reply - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get supportReplyStatusReply;

  /// Support Reply Status Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get supportReplyStatusSubmitted;

  /// Support No Message Text Provided - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No message text provided.'**
  String get supportNoMessageTextProvided;

  /// Support Trust Status Loading - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loading trust status'**
  String get supportTrustStatusLoading;

  /// No description provided for @supportResolutionValue.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {value}'**
  String supportResolutionValue(Object value);

  /// Support Reply Guidance Primary Open Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use your visible reply to explain the dispute timeline, what proof is already attached, and what support should review first.'**
  String get supportReplyGuidancePrimaryOpenDispute;

  /// Support Reply Guidance Primary Open Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use your reply to explain the current blocker clearly so support can continue the review.'**
  String get supportReplyGuidancePrimaryOpenDefault;

  /// Support Reply Guidance Primary In Progress Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep your next reply focused on the dispute timeline, proof gaps, and the clearest follow-up support should review.'**
  String get supportReplyGuidancePrimaryInProgressDispute;

  /// Support Reply Guidance Primary In Progress Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply with the next operational detail or clarification support asked for so the review can continue.'**
  String get supportReplyGuidancePrimaryInProgressDefault;

  /// Support Reply Guidance Primary Waiting Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply with the missing clarification or proof support requested so the dispute review can continue without unnecessary delay.'**
  String get supportReplyGuidancePrimaryWaitingDispute;

  /// Support Reply Guidance Primary Waiting Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply with the missing clarification support requested so the ticket can continue moving.'**
  String get supportReplyGuidancePrimaryWaitingDefault;

  /// Support Reply Guidance Primary Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This ticket is already resolved. Start a fresh follow-up only if a genuinely new issue appears.'**
  String get supportReplyGuidancePrimaryResolved;

  /// Support Reply Guidance Primary Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply with the clearest next detail you can share if support requests more information.'**
  String get supportReplyGuidancePrimaryUnknown;

  /// Support Reply Guidance Secondary Open In Progress Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If proof is missing from the current single-image flow, summarize the rest clearly in visible text so support knows what else to request or review.'**
  String get supportReplyGuidanceSecondaryOpenInProgressDispute;

  /// Support Reply Guidance Secondary Open In Progress Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the reply concise, specific, and tied to the load or trip context support is reviewing.'**
  String get supportReplyGuidanceSecondaryOpenInProgressDefault;

  /// Support Reply Guidance Secondary Waiting Dispute - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If more than one proof matters, attach the strongest one first and summarize the remaining context in your visible reply.'**
  String get supportReplyGuidanceSecondaryWaitingDispute;

  /// Support Reply Guidance Secondary Waiting Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Answer the latest support prompt directly so the next review step is clear.'**
  String get supportReplyGuidanceSecondaryWaitingDefault;

  /// Support Reply Guidance Secondary Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the recorded resolution for reference and use a new ticket only for genuinely new follow-up.'**
  String get supportReplyGuidanceSecondaryResolved;

  /// Support Reply Guidance Secondary Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep your reply clear and limited to the facts support can verify next.'**
  String get supportReplyGuidanceSecondaryUnknown;

  /// No description provided for @supportTicketTitleWithPriority.
  ///
  /// In en, this message translates to:
  /// **'{title} - {priority} priority'**
  String supportTicketTitleWithPriority(Object title, Object priority);

  /// Support Fallback Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportFallbackLabel;

  /// Support Trust Status Normal - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get supportTrustStatusNormal;

  /// Support Trust Status Warned - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Warned'**
  String get supportTrustStatusWarned;

  /// Support Trust Status Restricted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get supportTrustStatusRestricted;

  /// Support Trust Status Suspended - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get supportTrustStatusSuspended;

  /// Support Trust Status Banned - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get supportTrustStatusBanned;

  /// Support Trust Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supportTrustStatusUnknown;

  /// Support Trust Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trust: {status}'**
  String supportTrustBadge(Object status);

  /// Trust Safety Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety'**
  String get trustSafetyLabel;

  /// Trust Safety Warning Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety warning active'**
  String get trustSafetyWarningTitle;

  /// Trust Safety Warning Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account has a warning on record. Marketplace and support surfaces remain available, but you should avoid further violations and use support if you need clarification on the warning or next-step expectations.'**
  String get trustSafetyWarningMessage;

  /// Trust Safety Restriction Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety restriction active'**
  String get trustSafetyRestrictionTitle;

  /// Trust Safety Restriction Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some platform actions may be limited while this restriction remains active. Use support to confirm which actions are limited and what changes may be required before the restriction can be reviewed.'**
  String get trustSafetyRestrictionFallback;

  /// Trust Safety Suspension Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety suspension active'**
  String get trustSafetySuspensionTitle;

  /// Trust Safety Suspension Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Access to key platform actions may be paused while this suspension remains active. Use support for policy-allowed review updates or reinstatement guidance once the required next steps are complete.'**
  String get trustSafetySuspensionFallback;

  /// Trust Safety Ban Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety ban active'**
  String get trustSafetyBanTitle;

  /// Trust Safety Ban Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked from normal platform use. Use support only for policy-allowed clarification or final review outcome questions.'**
  String get trustSafetyBanFallback;

  /// Trust Safety Open Support - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open support'**
  String get trustSafetyOpenSupport;

  /// Trust Safety Healthy Message Line1 - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account currently has no active trust or safety enforcement. Keep delivery proofs, payout confirmations, and marketplace communication accurate so this status remains normal.'**
  String get trustSafetyHealthyMessageLine1;

  /// Trust Safety Healthy Message Line2 - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If policy or moderation questions ever appear on this account, open support for clarification before retrying blocked actions.'**
  String get trustSafetyHealthyMessageLine2;

  /// No description provided for @trustSafetyCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current status: {displayLabel}. {fallback}'**
  String trustSafetyCurrentStatus(Object displayLabel, Object fallback);

  /// No description provided for @trustSafetyCurrentStatusWithReason.
  ///
  /// In en, this message translates to:
  /// **'Current status: {displayLabel}. Reason summary: {reasonSummary}. {fallback}'**
  String trustSafetyCurrentStatusWithReason(
    Object displayLabel,
    Object reasonSummary,
    Object fallback,
  );

  /// Settings Language Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// Settings Language Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Hindi is the launch default. You can switch to English here.'**
  String get settingsLanguageHelper;

  /// Settings Language English - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Settings Language Hindi - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get settingsLanguageHindi;

  /// Settings Language Saved English - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Language saved: English'**
  String get settingsLanguageSavedEnglish;

  /// Settings Language Saved Hindi - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Language saved: Hindi'**
  String get settingsLanguageSavedHindi;

  /// Settings Language Save Failed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not save your language preference right now. Retry shortly from settings.'**
  String get settingsLanguageSaveFailed;

  /// Settings Language Saving - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Saving language preference...'**
  String get settingsLanguageSaving;

  /// Trucker Dashboard Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use your trucker dashboard as the command center for freight discovery, readiness, and active work visibility.'**
  String get truckerDashboardHeroSubtitle;

  /// Welcome message on trucker dashboard. Placeholder {fullName} is the user's full name.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {fullName}'**
  String truckerDashboardWelcomeBack(Object fullName);

  /// Trucker Dashboard Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker Dashboard'**
  String get truckerDashboardTitle;

  /// Trucker Dashboard Overview Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dashboard overview'**
  String get truckerDashboardOverviewTitle;

  /// Trucker Dashboard Quick Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get truckerDashboardQuickActionsTitle;

  /// Trucker Dashboard Quick Action Trips Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get truckerDashboardQuickActionTripsLabel;

  /// Trucker Dashboard Quick Action Chat Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get truckerDashboardQuickActionChatLabel;

  /// Trucker Dashboard Recent Activity Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get truckerDashboardRecentActivityTitle;

  /// Trucker Dashboard Readiness Next Steps Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Readiness and next steps'**
  String get truckerDashboardReadinessNextStepsTitle;

  /// Trucker Dashboard Readiness Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Readiness state unavailable'**
  String get truckerDashboardReadinessUnavailableTitle;

  /// Trucker Dashboard Readiness Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your trucker readiness state is temporarily unavailable. Retry shortly to refresh verification and fleet readiness.'**
  String get truckerDashboardReadinessFailureMessage;

  /// Trucker Dashboard Verification Pending Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get truckerDashboardVerificationPendingTitle;

  /// Trucker Dashboard Verification Pending Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You can browse loads while review is pending, but chat and call stay locked until verification is complete.'**
  String get truckerDashboardVerificationPendingDescription;

  /// Trucker Dashboard Open Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open verification'**
  String get truckerDashboardOpenVerificationAction;

  /// Trucker Dashboard Verification Complete Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get truckerDashboardVerificationCompleteTitle;

  /// Trucker Dashboard Verification Complete Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your trucker verification is complete. Chat and call stay unlocked on open loads while your readiness remains healthy.'**
  String get truckerDashboardVerificationCompleteDescription;

  /// Trucker Dashboard Review Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review verification'**
  String get truckerDashboardReviewVerificationAction;

  /// Trucker Dashboard Verification Needs Attention Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification needs attention'**
  String get truckerDashboardVerificationNeedsAttentionTitle;

  /// Trucker Dashboard Verification Needs Attention Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification was rejected. Browsing stays open, but communication and assignment readiness remain blocked.'**
  String get truckerDashboardVerificationNeedsAttentionDescription;

  /// Trucker Dashboard Fix Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fix verification'**
  String get truckerDashboardFixVerificationAction;

  /// Trucker Dashboard Complete Fleet Verification Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete fleet and verification setup'**
  String get truckerDashboardCompleteFleetVerificationTitle;

  /// Trucker Dashboard Complete Fleet Verification Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You can browse the marketplace now, but chat, call, and booking stay locked until you finish Aadhaar, PAN, profile photo, and get at least one truck approved.'**
  String get truckerDashboardCompleteFleetVerificationMessage;

  /// Trucker Dashboard Open Fleet Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open fleet and verification'**
  String get truckerDashboardOpenFleetVerificationAction;

  /// Trucker Dashboard Add Approve First Truck Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add and approve your first truck'**
  String get truckerDashboardAddApproveFirstTruckTitle;

  /// Trucker Dashboard Add Approve First Truck Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Marketplace browsing is available now, but your first approved truck is required before full trucker verification can complete.'**
  String get truckerDashboardAddApproveFirstTruckMessage;

  /// Trucker Dashboard Open Fleet Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open fleet'**
  String get truckerDashboardOpenFleetAction;

  /// Trucker Dashboard Complete Verification Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker verification'**
  String get truckerDashboardCompleteVerificationTitle;

  /// Trucker Dashboard Complete Verification Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You can browse the marketplace now. Finish Aadhaar, PAN, profile photo, and at least one approved truck to unlock chat and call.'**
  String get truckerDashboardCompleteVerificationMessage;

  /// Trucker Dashboard Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your trucker dashboard'**
  String get truckerDashboardLoadFailureTitle;

  /// Trucker Dashboard Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your trucker dashboard right now. Retry shortly to refresh the latest KPIs and activity summary.'**
  String get truckerDashboardLoadFailureMessage;

  /// Trucker Dashboard Setup In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Setup in progress'**
  String get truckerDashboardSetupInProgress;

  /// Trucker Dashboard Verification Status Verified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get truckerDashboardVerificationStatusVerified;

  /// Trucker Dashboard Verification Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get truckerDashboardVerificationStatusPending;

  /// Trucker Dashboard Verification Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get truckerDashboardVerificationStatusRejected;

  /// Trucker Dashboard Verification Status Unverified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get truckerDashboardVerificationStatusUnverified;

  /// Trucker Dashboard Verification Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerDashboardVerificationStatusUnknown;

  /// No description provided for @truckerDashboardApprovedTruckCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {# approved truck} other {# approved trucks}}'**
  String truckerDashboardApprovedTruckCount(int count);

  /// Trucker Dashboard Hero Summary - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dashboard-first remains the trucker home rule: understand readiness, scan active work, then jump into freight discovery from here.'**
  String get truckerDashboardHeroSummary;

  /// Trucker Dashboard Stat Active Bids Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active bids'**
  String get truckerDashboardStatActiveBidsLabel;

  /// Trucker Dashboard Stat Active Bids Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submitted requests still waiting for supplier decision'**
  String get truckerDashboardStatActiveBidsHelper;

  /// Trucker Dashboard Stat Upcoming Trips Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trips'**
  String get truckerDashboardStatUpcomingTripsLabel;

  /// Trucker Dashboard Stat Upcoming Trips Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned and pickup-stage work approaching execution'**
  String get truckerDashboardStatUpcomingTripsHelper;

  /// Trucker Dashboard Stat In Transit Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In-transit'**
  String get truckerDashboardStatInTransitLabel;

  /// Trucker Dashboard Stat In Transit Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips currently moving on the road'**
  String get truckerDashboardStatInTransitHelper;

  /// Trucker Dashboard Stat Completed Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get truckerDashboardStatCompletedLabel;

  /// Trucker Dashboard Stat Completed Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips already closed in your trucker history'**
  String get truckerDashboardStatCompletedHelper;

  /// Trucker Dashboard Recent Activity Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recent activity unavailable'**
  String get truckerDashboardRecentActivityUnavailableTitle;

  /// Trucker Dashboard Recent Activity Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your latest booking, trip, and fleet activity right now.'**
  String get truckerDashboardRecentActivityUnavailableMessage;

  /// Trucker Dashboard No Recent Activity Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get truckerDashboardNoRecentActivityTitle;

  /// Trucker Dashboard No Recent Activity Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your booking requests, trip movement, and fleet review updates will appear here once work begins.'**
  String get truckerDashboardNoRecentActivitySubtitle;

  /// Trucker Dashboard Booking Activity Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking activity'**
  String get truckerDashboardBookingActivityTitle;

  /// No description provided for @truckerDashboardBookingActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} active bid waiting for supplier review} other {{count} active bids waiting for supplier review}}'**
  String truckerDashboardBookingActivitySubtitle(int count);

  /// Trucker Dashboard Trip Activity Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip activity'**
  String get truckerDashboardTripActivityTitle;

  /// No description provided for @truckerDashboardTripActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{upcomingTrips} upcoming - {inTransitTrips} in transit - {completedTrips} completed'**
  String truckerDashboardTripActivitySubtitle(
    int upcomingTrips,
    int inTransitTrips,
    int completedTrips,
  );

  /// Trucker Dashboard Fleet Review Activity Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fleet review activity'**
  String get truckerDashboardFleetReviewActivityTitle;

  /// No description provided for @truckerDashboardFleetReviewActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{pendingTrucks} pending - {rejectedTrucks} rejected - {pendingReapprovalTrucks} pending reapproval'**
  String truckerDashboardFleetReviewActivitySubtitle(
    int pendingTrucks,
    int rejectedTrucks,
    int pendingReapprovalTrucks,
  );

  /// Trucker Dashboard Status Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get truckerDashboardStatusOpen;

  /// Trucker Dashboard Status Clear - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'clear'**
  String get truckerDashboardStatusClear;

  /// Trucker Dashboard Status Moving - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'moving'**
  String get truckerDashboardStatusMoving;

  /// Trucker Dashboard Status Tracked - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'tracked'**
  String get truckerDashboardStatusTracked;

  /// Trucker Dashboard Status Attention - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'attention'**
  String get truckerDashboardStatusAttention;

  /// Trucker Dashboard Readiness Summary Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker readiness unavailable'**
  String get truckerDashboardReadinessSummaryUnavailableTitle;

  /// Trucker Dashboard Readiness Summary Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your readiness summary right now.'**
  String get truckerDashboardReadinessSummaryUnavailableMessage;

  /// Trucker Dashboard Profile Setup In Progress Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile setup still in progress'**
  String get truckerDashboardProfileSetupInProgressTitle;

  /// Trucker Dashboard Profile Setup In Progress Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard will show readiness details once your trucker profile finishes loading.'**
  String get truckerDashboardProfileSetupInProgressSubtitle;

  /// Trucker Dashboard Verification Status Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get truckerDashboardVerificationStatusTitle;

  /// Trucker Dashboard Verification Ready Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Chat and call are unlocked on open loads because your verification is complete.'**
  String get truckerDashboardVerificationReadyMessage;

  /// Trucker Dashboard Verification Locked Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Browsing is open now. Chat and call unlock only after verification and at least one approved truck.'**
  String get truckerDashboardVerificationLockedMessage;

  /// No description provided for @truckerDashboardDlLabel.
  ///
  /// In en, this message translates to:
  /// **'DL: {value}'**
  String truckerDashboardDlLabel(Object value);

  /// Trucker Dashboard Fleet Readiness Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fleet readiness'**
  String get truckerDashboardFleetReadinessTitle;

  /// No description provided for @truckerDashboardApprovedTrucksSummary.
  ///
  /// In en, this message translates to:
  /// **'{approvedTrucks}/{totalTrucks} approved trucks'**
  String truckerDashboardApprovedTrucksSummary(
    int approvedTrucks,
    int totalTrucks,
  );

  /// Trucker Dashboard Ready Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get truckerDashboardReadyStatus;

  /// Trucker Dashboard Action Needed Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'action needed'**
  String get truckerDashboardActionNeededStatus;

  /// Trucker Dashboard Fleet Ready Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You have at least one approved truck available for verification-dependent workflows.'**
  String get truckerDashboardFleetReadyMessage;

  /// Trucker Dashboard Fleet Need First Truck Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add and approve your first truck in the fleet slice to complete trucker readiness.'**
  String get truckerDashboardFleetNeedFirstTruckMessage;

  /// No description provided for @truckerDashboardTruckAwaitingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} awaiting review'**
  String truckerDashboardTruckAwaitingReview(int count);

  /// No description provided for @truckerDashboardTruckRejected.
  ///
  /// In en, this message translates to:
  /// **'{count} rejected'**
  String truckerDashboardTruckRejected(int count);

  /// No description provided for @truckerDashboardTruckPendingReapproval.
  ///
  /// In en, this message translates to:
  /// **'{count} pending reapproval'**
  String truckerDashboardTruckPendingReapproval(int count);

  /// No description provided for @truckerDashboardTruckLifecycleAttention.
  ///
  /// In en, this message translates to:
  /// **'Truck lifecycle attention: {segments}. Non-approved trucks stay blocked for new booking workflows until review is cleared.'**
  String truckerDashboardTruckLifecycleAttention(Object segments);

  /// Trucker Trips Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get truckerTripsTitle;

  /// Trucker Trips Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track assigned trips, monitor proof deadlines, and hand off the right action at the right trip stage.'**
  String get truckerTripsSubtitle;

  /// Trucker Trips Stage Assigned - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get truckerTripsStageAssigned;

  /// Trucker Trips Stage Pickup Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup pending'**
  String get truckerTripsStagePickupPending;

  /// Trucker Trips Stage Picked Up - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get truckerTripsStagePickedUp;

  /// Trucker Trips Stage In Transit - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get truckerTripsStageInTransit;

  /// Trucker Trips Stage Delivered - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get truckerTripsStageDelivered;

  /// Trucker Trips Stage Proof Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted'**
  String get truckerTripsStageProofSubmitted;

  /// Trucker Trips Stage Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get truckerTripsStageCompleted;

  /// Trucker Trips Stage Disputed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get truckerTripsStageDisputed;

  /// Trucker Trips Stage Cancelled - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get truckerTripsStageCancelled;

  /// Trucker Trips Stage Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerTripsStageUnknown;

  /// Trucker Trips Proof Status Pod Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded'**
  String get truckerTripsProofStatusPodUploaded;

  /// Trucker Trips Proof Status Lr Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'LR uploaded'**
  String get truckerTripsProofStatusLrUploaded;

  /// Trucker Trips Proof Status Awaiting Pod - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Awaiting POD'**
  String get truckerTripsProofStatusAwaitingPod;

  /// Trucker Trips Proof Status Proof Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted'**
  String get truckerTripsProofStatusProofSubmitted;

  /// Trucker Trips Proof Status Proof Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof pending'**
  String get truckerTripsProofStatusProofPending;

  /// Trucker Trips Tab Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get truckerTripsTabActive;

  /// Trucker Trips Tab Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get truckerTripsTabCompleted;

  /// Trucker Trips Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trips'**
  String get truckerTripsLoadFailureTitle;

  /// Trucker Trips Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your trips right now. Retry shortly to refresh the latest execution timeline.'**
  String get truckerTripsLoadFailureMessage;

  /// Trucker Trips Empty Active Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get truckerTripsEmptyActiveTitle;

  /// Trucker Trips Empty Completed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get truckerTripsEmptyCompletedTitle;

  /// Trucker Trips Empty Active Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Book a load and wait for supplier approval to start your first trip.'**
  String get truckerTripsEmptyActiveSubtitle;

  /// Trucker Trips Empty Completed Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled trips will appear here after execution closes.'**
  String get truckerTripsEmptyCompletedSubtitle;

  /// Trucker Trips Empty Active Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Find loads'**
  String get truckerTripsEmptyActiveAction;

  /// Trucker Trips Empty Completed Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'View active trips'**
  String get truckerTripsEmptyCompletedAction;

  /// Trucker Trip Detail Not Found Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get truckerTripDetailNotFoundTitle;

  /// Trucker Trip Detail Not Found Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This assigned trip is no longer available or you no longer have access to it.'**
  String get truckerTripDetailNotFoundSubtitle;

  /// Trucker Trip Detail Back To Trips Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to my trips'**
  String get truckerTripDetailBackToTripsAction;

  /// No description provided for @truckerTripsTimeContextAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned {date}'**
  String truckerTripsTimeContextAssigned(Object date);

  /// No description provided for @truckerTripsTimeContextDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered {date}'**
  String truckerTripsTimeContextDelivered(Object date);

  /// No description provided for @truckerTripsTimeContextPodUploaded.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded {date}'**
  String truckerTripsTimeContextPodUploaded(Object date);

  /// No description provided for @truckerTripsTimeContextCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed {date}'**
  String truckerTripsTimeContextCompleted(Object date);

  /// No description provided for @truckerTripsTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck {truckNumber}'**
  String truckerTripsTruckLabel(Object truckNumber);

  /// Trucker Fleet Hero Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Manage truck readiness'**
  String get truckerFleetHeroTitle;

  /// Trucker Fleet Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track truck approval, review rejection guidance, and keep RC details current so booking-ready trucks stay available.'**
  String get truckerFleetHeroSubtitle;

  /// Trucker Fleet Editing Truck Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Editing truck'**
  String get truckerFleetEditingTruckAction;

  /// Trucker Fleet Add Truck Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add truck'**
  String get truckerFleetAddTruckAction;

  /// No description provided for @truckerFleetTruckCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} truck} other {{count} trucks}}'**
  String truckerFleetTruckCount(int count);

  /// No description provided for @truckerFleetApprovedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} approved'**
  String truckerFleetApprovedCount(int count);

  /// Trucker Fleet Action Attention Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck action needs attention'**
  String get truckerFleetActionAttentionTitle;

  /// Trucker Fleet Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The latest truck action could not be completed right now. Review the truck details and retry shortly.'**
  String get truckerFleetActionFailureMessage;

  /// Trucker Fleet Edit Truck Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Edit truck'**
  String get truckerFleetEditTruckTitle;

  /// Trucker Fleet Add Or Update Truck Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add or update truck'**
  String get truckerFleetAddOrUpdateTruckTitle;

  /// Trucker Fleet Truck Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck number'**
  String get truckerFleetTruckNumberLabel;

  /// Trucker Fleet Truck Number Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'MH12AB1234'**
  String get truckerFleetTruckNumberHint;

  /// Trucker Fleet Body Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get truckerFleetBodyTypeLabel;

  /// No description provided for @truckerFleetBodyTypeOption.
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String truckerFleetBodyTypeOption(Object value);

  /// Trucker Fleet Tyres Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tyres'**
  String get truckerFleetTyresLabel;

  /// No description provided for @truckerFleetTyresOption.
  ///
  /// In en, this message translates to:
  /// **'{tyres} tyres'**
  String truckerFleetTyresOption(int tyres);

  /// Trucker Fleet Capacity Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Capacity (tonnes)'**
  String get truckerFleetCapacityLabel;

  /// Trucker Fleet Capacity Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'25'**
  String get truckerFleetCapacityHint;

  /// Trucker Fleet Rc Document Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC document'**
  String get truckerFleetRcDocumentTitle;

  /// Trucker Fleet Rc Uploaded Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC image uploaded and linked to this truck draft.'**
  String get truckerFleetRcUploadedSubtitle;

  /// Trucker Fleet Rc Required Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload the truck RC before saving this truck.'**
  String get truckerFleetRcRequiredSubtitle;

  /// Trucker Fleet Uploaded Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'uploaded'**
  String get truckerFleetUploadedStatus;

  /// Trucker Fleet Required Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get truckerFleetRequiredStatus;

  /// No description provided for @truckerFleetStoredPath.
  ///
  /// In en, this message translates to:
  /// **'Stored path: {path}'**
  String truckerFleetStoredPath(Object path);

  /// Trucker Fleet Replace Rc Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Replace RC document'**
  String get truckerFleetReplaceRcAction;

  /// Trucker Fleet Upload Rc Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload RC document'**
  String get truckerFleetUploadRcAction;

  /// Trucker Fleet Rc Uploaded Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC uploaded successfully'**
  String get truckerFleetRcUploadedSuccess;

  /// Trucker Fleet Rc Updated Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC document updated successfully'**
  String get truckerFleetRcUpdatedSuccess;

  /// Trucker Fleet Save Truck Updates Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Save truck updates'**
  String get truckerFleetSaveTruckUpdatesAction;

  /// Trucker Fleet Save Truck Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Save truck'**
  String get truckerFleetSaveTruckAction;

  /// Trucker Fleet Truck Updated Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck updated successfully'**
  String get truckerFleetTruckUpdatedSuccess;

  /// Trucker Fleet Truck Added Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck added successfully'**
  String get truckerFleetTruckAddedSuccess;

  /// Trucker Fleet My Trucks Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'My trucks'**
  String get truckerFleetMyTrucksTitle;

  /// Trucker Fleet Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fleet unavailable'**
  String get truckerFleetUnavailableTitle;

  /// Trucker Fleet Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your fleet right now. Retry shortly to refresh the latest truck readiness and approval state.'**
  String get truckerFleetLoadFailureMessage;

  /// Trucker Fleet No Trucks Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No trucks added yet'**
  String get truckerFleetNoTrucksTitle;

  /// Trucker Fleet No Trucks Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add your first truck with its RC document so trucker verification can progress toward approval.'**
  String get truckerFleetNoTrucksSubtitle;

  /// Trucker Fleet Select Rc Source Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload RC document'**
  String get truckerFleetSelectRcSourceTitle;

  /// Trucker Fleet Take Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get truckerFleetTakePhotoAction;

  /// Trucker Fleet Choose Gallery Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get truckerFleetChooseGalleryAction;

  /// Trucker Fleet Rc Upload Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the RC document right now. Try another image or retry shortly.'**
  String get truckerFleetRcUploadFailureMessage;

  /// Trucker Fleet Save Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not save this truck right now. Review the truck details and retry shortly.'**
  String get truckerFleetSaveFailureMessage;

  /// Trucker Fleet Truck Number Conflict Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This truck number is already in use. Check the number and try again.'**
  String get truckerFleetTruckNumberConflictMessage;

  /// No description provided for @truckerFleetTruckCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{bodyType} - {tyres} tyres - {capacityTonnes}T'**
  String truckerFleetTruckCardSubtitle(
    Object bodyType,
    Object tyres,
    Object capacityTonnes,
  );

  /// No description provided for @truckerFleetModelLabel.
  ///
  /// In en, this message translates to:
  /// **'Model: {value}'**
  String truckerFleetModelLabel(Object value);

  /// No description provided for @truckerFleetReviewSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Review summary: {value}'**
  String truckerFleetReviewSummaryLabel(Object value);

  /// No description provided for @truckerFleetNextStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Next step: {value}'**
  String truckerFleetNextStepLabel(Object value);

  /// Trucker Fleet Blocked Booking Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This truck is blocked for approval-dependent booking workflows until review clears.'**
  String get truckerFleetBlockedBookingMessage;

  /// Trucker Fleet Fix Resubmit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fix and resubmit truck'**
  String get truckerFleetFixResubmitAction;

  /// Trucker Fleet Edit Truck Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Edit truck'**
  String get truckerFleetEditTruckAction;

  /// Trucker Fleet Status Pending Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get truckerFleetStatusPendingLabel;

  /// Trucker Fleet Status Verified Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get truckerFleetStatusVerifiedLabel;

  /// Trucker Fleet Status Rejected Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get truckerFleetStatusRejectedLabel;

  /// Trucker Fleet Status Edited Pending Reapproval Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending reapproval'**
  String get truckerFleetStatusEditedPendingReapprovalLabel;

  /// Trucker Fleet Status Archived Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get truckerFleetStatusArchivedLabel;

  /// Trucker Fleet Status Unknown Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerFleetStatusUnknownLabel;

  /// Trucker Fleet Status Pending Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your truck is waiting for admin review. Approval is required before this truck can be used for booking.'**
  String get truckerFleetStatusPendingMessage;

  /// Trucker Fleet Status Verified Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This truck is approved and available for verification-dependent workflows.'**
  String get truckerFleetStatusVerifiedMessage;

  /// Trucker Fleet Status Rejected Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This truck was rejected. Review the guidance below and update the affected details or RC document.'**
  String get truckerFleetStatusRejectedFallback;

  /// Trucker Fleet Status Edited Pending Reapproval Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This truck stays visible, but recent edits sent it back for reapproval before it can be used again.'**
  String get truckerFleetStatusEditedPendingReapprovalMessage;

  /// Trucker Fleet Status Archived Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This truck is archived and no longer available for normal booking workflows.'**
  String get truckerFleetStatusArchivedMessage;

  /// Trucker Fleet Status Unknown Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck review state is currently unavailable.'**
  String get truckerFleetStatusUnknownMessage;

  /// Trucker Find Loads Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Scan compact freight cards, keep filters tight, and move quickly from route interest to load evaluation.'**
  String get truckerFindLoadsHeroSubtitle;

  /// Trucker Find Loads Advanced Filters Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get truckerFindLoadsAdvancedFiltersAction;

  /// Trucker Find Loads Origin Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin city'**
  String get truckerFindLoadsOriginHint;

  /// Trucker Find Loads Destination Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination city'**
  String get truckerFindLoadsDestinationHint;

  /// Trucker Find Loads Material Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get truckerFindLoadsMaterialHint;

  /// Trucker Find Loads Sort By Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get truckerFindLoadsSortByLabel;

  /// Trucker Find Loads Sort Newest - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get truckerFindLoadsSortNewest;

  /// Trucker Find Loads Sort Price High To Low - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Price High>Low'**
  String get truckerFindLoadsSortPriceHighToLow;

  /// Trucker Find Loads Sort Price Low To High - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Price Low>High'**
  String get truckerFindLoadsSortPriceLowToHigh;

  /// Trucker Find Loads Sort Pickup Date - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get truckerFindLoadsSortPickupDate;

  /// Trucker Find Loads Marketplace Tabs Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Marketplace tabs'**
  String get truckerFindLoadsMarketplaceTabsTitle;

  /// Trucker Find Loads All Loads Tab - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'All Loads'**
  String get truckerFindLoadsAllLoadsTab;

  /// Trucker Find Loads Super Loads Tab - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Loads'**
  String get truckerFindLoadsSuperLoadsTab;

  /// Trucker Find Loads Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load freight'**
  String get truckerFindLoadsLoadFailureTitle;

  /// Trucker Find Loads Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load marketplace freight right now. Retry shortly to refresh the latest load search results.'**
  String get truckerFindLoadsLoadFailureMessage;

  /// Trucker Find Loads Empty Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No loads found'**
  String get truckerFindLoadsEmptyTitle;

  /// Trucker Find Loads Empty Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your city, material, or advanced filters to widen the marketplace search.'**
  String get truckerFindLoadsEmptySubtitle;

  /// Trucker Find Loads Load More Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'More loads unavailable'**
  String get truckerFindLoadsLoadMoreFailureTitle;

  /// Trucker Find Loads Load More Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load more freight right now. Retry shortly to continue the marketplace search.'**
  String get truckerFindLoadsLoadMoreFailureMessage;

  /// No description provided for @truckerFindLoadsSummaryFrom.
  ///
  /// In en, this message translates to:
  /// **'From {city}'**
  String truckerFindLoadsSummaryFrom(Object city);

  /// No description provided for @truckerFindLoadsSummaryTo.
  ///
  /// In en, this message translates to:
  /// **'To {city}'**
  String truckerFindLoadsSummaryTo(Object city);

  /// No description provided for @truckerFindLoadsSummaryTyres.
  ///
  /// In en, this message translates to:
  /// **'{value} tyre'**
  String truckerFindLoadsSummaryTyres(Object value);

  /// No description provided for @truckerFindLoadsSummaryPriceRange.
  ///
  /// In en, this message translates to:
  /// **'₹{minPrice}-{maxPrice}'**
  String truckerFindLoadsSummaryPriceRange(Object minPrice, Object maxPrice);

  /// Trucker Find Loads Summary Super Loads - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Loads'**
  String get truckerFindLoadsSummarySuperLoads;

  /// No description provided for @truckerFindLoadsSummaryAllLoads.
  ///
  /// In en, this message translates to:
  /// **'Showing all loads - {resultCount} result(s)'**
  String truckerFindLoadsSummaryAllLoads(int resultCount);

  /// No description provided for @truckerFindLoadsSummaryFiltered.
  ///
  /// In en, this message translates to:
  /// **'{pieces} - {resultCount} result(s)'**
  String truckerFindLoadsSummaryFiltered(Object pieces, int resultCount);

  /// Trucker Find Loads Reset Filters Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get truckerFindLoadsResetFiltersAction;

  /// Trucker Find Loads Any Body Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Any body'**
  String get truckerFindLoadsAnyBodyFallback;

  /// Trucker Find Loads Status Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get truckerFindLoadsStatusActive;

  /// Trucker Find Loads Status Assigned Partial - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned Partial'**
  String get truckerFindLoadsStatusAssignedPartial;

  /// Trucker Find Loads Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerFindLoadsStatusUnknown;

  /// No description provided for @truckerFindLoadsStatusUnknownFallback.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get truckerFindLoadsStatusUnknownFallback;

  /// No description provided for @truckerFindLoadsPriceAdvancePickup.
  ///
  /// In en, this message translates to:
  /// **'₹{priceAmount} - {advancePercentage}% adv - {pickupDate}'**
  String truckerFindLoadsPriceAdvancePickup(
    Object priceAmount,
    int advancePercentage,
    Object pickupDate,
  );

  /// Trucker Find Loads Truck Match Available - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck match available'**
  String get truckerFindLoadsTruckMatchAvailable;

  /// Trucker Find Loads No Approved Truck Match - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No approved truck match yet'**
  String get truckerFindLoadsNoApprovedTruckMatch;

  /// Trucker Find Loads Trip Cost Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip cost unavailable'**
  String get truckerFindLoadsTripCostUnavailable;

  /// No description provided for @truckerFindLoadsDistanceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Distance unavailable - Tyres {tyres}'**
  String truckerFindLoadsDistanceUnavailable(Object tyres);

  /// No description provided for @truckerFindLoadsDistanceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Distance {distanceKm} km - Tyres {tyres}'**
  String truckerFindLoadsDistanceAvailable(Object distanceKm, Object tyres);

  /// Trucker Find Loads Tyres Any - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get truckerFindLoadsTyresAny;

  /// Trucker Find Loads Super Load Banner - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Load - Payment Guarantee'**
  String get truckerFindLoadsSuperLoadBanner;

  /// Trucker Find Loads View Details Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get truckerFindLoadsViewDetailsAction;

  /// Trucker Find Loads Advanced Filters Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get truckerFindLoadsAdvancedFiltersTitle;

  /// Trucker Find Loads Truck Body Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck body type'**
  String get truckerFindLoadsTruckBodyTypeLabel;

  /// Trucker Find Loads Body Type Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get truckerFindLoadsBodyTypeOpen;

  /// Trucker Find Loads Body Type Trailer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get truckerFindLoadsBodyTypeTrailer;

  /// Trucker Find Loads Body Type Container - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get truckerFindLoadsBodyTypeContainer;

  /// Trucker Find Loads Body Type Tanker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get truckerFindLoadsBodyTypeTanker;

  /// Trucker Find Loads Body Type Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerFindLoadsBodyTypeUnknown;

  /// Trucker Find Loads Tyre Requirement Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tyre requirement'**
  String get truckerFindLoadsTyreRequirementTitle;

  /// Trucker Find Loads Min Price Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Min price (₹)'**
  String get truckerFindLoadsMinPriceLabel;

  /// Trucker Find Loads Max Price Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Max price (₹)'**
  String get truckerFindLoadsMaxPriceLabel;

  /// Trucker Find Loads Apply Filters Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get truckerFindLoadsApplyFiltersAction;

  /// Trucker Find Loads Reset Advanced Filters Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reset advanced filters'**
  String get truckerFindLoadsResetAdvancedFiltersAction;

  /// Supplier Post Load Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get supplierPostLoadTitle;

  /// Supplier Post Load Hero Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Create a supplier load'**
  String get supplierPostLoadHeroTitle;

  /// Supplier Post Load Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use one clean scrolling form to define route, cargo, vehicle requirements, pricing, and pickup timing.'**
  String get supplierPostLoadHeroSubtitle;

  /// Supplier Post Load Hero Helper - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Manual city entry still works if route services do not return a preview. Your form data stays intact on validation or submission failure.'**
  String get supplierPostLoadHeroHelper;

  /// Supplier Post Load Posting Blocked Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Posting is blocked'**
  String get supplierPostLoadPostingBlockedTitle;

  /// Supplier Post Load Open Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open verification'**
  String get supplierPostLoadOpenVerificationAction;

  /// Supplier Post Load Route Timing Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route and timing'**
  String get supplierPostLoadRouteTimingTitle;

  /// Supplier Post Load Origin City Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin city'**
  String get supplierPostLoadOriginCityLabel;

  /// Supplier Post Load Search City Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get supplierPostLoadSearchCityHint;

  /// Supplier Post Load Origin Exact Location Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin exact location'**
  String get supplierPostLoadOriginExactLocationLabel;

  /// Supplier Post Load Origin Exact Location Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Warehouse / pickup point'**
  String get supplierPostLoadOriginExactLocationHint;

  /// Supplier Post Load Destination City Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination city'**
  String get supplierPostLoadDestinationCityLabel;

  /// Supplier Post Load Destination Exact Location Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination exact location'**
  String get supplierPostLoadDestinationExactLocationLabel;

  /// Supplier Post Load Destination Exact Location Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Drop point / delivery point'**
  String get supplierPostLoadDestinationExactLocationHint;

  /// Supplier Post Load Pickup Date Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup date'**
  String get supplierPostLoadPickupDateLabel;

  /// Supplier Post Load Route Preview Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route preview'**
  String get supplierPostLoadRoutePreviewTitle;

  /// Shows route distance in kilometers. Placeholder {value} is the numeric distance.
  ///
  /// In en, this message translates to:
  /// **'Distance: {value} km'**
  String supplierPostLoadDistanceLabel(Object value);

  /// Shows estimated drive time in minutes. Placeholder {minutes} is the numeric drive time.
  ///
  /// In en, this message translates to:
  /// **'Est. drive time: {minutes} min'**
  String supplierPostLoadDriveTimeLabel(int minutes);

  /// Supplier Post Load Route Preview Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route preview unavailable'**
  String get supplierPostLoadRoutePreviewUnavailableTitle;

  /// Supplier Post Load Route Preview Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route distance and duration could not be derived right now. You can still continue with manual city-based posting.'**
  String get supplierPostLoadRoutePreviewUnavailableMessage;

  /// Supplier Post Load Cargo Details Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cargo details'**
  String get supplierPostLoadCargoDetailsTitle;

  /// Supplier Post Load Material Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get supplierPostLoadMaterialLabel;

  /// Supplier Post Load Weight Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Weight (tonnes)'**
  String get supplierPostLoadWeightLabel;

  /// Supplier Post Load Weight Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'22'**
  String get supplierPostLoadWeightHint;

  /// Supplier Post Load Vehicle Requirements Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Vehicle requirements'**
  String get supplierPostLoadVehicleRequirementsTitle;

  /// Supplier Post Load Truck Body Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck body type'**
  String get supplierPostLoadTruckBodyTypeLabel;

  /// Supplier Post Load Tyre Requirement Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tyre requirement'**
  String get supplierPostLoadTyreRequirementTitle;

  /// Supplier Post Load Any Tyres Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get supplierPostLoadAnyTyresLabel;

  /// Supplier Post Load Trucks Needed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucks needed'**
  String get supplierPostLoadTrucksNeededTitle;

  /// Supplier Post Load Trucks Needed Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucks needed'**
  String get supplierPostLoadTrucksNeededLabel;

  /// Supplier Post Load Trucks Needed Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get supplierPostLoadTrucksNeededHint;

  /// Supplier Post Load Pricing Schedule Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pricing and schedule'**
  String get supplierPostLoadPricingScheduleTitle;

  /// Supplier Post Load Price Amount Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Price amount (₹)'**
  String get supplierPostLoadPriceAmountLabel;

  /// Supplier Post Load Price Amount Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'54000'**
  String get supplierPostLoadPriceAmountHint;

  /// Supplier Post Load Price Type Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get supplierPostLoadPriceTypeTitle;

  /// Supplier Post Load Price Type Fixed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fixed'**
  String get supplierPostLoadPriceTypeFixed;

  /// Supplier Post Load Price Type Negotiable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Per Ton'**
  String get supplierPostLoadPriceTypeNegotiable;

  /// Supplier Post Load Price Type Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supplierPostLoadPriceTypeUnknown;

  /// Shows advance payment percentage. Placeholder {value} is the percentage amount.
  ///
  /// In en, this message translates to:
  /// **'Advance percentage: {value}%'**
  String supplierPostLoadAdvancePercentageLabel(int value);

  /// No description provided for @supplierPostLoadAdvanceBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Advance: ₹{advanceAmount} - Balance: ₹{balanceAmount}'**
  String supplierPostLoadAdvanceBalanceLabel(
    Object advanceAmount,
    Object balanceAmount,
  );

  /// Supplier Post Load Review Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review summary'**
  String get supplierPostLoadReviewSummaryTitle;

  /// Supplier Post Load Origin Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin pending'**
  String get supplierPostLoadOriginPending;

  /// Supplier Post Load Destination Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination pending'**
  String get supplierPostLoadDestinationPending;

  /// No description provided for @supplierPostLoadRouteSummary.
  ///
  /// In en, this message translates to:
  /// **'{origin} > {destination}'**
  String supplierPostLoadRouteSummary(Object origin, Object destination);

  /// No description provided for @supplierPostLoadCargoSummary.
  ///
  /// In en, this message translates to:
  /// **'{material} - {weightTonnes}T - {trucksNeeded} truck(s)'**
  String supplierPostLoadCargoSummary(
    Object material,
    Object weightTonnes,
    Object trucksNeeded,
  );

  /// No description provided for @supplierPostLoadPriceSummary.
  ///
  /// In en, this message translates to:
  /// **'Price: ₹{priceAmount} - {priceType}'**
  String supplierPostLoadPriceSummary(Object priceAmount, Object priceType);

  /// No description provided for @supplierPostLoadPickupSummary.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {pickupDate}'**
  String supplierPostLoadPickupSummary(Object pickupDate);

  /// Supplier Post Load Submission Failed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get supplierPostLoadSubmissionFailedTitle;

  /// Supplier Post Load Complete Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to post load'**
  String get supplierPostLoadCompleteVerificationAction;

  /// Supplier Post Load Submit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get supplierPostLoadSubmitAction;

  /// Supplier Post Load Created Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load created successfully'**
  String get supplierPostLoadCreatedSuccess;

  /// Supplier Post Load Submission Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not prepare this load submission right now. Review the load details and retry shortly.'**
  String get supplierPostLoadSubmissionFailureMessage;

  /// Supplier Post Load Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not create this load right now. Review the load details and retry shortly.'**
  String get supplierPostLoadSubmitFailureMessage;

  /// Supplier Post Load Verification Checking Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Checking supplier verification before enabling load posting.'**
  String get supplierPostLoadVerificationCheckingMessage;

  /// Supplier Post Load Verification Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm supplier verification right now. Retry shortly or open verification to review your trust status.'**
  String get supplierPostLoadVerificationUnavailableMessage;

  /// Supplier Post Load Profile Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier profile is unavailable right now. Retry shortly before posting this load.'**
  String get supplierPostLoadProfileUnavailableMessage;

  /// Supplier Post Load Verification Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier verification before posting loads. Upload identity and business documents, then submit them for review.'**
  String get supplierPostLoadVerificationRequiredMessage;

  /// Verification Readiness Check Aadhaar Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get verificationReadinessCheckAadhaarNumber;

  /// Verification Readiness Check Pan Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN number'**
  String get verificationReadinessCheckPanNumber;

  /// Verification Readiness Check Aadhaar Front Photo - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar front photo'**
  String get verificationReadinessCheckAadhaarFrontPhoto;

  /// Verification Readiness Check Aadhaar Back Photo - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar back photo'**
  String get verificationReadinessCheckAadhaarBackPhoto;

  /// Verification Readiness Check Pan Photo - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN photo'**
  String get verificationReadinessCheckPanPhoto;

  /// Verification Readiness Check Company Name - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get verificationReadinessCheckCompanyName;

  /// Verification Readiness Check Business Licence Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence number'**
  String get verificationReadinessCheckBusinessLicenceNumber;

  /// Verification Readiness Check Business Licence Document - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence document'**
  String get verificationReadinessCheckBusinessLicenceDocument;

  /// Verification Readiness Check Location - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification location'**
  String get verificationReadinessCheckLocation;

  /// Verification Readiness Check Truck With Rc Document - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck with RC document'**
  String get verificationReadinessCheckTruckWithRcDocument;

  /// Verification Submit Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get verificationSubmitSectionTitle;

  /// Verification Submit Section Title Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Submit for Verification'**
  String get verificationSubmitSectionTitleTrucker;

  /// Verification Submit Section Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete all items below, then tap Submit to send your documents for admin review.'**
  String get verificationSubmitSectionSubtitle;

  /// No description provided for @verificationReadinessCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{doneCount} / {totalCount} completed'**
  String verificationReadinessCompletedCount(int doneCount, int totalCount);

  /// Verification Open Fleet Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add or manage your truck with RC document from the fleet screen.'**
  String get verificationOpenFleetHint;

  /// No description provided for @supplierPostLoadSuggestionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{label} - {source}'**
  String supplierPostLoadSuggestionSubtitle(Object label, Object source);

  /// Supplier Dashboard Verification Status Verified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get supplierDashboardVerificationStatusVerified;

  /// Supplier Dashboard Verification Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get supplierDashboardVerificationStatusPending;

  /// Supplier Dashboard Verification Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get supplierDashboardVerificationStatusRejected;

  /// Supplier Dashboard Verification Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supplierDashboardVerificationStatusUnknown;

  /// Supplier Verification Pending Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get supplierVerificationPendingTitle;

  /// Supplier Verification Pending Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification is under review. Keep documents ready in case the support team asks for clarification.'**
  String get supplierVerificationPendingMessage;

  /// Supplier Verification Rejected Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification needs attention'**
  String get supplierVerificationRejectedTitle;

  /// Supplier Verification Complete Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your supplier verification is complete. You can keep posting loads and monitoring readiness from this dashboard.'**
  String get supplierVerificationCompleteDescription;

  /// Supplier Verification Needs Attention Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification needs attention'**
  String get supplierVerificationNeedsAttentionTitle;

  /// Supplier Verification Needs Attention Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the latest verification feedback, update the required documents, and resubmit when you are ready.'**
  String get supplierVerificationNeedsAttentionDescription;

  /// Supplier Open Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open verification'**
  String get supplierOpenVerification;

  /// Supplier Review Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review verification'**
  String get supplierReviewVerification;

  /// No description provided for @supplierDashboardVerificationStatusUnknownFallback.
  ///
  /// In en, this message translates to:
  /// **'Unknown verification status'**
  String get supplierDashboardVerificationStatusUnknownFallback;

  /// Supplier Fix Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fix verification'**
  String get supplierFixVerification;

  /// Supplier Complete Setup Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete your supplier setup'**
  String get supplierCompleteSetupTitle;

  /// Supplier Complete Setup Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier verification and add your company details before using the full supplier workspace.'**
  String get supplierCompleteSetupMessage;

  /// Supplier Complete Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete verification'**
  String get supplierCompleteVerification;

  /// Supplier Dashboard Super Load Readiness Intro - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Load eligibility is still partially admin-managed in the current app. This surface shows only the readiness facts the current profile model can confirm honestly.'**
  String get supplierDashboardSuperLoadReadinessIntro;

  /// Supplier Dashboard Super Load Verification Complete - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get supplierDashboardSuperLoadVerificationComplete;

  /// Supplier Dashboard Super Load Verification Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification still required'**
  String get supplierDashboardSuperLoadVerificationRequired;

  /// Supplier Dashboard Super Load Business Licence On File - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence on file'**
  String get supplierDashboardSuperLoadBusinessLicenceOnFile;

  /// Supplier Dashboard Super Load Business Licence Missing - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence missing'**
  String get supplierDashboardSuperLoadBusinessLicenceMissing;

  /// Supplier Dashboard Super Load Company Age Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company-age readiness unavailable in current app data'**
  String get supplierDashboardSuperLoadCompanyAgeUnavailable;

  /// Supplier Dashboard Super Load Readiness Summary Ready - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your current profile can confirm supplier verification and the business licence prerequisite, but final Super Load eligibility still cannot be determined here because company-age/readiness fields are not yet present in the current source model.'**
  String get supplierDashboardSuperLoadReadinessSummaryReady;

  /// Supplier Dashboard Super Load Readiness Summary Missing Business Licence - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your supplier verification is complete, but the business licence prerequisite is still missing from the current profile. Final Super Load eligibility remains blocked until that verification requirement is satisfied.'**
  String get supplierDashboardSuperLoadReadinessSummaryMissingBusinessLicence;

  /// Supplier Dashboard Super Load Readiness Summary Missing Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your current profile can confirm a business licence on file, but supplier verification is still incomplete. Final Super Load eligibility remains blocked until verification is completed and company-age/readiness fields exist in the current source model.'**
  String get supplierDashboardSuperLoadReadinessSummaryMissingVerification;

  /// Supplier Dashboard Super Load Readiness Summary Pending Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your supplier verification is already under review. Super Load readiness cannot move forward until that review completes, and final eligibility still remains admin-managed until company-age/readiness fields exist in the current source model.'**
  String get supplierDashboardSuperLoadReadinessSummaryPendingVerification;

  /// Supplier Dashboard Super Load Readiness Summary Rejected Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your supplier verification needs correction before Super Load readiness can move forward. Review the latest verification feedback, update the required documents, and then re-check this readiness surface once the packet is resubmitted.'**
  String get supplierDashboardSuperLoadReadinessSummaryRejectedVerification;

  /// Supplier Dashboard Super Load Readiness Summary Needs Attention - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both supplier verification and the business licence prerequisite still need attention before Super Load readiness can move closer to eligibility. Even after that, final eligibility remains admin-managed until company-age/readiness fields exist in the current source model.'**
  String get supplierDashboardSuperLoadReadinessSummaryNeedsAttention;

  /// Supplier Dashboard Super Load Next Step Ready - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next best action: keep your verification details accurate, monitor your loads normally, and use support only if you need follow-up on Super Load review or policy questions.'**
  String get supplierDashboardSuperLoadNextStepReady;

  /// Supplier Dashboard Super Load Next Step Business Licence - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next best action: update or upload the business licence through verification first, then re-check this readiness surface.'**
  String get supplierDashboardSuperLoadNextStepBusinessLicence;

  /// Supplier Dashboard Super Load Next Step Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next best action: complete supplier verification so the platform can confirm your trust baseline before any future Super Load review.'**
  String get supplierDashboardSuperLoadNextStepVerification;

  /// Supplier Dashboard Super Load Next Step Pending Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next best action: monitor the current verification review, keep business documents stable, and use support only if the review needs clarification while approval is still pending.'**
  String get supplierDashboardSuperLoadNextStepPendingVerification;

  /// Supplier Dashboard Super Load Next Step Rejected Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next best action: fix the rejected verification items first, resubmit the packet for review, and then return here for the refreshed readiness summary.'**
  String get supplierDashboardSuperLoadNextStepRejectedVerification;

  /// Supplier Dashboard Super Load Next Step Needs Attention - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next best action: complete supplier verification and business licence requirements first, then return here for the remaining readiness summary.'**
  String get supplierDashboardSuperLoadNextStepNeedsAttention;

  /// Supplier Dashboard Load Status Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get supplierDashboardLoadStatusActive;

  /// Supplier Load Status Assigned Partial - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned partial'**
  String get supplierLoadStatusAssignedPartial;

  /// Supplier Load Status Assigned Full - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned full'**
  String get supplierLoadStatusAssignedFull;

  /// Supplier Load Status In Transit - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get supplierLoadStatusInTransit;

  /// Supplier Load Status Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get supplierLoadStatusCompleted;

  /// Supplier Load Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supplierLoadStatusUnknown;

  /// Supplier Load Status Filled Outside App - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Filled outside app'**
  String get supplierLoadStatusFilledOutsideApp;

  /// Supplier Load Status Cancelled - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get supplierLoadStatusCancelled;

  /// Supplier Load Status Expired - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get supplierLoadStatusExpired;

  /// Supplier Load Status Deactivated - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Deactivated'**
  String get supplierLoadStatusDeactivated;

  /// No description provided for @supplierDashboardTrucksBooked.
  ///
  /// In en, this message translates to:
  /// **'{booked}/{needed} trucks booked'**
  String supplierDashboardTrucksBooked(int booked, int needed);

  /// Pickup date for a load on the supplier dashboard.
  ///
  /// In en, this message translates to:
  /// **'Pickup {value}'**
  String supplierDashboardLoadPickup(Object value);

  /// Supplier Dashboard Open Loads Workspace - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open loads workspace'**
  String get supplierDashboardOpenLoadsWorkspace;

  /// Supplier Dashboard Super Load Status Request Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Request submitted'**
  String get supplierDashboardSuperLoadStatusRequestSubmitted;

  /// Supplier Dashboard Super Load Status Under Review - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get supplierDashboardSuperLoadStatusUnderReview;

  /// Supplier Dashboard Super Load Status Approved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approved - payment pending'**
  String get supplierDashboardSuperLoadStatusApproved;

  /// Supplier Dashboard Super Load Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get supplierDashboardSuperLoadStatusRejected;

  /// Supplier Dashboard Super Load Status Expired Or Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supplierDashboardSuperLoadStatusExpiredOrClosed;

  /// Supplier Dashboard Super Load Status Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get supplierDashboardSuperLoadStatusActive;

  /// Supplier Dashboard Super Load Status Not Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Not requested'**
  String get supplierDashboardSuperLoadStatusNotActive;

  /// No description provided for @supplierDashboardSuperLoadBadge.
  ///
  /// In en, this message translates to:
  /// **'Super Load - {status}'**
  String supplierDashboardSuperLoadBadge(Object status);

  /// Supplier Dashboard Super Load Guidance Request Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This Super Load request is submitted and waiting for admin review. The dedicated supplier-side eligibility controls are still pending, so current state is admin-managed.'**
  String get supplierDashboardSuperLoadGuidanceRequestSubmitted;

  /// Supplier Dashboard Super Load Guidance Under Review - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This Super Load request is under admin review. Keep load details stable while review is in progress.'**
  String get supplierDashboardSuperLoadGuidanceUnderReview;

  /// Supplier Dashboard Super Load Guidance Approved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This Super Load request is approved, but activation still depends on the off-platform payment confirmation step.'**
  String get supplierDashboardSuperLoadGuidanceApproved;

  /// Supplier Dashboard Super Load Guidance Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This Super Load request was not approved. Use support if you need follow-up while the dedicated supplier readiness surface is still pending.'**
  String get supplierDashboardSuperLoadGuidanceRejected;

  /// Supplier Dashboard Super Load Guidance Expired Or Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This Super Load lifecycle is closed. Review the current load status and use support if follow-up is still needed.'**
  String get supplierDashboardSuperLoadGuidanceExpiredOrClosed;

  /// Supplier Dashboard Super Load Guidance Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This load is marked as a Super Load in the current lifecycle. Dedicated supplier-side eligibility controls are still being expanded.'**
  String get supplierDashboardSuperLoadGuidanceActive;

  /// Supplier Dashboard Super Load Guidance Not Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Load state is not active for this load.'**
  String get supplierDashboardSuperLoadGuidanceNotActive;

  /// No description provided for @supplierLinkedTripAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {date}'**
  String supplierLinkedTripAssignedLabel(Object date);

  /// No description provided for @supplierLinkedTripProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Proof status: {status}'**
  String supplierLinkedTripProofLabel(Object status);

  /// Supplier Linked Trip Track Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track trip'**
  String get supplierLinkedTripTrackAction;

  /// Supplier Trip Detail Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip Detail'**
  String get supplierTripDetailTitle;

  /// Supplier Trip Detail Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load supplier trip detail'**
  String get supplierTripDetailLoadFailureTitle;

  /// Supplier Trip Detail Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load this supplier trip detail right now. Retry shortly to refresh the latest trip status and proof review context.'**
  String get supplierTripDetailLoadFailureMessage;

  /// Supplier Trip Detail Rating Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The supplier rating state is temporarily unavailable. Retry shortly before submitting a rating.'**
  String get supplierTripDetailRatingFailureMessage;

  /// Supplier Trip Detail Rating Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this supplier rating right now. Review the rating and retry shortly.'**
  String get supplierTripDetailRatingSubmitFailureMessage;

  /// Supplier Trip Detail Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The latest supplier trip action could not be completed right now. Retry shortly after the trip detail refreshes.'**
  String get supplierTripDetailActionFailureMessage;

  /// Supplier Trip Detail Action Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that supplier trip action right now. Retry shortly after checking the latest trip status.'**
  String get supplierTripDetailActionSubmitFailureMessage;

  /// Supplier Trip Detail Rating Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get supplierTripDetailRatingSectionTitle;

  /// Supplier Trip Detail Rating Already Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You already rated this trip.'**
  String get supplierTripDetailRatingAlreadySubmitted;

  /// No description provided for @supplierTripDetailRatingSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String supplierTripDetailRatingSubmittedOn(Object date);

  /// Supplier Trip Detail Rating Prompt - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery is complete. Rate the trucker for this trip.'**
  String get supplierTripDetailRatingPrompt;

  /// Supplier Trip Detail Comment Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get supplierTripDetailCommentLabel;

  /// Supplier Trip Detail Comment Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Share anything useful about the trip outcome'**
  String get supplierTripDetailCommentHint;

  /// Supplier Trip Detail Rating Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rating unavailable'**
  String get supplierTripDetailRatingUnavailableTitle;

  /// Supplier Trip Detail Submit Rating Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get supplierTripDetailSubmitRatingAction;

  /// Supplier Trip Detail Rating Submitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted successfully.'**
  String get supplierTripDetailRatingSubmittedSuccess;

  /// No description provided for @supplierTripDetailRatingStarTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} star{s}'**
  String supplierTripDetailRatingStarTooltip(int count, Object s);

  /// No description provided for @supplierTripDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trip {tripId} - Truck {truckNumber}'**
  String supplierTripDetailHeroSubtitle(Object tripId, Object truckNumber);

  /// No description provided for @supplierTripDetailMaterialTruckerSummary.
  ///
  /// In en, this message translates to:
  /// **'{material} - Trucker {truckerName}'**
  String supplierTripDetailMaterialTruckerSummary(
    Object material,
    Object truckerName,
  );

  /// Supplier Trip Detail Next Step Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get supplierTripDetailNextStepTitle;

  /// Supplier Trip Detail Next Step Review Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm delivery'**
  String get supplierTripDetailNextStepReviewTitle;

  /// Supplier Trip Detail Next Step Review Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The trucker has uploaded POD. Review the proof and confirm delivery to close the trip.'**
  String get supplierTripDetailNextStepReviewMessage;

  /// Supplier Trip Detail Next Step Completed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get supplierTripDetailNextStepCompletedTitle;

  /// Supplier Trip Detail Next Step Completed Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery has been confirmed. Rating and post-trip follow-up continue from this completed state.'**
  String get supplierTripDetailNextStepCompletedMessage;

  /// Supplier Trip Detail Next Step Disputed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute in progress'**
  String get supplierTripDetailNextStepDisputedTitle;

  /// Supplier Trip Detail Next Step Disputed Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This trip is under dispute review and awaits support or operations resolution.'**
  String get supplierTripDetailNextStepDisputedMessage;

  /// Supplier Trip Detail Next Step Default Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track execution'**
  String get supplierTripDetailNextStepDefaultTitle;

  /// Supplier Trip Detail Next Step Default Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the current trip status, timestamps, and proof progress from this supplier execution view.'**
  String get supplierTripDetailNextStepDefaultMessage;

  /// Supplier Trip Detail Dispute Status Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute status'**
  String get supplierTripDetailDisputeStatusTitle;

  /// Supplier Trip Detail Dispute State Raised - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current state: Dispute raised'**
  String get supplierTripDetailDisputeStateRaised;

  /// No description provided for @supplierTripDetailDisputeCategorySummary.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String supplierTripDetailDisputeCategorySummary(Object category);

  /// No description provided for @supplierTripDetailDisputeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'{category}'**
  String supplierTripDetailDisputeCategoryLabel(Object category);

  /// No description provided for @supplierTripDetailDisputeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'{status}'**
  String supplierTripDetailDisputeStatusLabel(Object status);

  /// No description provided for @supplierTripDetailDisputeCurrentStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Current state: {status}'**
  String supplierTripDetailDisputeCurrentStateLabel(Object status);

  /// No description provided for @supplierTripDetailDisputeLastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String supplierTripDetailDisputeLastUpdatedLabel(Object date);

  /// Supplier Trip Detail Action Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier trip action unavailable'**
  String get supplierTripDetailActionUnavailableTitle;

  /// Supplier Trip Detail Proof Documents Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof documents'**
  String get supplierTripDetailProofDocumentsTitle;

  /// Supplier Trip Detail Pod Photo Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'POD photo'**
  String get supplierTripDetailPodPhotoTitle;

  /// Supplier Trip Detail Preview Unavailable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to open preview'**
  String get supplierTripDetailPreviewUnavailable;

  /// Supplier Trip Detail Open Pod Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open POD Photo'**
  String get supplierTripDetailOpenPodPhotoAction;

  /// Supplier Trip Detail Open Lr Document Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open LR Document'**
  String get supplierTripDetailOpenLrDocumentAction;

  /// Supplier Trip Detail Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get supplierTripDetailActionsTitle;

  /// Supplier Trip Detail Confirm Delivery Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get supplierTripDetailConfirmDeliveryAction;

  /// Supplier Trip Detail Confirm Delivery Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery confirmed. The trip is now completed.'**
  String get supplierTripDetailConfirmDeliverySuccess;

  /// Supplier Trip Detail Dispute Pod Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute POD'**
  String get supplierTripDetailDisputePodAction;

  /// No description provided for @supplierTripDetailReportSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier trip - {routeLabel}'**
  String supplierTripDetailReportSourceLabel(Object routeLabel);

  /// Supplier Trip Detail Route Schedule Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route and schedule'**
  String get supplierTripDetailRouteScheduleTitle;

  /// No description provided for @supplierTripDetailOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin: {origin}'**
  String supplierTripDetailOriginLabel(Object origin);

  /// No description provided for @supplierTripDetailDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination: {destination}'**
  String supplierTripDetailDestinationLabel(Object destination);

  /// No description provided for @supplierTripDetailDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String supplierTripDetailDistanceLabel(Object distance);

  /// No description provided for @supplierTripDetailDriveTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Drive time: {minutes} min'**
  String supplierTripDetailDriveTimeLabel(int minutes);

  /// No description provided for @supplierTripDetailPickupDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup date: {date}'**
  String supplierTripDetailPickupDateLabel(Object date);

  /// No description provided for @supplierTripDetailAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {dateTime}'**
  String supplierTripDetailAssignedLabel(Object dateTime);

  /// No description provided for @supplierTripDetailDeliveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivered: {dateTime}'**
  String supplierTripDetailDeliveredLabel(Object dateTime);

  /// No description provided for @supplierTripDetailPodUploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded: {dateTime}'**
  String supplierTripDetailPodUploadedLabel(Object dateTime);

  /// No description provided for @supplierTripDetailCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed: {dateTime}'**
  String supplierTripDetailCompletedLabel(Object dateTime);

  /// Supplier Trip Detail Trucker Truck Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker and truck'**
  String get supplierTripDetailTruckerTruckTitle;

  /// No description provided for @supplierTripDetailTruckerLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucker: {name}'**
  String supplierTripDetailTruckerLabel(Object name);

  /// No description provided for @supplierTripDetailTruckNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck number: {truckNumber}'**
  String supplierTripDetailTruckNumberLabel(Object truckNumber);

  /// No description provided for @supplierTripDetailBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type: {bodyType}'**
  String supplierTripDetailBodyTypeLabel(Object bodyType);

  /// No description provided for @supplierTripDetailTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {tyres}'**
  String supplierTripDetailTyresLabel(Object tyres);

  /// Supplier Trip Detail Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get supplierTripDetailPending;

  /// Supplier Trip Detail Stage Assigned - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get supplierTripDetailStageAssigned;

  /// Supplier Trip Detail Stage Pickup Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup pending'**
  String get supplierTripDetailStagePickupPending;

  /// Supplier Trip Detail Stage Picked Up - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get supplierTripDetailStagePickedUp;

  /// Supplier Trip Detail Stage In Transit - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get supplierTripDetailStageInTransit;

  /// Supplier Trip Detail Stage Delivered - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get supplierTripDetailStageDelivered;

  /// Supplier Trip Detail Stage Proof Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted'**
  String get supplierTripDetailStageProofSubmitted;

  /// Supplier Trip Detail Stage Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get supplierTripDetailStageCompleted;

  /// Supplier Trip Detail Stage Disputed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get supplierTripDetailStageDisputed;

  /// Supplier Trip Detail Stage Cancelled - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get supplierTripDetailStageCancelled;

  /// Supplier Trip Detail Stage Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supplierTripDetailStageUnknown;

  /// Supplier Trip Detail Verification Status Verified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get supplierTripDetailVerificationStatusVerified;

  /// Supplier Trip Detail Verification Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get supplierTripDetailVerificationStatusPending;

  /// Supplier Trip Detail Verification Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get supplierTripDetailVerificationStatusRejected;

  /// Supplier Trip Detail Verification Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get supplierTripDetailVerificationStatusUnknown;

  /// Supplier Trip Detail Dispute Category Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip dispute'**
  String get supplierTripDetailDisputeCategoryFallback;

  /// Supplier Trip Detail Dispute Status Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supplierTripDetailDisputeStatusFallback;

  /// Supplier Trip Detail Dispute Status Guidance Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support has received this dispute and review should begin shortly. Keep the related support replies clear if more proof context is needed.'**
  String get supplierTripDetailDisputeStatusGuidanceOpen;

  /// Supplier Trip Detail Dispute Status Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.'**
  String get supplierTripDetailDisputeStatusGuidanceInProgress;

  /// Supplier Trip Detail Dispute Status Guidance Waiting For User - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting for your clarification or additional context. Reply on the related support ticket so the review can continue.'**
  String get supplierTripDetailDisputeStatusGuidanceWaitingForUser;

  /// Supplier Trip Detail Dispute Status Guidance Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Check the linked support ticket outcome before raising any fresh follow-up issue.'**
  String get supplierTripDetailDisputeStatusGuidanceResolved;

  /// Supplier Trip Detail Dispute Status Guidance Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep following the related support ticket for the latest visible review updates.'**
  String get supplierTripDetailDisputeStatusGuidanceDefault;

  /// Supplier Trip Detail Dispute Banner Waiting Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute review waiting for your reply'**
  String get supplierTripDetailDisputeBannerWaitingTitle;

  /// Supplier Trip Detail Dispute Banner Closed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute review closed'**
  String get supplierTripDetailDisputeBannerClosedTitle;

  /// Supplier Trip Detail Dispute Banner In Progress Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute review in progress'**
  String get supplierTripDetailDisputeBannerInProgressTitle;

  /// Supplier Trip Detail Dispute Banner No Summary Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip. Support and operations are reviewing the delivery context, while raw evidence access may remain restricted during review.'**
  String get supplierTripDetailDisputeBannerNoSummaryMessage;

  /// No description provided for @supplierTripDetailDisputeBannerWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}. This trip dispute is waiting on your clarification or proof, while raw evidence access may remain restricted during review.'**
  String supplierTripDetailDisputeBannerWaitingMessage(Object category);

  /// No description provided for @supplierTripDetailDisputeBannerClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}. This trip dispute has reached a final review outcome. Recorded status updates remain visible, while raw evidence access may remain restricted.'**
  String supplierTripDetailDisputeBannerClosedMessage(Object category);

  /// No description provided for @supplierTripDetailDisputeBannerInProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}. Status: {status}. Support and operations are reviewing this trip dispute, while raw evidence access may remain restricted during review.'**
  String supplierTripDetailDisputeBannerInProgressMessage(
    Object category,
    Object status,
  );

  /// Supplier Trip Detail Shared Visibility Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.'**
  String get supplierTripDetailSharedVisibilityClosed;

  /// Supplier Trip Detail Shared Visibility In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'**
  String get supplierTripDetailSharedVisibilityInProgress;

  /// Supplier Trip Detail Action Guidance Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Check the recorded outcome on the linked support ticket before opening any genuinely new follow-up issue.'**
  String get supplierTripDetailActionGuidanceClosed;

  /// Supplier Trip Detail Action Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No further delivery-confirmation action is available while this dispute stays under review. Follow the linked support ticket if support requests clarification or additional context.'**
  String get supplierTripDetailActionGuidanceInProgress;

  /// Supplier Trip Detail Proof Guidance Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.'**
  String get supplierTripDetailProofGuidanceClosed;

  /// Supplier Trip Detail Proof Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If this dispute depends on additional documents beyond the current single-image flow, summarize those missing proofs clearly in the related support ticket replies.'**
  String get supplierTripDetailProofGuidanceInProgress;

  /// Verification Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// Verification Title Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier Verification'**
  String get verificationTitleSupplier;

  /// Verification Title Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker Verification'**
  String get verificationTitleTrucker;

  /// Verification Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load verification state'**
  String get verificationLoadFailureTitle;

  /// Verification Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your verification status right now. Retry shortly to refresh the latest verification state.'**
  String get verificationLoadFailureMessage;

  /// Verification Details Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification details unavailable'**
  String get verificationDetailsUnavailableTitle;

  /// Verification Details Unavailable Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not find the current verification record for this account. Please retry shortly.'**
  String get verificationDetailsUnavailableSubtitle;

  /// Verification Hero Pending Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier verification under review'**
  String get verificationHeroPendingSupplierTitle;

  /// Verification Hero Pending Trucker Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker verification under review'**
  String get verificationHeroPendingTruckerTitle;

  /// Verification Hero Verified Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier verification complete'**
  String get verificationHeroVerifiedSupplierTitle;

  /// Verification Hero Verified Trucker Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker verification complete'**
  String get verificationHeroVerifiedTruckerTitle;

  /// Verification Hero Rejected Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resubmit supplier verification'**
  String get verificationHeroRejectedSupplierTitle;

  /// Verification Hero Rejected Trucker Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resubmit trucker verification'**
  String get verificationHeroRejectedTruckerTitle;

  /// Verification Hero Initial Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier trust setup'**
  String get verificationHeroInitialSupplierTitle;

  /// Verification Hero Initial Trucker Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker trust setup'**
  String get verificationHeroInitialTruckerTitle;

  /// Verification Hero Pending Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification packet is already under review. We will notify you when approval is complete.'**
  String get verificationHeroPendingSubtitle;

  /// Verification Hero Verified Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification packet is already approved. You can review the captured documents and readiness details below.'**
  String get verificationHeroVerifiedSubtitle;

  /// Verification Hero Rejected With Feedback Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the rejected document markers below, replace any affected items, and resubmit when you are ready.'**
  String get verificationHeroRejectedWithFeedbackSubtitle;

  /// Verification Hero Rejected Fallback Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the rejection summary, replace any affected items, and resubmit the full packet when you are ready.'**
  String get verificationHeroRejectedFallbackSubtitle;

  /// Verification Hero Initial Supplier Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload the required business and identity documents, capture supplier verification location, and submit them for review from this single verification surface.'**
  String get verificationHeroInitialSupplierSubtitle;

  /// Verification Hero Initial Trucker Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload identity documents, confirm truck readiness, and submit the full verification packet for review from this single setup surface.'**
  String get verificationHeroInitialTruckerSubtitle;

  /// Verification Resubmit For Review Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for review'**
  String get verificationResubmitForReviewAction;

  /// Verification Submit For Review Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get verificationSubmitForReviewAction;

  /// Verification Resubmitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification resubmitted for review'**
  String get verificationResubmittedSuccess;

  /// Verification Submitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification submitted for review'**
  String get verificationSubmittedSuccess;

  /// Verification Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this verification packet right now. Review the current checklist and retry shortly.'**
  String get verificationSubmitFailureMessage;

  /// Verification What Happens Next Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get verificationWhatHappensNextTitle;

  /// Verification What Happens Next Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification packet is queued for review. You do not need to resubmit anything unless our team rejects the case with a correction request.'**
  String get verificationWhatHappensNextMessage;

  /// Verification Timeline Packet Submitted Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Packet submitted'**
  String get verificationTimelinePacketSubmittedTitle;

  /// Verification Timeline Packet Submitted Timestamp - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get verificationTimelinePacketSubmittedTimestamp;

  /// Verification Timeline Packet Submitted Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your current documents and readiness data are already attached to the verification case.'**
  String get verificationTimelinePacketSubmittedDescription;

  /// Verification Timeline Review In Progress Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review in progress'**
  String get verificationTimelineReviewInProgressTitle;

  /// Verification Timeline Review In Progress Timestamp - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get verificationTimelineReviewInProgressTimestamp;

  /// Verification Timeline Review In Progress Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Our operations team is reviewing the submitted identity, business, and readiness evidence.'**
  String get verificationTimelineReviewInProgressDescription;

  /// Verification Timeline Notified Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You will be notified'**
  String get verificationTimelineNotifiedTitle;

  /// Verification Timeline Notified Timestamp - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get verificationTimelineNotifiedTimestamp;

  /// Verification Timeline Notified Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We will update your verification state here once the review is approved or sent back for corrections.'**
  String get verificationTimelineNotifiedDescription;

  /// Verification Wizard Step Photo - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get verificationWizardStepPhoto;

  /// Verification Wizard Step Identity - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get verificationWizardStepIdentity;

  /// Verification Wizard Step Truck - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get verificationWizardStepTruck;

  /// Verification Wizard Step Business - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get verificationWizardStepBusiness;

  /// Verification Wizard Step Review - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get verificationWizardStepReview;

  /// Verification Wizard Back Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get verificationWizardBackAction;

  /// Verification Wizard Save And Exit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get verificationWizardSaveAndExitAction;

  /// Verification Wizard Exit Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Exit verification?'**
  String get verificationWizardExitTitle;

  /// Verification Wizard Exit Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You can leave this flow now and continue later.'**
  String get verificationWizardExitMessage;

  /// Verification Wizard Exit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get verificationWizardExitAction;

  /// Verification Wizard Dashboard Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get verificationWizardDashboardAction;

  /// Verification Wizard Profile Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get verificationWizardProfileTitle;

  /// Verification Wizard Profile Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear profile photo for verification.'**
  String get verificationWizardProfileSubtitle;

  /// Verification Wizard Profile Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use a clear, front-facing photo with good lighting.'**
  String get verificationWizardProfileHint;

  /// Verification Wizard Identity Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Identity documents'**
  String get verificationWizardIdentityTitle;

  /// Verification Wizard Identity Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add Aadhaar and PAN details with document uploads.'**
  String get verificationWizardIdentitySubtitle;

  /// Verification Wizard Aadhaar Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get verificationWizardAadhaarNumberLabel;

  /// Verification Wizard Pan Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN number'**
  String get verificationWizardPanNumberLabel;

  /// Verification Wizard Pan Document Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN document'**
  String get verificationWizardPanDocumentLabel;

  /// Verification Wizard Truck Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck details'**
  String get verificationWizardTruckTitle;

  /// Verification Wizard Truck Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add one truck and upload its RC document.'**
  String get verificationWizardTruckSubtitle;

  /// Verification Wizard Truck Info - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'At least one truck with an RC document is required for trucker verification.'**
  String get verificationWizardTruckInfo;

  /// Verification Wizard Truck Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck number'**
  String get verificationWizardTruckNumberLabel;

  /// Verification Wizard Body Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get verificationWizardBodyTypeLabel;

  /// Verification Wizard Tyres Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tyres'**
  String get verificationWizardTyresLabel;

  /// Verification Wizard Capacity Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get verificationWizardCapacityLabel;

  /// Verification Wizard Capacity Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'16'**
  String get verificationWizardCapacityHint;

  /// Verification Wizard Rc Document Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC document'**
  String get verificationWizardRcDocumentLabel;

  /// Verification Wizard Required For Verification - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Required for verification'**
  String get verificationWizardRequiredForVerification;

  /// Verification Wizard Truck Photo Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck photo'**
  String get verificationWizardTruckPhotoLabel;

  /// Verification Wizard Truck Photo Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Optional photo of your truck'**
  String get verificationWizardTruckPhotoHint;

  /// Verification Wizard Business Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get verificationWizardBusinessTitle;

  /// Verification Wizard Business Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add your company, licence, optional GST, and verification location.'**
  String get verificationWizardBusinessSubtitle;

  /// Verification Wizard Company Name Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get verificationWizardCompanyNameLabel;

  /// Verification Wizard Company Name Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your company name'**
  String get verificationWizardCompanyNameHint;

  /// Verification Wizard License Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get verificationWizardLicenseNumberLabel;

  /// Verification Wizard License Number Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your business licence number'**
  String get verificationWizardLicenseNumberHint;

  /// Verification Wizard License Document Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence document'**
  String get verificationWizardLicenseDocumentLabel;

  /// Verification Wizard Gst Details Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST details'**
  String get verificationWizardGstDetailsTitle;

  /// Verification Wizard Gst Details Added - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST details added'**
  String get verificationWizardGstDetailsAdded;

  /// Verification Wizard Gst Optional - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST is optional'**
  String get verificationWizardGstOptional;

  /// Verification Wizard Gst Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST number'**
  String get verificationWizardGstNumberLabel;

  /// Verification Wizard Gst Certificate Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST certificate'**
  String get verificationWizardGstCertificateLabel;

  /// Verification Wizard Search City Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get verificationWizardSearchCityTitle;

  /// Verification Wizard Search City Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Type city name'**
  String get verificationWizardSearchCityHint;

  /// Verification Wizard Use Current Location - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get verificationWizardUseCurrentLocation;

  /// No description provided for @verificationWizardNoCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found for \"{query}\"'**
  String verificationWizardNoCitiesFound(Object query);

  /// Verification Wizard Try Different Search - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get verificationWizardTryDifferentSearch;

  /// Verification Wizard Location Services Off Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get verificationWizardLocationServicesOffTitle;

  /// Verification Wizard Location Services Off Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS/location services and try again.'**
  String get verificationWizardLocationServicesOffMessage;

  /// Verification Wizard Location Permission Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get verificationWizardLocationPermissionTitle;

  /// Verification Wizard Location Permission Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Please allow location permission in app settings to continue.'**
  String get verificationWizardLocationPermissionMessage;

  /// Verification Wizard Open Settings Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get verificationWizardOpenSettingsAction;

  /// Verification Wizard Captured Via Gps - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Captured via GPS'**
  String get verificationWizardCapturedViaGps;

  /// Verification Wizard Added Manually - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get verificationWizardAddedManually;

  /// Verification Wizard Review Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get verificationWizardReviewTitle;

  /// Verification Wizard Review Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Confirm your details before sending the verification packet.'**
  String get verificationWizardReviewSubtitle;

  /// Verification Wizard Review Profile - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get verificationWizardReviewProfile;

  /// Verification Wizard Review Profile Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile photo uploaded'**
  String get verificationWizardReviewProfileUploaded;

  /// Verification Wizard Review Profile Missing - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile photo missing'**
  String get verificationWizardReviewProfileMissing;

  /// Verification Wizard Review Identity - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get verificationWizardReviewIdentity;

  /// Verification Wizard Review Documents Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Documents uploaded'**
  String get verificationWizardReviewDocumentsUploaded;

  /// Verification Wizard Review Truck - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get verificationWizardReviewTruck;

  /// Verification Wizard Review Truck Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck number'**
  String get verificationWizardReviewTruckNumber;

  /// Verification Wizard Review Rc Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC document uploaded'**
  String get verificationWizardReviewRcUploaded;

  /// Verification Wizard Review Truck Photo Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck photo uploaded'**
  String get verificationWizardReviewTruckPhotoUploaded;

  /// Verification Wizard Review Business - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get verificationWizardReviewBusiness;

  /// Verification Wizard Review Company Name - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get verificationWizardReviewCompanyName;

  /// Verification Wizard Review License Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get verificationWizardReviewLicenseNumber;

  /// Verification Wizard Review Gst Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST number'**
  String get verificationWizardReviewGstNumber;

  /// Verification Wizard Review Location - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get verificationWizardReviewLocation;

  /// Verification Wizard Review Timeline Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review usually completes after the submitted packet is checked by the team.'**
  String get verificationWizardReviewTimelineMessage;

  /// Verification Wizard Terms Text - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the information and uploaded documents are accurate and ready for verification review.'**
  String get verificationWizardTermsText;

  /// Verification Wizard Validation Error - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Please complete the required fields before submitting.'**
  String get verificationWizardValidationError;

  /// Verification Wizard Unauthorized Error - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your session is unavailable. Please sign in again.'**
  String get verificationWizardUnauthorizedError;

  /// Verification Wizard Unknown Error - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while submitting verification.'**
  String get verificationWizardUnknownError;

  /// Verification Wizard Profile Photo Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile photo is required'**
  String get verificationWizardProfilePhotoRequired;

  /// Verification Wizard Aadhaar Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar must be 12 digits'**
  String get verificationWizardAadhaarRequired;

  /// Verification Wizard Pan Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Invalid PAN format'**
  String get verificationWizardPanRequired;

  /// Verification Wizard Aadhaar Front Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar front photo required'**
  String get verificationWizardAadhaarFrontRequired;

  /// Verification Wizard Aadhaar Back Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar back photo required'**
  String get verificationWizardAadhaarBackRequired;

  /// Verification Wizard Pan Photo Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN photo required'**
  String get verificationWizardPanPhotoRequired;

  /// Verification Wizard Truck Number Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck number is required'**
  String get verificationWizardTruckNumberRequired;

  /// Verification Wizard Rc Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'RC document is required'**
  String get verificationWizardRcRequired;

  /// Verification Wizard Company Name Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get verificationWizardCompanyNameRequired;

  /// Verification Wizard License Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'License number is required'**
  String get verificationWizardLicenseRequired;

  /// Verification Wizard License Document Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'License document is required'**
  String get verificationWizardLicenseDocumentRequired;

  /// Verification Wizard Location Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification location is required'**
  String get verificationWizardLocationRequired;

  /// Verification Action Needs Attention Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification action needs attention'**
  String get verificationActionNeedsAttentionTitle;

  /// Verification Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The latest verification action could not be completed right now. Review the current checklist and retry shortly.'**
  String get verificationActionFailureMessage;

  /// Verification Latest Rejection Reason Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Latest rejection reason'**
  String get verificationLatestRejectionReasonTitle;

  /// Verification Next Step Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get verificationNextStepTitle;

  /// Verification Location Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification location'**
  String get verificationLocationTitle;

  /// Verification Location Captured Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Location captured'**
  String get verificationLocationCapturedTitle;

  /// Verification Location Required Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Location still required'**
  String get verificationLocationRequiredTitle;

  /// Verification Location Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier verification needs a city-level location capture before submission can proceed.'**
  String get verificationLocationRequiredMessage;

  /// Verification Location Captured Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'captured'**
  String get verificationLocationCapturedStatus;

  /// Verification Location Required Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get verificationLocationRequiredStatus;

  /// Verification Location Captured Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Captured location remains attached to the supplier verification packet for review.'**
  String get verificationLocationCapturedFooter;

  /// Verification Location Capture Guidance Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We attempt GPS capture and resolve to the nearest city-level location when possible.'**
  String get verificationLocationCaptureGuidanceFooter;

  /// Verification Refresh Location Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get verificationRefreshLocationAction;

  /// Verification Capture Location Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Capture location'**
  String get verificationCaptureLocationAction;

  /// Verification Location Captured Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification location captured'**
  String get verificationLocationCapturedSuccess;

  /// Verification Location Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not capture the verification location right now. Retry shortly from this verification screen.'**
  String get verificationLocationFailureMessage;

  /// Verification Manual Location Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter location manually'**
  String get verificationManualLocationAction;

  /// Verification Manual Location Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add verification location manually'**
  String get verificationManualLocationTitle;

  /// Verification Manual Location City Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get verificationManualLocationCityLabel;

  /// Verification Manual Location State Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'State (optional)'**
  String get verificationManualLocationStateLabel;

  /// Verification Manual Location Save Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Save location'**
  String get verificationManualLocationSaveAction;

  /// Verification Doc Type Aadhaar Front - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar front'**
  String get verificationDocTypeAadhaarFront;

  /// Verification Doc Type Aadhaar Back - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar back'**
  String get verificationDocTypeAadhaarBack;

  /// Verification Doc Type Pan - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN card'**
  String get verificationDocTypePan;

  /// Verification Doc Type Profile Photo - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get verificationDocTypeProfilePhoto;

  /// Verification Doc Type Business Licence - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence'**
  String get verificationDocTypeBusinessLicence;

  /// Verification Doc Type Gst Certificate - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST certificate'**
  String get verificationDocTypeGstCertificate;

  /// Verification Document Checklist Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Document checklist'**
  String get verificationDocumentChecklistTitle;

  /// No description provided for @verificationDocumentUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{label} uploaded successfully'**
  String verificationDocumentUploadedSuccess(Object label);

  /// Verification Document Upload Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not upload that verification document right now. Try another image or retry shortly.'**
  String get verificationDocumentUploadFailureMessage;

  /// Verification Readiness Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification readiness'**
  String get verificationReadinessSupplierTitle;

  /// Verification Readiness Trucker Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification and truck readiness'**
  String get verificationReadinessTruckerTitle;

  /// Verification Current State Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current verification state'**
  String get verificationCurrentStateTitle;

  /// Verification Status Verified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationStatusVerified;

  /// Verification Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get verificationStatusPending;

  /// Verification Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verificationStatusRejected;

  /// Verification Status Unverified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get verificationStatusUnverified;

  /// Verification Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get verificationStatusUnknown;

  /// Verification Current State Supplier Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier verification keeps load-posting readiness and trust visibility aligned to one authoritative state.'**
  String get verificationCurrentStateSupplierFooter;

  /// Verification Current State Trucker Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker verification unlocks chat and call on open loads once identity documents and truck readiness are complete.'**
  String get verificationCurrentStateTruckerFooter;

  /// Verification Business Readiness Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business readiness'**
  String get verificationBusinessReadinessTitle;

  /// Verification Truck Readiness Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck readiness'**
  String get verificationTruckReadinessTitle;

  /// Verification Company Name Needs Attention - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company name still needs attention'**
  String get verificationCompanyNameNeedsAttention;

  /// Approved Truck Count Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{count} approved truck{s}'**
  String approvedTruckCountLabel(Object count, Object s);

  /// Verification Check Profile Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'check profile'**
  String get verificationCheckProfileStatus;

  /// Verification Captured Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'captured'**
  String get verificationCapturedStatus;

  /// Verification Ready Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get verificationReadyStatus;

  /// Verification Action Needed Status - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'action needed'**
  String get verificationActionNeededStatus;

  /// Verification Business Readiness Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence is required for supplier verification. GST certificate remains optional.'**
  String get verificationBusinessReadinessFooter;

  /// Verification Truck Ready Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You already have at least one approved truck available for verification-dependent workflows.'**
  String get verificationTruckReadyFooter;

  /// Verification Truck Required Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'At least one approved truck is still required before trucker verification can be submitted.'**
  String get verificationTruckRequiredFooter;

  /// Verification Packet Details Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification packet details'**
  String get verificationPacketDetailsSectionTitle;

  /// Verification Identity Packet Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Identity packet details'**
  String get verificationIdentityPacketSectionTitle;

  /// No description provided for @verificationReadyTruckCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} ready {count, plural, =1{truck} other{trucks}}'**
  String verificationReadyTruckCountLabel(int count);

  /// Verification Truck Ready With Rc Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You already have at least one complete truck packet with RC document attached.'**
  String get verificationTruckReadyWithRcFooter;

  /// Verification Truck Required With Rc Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add one truck with its RC document before submitting trucker verification.'**
  String get verificationTruckRequiredWithRcFooter;

  /// Verification Truck Packet Still Required Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A truck packet is still required'**
  String get verificationTruckPacketStillRequiredTitle;

  /// Verification Truck Packet Still Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open your fleet to add the first truck or upload the RC document so trucker verification can be submitted as one packet.'**
  String get verificationTruckPacketStillRequiredMessage;

  /// Verification Truck Packet Required Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck packet required'**
  String get verificationTruckPacketRequiredBadge;

  /// Verification Truck Approval Required Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck approval is still required'**
  String get verificationTruckApprovalRequiredTitle;

  /// Verification Truck Approval Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open your fleet to add the first truck, review rejection guidance, or resubmit edited truck details for approval.'**
  String get verificationTruckApprovalRequiredMessage;

  /// Verification Open Fleet Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open fleet'**
  String get verificationOpenFleetAction;

  /// Verification Unlocks Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What this unlocks'**
  String get verificationUnlocksTitle;

  /// Verification Unlocks Supplier Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Once verified, your supplier account becomes trust-ready for broader marketplace and account workflows.'**
  String get verificationUnlocksSupplierMessage;

  /// Verification Unlocks Trucker Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Once verified, chat and call stay unlocked on open loads and your trucker account becomes assignment-ready.'**
  String get verificationUnlocksTruckerMessage;

  /// Verification Source Of Truth Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification source of truth'**
  String get verificationSourceOfTruthBadge;

  /// Verification Chat And Call Gating Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Chat and call gating'**
  String get verificationChatAndCallGatingBadge;

  /// Verification Approved Truck Required Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approved truck required'**
  String get verificationApprovedTruckRequiredBadge;

  /// Verification Back To Account Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to account'**
  String get verificationBackToAccountAction;

  /// Verification Upload Source Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload {documentLabel}'**
  String verificationUploadSourceTitle(Object documentLabel);

  /// Verification Take Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get verificationTakePhotoAction;

  /// Verification Choose From Gallery Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get verificationChooseFromGalleryAction;

  /// Verification Rejection Summary With Markers - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{summary}\n\nRejected documents are marked below with document-specific correction notes.'**
  String verificationRejectionSummaryWithMarkers(Object summary);

  /// Verification Rejection Summary Packet Level - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{summary}\n\nCurrent review feedback is returned as one packet-level reason when document-specific review markers are not provided.'**
  String verificationRejectionSummaryPacketLevel(Object summary);

  /// Verification Pending Banner Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get verificationPendingBannerTitle;

  /// Verification Pending Banner Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification packet is already under review. You can keep browsing while review is pending.'**
  String get verificationPendingBannerDescription;

  /// Verification Complete Banner Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get verificationCompleteBannerTitle;

  /// Verification Complete Banner Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account is already verified. You can still review the uploaded document checklist below.'**
  String get verificationCompleteBannerDescription;

  /// Verification Needs Attention Banner Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification needs attention'**
  String get verificationNeedsAttentionBannerTitle;

  /// Verification Needs Attention Banner Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the rejection summary, replace any affected documents, and resubmit the packet when ready.'**
  String get verificationNeedsAttentionBannerDescription;

  /// Verification Not Submitted Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification not submitted yet'**
  String get verificationNotSubmittedTitle;

  /// Verification Not Submitted Supplier Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar, PAN, profile photo, and business licence before submitting supplier verification.'**
  String get verificationNotSubmittedSupplierMessage;

  /// Verification Not Submitted Trucker Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar, PAN, profile photo, and ensure at least one approved truck exists before submitting trucker verification.'**
  String get verificationNotSubmittedTruckerMessage;

  /// Verification Locked Status Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verificationLockedStatusSectionTitle;

  /// Verification Locked Status Verified Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationLockedStatusVerifiedTitle;

  /// Verification Locked Status Pending Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get verificationLockedStatusPendingTitle;

  /// Verification Locked Status Verified Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification has been approved. No action is needed right now.'**
  String get verificationLockedStatusVerifiedMessage;

  /// Verification Locked Status Pending Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your documents are being reviewed. You will be notified once the review is complete.'**
  String get verificationLockedStatusPendingMessage;

  /// Verification Submit Locked Footer - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Once submitted, your details stay locked until the admin completes the review.'**
  String get verificationSubmitLockedFooter;

  /// Verification Required Uploaded Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{uploaded}/{required} required uploaded'**
  String verificationRequiredUploadedLabel(Object required, Object uploaded);

  /// Verification Prerequisites Satisfied Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'All current client-side verification prerequisites are satisfied for submission.'**
  String get verificationPrerequisitesSatisfiedMessage;

  /// Verification Document Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get verificationDocumentStatusPending;

  /// Verification Document Status Verified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'verified'**
  String get verificationDocumentStatusVerified;

  /// Verification Document Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'rejected'**
  String get verificationDocumentStatusRejected;

  /// Verification Document Status Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'uploaded'**
  String get verificationDocumentStatusUploaded;

  /// Verification Document Status Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get verificationDocumentStatusRequired;

  /// Verification Document Status Optional - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get verificationDocumentStatusOptional;

  /// Verification Document Correction Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This document needs correction before verification can be resubmitted.'**
  String get verificationDocumentCorrectionFallback;

  /// Verification Document Uploaded Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded and linked to your verification record.'**
  String get verificationDocumentUploadedSubtitle;

  /// Verification Document Required Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Required before verification can be submitted.'**
  String get verificationDocumentRequiredSubtitle;

  /// Verification Document Optional Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Optional for the current verification packet.'**
  String get verificationDocumentOptionalSubtitle;

  /// Verification Review Note Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review note: {reason}'**
  String verificationReviewNoteLabel(Object reason);

  /// Verification Stored Path Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Stored path: {path}'**
  String verificationStoredPathLabel(Object path);

  /// Verification Document Missing Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This document is still missing from the current packet.'**
  String get verificationDocumentMissingMessage;

  /// Verification Replace Document Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Replace document'**
  String get verificationReplaceDocumentAction;

  /// Verification Upload Document Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get verificationUploadDocumentAction;

  /// Trucker Trip Detail Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip Detail'**
  String get truckerTripDetailTitle;

  /// Trucker Trip Detail Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trip detail'**
  String get truckerTripDetailLoadFailureTitle;

  /// Trucker Trip Detail Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load this trip detail right now. Retry shortly to refresh the latest trip status and actions.'**
  String get truckerTripDetailLoadFailureMessage;

  /// Trucker Trip Detail Rating Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your trip rating state is temporarily unavailable. Retry shortly before submitting a rating.'**
  String get truckerTripDetailRatingFailureMessage;

  /// Trucker Trip Detail Rating Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not submit your rating right now. Review the rating and retry shortly.'**
  String get truckerTripDetailRatingSubmitFailureMessage;

  /// Trucker Trip Detail Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The latest trip action could not be completed right now. Retry shortly after the trip detail refreshes.'**
  String get truckerTripDetailActionFailureMessage;

  /// Trucker Trip Detail Action Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that trip action right now. Retry shortly after checking the latest trip status.'**
  String get truckerTripDetailActionSubmitFailureMessage;

  /// Trucker Trip Detail Lr Upload Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the LR proof right now. Try another image or retry shortly.'**
  String get truckerTripDetailLrUploadFailureMessage;

  /// Trucker Trip Detail Pod Upload Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the POD proof right now. Try another image or retry shortly.'**
  String get truckerTripDetailPodUploadFailureMessage;

  /// Trucker Trip Detail Rating Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get truckerTripDetailRatingSectionTitle;

  /// Trucker Trip Detail Rating Already Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You already rated this trip.'**
  String get truckerTripDetailRatingAlreadySubmitted;

  /// Trucker Trip Detail Rating Submitted On - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String truckerTripDetailRatingSubmittedOn(Object date);

  /// Trucker Trip Detail Rating Prompt - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery is complete. Rate the supplier for this trip.'**
  String get truckerTripDetailRatingPrompt;

  /// Trucker Trip Detail Comment Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get truckerTripDetailCommentLabel;

  /// Trucker Trip Detail Comment Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Share anything useful about the trip outcome'**
  String get truckerTripDetailCommentHint;

  /// Trucker Trip Detail Rating Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rating unavailable'**
  String get truckerTripDetailRatingUnavailableTitle;

  /// Trucker Trip Detail Submit Rating Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get truckerTripDetailSubmitRatingAction;

  /// Trucker Trip Detail Rating Submitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted successfully.'**
  String get truckerTripDetailRatingSubmittedSuccess;

  /// Trucker Trip Detail Rating Star Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{count} star{s}'**
  String truckerTripDetailRatingStarTooltip(Object count, Object s);

  /// Trucker Trip Detail Auto Complete Due Now - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Auto-complete is due now.'**
  String get truckerTripDetailAutoCompleteDueNow;

  /// Trucker Trip Detail Auto Complete Duration - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String truckerTripDetailAutoCompleteDuration(Object hours, Object minutes);

  /// Trucker Trip Detail Auto Complete In - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Auto-complete in: {duration}'**
  String truckerTripDetailAutoCompleteIn(Object duration);

  /// Trucker Trip Detail Verification Status Verified - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get truckerTripDetailVerificationStatusVerified;

  /// Trucker Trip Detail Verification Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get truckerTripDetailVerificationStatusPending;

  /// Trucker Trip Detail Verification Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get truckerTripDetailVerificationStatusRejected;

  /// Trucker Trip Detail Verification Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerTripDetailVerificationStatusUnknown;

  /// Trucker Trip Detail Stage Assigned - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get truckerTripDetailStageAssigned;

  /// Trucker Trip Detail Stage Pickup Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup pending'**
  String get truckerTripDetailStagePickupPending;

  /// Trucker Trip Detail Stage Picked Up - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Picked up'**
  String get truckerTripDetailStagePickedUp;

  /// Trucker Trip Detail Stage In Transit - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get truckerTripDetailStageInTransit;

  /// Trucker Trip Detail Stage Delivered - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get truckerTripDetailStageDelivered;

  /// Trucker Trip Detail Stage Proof Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted'**
  String get truckerTripDetailStageProofSubmitted;

  /// Trucker Trip Detail Stage Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get truckerTripDetailStageCompleted;

  /// Trucker Trip Detail Stage Disputed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Disputed'**
  String get truckerTripDetailStageDisputed;

  /// Trucker Trip Detail Stage Cancelled - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get truckerTripDetailStageCancelled;

  /// Trucker Trip Detail Proof Status Pod Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded'**
  String get truckerTripDetailProofStatusPodUploaded;

  /// Trucker Trip Detail Proof Status Lr Uploaded - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'LR uploaded'**
  String get truckerTripDetailProofStatusLrUploaded;

  /// Trucker Trip Detail Proof Status Awaiting Pod - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Awaiting POD'**
  String get truckerTripDetailProofStatusAwaitingPod;

  /// Trucker Trip Detail Proof Status Proof Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof submitted'**
  String get truckerTripDetailProofStatusProofSubmitted;

  /// Trucker Trip Detail Proof Status Proof Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof pending'**
  String get truckerTripDetailProofStatusProofPending;

  /// Trucker Trip Detail Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip {tripId} - Truck {truckNumber}'**
  String truckerTripDetailHeroSubtitle(Object tripId, Object truckNumber);

  /// Trucker Trip Detail Material Pickup Summary - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{material} - Pickup {pickupDate}'**
  String truckerTripDetailMaterialPickupSummary(
    Object material,
    Object pickupDate,
  );

  /// Trucker Trip Detail Next Step Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get truckerTripDetailNextStepTitle;

  /// Trucker Trip Detail Action Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip action unavailable'**
  String get truckerTripDetailActionUnavailableTitle;

  /// Trucker Trip Detail Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get truckerTripDetailActionsTitle;

  /// Trucker Trip Detail Replace Lr Upload Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Replace LR Upload'**
  String get truckerTripDetailReplaceLrUploadAction;

  /// Trucker Trip Detail Upload Lr Optional Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload LR (Optional)'**
  String get truckerTripDetailUploadLrOptionalAction;

  /// Trucker Trip Detail Upload Lr Image Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload LR image'**
  String get truckerTripDetailUploadLrImageTitle;

  /// Trucker Trip Detail Lr Uploaded Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'LR uploaded successfully.'**
  String get truckerTripDetailLrUploadedSuccess;

  /// Trucker Trip Detail Upload Pod Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload POD Photo'**
  String get truckerTripDetailUploadPodPhotoAction;

  /// Trucker Trip Detail Upload Pod Photo Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload POD photo'**
  String get truckerTripDetailUploadPodPhotoTitle;

  /// Trucker Trip Detail Pod Uploaded Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded successfully. Supplier confirmation is now pending.'**
  String get truckerTripDetailPodUploadedSuccess;

  /// Trucker Trip Detail Call Supplier Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Call Supplier'**
  String get truckerTripDetailCallSupplierAction;

  /// Trucker Trip Detail Open In Google Maps Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get truckerTripDetailOpenInGoogleMapsAction;

  /// Trucker Trip Detail Report Source Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker trip - {originLabel} > {destinationLabel}'**
  String truckerTripDetailReportSourceLabel(
    Object destinationLabel,
    Object originLabel,
  );

  /// Trucker Trip Detail Review Countdown Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery review countdown'**
  String get truckerTripDetailReviewCountdownTitle;

  /// Trucker Trip Detail Review Countdown Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier confirmation is pending. This trip auto-completes 48 hours after POD upload if no action is taken.'**
  String get truckerTripDetailReviewCountdownMessage;

  /// Trucker Trip Detail Dispute Status Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute status'**
  String get truckerTripDetailDisputeStatusTitle;

  /// Trucker Trip Detail Dispute State Raised - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current state: Dispute raised'**
  String get truckerTripDetailDisputeStateRaised;

  /// Trucker Trip Detail Dispute Current State Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current state: {status}'**
  String truckerTripDetailDisputeCurrentStateLabel(Object status);

  /// Trucker Trip Detail Dispute Category Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{category}'**
  String truckerTripDetailDisputeCategoryLabel(Object category);

  /// Trucker Trip Detail Dispute Last Updated Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String truckerTripDetailDisputeLastUpdatedLabel(Object date);

  /// Trucker Trip Detail Dispute Status Guidance Open - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support has received this dispute and review should begin shortly. Keep the related support replies clear if more proof context is needed.'**
  String get truckerTripDetailDisputeStatusGuidanceOpen;

  /// Trucker Trip Detail Dispute Status Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.'**
  String get truckerTripDetailDisputeStatusGuidanceInProgress;

  /// Trucker Trip Detail Dispute Status Guidance Waiting For User - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting for your clarification or additional context. Reply on the related support ticket so the review can continue.'**
  String get truckerTripDetailDisputeStatusGuidanceWaitingForUser;

  /// Trucker Trip Detail Dispute Status Guidance Resolved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Check the linked support ticket outcome before raising any fresh follow-up issue.'**
  String get truckerTripDetailDisputeStatusGuidanceResolved;

  /// Trucker Trip Detail Dispute Status Guidance Default - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep following the related support ticket for the latest visible review updates.'**
  String get truckerTripDetailDisputeStatusGuidanceDefault;

  /// Trucker Trip Detail Dispute Banner Waiting Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute waiting for your reply'**
  String get truckerTripDetailDisputeBannerWaitingTitle;

  /// Trucker Trip Detail Dispute Banner Closed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute review closed'**
  String get truckerTripDetailDisputeBannerClosedTitle;

  /// Trucker Trip Detail Dispute Banner In Progress Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute in progress'**
  String get truckerTripDetailDisputeBannerInProgressTitle;

  /// Trucker Trip Detail Dispute Banner No Summary Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip. The trip stays open while support or operations review the submitted proof and delivery context. Both sides can see dispute status, but sensitive evidence may remain restricted during review.'**
  String get truckerTripDetailDisputeBannerNoSummaryMessage;

  /// Trucker Trip Detail Dispute Banner Waiting Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip under {category} and is waiting on your clarification or proof. Sensitive evidence may remain restricted during review.'**
  String truckerTripDetailDisputeBannerWaitingMessage(Object category);

  /// Trucker Trip Detail Dispute Banner Closed Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A dispute raised on this trip under {category} has reached a final review outcome. Recorded status updates remain visible, while sensitive evidence may remain restricted.'**
  String truckerTripDetailDisputeBannerClosedMessage(Object category);

  /// Trucker Trip Detail Dispute Banner In Progress Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip under {category}. The trip stays open while support or operations review the delivery context, and sensitive evidence may remain restricted during review.'**
  String truckerTripDetailDisputeBannerInProgressMessage(Object category);

  /// Trucker Trip Detail Dispute Action Guidance Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Keep this trip detail for the recorded outcome and start a fresh follow-up only if a genuinely new issue appears.'**
  String get truckerTripDetailDisputeActionGuidanceClosed;

  /// Trucker Trip Detail Dispute Action Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No further trip-stage action is available until the dispute is resolved. Keep this trip detail for status updates and follow any support instructions if requested.'**
  String get truckerTripDetailDisputeActionGuidanceInProgress;

  /// Trucker Trip Detail Shared Visibility Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.'**
  String get truckerTripDetailSharedVisibilityClosed;

  /// Trucker Trip Detail Shared Visibility In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'**
  String get truckerTripDetailSharedVisibilityInProgress;

  /// Trucker Trip Detail Proof Guidance Closed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.'**
  String get truckerTripDetailProofGuidanceClosed;

  /// Trucker Trip Detail Proof Guidance In Progress - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If additional supporting proofs are not attached in the current single-image flow, keep the related support replies clear so support and operations know what else to review.'**
  String get truckerTripDetailProofGuidanceInProgress;

  /// Trucker Trip Detail Cancelled Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get truckerTripDetailCancelledTitle;

  /// Trucker Trip Detail Cancelled Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled before completion. No further execution actions are available, and this detail now serves as a record of the cancelled movement.'**
  String get truckerTripDetailCancelledMessage;

  /// Trucker Trip Detail Cancellation Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancellation summary'**
  String get truckerTripDetailCancellationSummaryTitle;

  /// Trucker Trip Detail Cancellation Current State - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current state: cancelled'**
  String get truckerTripDetailCancellationCurrentState;

  /// Trucker Trip Detail Route Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route: {route}'**
  String truckerTripDetailRouteLabel(Object route);

  /// Trucker Trip Detail Material Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Material: {material}'**
  String truckerTripDetailMaterialLabel(Object material);

  /// Trucker Trip Detail Assigned On Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned on: {dateTime}'**
  String truckerTripDetailAssignedOnLabel(Object dateTime);

  /// Trucker Trip Detail Cancellation Followup Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If support or operations share follow-up instructions, use this trip reference and the existing trip timeline for context.'**
  String get truckerTripDetailCancellationFollowupMessage;

  /// Trucker Trip Detail Trip Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get truckerTripDetailTripSummaryTitle;

  /// Trucker Trip Detail Trip Summary Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This trip is complete and closed out from the execution workflow.'**
  String get truckerTripDetailTripSummaryMessage;

  /// Trucker Trip Detail Completed On Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed on: {dateTime}'**
  String truckerTripDetailCompletedOnLabel(Object dateTime);

  /// Trucker Trip Detail Route Schedule Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route and schedule'**
  String get truckerTripDetailRouteScheduleTitle;

  /// Trucker Trip Detail Origin Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin: {origin}'**
  String truckerTripDetailOriginLabel(Object origin);

  /// Trucker Trip Detail Destination Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination: {destination}'**
  String truckerTripDetailDestinationLabel(Object destination);

  /// Trucker Trip Detail Distance Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String truckerTripDetailDistanceLabel(Object distance);

  /// Trucker Trip Detail Drive Time Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Drive time: {minutes} min'**
  String truckerTripDetailDriveTimeLabel(Object minutes);

  /// Trucker Trip Detail Assigned Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {dateTime}'**
  String truckerTripDetailAssignedLabel(Object dateTime);

  /// Trucker Trip Detail Started Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Started: {dateTime}'**
  String truckerTripDetailStartedLabel(Object dateTime);

  /// Trucker Trip Detail Delivered Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivered: {dateTime}'**
  String truckerTripDetailDeliveredLabel(Object dateTime);

  /// Trucker Trip Detail Pod Uploaded Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded: {dateTime}'**
  String truckerTripDetailPodUploadedLabel(Object dateTime);

  /// Trucker Trip Detail Completed Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed: {dateTime}'**
  String truckerTripDetailCompletedLabel(Object dateTime);

  /// Trucker Trip Detail Truck Supplier Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck and supplier'**
  String get truckerTripDetailTruckSupplierTitle;

  /// Trucker Trip Detail Truck Number Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck number: {truckNumber}'**
  String truckerTripDetailTruckNumberLabel(Object truckNumber);

  /// Trucker Trip Detail Body Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Body type: {bodyType}'**
  String truckerTripDetailBodyTypeLabel(Object bodyType);

  /// Trucker Trip Detail Tyres Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {tyres}'**
  String truckerTripDetailTyresLabel(Object tyres);

  /// Trucker Trip Detail Supplier Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name}'**
  String truckerTripDetailSupplierLabel(Object name);

  /// Trucker Trip Detail Company Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company: {companyName}'**
  String truckerTripDetailCompanyLabel(Object companyName);

  /// Trucker Trip Detail Mobile Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Mobile: {mobile}'**
  String truckerTripDetailMobileLabel(Object mobile);

  /// Trucker Trip Detail Take Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get truckerTripDetailTakePhotoAction;

  /// Trucker Trip Detail Choose From Gallery Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get truckerTripDetailChooseFromGalleryAction;

  /// Trucker Trip Detail Head To Pickup Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Head to pickup'**
  String get truckerTripDetailHeadToPickupAction;

  /// Trucker Trip Detail Head To Pickup Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup movement started. The supplier can now see that you are heading to pickup.'**
  String get truckerTripDetailHeadToPickupSuccess;

  /// Trucker Trip Detail Cargo Loaded Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cargo Loaded'**
  String get truckerTripDetailCargoLoadedAction;

  /// Trucker Trip Detail Cargo Loaded Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cargo loading has been confirmed for this trip.'**
  String get truckerTripDetailCargoLoadedSuccess;

  /// Trucker Trip Detail Start Trip Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get truckerTripDetailStartTripAction;

  /// Trucker Trip Detail Start Trip Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip started successfully. This load is now in transit.'**
  String get truckerTripDetailStartTripSuccess;

  /// Trucker Trip Detail Mark Delivered Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get truckerTripDetailMarkDeliveredAction;

  /// Trucker Trip Detail Mark Delivered Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery recorded. Upload POD in the next step to complete the proof flow.'**
  String get truckerTripDetailMarkDeliveredSuccess;

  /// Trucker Trip Detail Next Step Assigned Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Head to pickup'**
  String get truckerTripDetailNextStepAssignedTitle;

  /// Trucker Trip Detail Next Step Assigned Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This trip is assigned and waiting for the pickup movement to begin.'**
  String get truckerTripDetailNextStepAssignedMessage;

  /// Trucker Trip Detail Next Step Pickup Pending Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Confirm loading'**
  String get truckerTripDetailNextStepPickupPendingTitle;

  /// Trucker Trip Detail Next Step Pickup Pending Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The trip is at pickup and waiting for cargo loading confirmation.'**
  String get truckerTripDetailNextStepPickupPendingMessage;

  /// Trucker Trip Detail Next Step Picked Up Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Start the trip'**
  String get truckerTripDetailNextStepPickedUpTitle;

  /// Trucker Trip Detail Next Step Picked Up Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cargo is loaded and the next operational milestone is moving into transit.'**
  String get truckerTripDetailNextStepPickedUpMessage;

  /// Trucker Trip Detail Next Step In Transit Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reach destination'**
  String get truckerTripDetailNextStepInTransitTitle;

  /// Trucker Trip Detail Next Step In Transit Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The trip is in transit and the next milestone is delivery confirmation.'**
  String get truckerTripDetailNextStepInTransitMessage;

  /// Trucker Trip Detail Next Step Delivered Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload POD'**
  String get truckerTripDetailNextStepDeliveredTitle;

  /// Trucker Trip Detail Next Step Delivered Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Delivery is recorded and proof of delivery is the next required step.'**
  String get truckerTripDetailNextStepDeliveredMessage;

  /// Trucker Trip Detail Next Step Proof Submitted Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Await supplier confirmation'**
  String get truckerTripDetailNextStepProofSubmittedTitle;

  /// Trucker Trip Detail Next Step Proof Submitted Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Proof is submitted and the trip is waiting for supplier review or auto-completion.'**
  String get truckerTripDetailNextStepProofSubmittedMessage;

  /// Trucker Trip Detail Next Step Completed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get truckerTripDetailNextStepCompletedTitle;

  /// Trucker Trip Detail Next Step Completed Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Execution is closed and this trip now serves as a historical record.'**
  String get truckerTripDetailNextStepCompletedMessage;

  /// Trucker Trip Detail Next Step Disputed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute in progress'**
  String get truckerTripDetailNextStepDisputedTitle;

  /// Trucker Trip Detail Next Step Disputed Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'A dispute is active on this trip and operational review is required before closure.'**
  String get truckerTripDetailNextStepDisputedMessage;

  /// Trucker Trip Detail Next Step Cancelled Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get truckerTripDetailNextStepCancelledTitle;

  /// Trucker Trip Detail Next Step Cancelled Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled before normal completion and no further execution steps remain.'**
  String get truckerTripDetailNextStepCancelledMessage;

  /// Trucker Trip Detail Next Step Default Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Check execution status'**
  String get truckerTripDetailNextStepDefaultTitle;

  /// Trucker Trip Detail Next Step Default Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Review the current trip state and recent timestamps to understand the latest movement.'**
  String get truckerTripDetailNextStepDefaultMessage;

  /// Trucker Trip Detail Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get truckerTripDetailPending;

  /// Supplier Raise Dispute Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get supplierRaiseDisputeTitle;

  /// Supplier Raise Dispute Trip Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip detail unavailable'**
  String get supplierRaiseDisputeTripUnavailableTitle;

  /// Supplier Raise Dispute Trip Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load this trip detail right now. Retry shortly to review the latest dispute context.'**
  String get supplierRaiseDisputeTripLoadFailureMessage;

  /// Supplier Raise Dispute Hero Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute delivery proof'**
  String get supplierRaiseDisputeHeroTitle;

  /// Supplier Raise Dispute Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain what is wrong with the submitted POD so the dispute can be opened against the current trip and routed into support review.'**
  String get supplierRaiseDisputeHeroSubtitle;

  /// Supplier Raise Dispute Trip Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip {tripId}'**
  String supplierRaiseDisputeTripBadge(Object tripId);

  /// Supplier Raise Dispute Hero Summary - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{routeLabel} - {material}'**
  String supplierRaiseDisputeHeroSummary(Object material, Object routeLabel);

  /// Supplier Raise Dispute Hero Guidance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select the dispute category that best matches the issue, add a written explanation, and optionally attach one supporting evidence image for support review.'**
  String get supplierRaiseDisputeHeroGuidance;

  /// Supplier Raise Dispute Partial Context Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some trip detail context is unavailable'**
  String get supplierRaiseDisputePartialContextUnavailableTitle;

  /// Supplier Raise Dispute Trip Context Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some dispute context is temporarily unavailable. Retry shortly to refresh the latest trip detail and proof review state.'**
  String get supplierRaiseDisputeTripContextFailureMessage;

  /// Supplier Raise Dispute Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute summary'**
  String get supplierRaiseDisputeSummaryTitle;

  /// Supplier Raise Dispute Trip Route Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip route: {routeLabel}'**
  String supplierRaiseDisputeTripRouteLabel(Object routeLabel);

  /// Supplier Raise Dispute Truck Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck: {truckNumber}'**
  String supplierRaiseDisputeTruckLabel(Object truckNumber);

  /// Supplier Raise Dispute Trucker Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker: {truckerName}'**
  String supplierRaiseDisputeTruckerLabel(Object truckerName);

  /// Supplier Raise Dispute Current Stage Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current stage: {stageLabel}'**
  String supplierRaiseDisputeCurrentStageLabel(Object stageLabel);

  /// Supplier Raise Dispute Submission Blocked Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute submission blocked'**
  String get supplierRaiseDisputeSubmissionBlockedTitle;

  /// Supplier Raise Dispute Submission Blocked Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You can only raise this POD dispute while the trip is in proof submitted state.'**
  String get supplierRaiseDisputeSubmissionBlockedMessage;

  /// Supplier Raise Dispute Submission Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute submission unavailable'**
  String get supplierRaiseDisputeSubmissionUnavailableTitle;

  /// Supplier Raise Dispute Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this dispute right now. Review the dispute details and retry shortly.'**
  String get supplierRaiseDisputeSubmitFailureMessage;

  /// Supplier Raise Dispute Problem Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What is wrong with the POD?'**
  String get supplierRaiseDisputeProblemTitle;

  /// Supplier Raise Dispute Category Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute category'**
  String get supplierRaiseDisputeCategoryLabel;

  /// Supplier Raise Dispute Reason Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute reason'**
  String get supplierRaiseDisputeReasonLabel;

  /// Supplier Raise Dispute Reason Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain what is wrong with the submitted proof and what support should review.'**
  String get supplierRaiseDisputeReasonHint;

  /// Supplier Raise Dispute Helpful Details Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Helpful details to include'**
  String get supplierRaiseDisputeHelpfulDetailsTitle;

  /// Supplier Raise Dispute Helpful Details Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The current dispute flow still accepts one optional image. Use these prompts to capture any second or third proof in your written explanation.'**
  String get supplierRaiseDisputeHelpfulDetailsMessage;

  /// Supplier Raise Dispute Evidence Optional Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence (optional)'**
  String get supplierRaiseDisputeEvidenceOptionalTitle;

  /// Supplier Raise Dispute No Evidence Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No evidence image attached yet. You can attach one supporting image in the current flow.'**
  String get supplierRaiseDisputeNoEvidenceAttached;

  /// Supplier Raise Dispute Evidence Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'One supporting evidence image is attached for review.'**
  String get supplierRaiseDisputeEvidenceAttached;

  /// Supplier Raise Dispute Visible To Other Party Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Visible to the other party: dispute category and status only. Raw evidence may stay restricted during review.'**
  String get supplierRaiseDisputeVisibleToOtherPartyMessage;

  /// Supplier Raise Dispute Use Camera Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get supplierRaiseDisputeUseCameraAction;

  /// Supplier Raise Dispute Choose Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get supplierRaiseDisputeChoosePhotoAction;

  /// Supplier Raise Dispute Remove Evidence Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Remove evidence'**
  String get supplierRaiseDisputeRemoveEvidenceAction;

  /// Supplier Raise Dispute Submit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit dispute'**
  String get supplierRaiseDisputeSubmitAction;

  /// Supplier Raise Dispute Category Error - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select a valid dispute category'**
  String get supplierRaiseDisputeCategoryError;

  /// Supplier Raise Dispute Reason Error - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain the POD problem in at least 10 characters'**
  String get supplierRaiseDisputeReasonError;

  /// Supplier Raise Dispute Submitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted. Support ticket created for review.'**
  String get supplierRaiseDisputeSubmittedSuccess;

  /// Supplier Raise Dispute Attachment Attached Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached successfully'**
  String get supplierRaiseDisputeAttachmentAttachedSuccess;

  /// Supplier Raise Dispute Attachment Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not attach that evidence image right now. Try another image or retry shortly.'**
  String get supplierRaiseDisputeAttachmentFailureMessage;

  /// Supplier Raise Dispute Evidence Guidance Loaded Quantity Mismatch - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: the loaded bilty or loading proof that shows the dispatched quantity. Only one image can be attached right now.'**
  String get supplierRaiseDisputeEvidenceGuidanceLoadedQuantityMismatch;

  /// Supplier Raise Dispute Evidence Guidance Unloaded Quantity Mismatch - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: the unloaded bilty, weighbridge slip, or unloading proof showing the received quantity. Only one image can be attached right now.'**
  String get supplierRaiseDisputeEvidenceGuidanceUnloadedQuantityMismatch;

  /// Supplier Raise Dispute Evidence Guidance Document Mismatch - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: the clearest POD, bilty, or related proof image showing the document mismatch. Only one image can be attached right now.'**
  String get supplierRaiseDisputeEvidenceGuidanceDocumentMismatch;

  /// Supplier Raise Dispute Evidence Guidance Non Payment - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one proof image that best supports the non-payment claim. Full payment workflow evidence still remains limited in the current flow.'**
  String get supplierRaiseDisputeEvidenceGuidanceNonPayment;

  /// Supplier Raise Dispute Evidence Guidance Fake Payout Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one payout-proof image that best shows the fake or inconsistent payment claim.'**
  String get supplierRaiseDisputeEvidenceGuidanceFakePayoutProof;

  /// Supplier Raise Dispute Evidence Guidance Delay Or No Show - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one supporting image or screenshot that best shows the delay or no-show context.'**
  String get supplierRaiseDisputeEvidenceGuidanceDelayOrNoShow;

  /// Supplier Raise Dispute Evidence Guidance Damage Or Shortage - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one image that best shows the damage, shortage, or affected goods at delivery.'**
  String get supplierRaiseDisputeEvidenceGuidanceDamageOrShortage;

  /// Supplier Raise Dispute Evidence Guidance Abusive Behavior - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one supporting image or screenshot if it is safe and relevant to the abusive-behavior claim.'**
  String get supplierRaiseDisputeEvidenceGuidanceAbusiveBehavior;

  /// Supplier Raise Dispute Evidence Guidance Spam Or Scam - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one screenshot or proof image that best supports the spam or scam report.'**
  String get supplierRaiseDisputeEvidenceGuidanceSpamOrScam;

  /// Supplier Raise Dispute Evidence Guidance Other - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Provide a clear explanation of the dispute and attach the single most relevant supporting image if needed.'**
  String get supplierRaiseDisputeEvidenceGuidanceOther;

  /// Supplier Raise Dispute Evidence Guidance Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attach the single most relevant supporting image available for this dispute category.'**
  String get supplierRaiseDisputeEvidenceGuidanceFallback;

  /// Supplier Raise Dispute Best Image Guidance Document Category - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the clearest single document image where quantities, signatures, stamps, or POD details are readable in one frame.'**
  String get supplierRaiseDisputeBestImageGuidanceDocumentCategory;

  /// Supplier Raise Dispute Best Image Guidance Payment Category - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the single screenshot or payout-proof image that most clearly shows the mismatch, missing payment, or fake confirmation.'**
  String get supplierRaiseDisputeBestImageGuidancePaymentCategory;

  /// Supplier Raise Dispute Best Image Guidance Timeline Category - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the single screenshot or photo that gives the strongest timeline or behavior context in one image.'**
  String get supplierRaiseDisputeBestImageGuidanceTimelineCategory;

  /// Supplier Raise Dispute Best Image Guidance Damage Category - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the single image that best shows the damaged goods, shortage, or delivered condition at handover.'**
  String get supplierRaiseDisputeBestImageGuidanceDamageCategory;

  /// Supplier Raise Dispute Best Image Guidance Other - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the one image that gives support the strongest proof of the issue you describe in your written reason.'**
  String get supplierRaiseDisputeBestImageGuidanceOther;

  /// Supplier Raise Dispute Best Image Guidance Fallback - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the one clearest image that gives support the strongest proof to review first.'**
  String get supplierRaiseDisputeBestImageGuidanceFallback;

  /// Supplier Raise Dispute Prompt Dispatch Quantity Shown On Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Dispatch quantity shown on proof:'**
  String get supplierRaiseDisputePromptDispatchQuantityShownOnProof;

  /// Supplier Raise Dispute Prompt Quantity Actually Challenged - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Quantity actually challenged:'**
  String get supplierRaiseDisputePromptQuantityActuallyChallenged;

  /// Supplier Raise Dispute Prompt Other Loading Proof Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other loading proof not attached but reviewed by support:'**
  String get supplierRaiseDisputePromptOtherLoadingProofNotAttached;

  /// Supplier Raise Dispute Prompt Quantity Received At Unloading - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Quantity received at unloading:'**
  String get supplierRaiseDisputePromptQuantityReceivedAtUnloading;

  /// Supplier Raise Dispute Prompt Quantity Expected From Dispatch Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Quantity expected from dispatch proof:'**
  String get supplierRaiseDisputePromptQuantityExpectedFromDispatchProof;

  /// Supplier Raise Dispute Prompt Extra Unload Proof Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Extra unload proof not attached but available:'**
  String get supplierRaiseDisputePromptExtraUnloadProofNotAttached;

  /// Supplier Raise Dispute Prompt Document Field Does Not Match - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Document field that does not match:'**
  String get supplierRaiseDisputePromptDocumentFieldDoesNotMatch;

  /// Supplier Raise Dispute Prompt Correct Trip Or Pod Detail Should Be - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Correct trip or POD detail should be:'**
  String get supplierRaiseDisputePromptCorrectTripOrPodDetailShouldBe;

  /// Supplier Raise Dispute Prompt Other Related Document Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other related document not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherRelatedDocumentNotAttached;

  /// Supplier Raise Dispute Prompt Amount Still Unpaid - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Amount still unpaid:'**
  String get supplierRaiseDisputePromptAmountStillUnpaid;

  /// Supplier Raise Dispute Prompt Payment Due Date Or Milestone - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Payment due date or milestone:'**
  String get supplierRaiseDisputePromptPaymentDueDateOrMilestone;

  /// Supplier Raise Dispute Prompt Other Payment Proof Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other payment proof not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherPaymentProofNotAttached;

  /// Supplier Raise Dispute Prompt Why Payout Proof Looks Fake - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Why the payout proof looks fake or inconsistent:'**
  String get supplierRaiseDisputePromptWhyPayoutProofLooksFake;

  /// Supplier Raise Dispute Prompt What Payment Status Should Be - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What payment status should be instead:'**
  String get supplierRaiseDisputePromptWhatPaymentStatusShouldBe;

  /// Supplier Raise Dispute Prompt Other Proof Or Chat Context Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other proof or chat context not attached:'**
  String get supplierRaiseDisputePromptOtherProofOrChatContextNotAttached;

  /// Supplier Raise Dispute Prompt Expected Reporting Or Arrival Time - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Expected reporting or arrival time:'**
  String get supplierRaiseDisputePromptExpectedReportingOrArrivalTime;

  /// Supplier Raise Dispute Prompt Actual Delay Or No Show Outcome - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Actual delay or no-show outcome:'**
  String get supplierRaiseDisputePromptActualDelayOrNoShowOutcome;

  /// Supplier Raise Dispute Prompt Other Timing Proof Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other timing proof not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherTimingProofNotAttached;

  /// Supplier Raise Dispute Prompt Goods Affected By Damage Or Shortage - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Goods affected by damage or shortage:'**
  String get supplierRaiseDisputePromptGoodsAffectedByDamageOrShortage;

  /// Supplier Raise Dispute Prompt Quantity Or Condition Difference Noticed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Quantity or condition difference noticed:'**
  String get supplierRaiseDisputePromptQuantityOrConditionDifferenceNoticed;

  /// Supplier Raise Dispute Prompt Other Supporting Proof Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other supporting proof not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherSupportingProofNotAttached;

  /// Supplier Raise Dispute Prompt What Happened During Incident - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What happened during the incident:'**
  String get supplierRaiseDisputePromptWhatHappenedDuringIncident;

  /// Supplier Raise Dispute Prompt When Or Where Behavior Occurred - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'When or where the behavior occurred:'**
  String get supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred;

  /// Supplier Raise Dispute Prompt What Scam Or Spam Behavior Occurred - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What scam or spam behavior occurred:'**
  String get supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred;

  /// Supplier Raise Dispute Prompt What Misleading Claim Was Made - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What misleading claim was made:'**
  String get supplierRaiseDisputePromptWhatMisleadingClaimWasMade;

  /// Supplier Raise Dispute Prompt Main Issue Support Should Review - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Main issue support should review:'**
  String get supplierRaiseDisputePromptMainIssueSupportShouldReview;

  /// Supplier Raise Dispute Prompt What Outcome Or Correction Needed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What outcome or correction is needed:'**
  String get supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded;

  /// Supplier Raise Dispute Prompt Strongest Missing Proof Not Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Strongest missing proof not attached:'**
  String get supplierRaiseDisputePromptStrongestMissingProofNotAttached;

  /// Supplier Raise Dispute Checklist Loaded Readable Quantity - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the dispatched quantity readable in the uploaded image.'**
  String get supplierRaiseDisputeChecklistLoadedReadableQuantity;

  /// Supplier Raise Dispute Checklist Loaded Prefer Bilty - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Include the bilty, loading slip, or marked proof instead of a distant photo.'**
  String get supplierRaiseDisputeChecklistLoadedPreferBilty;

  /// Supplier Raise Dispute Checklist Loaded Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to describe any additional document context not visible in the image.'**
  String get supplierRaiseDisputeChecklistLoadedUseWrittenReason;

  /// Supplier Raise Dispute Checklist Unloaded Keep Received Quantity - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the received quantity or unload record readable in the image.'**
  String get supplierRaiseDisputeChecklistUnloadedKeepReceivedQuantity;

  /// Supplier Raise Dispute Checklist Unloaded Prefer Weighbridge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Prefer a weighbridge slip, unload bilty, or marked proof over a generic cargo photo.'**
  String get supplierRaiseDisputeChecklistUnloadedPreferWeighbridge;

  /// Supplier Raise Dispute Checklist Unloaded Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain any missing second document that cannot fit in the current single-image flow.'**
  String get supplierRaiseDisputeChecklistUnloadedUseWrittenReason;

  /// Supplier Raise Dispute Checklist Document Readable Fields - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Make sure key document fields are readable in one frame.'**
  String get supplierRaiseDisputeChecklistDocumentReadableFields;

  /// Supplier Raise Dispute Checklist Document Prefer Specific Page - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Prefer the specific POD or bilty page where the mismatch appears.'**
  String get supplierRaiseDisputeChecklistDocumentPreferSpecificPage;

  /// Supplier Raise Dispute Checklist Document Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to describe what field or proof does not match the trip.'**
  String get supplierRaiseDisputeChecklistDocumentUseWrittenReason;

  /// Supplier Raise Dispute Checklist Payment Prefer Clearest Screenshot - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Prefer the clearest single payout-related screenshot or proof image.'**
  String get supplierRaiseDisputeChecklistPaymentPreferClearestScreenshot;

  /// Supplier Raise Dispute Checklist Payment Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain what payment is still missing and when it was due.'**
  String get supplierRaiseDisputeChecklistPaymentUseWrittenReason;

  /// Supplier Raise Dispute Checklist Payment Upload Strongest First - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If multiple proofs exist, upload the strongest one first and summarize the rest in text.'**
  String get supplierRaiseDisputeChecklistPaymentUploadStrongestFirst;

  /// Supplier Raise Dispute Checklist Fake Prefer Screenshot - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Prefer the payout screenshot or proof image that most clearly appears fake or inconsistent.'**
  String get supplierRaiseDisputeChecklistFakePreferScreenshot;

  /// Supplier Raise Dispute Checklist Fake Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain what is suspicious about the proof.'**
  String get supplierRaiseDisputeChecklistFakeUseWrittenReason;

  /// Supplier Raise Dispute Checklist Fake Summarize Chat Context - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'If supporting chat context exists, summarize it in text when it cannot fit in the single-image flow.'**
  String get supplierRaiseDisputeChecklistFakeSummarizeChatContext;

  /// Supplier Raise Dispute Checklist Delay Choose Clearest Timing - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the clearest screenshot or photo showing the missed timing or no-show context.'**
  String get supplierRaiseDisputeChecklistDelayChooseClearestTiming;

  /// Supplier Raise Dispute Checklist Delay Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain the expected time and the actual outcome.'**
  String get supplierRaiseDisputeChecklistDelayUseWrittenReason;

  /// Supplier Raise Dispute Checklist Delay Keep Focused Image - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the uploaded image focused on timing/location evidence instead of unrelated media.'**
  String get supplierRaiseDisputeChecklistDelayKeepFocusedImage;

  /// Supplier Raise Dispute Checklist Damage Choose Image - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the image that most clearly shows the damage or shortage at delivery.'**
  String get supplierRaiseDisputeChecklistDamageChooseImage;

  /// Supplier Raise Dispute Checklist Damage Keep Affected Goods - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the affected goods or missing quantity context visible in the frame.'**
  String get supplierRaiseDisputeChecklistDamageKeepAffectedGoods;

  /// Supplier Raise Dispute Checklist Damage Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain what cannot be shown in the single uploaded image.'**
  String get supplierRaiseDisputeChecklistDamageUseWrittenReason;

  /// Supplier Raise Dispute Checklist Abusive Upload If Safe - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Upload evidence only if it is safe and relevant to the case.'**
  String get supplierRaiseDisputeChecklistAbusiveUploadIfSafe;

  /// Supplier Raise Dispute Checklist Abusive Prefer Clearest Screenshot - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Prefer the clearest screenshot or image tied directly to the abusive incident.'**
  String get supplierRaiseDisputeChecklistAbusivePreferClearestScreenshot;

  /// Supplier Raise Dispute Checklist Abusive Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain the sequence of events without adding sensitive internal notes.'**
  String get supplierRaiseDisputeChecklistAbusiveUseWrittenReason;

  /// Supplier Raise Dispute Checklist Spam Choose Screenshot - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the screenshot or image that most clearly shows the scam or spam behavior.'**
  String get supplierRaiseDisputeChecklistSpamChooseScreenshot;

  /// Supplier Raise Dispute Checklist Spam Prefer Strongest Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Prefer the strongest proof of deception instead of a partial conversation fragment.'**
  String get supplierRaiseDisputeChecklistSpamPreferStrongestProof;

  /// Supplier Raise Dispute Checklist Spam Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to summarize any extra scam context that cannot fit in one image.'**
  String get supplierRaiseDisputeChecklistSpamUseWrittenReason;

  /// Supplier Raise Dispute Checklist Other Choose Strongest Image - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the one strongest image that supports your explanation.'**
  String get supplierRaiseDisputeChecklistOtherChooseStrongestImage;

  /// Supplier Raise Dispute Checklist Other Keep Issue Readable - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the issue-specific detail readable in the uploaded image.'**
  String get supplierRaiseDisputeChecklistOtherKeepIssueReadable;

  /// Supplier Raise Dispute Checklist Other Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain the rest of the evidence that cannot fit in the current flow.'**
  String get supplierRaiseDisputeChecklistOtherUseWrittenReason;

  /// Supplier Raise Dispute Checklist Fallback Choose Clearest Image - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose the one clearest supporting image available.'**
  String get supplierRaiseDisputeChecklistFallbackChooseClearestImage;

  /// Supplier Raise Dispute Checklist Fallback Keep Readable Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Keep the important proof readable in the frame.'**
  String get supplierRaiseDisputeChecklistFallbackKeepReadableProof;

  /// Supplier Raise Dispute Checklist Fallback Use Written Reason - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to describe any additional evidence not visible in the image.'**
  String get supplierRaiseDisputeChecklistFallbackUseWrittenReason;

  /// Report Issue Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssueTitle;

  /// Report Issue Hero Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report spam, scam, or abuse'**
  String get reportIssueHeroTitle;

  /// Report Issue Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open a trust-safety ticket tied to the current operational context so support can review the issue quickly.'**
  String get reportIssueHeroSubtitle;

  /// Report Issue Hero Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attach one evidence image if you have it. The report still submits through the live support-ticket workflow using the linked load/trip context, and can also capture fake payout-proof or non-payment issues.'**
  String get reportIssueHeroMessage;

  /// Report Issue Submission Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report submission unavailable'**
  String get reportIssueSubmissionUnavailableTitle;

  /// Report Issue Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This report could not be prepared or submitted right now. Review the linked context and try again shortly.'**
  String get reportIssueFailureMessage;

  /// Report Issue Linked Context Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Linked context'**
  String get reportIssueLinkedContextTitle;

  /// Report Issue Source Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Source: {sourceLabel}'**
  String reportIssueSourceLabel(Object sourceLabel);

  /// Report Issue Related Load Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Related load: {value}'**
  String reportIssueRelatedLoadLabel(Object value);

  /// Report Issue Related Trip Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Related trip: {value}'**
  String reportIssueRelatedTripLabel(Object value);

  /// Report Issue Not Linked - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get reportIssueNotLinked;

  /// Report Issue Details Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportIssueDetailsTitle;

  /// Report Issue Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Issue type'**
  String get reportIssueTypeLabel;

  /// Report Issue What Happened Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportIssueWhatHappenedLabel;

  /// Report Issue What Happened Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain the spam, fake proof, non-payment, payout deception, or abusive behavior that support should review.'**
  String get reportIssueWhatHappenedHint;

  /// Report Issue Helpful Details Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Helpful details to include'**
  String get reportIssueHelpfulDetailsTitle;

  /// Report Issue Evidence Optional Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence (required)'**
  String get reportIssueEvidenceOptionalTitle;

  /// Report Issue No Evidence Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attach one evidence image before submitting this report.'**
  String get reportIssueNoEvidenceAttached;

  /// Report Issue Evidence Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'One evidence image is attached for review.'**
  String get reportIssueEvidenceAttached;

  /// Report Issue Use Camera Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get reportIssueUseCameraAction;

  /// Report Issue Choose Photo Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get reportIssueChoosePhotoAction;

  /// Report Issue Remove Evidence Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Remove evidence'**
  String get reportIssueRemoveEvidenceAction;

  /// Report Issue Submit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportIssueSubmitAction;

  /// Report Issue Submitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get reportIssueSubmittedSuccess;

  /// Report Issue Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this report right now. Review the details and retry shortly.'**
  String get reportIssueSubmitFailureMessage;

  /// Report Issue Attachment Attached Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached successfully'**
  String get reportIssueAttachmentAttachedSuccess;

  /// Report Issue Attachment Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not attach that evidence image right now. Try another image or retry shortly.'**
  String get reportIssueAttachmentFailureMessage;

  /// Report Issue Category Spam Or Scam Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportIssueCategorySpamOrScamLabel;

  /// Report Issue Category Abusive Behavior Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior'**
  String get reportIssueCategoryAbusiveBehaviorLabel;

  /// Report Issue Category Fake Payout Proof Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof'**
  String get reportIssueCategoryFakePayoutProofLabel;

  /// Report Issue Category Non Payment Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Non-payment'**
  String get reportIssueCategoryNonPaymentLabel;

  /// Report Issue Category Guidance Spam Or Scam - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain the spam, scam, or misleading behavior clearly and attach one evidence image that helps support review the report.'**
  String get reportIssueCategoryGuidanceSpamOrScam;

  /// Report Issue Category Guidance Abusive Behavior - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Describe the abusive or unsafe behavior clearly, including where it happened and any context support should review.'**
  String get reportIssueCategoryGuidanceAbusiveBehavior;

  /// Report Issue Category Guidance Fake Payout Proof - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain why the payout proof looks fake or misleading and attach one evidence image with the most useful payment context you can share.'**
  String get reportIssueCategoryGuidanceFakePayoutProof;

  /// Report Issue Category Guidance Non Payment - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Describe the non-payment issue clearly, including what was due, what follow-up already happened, and attach one evidence image with the strongest payment proof you can share.'**
  String get reportIssueCategoryGuidanceNonPayment;

  /// Support Create Ticket Screen Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Create support ticket'**
  String get supportCreateTicketScreenTitle;

  /// Support Create Ticket Hero Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open a support request'**
  String get supportCreateTicketHeroTitle;

  /// Support Create Ticket Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue clearly so support can route it faster and keep your follow-up thread linked to the right context.'**
  String get supportCreateTicketHeroSubtitle;

  /// Support Create Ticket Hero Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You can optionally include a related load or trip id if the issue is tied to a specific operational flow. You can also attach one evidence image if it helps support review the issue faster.'**
  String get supportCreateTicketHeroMessage;

  /// Support Create Ticket Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support request needs attention'**
  String get supportCreateTicketFailureTitle;

  /// Support Create Ticket Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your support request could not be prepared or submitted right now. Review the issue details and try again shortly.'**
  String get supportCreateTicketFailureMessage;

  /// Support Create Ticket Details Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Ticket details'**
  String get supportCreateTicketDetailsTitle;

  /// Support Compose Category Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportComposeCategoryLabel;

  /// Support Compose Category General - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get supportComposeCategoryGeneral;

  /// Support Compose Category Account - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supportComposeCategoryAccount;

  /// Support Compose Category Load - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get supportComposeCategoryLoad;

  /// Support Compose Category Trip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get supportComposeCategoryTrip;

  /// Support Compose Category Payment - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get supportComposeCategoryPayment;

  /// Support Compose Category Technical - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get supportComposeCategoryTechnical;

  /// Support Compose Category Other - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportComposeCategoryOther;

  /// Support Create Ticket Related Load Id Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Related load id (optional)'**
  String get supportCreateTicketRelatedLoadIdLabel;

  /// Support Create Ticket Related Load Id Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'load-123'**
  String get supportCreateTicketRelatedLoadIdHint;

  /// Support Create Ticket Related Trip Id Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Related trip id (optional)'**
  String get supportCreateTicketRelatedTripIdLabel;

  /// Support Create Ticket Related Trip Id Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'trip-123'**
  String get supportCreateTicketRelatedTripIdHint;

  /// Support Create Ticket Description Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get supportCreateTicketDescriptionLabel;

  /// Support Create Ticket Description Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Explain what happened, what is blocked, and what follow-up you need.'**
  String get supportCreateTicketDescriptionHint;

  /// Support Compose Attachment Optional Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attachment (optional)'**
  String get supportComposeAttachmentOptionalTitle;

  /// Support Compose No Attachment - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No evidence image attached yet.'**
  String get supportComposeNoAttachment;

  /// Support Compose Attachment Attached - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'One evidence image is attached for support review.'**
  String get supportComposeAttachmentAttached;

  /// Support Compose Remove Attachment Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get supportComposeRemoveAttachmentAction;

  /// Support Compose Attachment Added Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attachment added successfully'**
  String get supportComposeAttachmentAddedSuccess;

  /// Support Compose Attachment Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not attach that evidence image right now. Try another image or retry shortly.'**
  String get supportComposeAttachmentFailureMessage;

  /// Support Create Ticket Invalid Category Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select a valid support category'**
  String get supportCreateTicketInvalidCategoryMessage;

  /// Support Create Ticket Description Too Short Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in at least 10 characters'**
  String get supportCreateTicketDescriptionTooShortMessage;

  /// Report Issue Invalid Category Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select a valid report category'**
  String get reportIssueInvalidCategoryMessage;

  /// Report Issue Description Too Short Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in at least 10 characters'**
  String get reportIssueDescriptionTooShortMessage;

  /// Report Issue Attachment Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Attach one evidence image before submitting this report'**
  String get reportIssueAttachmentRequiredMessage;

  /// Support Reply Message Too Short Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply must contain at least 2 characters'**
  String get supportReplyMessageTooShortMessage;

  /// Support Create Ticket Submit Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get supportCreateTicketSubmitAction;

  /// Support Create Ticket Submitted Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Support ticket created successfully'**
  String get supportCreateTicketSubmittedSuccess;

  /// Support Create Ticket Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not create this support ticket right now. Review the details and retry shortly.'**
  String get supportCreateTicketSubmitFailureMessage;

  /// Support Reply Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply needs attention'**
  String get supportReplyFailureTitle;

  /// Support Reply Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your latest support reply could not be prepared or submitted right now. Review the message and try again shortly.'**
  String get supportReplyFailureMessage;

  /// Support Reply Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply to support'**
  String get supportReplyLabel;

  /// Support Reply Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add the next detail or response support requested.'**
  String get supportReplyHint;

  /// Support Reply Send Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get supportReplySendAction;

  /// Support Reply Sent Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reply sent successfully'**
  String get supportReplySentSuccess;

  /// Support Reply Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not send your reply right now. Review the message and retry shortly.'**
  String get supportReplySubmitFailureMessage;

  /// Supplier Trips Section Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier trips'**
  String get supplierTripsSectionTitle;

  /// Supplier Trips Section Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track active movements and recent trip outcomes from one supplier execution surface.'**
  String get supplierTripsSectionSubtitle;

  /// Supplier Trips Tab Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get supplierTripsTabActive;

  /// Supplier Trips Tab Completed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get supplierTripsTabCompleted;

  /// Supplier Trips Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load supplier trips'**
  String get supplierTripsLoadFailureTitle;

  /// Supplier Trips Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your supplier trips right now. Retry shortly to refresh the latest trip list and statuses.'**
  String get supplierTripsLoadFailureMessage;

  /// Supplier Trips Empty Active Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No active trips yet'**
  String get supplierTripsEmptyActiveTitle;

  /// Supplier Trips Empty Completed Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get supplierTripsEmptyCompletedTitle;

  /// Supplier Trips Empty Active Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips will appear here once a load moves into assigned execution.'**
  String get supplierTripsEmptyActiveSubtitle;

  /// Supplier Trips Empty Completed Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Completed supplier trips will appear here once deliveries are closed out.'**
  String get supplierTripsEmptyCompletedSubtitle;

  /// Supplier Trips Empty Active Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open my loads'**
  String get supplierTripsEmptyActiveAction;

  /// Supplier Trips Empty Completed Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'View active trips'**
  String get supplierTripsEmptyCompletedAction;

  /// Supplier Trips Assigned Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned {date}'**
  String supplierTripsAssignedLabel(Object date);

  /// Supplier Trips Trucker Truck Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker {truckerId} - Truck {truckId}'**
  String supplierTripsTruckerTruckLabel(Object truckId, Object truckerId);

  /// Supplier Trips Track Trip Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Track trip'**
  String get supplierTripsTrackTripAction;

  /// Supplier Trip Detail Not Found Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get supplierTripDetailNotFoundTitle;

  /// Supplier Trip Detail Not Found Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This supplier trip is no longer available or you no longer have access to it.'**
  String get supplierTripDetailNotFoundSubtitle;

  /// Supplier Trip Detail Back To Trips Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to supplier trips'**
  String get supplierTripDetailBackToTripsAction;

  /// Supplier Trip Detail Stub Screen Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip detail'**
  String get supplierTripDetailStubScreenTitle;

  /// Supplier Trip Detail Stub Card Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier trip detail'**
  String get supplierTripDetailStubCardTitle;

  /// Supplier Trip Detail Stub Reference - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip reference: {tripId}'**
  String supplierTripDetailStubReference(Object tripId);

  /// Supplier Trip Detail Stub Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Detailed supplier trip execution screens will expand in the next trip-detail slice. Navigation is already wired from the supplier trips list.'**
  String get supplierTripDetailStubMessage;

  /// Assistant Hero Title With Name - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Guided help for {firstName}'**
  String assistantHeroTitleWithName(Object firstName);

  /// Assistant Hero Subtitle Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use guided shortcuts for posting loads, checking active load execution, and opening the right communication or support surface quickly.'**
  String get assistantHeroSubtitleSupplier;

  /// Assistant Hero Subtitle Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use guided shortcuts for finding loads, checking trip execution, and opening the right communication or support surface quickly.'**
  String get assistantHeroSubtitleTrucker;

  /// Assistant Workflow Guidance Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier workflow guidance'**
  String get assistantWorkflowGuidanceSupplier;

  /// Assistant Workflow Guidance Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker workflow guidance'**
  String get assistantWorkflowGuidanceTrucker;

  /// Assistant Profile Complete - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile complete'**
  String get assistantProfileComplete;

  /// Assistant Profile Incomplete - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Profile incomplete'**
  String get assistantProfileIncomplete;

  /// Assistant Recommended Next Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Recommended next actions'**
  String get assistantRecommendedNextActionsTitle;

  /// Assistant Open Supplier Trips Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open supplier trips'**
  String get assistantOpenSupplierTripsAction;

  /// Assistant Find Loads Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Find loads'**
  String get assistantFindLoadsAction;

  /// Assistant Open Trips Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open trips'**
  String get assistantOpenTripsAction;

  /// Assistant Open Messages Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open messages'**
  String get assistantOpenMessagesAction;

  /// Assistant Guided Help Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Guided help'**
  String get assistantGuidedHelpTitle;

  /// Assistant Best For Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Best for'**
  String get assistantBestForLabel;

  /// Assistant Best For Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Posting loads, checking active load execution, reviewing conversations, and opening support quickly.'**
  String get assistantBestForSupplier;

  /// Assistant Best For Trucker - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Finding loads, checking trip execution, reviewing conversations, and opening support quickly.'**
  String get assistantBestForTrucker;

  /// Assistant Voice Behavior Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice behavior'**
  String get assistantVoiceBehaviorLabel;

  /// Assistant Voice Behavior Value - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Manual entry only right now. Full conversational bot, STT, and auto-speak remain in the dedicated communication and localization phases.'**
  String get assistantVoiceBehaviorValue;

  /// Assistant Current Role Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Current role'**
  String get assistantCurrentRoleLabel;

  /// Assistant More Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get assistantMoreActionsTitle;

  /// Assistant Open Notifications Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open notifications'**
  String get assistantOpenNotificationsAction;

  /// Assistant Open Support Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open support'**
  String get assistantOpenSupportAction;

  /// Shell Access Restricted Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Access restricted'**
  String get shellAccessRestrictedTitle;

  /// Shell Access Restricted Deactivated Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account is deactivated pending cleanup. Signing you out safely...'**
  String get shellAccessRestrictedDeactivatedSubtitle;

  /// Shell Access Restricted Banned Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your account access is restricted. Signing you out safely...'**
  String get shellAccessRestrictedBannedSubtitle;

  /// Shell Account Deactivated Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get shellAccountDeactivatedMessage;

  /// Shell Account Banned Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Account banned'**
  String get shellAccountBannedMessage;

  /// Shell Route Not Found Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get shellRouteNotFoundTitle;

  /// Shell Messages Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load your messages right now. Retry shortly to refresh the latest conversations.'**
  String get shellMessagesLoadFailureMessage;

  /// Shell Messages Booking Status Submitted - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get shellMessagesBookingStatusSubmitted;

  /// Shell Messages Booking Status Approved - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get shellMessagesBookingStatusApproved;

  /// Shell Messages Booking Status Rejected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get shellMessagesBookingStatusRejected;

  /// Shell Messages Booking Status Pending - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get shellMessagesBookingStatusPending;

  /// Shell Messages Booking Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get shellMessagesBookingStatusUnknown;

  /// Trucker Load Detail Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load Detail'**
  String get truckerLoadDetailTitle;

  /// Trucker Load Detail Load Not Found Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load not found'**
  String get truckerLoadDetailLoadNotFoundTitle;

  /// Trucker Load Detail Load Not Found Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This marketplace load is no longer available or you no longer have access to it.'**
  String get truckerLoadDetailLoadNotFoundSubtitle;

  /// Trucker Load Detail Back To Find Loads Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to find loads'**
  String get truckerLoadDetailBackToFindLoadsAction;

  /// Trucker Load Detail Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load freight detail'**
  String get truckerLoadDetailLoadFailureTitle;

  /// Trucker Load Detail Load Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not load this freight detail right now. Retry shortly to refresh the current route, pricing, and booking context.'**
  String get truckerLoadDetailLoadFailureMessage;

  /// Trucker Load Detail Support Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some supporting load details are unavailable'**
  String get truckerLoadDetailSupportUnavailableTitle;

  /// Trucker Load Detail Support Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some supporting load details are temporarily unavailable. Retry shortly to refresh the latest freight context.'**
  String get truckerLoadDetailSupportFailureMessage;

  /// Trucker Load Detail Action Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Action unavailable'**
  String get truckerLoadDetailActionFailureTitle;

  /// Trucker Load Detail Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'The latest load action could not be completed right now. Review the current load details and retry shortly.'**
  String get truckerLoadDetailActionFailureMessage;

  /// Trucker Load Detail Booking Submit Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this booking request right now. Review the selected truck and retry shortly.'**
  String get truckerLoadDetailBookingSubmitFailureMessage;

  /// Trucker Load Detail Hero Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load {loadId} - Pickup {pickupDate}'**
  String truckerLoadDetailHeroSubtitle(Object loadId, Object pickupDate);

  /// Trucker Load Detail Price Badge - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'₹{priceAmount} - {priceType}'**
  String truckerLoadDetailPriceBadge(Object priceAmount, Object priceType);

  /// Trucker Load Detail Truck Match Available - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck match available'**
  String get truckerLoadDetailTruckMatchAvailable;

  /// Trucker Load Detail No Approved Truck Match Yet - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No approved truck match yet'**
  String get truckerLoadDetailNoApprovedTruckMatchYet;

  /// Trucker Load Detail Material Summary - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{material} - {weightTonnes}T - Advance {advancePercentage}%'**
  String truckerLoadDetailMaterialSummary(
    Object advancePercentage,
    Object material,
    Object weightTonnes,
  );

  /// Trucker Load Detail Super Load Guarantee - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Super Load - Payment Guarantee'**
  String get truckerLoadDetailSuperLoadGuarantee;

  /// Trucker Load Detail Route Price Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route and price summary'**
  String get truckerLoadDetailRoutePriceSummaryTitle;

  /// Trucker Load Detail Origin Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin: {origin}'**
  String truckerLoadDetailOriginLabel(Object origin);

  /// Trucker Load Detail Destination Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination: {destination}'**
  String truckerLoadDetailDestinationLabel(Object destination);

  /// Trucker Load Detail Pickup Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {pickupDate}'**
  String truckerLoadDetailPickupLabel(Object pickupDate);

  /// Trucker Load Detail Price Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Price: ₹{priceAmount} - {priceType}'**
  String truckerLoadDetailPriceLabel(Object priceAmount, Object priceType);

  /// Trucker Load Detail Distance Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String truckerLoadDetailDistanceLabel(Object distance);

  /// Trucker Load Detail Drive Time Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Estimated drive time: {minutes} min'**
  String truckerLoadDetailDriveTimeLabel(Object minutes);

  /// Trucker Load Detail Truck Requirement Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck requirement summary'**
  String get truckerLoadDetailTruckRequirementTitle;

  /// Trucker Load Detail Body Type Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Body type: {bodyType}'**
  String truckerLoadDetailBodyTypeLabel(Object bodyType);

  /// Trucker Load Detail Tyres Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {tyres}'**
  String truckerLoadDetailTyresLabel(Object tyres);

  /// Trucker Load Detail Trucks Needed Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucks needed: {booked}/{needed} booked'**
  String truckerLoadDetailTrucksNeededLabel(Object booked, Object needed);

  /// Trucker Load Detail Any Option - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get truckerLoadDetailAnyOption;

  /// Trucker Load Detail No Approved Truck Selected - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No approved truck selected'**
  String get truckerLoadDetailNoApprovedTruckSelected;

  /// Trucker Load Detail Selected Truck Matches - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Selected truck matches this load'**
  String get truckerLoadDetailSelectedTruckMatches;

  /// Trucker Load Detail Selected Truck May Not Match - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Selected truck may not match this load'**
  String get truckerLoadDetailSelectedTruckMayNotMatch;

  /// Trucker Load Detail Cargo Schedule Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cargo and schedule details'**
  String get truckerLoadDetailCargoScheduleTitle;

  /// Trucker Load Detail Material Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Material: {material}'**
  String truckerLoadDetailMaterialLabel(Object material);

  /// Trucker Load Detail Weight Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Weight: {weight} tonnes'**
  String truckerLoadDetailWeightLabel(Object weight);

  /// Trucker Load Detail Origin City Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Origin city: {city}'**
  String truckerLoadDetailOriginCityLabel(Object city);

  /// Trucker Load Detail Destination City Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Destination city: {city}'**
  String truckerLoadDetailDestinationCityLabel(Object city);

  /// Trucker Load Detail Trip Cost Estimate Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip cost estimate'**
  String get truckerLoadDetailTripCostEstimateTitle;

  /// Trucker Load Detail Trip Cost Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trip cost unavailable'**
  String get truckerLoadDetailTripCostUnavailableTitle;

  /// Trucker Load Detail Trip Cost Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Distance is unavailable for this load right now, so the trip cost estimate cannot be calculated yet.'**
  String get truckerLoadDetailTripCostUnavailableMessage;

  /// Trucker Load Detail Diesel Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Diesel: ₹{amount}'**
  String truckerLoadDetailDieselLabel(Object amount);

  /// Trucker Load Detail Tolls Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Tolls: ₹{amount}'**
  String truckerLoadDetailTollsLabel(Object amount);

  /// Trucker Load Detail Mileage Used Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Mileage used: {value} km/L'**
  String truckerLoadDetailMileageUsedLabel(Object value);

  /// Trucker Load Detail Diesel Price Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Diesel price: ₹{value}/L'**
  String truckerLoadDetailDieselPriceLabel(Object value);

  /// Trucker Load Detail Estimated Toll Plazas Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Estimated toll plazas: {count}'**
  String truckerLoadDetailEstimatedTollPlazasLabel(Object count);

  /// Trucker Load Detail Supplier Summary Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier summary'**
  String get truckerLoadDetailSupplierSummaryTitle;

  /// Trucker Load Detail Contact Owner Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Contact owner: {name}'**
  String truckerLoadDetailContactOwnerLabel(Object name);

  /// Trucker Load Detail Verified Supplier - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified supplier'**
  String get truckerLoadDetailVerifiedSupplier;

  /// Trucker Load Detail Supplier Profile - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supplier profile'**
  String get truckerLoadDetailSupplierProfile;

  /// Trucker Load Detail Next Step Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get truckerLoadDetailNextStepTitle;

  /// Trucker Load Detail Status Active - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get truckerLoadDetailStatusActive;

  /// Trucker Load Detail Status Assigned Partial - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Assigned partial'**
  String get truckerLoadDetailStatusAssignedPartial;

  /// Trucker Load Detail Status Unknown - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get truckerLoadDetailStatusUnknown;

  /// No description provided for @truckerLoadDetailBookingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking status: {status}'**
  String truckerLoadDetailBookingStatusLabel(Object status);

  /// Trucker Load Detail Booking Feedback Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking feedback'**
  String get truckerLoadDetailBookingFeedbackTitle;

  /// Trucker Load Detail Booking Blocked Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking is blocked'**
  String get truckerLoadDetailBookingBlockedTitle;

  /// Trucker Load Detail Message Supplier Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Message supplier'**
  String get truckerLoadDetailMessageSupplierAction;

  /// Trucker Load Detail Call Supplier Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Call supplier'**
  String get truckerLoadDetailCallSupplierAction;

  /// Trucker Load Detail Using Truck Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Using {truckNumber}'**
  String truckerLoadDetailUsingTruckLabel(Object truckNumber);

  /// Trucker Load Detail Selected Truck Summary - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This load will be booked with {truckNumber} - {bodyType} - {tyres} tyres.'**
  String truckerLoadDetailSelectedTruckSummary(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  );

  /// Trucker Load Detail Approved Truck Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approved truck for this request'**
  String get truckerLoadDetailApprovedTruckLabel;

  /// Trucker Load Detail Truck Option Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'{truckNumber} - {bodyType} - {tyres} tyres'**
  String truckerLoadDetailTruckOptionLabel(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  );

  /// Trucker Load Detail No Approved Trucks Available - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No approved trucks are available yet.'**
  String get truckerLoadDetailNoApprovedTrucksAvailable;

  /// Trucker Load Detail Add Truck First Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add a Truck First'**
  String get truckerLoadDetailAddTruckFirstAction;

  /// Trucker Load Detail Request Submitted Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get truckerLoadDetailRequestSubmittedAction;

  /// Trucker Load Detail Booked Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get truckerLoadDetailBookedAction;

  /// Trucker Load Detail Book This Load Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Book This Load'**
  String get truckerLoadDetailBookThisLoadAction;

  /// Trucker Load Detail Load Booked Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load booked! Waiting for supplier approval'**
  String get truckerLoadDetailLoadBookedSuccess;

  /// Trucker Load Detail Share Load Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Share load'**
  String get truckerLoadDetailShareLoadAction;

  /// Trucker Load Detail Share Load Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Share load'**
  String get truckerLoadDetailShareLoadTitle;

  /// Trucker Load Detail Share Load Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Share a safe summary-first load card without exposing direct phone numbers or private operational notes.'**
  String get truckerLoadDetailShareLoadMessage;

  /// Trucker Load Detail System Share Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'System share'**
  String get truckerLoadDetailSystemShareAction;

  /// Trucker Load Detail Share To Whats App Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Share to WhatsApp'**
  String get truckerLoadDetailShareToWhatsAppAction;

  /// Trucker Load Detail Whats App Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is unavailable on this device. Use system share instead.'**
  String get truckerLoadDetailWhatsAppUnavailableMessage;

  /// Trucker Load Detail Open In Google Maps Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get truckerLoadDetailOpenInGoogleMapsAction;

  /// Trucker Load Detail Report Spam Or Abuse Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Report spam or abuse'**
  String get truckerLoadDetailReportSpamOrAbuseAction;

  /// Trucker Load Detail Report Source Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trucker load - {routeLabel}'**
  String truckerLoadDetailReportSourceLabel(Object routeLabel);

  /// Trucker Load Detail Verification Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.'**
  String get truckerLoadDetailVerificationRequiredMessage;

  /// Trucker Load Detail Truck Approval Required Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add and approve at least one truck before booking this load or unlocking supplier chat.'**
  String get truckerLoadDetailTruckApprovalRequiredMessage;

  /// Trucker Load Detail Add Truck Dialog Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add a truck first'**
  String get truckerLoadDetailAddTruckDialogTitle;

  /// Trucker Load Detail Add Truck Dialog Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You need at least one approved truck before you can book this load. Open Fleet now to add or complete truck approval?'**
  String get truckerLoadDetailAddTruckDialogMessage;

  /// Trucker Load Detail Not Now Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get truckerLoadDetailNotNowAction;

  /// Trucker Load Detail Open Fleet Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open Fleet'**
  String get truckerLoadDetailOpenFleetAction;

  /// Trucker Load Detail Confirm Booking Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Confirm load booking'**
  String get truckerLoadDetailConfirmBookingTitle;

  /// Trucker Load Detail Confirm Booking Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Book {material} {routeLabel} with {truckNumber}?'**
  String truckerLoadDetailConfirmBookingMessage(
    Object material,
    Object routeLabel,
    Object truckNumber,
  );

  /// Trucker Load Detail Cancel Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get truckerLoadDetailCancelAction;

  /// Auth Tts Splash Welcome - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TranZfort. I will help you finish a quick setup before you continue.'**
  String get authTtsSplashWelcome;

  /// Auth Session Refresh Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not refresh your session right now. Please continue and try again if needed.'**
  String get authSessionRefreshFailureMessage;

  /// Auth Notification Permission Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Notification permission could not be enabled right now.'**
  String get authNotificationPermissionFailureMessage;

  /// Auth Tts Voice Guidance Enabled - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance is now enabled.'**
  String get authTtsVoiceGuidanceEnabled;

  /// Auth Config Incomplete Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Setup incomplete'**
  String get authConfigIncompleteTitle;

  /// Auth Config Incomplete Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Some app configuration is missing. Sign-in may not work until setup is completed.'**
  String get authConfigIncompleteMessage;

  /// Auth Tts Sign In Prompt - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to sign in to TranZfort.'**
  String get authTtsSignInPrompt;

  /// Auth Tts Onboarding Role Prompt - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Choose your role to continue onboarding.'**
  String get authTtsOnboardingRolePrompt;

  /// Post Load Validation Origin City Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select the origin city'**
  String get postLoadValidationOriginCityRequired;

  /// Post Load Validation Origin Location Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter the pickup location'**
  String get postLoadValidationOriginLocationRequired;

  /// Post Load Validation Destination City Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select the destination city'**
  String get postLoadValidationDestinationCityRequired;

  /// Post Load Validation Destination Location Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter the drop location'**
  String get postLoadValidationDestinationLocationRequired;

  /// Post Load Validation Material Required - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter the material name'**
  String get postLoadValidationMaterialRequired;

  /// Post Load Validation Weight Range - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 0 and 100 tonnes'**
  String get postLoadValidationWeightRange;

  /// Post Load Validation Trucks Needed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'At least one truck is required'**
  String get postLoadValidationTrucksNeeded;

  /// Post Load Validation Price Positive - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price greater than zero'**
  String get postLoadValidationPricePositive;

  /// Post Load Validation Price Type - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select a valid price type'**
  String get postLoadValidationPriceType;

  /// Post Load Validation Pickup Date Past - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Pickup date cannot be in the past'**
  String get postLoadValidationPickupDatePast;

  /// No description provided for @settingsRoleSentenceHi.
  ///
  /// In en, this message translates to:
  /// **'Current role: {roleLabel}.'**
  String settingsRoleSentenceHi(Object roleLabel);

  /// No description provided for @settingsRoleSentenceEn.
  ///
  /// In en, this message translates to:
  /// **'Current role: {roleLabel}.'**
  String settingsRoleSentenceEn(Object roleLabel);

  /// Push Issue Permission Request Failed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Permission request failed.'**
  String get pushIssuePermissionRequestFailed;

  /// Push Issue Local Init Failed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Local notification setup failed.'**
  String get pushIssueLocalInitFailed;

  /// Push Issue Display Failed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Notification display failed.'**
  String get pushIssueDisplayFailed;

  /// Push Issue Token Sync Failed - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Token sync failed.'**
  String get pushIssueTokenSyncFailed;

  /// Trucker Fleet Return To Verification Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Return to verification'**
  String get truckerFleetReturnToVerificationTitle;

  /// Trucker Fleet Return To Verification Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add or update your truck, then return to verification to continue.'**
  String get truckerFleetReturnToVerificationMessage;

  /// Trucker Fleet Back To Verification Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to verification'**
  String get truckerFleetBackToVerificationAction;

  /// Trucker Fleet Truck Saved Return Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck saved. Return to verification to continue.'**
  String get truckerFleetTruckSavedReturnMessage;

  /// Trucker Load Detail Profile Loading Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Checking your profile. Please wait...'**
  String get truckerLoadDetailProfileLoadingMessage;

  /// Supplier Load Detail Not Found Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load not found'**
  String get supplierLoadDetailNotFoundTitle;

  /// Supplier Load Detail Not Found Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This load detail is not available right now. Return to My Loads and try again.'**
  String get supplierLoadDetailNotFoundSubtitle;

  /// Supplier Load Detail Load Failure Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to load load detail'**
  String get supplierLoadDetailLoadFailureTitle;

  /// Supplier Load Detail Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not load this load detail. Please try again.'**
  String get supplierLoadDetailFailureMessage;

  /// Supplier Load Detail Screen Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load detail'**
  String get supplierLoadDetailScreenTitle;

  /// No description provided for @supplierLoadDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load ID: {loadId} - Pickup: {pickupDate}'**
  String supplierLoadDetailHeroSubtitle(Object loadId, Object pickupDate);

  /// Supplier Load Detail Linked Execution Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Linked execution data unavailable'**
  String get supplierLoadDetailLinkedExecutionUnavailableTitle;

  /// Supplier Load Support Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh bookings or trips right now. Please retry.'**
  String get supplierLoadSupportFailureMessage;

  /// Supplier Load Detail Status And Actions Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Status and actions'**
  String get supplierLoadDetailStatusAndActionsTitle;

  /// No description provided for @supplierLoadDetailCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current status: {status}'**
  String supplierLoadDetailCurrentStatus(Object status);

  /// Supplier Load Detail Actions Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Use these actions only after checking the latest status.'**
  String get supplierLoadDetailActionsSubtitle;

  /// Supplier Load Detail Action Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Action unavailable'**
  String get supplierLoadDetailActionUnavailableTitle;

  /// Supplier Load Action Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that load action right now. Please try again.'**
  String get supplierLoadActionFailureMessage;

  /// Supplier Load Detail Cancel Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cancel load'**
  String get supplierLoadDetailCancelAction;

  /// Supplier Load Detail Cancelled Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load cancelled successfully'**
  String get supplierLoadDetailCancelledSuccess;

  /// Supplier Load Cancel Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel this load right now. Please try again.'**
  String get supplierLoadCancelFailureMessage;

  /// Supplier Load Detail Close Filled Outside Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Close as filled outside app'**
  String get supplierLoadDetailCloseFilledOutsideAction;

  /// Supplier Load Detail Closed Filled Outside Success - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load marked as filled outside the app'**
  String get supplierLoadDetailClosedFilledOutsideSuccess;

  /// Supplier Load Close Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not close this load right now. Please try again.'**
  String get supplierLoadCloseFailureMessage;

  /// Supplier Load Detail Route And Schedule Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route and schedule'**
  String get supplierLoadDetailRouteAndScheduleTitle;

  /// Label showing origin city. Placeholder {value} is the city name.
  ///
  /// In en, this message translates to:
  /// **'Origin city: {value}'**
  String supplierLoadDetailOriginCity(Object value);

  /// No description provided for @supplierLoadDetailOriginPoint.
  ///
  /// In en, this message translates to:
  /// **'Origin point: {value}'**
  String supplierLoadDetailOriginPoint(Object value);

  /// Label showing destination city. Placeholder {value} is the city name.
  ///
  /// In en, this message translates to:
  /// **'Destination city: {value}'**
  String supplierLoadDetailDestinationCity(Object value);

  /// No description provided for @supplierLoadDetailDestinationPoint.
  ///
  /// In en, this message translates to:
  /// **'Destination point: {value}'**
  String supplierLoadDetailDestinationPoint(Object value);

  /// Label showing pickup date. Placeholder {value} is the formatted date.
  ///
  /// In en, this message translates to:
  /// **'Pickup date: {value}'**
  String supplierLoadDetailPickupDate(Object value);

  /// Label showing route distance. Placeholder {value} is the distance value.
  ///
  /// In en, this message translates to:
  /// **'Distance: {value}'**
  String supplierLoadDetailDistance(Object value);

  /// No description provided for @supplierLoadDetailDriveTime.
  ///
  /// In en, this message translates to:
  /// **'Drive time: {value}'**
  String supplierLoadDetailDriveTime(Object value);

  /// Supplier Load Detail Route Preview Unavailable Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route preview unavailable'**
  String get supplierLoadDetailRoutePreviewUnavailableTitle;

  /// Supplier Load Detail Route Preview Unavailable Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route preview details are unavailable for this load right now.'**
  String get supplierLoadDetailRoutePreviewUnavailableMessage;

  /// Supplier Load Detail Open In Google Maps - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get supplierLoadDetailOpenInGoogleMaps;

  /// Supplier Load Detail Cargo And Requirements Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Cargo and requirements'**
  String get supplierLoadDetailCargoAndRequirementsTitle;

  /// No description provided for @supplierLoadDetailMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material: {value}'**
  String supplierLoadDetailMaterial(Object value);

  /// No description provided for @supplierLoadDetailWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight: {value}'**
  String supplierLoadDetailWeight(Object value);

  /// Supplier Load Detail Any Value - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get supplierLoadDetailAnyValue;

  /// Label showing truck body type. Placeholder {value} is the body type name.
  ///
  /// In en, this message translates to:
  /// **'Body type: {value}'**
  String supplierLoadDetailBodyType(Object value);

  /// Label showing tyre count. Placeholder {value} is the number of tyres.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {value}'**
  String supplierLoadDetailTyres(Object value);

  /// Supplier Load Detail Booking And Trip Linkage Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking and trip linkage'**
  String get supplierLoadDetailBookingAndTripLinkageTitle;

  /// Supplier Load Detail Booking Linkage Empty Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No booking requests or linked trips are available on this load yet.'**
  String get supplierLoadDetailBookingLinkageEmptyDescription;

  /// Supplier Load Detail Booking Linkage Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'See booking requests and linked trips together.'**
  String get supplierLoadDetailBookingLinkageDescription;

  /// Supplier Load Detail No Booking Requests Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No booking requests yet'**
  String get supplierLoadDetailNoBookingRequestsTitle;

  /// Supplier Load Detail No Booking Requests Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking requests will appear here once truckers respond to this load.'**
  String get supplierLoadDetailNoBookingRequestsSubtitle;

  /// Supplier Load Detail Linked Trips Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Linked trips'**
  String get supplierLoadDetailLinkedTripsTitle;

  /// Supplier Load Detail No Linked Trips Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No linked trips yet'**
  String get supplierLoadDetailNoLinkedTripsTitle;

  /// Supplier Load Detail No Linked Trips Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Trips will appear here after you approve a booking.'**
  String get supplierLoadDetailNoLinkedTripsSubtitle;

  /// Supplier Load Detail Activity Timeline Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Activity timeline'**
  String get supplierLoadDetailActivityTimelineTitle;

  /// Supplier Load Detail Timeline Created Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load created'**
  String get supplierLoadDetailTimelineCreatedTitle;

  /// Supplier Load Detail Timeline Created Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This load was created.'**
  String get supplierLoadDetailTimelineCreatedDescription;

  /// Supplier Load Detail Timeline Published Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Load published'**
  String get supplierLoadDetailTimelinePublishedTitle;

  /// Supplier Load Detail Timeline Published Description - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'This load is published and visible to truckers.'**
  String get supplierLoadDetailTimelinePublishedDescription;

  /// Supplier Load Detail Timeline Updated Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get supplierLoadDetailTimelineUpdatedTitle;

  /// No description provided for @supplierLoadDetailTimelineUpdatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Current status: {status}.'**
  String supplierLoadDetailTimelineUpdatedDescription(Object status);

  /// Supplier Booking Verified Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get supplierBookingVerifiedLabel;

  /// Shows trucker rating. Placeholder {rating} is the numeric rating value.
  ///
  /// In en, this message translates to:
  /// **'Rating: {rating}'**
  String supplierBookingRatingLabel(Object rating);

  /// Shows tyre count on truck. Placeholder {tyres} is the number of tyres.
  ///
  /// In en, this message translates to:
  /// **'{tyres} tyres'**
  String supplierBookingTyres(Object tyres);

  /// No description provided for @supplierBookingSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'{truckLabel} - Submitted {submittedAt}'**
  String supplierBookingSubmittedAt(Object truckLabel, Object submittedAt);

  /// Shows when booking decision was made. Placeholder {decidedAt} is the timestamp.
  ///
  /// In en, this message translates to:
  /// **'Decision recorded {decidedAt}'**
  String supplierBookingDecisionRecorded(Object decidedAt);

  /// Subtitle for linked trip showing material, trucker and truck info. Placeholders: {material}, {truckerId}, {truckId}.
  ///
  /// In en, this message translates to:
  /// **'{material} - Trucker {truckerId} - Truck {truckId}'**
  String supplierLinkedTripSubtitle(
    Object material,
    Object truckerId,
    Object truckId,
  );

  /// Supplier Booking Approved Success Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking approved successfully'**
  String get supplierBookingApprovedSuccessMessage;

  /// Supplier Load Approve Booking Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not approve this booking right now. Please try again.'**
  String get supplierLoadApproveBookingFailureMessage;

  /// Supplier Booking Rejected Success Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected successfully'**
  String get supplierBookingRejectedSuccessMessage;

  /// Supplier Load Reject Booking Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not reject this booking right now. Please try again.'**
  String get supplierLoadRejectBookingFailureMessage;

  /// Supplier Booking Approve Dialog Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Approve booking'**
  String get supplierBookingApproveDialogTitle;

  /// No description provided for @supplierBookingApproveDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Approve booking for {material} from {origin} to {destination}?'**
  String supplierBookingApproveDialogMessage(
    Object material,
    Object origin,
    Object destination,
  );

  /// Supplier Booking Reject Dialog Title - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reject booking'**
  String get supplierBookingRejectDialogTitle;

  /// Supplier Booking Reject Dialog Subtitle - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add a short reason before rejecting this booking.'**
  String get supplierBookingRejectDialogSubtitle;

  /// Supplier Booking Reject Reason Label - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get supplierBookingRejectReasonLabel;

  /// Supplier Booking Reject Reason Hint - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Example: vehicle mismatch or route timing issue'**
  String get supplierBookingRejectReasonHint;

  /// Verification Field Company Name - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get verificationFieldCompanyName;

  /// Verification Field Aadhaar Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get verificationFieldAadhaarNumber;

  /// Verification Field Pan Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'PAN number'**
  String get verificationFieldPanNumber;

  /// Verification Field Business Licence Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Business licence number'**
  String get verificationFieldBusinessLicenceNumber;

  /// Verification Field Gst Number - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'GST number'**
  String get verificationFieldGstNumber;

  /// Verification Field Gst Optional - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get verificationFieldGstOptional;

  /// Verification Save Packet Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get verificationSavePacketAction;

  /// Verification Save Success Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification details saved'**
  String get verificationSaveSuccessMessage;

  /// Verification Save Failure Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Could not save verification details'**
  String get verificationSaveFailureMessage;

  /// Verification Locked Verified Guidance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification is already approved, so these fields are locked.'**
  String get verificationLockedVerifiedGuidance;

  /// Verification Locked Pending Guidance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification is under review, so these fields are locked until a decision is made.'**
  String get verificationLockedPendingGuidance;

  /// Verification Unlocked Supplier Guidance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your business and identity details, then upload the required documents.'**
  String get verificationUnlockedSupplierGuidance;

  /// Verification Unlocked Trucker Guidance - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your identity details and keep at least one truck ready for verification.'**
  String get verificationUnlockedTruckerGuidance;

  /// Verification Blocked Already Complete - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Verification is already complete.'**
  String get verificationBlockedAlreadyComplete;

  /// Verification Blocked Under Review - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Your verification is already under review.'**
  String get verificationBlockedUnderReview;

  /// Verification Blocked Missing Identity - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add your Aadhaar and PAN numbers first.'**
  String get verificationBlockedMissingIdentity;

  /// Verification Blocked Missing Company Name - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your company name first.'**
  String get verificationBlockedMissingCompanyName;

  /// Verification Blocked Missing Business Numbers - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Enter your business licence details first.'**
  String get verificationBlockedMissingBusinessNumbers;

  /// Error message when required document is missing. Placeholder {documentType} is the document type name.
  ///
  /// In en, this message translates to:
  /// **'Upload {documentType} to continue.'**
  String verificationBlockedMissingDocument(Object documentType);

  /// Verification Blocked Missing Location - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add your verification location first.'**
  String get verificationBlockedMissingLocation;

  /// Verification Blocked Missing Truck - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Add at least one truck before submitting verification.'**
  String get verificationBlockedMissingTruck;

  /// Shows count of verification-ready trucks. Placeholder {count} is the truck count.
  ///
  /// In en, this message translates to:
  /// **'Verification-ready trucks: {count}'**
  String verificationReadyTruckCount(Object count);

  /// App Bar Language Toggle Tooltip - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get appBarLanguageToggleTooltip;

  /// Connectivity Offline Banner - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Features may be limited.'**
  String get connectivityOfflineBanner;

  /// Connectivity Offline Actions Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Actions that need network access should stay disabled.'**
  String get connectivityOfflineActionsMessage;

  /// Locale Select Supported Language - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Select a supported language'**
  String get localeSelectSupportedLanguage;

  /// Locale Field Supported Languages - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Supported languages are English and Hindi'**
  String get localeFieldSupportedLanguages;

  /// Onboarding Gate Timeout Message - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Loading is taking longer than expected.'**
  String get onboardingGateTimeoutMessage;

  /// Onboarding Gate Retry Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onboardingGateRetryAction;

  /// Onboarding Gate Back To Sign In Action - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get onboardingGateBackToSignInAction;

  /// Success message after sending password reset. Placeholder {email} is the recipient email.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}. Check your inbox.'**
  String authPasswordResetSentSuccess(Object email);

  /// Auth Password Reset Sent Failure - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Unable to send reset link. Please try again.'**
  String get authPasswordResetSentFailure;

  /// Chat Preview Voice - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get chatPreviewVoice;

  /// Chat Preview Location - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Location shared'**
  String get chatPreviewLocation;

  /// Chat Preview Document - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Document shared'**
  String get chatPreviewDocument;

  /// Chat Preview Map Card - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Route card shared'**
  String get chatPreviewMapCard;

  /// Chat Preview Truck Card - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'Truck details shared'**
  String get chatPreviewTruckCard;

  /// Chat Preview System - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get chatPreviewSystem;

  /// Chat Preview Empty - User-facing text for the app interface.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatPreviewEmpty;

  /// Report source label for supplier load. Placeholder {routeLabel} is the route description.
  ///
  /// In en, this message translates to:
  /// **'Supplier load - {routeLabel}'**
  String reportSourceSupplierLoad(Object routeLabel);
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
