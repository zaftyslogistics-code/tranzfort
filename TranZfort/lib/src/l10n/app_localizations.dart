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

  /// No description provided for @authGoogleFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not continue with Google right now. Retry shortly or use email sign-in instead.'**
  String get authGoogleFailureMessage;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TranZfort'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Google or email sign-in to continue into your supplier or trucker workspace.'**
  String get authWelcomeSubtitle;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get authEmailHint;

  /// No description provided for @authForgotPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordAction;

  /// No description provided for @authConfigIncompleteSignInMessage.
  ///
  /// In en, this message translates to:
  /// **'Supabase is not configured in this build, so sign-in and live account data will remain unavailable until the environment is fixed.'**
  String get authConfigIncompleteSignInMessage;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authOrWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Or continue with email'**
  String get authOrWithEmail;

  /// No description provided for @authPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Email and password'**
  String get authPasswordTitle;

  /// No description provided for @authPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your email and password, or create a new TranZfort account to continue.'**
  String get authPasswordSubtitle;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authPasswordConfirmLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 8 characters'**
  String get authPasswordHint;

  /// No description provided for @authPasswordModeSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authPasswordModeSignIn;

  /// No description provided for @commonCreateAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get commonCreateAccountAction;

  /// No description provided for @authPasswordSwitchToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authPasswordSwitchToSignIn;

  /// No description provided for @authPasswordSwitchToSignUp.
  ///
  /// In en, this message translates to:
  /// **'New to TranZfort? Create account'**
  String get authPasswordSwitchToSignUp;

  /// No description provided for @authPasswordSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get authPasswordSignInAction;

  /// No description provided for @authPasswordInvalidEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authPasswordInvalidEmailMessage;

  /// No description provided for @authPasswordTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a password with at least 8 characters.'**
  String get authPasswordTooShortMessage;

  /// No description provided for @authPasswordConfirmMismatchMessage.
  ///
  /// In en, this message translates to:
  /// **'The password confirmation does not match.'**
  String get authPasswordConfirmMismatchMessage;

  /// No description provided for @authPasswordSignInFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you in with email and password right now. Retry shortly or use another sign-in method.'**
  String get authPasswordSignInFailureMessage;

  /// No description provided for @authPasswordSignUpFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not create your account right now. Retry shortly with the same details.'**
  String get authPasswordSignUpFailureMessage;

  /// No description provided for @authPasswordCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authPasswordCheckEmailTitle;

  /// Instruction for user to check their email for verification link. Placeholder {email} is the user's email address.
  ///
  /// In en, this message translates to:
  /// **'We sent a verification link to {email}. Open that email, finish verification, and then return here to sign in.'**
  String authPasswordCheckEmailSubtitle(Object email);

  /// No description provided for @authPasswordResendVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get authPasswordResendVerificationAction;

  /// Success message after resending verification email. Placeholder {email} is the recipient's email address.
  ///
  /// In en, this message translates to:
  /// **'We sent a fresh verification email to {email}. Open it, finish verification, and then sign in.'**
  String authPasswordResendVerificationSuccessMessage(Object email);

  /// No description provided for @authPasswordResendVerificationFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not resend the verification email right now. Retry shortly or use a different email.'**
  String get authPasswordResendVerificationFailureMessage;

  /// No description provided for @commonBackToSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get commonBackToSignInAction;

  /// No description provided for @authPasswordUseDifferentEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get authPasswordUseDifferentEmailAction;

  /// No description provided for @authErrorEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get authErrorEmailRequired;

  /// No description provided for @authErrorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authErrorEmailInvalid;

  /// No description provided for @authErrorPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get authErrorPasswordRequired;

  /// No description provided for @authErrorPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get authErrorPasswordTooShort;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already registered'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get authErrorWeakPassword;

  /// No description provided for @authRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a valid role to continue'**
  String get authRoleRequired;

  /// No description provided for @authNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get authNameTooShort;

  /// No description provided for @authMobileRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get authMobileRequired;

  /// No description provided for @authLanguageUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Select a supported language'**
  String get authLanguageUnsupported;

  /// No description provided for @authUnexpectedResponse.
  ///
  /// In en, this message translates to:
  /// **'Unexpected response format from account deletion request'**
  String get authUnexpectedResponse;

  /// No description provided for @authGoogleNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in is not configured. Set GOOGLE_WEB_CLIENT_ID in the app environment and retry.'**
  String get authGoogleNotConfigured;

  /// No description provided for @authGoogleSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign in was cancelled. Please try again.'**
  String get authGoogleSignInCancelled;

  /// No description provided for @authGoogleTokenFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch Google sign-in token. Please try again.'**
  String get authGoogleTokenFetchFailed;

  /// No description provided for @onboardingDiscardRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard role selection?'**
  String get onboardingDiscardRoleTitle;

  /// No description provided for @onboardingDiscardRoleMessage.
  ///
  /// In en, this message translates to:
  /// **'Your selected role will be lost'**
  String get onboardingDiscardRoleMessage;

  /// No description provided for @onboardingDiscardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get onboardingDiscardChangesTitle;

  /// No description provided for @onboardingDiscardChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost'**
  String get onboardingDiscardChangesMessage;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied'**
  String get locationPermissionDenied;

  /// No description provided for @locationEnableGps.
  ///
  /// In en, this message translates to:
  /// **'Enable GPS'**
  String get locationEnableGps;

  /// No description provided for @locationEnableServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services (GPS) to capture your current location.'**
  String get locationEnableServicesMessage;

  /// No description provided for @locationGrantPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please grant location permission to capture your current location.'**
  String get locationGrantPermissionMessage;

  /// No description provided for @locationOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get locationOpenSettings;

  /// No description provided for @locationPermissionDeniedForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied. Please enable it in app settings.'**
  String get locationPermissionDeniedForeverMessage;

  /// No description provided for @searchYourLocation.
  ///
  /// In en, this message translates to:
  /// **'Search your location'**
  String get searchYourLocation;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// No description provided for @clearLocation.
  ///
  /// In en, this message translates to:
  /// **'Clear location'**
  String get clearLocation;

  /// No description provided for @routePreviewInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load route preview'**
  String get routePreviewInvalidError;

  /// No description provided for @publicProfileLoadErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get publicProfileLoadErrorTitle;

  /// No description provided for @publicProfileNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get publicProfileNotFoundTitle;

  /// No description provided for @supplierPostLoadSpecifyMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Specify Material'**
  String get supplierPostLoadSpecifyMaterialLabel;

  /// No description provided for @supplierPostLoadSpecifyMaterialHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Fruits, Iron Ore, Bricks'**
  String get supplierPostLoadSpecifyMaterialHint;

  /// No description provided for @supplierPostLoadMaterialCoal.
  ///
  /// In en, this message translates to:
  /// **'Coal'**
  String get supplierPostLoadMaterialCoal;

  /// No description provided for @supplierPostLoadMaterialSteel.
  ///
  /// In en, this message translates to:
  /// **'Steel'**
  String get supplierPostLoadMaterialSteel;

  /// No description provided for @supplierPostLoadMaterialCement.
  ///
  /// In en, this message translates to:
  /// **'Cement'**
  String get supplierPostLoadMaterialCement;

  /// No description provided for @supplierPostLoadMaterialGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get supplierPostLoadMaterialGrains;

  /// No description provided for @supplierPostLoadMaterialFertilizer.
  ///
  /// In en, this message translates to:
  /// **'Fertilizer'**
  String get supplierPostLoadMaterialFertilizer;

  /// No description provided for @supplierPostLoadMaterialMachinery.
  ///
  /// In en, this message translates to:
  /// **'Machinery'**
  String get supplierPostLoadMaterialMachinery;

  /// No description provided for @supplierPostLoadMaterialOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supplierPostLoadMaterialOther;

  /// No description provided for @supplierPostLoadBodyTypeAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get supplierPostLoadBodyTypeAny;

  /// No description provided for @supplierPostLoadBodyTypeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supplierPostLoadBodyTypeOpen;

  /// No description provided for @supplierPostLoadBodyTypeContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get supplierPostLoadBodyTypeContainer;

  /// No description provided for @supplierPostLoadBodyTypeTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get supplierPostLoadBodyTypeTrailer;

  /// No description provided for @supplierPostLoadBodyTypeTanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get supplierPostLoadBodyTypeTanker;

  /// No description provided for @supplierPostLoadBodyTypeRefrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated'**
  String get supplierPostLoadBodyTypeRefrigerated;

  /// No description provided for @postLoadValidationCustomMaterialRequired.
  ///
  /// In en, this message translates to:
  /// **'Please specify the material'**
  String get postLoadValidationCustomMaterialRequired;

  /// No description provided for @supplierLoadSubmissionAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Load submission is already in progress'**
  String get supplierLoadSubmissionAlreadyInProgress;

  /// No description provided for @truckerFleetValidationTruckNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid truck number'**
  String get truckerFleetValidationTruckNumber;

  /// No description provided for @truckerFleetValidationTyreCount.
  ///
  /// In en, this message translates to:
  /// **'Select a valid tyre count'**
  String get truckerFleetValidationTyreCount;

  /// No description provided for @truckerFleetValidationCapacityTonnes.
  ///
  /// In en, this message translates to:
  /// **'Capacity must be between 0 and 100 tonnes'**
  String get truckerFleetValidationCapacityTonnes;

  /// No description provided for @truckerFleetValidationRcDocument.
  ///
  /// In en, this message translates to:
  /// **'RC document is required'**
  String get truckerFleetValidationRcDocument;

  /// No description provided for @truckerFleetErrorTruckNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected truck was not found'**
  String get truckerFleetErrorTruckNotFound;

  /// No description provided for @truckerFleetErrorSaveAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Truck save is already in progress'**
  String get truckerFleetErrorSaveAlreadyInProgress;

  /// No description provided for @truckerFleetErrorValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Please correct the highlighted truck details'**
  String get truckerFleetErrorValidationFailed;

  /// No description provided for @truckerFleetBodyTypeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get truckerFleetBodyTypeOpen;

  /// No description provided for @truckerFleetBodyTypeContainer.
  ///
  /// In en, this message translates to:
  /// **'Container'**
  String get truckerFleetBodyTypeContainer;

  /// No description provided for @truckerFleetBodyTypeTrailer.
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get truckerFleetBodyTypeTrailer;

  /// No description provided for @truckerFleetBodyTypeTanker.
  ///
  /// In en, this message translates to:
  /// **'Tanker'**
  String get truckerFleetBodyTypeTanker;

  /// No description provided for @truckerFleetBodyTypeRefrigerated.
  ///
  /// In en, this message translates to:
  /// **'Refrigerated'**
  String get truckerFleetBodyTypeRefrigerated;

  /// No description provided for @chatTonnesCompact.
  ///
  /// In en, this message translates to:
  /// **'{value}T'**
  String chatTonnesCompact(Object value);

  /// No description provided for @verificationCompleteAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields'**
  String get verificationCompleteAllFields;

  /// No description provided for @verificationLocationSourceManualCityEntry.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get verificationLocationSourceManualCityEntry;

  /// No description provided for @verificationLocationSourceGoogleGeocode.
  ///
  /// In en, this message translates to:
  /// **'Captured via GPS'**
  String get verificationLocationSourceGoogleGeocode;

  /// No description provided for @verificationLocationSourceOfflineNearestCity.
  ///
  /// In en, this message translates to:
  /// **'Offline location'**
  String get verificationLocationSourceOfflineNearestCity;

  /// No description provided for @supportCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get supportCategoryGeneral;

  /// No description provided for @supportCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supportCategoryAccount;

  /// No description provided for @supportCategoryLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get supportCategoryLoad;

  /// No description provided for @supportCategoryTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get supportCategoryTrip;

  /// No description provided for @supportCategoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get supportCategoryPayment;

  /// No description provided for @supportCategoryTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get supportCategoryTechnical;

  /// No description provided for @supportCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportCategoryOther;

  /// No description provided for @reportIssueCategorySpamOrScam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportIssueCategorySpamOrScam;

  /// No description provided for @reportIssueCategoryFakePayoutProof.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof'**
  String get reportIssueCategoryFakePayoutProof;

  /// No description provided for @reportIssueCategoryNonPayment.
  ///
  /// In en, this message translates to:
  /// **'Non-payment'**
  String get reportIssueCategoryNonPayment;

  /// No description provided for @reportIssueCategoryAbusiveBehavior.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior'**
  String get reportIssueCategoryAbusiveBehavior;

  /// No description provided for @reportIssueContextSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current conversation or trip context'**
  String get reportIssueContextSourceLabel;

  /// No description provided for @onboardingSelectRoleError.
  ///
  /// In en, this message translates to:
  /// **'Select whether you are joining as a supplier or trucker.'**
  String get onboardingSelectRoleError;

  /// No description provided for @onboardingRoleWorkspaceFailure.
  ///
  /// In en, this message translates to:
  /// **'We could not prepare your role workspace right now. Retry shortly after selecting your role again.'**
  String get onboardingRoleWorkspaceFailure;

  /// No description provided for @onboardingRoleSaveFailure.
  ///
  /// In en, this message translates to:
  /// **'We could not save your role right now. Retry shortly.'**
  String get onboardingRoleSaveFailure;

  /// No description provided for @onboardingChooseRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose role'**
  String get onboardingChooseRoleTitle;

  /// No description provided for @onboardingRoleQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which role fits your work?'**
  String get onboardingRoleQuestion;

  /// No description provided for @onboardingRoleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your role decides the tools, dashboard, and workflows TranZfort will prepare for you.'**
  String get onboardingRoleSubtitle;

  /// No description provided for @onboardingSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get onboardingSupplierTitle;

  /// No description provided for @onboardingSupplierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post loads, review bookings, manage trips, and track delivery follow-through.'**
  String get onboardingSupplierSubtitle;

  /// No description provided for @onboardingTruckerTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucker'**
  String get onboardingTruckerTitle;

  /// No description provided for @onboardingTruckerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find loads, manage fleet readiness, and execute active trips from one place.'**
  String get onboardingTruckerSubtitle;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingProfileSaveFailure.
  ///
  /// In en, this message translates to:
  /// **'We could not save your profile right now. Review the details and retry shortly.'**
  String get onboardingProfileSaveFailure;

  /// No description provided for @onboardingCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get onboardingCompleteProfileTitle;

  /// No description provided for @onboardingCompleteProfileHeading.
  ///
  /// In en, this message translates to:
  /// **'Finish your basic profile'**
  String get onboardingCompleteProfileHeading;

  /// No description provided for @onboardingCompleteProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the core contact details that will follow you through verification and daily operations.'**
  String get onboardingCompleteProfileSubtitle;

  /// No description provided for @onboardingFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get onboardingFullNameLabel;

  /// No description provided for @onboardingFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get onboardingFullNameHint;

  /// No description provided for @onboardingMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get onboardingMobileLabel;

  /// No description provided for @onboardingTermsAcceptance.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you confirm that your basic profile details are accurate and that you agree to the platform terms.'**
  String get onboardingTermsAcceptance;

  /// No description provided for @onboardingSaveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get onboardingSaveAndContinue;

  /// No description provided for @commonRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetryAction;

  /// No description provided for @shellPressBackAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get shellPressBackAgainToExit;

  /// No description provided for @commonNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get commonNotificationsLabel;

  /// No description provided for @supplierMyLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'My loads'**
  String get supplierMyLoadsTitle;

  /// No description provided for @supplierMyLoadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Monitor active supplier loads, booking demand, and completed load history from one place.'**
  String get supplierMyLoadsSubtitle;

  /// No description provided for @commonActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get commonActiveLabel;

  /// No description provided for @commonCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get commonCompletedLabel;

  /// No description provided for @supplierMyLoadsLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your supplier loads'**
  String get supplierMyLoadsLoadFailureTitle;

  /// No description provided for @supplierMyLoadsFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your supplier loads right now. Retry shortly to refresh the latest load list.'**
  String get supplierMyLoadsFailureMessage;

  /// No description provided for @supplierMyLoadsEmptyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active loads yet'**
  String get supplierMyLoadsEmptyActiveTitle;

  /// No description provided for @supplierMyLoadsEmptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed loads yet'**
  String get supplierMyLoadsEmptyCompletedTitle;

  /// No description provided for @supplierMyLoadsEmptyActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post your first load to start receiving booking requests and execution updates here.'**
  String get supplierMyLoadsEmptyActiveSubtitle;

  /// No description provided for @supplierMyLoadsEmptyCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed, cancelled, expired, and externally filled loads will appear here once active work is closed out.'**
  String get supplierMyLoadsEmptyCompletedSubtitle;

  /// No description provided for @supplierMyLoadsOpenActiveLoads.
  ///
  /// In en, this message translates to:
  /// **'Open active loads'**
  String get supplierMyLoadsOpenActiveLoads;

  /// No description provided for @supplierMyLoadsMoreUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load more supplier loads'**
  String get supplierMyLoadsMoreUnavailableTitle;

  /// No description provided for @supplierMyLoadsPaginationFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load more supplier loads right now. Retry shortly to refresh the latest load history.'**
  String get supplierMyLoadsPaginationFailureMessage;

  /// No description provided for @supplierMyLoadsLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more loads...'**
  String get supplierMyLoadsLoadingMore;

  /// No description provided for @supplierMyLoadsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more loads'**
  String get supplierMyLoadsLoadMore;

  /// No description provided for @supplierLoadCardPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup {value}'**
  String supplierLoadCardPickupDate(Object value);

  /// No description provided for @supplierLoadCardTrucks.
  ///
  /// In en, this message translates to:
  /// **'{booked}/{needed} trucks booked'**
  String supplierLoadCardTrucks(Object booked, Object needed);

  /// No description provided for @supplierLoadCardTrackLoad.
  ///
  /// In en, this message translates to:
  /// **'Track load'**
  String get supplierLoadCardTrackLoad;

  /// No description provided for @supplierLoadCardViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View history'**
  String get supplierLoadCardViewHistory;

  /// No description provided for @commonViewDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get commonViewDetailsAction;

  /// No description provided for @supplierRecentLoadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent loads'**
  String get supplierRecentLoadsTitle;

  /// Welcome message on supplier dashboard. Placeholder {name} is the user's display name.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String supplierDashboardWelcomeBack(Object name);

  /// No description provided for @commonDashboardOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard overview'**
  String get commonDashboardOverviewTitle;

  /// No description provided for @supplierDashboardSuperLoadReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Super Load readiness'**
  String get supplierDashboardSuperLoadReadinessTitle;

  /// No description provided for @commonQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get commonQuickActionsTitle;

  /// No description provided for @commonChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get commonChatLabel;

  /// No description provided for @commonPostLoadAction.
  ///
  /// In en, this message translates to:
  /// **'Post Load'**
  String get commonPostLoadAction;

  /// No description provided for @supplierDashboardStatsActiveLoadsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active loads'**
  String get supplierDashboardStatsActiveLoadsLabel;

  /// No description provided for @supplierDashboardStatsPendingBookingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending bookings'**
  String get supplierDashboardStatsPendingBookingsLabel;

  /// No description provided for @supplierDashboardStatsInTransitTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trips in transit'**
  String get supplierDashboardStatsInTransitTripsLabel;

  /// No description provided for @supplierDashboardStatsCompletedTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed trips'**
  String get supplierDashboardStatsCompletedTripsLabel;

  /// No description provided for @commonOpenMyLoadsAction.
  ///
  /// In en, this message translates to:
  /// **'Open my loads'**
  String get commonOpenMyLoadsAction;

  /// No description provided for @supplierDashboardLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your supplier dashboard'**
  String get supplierDashboardLoadFailureTitle;

  /// No description provided for @supplierDashboardLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your supplier dashboard right now. Retry shortly to refresh the latest overview metrics.'**
  String get supplierDashboardLoadFailureMessage;

  /// No description provided for @supplierDashboardAccountStateUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier account state unavailable'**
  String get supplierDashboardAccountStateUnavailableTitle;

  /// No description provided for @supplierDashboardAccountStateUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your current supplier account state right now. Retry shortly to restore the latest verification and company details.'**
  String get supplierDashboardAccountStateUnavailableMessage;

  /// No description provided for @supplierDashboardRecentLoadsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent loads unavailable'**
  String get supplierDashboardRecentLoadsUnavailableTitle;

  /// No description provided for @supplierDashboardRecentLoadsUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your recent supplier loads right now. Retry shortly to refresh the latest load list.'**
  String get supplierDashboardRecentLoadsUnavailableMessage;

  /// No description provided for @supplierDashboardNoLoadsPostedTitle.
  ///
  /// In en, this message translates to:
  /// **'No loads posted yet'**
  String get supplierDashboardNoLoadsPostedTitle;

  /// No description provided for @supplierDashboardNoLoadsPostedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post your first supplier load to start receiving booking requests and linked trip activity.'**
  String get supplierDashboardNoLoadsPostedSubtitle;

  /// No description provided for @shellTabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get shellTabHome;

  /// No description provided for @shellTitleSupplierDashboard.
  ///
  /// In en, this message translates to:
  /// **'Supplier dashboard'**
  String get shellTitleSupplierDashboard;

  /// No description provided for @shellTabLoads.
  ///
  /// In en, this message translates to:
  /// **'Loads'**
  String get shellTabLoads;

  /// No description provided for @shellTitleMyLoads.
  ///
  /// In en, this message translates to:
  /// **'My Loads'**
  String get shellTitleMyLoads;

  /// No description provided for @commonTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get commonTripsLabel;

  /// No description provided for @commonDashboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get commonDashboardLabel;

  /// No description provided for @shellTabFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get shellTabFind;

  /// No description provided for @shellTitleFindLoads.
  ///
  /// In en, this message translates to:
  /// **'Find Loads'**
  String get shellTitleFindLoads;

  /// No description provided for @shellDrawerSupplierWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Supplier workspace'**
  String get shellDrawerSupplierWorkspace;

  /// No description provided for @shellDrawerTruckerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Trucker workspace'**
  String get shellDrawerTruckerWorkspace;

  /// No description provided for @commonFleetLabel.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get commonFleetLabel;

  /// No description provided for @commonSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get commonSupportLabel;

  /// No description provided for @commonProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get commonProfileLabel;

  /// No description provided for @commonSignOutAction.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get commonSignOutAction;

  /// No description provided for @shellSignOutFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you out right now. Retry shortly.'**
  String get shellSignOutFailureMessage;

  /// No description provided for @shellMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get shellMessagesTitle;

  /// No description provided for @shellMessagesSupplierSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track load-linked conversations with truckers and reply quickly from one place.'**
  String get shellMessagesSupplierSubtitle;

  /// No description provided for @shellMessagesTruckerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on top of supplier updates, route context, and booking follow-through in one inbox.'**
  String get shellMessagesTruckerSubtitle;

  /// No description provided for @shellMessagesSupplierGroupedInbox.
  ///
  /// In en, this message translates to:
  /// **'Grouped inbox'**
  String get shellMessagesSupplierGroupedInbox;

  /// No description provided for @shellMessagesTruckerFlatInbox.
  ///
  /// In en, this message translates to:
  /// **'Flat inbox'**
  String get shellMessagesTruckerFlatInbox;

  /// Shows count of unread conversation threads. Placeholder {count} is the number of unread threads.
  ///
  /// In en, this message translates to:
  /// **'{count} unread threads'**
  String shellMessagesUnreadThreads(int count);

  /// No description provided for @shellMessagesLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get shellMessagesLoadFailureTitle;

  /// No description provided for @shellMessagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get shellMessagesEmptyTitle;

  /// No description provided for @shellMessagesSupplierEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Load-linked trucker conversations will appear here after the first message arrives.'**
  String get shellMessagesSupplierEmptySubtitle;

  /// No description provided for @shellMessagesTruckerEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a chat by booking a load and your supplier conversations will show here.'**
  String get shellMessagesTruckerEmptySubtitle;

  /// No description provided for @shellMessagesActiveConversations.
  ///
  /// In en, this message translates to:
  /// **'{count} active conversations - {preview}'**
  String shellMessagesActiveConversations(int count, Object preview);

  /// No description provided for @shellMessagesUnreadStatus.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get shellMessagesUnreadStatus;

  /// No description provided for @shellMessagesReadStatus.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get shellMessagesReadStatus;

  /// No description provided for @shellMessagesHideTruckerConversations.
  ///
  /// In en, this message translates to:
  /// **'Hide trucker conversations'**
  String get shellMessagesHideTruckerConversations;

  /// No description provided for @shellMessagesLatestBy.
  ///
  /// In en, this message translates to:
  /// **'Latest by {name} - {timestamp}'**
  String shellMessagesLatestBy(Object name, Object timestamp);

  /// No description provided for @truckerChatSupplierAction.
  ///
  /// In en, this message translates to:
  /// **'Chat with supplier'**
  String get truckerChatSupplierAction;

  /// No description provided for @truckerLoadChatStartFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not start this supplier chat right now. Retry shortly from the load detail.'**
  String get truckerLoadChatStartFailureMessage;

  /// No description provided for @truckerTripChatStartFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not start this supplier chat right now. Retry shortly from the trip detail.'**
  String get truckerTripChatStartFailureMessage;

  /// Message shown when chat is unavailable. Placeholder {reason} explains why chat is locked.
  ///
  /// In en, this message translates to:
  /// **'Chat unavailable: {reason}'**
  String truckerChatLockedLabel(Object reason);

  /// No description provided for @chatTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get chatTitleFallback;

  /// No description provided for @commonCallAction.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get commonCallAction;

  /// Label for reporting chat source. Placeholder {source} is the chat context source.
  ///
  /// In en, this message translates to:
  /// **'Chat - {source}'**
  String chatReportSourceLabel(Object source);

  /// No description provided for @chatMenuMarkConversationRead.
  ///
  /// In en, this message translates to:
  /// **'Mark conversation read'**
  String get chatMenuMarkConversationRead;

  /// No description provided for @chatMenuRefreshThread.
  ///
  /// In en, this message translates to:
  /// **'Refresh thread'**
  String get chatMenuRefreshThread;

  /// No description provided for @commonReportSpamOrAbuseAction.
  ///
  /// In en, this message translates to:
  /// **'Report spam or abuse'**
  String get commonReportSpamOrAbuseAction;

  /// No description provided for @chatConversationUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation unavailable'**
  String get chatConversationUnavailableTitle;

  /// No description provided for @chatConversationUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We could not find this conversation right now. Refresh or return to your inbox.'**
  String get chatConversationUnavailableSubtitle;

  /// No description provided for @chatBackToInboxAction.
  ///
  /// In en, this message translates to:
  /// **'Back to messages'**
  String get chatBackToInboxAction;

  /// No description provided for @chatBookingActionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking action unavailable'**
  String get chatBookingActionUnavailableTitle;

  /// No description provided for @chatBookingActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest booking action could not be completed from this chat. Review the booking state and retry shortly.'**
  String get chatBookingActionFailureMessage;

  /// No description provided for @chatApproveBookingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve booking?'**
  String get chatApproveBookingDialogTitle;

  /// No description provided for @chatApproveBookingDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will approve the trucker booking request from the chat context.'**
  String get chatApproveBookingDialogMessage;

  /// No description provided for @chatRejectBookingDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject booking?'**
  String get chatRejectBookingDialogTitle;

  /// No description provided for @chatRejectBookingDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'This will reject the trucker booking request from the chat context.'**
  String get chatRejectBookingDialogMessage;

  /// No description provided for @commonCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancelAction;

  /// No description provided for @commonDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscardAction;

  /// No description provided for @chatActionApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get chatActionApprove;

  /// No description provided for @chatActionReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get chatActionReject;

  /// No description provided for @chatBookingApprovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking approved!'**
  String get chatBookingApprovedSuccess;

  /// No description provided for @chatBookingRejectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected.'**
  String get chatBookingRejectedSuccess;

  /// No description provided for @chatTextSendFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not send your message right now. Retry shortly from this chat.'**
  String get chatTextSendFailureMessage;

  /// No description provided for @chatVoiceStartFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not start voice recording right now. Retry shortly from this chat.'**
  String get chatVoiceStartFailureMessage;

  /// No description provided for @chatVoiceUploadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not upload this voice message right now. Retry shortly from this chat.'**
  String get chatVoiceUploadFailureMessage;

  /// No description provided for @chatVoiceSendFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not send this voice message right now. Retry shortly from this chat.'**
  String get chatVoiceSendFailureMessage;

  /// No description provided for @chatApproveBookingFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not approve this booking right now. Retry shortly from this chat.'**
  String get chatApproveBookingFailureMessage;

  /// No description provided for @chatRejectBookingFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not reject this booking right now. Retry shortly from this chat.'**
  String get chatRejectBookingFailureMessage;

  /// No description provided for @chatLoadContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Load context'**
  String get chatLoadContextTitle;

  /// No description provided for @chatCollapseLoadContextTooltip.
  ///
  /// In en, this message translates to:
  /// **'Collapse load context'**
  String get chatCollapseLoadContextTooltip;

  /// No description provided for @chatExpandLoadContextTooltip.
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

  /// No description provided for @chatBookingStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get chatBookingStatusApproved;

  /// No description provided for @commonUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get commonUnknownLabel;

  /// No description provided for @chatMessagesLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load messages'**
  String get chatMessagesLoadFailureTitle;

  /// No description provided for @chatMessagesLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this conversation right now. Retry shortly to refresh the latest messages and booking context.'**
  String get chatMessagesLoadFailureMessage;

  /// No description provided for @chatNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessagesTitle;

  /// No description provided for @chatNoMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a message to start this conversation.'**
  String get chatNoMessagesSubtitle;

  /// No description provided for @commonSystemUpdateLabel.
  ///
  /// In en, this message translates to:
  /// **'System update'**
  String get commonSystemUpdateLabel;

  /// No description provided for @chatSendingLabel.
  ///
  /// In en, this message translates to:
  /// **'sending...'**
  String get chatSendingLabel;

  /// No description provided for @chatPauseVoiceMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause voice message'**
  String get chatPauseVoiceMessageTooltip;

  /// No description provided for @chatPlayVoiceMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Play voice message'**
  String get chatPlayVoiceMessageTooltip;

  /// No description provided for @commonVoiceMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice message'**
  String get commonVoiceMessageLabel;

  /// No description provided for @chatVoicePlaybackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice playback is unavailable right now.'**
  String get chatVoicePlaybackUnavailable;

  /// No description provided for @chatVoicePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not play this voice message right now.'**
  String get chatVoicePlaybackFailed;

  /// No description provided for @chatLocationSharedFallback.
  ///
  /// In en, this message translates to:
  /// **'Shared location'**
  String get chatLocationSharedFallback;

  /// No description provided for @chatMapPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Map preview unavailable'**
  String get chatMapPreviewUnavailable;

  /// No description provided for @chatOpenInMapsAction.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get chatOpenInMapsAction;

  /// No description provided for @chatDocumentSharedFallback.
  ///
  /// In en, this message translates to:
  /// **'Shared document'**
  String get chatDocumentSharedFallback;

  /// No description provided for @chatAttachmentSavedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment saved to this conversation.'**
  String get chatAttachmentSavedSubtitle;

  /// No description provided for @chatOpenDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Open document'**
  String get chatOpenDocumentAction;

  /// No description provided for @chatRouteSummaryFallback.
  ///
  /// In en, this message translates to:
  /// **'Route summary'**
  String get chatRouteSummaryFallback;

  /// No description provided for @chatViewRouteAction.
  ///
  /// In en, this message translates to:
  /// **'View route'**
  String get chatViewRouteAction;

  /// No description provided for @commonTruckDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck details'**
  String get commonTruckDetailsLabel;

  /// No description provided for @chatTruckTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} tyres'**
  String chatTruckTyresLabel(Object value);

  /// No description provided for @chatTypeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessageHint;

  /// No description provided for @chatStopRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get chatStopRecordingTooltip;

  /// No description provided for @chatVoiceRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice recording'**
  String get chatVoiceRecordingTooltip;

  /// No description provided for @chatSendAction.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSendAction;

  /// No description provided for @commonHearSummary.
  ///
  /// In en, this message translates to:
  /// **'Hear summary'**
  String get commonHearSummary;

  /// No description provided for @commonVoiceMuted.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance is muted on this device.'**
  String get commonVoiceMuted;

  /// No description provided for @commonVoiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance is unavailable right now.'**
  String get commonVoiceUnavailable;

  /// No description provided for @notificationsMarkedAllReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notificationsMarkedAllReadSuccess;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications'**
  String get notificationsLoadFailureTitle;

  /// No description provided for @notificationsMarkAllReadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not mark all notifications as read right now. Retry shortly from the notifications screen.'**
  String get notificationsMarkAllReadFailureMessage;

  /// No description provided for @notificationsLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your notifications right now. Retry shortly to refresh the latest alerts and updates.'**
  String get notificationsLoadFailureMessage;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No new notifications.'**
  String get notificationsEmptySubtitle;

  /// No description provided for @notificationsOverviewTitle.
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

  /// No description provided for @commonLoadMoreAction.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get commonLoadMoreAction;

  /// No description provided for @notificationsTtsSummary.
  ///
  /// In en, this message translates to:
  /// **'Notifications screen. You have {unreadCount} unread notifications and {highPriorityUnreadCount} high priority alerts pending review.'**
  String notificationsTtsSummary(int unreadCount, int highPriorityUnreadCount);

  /// No description provided for @notificationsGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsGroupToday;

  /// No description provided for @notificationsGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationsGroupYesterday;

  /// No description provided for @notificationsPriorityHighLabel.
  ///
  /// In en, this message translates to:
  /// **'HIGH'**
  String get notificationsPriorityHighLabel;

  /// No description provided for @notificationsBodyFallback.
  ///
  /// In en, this message translates to:
  /// **'Open the linked workflow for full context.'**
  String get notificationsBodyFallback;

  /// No description provided for @notificationFallbackValue.
  ///
  /// In en, this message translates to:
  /// **'{type, select, verification_update {Verification update} booking_update {Booking update} trip_update {Trip update} proof_update {Proof update} super_load_update {Super Load update} message_received {New message} support_update {Support update} dispute_update {Dispute update} account_update {Account update} system_notice {System notice} load_expiry_warning {Load expiry warning} other {Notification}}'**
  String notificationFallbackValue(String type);

  /// No description provided for @navDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get navDeleteAccount;

  /// No description provided for @deleteAccountRequestedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Deletion requested on'**
  String get deleteAccountRequestedOnLabel;

  /// No description provided for @deleteAccountGracePeriodEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace period ends'**
  String get deleteAccountGracePeriodEndsLabel;

  /// No description provided for @deleteAccountGracePeriodPassedLabel.
  ///
  /// In en, this message translates to:
  /// **'Grace-period end date has passed. Permanent deletion processing may happen at any time.'**
  String get deleteAccountGracePeriodPassedLabel;

  /// No description provided for @deleteAccountGracePeriodLessThanOneDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Less than 1 day remains before the grace period ends.'**
  String get deleteAccountGracePeriodLessThanOneDayLabel;

  /// ICU plural message showing remaining days in grace period before account deletion. Placeholder {count} is the number of days remaining.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} day remains before the grace period ends.} other {{count} days remain before the grace period ends.}}'**
  String deleteAccountGracePeriodRemainingDaysLabel(int count);

  /// No description provided for @deleteAccountLifecycleFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The account deletion lifecycle is temporarily unavailable. Retry shortly to refresh the latest deletion status.'**
  String get deleteAccountLifecycleFailureMessage;

  /// No description provided for @deleteAccountCancelFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not cancel this deletion request right now. Retry shortly from the deletion lifecycle screen.'**
  String get deleteAccountCancelFailureMessage;

  /// No description provided for @deleteAccountRequestFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not process this deletion request right now. Review the current account status and retry shortly.'**
  String get deleteAccountRequestFailureMessage;

  /// No description provided for @deleteAccountAcceptedSignOutFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Deletion was accepted, but we could not complete sign out right now. Retry shortly to refresh your account session.'**
  String get deleteAccountAcceptedSignOutFailureMessage;

  /// No description provided for @deleteAccountBlockedSummaryMessage.
  ///
  /// In en, this message translates to:
  /// **'This deletion request cannot proceed yet because another account dependency still needs attention.'**
  String get deleteAccountBlockedSummaryMessage;

  /// No description provided for @deleteAccountCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request was cancelled. Account access can be restored while the lifecycle returns to active.'**
  String get deleteAccountCancelledMessage;

  /// No description provided for @deleteAccountAcceptedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your deletion request was accepted. You have been signed out while the account enters pending cleanup.'**
  String get deleteAccountAcceptedMessage;

  /// No description provided for @deleteAccountBlockerRecoveryGuidanceActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'Finish or cancel every active trip first, then retry the deletion request.'**
  String get deleteAccountBlockerRecoveryGuidanceActiveTrips;

  /// No description provided for @deleteAccountBlockerRecoveryGuidanceDispute.
  ///
  /// In en, this message translates to:
  /// **'Wait until the unresolved dispute is reviewed or resolved before requesting deletion again.'**
  String get deleteAccountBlockerRecoveryGuidanceDispute;

  /// No description provided for @deleteAccountBlockerRecoveryGuidanceCompliance.
  ///
  /// In en, this message translates to:
  /// **'Some records still need to stay on the platform for compliance or retention policy. Use support if you need clarification on the hold.'**
  String get deleteAccountBlockerRecoveryGuidanceCompliance;

  /// No description provided for @deleteAccountBlockerRecoveryGuidanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Resolve the blocking dependency first, then request deletion again.'**
  String get deleteAccountBlockerRecoveryGuidanceDefault;

  /// No description provided for @deleteAccountBlockerActionOpenTrips.
  ///
  /// In en, this message translates to:
  /// **'Open trips'**
  String get deleteAccountBlockerActionOpenTrips;

  /// No description provided for @commonOpenSupportAction.
  ///
  /// In en, this message translates to:
  /// **'Open support'**
  String get commonOpenSupportAction;

  /// No description provided for @deleteAccountBlockerTitleActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'Finish active trips first'**
  String get deleteAccountBlockerTitleActiveTrips;

  /// No description provided for @deleteAccountBlockerTitleDispute.
  ///
  /// In en, this message translates to:
  /// **'Resolve the open dispute first'**
  String get deleteAccountBlockerTitleDispute;

  /// No description provided for @deleteAccountBlockerTitleCompliance.
  ///
  /// In en, this message translates to:
  /// **'Wait for the compliance hold to clear'**
  String get deleteAccountBlockerTitleCompliance;

  /// No description provided for @deleteAccountBlockerTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Resolve the blocker first'**
  String get deleteAccountBlockerTitleDefault;

  /// No description provided for @deleteAccountBlockerBodyActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'This account still has active trip work attached to it. Review the current trip list, complete any legitimate active work, and then retry the deletion request.'**
  String get deleteAccountBlockerBodyActiveTrips;

  /// No description provided for @deleteAccountBlockerBodyDispute.
  ///
  /// In en, this message translates to:
  /// **'This account still has an unresolved dispute or review dependency. Use support to follow the current case until the blocking dispute is resolved.'**
  String get deleteAccountBlockerBodyDispute;

  /// No description provided for @deleteAccountBlockerBodyCompliance.
  ///
  /// In en, this message translates to:
  /// **'This account is still under a compliance or retention hold. Support can clarify the current hold, but the platform cannot bypass the retention requirement.'**
  String get deleteAccountBlockerBodyCompliance;

  /// No description provided for @deleteAccountBlockerBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Review the current blocker carefully and resolve it before retrying the deletion request.'**
  String get deleteAccountBlockerBodyDefault;

  /// No description provided for @deleteAccountSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Need help first?'**
  String get deleteAccountSupportTitle;

  /// No description provided for @deleteAccountSupportBodyPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Use support if you need clarification on the pending-cleanup status, the grace-period timeline, or whether cancellation is the right next step for this account.'**
  String get deleteAccountSupportBodyPendingCleanup;

  /// No description provided for @deleteAccountSupportBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Use support if you expect blockers like active trips, unresolved disputes, or compliance holds and need clarification before retrying the deletion request.'**
  String get deleteAccountSupportBodyDefault;

  /// No description provided for @deleteAccountSupportDetailPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Support can clarify the current lifecycle state, but they may still need to follow retention and compliance policy before permanent deletion is processed.'**
  String get deleteAccountSupportDetailPendingCleanup;

  /// No description provided for @deleteAccountSupportDetailDefault.
  ///
  /// In en, this message translates to:
  /// **'Support can explain the current blocker or retention requirement, but they cannot bypass required cleanup, dispute review, or compliance policy.'**
  String get deleteAccountSupportDetailDefault;

  /// No description provided for @commonWhatHappensNextTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next'**
  String get commonWhatHappensNextTitle;

  /// No description provided for @deleteAccountWhatHappensNextBodyPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Your account is already in the pending-cleanup state. Cancel the request if you want to restore the account to active before permanent deletion is processed.'**
  String get deleteAccountWhatHappensNextBodyPendingCleanup;

  /// No description provided for @deleteAccountWhatHappensNextBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'If no blockers exist, your account is moved to deactivated pending cleanup and you are signed out safely.'**
  String get deleteAccountWhatHappensNextBodyDefault;

  /// No description provided for @deleteAccountWhatHappensNextDetailPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'If you cancel now, the account deletion status returns to active and normal access is restored.'**
  String get deleteAccountWhatHappensNextDetailPendingCleanup;

  /// No description provided for @deleteAccountWhatHappensNextDetailDefault.
  ///
  /// In en, this message translates to:
  /// **'If blockers exist, the platform keeps your account active and tells you which dependency must be resolved first.'**
  String get deleteAccountWhatHappensNextDetailDefault;

  /// No description provided for @deleteAccountWhatHappensNextFootnotePendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Support may still retain internal records according to policy, but the user-facing deletion request will be cancelled.'**
  String get deleteAccountWhatHappensNextFootnotePendingCleanup;

  /// No description provided for @deleteAccountWhatHappensNextFootnoteDefault.
  ///
  /// In en, this message translates to:
  /// **'The deletion request can now be cancelled while the account is in the pending-cleanup lifecycle before permanent deletion is processed.'**
  String get deleteAccountWhatHappensNextFootnoteDefault;

  /// No description provided for @deleteAccountLifecycleUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deletion lifecycle unavailable'**
  String get deleteAccountLifecycleUnavailableTitle;

  /// No description provided for @deleteAccountCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion request cancelled'**
  String get deleteAccountCancelledTitle;

  /// No description provided for @deleteAccountAlreadyRequestedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion already requested'**
  String get deleteAccountAlreadyRequestedTitle;

  /// No description provided for @deleteAccountAlreadyRequestedMessage.
  ///
  /// In en, this message translates to:
  /// **'This account is currently deactivated pending cleanup. Cancel the request below if you need to restore access during the grace-period lifecycle.'**
  String get deleteAccountAlreadyRequestedMessage;

  /// No description provided for @commonCancelDeletionRequestAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion request'**
  String get commonCancelDeletionRequestAction;

  /// No description provided for @deleteAccountCancellingButton.
  ///
  /// In en, this message translates to:
  /// **'Cancelling deletion...'**
  String get deleteAccountCancellingButton;

  /// No description provided for @deleteAccountUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deletion unavailable'**
  String get deleteAccountUnavailableTitle;

  /// No description provided for @deleteAccountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Deletion blocked'**
  String get deleteAccountBlockedTitle;

  /// No description provided for @deleteAccountConfirmRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion request'**
  String get deleteAccountConfirmRequestTitle;

  /// No description provided for @deleteAccountRequestingButton.
  ///
  /// In en, this message translates to:
  /// **'Requesting deletion...'**
  String get deleteAccountRequestingButton;

  /// No description provided for @deleteAccountScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountScreenTitle;

  /// No description provided for @deleteAccountHeroTitlePendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Account deletion pending cleanup'**
  String get deleteAccountHeroTitlePendingCleanup;

  /// No description provided for @deleteAccountHeroTitleDefault.
  ///
  /// In en, this message translates to:
  /// **'Request account deletion'**
  String get deleteAccountHeroTitleDefault;

  /// No description provided for @deleteAccountHeroSubtitlePendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Your account is currently deactivated pending cleanup. You can still cancel this request during the grace-period lifecycle while the account is not permanently deleted.'**
  String get deleteAccountHeroSubtitlePendingCleanup;

  /// No description provided for @deleteAccountHeroSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'This action can deactivate your account immediately if no active blockers exist. Review the consequences carefully before continuing.'**
  String get deleteAccountHeroSubtitleDefault;

  /// No description provided for @deleteAccountHeroBodyPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'The deletion request has already been accepted and the account is in pending-cleanup state. Cancel the request if you want to restore normal account access before permanent deletion is processed.'**
  String get deleteAccountHeroBodyPendingCleanup;

  /// No description provided for @deleteAccountHeroBodyDefault.
  ///
  /// In en, this message translates to:
  /// **'Before deletion can proceed, the platform checks for active trips, unresolved disputes, and compliance or verification records that still require retention.'**
  String get deleteAccountHeroBodyDefault;

  /// No description provided for @accountSignOutFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not sign you out right now. Retry shortly from this screen.'**
  String get accountSignOutFailureMessage;

  /// No description provided for @accountRoleValue.
  ///
  /// In en, this message translates to:
  /// **'{role, select, supplier {Supplier} trucker {Trucker} other {Unknown}}'**
  String accountRoleValue(String role);

  /// No description provided for @accountStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Account status'**
  String get accountStatusTitle;

  /// No description provided for @accountProfileStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile status'**
  String get accountProfileStatusLabel;

  /// No description provided for @accountProfileStatusComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get accountProfileStatusComplete;

  /// No description provided for @accountProfileStatusNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get accountProfileStatusNeedsAttention;

  /// No description provided for @accountAccountStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Account state'**
  String get accountAccountStateLabel;

  /// No description provided for @accountStateValue.
  ///
  /// In en, this message translates to:
  /// **'{state, select, deactivated_pending_cleanup {Deactivated pending cleanup} restricted {Restricted} active {Active} unknown {Unknown} other {Unknown}}'**
  String accountStateValue(String state);

  /// No description provided for @accountLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Account details unavailable'**
  String get accountLoadFailureTitle;

  /// No description provided for @accountLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your account details right now. Retry shortly from this screen.'**
  String get accountLoadFailureMessage;

  /// No description provided for @accountManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage account'**
  String get accountManageTitle;

  /// No description provided for @accountVerificationLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get accountVerificationLabel;

  /// No description provided for @accountSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountSettingsLabel;

  /// No description provided for @accountSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Current session'**
  String get accountSessionTitle;

  /// No description provided for @accountSignedInAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Signed in as'**
  String get accountSignedInAsLabel;

  /// No description provided for @accountCurrentAuthenticatedSession.
  ///
  /// In en, this message translates to:
  /// **'Current authenticated session'**
  String get accountCurrentAuthenticatedSession;

  /// No description provided for @profileLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get profileLoadFailureTitle;

  /// No description provided for @profileLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your profile right now. Retry shortly from this screen.'**
  String get profileLoadFailureMessage;

  /// No description provided for @profileSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile summary'**
  String get profileSummaryTitle;

  /// No description provided for @profileNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileNameLabel;

  /// No description provided for @profileValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileValueNotSet;

  /// No description provided for @profilePhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get profilePhoneLabel;

  /// No description provided for @profileValueNotProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get profileValueNotProvided;

  /// No description provided for @profileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmailLabel;

  /// No description provided for @profileRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get profileRoleLabel;

  /// No description provided for @profileLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocationLabel;

  /// No description provided for @profileLocationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileLocationNotSet;

  /// No description provided for @profileReadinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile readiness'**
  String get profileReadinessTitle;

  /// No description provided for @profileCompletenessLabel.
  ///
  /// In en, this message translates to:
  /// **'Completeness'**
  String get profileCompletenessLabel;

  /// No description provided for @profileCompletenessComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get profileCompletenessComplete;

  /// No description provided for @profileCompletenessNeedsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Needs updates'**
  String get profileCompletenessNeedsUpdates;

  /// No description provided for @profileDeletionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Deletion status'**
  String get profileDeletionStatusLabel;

  /// No description provided for @profileOpenFleetReadiness.
  ///
  /// In en, this message translates to:
  /// **'Open fleet readiness'**
  String get profileOpenFleetReadiness;

  /// No description provided for @profileRequestAccountDeletion.
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

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferencesTitle;

  /// No description provided for @settingsRoleContextLabel.
  ///
  /// In en, this message translates to:
  /// **'Role context'**
  String get settingsRoleContextLabel;

  /// TTS summary for settings screen. Placeholders {selectedLanguageLabel} and {roleSentence} describe current settings.
  ///
  /// In en, this message translates to:
  /// **'Settings screen. Language is set to {selectedLanguageLabel}. Voice guidance is manual right now. Notifications are enabled through the in-app inbox.{roleSentence}'**
  String settingsTtsSummary(Object selectedLanguageLabel, Object roleSentence);

  /// No description provided for @settingsVoiceAssistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice assistance'**
  String get settingsVoiceAssistanceLabel;

  /// No description provided for @settingsVoiceAssistanceValue.
  ///
  /// In en, this message translates to:
  /// **'Manual contextual summaries are available from supported screens.'**
  String get settingsVoiceAssistanceValue;

  /// No description provided for @settingsNotificationsValue.
  ///
  /// In en, this message translates to:
  /// **'In-app inbox and push status controls are available here.'**
  String get settingsNotificationsValue;

  /// No description provided for @settingsConnectedSurfacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected surfaces'**
  String get settingsConnectedSurfacesTitle;

  /// No description provided for @settingsPushNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotificationsTitle;

  /// No description provided for @settingsPushStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get settingsPushStatusLabel;

  /// No description provided for @settingsPushRequestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request permission'**
  String get settingsPushRequestPermission;

  /// No description provided for @settingsPushRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get settingsPushRefreshStatus;

  /// No description provided for @settingsPushStatusUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Push notification status unavailable'**
  String get settingsPushStatusUnavailableTitle;

  /// No description provided for @settingsPushStatusUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to read device notification permission right now. Refresh after Firebase/device support is available.'**
  String get settingsPushStatusUnavailableMessage;

  /// No description provided for @settingsPushStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, allowed {Allowed} allowed_quietly {Allowed quietly} blocked {Blocked in system settings} not_requested {Not requested yet} unavailable {Unavailable on this device/build} other {Unavailable}}'**
  String settingsPushStatusValue(String status);

  /// No description provided for @settingsPushGuidanceValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, allowed {Foreground and opened push flows are enabled when Firebase delivery is configured.} allowed_quietly {Push is allowed quietly. You can promote alerts in the device notification settings if needed.} blocked {Push notifications are blocked. Open your device notification settings for TranZfort to enable alerts again.} not_requested {Push permission has not been requested yet on this device session.} unavailable {Push runtime is unavailable here until Firebase/device support is fully configured.} other {Push runtime is unavailable here until Firebase/device support is fully configured.}}'**
  String settingsPushGuidanceValue(String status);

  /// Shows count of active support tickets with pluralization. Placeholder {count} is the ticket count, {s} is plural suffix.
  ///
  /// In en, this message translates to:
  /// **'{count} ticket{s}'**
  String supportActiveTicketCount(Object count, Object s);

  /// No description provided for @supportScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Support and dispute follow-up'**
  String get supportScreenTitle;

  /// No description provided for @supportHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your latest support activity'**
  String get supportHeroTitle;

  /// No description provided for @supportHeroSubtitleSupplier.
  ///
  /// In en, this message translates to:
  /// **'Use support to review dispute progress, payment follow-ups, and the latest visible ticket updates linked to your supplier activity.'**
  String get supportHeroSubtitleSupplier;

  /// No description provided for @supportHeroSubtitleTrucker.
  ///
  /// In en, this message translates to:
  /// **'Use support to review dispute progress, freight follow-ups, and the latest visible ticket updates linked to your trucker activity.'**
  String get supportHeroSubtitleTrucker;

  /// No description provided for @supportNoActiveTickets.
  ///
  /// In en, this message translates to:
  /// **'No active tickets'**
  String get supportNoActiveTickets;

  /// No description provided for @supportCreateTicketAction.
  ///
  /// In en, this message translates to:
  /// **'Create support ticket'**
  String get supportCreateTicketAction;

  /// No description provided for @supportIntroMessage.
  ///
  /// In en, this message translates to:
  /// **'Follow your latest support and dispute tickets here, review visible workflow updates, and reply with any clarification or proof support requested.'**
  String get supportIntroMessage;

  /// No description provided for @supportTicketSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Support summary'**
  String get supportTicketSummaryTitle;

  /// No description provided for @supportEscalationPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Escalation path'**
  String get supportEscalationPathLabel;

  /// No description provided for @supportEscalationPathSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier support'**
  String get supportEscalationPathSupplier;

  /// No description provided for @supportEscalationPathTrucker.
  ///
  /// In en, this message translates to:
  /// **'Trucker support'**
  String get supportEscalationPathTrucker;

  /// No description provided for @supportCurrentTrustStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Current trust status'**
  String get supportCurrentTrustStatusLabel;

  /// No description provided for @supportMyTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get supportMyTicketsTitle;

  /// No description provided for @supportSelectedTicketAndReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected ticket and reply'**
  String get supportSelectedTicketAndReplyTitle;

  /// No description provided for @supportSelectTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a ticket'**
  String get supportSelectTicketTitle;

  /// No description provided for @supportSelectTicketSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a support ticket from the list to review its visible thread, workflow state, and reply options.'**
  String get supportSelectTicketSubtitle;

  /// No description provided for @supportTicketsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Support tickets unavailable'**
  String get supportTicketsUnavailableTitle;

  /// No description provided for @supportNoTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get supportNoTicketsTitle;

  /// No description provided for @supportNoTicketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a support ticket to start a new support or dispute follow-up and track future updates here.'**
  String get supportNoTicketsSubtitle;

  /// No description provided for @supportLoadingOlderTickets.
  ///
  /// In en, this message translates to:
  /// **'Loading older tickets...'**
  String get supportLoadingOlderTickets;

  /// No description provided for @supportLoadOlderTickets.
  ///
  /// In en, this message translates to:
  /// **'Load older tickets'**
  String get supportLoadOlderTickets;

  /// No description provided for @supportTicketsLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your support tickets right now. Retry shortly to refresh your latest support and dispute activity.'**
  String get supportTicketsLoadFailureMessage;

  /// No description provided for @supportOpenTripAction.
  ///
  /// In en, this message translates to:
  /// **'Open trip'**
  String get supportOpenTripAction;

  /// No description provided for @supportOpenLoadAction.
  ///
  /// In en, this message translates to:
  /// **'Open load'**
  String get supportOpenLoadAction;

  /// No description provided for @supportViewingThisTicket.
  ///
  /// In en, this message translates to:
  /// **'Viewing this ticket'**
  String get supportViewingThisTicket;

  /// No description provided for @supportOpenTicketAction.
  ///
  /// In en, this message translates to:
  /// **'Open ticket'**
  String get supportOpenTicketAction;

  /// No description provided for @supportDetailUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket detail unavailable'**
  String get supportDetailUnavailableTitle;

  /// No description provided for @supportDetailUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this ticket detail right now. Retry shortly to refresh the latest visible thread and workflow status.'**
  String get supportDetailUnavailableMessage;

  /// No description provided for @supportTicketUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket unavailable'**
  String get supportTicketUnavailableTitle;

  /// No description provided for @supportTicketUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This support ticket is unavailable right now for the current account.'**
  String get supportTicketUnavailableSubtitle;

  /// No description provided for @supportTicketStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, open {Open} in_progress {In progress} waiting_for_you {Waiting for you} resolved {Resolved} closed {Closed} unknown {Unknown} other {Unknown}}'**
  String supportTicketStatusValue(String status);

  /// No description provided for @supportTicketPriorityValue.
  ///
  /// In en, this message translates to:
  /// **'{priority, select, low {low} medium {medium} high {high} urgent {urgent} not_set {not set} other {not set}}'**
  String supportTicketPriorityValue(String priority);

  /// No description provided for @supportTicketTitleTripDisputeReview.
  ///
  /// In en, this message translates to:
  /// **'Trip dispute review'**
  String get supportTicketTitleTripDisputeReview;

  /// No description provided for @supportTicketTitleLoadedQuantityMismatchReport.
  ///
  /// In en, this message translates to:
  /// **'Loaded quantity mismatch report'**
  String get supportTicketTitleLoadedQuantityMismatchReport;

  /// No description provided for @supportTicketTitleUnloadedQuantityMismatchReport.
  ///
  /// In en, this message translates to:
  /// **'Unloaded quantity mismatch report'**
  String get supportTicketTitleUnloadedQuantityMismatchReport;

  /// No description provided for @supportTicketTitleDocumentMismatchReport.
  ///
  /// In en, this message translates to:
  /// **'Document mismatch report'**
  String get supportTicketTitleDocumentMismatchReport;

  /// No description provided for @supportTicketTitleSpamOrScamReport.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam report'**
  String get supportTicketTitleSpamOrScamReport;

  /// No description provided for @supportTicketTitleAbusiveBehaviorReport.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior report'**
  String get supportTicketTitleAbusiveBehaviorReport;

  /// No description provided for @supportTicketTitleFakePayoutProofReport.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof report'**
  String get supportTicketTitleFakePayoutProofReport;

  /// No description provided for @supportTicketTitleNonPaymentReport.
  ///
  /// In en, this message translates to:
  /// **'Non-payment report'**
  String get supportTicketTitleNonPaymentReport;

  /// No description provided for @supportTicketTitleDelayOrNoShowReport.
  ///
  /// In en, this message translates to:
  /// **'Delay or no-show report'**
  String get supportTicketTitleDelayOrNoShowReport;

  /// No description provided for @supportTicketTitleDamageOrShortageReport.
  ///
  /// In en, this message translates to:
  /// **'Damage or shortage report'**
  String get supportTicketTitleDamageOrShortageReport;

  /// No description provided for @supportTicketTitleOtherReport.
  ///
  /// In en, this message translates to:
  /// **'Other report'**
  String get supportTicketTitleOtherReport;

  /// No description provided for @supportDisputeCategoryTripDispute.
  ///
  /// In en, this message translates to:
  /// **'Trip dispute'**
  String get supportDisputeCategoryTripDispute;

  /// No description provided for @supportDisputeCategoryLoadedQuantityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Loaded quantity mismatch'**
  String get supportDisputeCategoryLoadedQuantityMismatch;

  /// No description provided for @supportDisputeCategoryUnloadedQuantityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Unloaded quantity mismatch'**
  String get supportDisputeCategoryUnloadedQuantityMismatch;

  /// No description provided for @supportDisputeCategoryDocumentMismatch.
  ///
  /// In en, this message translates to:
  /// **'Document mismatch'**
  String get supportDisputeCategoryDocumentMismatch;

  /// No description provided for @supportDisputeCategoryNonPayment.
  ///
  /// In en, this message translates to:
  /// **'Non-payment'**
  String get supportDisputeCategoryNonPayment;

  /// No description provided for @supportDisputeCategoryFakePayoutProof.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof'**
  String get supportDisputeCategoryFakePayoutProof;

  /// No description provided for @supportDisputeCategoryDelayOrNoShow.
  ///
  /// In en, this message translates to:
  /// **'Delay or no-show'**
  String get supportDisputeCategoryDelayOrNoShow;

  /// No description provided for @supportDisputeCategoryDamageOrShortage.
  ///
  /// In en, this message translates to:
  /// **'Damage or shortage'**
  String get supportDisputeCategoryDamageOrShortage;

  /// No description provided for @supportDisputeCategoryAbusiveBehavior.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior'**
  String get supportDisputeCategoryAbusiveBehavior;

  /// No description provided for @supportDisputeCategorySpamOrScam.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get supportDisputeCategorySpamOrScam;

  /// No description provided for @supportDisputeCategoryOther.
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
  /// **'Support ticket on record'**
  String get supportTicketReference;

  /// No description provided for @supportTripReference.
  ///
  /// In en, this message translates to:
  /// **'Linked trip'**
  String get supportTripReference;

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
  /// **'Support ticket on record'**
  String get supportTicketIdValue;

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
  /// **'Related trip linked'**
  String get supportRelatedTripValue;

  /// No description provided for @supportRelatedLoadValue.
  ///
  /// In en, this message translates to:
  /// **'Related load linked'**
  String get supportRelatedLoadValue;

  /// No description provided for @supportOpenRelatedTripAction.
  ///
  /// In en, this message translates to:
  /// **'Open related trip'**
  String get supportOpenRelatedTripAction;

  /// No description provided for @supportOpenRelatedLoadAction.
  ///
  /// In en, this message translates to:
  /// **'Open related load'**
  String get supportOpenRelatedLoadAction;

  /// No description provided for @supportWorkflowGuidanceOpen.
  ///
  /// In en, this message translates to:
  /// **'Support has received this ticket and review should begin shortly. Use visible replies to add any missing context if needed.'**
  String get supportWorkflowGuidanceOpen;

  /// No description provided for @supportWorkflowGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Support or operations are actively reviewing this ticket. Watch for visible replies and be ready to clarify the timeline or proof if more detail is requested.'**
  String get supportWorkflowGuidanceInProgress;

  /// No description provided for @supportWorkflowGuidanceWaitingForUser.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting on your clarification or proof. Reply on this ticket so the review can continue without unnecessary delay.'**
  String get supportWorkflowGuidanceWaitingForUser;

  /// No description provided for @supportWorkflowGuidanceResolved.
  ///
  /// In en, this message translates to:
  /// **'This ticket has reached a final support outcome. Review the recorded resolution before opening any fresh follow-up.'**
  String get supportWorkflowGuidanceResolved;

  /// No description provided for @supportWorkflowGuidanceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Review the latest visible ticket updates for the current workflow state.'**
  String get supportWorkflowGuidanceUnknown;

  /// No description provided for @commonDisputeReviewClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute review closed'**
  String get commonDisputeReviewClosedTitle;

  /// No description provided for @supportDisputeBannerTitleWaiting.
  ///
  /// In en, this message translates to:
  /// **'Dispute waiting for your reply'**
  String get supportDisputeBannerTitleWaiting;

  /// No description provided for @supportDisputeBannerTitleInProgress.
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

  /// No description provided for @supportEvidenceVisibilitySummaryClosed.
  ///
  /// In en, this message translates to:
  /// **'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this ticket.'**
  String get supportEvidenceVisibilitySummaryClosed;

  /// No description provided for @supportEvidenceVisibilitySummaryInProgress.
  ///
  /// In en, this message translates to:
  /// **'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible on this ticket.'**
  String get supportEvidenceVisibilitySummaryInProgress;

  /// No description provided for @supportRestrictedEvidenceMessageClosed.
  ///
  /// In en, this message translates to:
  /// **'Raw attachments and sensitive proof may remain restricted even after the review outcome is recorded on the ticket.'**
  String get supportRestrictedEvidenceMessageClosed;

  /// No description provided for @supportRestrictedEvidenceMessageInProgress.
  ///
  /// In en, this message translates to:
  /// **'Raw attachments and sensitive proof may remain restricted while this review stays active on the ticket.'**
  String get supportRestrictedEvidenceMessageInProgress;

  /// No description provided for @supportAdditionalProofGuidanceClosed.
  ///
  /// In en, this message translates to:
  /// **'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have a genuinely new issue or clarification to raise.'**
  String get supportAdditionalProofGuidanceClosed;

  /// No description provided for @supportAdditionalProofGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'If your dispute depends on additional documents or screenshots beyond the current single-image flow, describe those missing proofs clearly in your visible reply so support knows what else to review.'**
  String get supportAdditionalProofGuidanceInProgress;

  /// No description provided for @supportAttachmentVisibilityMessageClosed.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached to this reply. Raw file access may remain restricted even after the review outcome is recorded on this ticket.'**
  String get supportAttachmentVisibilityMessageClosed;

  /// No description provided for @supportAttachmentVisibilityMessageInProgress.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached to this reply. Raw file access may remain restricted during review.'**
  String get supportAttachmentVisibilityMessageInProgress;

  /// No description provided for @supportAttachmentGuidanceMessageClosed.
  ///
  /// In en, this message translates to:
  /// **'If you still need to reference other supporting proofs after closure, open a fresh follow-up only when you have genuinely new context that was not captured on this ticket.'**
  String get supportAttachmentGuidanceMessageClosed;

  /// No description provided for @supportAttachmentGuidanceMessageInProgress.
  ///
  /// In en, this message translates to:
  /// **'If other supporting proofs are not attached here, summarize them in visible reply text so support can request or review them safely.'**
  String get supportAttachmentGuidanceMessageInProgress;

  /// No description provided for @supportSupportTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Support team'**
  String get supportSupportTeamLabel;

  /// No description provided for @supportYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get supportYouLabel;

  /// No description provided for @supportEmptyThreadSubtitleOpen.
  ///
  /// In en, this message translates to:
  /// **'No visible thread has been posted on this support ticket yet.'**
  String get supportEmptyThreadSubtitleOpen;

  /// No description provided for @supportEmptyThreadSubtitleInProgress.
  ///
  /// In en, this message translates to:
  /// **'No visible thread is available yet while this ticket remains under active review.'**
  String get supportEmptyThreadSubtitleInProgress;

  /// No description provided for @supportEmptyThreadSubtitleWaiting.
  ///
  /// In en, this message translates to:
  /// **'No visible thread is available yet. Reply on this ticket so the review can continue.'**
  String get supportEmptyThreadSubtitleWaiting;

  /// No description provided for @supportEmptyThreadSubtitleResolved.
  ///
  /// In en, this message translates to:
  /// **'No visible thread was recorded before this ticket was resolved or closed.'**
  String get supportEmptyThreadSubtitleResolved;

  /// No description provided for @supportEmptyThreadSubtitleUnknown.
  ///
  /// In en, this message translates to:
  /// **'No visible thread is available for this support ticket yet.'**
  String get supportEmptyThreadSubtitleUnknown;

  /// No description provided for @supportEvidenceVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence visibility'**
  String get supportEvidenceVisibilityTitle;

  /// No description provided for @supportVisibleThreadSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Visible thread summary'**
  String get supportVisibleThreadSummaryTitle;

  /// No description provided for @supportVisibleRepliesCount.
  ///
  /// In en, this message translates to:
  /// **'Visible replies: {count}'**
  String supportVisibleRepliesCount(int count);

  /// No description provided for @supportLastVisibleUpdateNone.
  ///
  /// In en, this message translates to:
  /// **'Last visible update: No visible replies yet.'**
  String get supportLastVisibleUpdateNone;

  /// No description provided for @supportLastVisibleUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last visible update: {value}'**
  String supportLastVisibleUpdate(Object value);

  /// No description provided for @supportLatestVisibleSenderNone.
  ///
  /// In en, this message translates to:
  /// **'Latest visible sender: No visible sender yet.'**
  String get supportLatestVisibleSenderNone;

  /// No description provided for @supportLatestVisibleSender.
  ///
  /// In en, this message translates to:
  /// **'Latest visible sender: {value}'**
  String supportLatestVisibleSender(Object value);

  /// No description provided for @supportVisibleAttachmentSummaryPresent.
  ///
  /// In en, this message translates to:
  /// **'Visible attachment summary: One or more visible replies include an attachment reference.'**
  String get supportVisibleAttachmentSummaryPresent;

  /// No description provided for @supportVisibleAttachmentSummaryAbsent.
  ///
  /// In en, this message translates to:
  /// **'Visible attachment summary: No visible replies include an attachment reference yet.'**
  String get supportVisibleAttachmentSummaryAbsent;

  /// No description provided for @supportNoVisibleThreadTitle.
  ///
  /// In en, this message translates to:
  /// **'No visible thread yet'**
  String get supportNoVisibleThreadTitle;

  /// No description provided for @supportCurrentWorkflowTitle.
  ///
  /// In en, this message translates to:
  /// **'Current workflow'**
  String get supportCurrentWorkflowTitle;

  /// No description provided for @supportResolutionOutcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resolution outcome'**
  String get supportResolutionOutcomeTitle;

  /// No description provided for @supportResolvedOn.
  ///
  /// In en, this message translates to:
  /// **'Resolved on: {value}'**
  String supportResolvedOn(Object value);

  /// No description provided for @supportWaitingForReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting for your reply'**
  String get supportWaitingForReplyTitle;

  /// No description provided for @supportWaitingForReplyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reply on this ticket with the requested clarification or proof so the review can continue.'**
  String get supportWaitingForReplyMessage;

  /// No description provided for @supportReplyGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply guidance'**
  String get supportReplyGuidanceTitle;

  /// No description provided for @supportRepliesClosedTitle.
  ///
  /// In en, this message translates to:
  /// **'Replies are closed for this ticket'**
  String get supportRepliesClosedTitle;

  /// No description provided for @supportRepliesClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'This ticket has reached a final support outcome and does not accept further replies.'**
  String get supportRepliesClosedMessage;

  /// No description provided for @supportReplyStatusReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get supportReplyStatusReply;

  /// No description provided for @supportReplyStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get supportReplyStatusSubmitted;

  /// No description provided for @supportNoMessageTextProvided.
  ///
  /// In en, this message translates to:
  /// **'No message text provided.'**
  String get supportNoMessageTextProvided;

  /// No description provided for @supportTrustStatusLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading trust status'**
  String get supportTrustStatusLoading;

  /// No description provided for @supportResolutionValue.
  ///
  /// In en, this message translates to:
  /// **'Resolution: {value}'**
  String supportResolutionValue(Object value);

  /// No description provided for @supportReplyGuidancePrimaryOpenDispute.
  ///
  /// In en, this message translates to:
  /// **'Use your visible reply to explain the dispute timeline, what proof is already attached, and what support should review first.'**
  String get supportReplyGuidancePrimaryOpenDispute;

  /// No description provided for @supportReplyGuidancePrimaryOpenDefault.
  ///
  /// In en, this message translates to:
  /// **'Use your reply to explain the current blocker clearly so support can continue the review.'**
  String get supportReplyGuidancePrimaryOpenDefault;

  /// No description provided for @supportReplyGuidancePrimaryInProgressDispute.
  ///
  /// In en, this message translates to:
  /// **'Keep your next reply focused on the dispute timeline, proof gaps, and the clearest follow-up support should review.'**
  String get supportReplyGuidancePrimaryInProgressDispute;

  /// No description provided for @supportReplyGuidancePrimaryInProgressDefault.
  ///
  /// In en, this message translates to:
  /// **'Reply with the next operational detail or clarification support asked for so the review can continue.'**
  String get supportReplyGuidancePrimaryInProgressDefault;

  /// No description provided for @supportReplyGuidancePrimaryWaitingDispute.
  ///
  /// In en, this message translates to:
  /// **'Reply with the missing clarification or proof support requested so the dispute review can continue without unnecessary delay.'**
  String get supportReplyGuidancePrimaryWaitingDispute;

  /// No description provided for @supportReplyGuidancePrimaryWaitingDefault.
  ///
  /// In en, this message translates to:
  /// **'Reply with the missing clarification support requested so the ticket can continue moving.'**
  String get supportReplyGuidancePrimaryWaitingDefault;

  /// No description provided for @supportReplyGuidancePrimaryResolved.
  ///
  /// In en, this message translates to:
  /// **'This ticket is already resolved. Start a fresh follow-up only if a genuinely new issue appears.'**
  String get supportReplyGuidancePrimaryResolved;

  /// No description provided for @supportReplyGuidancePrimaryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Reply with the clearest next detail you can share if support requests more information.'**
  String get supportReplyGuidancePrimaryUnknown;

  /// No description provided for @supportReplyGuidanceSecondaryOpenInProgressDispute.
  ///
  /// In en, this message translates to:
  /// **'If proof is missing from the current single-image flow, summarize the rest clearly in visible text so support knows what else to request or review.'**
  String get supportReplyGuidanceSecondaryOpenInProgressDispute;

  /// No description provided for @supportReplyGuidanceSecondaryOpenInProgressDefault.
  ///
  /// In en, this message translates to:
  /// **'Keep the reply concise, specific, and tied to the load or trip context support is reviewing.'**
  String get supportReplyGuidanceSecondaryOpenInProgressDefault;

  /// No description provided for @supportReplyGuidanceSecondaryWaitingDispute.
  ///
  /// In en, this message translates to:
  /// **'If more than one proof matters, attach the strongest one first and summarize the remaining context in your visible reply.'**
  String get supportReplyGuidanceSecondaryWaitingDispute;

  /// No description provided for @supportReplyGuidanceSecondaryWaitingDefault.
  ///
  /// In en, this message translates to:
  /// **'Answer the latest support prompt directly so the next review step is clear.'**
  String get supportReplyGuidanceSecondaryWaitingDefault;

  /// No description provided for @supportReplyGuidanceSecondaryResolved.
  ///
  /// In en, this message translates to:
  /// **'Keep the recorded resolution for reference and use a new ticket only for genuinely new follow-up.'**
  String get supportReplyGuidanceSecondaryResolved;

  /// No description provided for @supportReplyGuidanceSecondaryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Keep your reply clear and limited to the facts support can verify next.'**
  String get supportReplyGuidanceSecondaryUnknown;

  /// No description provided for @supportTicketTitleWithPriority.
  ///
  /// In en, this message translates to:
  /// **'{title} - {priority} priority'**
  String supportTicketTitleWithPriority(Object title, Object priority);

  /// No description provided for @supportTrustStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, normal {Normal} warned {Warned} restricted {Restricted} suspended {Suspended} banned {Banned} unknown {Unknown} other {Unknown}}'**
  String supportTrustStatusValue(String status);

  /// No description provided for @supportTrustBadge.
  ///
  /// In en, this message translates to:
  /// **'Trust: {status}'**
  String supportTrustBadge(Object status);

  /// No description provided for @trustSafetyLabel.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety'**
  String get trustSafetyLabel;

  /// No description provided for @trustSafetyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety warning active'**
  String get trustSafetyWarningTitle;

  /// No description provided for @trustSafetyWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has a warning on record. Marketplace and support surfaces remain available, but you should avoid further violations and use support if you need clarification on the warning or next-step expectations.'**
  String get trustSafetyWarningMessage;

  /// No description provided for @trustSafetyRestrictionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety restriction active'**
  String get trustSafetyRestrictionTitle;

  /// No description provided for @trustSafetyRestrictionFallback.
  ///
  /// In en, this message translates to:
  /// **'Some platform actions may be limited while this restriction remains active. Use support to confirm which actions are limited and what changes may be required before the restriction can be reviewed.'**
  String get trustSafetyRestrictionFallback;

  /// No description provided for @trustSafetySuspensionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety suspension active'**
  String get trustSafetySuspensionTitle;

  /// No description provided for @trustSafetySuspensionFallback.
  ///
  /// In en, this message translates to:
  /// **'Access to key platform actions may be paused while this suspension remains active. Use support for policy-allowed review updates or reinstatement guidance once the required next steps are complete.'**
  String get trustSafetySuspensionFallback;

  /// No description provided for @trustSafetyBanTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust & safety ban active'**
  String get trustSafetyBanTitle;

  /// No description provided for @trustSafetyBanFallback.
  ///
  /// In en, this message translates to:
  /// **'This account is blocked from normal platform use. Use support only for policy-allowed clarification or final review outcome questions.'**
  String get trustSafetyBanFallback;

  /// No description provided for @trustSafetyHealthyMessageLine1.
  ///
  /// In en, this message translates to:
  /// **'Your account currently has no active trust or safety enforcement. Keep delivery proofs, payout confirmations, and marketplace communication accurate so this status remains normal.'**
  String get trustSafetyHealthyMessageLine1;

  /// No description provided for @trustSafetyHealthyMessageLine2.
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

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @settingsLanguageHelper.
  ///
  /// In en, this message translates to:
  /// **'Hindi is the launch default. You can switch to English here.'**
  String get settingsLanguageHelper;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageHindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get settingsLanguageHindi;

  /// No description provided for @settingsLanguageSavedEnglish.
  ///
  /// In en, this message translates to:
  /// **'Language saved: English'**
  String get settingsLanguageSavedEnglish;

  /// No description provided for @settingsLanguageSavedHindi.
  ///
  /// In en, this message translates to:
  /// **'Language saved: Hindi'**
  String get settingsLanguageSavedHindi;

  /// No description provided for @settingsLanguageSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not save your language preference right now. Retry shortly from settings.'**
  String get settingsLanguageSaveFailed;

  /// No description provided for @settingsLanguageSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving language preference...'**
  String get settingsLanguageSaving;

  /// Welcome message on trucker dashboard. Placeholder {fullName} is the user's full name.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {fullName}'**
  String truckerDashboardWelcomeBack(Object fullName);

  /// No description provided for @truckerDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucker Dashboard'**
  String get truckerDashboardTitle;

  /// No description provided for @truckerDashboardQuickActionTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'My Trips'**
  String get truckerDashboardQuickActionTripsLabel;

  /// No description provided for @truckerDashboardRecentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get truckerDashboardRecentActivityTitle;

  /// No description provided for @truckerDashboardReadinessNextStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Readiness and next steps'**
  String get truckerDashboardReadinessNextStepsTitle;

  /// No description provided for @truckerDashboardReadinessUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Readiness state unavailable'**
  String get truckerDashboardReadinessUnavailableTitle;

  /// No description provided for @truckerDashboardReadinessFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Your trucker readiness state is temporarily unavailable. Retry shortly to refresh verification and fleet readiness.'**
  String get truckerDashboardReadinessFailureMessage;

  /// No description provided for @commonVerificationPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get commonVerificationPendingTitle;

  /// No description provided for @commonOpenVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Open verification'**
  String get commonOpenVerificationAction;

  /// No description provided for @commonVerificationNeedsAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification needs attention'**
  String get commonVerificationNeedsAttentionTitle;

  /// No description provided for @truckerDashboardFixVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Fix verification'**
  String get truckerDashboardFixVerificationAction;

  /// No description provided for @truckerDashboardCompleteFleetVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete fleet and verification setup'**
  String get truckerDashboardCompleteFleetVerificationTitle;

  /// No description provided for @truckerDashboardOpenFleetVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Open fleet and verification'**
  String get truckerDashboardOpenFleetVerificationAction;

  /// No description provided for @truckerDashboardAddApproveFirstTruckTitle.
  ///
  /// In en, this message translates to:
  /// **'Add and approve your first truck'**
  String get truckerDashboardAddApproveFirstTruckTitle;

  /// No description provided for @truckerDashboardOpenFleetAction.
  ///
  /// In en, this message translates to:
  /// **'Open fleet'**
  String get truckerDashboardOpenFleetAction;

  /// No description provided for @truckerDashboardCompleteVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker verification'**
  String get truckerDashboardCompleteVerificationTitle;

  /// No description provided for @truckerDashboardLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your trucker dashboard'**
  String get truckerDashboardLoadFailureTitle;

  /// No description provided for @truckerDashboardLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your trucker dashboard right now. Retry shortly to refresh the latest KPIs and activity summary.'**
  String get truckerDashboardLoadFailureMessage;

  /// No description provided for @truckerDashboardSetupInProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup in progress'**
  String get truckerDashboardSetupInProgress;

  /// No description provided for @truckerDashboardApprovedTruckCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {# approved truck} other {# approved trucks}}'**
  String truckerDashboardApprovedTruckCount(int count);

  /// No description provided for @truckerDashboardStatActiveBidsLabel.
  ///
  /// In en, this message translates to:
  /// **'Active bids'**
  String get truckerDashboardStatActiveBidsLabel;

  /// No description provided for @truckerDashboardStatUpcomingTripsLabel.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trips'**
  String get truckerDashboardStatUpcomingTripsLabel;

  /// No description provided for @truckerDashboardStatInTransitLabel.
  ///
  /// In en, this message translates to:
  /// **'In-transit'**
  String get truckerDashboardStatInTransitLabel;

  /// No description provided for @truckerDashboardRecentActivityUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent activity unavailable'**
  String get truckerDashboardRecentActivityUnavailableTitle;

  /// No description provided for @truckerDashboardRecentActivityUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your latest booking, trip, and fleet activity right now.'**
  String get truckerDashboardRecentActivityUnavailableMessage;

  /// No description provided for @truckerDashboardNoRecentActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'No recent activity yet'**
  String get truckerDashboardNoRecentActivityTitle;

  /// No description provided for @truckerDashboardNoRecentActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your booking requests, trip movement, and fleet review updates will appear here once work begins.'**
  String get truckerDashboardNoRecentActivitySubtitle;

  /// No description provided for @truckerDashboardBookingActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking activity'**
  String get truckerDashboardBookingActivityTitle;

  /// No description provided for @truckerDashboardBookingActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} active bid waiting for supplier review} other {{count} active bids waiting for supplier review}}'**
  String truckerDashboardBookingActivitySubtitle(int count);

  /// No description provided for @truckerDashboardTripActivityTitle.
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

  /// No description provided for @truckerDashboardFleetReviewActivityTitle.
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

  /// No description provided for @truckerDashboardStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, open {open} clear {clear} moving {moving} tracked {tracked} attention {attention} other {attention}}'**
  String truckerDashboardStatusValue(String status);

  /// No description provided for @truckerDashboardReadinessSummaryUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucker readiness unavailable'**
  String get truckerDashboardReadinessSummaryUnavailableTitle;

  /// No description provided for @truckerDashboardReadinessSummaryUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your readiness summary right now.'**
  String get truckerDashboardReadinessSummaryUnavailableMessage;

  /// No description provided for @truckerDashboardProfileSetupInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile setup still in progress'**
  String get truckerDashboardProfileSetupInProgressTitle;

  /// No description provided for @truckerDashboardProfileSetupInProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your dashboard will show readiness details once your trucker profile finishes loading.'**
  String get truckerDashboardProfileSetupInProgressSubtitle;

  /// No description provided for @truckerDashboardVerificationStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get truckerDashboardVerificationStatusTitle;

  /// No description provided for @truckerDashboardDlLabel.
  ///
  /// In en, this message translates to:
  /// **'DL: {value}'**
  String truckerDashboardDlLabel(Object value);

  /// No description provided for @truckerDashboardFleetReadinessTitle.
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

  /// No description provided for @truckerDashboardReadyStatus.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get truckerDashboardReadyStatus;

  /// No description provided for @truckerDashboardActionNeededStatus.
  ///
  /// In en, this message translates to:
  /// **'action needed'**
  String get truckerDashboardActionNeededStatus;

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

  /// No description provided for @truckerTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get truckerTripsTitle;

  /// No description provided for @truckerTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track assigned trips, monitor proof deadlines, and hand off the right action at the right trip stage.'**
  String get truckerTripsSubtitle;

  /// No description provided for @tripStageValue.
  ///
  /// In en, this message translates to:
  /// **'{stage, select, assigned {Assigned} pickup_pending {Pickup pending} picked_up {Picked up} in_transit {In transit} delivered {Delivered} proof_submitted {Proof submitted} completed {Completed} disputed {Disputed} cancelled {Cancelled} other {Unknown}}'**
  String tripStageValue(String stage);

  /// No description provided for @proofStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, pod_uploaded {POD uploaded} lr_uploaded {LR uploaded} awaiting_pod {Awaiting POD} proof_submitted {Proof submitted} other {Proof pending}}'**
  String proofStatusValue(String status);

  /// No description provided for @truckerTripsLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trips'**
  String get truckerTripsLoadFailureTitle;

  /// No description provided for @truckerTripsLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your trips right now. Retry shortly to refresh the latest execution timeline.'**
  String get truckerTripsLoadFailureMessage;

  /// No description provided for @truckerTripsEmptyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get truckerTripsEmptyActiveTitle;

  /// No description provided for @truckerTripsEmptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get truckerTripsEmptyCompletedTitle;

  /// No description provided for @truckerTripsEmptyActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book a load and wait for supplier approval to start your first trip.'**
  String get truckerTripsEmptyActiveSubtitle;

  /// No description provided for @truckerTripsEmptyCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled trips will appear here after execution closes.'**
  String get truckerTripsEmptyCompletedSubtitle;

  /// No description provided for @truckerTripsEmptyActiveAction.
  ///
  /// In en, this message translates to:
  /// **'Find loads'**
  String get truckerTripsEmptyActiveAction;

  /// No description provided for @truckerTripsEmptyCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'View active trips'**
  String get truckerTripsEmptyCompletedAction;

  /// No description provided for @truckerTripDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get truckerTripDetailNotFoundTitle;

  /// No description provided for @truckerTripDetailNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This assigned trip is no longer available or you no longer have access to it.'**
  String get truckerTripDetailNotFoundSubtitle;

  /// No description provided for @truckerTripDetailBackToTripsAction.
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

  /// No description provided for @truckerFleetHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage truck readiness'**
  String get truckerFleetHeroTitle;

  /// No description provided for @truckerFleetHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track truck approval, review rejection guidance, and keep RC details current so booking-ready trucks stay available.'**
  String get truckerFleetHeroSubtitle;

  /// No description provided for @truckerFleetEditingTruckAction.
  ///
  /// In en, this message translates to:
  /// **'Editing truck'**
  String get truckerFleetEditingTruckAction;

  /// No description provided for @truckerFleetAddTruckAction.
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

  /// No description provided for @truckerFleetActionAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Truck action needs attention'**
  String get truckerFleetActionAttentionTitle;

  /// No description provided for @truckerFleetActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest truck action could not be completed right now. Review the truck details and retry shortly.'**
  String get truckerFleetActionFailureMessage;

  /// No description provided for @truckerFleetEditTruckTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit truck'**
  String get truckerFleetEditTruckTitle;

  /// No description provided for @truckerFleetAddOrUpdateTruckTitle.
  ///
  /// In en, this message translates to:
  /// **'Add or update truck'**
  String get truckerFleetAddOrUpdateTruckTitle;

  /// No description provided for @commonTruckNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck number'**
  String get commonTruckNumberLabel;

  /// No description provided for @truckerFleetTruckNumberHint.
  ///
  /// In en, this message translates to:
  /// **'MH12AB1234'**
  String get truckerFleetTruckNumberHint;

  /// No description provided for @truckerFleetBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get truckerFleetBodyTypeLabel;

  /// No description provided for @truckerFleetBodyTypeOption.
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String truckerFleetBodyTypeOption(Object value);

  /// No description provided for @truckerFleetTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres'**
  String get truckerFleetTyresLabel;

  /// No description provided for @truckerFleetTyresOption.
  ///
  /// In en, this message translates to:
  /// **'{tyres} tyres'**
  String truckerFleetTyresOption(int tyres);

  /// No description provided for @truckerFleetCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity (tonnes)'**
  String get truckerFleetCapacityLabel;

  /// No description provided for @truckerFleetCapacityHint.
  ///
  /// In en, this message translates to:
  /// **'25'**
  String get truckerFleetCapacityHint;

  /// No description provided for @truckerFleetRcDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'RC document'**
  String get truckerFleetRcDocumentTitle;

  /// No description provided for @truckerFleetRcUploadedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'RC image uploaded and linked to this truck draft.'**
  String get truckerFleetRcUploadedSubtitle;

  /// No description provided for @truckerFleetRcRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload the truck RC before saving this truck.'**
  String get truckerFleetRcRequiredSubtitle;

  /// No description provided for @truckerFleetUploadedStatus.
  ///
  /// In en, this message translates to:
  /// **'uploaded'**
  String get truckerFleetUploadedStatus;

  /// No description provided for @truckerFleetRequiredStatus.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get truckerFleetRequiredStatus;

  /// No description provided for @truckerFleetStoredPath.
  ///
  /// In en, this message translates to:
  /// **'Stored path: {path}'**
  String truckerFleetStoredPath(Object path);

  /// No description provided for @truckerFleetReplaceRcAction.
  ///
  /// In en, this message translates to:
  /// **'Replace RC document'**
  String get truckerFleetReplaceRcAction;

  /// No description provided for @truckerFleetUploadRcAction.
  ///
  /// In en, this message translates to:
  /// **'Upload RC document'**
  String get truckerFleetUploadRcAction;

  /// No description provided for @truckerFleetRcUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'RC uploaded successfully'**
  String get truckerFleetRcUploadedSuccess;

  /// No description provided for @truckerFleetRcUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'RC document updated successfully'**
  String get truckerFleetRcUpdatedSuccess;

  /// No description provided for @truckerFleetSaveTruckUpdatesAction.
  ///
  /// In en, this message translates to:
  /// **'Save truck updates'**
  String get truckerFleetSaveTruckUpdatesAction;

  /// No description provided for @truckerFleetSaveTruckAction.
  ///
  /// In en, this message translates to:
  /// **'Save truck'**
  String get truckerFleetSaveTruckAction;

  /// No description provided for @truckerFleetTruckUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Truck updated successfully'**
  String get truckerFleetTruckUpdatedSuccess;

  /// No description provided for @truckerFleetTruckAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Truck added successfully'**
  String get truckerFleetTruckAddedSuccess;

  /// No description provided for @truckerFleetMyTrucksTitle.
  ///
  /// In en, this message translates to:
  /// **'My trucks'**
  String get truckerFleetMyTrucksTitle;

  /// No description provided for @truckerFleetUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Fleet unavailable'**
  String get truckerFleetUnavailableTitle;

  /// No description provided for @truckerFleetLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your fleet right now. Retry shortly to refresh the latest truck readiness and approval state.'**
  String get truckerFleetLoadFailureMessage;

  /// No description provided for @truckerFleetNoTrucksTitle.
  ///
  /// In en, this message translates to:
  /// **'No trucks added yet'**
  String get truckerFleetNoTrucksTitle;

  /// No description provided for @truckerFleetNoTrucksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first truck with its RC document so trucker verification can progress toward approval.'**
  String get truckerFleetNoTrucksSubtitle;

  /// No description provided for @truckerFleetSelectRcSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload RC document'**
  String get truckerFleetSelectRcSourceTitle;

  /// No description provided for @commonTakePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get commonTakePhotoAction;

  /// No description provided for @commonChooseFromGalleryAction.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get commonChooseFromGalleryAction;

  /// No description provided for @truckerFleetRcUploadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the RC document right now. Try another image or retry shortly.'**
  String get truckerFleetRcUploadFailureMessage;

  /// No description provided for @truckerFleetSaveFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not save this truck right now. Review the truck details and retry shortly.'**
  String get truckerFleetSaveFailureMessage;

  /// No description provided for @truckerFleetTruckNumberConflictMessage.
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

  /// No description provided for @truckerFleetBlockedBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'This truck is blocked for approval-dependent booking workflows until review clears.'**
  String get truckerFleetBlockedBookingMessage;

  /// No description provided for @truckerFleetFixResubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Fix and resubmit truck'**
  String get truckerFleetFixResubmitAction;

  /// No description provided for @truckerFleetEditTruckAction.
  ///
  /// In en, this message translates to:
  /// **'Edit truck'**
  String get truckerFleetEditTruckAction;

  /// No description provided for @truckerFleetStatusLabelValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, pending {Pending review} verified {Approved} rejected {Rejected} edited_pending_reapproval {Pending reapproval} archived {Archived} unknown {Unknown} other {Unknown}}'**
  String truckerFleetStatusLabelValue(String status);

  /// No description provided for @truckerFleetStatusMessageValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, pending {Your truck is waiting for admin review. Approval is required before this truck can be used for booking.} verified {This truck is approved and available for verification-dependent workflows.} rejected {This truck was rejected. Review the guidance below and update the affected details or RC document.} edited_pending_reapproval {This truck stays visible, but recent edits sent it back for reapproval before it can be used again.} archived {This truck is archived and no longer available for normal booking workflows.} unknown {Truck review state is currently unavailable.} other {Truck review state is currently unavailable.}}'**
  String truckerFleetStatusMessageValue(String status);

  /// No description provided for @truckerFindLoadsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan compact freight cards, keep filters tight, and move quickly from route interest to load evaluation.'**
  String get truckerFindLoadsHeroSubtitle;

  /// No description provided for @truckerFindLoadsAdvancedFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get truckerFindLoadsAdvancedFiltersAction;

  /// No description provided for @truckerFindLoadsOriginHint.
  ///
  /// In en, this message translates to:
  /// **'Origin city'**
  String get truckerFindLoadsOriginHint;

  /// No description provided for @truckerFindLoadsDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'Destination city'**
  String get truckerFindLoadsDestinationHint;

  /// No description provided for @truckerFindLoadsMaterialHint.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get truckerFindLoadsMaterialHint;

  /// No description provided for @truckerFindLoadsSortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get truckerFindLoadsSortByLabel;

  /// No description provided for @truckerFindLoadsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get truckerFindLoadsSortNewest;

  /// No description provided for @truckerFindLoadsSortPriceHighToLow.
  ///
  /// In en, this message translates to:
  /// **'Price High>Low'**
  String get truckerFindLoadsSortPriceHighToLow;

  /// No description provided for @truckerFindLoadsSortPriceLowToHigh.
  ///
  /// In en, this message translates to:
  /// **'Price Low>High'**
  String get truckerFindLoadsSortPriceLowToHigh;

  /// No description provided for @truckerFindLoadsSortPickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup Date'**
  String get truckerFindLoadsSortPickupDate;

  /// No description provided for @truckerFindLoadsAllLoadsTab.
  ///
  /// In en, this message translates to:
  /// **'All Loads'**
  String get truckerFindLoadsAllLoadsTab;

  /// No description provided for @truckerFindLoadsSuperLoadsTab.
  ///
  /// In en, this message translates to:
  /// **'Super Loads'**
  String get truckerFindLoadsSuperLoadsTab;

  /// No description provided for @truckerFindLoadsLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load freight'**
  String get truckerFindLoadsLoadFailureTitle;

  /// No description provided for @truckerFindLoadsLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load marketplace freight right now. Retry shortly to refresh the latest load search results.'**
  String get truckerFindLoadsLoadFailureMessage;

  /// No description provided for @truckerFindLoadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No loads found'**
  String get truckerFindLoadsEmptyTitle;

  /// No description provided for @truckerFindLoadsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your city, material, or advanced filters to widen the marketplace search.'**
  String get truckerFindLoadsEmptySubtitle;

  /// No description provided for @truckerFindLoadsLoadMoreFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'More loads unavailable'**
  String get truckerFindLoadsLoadMoreFailureTitle;

  /// No description provided for @truckerFindLoadsLoadMoreFailureMessage.
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

  /// No description provided for @truckerFindLoadsSummarySuperLoads.
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

  /// No description provided for @truckerFindLoadsResetFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get truckerFindLoadsResetFiltersAction;

  /// No description provided for @truckerFindLoadsAnyBodyFallback.
  ///
  /// In en, this message translates to:
  /// **'Any body'**
  String get truckerFindLoadsAnyBodyFallback;

  /// No description provided for @truckerFindLoadsStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active {Active} assigned_partial {Assigned Partial} unknown {Unknown} other {Unknown}}'**
  String truckerFindLoadsStatusValue(String status);

  /// No description provided for @truckerFindLoadsAdvancedFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced filters'**
  String get truckerFindLoadsAdvancedFiltersTitle;

  /// No description provided for @truckerFindLoadsTruckBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck body type'**
  String get truckerFindLoadsTruckBodyTypeLabel;

  /// No description provided for @truckerFindLoadsBodyTypeValue.
  ///
  /// In en, this message translates to:
  /// **'{type, select, open {Open} trailer {Trailer} container {Container} tanker {Tanker} other {Unknown}}'**
  String truckerFindLoadsBodyTypeValue(String type);

  /// No description provided for @truckerFindLoadsTyreRequirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Tyre requirement'**
  String get truckerFindLoadsTyreRequirementTitle;

  /// No description provided for @truckerFindLoadsMinPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Min price (₹)'**
  String get truckerFindLoadsMinPriceLabel;

  /// No description provided for @truckerFindLoadsMaxPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Max price (₹)'**
  String get truckerFindLoadsMaxPriceLabel;

  /// No description provided for @truckerFindLoadsApplyFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get truckerFindLoadsApplyFiltersAction;

  /// No description provided for @truckerFindLoadsResetAdvancedFiltersAction.
  ///
  /// In en, this message translates to:
  /// **'Reset advanced filters'**
  String get truckerFindLoadsResetAdvancedFiltersAction;

  /// No description provided for @supplierPostLoadHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a supplier load'**
  String get supplierPostLoadHeroTitle;

  /// No description provided for @supplierPostLoadHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use one clean scrolling form to define route, cargo, vehicle requirements, pricing, and pickup timing.'**
  String get supplierPostLoadHeroSubtitle;

  /// No description provided for @supplierPostLoadHeroHelper.
  ///
  /// In en, this message translates to:
  /// **'Manual city entry still works if route services do not return a preview. Your form data stays intact on validation or submission failure.'**
  String get supplierPostLoadHeroHelper;

  /// No description provided for @supplierPostLoadPostingBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Posting is blocked'**
  String get supplierPostLoadPostingBlockedTitle;

  /// No description provided for @supplierPostLoadRouteTimingTitle.
  ///
  /// In en, this message translates to:
  /// **'Route and timing'**
  String get supplierPostLoadRouteTimingTitle;

  /// No description provided for @supplierPostLoadOriginCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin city'**
  String get supplierPostLoadOriginCityLabel;

  /// No description provided for @supplierPostLoadSearchCityHint.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get supplierPostLoadSearchCityHint;

  /// No description provided for @supplierPostLoadOriginExactLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin exact location'**
  String get supplierPostLoadOriginExactLocationLabel;

  /// No description provided for @supplierPostLoadOriginExactLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Warehouse / pickup point'**
  String get supplierPostLoadOriginExactLocationHint;

  /// No description provided for @supplierPostLoadDestinationCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination city'**
  String get supplierPostLoadDestinationCityLabel;

  /// No description provided for @supplierPostLoadDestinationExactLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination exact location'**
  String get supplierPostLoadDestinationExactLocationLabel;

  /// No description provided for @supplierPostLoadDestinationExactLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Drop point / delivery point'**
  String get supplierPostLoadDestinationExactLocationHint;

  /// No description provided for @supplierPostLoadPickupDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup date'**
  String get supplierPostLoadPickupDateLabel;

  /// No description provided for @supplierPostLoadRoutePreviewTitle.
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

  /// No description provided for @supplierPostLoadRoutePreviewUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Route preview unavailable'**
  String get supplierPostLoadRoutePreviewUnavailableTitle;

  /// No description provided for @supplierPostLoadRoutePreviewUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Route distance and duration could not be derived right now. You can still continue with manual city-based posting.'**
  String get supplierPostLoadRoutePreviewUnavailableMessage;

  /// No description provided for @supplierPostLoadCargoDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cargo details'**
  String get supplierPostLoadCargoDetailsTitle;

  /// No description provided for @supplierPostLoadMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get supplierPostLoadMaterialLabel;

  /// No description provided for @supplierPostLoadWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight (tonnes)'**
  String get supplierPostLoadWeightLabel;

  /// No description provided for @supplierPostLoadWeightHint.
  ///
  /// In en, this message translates to:
  /// **'22'**
  String get supplierPostLoadWeightHint;

  /// No description provided for @supplierPostLoadVehicleRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle requirements'**
  String get supplierPostLoadVehicleRequirementsTitle;

  /// No description provided for @supplierPostLoadTruckBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck body type'**
  String get supplierPostLoadTruckBodyTypeLabel;

  /// No description provided for @supplierPostLoadTyreRequirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Tyre requirement'**
  String get supplierPostLoadTyreRequirementTitle;

  /// No description provided for @commonAnyLabel.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get commonAnyLabel;

  /// No description provided for @supplierPostLoadTrucksNeededTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucks needed'**
  String get supplierPostLoadTrucksNeededTitle;

  /// No description provided for @supplierPostLoadTrucksNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucks needed'**
  String get supplierPostLoadTrucksNeededLabel;

  /// No description provided for @supplierPostLoadTrucksNeededHint.
  ///
  /// In en, this message translates to:
  /// **'1'**
  String get supplierPostLoadTrucksNeededHint;

  /// No description provided for @supplierPostLoadPricingScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing and schedule'**
  String get supplierPostLoadPricingScheduleTitle;

  /// No description provided for @supplierPostLoadPriceAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Price amount (₹)'**
  String get supplierPostLoadPriceAmountLabel;

  /// No description provided for @supplierPostLoadPriceAmountHint.
  ///
  /// In en, this message translates to:
  /// **'54000'**
  String get supplierPostLoadPriceAmountHint;

  /// No description provided for @supplierPostLoadPriceTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get supplierPostLoadPriceTypeTitle;

  /// No description provided for @supplierPostLoadPriceTypeValue.
  ///
  /// In en, this message translates to:
  /// **'{type, select, fixed {Fixed} per_ton {Per Ton} other {Unknown}}'**
  String supplierPostLoadPriceTypeValue(String type);

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

  /// No description provided for @supplierPostLoadReviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Review summary'**
  String get supplierPostLoadReviewSummaryTitle;

  /// No description provided for @supplierPostLoadOriginPending.
  ///
  /// In en, this message translates to:
  /// **'Origin pending'**
  String get supplierPostLoadOriginPending;

  /// No description provided for @supplierPostLoadDestinationPending.
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

  /// No description provided for @supplierPostLoadSubmissionFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission failed'**
  String get supplierPostLoadSubmissionFailedTitle;

  /// No description provided for @supplierPostLoadCompleteVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Complete verification to post load'**
  String get supplierPostLoadCompleteVerificationAction;

  /// No description provided for @supplierPostLoadCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load created successfully'**
  String get supplierPostLoadCreatedSuccess;

  /// No description provided for @supplierPostLoadSubmissionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not prepare this load submission right now. Review the load details and retry shortly.'**
  String get supplierPostLoadSubmissionFailureMessage;

  /// No description provided for @supplierPostLoadSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not create this load right now. Review the load details and retry shortly.'**
  String get supplierPostLoadSubmitFailureMessage;

  /// No description provided for @supplierPostLoadVerificationCheckingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking supplier verification before enabling load posting.'**
  String get supplierPostLoadVerificationCheckingMessage;

  /// No description provided for @supplierPostLoadVerificationUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Unable to confirm supplier verification right now. Retry shortly or open verification to review your trust status.'**
  String get supplierPostLoadVerificationUnavailableMessage;

  /// No description provided for @supplierPostLoadProfileUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Supplier profile is unavailable right now. Retry shortly before posting this load.'**
  String get supplierPostLoadProfileUnavailableMessage;

  /// No description provided for @supplierPostLoadVerificationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier verification before posting loads. Upload identity and business documents, then submit them for review.'**
  String get supplierPostLoadVerificationRequiredMessage;

  /// No description provided for @commonAadhaarNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number'**
  String get commonAadhaarNumberLabel;

  /// No description provided for @commonPanNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN number'**
  String get commonPanNumberLabel;

  /// No description provided for @verificationReadinessCheckAadhaarFrontPhoto.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar front photo'**
  String get verificationReadinessCheckAadhaarFrontPhoto;

  /// No description provided for @verificationReadinessCheckAadhaarBackPhoto.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar back photo'**
  String get verificationReadinessCheckAadhaarBackPhoto;

  /// No description provided for @verificationReadinessCheckPanPhoto.
  ///
  /// In en, this message translates to:
  /// **'PAN photo'**
  String get verificationReadinessCheckPanPhoto;

  /// No description provided for @commonCompanyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get commonCompanyNameLabel;

  /// No description provided for @verificationReadinessCheckBusinessLicenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Business licence number'**
  String get verificationReadinessCheckBusinessLicenceNumber;

  /// No description provided for @verificationReadinessCheckBusinessLicenceDocument.
  ///
  /// In en, this message translates to:
  /// **'Business licence document'**
  String get verificationReadinessCheckBusinessLicenceDocument;

  /// No description provided for @verificationReadinessCheckLocation.
  ///
  /// In en, this message translates to:
  /// **'Verification location'**
  String get verificationReadinessCheckLocation;

  /// No description provided for @verificationReadinessCheckTruckWithRcDocument.
  ///
  /// In en, this message translates to:
  /// **'Truck with RC document'**
  String get verificationReadinessCheckTruckWithRcDocument;

  /// No description provided for @verificationSubmitSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit for Verification'**
  String get verificationSubmitSectionTitle;

  /// No description provided for @verificationSubmitSectionTitleTrucker.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Submit for Verification'**
  String get verificationSubmitSectionTitleTrucker;

  /// No description provided for @verificationSubmitSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete all items below, then tap Submit to send your documents for admin review.'**
  String get verificationSubmitSectionSubtitle;

  /// No description provided for @verificationReadinessCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{doneCount} / {totalCount} completed'**
  String verificationReadinessCompletedCount(int doneCount, int totalCount);

  /// No description provided for @verificationOpenFleetHint.
  ///
  /// In en, this message translates to:
  /// **'Add or manage your truck with RC document from the fleet screen.'**
  String get verificationOpenFleetHint;

  /// No description provided for @supplierPostLoadSuggestionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{label} - {source}'**
  String supplierPostLoadSuggestionSubtitle(Object label, Object source);

  /// No description provided for @supplierVerificationPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification is under review. Keep documents ready in case the support team asks for clarification.'**
  String get supplierVerificationPendingMessage;

  /// No description provided for @supplierVerificationNeedsAttentionDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the latest verification feedback, update the required documents, and resubmit when you are ready.'**
  String get supplierVerificationNeedsAttentionDescription;

  /// No description provided for @supplierReviewVerification.
  ///
  /// In en, this message translates to:
  /// **'Review verification'**
  String get supplierReviewVerification;

  /// No description provided for @supplierFixVerification.
  ///
  /// In en, this message translates to:
  /// **'Fix verification'**
  String get supplierFixVerification;

  /// No description provided for @supplierCompleteSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your supplier setup'**
  String get supplierCompleteSetupTitle;

  /// No description provided for @supplierCompleteSetupMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete supplier verification and add your company details before using the full supplier workspace.'**
  String get supplierCompleteSetupMessage;

  /// No description provided for @supplierCompleteVerification.
  ///
  /// In en, this message translates to:
  /// **'Complete verification'**
  String get supplierCompleteVerification;

  /// No description provided for @supplierDashboardSuperLoadVerificationComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get supplierDashboardSuperLoadVerificationComplete;

  /// No description provided for @supplierDashboardSuperLoadBusinessLicenceOnFile.
  ///
  /// In en, this message translates to:
  /// **'Business licence on file'**
  String get supplierDashboardSuperLoadBusinessLicenceOnFile;

  /// No description provided for @supplierDashboardSuperLoadBusinessLicenceMissing.
  ///
  /// In en, this message translates to:
  /// **'Business licence missing'**
  String get supplierDashboardSuperLoadBusinessLicenceMissing;

  /// No description provided for @supplierDashboardSuperLoadCompanyAgeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Company-age readiness unavailable in current app data'**
  String get supplierDashboardSuperLoadCompanyAgeUnavailable;

  /// No description provided for @supplierLoadStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active {Active} assigned_partial {Assigned partial} assigned_full {Assigned full} in_transit {In transit} completed {Completed} filled_outside_app {Filled outside app} cancelled {Cancelled} expired {Expired} deactivated {Deactivated} unknown {Unknown} other {Unknown}}'**
  String supplierLoadStatusValue(String status);

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

  /// No description provided for @supplierDashboardOpenLoadsWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open loads workspace'**
  String get supplierDashboardOpenLoadsWorkspace;

  /// No description provided for @supplierDashboardSuperLoadStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, request_submitted {Request submitted} under_review {Under review} approved_payment_pending {Approved - payment pending} rejected {Rejected} expired_or_closed {Closed} active {Active} not_requested {Not requested} other {Not requested}}'**
  String supplierDashboardSuperLoadStatusValue(String status);

  /// No description provided for @supplierDashboardSuperLoadBadge.
  ///
  /// In en, this message translates to:
  /// **'Super Load - {status}'**
  String supplierDashboardSuperLoadBadge(Object status);

  /// No description provided for @supplierDashboardSuperLoadGuidanceValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, request_submitted {This Super Load request is submitted and waiting for admin review. The dedicated supplier-side eligibility controls are still pending, so current state is admin-managed.} under_review {This Super Load request is under admin review. Keep load details stable while review is in progress.} approved_payment_pending {This Super Load request is approved, but activation still depends on the off-platform payment confirmation step.} rejected {This Super Load request was not approved. Use support if you need follow-up while the dedicated supplier readiness surface is still pending.} expired_or_closed {This Super Load lifecycle is closed. Review the current load status and use support if follow-up is still needed.} active {This load is marked as a Super Load in the current lifecycle. Dedicated supplier-side eligibility controls are still being expanded.} not_requested {Super Load state is not active for this load.} other {Super Load state is not active for this load.}}'**
  String supplierDashboardSuperLoadGuidanceValue(String status);

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

  /// No description provided for @supplierLinkedTripTrackAction.
  ///
  /// In en, this message translates to:
  /// **'Track trip'**
  String get supplierLinkedTripTrackAction;

  /// No description provided for @supplierTripDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Detail'**
  String get supplierTripDetailTitle;

  /// No description provided for @supplierTripDetailLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load supplier trip detail'**
  String get supplierTripDetailLoadFailureTitle;

  /// No description provided for @supplierTripDetailLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this supplier trip detail right now. Retry shortly to refresh the latest trip status and proof review context.'**
  String get supplierTripDetailLoadFailureMessage;

  /// No description provided for @supplierTripDetailRatingFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The supplier rating state is temporarily unavailable. Retry shortly before submitting a rating.'**
  String get supplierTripDetailRatingFailureMessage;

  /// No description provided for @supplierTripDetailRatingSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this supplier rating right now. Review the rating and retry shortly.'**
  String get supplierTripDetailRatingSubmitFailureMessage;

  /// No description provided for @supplierTripDetailActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest supplier trip action could not be completed right now. Retry shortly after the trip detail refreshes.'**
  String get supplierTripDetailActionFailureMessage;

  /// No description provided for @supplierTripDetailActionSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that supplier trip action right now. Retry shortly after checking the latest trip status.'**
  String get supplierTripDetailActionSubmitFailureMessage;

  /// No description provided for @supplierTripDetailRatingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get supplierTripDetailRatingSectionTitle;

  /// No description provided for @supplierTripDetailRatingAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You already rated this trip.'**
  String get supplierTripDetailRatingAlreadySubmitted;

  /// No description provided for @supplierTripDetailRatingSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String supplierTripDetailRatingSubmittedOn(Object date);

  /// No description provided for @supplierTripDetailRatingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delivery is complete. Rate the trucker for this trip.'**
  String get supplierTripDetailRatingPrompt;

  /// No description provided for @supplierTripDetailCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get supplierTripDetailCommentLabel;

  /// No description provided for @supplierTripDetailCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Share anything useful about the trip outcome'**
  String get supplierTripDetailCommentHint;

  /// No description provided for @supplierTripDetailRatingUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Rating unavailable'**
  String get supplierTripDetailRatingUnavailableTitle;

  /// No description provided for @supplierTripDetailSubmitRatingAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get supplierTripDetailSubmitRatingAction;

  /// No description provided for @supplierTripDetailRatingSubmittedSuccess.
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
  /// **'Truck {truckNumber}'**
  String supplierTripDetailHeroSubtitle(Object truckNumber);

  /// No description provided for @supplierTripDetailMaterialTruckerSummary.
  ///
  /// In en, this message translates to:
  /// **'{material} - Trucker {truckerName}'**
  String supplierTripDetailMaterialTruckerSummary(
    Object material,
    Object truckerName,
  );

  /// No description provided for @commonNextStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get commonNextStepTitle;

  /// No description provided for @supplierTripDetailNextStepReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and confirm delivery'**
  String get supplierTripDetailNextStepReviewTitle;

  /// No description provided for @supplierTripDetailNextStepReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'The trucker has uploaded POD. Review the proof and confirm delivery to close the trip.'**
  String get supplierTripDetailNextStepReviewMessage;

  /// No description provided for @supplierTripDetailNextStepCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get supplierTripDetailNextStepCompletedTitle;

  /// No description provided for @supplierTripDetailNextStepCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Delivery has been confirmed. Rating and post-trip follow-up continue from this completed state.'**
  String get supplierTripDetailNextStepCompletedMessage;

  /// No description provided for @commonDisputeInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute in progress'**
  String get commonDisputeInProgressTitle;

  /// No description provided for @supplierTripDetailNextStepDisputedMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is under dispute review and awaits support or operations resolution.'**
  String get supplierTripDetailNextStepDisputedMessage;

  /// No description provided for @supplierTripDetailNextStepDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Track execution'**
  String get supplierTripDetailNextStepDefaultTitle;

  /// No description provided for @supplierTripDetailNextStepDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Review the current trip status, timestamps, and proof progress from this supplier execution view.'**
  String get supplierTripDetailNextStepDefaultMessage;

  /// No description provided for @supplierTripDetailDisputeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute status'**
  String get supplierTripDetailDisputeStatusTitle;

  /// No description provided for @supplierTripDetailDisputeStateRaised.
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

  /// No description provided for @supplierTripDetailActionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier trip action unavailable'**
  String get supplierTripDetailActionUnavailableTitle;

  /// No description provided for @supplierTripDetailProofDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Proof documents'**
  String get supplierTripDetailProofDocumentsTitle;

  /// No description provided for @supplierTripDetailPodPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'POD photo'**
  String get supplierTripDetailPodPhotoTitle;

  /// No description provided for @supplierTripDetailPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to open preview'**
  String get supplierTripDetailPreviewUnavailable;

  /// No description provided for @supplierTripDetailOpenPodPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Open POD Photo'**
  String get supplierTripDetailOpenPodPhotoAction;

  /// No description provided for @supplierTripDetailOpenLrDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Open LR Document'**
  String get supplierTripDetailOpenLrDocumentAction;

  /// No description provided for @supplierTripDetailActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get supplierTripDetailActionsTitle;

  /// No description provided for @supplierTripDetailConfirmDeliveryAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get supplierTripDetailConfirmDeliveryAction;

  /// No description provided for @supplierTripDetailConfirmDeliverySuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery confirmed. The trip is now completed.'**
  String get supplierTripDetailConfirmDeliverySuccess;

  /// No description provided for @supplierTripDetailDisputePodAction.
  ///
  /// In en, this message translates to:
  /// **'Dispute POD'**
  String get supplierTripDetailDisputePodAction;

  /// No description provided for @supplierTripDetailReportSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier trip - {routeLabel}'**
  String supplierTripDetailReportSourceLabel(Object routeLabel);

  /// No description provided for @commonRouteAndScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Route and schedule'**
  String get commonRouteAndScheduleTitle;

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

  /// No description provided for @supplierTripDetailTruckerTruckTitle.
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

  /// No description provided for @commonPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get commonPendingLabel;

  /// No description provided for @supplierTripDetailDisputeStatusGuidanceOpen.
  ///
  /// In en, this message translates to:
  /// **'Support has received this dispute and review should begin shortly. Keep the related support replies clear if more proof context is needed.'**
  String get supplierTripDetailDisputeStatusGuidanceOpen;

  /// No description provided for @supplierTripDetailDisputeStatusGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.'**
  String get supplierTripDetailDisputeStatusGuidanceInProgress;

  /// No description provided for @supplierTripDetailDisputeStatusGuidanceWaitingForUser.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting for your clarification or additional context. Reply on the related support ticket so the review can continue.'**
  String get supplierTripDetailDisputeStatusGuidanceWaitingForUser;

  /// No description provided for @supplierTripDetailDisputeStatusGuidanceResolved.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Check the linked support ticket outcome before raising any fresh follow-up issue.'**
  String get supplierTripDetailDisputeStatusGuidanceResolved;

  /// No description provided for @supplierTripDetailDisputeStatusGuidanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Keep following the related support ticket for the latest visible review updates.'**
  String get supplierTripDetailDisputeStatusGuidanceDefault;

  /// No description provided for @supplierTripDetailDisputeBannerWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute review waiting for your reply'**
  String get supplierTripDetailDisputeBannerWaitingTitle;

  /// No description provided for @supplierTripDetailDisputeBannerInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute review in progress'**
  String get supplierTripDetailDisputeBannerInProgressTitle;

  /// No description provided for @supplierTripDetailDisputeBannerNoSummaryMessage.
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

  /// No description provided for @supplierTripDetailSharedVisibilityClosed.
  ///
  /// In en, this message translates to:
  /// **'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.'**
  String get supplierTripDetailSharedVisibilityClosed;

  /// No description provided for @supplierTripDetailSharedVisibilityInProgress.
  ///
  /// In en, this message translates to:
  /// **'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'**
  String get supplierTripDetailSharedVisibilityInProgress;

  /// No description provided for @supplierTripDetailActionGuidanceClosed.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Check the recorded outcome on the linked support ticket before opening any genuinely new follow-up issue.'**
  String get supplierTripDetailActionGuidanceClosed;

  /// No description provided for @supplierTripDetailActionGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'No further delivery-confirmation action is available while this dispute stays under review. Follow the linked support ticket if support requests clarification or additional context.'**
  String get supplierTripDetailActionGuidanceInProgress;

  /// No description provided for @supplierTripDetailProofGuidanceClosed.
  ///
  /// In en, this message translates to:
  /// **'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.'**
  String get supplierTripDetailProofGuidanceClosed;

  /// No description provided for @supplierTripDetailProofGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'If this dispute depends on additional documents beyond the current single-image flow, summarize those missing proofs clearly in the related support ticket replies.'**
  String get supplierTripDetailProofGuidanceInProgress;

  /// No description provided for @verificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verificationTitle;

  /// No description provided for @verificationTitleSupplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier Verification'**
  String get verificationTitleSupplier;

  /// No description provided for @verificationTitleTrucker.
  ///
  /// In en, this message translates to:
  /// **'Trucker Verification'**
  String get verificationTitleTrucker;

  /// No description provided for @verificationLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load verification state'**
  String get verificationLoadFailureTitle;

  /// No description provided for @verificationLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your verification status right now. Retry shortly to refresh the latest verification state.'**
  String get verificationLoadFailureMessage;

  /// No description provided for @verificationDetailsUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification details unavailable'**
  String get verificationDetailsUnavailableTitle;

  /// No description provided for @verificationDetailsUnavailableSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We could not find the current verification record for this account. Please retry shortly.'**
  String get verificationDetailsUnavailableSubtitle;

  /// No description provided for @verificationResubmitForReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Resubmit for review'**
  String get verificationResubmitForReviewAction;

  /// No description provided for @verificationSubmitForReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get verificationSubmitForReviewAction;

  /// No description provided for @verificationResubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification resubmitted for review'**
  String get verificationResubmittedSuccess;

  /// No description provided for @verificationSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification submitted for review'**
  String get verificationSubmittedSuccess;

  /// No description provided for @verificationSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this verification packet right now. Review the current checklist and retry shortly.'**
  String get verificationSubmitFailureMessage;

  /// No description provided for @verificationWhatHappensNextMessage.
  ///
  /// In en, this message translates to:
  /// **'Your verification packet is queued for review. You do not need to resubmit anything unless our team rejects the case with a correction request.'**
  String get verificationWhatHappensNextMessage;

  /// No description provided for @verificationTimelinePacketSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Packet submitted'**
  String get verificationTimelinePacketSubmittedTitle;

  /// No description provided for @verificationTimelinePacketSubmittedDescription.
  ///
  /// In en, this message translates to:
  /// **'Your current documents and readiness data are already attached to the verification case.'**
  String get verificationTimelinePacketSubmittedDescription;

  /// No description provided for @verificationTimelineReviewInProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Review in progress'**
  String get verificationTimelineReviewInProgressTitle;

  /// No description provided for @verificationTimelineReviewInProgressTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get verificationTimelineReviewInProgressTimestamp;

  /// No description provided for @verificationTimelineReviewInProgressDescription.
  ///
  /// In en, this message translates to:
  /// **'Our operations team is reviewing the submitted identity, business, and readiness evidence.'**
  String get verificationTimelineReviewInProgressDescription;

  /// No description provided for @verificationTimelineNotifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'You will be notified'**
  String get verificationTimelineNotifiedTitle;

  /// No description provided for @verificationTimelineNotifiedTimestamp.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get verificationTimelineNotifiedTimestamp;

  /// No description provided for @verificationTimelineNotifiedDescription.
  ///
  /// In en, this message translates to:
  /// **'We will update your verification state here once the review is approved or sent back for corrections.'**
  String get verificationTimelineNotifiedDescription;

  /// No description provided for @verificationWizardStepPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get verificationWizardStepPhoto;

  /// No description provided for @verificationWizardStepIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get verificationWizardStepIdentity;

  /// No description provided for @verificationWizardStepTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get verificationWizardStepTruck;

  /// No description provided for @verificationWizardStepBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get verificationWizardStepBusiness;

  /// No description provided for @verificationWizardStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get verificationWizardStepReview;

  /// No description provided for @verificationWizardBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get verificationWizardBackAction;

  /// No description provided for @verificationWizardBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Back?'**
  String get verificationWizardBackTitle;

  /// No description provided for @verificationWizardBackMessage.
  ///
  /// In en, this message translates to:
  /// **'You will lose your progress on this step. Do you want to go back?'**
  String get verificationWizardBackMessage;

  /// No description provided for @verificationWizardSaveAndExitAction.
  ///
  /// In en, this message translates to:
  /// **'Save & exit'**
  String get verificationWizardSaveAndExitAction;

  /// No description provided for @verificationWizardExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit verification?'**
  String get verificationWizardExitTitle;

  /// No description provided for @verificationWizardExitMessage.
  ///
  /// In en, this message translates to:
  /// **'You can leave this flow now and continue later.'**
  String get verificationWizardExitMessage;

  /// No description provided for @verificationWizardExitAction.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get verificationWizardExitAction;

  /// No description provided for @verificationWizardProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get verificationWizardProfileTitle;

  /// No description provided for @verificationWizardProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear profile photo for verification.'**
  String get verificationWizardProfileSubtitle;

  /// No description provided for @verificationWizardProfileHint.
  ///
  /// In en, this message translates to:
  /// **'Use a clear, front-facing photo with good lighting.'**
  String get verificationWizardProfileHint;

  /// No description provided for @verificationWizardIdentityTitle.
  ///
  /// In en, this message translates to:
  /// **'Identity documents'**
  String get verificationWizardIdentityTitle;

  /// No description provided for @verificationWizardIdentitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add Aadhaar and PAN details with document uploads.'**
  String get verificationWizardIdentitySubtitle;

  /// No description provided for @verificationWizardPanDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'PAN document'**
  String get verificationWizardPanDocumentLabel;

  /// No description provided for @verificationWizardTruckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add one truck and upload its RC document.'**
  String get verificationWizardTruckSubtitle;

  /// No description provided for @verificationWizardTruckInfo.
  ///
  /// In en, this message translates to:
  /// **'At least one truck with an RC document is required for trucker verification.'**
  String get verificationWizardTruckInfo;

  /// No description provided for @verificationWizardBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type'**
  String get verificationWizardBodyTypeLabel;

  /// No description provided for @verificationWizardTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres'**
  String get verificationWizardTyresLabel;

  /// No description provided for @verificationWizardCapacityLabel.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get verificationWizardCapacityLabel;

  /// No description provided for @verificationWizardCapacityHint.
  ///
  /// In en, this message translates to:
  /// **'16'**
  String get verificationWizardCapacityHint;

  /// No description provided for @verificationWizardRcDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'RC document'**
  String get verificationWizardRcDocumentLabel;

  /// No description provided for @verificationWizardRequiredForVerification.
  ///
  /// In en, this message translates to:
  /// **'Required for verification'**
  String get verificationWizardRequiredForVerification;

  /// No description provided for @verificationWizardTruckPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck photo'**
  String get verificationWizardTruckPhotoLabel;

  /// No description provided for @verificationWizardTruckPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Optional photo of your truck'**
  String get verificationWizardTruckPhotoHint;

  /// No description provided for @verificationWizardBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Business details'**
  String get verificationWizardBusinessTitle;

  /// No description provided for @verificationWizardBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your company, licence, optional GST, and verification location.'**
  String get verificationWizardBusinessSubtitle;

  /// No description provided for @verificationWizardCompanyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your company name'**
  String get verificationWizardCompanyNameHint;

  /// No description provided for @verificationWizardLicenseNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get verificationWizardLicenseNumberLabel;

  /// No description provided for @verificationWizardLicenseNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your business licence number'**
  String get verificationWizardLicenseNumberHint;

  /// No description provided for @verificationWizardLicenseDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Business licence document'**
  String get verificationWizardLicenseDocumentLabel;

  /// No description provided for @verificationWizardGstDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'GST details'**
  String get verificationWizardGstDetailsTitle;

  /// No description provided for @verificationWizardGstDetailsAdded.
  ///
  /// In en, this message translates to:
  /// **'GST details added'**
  String get verificationWizardGstDetailsAdded;

  /// No description provided for @verificationWizardGstOptional.
  ///
  /// In en, this message translates to:
  /// **'GST is optional'**
  String get verificationWizardGstOptional;

  /// No description provided for @commonGstNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'GST number'**
  String get commonGstNumberLabel;

  /// No description provided for @verificationWizardGstCertificateLabel.
  ///
  /// In en, this message translates to:
  /// **'GST certificate'**
  String get verificationWizardGstCertificateLabel;

  /// No description provided for @verificationWizardSearchCityTitle.
  ///
  /// In en, this message translates to:
  /// **'Search city'**
  String get verificationWizardSearchCityTitle;

  /// No description provided for @verificationWizardSearchCityHint.
  ///
  /// In en, this message translates to:
  /// **'Type city name'**
  String get verificationWizardSearchCityHint;

  /// No description provided for @verificationWizardUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get verificationWizardUseCurrentLocation;

  /// No description provided for @verificationWizardNoCitiesFound.
  ///
  /// In en, this message translates to:
  /// **'No cities found for \"{query}\"'**
  String verificationWizardNoCitiesFound(Object query);

  /// No description provided for @verificationWizardTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get verificationWizardTryDifferentSearch;

  /// No description provided for @verificationWizardLocationServicesOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get verificationWizardLocationServicesOffTitle;

  /// No description provided for @verificationWizardLocationServicesOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable GPS/location services and try again.'**
  String get verificationWizardLocationServicesOffMessage;

  /// No description provided for @verificationWizardLocationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get verificationWizardLocationPermissionTitle;

  /// No description provided for @verificationWizardLocationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please allow location permission in app settings to continue.'**
  String get verificationWizardLocationPermissionMessage;

  /// No description provided for @verificationWizardOpenSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get verificationWizardOpenSettingsAction;

  /// No description provided for @verificationWizardCapturedViaGps.
  ///
  /// In en, this message translates to:
  /// **'Captured via GPS'**
  String get verificationWizardCapturedViaGps;

  /// No description provided for @verificationWizardAddedManually.
  ///
  /// In en, this message translates to:
  /// **'Added manually'**
  String get verificationWizardAddedManually;

  /// No description provided for @verificationWizardReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review and submit'**
  String get verificationWizardReviewTitle;

  /// No description provided for @verificationWizardReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your details before sending the verification packet.'**
  String get verificationWizardReviewSubtitle;

  /// No description provided for @verificationWizardReviewProfileUploaded.
  ///
  /// In en, this message translates to:
  /// **'Profile photo uploaded'**
  String get verificationWizardReviewProfileUploaded;

  /// No description provided for @verificationWizardReviewProfileMissing.
  ///
  /// In en, this message translates to:
  /// **'Profile photo missing'**
  String get verificationWizardReviewProfileMissing;

  /// No description provided for @verificationWizardReviewIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get verificationWizardReviewIdentity;

  /// No description provided for @verificationWizardReviewDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'Documents uploaded'**
  String get verificationWizardReviewDocumentsUploaded;

  /// No description provided for @verificationWizardReviewTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get verificationWizardReviewTruck;

  /// No description provided for @verificationWizardReviewRcUploaded.
  ///
  /// In en, this message translates to:
  /// **'RC document uploaded'**
  String get verificationWizardReviewRcUploaded;

  /// No description provided for @verificationWizardReviewTruckPhotoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Truck photo uploaded'**
  String get verificationWizardReviewTruckPhotoUploaded;

  /// No description provided for @verificationWizardReviewBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get verificationWizardReviewBusiness;

  /// No description provided for @verificationWizardReviewLicenseNumber.
  ///
  /// In en, this message translates to:
  /// **'License number'**
  String get verificationWizardReviewLicenseNumber;

  /// No description provided for @verificationWizardReviewLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get verificationWizardReviewLocation;

  /// No description provided for @verificationWizardReviewTimelineMessage.
  ///
  /// In en, this message translates to:
  /// **'Review usually completes after the submitted packet is checked by the team.'**
  String get verificationWizardReviewTimelineMessage;

  /// No description provided for @verificationWizardTermsText.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the information and uploaded documents are accurate and ready for verification review.'**
  String get verificationWizardTermsText;

  /// No description provided for @verificationWizardValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please complete the required fields before submitting.'**
  String get verificationWizardValidationError;

  /// No description provided for @verificationWizardUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Your session is unavailable. Please sign in again.'**
  String get verificationWizardUnauthorizedError;

  /// No description provided for @verificationWizardUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while submitting verification.'**
  String get verificationWizardUnknownError;

  /// No description provided for @verificationActionNeedsAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification action needs attention'**
  String get verificationActionNeedsAttentionTitle;

  /// No description provided for @verificationActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest verification action could not be completed right now. Review the current checklist and retry shortly.'**
  String get verificationActionFailureMessage;

  /// No description provided for @verificationLatestRejectionReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest rejection reason'**
  String get verificationLatestRejectionReasonTitle;

  /// No description provided for @verificationLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification location'**
  String get verificationLocationTitle;

  /// No description provided for @verificationLocationCapturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location captured'**
  String get verificationLocationCapturedTitle;

  /// No description provided for @verificationLocationRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Location still required'**
  String get verificationLocationRequiredTitle;

  /// No description provided for @verificationLocationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Supplier verification needs a city-level location capture before submission can proceed.'**
  String get verificationLocationRequiredMessage;

  /// No description provided for @verificationLocationCapturedStatus.
  ///
  /// In en, this message translates to:
  /// **'captured'**
  String get verificationLocationCapturedStatus;

  /// No description provided for @verificationLocationRequiredStatus.
  ///
  /// In en, this message translates to:
  /// **'required'**
  String get verificationLocationRequiredStatus;

  /// No description provided for @verificationLocationCapturedFooter.
  ///
  /// In en, this message translates to:
  /// **'Captured location remains attached to the supplier verification packet for review.'**
  String get verificationLocationCapturedFooter;

  /// No description provided for @verificationLocationCaptureGuidanceFooter.
  ///
  /// In en, this message translates to:
  /// **'We attempt GPS capture and resolve to the nearest city-level location when possible.'**
  String get verificationLocationCaptureGuidanceFooter;

  /// No description provided for @verificationRefreshLocationAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get verificationRefreshLocationAction;

  /// No description provided for @verificationCaptureLocationAction.
  ///
  /// In en, this message translates to:
  /// **'Capture location'**
  String get verificationCaptureLocationAction;

  /// No description provided for @verificationLocationCapturedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Verification location captured'**
  String get verificationLocationCapturedSuccess;

  /// No description provided for @verificationLocationFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not capture the verification location right now. Retry shortly from this verification screen.'**
  String get verificationLocationFailureMessage;

  /// No description provided for @verificationGpsDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS is disabled'**
  String get verificationGpsDisabledTitle;

  /// No description provided for @verificationGpsDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Please enable GPS in your device settings to capture your verification location.'**
  String get verificationGpsDisabledMessage;

  /// No description provided for @verificationOpenSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get verificationOpenSettingsAction;

  /// No description provided for @verificationPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get verificationPermissionDeniedTitle;

  /// No description provided for @verificationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Location access is permanently denied. Please enable location permission in your app settings to continue.'**
  String get verificationPermissionDeniedMessage;

  /// No description provided for @verificationOpenAppSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get verificationOpenAppSettingsAction;

  /// No description provided for @verificationManualLocationAction.
  ///
  /// In en, this message translates to:
  /// **'Enter location manually'**
  String get verificationManualLocationAction;

  /// No description provided for @verificationDocTypeAadhaarFront.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar front'**
  String get verificationDocTypeAadhaarFront;

  /// No description provided for @verificationDocTypeAadhaarBack.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar back'**
  String get verificationDocTypeAadhaarBack;

  /// No description provided for @verificationDocTypePan.
  ///
  /// In en, this message translates to:
  /// **'PAN card'**
  String get verificationDocTypePan;

  /// No description provided for @verificationDocTypeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get verificationDocTypeProfilePhoto;

  /// No description provided for @verificationDocTypeBusinessLicence.
  ///
  /// In en, this message translates to:
  /// **'Business licence'**
  String get verificationDocTypeBusinessLicence;

  /// No description provided for @verificationDocTypeGstCertificate.
  ///
  /// In en, this message translates to:
  /// **'GST certificate'**
  String get verificationDocTypeGstCertificate;

  /// No description provided for @verificationDocumentChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Document checklist'**
  String get verificationDocumentChecklistTitle;

  /// No description provided for @verificationDocumentUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{label} uploaded successfully'**
  String verificationDocumentUploadedSuccess(Object label);

  /// No description provided for @verificationDocumentUploadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not upload that verification document right now. Try another image or retry shortly.'**
  String get verificationDocumentUploadFailureMessage;

  /// No description provided for @verificationStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationStatusVerified;

  /// No description provided for @verificationStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verificationStatusRejected;

  /// No description provided for @verificationStatusUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get verificationStatusUnverified;

  /// No description provided for @verificationPacketDetailsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification packet details'**
  String get verificationPacketDetailsSectionTitle;

  /// No description provided for @verificationReadyTruckCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} ready {count, plural, =1{truck} other{trucks}}'**
  String verificationReadyTruckCountLabel(int count);

  /// No description provided for @verificationTruckReadyWithRcFooter.
  ///
  /// In en, this message translates to:
  /// **'You already have at least one complete truck packet with RC document attached.'**
  String get verificationTruckReadyWithRcFooter;

  /// No description provided for @verificationTruckPacketStillRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'A truck packet is still required'**
  String get verificationTruckPacketStillRequiredTitle;

  /// No description provided for @verificationTruckPacketStillRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Open your fleet to add the first truck or upload the RC document so trucker verification can be submitted as one packet.'**
  String get verificationTruckPacketStillRequiredMessage;

  /// No description provided for @verificationOpenFleetAction.
  ///
  /// In en, this message translates to:
  /// **'Open fleet'**
  String get verificationOpenFleetAction;

  /// No description provided for @verificationChatAndCallGatingBadge.
  ///
  /// In en, this message translates to:
  /// **'Chat and call gating'**
  String get verificationChatAndCallGatingBadge;

  /// No description provided for @verificationUploadSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload {documentLabel}'**
  String verificationUploadSourceTitle(Object documentLabel);

  /// No description provided for @verificationRejectionSummaryWithMarkers.
  ///
  /// In en, this message translates to:
  /// **'{summary}\n\nRejected documents are marked below with document-specific correction notes.'**
  String verificationRejectionSummaryWithMarkers(Object summary);

  /// No description provided for @verificationRejectionSummaryPacketLevel.
  ///
  /// In en, this message translates to:
  /// **'{summary}\n\nCurrent review feedback is returned as one packet-level reason when document-specific review markers are not provided.'**
  String verificationRejectionSummaryPacketLevel(Object summary);

  /// No description provided for @verificationPendingBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Your verification packet is already under review. You can keep browsing while review is pending.'**
  String get verificationPendingBannerDescription;

  /// No description provided for @verificationCompleteBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification complete'**
  String get verificationCompleteBannerTitle;

  /// No description provided for @verificationCompleteBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Your account is already verified. You can still review the uploaded document checklist below.'**
  String get verificationCompleteBannerDescription;

  /// No description provided for @verificationNeedsAttentionBannerDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the rejection summary, replace any affected documents, and resubmit the packet when ready.'**
  String get verificationNeedsAttentionBannerDescription;

  /// No description provided for @verificationNotSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification not submitted yet'**
  String get verificationNotSubmittedTitle;

  /// No description provided for @verificationNotSubmittedSupplierMessage.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar, PAN, profile photo, and business licence before submitting supplier verification.'**
  String get verificationNotSubmittedSupplierMessage;

  /// No description provided for @verificationNotSubmittedTruckerMessage.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar, PAN, profile photo, and ensure at least one approved truck exists before submitting trucker verification.'**
  String get verificationNotSubmittedTruckerMessage;

  /// No description provided for @verificationLockedStatusSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get verificationLockedStatusSectionTitle;

  /// No description provided for @verificationLockedStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, verified_title {Verified} pending_title {Under review} verified_message {Your verification has been approved. No action is needed right now.} pending_message {Your documents are being reviewed. You will be notified once the review is complete.} other {Unknown}}'**
  String verificationLockedStatusValue(String status);

  /// No description provided for @verificationSubmitLockedFooter.
  ///
  /// In en, this message translates to:
  /// **'Once submitted, your details stay locked until the admin completes the review.'**
  String get verificationSubmitLockedFooter;

  /// No description provided for @verificationDocumentStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, pending {pending} verified {verified} rejected {rejected} uploaded {uploaded} required {required} optional {optional} other {optional}}'**
  String verificationDocumentStatusValue(String status);

  /// No description provided for @verificationDocumentCorrectionFallback.
  ///
  /// In en, this message translates to:
  /// **'This document needs correction before verification can be resubmitted.'**
  String get verificationDocumentCorrectionFallback;

  /// No description provided for @verificationDocumentUploadedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Document uploaded and linked to your verification record.'**
  String get verificationDocumentUploadedSubtitle;

  /// No description provided for @verificationDocumentRequiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Required before verification can be submitted.'**
  String get verificationDocumentRequiredSubtitle;

  /// No description provided for @verificationDocumentOptionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional for the current verification packet.'**
  String get verificationDocumentOptionalSubtitle;

  /// No description provided for @verificationReviewNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Review note: {reason}'**
  String verificationReviewNoteLabel(Object reason);

  /// No description provided for @verificationStoredPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Stored path: {path}'**
  String verificationStoredPathLabel(Object path);

  /// No description provided for @verificationDocumentMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'This document is still missing from the current packet.'**
  String get verificationDocumentMissingMessage;

  /// No description provided for @verificationReplaceDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Replace document'**
  String get verificationReplaceDocumentAction;

  /// No description provided for @verificationUploadDocumentAction.
  ///
  /// In en, this message translates to:
  /// **'Upload document'**
  String get verificationUploadDocumentAction;

  /// No description provided for @truckerTripDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Detail'**
  String get truckerTripDetailTitle;

  /// No description provided for @truckerTripDetailLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trip detail'**
  String get truckerTripDetailLoadFailureTitle;

  /// No description provided for @truckerTripDetailLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this trip detail right now. Retry shortly to refresh the latest trip status and actions.'**
  String get truckerTripDetailLoadFailureMessage;

  /// No description provided for @truckerTripDetailRatingFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Your trip rating state is temporarily unavailable. Retry shortly before submitting a rating.'**
  String get truckerTripDetailRatingFailureMessage;

  /// No description provided for @truckerTripDetailRatingSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not submit your rating right now. Review the rating and retry shortly.'**
  String get truckerTripDetailRatingSubmitFailureMessage;

  /// No description provided for @truckerTripDetailActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest trip action could not be completed right now. Retry shortly after the trip detail refreshes.'**
  String get truckerTripDetailActionFailureMessage;

  /// No description provided for @truckerTripDetailActionSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that trip action right now. Retry shortly after checking the latest trip status.'**
  String get truckerTripDetailActionSubmitFailureMessage;

  /// No description provided for @truckerTripDetailLrUploadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the LR proof right now. Try another image or retry shortly.'**
  String get truckerTripDetailLrUploadFailureMessage;

  /// No description provided for @truckerTripDetailPodUploadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not upload the POD proof right now. Try another image or retry shortly.'**
  String get truckerTripDetailPodUploadFailureMessage;

  /// No description provided for @truckerTripDetailRatingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate this trip'**
  String get truckerTripDetailRatingSectionTitle;

  /// No description provided for @truckerTripDetailRatingAlreadySubmitted.
  ///
  /// In en, this message translates to:
  /// **'You already rated this trip.'**
  String get truckerTripDetailRatingAlreadySubmitted;

  /// No description provided for @truckerTripDetailRatingSubmittedOn.
  ///
  /// In en, this message translates to:
  /// **'Submitted on {date}'**
  String truckerTripDetailRatingSubmittedOn(Object date);

  /// No description provided for @truckerTripDetailRatingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delivery is complete. Rate the supplier for this trip.'**
  String get truckerTripDetailRatingPrompt;

  /// No description provided for @truckerTripDetailCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get truckerTripDetailCommentLabel;

  /// No description provided for @truckerTripDetailCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Share anything useful about the trip outcome'**
  String get truckerTripDetailCommentHint;

  /// No description provided for @truckerTripDetailRatingUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Rating unavailable'**
  String get truckerTripDetailRatingUnavailableTitle;

  /// No description provided for @truckerTripDetailSubmitRatingAction.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get truckerTripDetailSubmitRatingAction;

  /// No description provided for @truckerTripDetailRatingSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted successfully.'**
  String get truckerTripDetailRatingSubmittedSuccess;

  /// No description provided for @truckerTripDetailRatingStarTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} star{s}'**
  String truckerTripDetailRatingStarTooltip(Object count, Object s);

  /// No description provided for @truckerTripDetailAutoCompleteDueNow.
  ///
  /// In en, this message translates to:
  /// **'Auto-complete is due now.'**
  String get truckerTripDetailAutoCompleteDueNow;

  /// No description provided for @truckerTripDetailAutoCompleteDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String truckerTripDetailAutoCompleteDuration(Object hours, Object minutes);

  /// No description provided for @truckerTripDetailAutoCompleteIn.
  ///
  /// In en, this message translates to:
  /// **'Auto-complete in: {duration}'**
  String truckerTripDetailAutoCompleteIn(Object duration);

  /// No description provided for @truckerTripDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Truck {truckNumber}'**
  String truckerTripDetailHeroSubtitle(Object truckNumber);

  /// No description provided for @truckerTripDetailMaterialPickupSummary.
  ///
  /// In en, this message translates to:
  /// **'{material} - Pickup {pickupDate}'**
  String truckerTripDetailMaterialPickupSummary(
    Object material,
    Object pickupDate,
  );

  /// No description provided for @truckerTripDetailActionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip action unavailable'**
  String get truckerTripDetailActionUnavailableTitle;

  /// No description provided for @truckerTripDetailActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get truckerTripDetailActionsTitle;

  /// No description provided for @truckerTripDetailReplaceLrUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Replace LR Upload'**
  String get truckerTripDetailReplaceLrUploadAction;

  /// No description provided for @truckerTripDetailUploadLrOptionalAction.
  ///
  /// In en, this message translates to:
  /// **'Upload LR (Optional)'**
  String get truckerTripDetailUploadLrOptionalAction;

  /// No description provided for @truckerTripDetailUploadLrImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload LR image'**
  String get truckerTripDetailUploadLrImageTitle;

  /// No description provided for @truckerTripDetailLrUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'LR uploaded successfully.'**
  String get truckerTripDetailLrUploadedSuccess;

  /// No description provided for @truckerTripDetailUploadPodPhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Upload POD Photo'**
  String get truckerTripDetailUploadPodPhotoAction;

  /// No description provided for @truckerTripDetailUploadPodPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload POD photo'**
  String get truckerTripDetailUploadPodPhotoTitle;

  /// No description provided for @truckerTripDetailPodUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded successfully. Supplier confirmation is now pending.'**
  String get truckerTripDetailPodUploadedSuccess;

  /// No description provided for @truckerTripDetailCallSupplierAction.
  ///
  /// In en, this message translates to:
  /// **'Call Supplier'**
  String get truckerTripDetailCallSupplierAction;

  /// No description provided for @commonOpenInGoogleMapsAction.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get commonOpenInGoogleMapsAction;

  /// No description provided for @truckerTripDetailReportSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucker trip - {originLabel} to {destinationLabel}'**
  String truckerTripDetailReportSourceLabel(
    Object destinationLabel,
    Object originLabel,
  );

  /// No description provided for @truckerTripDetailReviewCountdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery review countdown'**
  String get truckerTripDetailReviewCountdownTitle;

  /// No description provided for @truckerTripDetailReviewCountdownMessage.
  ///
  /// In en, this message translates to:
  /// **'Supplier confirmation is pending. This trip auto-completes 48 hours after POD upload if no action is taken.'**
  String get truckerTripDetailReviewCountdownMessage;

  /// No description provided for @truckerTripDetailDisputeStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute status'**
  String get truckerTripDetailDisputeStatusTitle;

  /// No description provided for @truckerTripDetailDisputeStateRaised.
  ///
  /// In en, this message translates to:
  /// **'Current state: Dispute raised'**
  String get truckerTripDetailDisputeStateRaised;

  /// No description provided for @truckerTripDetailDisputeCurrentStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Current state: {status}'**
  String truckerTripDetailDisputeCurrentStateLabel(Object status);

  /// No description provided for @truckerTripDetailDisputeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'{category}'**
  String truckerTripDetailDisputeCategoryLabel(Object category);

  /// No description provided for @truckerTripDetailDisputeLastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String truckerTripDetailDisputeLastUpdatedLabel(Object date);

  /// No description provided for @truckerTripDetailDisputeStatusGuidanceOpen.
  ///
  /// In en, this message translates to:
  /// **'Support has received this dispute and review should begin shortly. Keep the related support replies clear if more proof context is needed.'**
  String get truckerTripDetailDisputeStatusGuidanceOpen;

  /// No description provided for @truckerTripDetailDisputeStatusGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'Support or operations are actively reviewing the dispute. Watch the related support ticket for visible updates or clarification requests.'**
  String get truckerTripDetailDisputeStatusGuidanceInProgress;

  /// No description provided for @truckerTripDetailDisputeStatusGuidanceWaitingForUser.
  ///
  /// In en, this message translates to:
  /// **'Support is waiting for your clarification or additional context. Reply on the related support ticket so the review can continue.'**
  String get truckerTripDetailDisputeStatusGuidanceWaitingForUser;

  /// No description provided for @truckerTripDetailDisputeStatusGuidanceResolved.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Check the linked support ticket outcome before raising any fresh follow-up issue.'**
  String get truckerTripDetailDisputeStatusGuidanceResolved;

  /// No description provided for @truckerTripDetailDisputeStatusGuidanceDefault.
  ///
  /// In en, this message translates to:
  /// **'Keep following the related support ticket for the latest visible review updates.'**
  String get truckerTripDetailDisputeStatusGuidanceDefault;

  /// No description provided for @truckerTripDetailDisputeBannerWaitingTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute waiting for your reply'**
  String get truckerTripDetailDisputeBannerWaitingTitle;

  /// No description provided for @truckerTripDetailDisputeBannerNoSummaryMessage.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip. The trip stays open while support or operations review the submitted proof and delivery context. Both sides can see dispute status, but sensitive evidence may remain restricted during review.'**
  String get truckerTripDetailDisputeBannerNoSummaryMessage;

  /// No description provided for @truckerTripDetailDisputeBannerWaitingMessage.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip under {category} and is waiting on your clarification or proof. Sensitive evidence may remain restricted during review.'**
  String truckerTripDetailDisputeBannerWaitingMessage(Object category);

  /// No description provided for @truckerTripDetailDisputeBannerClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'A dispute raised on this trip under {category} has reached a final review outcome. Recorded status updates remain visible, while sensitive evidence may remain restricted.'**
  String truckerTripDetailDisputeBannerClosedMessage(Object category);

  /// No description provided for @truckerTripDetailDisputeBannerInProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'A dispute has been raised on this trip under {category}. The trip stays open while support or operations review the delivery context, and sensitive evidence may remain restricted during review.'**
  String truckerTripDetailDisputeBannerInProgressMessage(Object category);

  /// No description provided for @truckerTripDetailDisputeActionGuidanceClosed.
  ///
  /// In en, this message translates to:
  /// **'This dispute has reached a final review state. Keep this trip detail for the recorded outcome and start a fresh follow-up only if a genuinely new issue appears.'**
  String get truckerTripDetailDisputeActionGuidanceClosed;

  /// No description provided for @truckerTripDetailDisputeActionGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'No further trip-stage action is available until the dispute is resolved. Keep this trip detail for status updates and follow any support instructions if requested.'**
  String get truckerTripDetailDisputeActionGuidanceInProgress;

  /// No description provided for @truckerTripDetailSharedVisibilityClosed.
  ///
  /// In en, this message translates to:
  /// **'Both parties can still follow the recorded dispute category, final workflow state, and visible support replies kept on this trip dispute.'**
  String get truckerTripDetailSharedVisibilityClosed;

  /// No description provided for @truckerTripDetailSharedVisibilityInProgress.
  ///
  /// In en, this message translates to:
  /// **'Both parties can follow the dispute category, workflow status, and support replies that are intentionally visible during review.'**
  String get truckerTripDetailSharedVisibilityInProgress;

  /// No description provided for @truckerTripDetailProofGuidanceClosed.
  ///
  /// In en, this message translates to:
  /// **'If you believe important proof was not considered before closure, start a fresh support follow-up only when you have genuinely new dispute context to raise.'**
  String get truckerTripDetailProofGuidanceClosed;

  /// No description provided for @truckerTripDetailProofGuidanceInProgress.
  ///
  /// In en, this message translates to:
  /// **'If additional supporting proofs are not attached in the current single-image flow, keep the related support replies clear so support and operations know what else to review.'**
  String get truckerTripDetailProofGuidanceInProgress;

  /// No description provided for @truckerTripDetailCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get truckerTripDetailCancelledTitle;

  /// No description provided for @truckerTripDetailCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled before completion. No further execution actions are available, and this detail now serves as a record of the cancelled movement.'**
  String get truckerTripDetailCancelledMessage;

  /// No description provided for @truckerTripDetailCancellationSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation summary'**
  String get truckerTripDetailCancellationSummaryTitle;

  /// No description provided for @truckerTripDetailCancellationCurrentState.
  ///
  /// In en, this message translates to:
  /// **'Current state: cancelled'**
  String get truckerTripDetailCancellationCurrentState;

  /// No description provided for @truckerTripDetailRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Route: {route}'**
  String truckerTripDetailRouteLabel(Object route);

  /// No description provided for @truckerTripDetailMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material: {material}'**
  String truckerTripDetailMaterialLabel(Object material);

  /// No description provided for @truckerTripDetailAssignedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned on: {dateTime}'**
  String truckerTripDetailAssignedOnLabel(Object dateTime);

  /// No description provided for @truckerTripDetailCancellationFollowupMessage.
  ///
  /// In en, this message translates to:
  /// **'If support or operations share follow-up instructions, use this trip reference and the existing trip timeline for context.'**
  String get truckerTripDetailCancellationFollowupMessage;

  /// No description provided for @truckerTripDetailTripSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip summary'**
  String get truckerTripDetailTripSummaryTitle;

  /// No description provided for @truckerTripDetailTripSummaryMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is complete and closed out from the execution workflow.'**
  String get truckerTripDetailTripSummaryMessage;

  /// No description provided for @truckerTripDetailCompletedOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed on: {dateTime}'**
  String truckerTripDetailCompletedOnLabel(Object dateTime);

  /// No description provided for @truckerTripDetailOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin: {origin}'**
  String truckerTripDetailOriginLabel(Object origin);

  /// No description provided for @truckerTripDetailDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination: {destination}'**
  String truckerTripDetailDestinationLabel(Object destination);

  /// No description provided for @truckerTripDetailDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String truckerTripDetailDistanceLabel(Object distance);

  /// No description provided for @truckerTripDetailDriveTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Drive time: {minutes} min'**
  String truckerTripDetailDriveTimeLabel(Object minutes);

  /// No description provided for @truckerTripDetailAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned: {dateTime}'**
  String truckerTripDetailAssignedLabel(Object dateTime);

  /// No description provided for @truckerTripDetailStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started: {dateTime}'**
  String truckerTripDetailStartedLabel(Object dateTime);

  /// No description provided for @truckerTripDetailDeliveredLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivered: {dateTime}'**
  String truckerTripDetailDeliveredLabel(Object dateTime);

  /// No description provided for @truckerTripDetailPodUploadedLabel.
  ///
  /// In en, this message translates to:
  /// **'POD uploaded: {dateTime}'**
  String truckerTripDetailPodUploadedLabel(Object dateTime);

  /// No description provided for @truckerTripDetailCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed: {dateTime}'**
  String truckerTripDetailCompletedLabel(Object dateTime);

  /// No description provided for @truckerTripDetailTruckSupplierTitle.
  ///
  /// In en, this message translates to:
  /// **'Truck and supplier'**
  String get truckerTripDetailTruckSupplierTitle;

  /// No description provided for @truckerTripDetailTruckNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck number: {truckNumber}'**
  String truckerTripDetailTruckNumberLabel(Object truckNumber);

  /// No description provided for @truckerTripDetailBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type: {bodyType}'**
  String truckerTripDetailBodyTypeLabel(Object bodyType);

  /// No description provided for @truckerTripDetailTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {tyres}'**
  String truckerTripDetailTyresLabel(Object tyres);

  /// No description provided for @truckerTripDetailSupplierLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplier: {name}'**
  String truckerTripDetailSupplierLabel(Object name);

  /// No description provided for @truckerTripDetailCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company: {companyName}'**
  String truckerTripDetailCompanyLabel(Object companyName);

  /// No description provided for @truckerTripDetailMobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile: {mobile}'**
  String truckerTripDetailMobileLabel(Object mobile);

  /// No description provided for @truckerTripDetailHeadToPickupAction.
  ///
  /// In en, this message translates to:
  /// **'Head to pickup'**
  String get truckerTripDetailHeadToPickupAction;

  /// No description provided for @truckerTripDetailHeadToPickupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Pickup movement started. The supplier can now see that you are heading to pickup.'**
  String get truckerTripDetailHeadToPickupSuccess;

  /// No description provided for @truckerTripDetailCargoLoadedAction.
  ///
  /// In en, this message translates to:
  /// **'Cargo Loaded'**
  String get truckerTripDetailCargoLoadedAction;

  /// No description provided for @truckerTripDetailCargoLoadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cargo loading has been confirmed for this trip.'**
  String get truckerTripDetailCargoLoadedSuccess;

  /// No description provided for @truckerTripDetailStartTripAction.
  ///
  /// In en, this message translates to:
  /// **'Start Trip'**
  String get truckerTripDetailStartTripAction;

  /// No description provided for @truckerTripDetailStartTripSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip started successfully. This load is now in transit.'**
  String get truckerTripDetailStartTripSuccess;

  /// No description provided for @truckerTripDetailMarkDeliveredAction.
  ///
  /// In en, this message translates to:
  /// **'Mark Delivered'**
  String get truckerTripDetailMarkDeliveredAction;

  /// No description provided for @truckerTripDetailMarkDeliveredSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery recorded. Upload POD in the next step to complete the proof flow.'**
  String get truckerTripDetailMarkDeliveredSuccess;

  /// No description provided for @truckerTripDetailNextStepAssignedTitle.
  ///
  /// In en, this message translates to:
  /// **'Head to pickup'**
  String get truckerTripDetailNextStepAssignedTitle;

  /// No description provided for @truckerTripDetailNextStepAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is assigned and waiting for the pickup movement to begin.'**
  String get truckerTripDetailNextStepAssignedMessage;

  /// No description provided for @truckerTripDetailNextStepPickupPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm loading'**
  String get truckerTripDetailNextStepPickupPendingTitle;

  /// No description provided for @truckerTripDetailNextStepPickupPendingMessage.
  ///
  /// In en, this message translates to:
  /// **'The trip is at pickup and waiting for cargo loading confirmation.'**
  String get truckerTripDetailNextStepPickupPendingMessage;

  /// No description provided for @truckerTripDetailNextStepPickedUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Start the trip'**
  String get truckerTripDetailNextStepPickedUpTitle;

  /// No description provided for @truckerTripDetailNextStepPickedUpMessage.
  ///
  /// In en, this message translates to:
  /// **'Cargo is loaded and the next operational milestone is moving into transit.'**
  String get truckerTripDetailNextStepPickedUpMessage;

  /// No description provided for @truckerTripDetailNextStepInTransitTitle.
  ///
  /// In en, this message translates to:
  /// **'Reach destination'**
  String get truckerTripDetailNextStepInTransitTitle;

  /// No description provided for @truckerTripDetailNextStepInTransitMessage.
  ///
  /// In en, this message translates to:
  /// **'The trip is in transit and the next milestone is delivery confirmation.'**
  String get truckerTripDetailNextStepInTransitMessage;

  /// No description provided for @truckerTripDetailNextStepDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload POD'**
  String get truckerTripDetailNextStepDeliveredTitle;

  /// No description provided for @truckerTripDetailNextStepDeliveredMessage.
  ///
  /// In en, this message translates to:
  /// **'Delivery is recorded and proof of delivery is the next required step.'**
  String get truckerTripDetailNextStepDeliveredMessage;

  /// No description provided for @truckerTripDetailNextStepProofSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Await supplier confirmation'**
  String get truckerTripDetailNextStepProofSubmittedTitle;

  /// No description provided for @truckerTripDetailNextStepProofSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Proof is submitted and the trip is waiting for supplier review or auto-completion.'**
  String get truckerTripDetailNextStepProofSubmittedMessage;

  /// No description provided for @truckerTripDetailNextStepCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip completed'**
  String get truckerTripDetailNextStepCompletedTitle;

  /// No description provided for @truckerTripDetailNextStepCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Execution is closed and this trip now serves as a historical record.'**
  String get truckerTripDetailNextStepCompletedMessage;

  /// No description provided for @truckerTripDetailNextStepDisputedMessage.
  ///
  /// In en, this message translates to:
  /// **'A dispute is active on this trip and operational review is required before closure.'**
  String get truckerTripDetailNextStepDisputedMessage;

  /// No description provided for @truckerTripDetailNextStepCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get truckerTripDetailNextStepCancelledTitle;

  /// No description provided for @truckerTripDetailNextStepCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip was cancelled before normal completion and no further execution steps remain.'**
  String get truckerTripDetailNextStepCancelledMessage;

  /// No description provided for @truckerTripDetailNextStepDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Check execution status'**
  String get truckerTripDetailNextStepDefaultTitle;

  /// No description provided for @truckerTripDetailNextStepDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'Review the current trip state and recent timestamps to understand the latest movement.'**
  String get truckerTripDetailNextStepDefaultMessage;

  /// No description provided for @supplierRaiseDisputeTitle.
  ///
  /// In en, this message translates to:
  /// **'Raise Dispute'**
  String get supplierRaiseDisputeTitle;

  /// No description provided for @supplierRaiseDisputeTripUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip detail unavailable'**
  String get supplierRaiseDisputeTripUnavailableTitle;

  /// No description provided for @supplierRaiseDisputeTripLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this trip detail right now. Retry shortly to review the latest dispute context.'**
  String get supplierRaiseDisputeTripLoadFailureMessage;

  /// No description provided for @supplierRaiseDisputeHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute delivery proof'**
  String get supplierRaiseDisputeHeroTitle;

  /// No description provided for @supplierRaiseDisputeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explain what is wrong with the submitted POD so the dispute can be opened against the current trip and routed into support review.'**
  String get supplierRaiseDisputeHeroSubtitle;

  /// No description provided for @supplierRaiseDisputeTripBadge.
  ///
  /// In en, this message translates to:
  /// **'Trip under review'**
  String get supplierRaiseDisputeTripBadge;

  /// No description provided for @supplierRaiseDisputeHeroSummary.
  ///
  /// In en, this message translates to:
  /// **'{routeLabel} - {material}'**
  String supplierRaiseDisputeHeroSummary(Object material, Object routeLabel);

  /// No description provided for @supplierRaiseDisputeHeroGuidance.
  ///
  /// In en, this message translates to:
  /// **'Select the dispute category that best matches the issue, add a written explanation, and optionally attach one supporting evidence image for support review.'**
  String get supplierRaiseDisputeHeroGuidance;

  /// No description provided for @supplierRaiseDisputePartialContextUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Some trip detail context is unavailable'**
  String get supplierRaiseDisputePartialContextUnavailableTitle;

  /// No description provided for @supplierRaiseDisputeTripContextFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Some dispute context is temporarily unavailable. Retry shortly to refresh the latest trip detail and proof review state.'**
  String get supplierRaiseDisputeTripContextFailureMessage;

  /// No description provided for @supplierRaiseDisputeSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute summary'**
  String get supplierRaiseDisputeSummaryTitle;

  /// No description provided for @supplierRaiseDisputeTripRouteLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip route: {routeLabel}'**
  String supplierRaiseDisputeTripRouteLabel(Object routeLabel);

  /// No description provided for @supplierRaiseDisputeTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Truck: {truckNumber}'**
  String supplierRaiseDisputeTruckLabel(Object truckNumber);

  /// No description provided for @supplierRaiseDisputeTruckerLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucker: {truckerName}'**
  String supplierRaiseDisputeTruckerLabel(Object truckerName);

  /// No description provided for @supplierRaiseDisputeCurrentStageLabel.
  ///
  /// In en, this message translates to:
  /// **'Current stage: {stageLabel}'**
  String supplierRaiseDisputeCurrentStageLabel(Object stageLabel);

  /// No description provided for @supplierRaiseDisputeSubmissionBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute submission blocked'**
  String get supplierRaiseDisputeSubmissionBlockedTitle;

  /// No description provided for @supplierRaiseDisputeSubmissionBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can only raise this POD dispute while the trip is in proof submitted state.'**
  String get supplierRaiseDisputeSubmissionBlockedMessage;

  /// No description provided for @supplierRaiseDisputeSubmissionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Dispute submission unavailable'**
  String get supplierRaiseDisputeSubmissionUnavailableTitle;

  /// No description provided for @supplierRaiseDisputeSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this dispute right now. Review the dispute details and retry shortly.'**
  String get supplierRaiseDisputeSubmitFailureMessage;

  /// No description provided for @supplierRaiseDisputeProblemTitle.
  ///
  /// In en, this message translates to:
  /// **'What is wrong with the POD?'**
  String get supplierRaiseDisputeProblemTitle;

  /// No description provided for @supplierRaiseDisputeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Dispute category'**
  String get supplierRaiseDisputeCategoryLabel;

  /// No description provided for @supplierRaiseDisputeReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Dispute reason'**
  String get supplierRaiseDisputeReasonLabel;

  /// No description provided for @supplierRaiseDisputeReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Explain what is wrong with the submitted proof and what support should review.'**
  String get supplierRaiseDisputeReasonHint;

  /// No description provided for @supplierRaiseDisputeHelpfulDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Helpful details to include'**
  String get supplierRaiseDisputeHelpfulDetailsTitle;

  /// No description provided for @supplierRaiseDisputeHelpfulDetailsMessage.
  ///
  /// In en, this message translates to:
  /// **'The current dispute flow still accepts one optional image. Use these prompts to capture any second or third proof in your written explanation.'**
  String get supplierRaiseDisputeHelpfulDetailsMessage;

  /// No description provided for @supplierRaiseDisputeEvidenceOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence (optional)'**
  String get supplierRaiseDisputeEvidenceOptionalTitle;

  /// No description provided for @supplierRaiseDisputeNoEvidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'No evidence image attached yet. You can attach one supporting image in the current flow.'**
  String get supplierRaiseDisputeNoEvidenceAttached;

  /// No description provided for @supplierRaiseDisputeEvidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'One supporting evidence image is attached for review.'**
  String get supplierRaiseDisputeEvidenceAttached;

  /// No description provided for @supplierRaiseDisputeVisibleToOtherPartyMessage.
  ///
  /// In en, this message translates to:
  /// **'Visible to the other party: dispute category and status only. Raw evidence may stay restricted during review.'**
  String get supplierRaiseDisputeVisibleToOtherPartyMessage;

  /// No description provided for @supplierRaiseDisputeUseCameraAction.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get supplierRaiseDisputeUseCameraAction;

  /// No description provided for @supplierRaiseDisputeChoosePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get supplierRaiseDisputeChoosePhotoAction;

  /// No description provided for @supplierRaiseDisputeRemoveEvidenceAction.
  ///
  /// In en, this message translates to:
  /// **'Remove evidence'**
  String get supplierRaiseDisputeRemoveEvidenceAction;

  /// No description provided for @supplierRaiseDisputeSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit dispute'**
  String get supplierRaiseDisputeSubmitAction;

  /// No description provided for @supplierRaiseDisputeCategoryError.
  ///
  /// In en, this message translates to:
  /// **'Select a valid dispute category'**
  String get supplierRaiseDisputeCategoryError;

  /// No description provided for @supplierRaiseDisputeReasonError.
  ///
  /// In en, this message translates to:
  /// **'Explain the POD problem in at least 10 characters'**
  String get supplierRaiseDisputeReasonError;

  /// No description provided for @supplierRaiseDisputeSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Dispute submitted. Support ticket created for review.'**
  String get supplierRaiseDisputeSubmittedSuccess;

  /// No description provided for @supplierRaiseDisputeAttachmentAttachedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached successfully'**
  String get supplierRaiseDisputeAttachmentAttachedSuccess;

  /// No description provided for @commonAttachmentFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not attach that evidence image right now. Try another image or retry shortly.'**
  String get commonAttachmentFailureMessage;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceLoadedQuantityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: the loaded bilty or loading proof that shows the dispatched quantity. Only one image can be attached right now.'**
  String get supplierRaiseDisputeEvidenceGuidanceLoadedQuantityMismatch;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceUnloadedQuantityMismatch.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: the unloaded bilty, weighbridge slip, or unloading proof showing the received quantity. Only one image can be attached right now.'**
  String get supplierRaiseDisputeEvidenceGuidanceUnloadedQuantityMismatch;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceDocumentMismatch.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: the clearest POD, bilty, or related proof image showing the document mismatch. Only one image can be attached right now.'**
  String get supplierRaiseDisputeEvidenceGuidanceDocumentMismatch;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceNonPayment.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one proof image that best supports the non-payment claim. Full payment workflow evidence still remains limited in the current flow.'**
  String get supplierRaiseDisputeEvidenceGuidanceNonPayment;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceFakePayoutProof.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one payout-proof image that best shows the fake or inconsistent payment claim.'**
  String get supplierRaiseDisputeEvidenceGuidanceFakePayoutProof;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceDelayOrNoShow.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one supporting image or screenshot that best shows the delay or no-show context.'**
  String get supplierRaiseDisputeEvidenceGuidanceDelayOrNoShow;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceDamageOrShortage.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one image that best shows the damage, shortage, or affected goods at delivery.'**
  String get supplierRaiseDisputeEvidenceGuidanceDamageOrShortage;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceAbusiveBehavior.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one supporting image or screenshot if it is safe and relevant to the abusive-behavior claim.'**
  String get supplierRaiseDisputeEvidenceGuidanceAbusiveBehavior;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceSpamOrScam.
  ///
  /// In en, this message translates to:
  /// **'Recommended evidence: one screenshot or proof image that best supports the spam or scam report.'**
  String get supplierRaiseDisputeEvidenceGuidanceSpamOrScam;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceOther.
  ///
  /// In en, this message translates to:
  /// **'Provide a clear explanation of the dispute and attach the single most relevant supporting image if needed.'**
  String get supplierRaiseDisputeEvidenceGuidanceOther;

  /// No description provided for @supplierRaiseDisputeEvidenceGuidanceFallback.
  ///
  /// In en, this message translates to:
  /// **'Attach the single most relevant supporting image available for this dispute category.'**
  String get supplierRaiseDisputeEvidenceGuidanceFallback;

  /// No description provided for @supplierRaiseDisputeBestImageGuidanceDocumentCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose the clearest single document image where quantities, signatures, stamps, or POD details are readable in one frame.'**
  String get supplierRaiseDisputeBestImageGuidanceDocumentCategory;

  /// No description provided for @supplierRaiseDisputeBestImageGuidancePaymentCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose the single screenshot or payout-proof image that most clearly shows the mismatch, missing payment, or fake confirmation.'**
  String get supplierRaiseDisputeBestImageGuidancePaymentCategory;

  /// No description provided for @supplierRaiseDisputeBestImageGuidanceTimelineCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose the single screenshot or photo that gives the strongest timeline or behavior context in one image.'**
  String get supplierRaiseDisputeBestImageGuidanceTimelineCategory;

  /// No description provided for @supplierRaiseDisputeBestImageGuidanceDamageCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose the single image that best shows the damaged goods, shortage, or delivered condition at handover.'**
  String get supplierRaiseDisputeBestImageGuidanceDamageCategory;

  /// No description provided for @supplierRaiseDisputeBestImageGuidanceOther.
  ///
  /// In en, this message translates to:
  /// **'Choose the one image that gives support the strongest proof of the issue you describe in your written reason.'**
  String get supplierRaiseDisputeBestImageGuidanceOther;

  /// No description provided for @supplierRaiseDisputeBestImageGuidanceFallback.
  ///
  /// In en, this message translates to:
  /// **'Choose the one clearest image that gives support the strongest proof to review first.'**
  String get supplierRaiseDisputeBestImageGuidanceFallback;

  /// No description provided for @supplierRaiseDisputePromptDispatchQuantityShownOnProof.
  ///
  /// In en, this message translates to:
  /// **'Dispatch quantity shown on proof:'**
  String get supplierRaiseDisputePromptDispatchQuantityShownOnProof;

  /// No description provided for @supplierRaiseDisputePromptQuantityActuallyChallenged.
  ///
  /// In en, this message translates to:
  /// **'Quantity actually challenged:'**
  String get supplierRaiseDisputePromptQuantityActuallyChallenged;

  /// No description provided for @supplierRaiseDisputePromptOtherLoadingProofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Other loading proof not attached but reviewed by support:'**
  String get supplierRaiseDisputePromptOtherLoadingProofNotAttached;

  /// No description provided for @supplierRaiseDisputePromptQuantityReceivedAtUnloading.
  ///
  /// In en, this message translates to:
  /// **'Quantity received at unloading:'**
  String get supplierRaiseDisputePromptQuantityReceivedAtUnloading;

  /// No description provided for @supplierRaiseDisputePromptQuantityExpectedFromDispatchProof.
  ///
  /// In en, this message translates to:
  /// **'Quantity expected from dispatch proof:'**
  String get supplierRaiseDisputePromptQuantityExpectedFromDispatchProof;

  /// No description provided for @supplierRaiseDisputePromptExtraUnloadProofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Extra unload proof not attached but available:'**
  String get supplierRaiseDisputePromptExtraUnloadProofNotAttached;

  /// No description provided for @supplierRaiseDisputePromptDocumentFieldDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Document field that does not match:'**
  String get supplierRaiseDisputePromptDocumentFieldDoesNotMatch;

  /// No description provided for @supplierRaiseDisputePromptCorrectTripOrPodDetailShouldBe.
  ///
  /// In en, this message translates to:
  /// **'Correct trip or POD detail should be:'**
  String get supplierRaiseDisputePromptCorrectTripOrPodDetailShouldBe;

  /// No description provided for @supplierRaiseDisputePromptOtherRelatedDocumentNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Other related document not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherRelatedDocumentNotAttached;

  /// No description provided for @supplierRaiseDisputePromptAmountStillUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Amount still unpaid:'**
  String get supplierRaiseDisputePromptAmountStillUnpaid;

  /// No description provided for @supplierRaiseDisputePromptPaymentDueDateOrMilestone.
  ///
  /// In en, this message translates to:
  /// **'Payment due date or milestone:'**
  String get supplierRaiseDisputePromptPaymentDueDateOrMilestone;

  /// No description provided for @supplierRaiseDisputePromptOtherPaymentProofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Other payment proof not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherPaymentProofNotAttached;

  /// No description provided for @supplierRaiseDisputePromptWhyPayoutProofLooksFake.
  ///
  /// In en, this message translates to:
  /// **'Why the payout proof looks fake or inconsistent:'**
  String get supplierRaiseDisputePromptWhyPayoutProofLooksFake;

  /// No description provided for @supplierRaiseDisputePromptWhatPaymentStatusShouldBe.
  ///
  /// In en, this message translates to:
  /// **'What payment status should be instead:'**
  String get supplierRaiseDisputePromptWhatPaymentStatusShouldBe;

  /// No description provided for @supplierRaiseDisputePromptOtherProofOrChatContextNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Other proof or chat context not attached:'**
  String get supplierRaiseDisputePromptOtherProofOrChatContextNotAttached;

  /// No description provided for @supplierRaiseDisputePromptExpectedReportingOrArrivalTime.
  ///
  /// In en, this message translates to:
  /// **'Expected reporting or arrival time:'**
  String get supplierRaiseDisputePromptExpectedReportingOrArrivalTime;

  /// No description provided for @supplierRaiseDisputePromptActualDelayOrNoShowOutcome.
  ///
  /// In en, this message translates to:
  /// **'Actual delay or no-show outcome:'**
  String get supplierRaiseDisputePromptActualDelayOrNoShowOutcome;

  /// No description provided for @supplierRaiseDisputePromptOtherTimingProofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Other timing proof not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherTimingProofNotAttached;

  /// No description provided for @supplierRaiseDisputePromptGoodsAffectedByDamageOrShortage.
  ///
  /// In en, this message translates to:
  /// **'Goods affected by damage or shortage:'**
  String get supplierRaiseDisputePromptGoodsAffectedByDamageOrShortage;

  /// No description provided for @supplierRaiseDisputePromptQuantityOrConditionDifferenceNoticed.
  ///
  /// In en, this message translates to:
  /// **'Quantity or condition difference noticed:'**
  String get supplierRaiseDisputePromptQuantityOrConditionDifferenceNoticed;

  /// No description provided for @supplierRaiseDisputePromptOtherSupportingProofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Other supporting proof not attached but relevant:'**
  String get supplierRaiseDisputePromptOtherSupportingProofNotAttached;

  /// No description provided for @supplierRaiseDisputePromptWhatHappenedDuringIncident.
  ///
  /// In en, this message translates to:
  /// **'What happened during the incident:'**
  String get supplierRaiseDisputePromptWhatHappenedDuringIncident;

  /// No description provided for @supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred.
  ///
  /// In en, this message translates to:
  /// **'When or where the behavior occurred:'**
  String get supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred;

  /// No description provided for @supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred.
  ///
  /// In en, this message translates to:
  /// **'What scam or spam behavior occurred:'**
  String get supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred;

  /// No description provided for @supplierRaiseDisputePromptWhatMisleadingClaimWasMade.
  ///
  /// In en, this message translates to:
  /// **'What misleading claim was made:'**
  String get supplierRaiseDisputePromptWhatMisleadingClaimWasMade;

  /// No description provided for @supplierRaiseDisputePromptMainIssueSupportShouldReview.
  ///
  /// In en, this message translates to:
  /// **'Main issue support should review:'**
  String get supplierRaiseDisputePromptMainIssueSupportShouldReview;

  /// No description provided for @supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded.
  ///
  /// In en, this message translates to:
  /// **'What outcome or correction is needed:'**
  String get supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded;

  /// No description provided for @supplierRaiseDisputePromptStrongestMissingProofNotAttached.
  ///
  /// In en, this message translates to:
  /// **'Strongest missing proof not attached:'**
  String get supplierRaiseDisputePromptStrongestMissingProofNotAttached;

  /// No description provided for @supplierRaiseDisputeChecklistLoadedReadableQuantity.
  ///
  /// In en, this message translates to:
  /// **'Keep the dispatched quantity readable in the uploaded image.'**
  String get supplierRaiseDisputeChecklistLoadedReadableQuantity;

  /// No description provided for @supplierRaiseDisputeChecklistLoadedPreferBilty.
  ///
  /// In en, this message translates to:
  /// **'Include the bilty, loading slip, or marked proof instead of a distant photo.'**
  String get supplierRaiseDisputeChecklistLoadedPreferBilty;

  /// No description provided for @supplierRaiseDisputeChecklistLoadedUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to describe any additional document context not visible in the image.'**
  String get supplierRaiseDisputeChecklistLoadedUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistUnloadedKeepReceivedQuantity.
  ///
  /// In en, this message translates to:
  /// **'Keep the received quantity or unload record readable in the image.'**
  String get supplierRaiseDisputeChecklistUnloadedKeepReceivedQuantity;

  /// No description provided for @supplierRaiseDisputeChecklistUnloadedPreferWeighbridge.
  ///
  /// In en, this message translates to:
  /// **'Prefer a weighbridge slip, unload bilty, or marked proof over a generic cargo photo.'**
  String get supplierRaiseDisputeChecklistUnloadedPreferWeighbridge;

  /// No description provided for @supplierRaiseDisputeChecklistUnloadedUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain any missing second document that cannot fit in the current single-image flow.'**
  String get supplierRaiseDisputeChecklistUnloadedUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistDocumentReadableFields.
  ///
  /// In en, this message translates to:
  /// **'Make sure key document fields are readable in one frame.'**
  String get supplierRaiseDisputeChecklistDocumentReadableFields;

  /// No description provided for @supplierRaiseDisputeChecklistDocumentPreferSpecificPage.
  ///
  /// In en, this message translates to:
  /// **'Prefer the specific POD or bilty page where the mismatch appears.'**
  String get supplierRaiseDisputeChecklistDocumentPreferSpecificPage;

  /// No description provided for @supplierRaiseDisputeChecklistDocumentUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to describe what field or proof does not match the trip.'**
  String get supplierRaiseDisputeChecklistDocumentUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistPaymentPreferClearestScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Prefer the clearest single payout-related screenshot or proof image.'**
  String get supplierRaiseDisputeChecklistPaymentPreferClearestScreenshot;

  /// No description provided for @supplierRaiseDisputeChecklistPaymentUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain what payment is still missing and when it was due.'**
  String get supplierRaiseDisputeChecklistPaymentUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistPaymentUploadStrongestFirst.
  ///
  /// In en, this message translates to:
  /// **'If multiple proofs exist, upload the strongest one first and summarize the rest in text.'**
  String get supplierRaiseDisputeChecklistPaymentUploadStrongestFirst;

  /// No description provided for @supplierRaiseDisputeChecklistFakePreferScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Prefer the payout screenshot or proof image that most clearly appears fake or inconsistent.'**
  String get supplierRaiseDisputeChecklistFakePreferScreenshot;

  /// No description provided for @supplierRaiseDisputeChecklistFakeUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain what is suspicious about the proof.'**
  String get supplierRaiseDisputeChecklistFakeUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistFakeSummarizeChatContext.
  ///
  /// In en, this message translates to:
  /// **'If supporting chat context exists, summarize it in text when it cannot fit in the single-image flow.'**
  String get supplierRaiseDisputeChecklistFakeSummarizeChatContext;

  /// No description provided for @supplierRaiseDisputeChecklistDelayChooseClearestTiming.
  ///
  /// In en, this message translates to:
  /// **'Choose the clearest screenshot or photo showing the missed timing or no-show context.'**
  String get supplierRaiseDisputeChecklistDelayChooseClearestTiming;

  /// No description provided for @supplierRaiseDisputeChecklistDelayUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain the expected time and the actual outcome.'**
  String get supplierRaiseDisputeChecklistDelayUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistDelayKeepFocusedImage.
  ///
  /// In en, this message translates to:
  /// **'Keep the uploaded image focused on timing/location evidence instead of unrelated media.'**
  String get supplierRaiseDisputeChecklistDelayKeepFocusedImage;

  /// No description provided for @supplierRaiseDisputeChecklistDamageChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose the image that most clearly shows the damage or shortage at delivery.'**
  String get supplierRaiseDisputeChecklistDamageChooseImage;

  /// No description provided for @supplierRaiseDisputeChecklistDamageKeepAffectedGoods.
  ///
  /// In en, this message translates to:
  /// **'Keep the affected goods or missing quantity context visible in the frame.'**
  String get supplierRaiseDisputeChecklistDamageKeepAffectedGoods;

  /// No description provided for @supplierRaiseDisputeChecklistDamageUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain what cannot be shown in the single uploaded image.'**
  String get supplierRaiseDisputeChecklistDamageUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistAbusiveUploadIfSafe.
  ///
  /// In en, this message translates to:
  /// **'Upload evidence only if it is safe and relevant to the case.'**
  String get supplierRaiseDisputeChecklistAbusiveUploadIfSafe;

  /// No description provided for @supplierRaiseDisputeChecklistAbusivePreferClearestScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Prefer the clearest screenshot or image tied directly to the abusive incident.'**
  String get supplierRaiseDisputeChecklistAbusivePreferClearestScreenshot;

  /// No description provided for @supplierRaiseDisputeChecklistAbusiveUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain the sequence of events without adding sensitive internal notes.'**
  String get supplierRaiseDisputeChecklistAbusiveUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistSpamChooseScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Choose the screenshot or image that most clearly shows the scam or spam behavior.'**
  String get supplierRaiseDisputeChecklistSpamChooseScreenshot;

  /// No description provided for @supplierRaiseDisputeChecklistSpamPreferStrongestProof.
  ///
  /// In en, this message translates to:
  /// **'Prefer the strongest proof of deception instead of a partial conversation fragment.'**
  String get supplierRaiseDisputeChecklistSpamPreferStrongestProof;

  /// No description provided for @supplierRaiseDisputeChecklistSpamUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to summarize any extra scam context that cannot fit in one image.'**
  String get supplierRaiseDisputeChecklistSpamUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistOtherChooseStrongestImage.
  ///
  /// In en, this message translates to:
  /// **'Choose the one strongest image that supports your explanation.'**
  String get supplierRaiseDisputeChecklistOtherChooseStrongestImage;

  /// No description provided for @supplierRaiseDisputeChecklistOtherKeepIssueReadable.
  ///
  /// In en, this message translates to:
  /// **'Keep the issue-specific detail readable in the uploaded image.'**
  String get supplierRaiseDisputeChecklistOtherKeepIssueReadable;

  /// No description provided for @supplierRaiseDisputeChecklistOtherUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to explain the rest of the evidence that cannot fit in the current flow.'**
  String get supplierRaiseDisputeChecklistOtherUseWrittenReason;

  /// No description provided for @supplierRaiseDisputeChecklistFallbackChooseClearestImage.
  ///
  /// In en, this message translates to:
  /// **'Choose the one clearest supporting image available.'**
  String get supplierRaiseDisputeChecklistFallbackChooseClearestImage;

  /// No description provided for @supplierRaiseDisputeChecklistFallbackKeepReadableProof.
  ///
  /// In en, this message translates to:
  /// **'Keep the important proof readable in the frame.'**
  String get supplierRaiseDisputeChecklistFallbackKeepReadableProof;

  /// No description provided for @supplierRaiseDisputeChecklistFallbackUseWrittenReason.
  ///
  /// In en, this message translates to:
  /// **'Use the written reason to describe any additional evidence not visible in the image.'**
  String get supplierRaiseDisputeChecklistFallbackUseWrittenReason;

  /// No description provided for @reportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssueTitle;

  /// No description provided for @reportIssueHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Report spam, scam, or abuse'**
  String get reportIssueHeroTitle;

  /// No description provided for @reportIssueHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a trust-safety ticket tied to the current operational context so support can review the issue quickly.'**
  String get reportIssueHeroSubtitle;

  /// No description provided for @reportIssueHeroMessage.
  ///
  /// In en, this message translates to:
  /// **'Attach one evidence image if you have it. The report still submits through the live support-ticket workflow using the linked load/trip context, and can also capture fake payout-proof or non-payment issues.'**
  String get reportIssueHeroMessage;

  /// No description provided for @reportIssueSubmissionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Report submission unavailable'**
  String get reportIssueSubmissionUnavailableTitle;

  /// No description provided for @reportIssueFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'This report could not be prepared or submitted right now. Review the linked context and try again shortly.'**
  String get reportIssueFailureMessage;

  /// No description provided for @reportIssueLinkedContextTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked context'**
  String get reportIssueLinkedContextTitle;

  /// No description provided for @reportIssueSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {sourceLabel}'**
  String reportIssueSourceLabel(Object sourceLabel);

  /// No description provided for @reportIssueRelatedLoadLabel.
  ///
  /// In en, this message translates to:
  /// **'Related load linked'**
  String get reportIssueRelatedLoadLabel;

  /// No description provided for @reportIssueRelatedTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Related trip linked'**
  String get reportIssueRelatedTripLabel;

  /// No description provided for @reportIssueNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get reportIssueNotLinked;

  /// No description provided for @reportIssueDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportIssueDetailsTitle;

  /// No description provided for @reportIssueTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Issue type'**
  String get reportIssueTypeLabel;

  /// No description provided for @reportIssueWhatHappenedLabel.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get reportIssueWhatHappenedLabel;

  /// No description provided for @reportIssueWhatHappenedHint.
  ///
  /// In en, this message translates to:
  /// **'Explain the spam, fake proof, non-payment, payout deception, or abusive behavior that support should review.'**
  String get reportIssueWhatHappenedHint;

  /// No description provided for @reportIssueHelpfulDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Helpful details to include'**
  String get reportIssueHelpfulDetailsTitle;

  /// No description provided for @reportIssueEvidenceOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Evidence (required)'**
  String get reportIssueEvidenceOptionalTitle;

  /// No description provided for @reportIssueNoEvidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'Attach one evidence image before submitting this report.'**
  String get reportIssueNoEvidenceAttached;

  /// No description provided for @reportIssueEvidenceAttached.
  ///
  /// In en, this message translates to:
  /// **'One evidence image is attached for review.'**
  String get reportIssueEvidenceAttached;

  /// No description provided for @reportIssueUseCameraAction.
  ///
  /// In en, this message translates to:
  /// **'Use camera'**
  String get reportIssueUseCameraAction;

  /// No description provided for @reportIssueChoosePhotoAction.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get reportIssueChoosePhotoAction;

  /// No description provided for @reportIssueRemoveEvidenceAction.
  ///
  /// In en, this message translates to:
  /// **'Remove evidence'**
  String get reportIssueRemoveEvidenceAction;

  /// No description provided for @reportIssueSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get reportIssueSubmitAction;

  /// No description provided for @reportIssueSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted successfully'**
  String get reportIssueSubmittedSuccess;

  /// No description provided for @reportIssueSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this report right now. Review the details and retry shortly.'**
  String get reportIssueSubmitFailureMessage;

  /// No description provided for @reportIssueAttachmentAttachedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Evidence attached successfully'**
  String get reportIssueAttachmentAttachedSuccess;

  /// No description provided for @reportIssueCategorySpamOrScamLabel.
  ///
  /// In en, this message translates to:
  /// **'Spam or scam'**
  String get reportIssueCategorySpamOrScamLabel;

  /// No description provided for @reportIssueCategoryAbusiveBehaviorLabel.
  ///
  /// In en, this message translates to:
  /// **'Abusive behavior'**
  String get reportIssueCategoryAbusiveBehaviorLabel;

  /// No description provided for @reportIssueCategoryFakePayoutProofLabel.
  ///
  /// In en, this message translates to:
  /// **'Fake payout proof'**
  String get reportIssueCategoryFakePayoutProofLabel;

  /// No description provided for @reportIssueCategoryNonPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Non-payment'**
  String get reportIssueCategoryNonPaymentLabel;

  /// No description provided for @reportIssueCategoryGuidanceSpamOrScam.
  ///
  /// In en, this message translates to:
  /// **'Explain the spam, scam, or misleading behavior clearly and attach one evidence image that helps support review the report.'**
  String get reportIssueCategoryGuidanceSpamOrScam;

  /// No description provided for @reportIssueCategoryGuidanceAbusiveBehavior.
  ///
  /// In en, this message translates to:
  /// **'Describe the abusive or unsafe behavior clearly, including where it happened and any context support should review.'**
  String get reportIssueCategoryGuidanceAbusiveBehavior;

  /// No description provided for @reportIssueCategoryGuidanceFakePayoutProof.
  ///
  /// In en, this message translates to:
  /// **'Explain why the payout proof looks fake or misleading and attach one evidence image with the most useful payment context you can share.'**
  String get reportIssueCategoryGuidanceFakePayoutProof;

  /// No description provided for @reportIssueCategoryGuidanceNonPayment.
  ///
  /// In en, this message translates to:
  /// **'Describe the non-payment issue clearly, including what was due, what follow-up already happened, and attach one evidence image with the strongest payment proof you can share.'**
  String get reportIssueCategoryGuidanceNonPayment;

  /// No description provided for @supportCreateTicketScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Create support ticket'**
  String get supportCreateTicketScreenTitle;

  /// No description provided for @supportCreateTicketHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Open a support request'**
  String get supportCreateTicketHeroTitle;

  /// No description provided for @supportCreateTicketHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue clearly so support can route it faster and keep your follow-up thread linked to the right context.'**
  String get supportCreateTicketHeroSubtitle;

  /// No description provided for @supportCreateTicketHeroMessage.
  ///
  /// In en, this message translates to:
  /// **'You can optionally include a related load or trip id if the issue is tied to a specific operational flow. You can also attach one evidence image if it helps support review the issue faster.'**
  String get supportCreateTicketHeroMessage;

  /// No description provided for @supportCreateTicketFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Support request needs attention'**
  String get supportCreateTicketFailureTitle;

  /// No description provided for @supportCreateTicketFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Your support request could not be prepared or submitted right now. Review the issue details and try again shortly.'**
  String get supportCreateTicketFailureMessage;

  /// No description provided for @supportCreateTicketDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket details'**
  String get supportCreateTicketDetailsTitle;

  /// No description provided for @supportComposeCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get supportComposeCategoryLabel;

  /// No description provided for @supportComposeCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get supportComposeCategoryGeneral;

  /// No description provided for @supportComposeCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get supportComposeCategoryAccount;

  /// No description provided for @supportComposeCategoryLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get supportComposeCategoryLoad;

  /// No description provided for @supportComposeCategoryTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get supportComposeCategoryTrip;

  /// No description provided for @supportComposeCategoryPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get supportComposeCategoryPayment;

  /// No description provided for @supportComposeCategoryTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get supportComposeCategoryTechnical;

  /// No description provided for @supportComposeCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get supportComposeCategoryOther;

  /// No description provided for @supportCreateTicketRelatedLoadIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Related load id (optional)'**
  String get supportCreateTicketRelatedLoadIdLabel;

  /// No description provided for @supportCreateTicketRelatedLoadIdHint.
  ///
  /// In en, this message translates to:
  /// **'load-123'**
  String get supportCreateTicketRelatedLoadIdHint;

  /// No description provided for @supportCreateTicketRelatedTripIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Related trip id (optional)'**
  String get supportCreateTicketRelatedTripIdLabel;

  /// No description provided for @supportCreateTicketRelatedTripIdHint.
  ///
  /// In en, this message translates to:
  /// **'trip-123'**
  String get supportCreateTicketRelatedTripIdHint;

  /// No description provided for @supportCreateTicketDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get supportCreateTicketDescriptionLabel;

  /// No description provided for @supportCreateTicketDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Explain what happened, what is blocked, and what follow-up you need.'**
  String get supportCreateTicketDescriptionHint;

  /// No description provided for @supportComposeAttachmentOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Attachment (optional)'**
  String get supportComposeAttachmentOptionalTitle;

  /// No description provided for @supportComposeNoAttachment.
  ///
  /// In en, this message translates to:
  /// **'No evidence image attached yet.'**
  String get supportComposeNoAttachment;

  /// No description provided for @supportComposeAttachmentAttached.
  ///
  /// In en, this message translates to:
  /// **'One evidence image is attached for support review.'**
  String get supportComposeAttachmentAttached;

  /// No description provided for @supportComposeRemoveAttachmentAction.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get supportComposeRemoveAttachmentAction;

  /// No description provided for @supportComposeAttachmentAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Attachment added successfully'**
  String get supportComposeAttachmentAddedSuccess;

  /// No description provided for @supportCreateTicketInvalidCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a valid support category'**
  String get supportCreateTicketInvalidCategoryMessage;

  /// No description provided for @supportCreateTicketDescriptionTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in at least 10 characters'**
  String get supportCreateTicketDescriptionTooShortMessage;

  /// No description provided for @reportIssueInvalidCategoryMessage.
  ///
  /// In en, this message translates to:
  /// **'Select a valid report category'**
  String get reportIssueInvalidCategoryMessage;

  /// No description provided for @reportIssueDescriptionTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in at least 10 characters'**
  String get reportIssueDescriptionTooShortMessage;

  /// No description provided for @reportIssueAttachmentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Attach one evidence image before submitting this report'**
  String get reportIssueAttachmentRequiredMessage;

  /// No description provided for @supportReplyMessageTooShortMessage.
  ///
  /// In en, this message translates to:
  /// **'Reply must contain at least 2 characters'**
  String get supportReplyMessageTooShortMessage;

  /// No description provided for @supportCreateTicketSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit ticket'**
  String get supportCreateTicketSubmitAction;

  /// No description provided for @supportCreateTicketSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Support ticket created successfully'**
  String get supportCreateTicketSubmittedSuccess;

  /// No description provided for @supportCreateTicketSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not create this support ticket right now. Review the details and retry shortly.'**
  String get supportCreateTicketSubmitFailureMessage;

  /// No description provided for @supportReplyFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply needs attention'**
  String get supportReplyFailureTitle;

  /// No description provided for @supportReplyFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Your latest support reply could not be prepared or submitted right now. Review the message and try again shortly.'**
  String get supportReplyFailureMessage;

  /// No description provided for @supportReplyLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply to support'**
  String get supportReplyLabel;

  /// No description provided for @supportReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Add the next detail or response support requested.'**
  String get supportReplyHint;

  /// No description provided for @supportReplySendAction.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get supportReplySendAction;

  /// No description provided for @supportReplySentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reply sent successfully'**
  String get supportReplySentSuccess;

  /// No description provided for @supportReplySubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not send your reply right now. Review the message and retry shortly.'**
  String get supportReplySubmitFailureMessage;

  /// No description provided for @supplierTripsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier trips'**
  String get supplierTripsSectionTitle;

  /// No description provided for @supplierTripsSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track active movements and recent trip outcomes from one supplier execution surface.'**
  String get supplierTripsSectionSubtitle;

  /// No description provided for @supplierTripsLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load supplier trips'**
  String get supplierTripsLoadFailureTitle;

  /// No description provided for @supplierTripsLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your supplier trips right now. Retry shortly to refresh the latest trip list and statuses.'**
  String get supplierTripsLoadFailureMessage;

  /// No description provided for @supplierTripsEmptyActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No active trips yet'**
  String get supplierTripsEmptyActiveTitle;

  /// No description provided for @supplierTripsEmptyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet'**
  String get supplierTripsEmptyCompletedTitle;

  /// No description provided for @supplierTripsEmptyActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips will appear here once a load moves into assigned execution.'**
  String get supplierTripsEmptyActiveSubtitle;

  /// No description provided for @supplierTripsEmptyCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Completed supplier trips will appear here once deliveries are closed out.'**
  String get supplierTripsEmptyCompletedSubtitle;

  /// No description provided for @supplierTripsEmptyCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'View active trips'**
  String get supplierTripsEmptyCompletedAction;

  /// No description provided for @supplierTripsAssignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned {date}'**
  String supplierTripsAssignedLabel(Object date);

  /// No description provided for @supplierTripsTruckerTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucker {truckerId} - Truck {truckId}'**
  String supplierTripsTruckerTruckLabel(Object truckId, Object truckerId);

  /// No description provided for @supplierTripsTrackTripAction.
  ///
  /// In en, this message translates to:
  /// **'Track trip'**
  String get supplierTripsTrackTripAction;

  /// No description provided for @supplierTripDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip not found'**
  String get supplierTripDetailNotFoundTitle;

  /// No description provided for @supplierTripDetailNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This supplier trip is no longer available or you no longer have access to it.'**
  String get supplierTripDetailNotFoundSubtitle;

  /// No description provided for @supplierTripDetailBackToTripsAction.
  ///
  /// In en, this message translates to:
  /// **'Back to supplier trips'**
  String get supplierTripDetailBackToTripsAction;

  /// No description provided for @shellAccessRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Access restricted'**
  String get shellAccessRestrictedTitle;

  /// No description provided for @shellAccessRestrictedDeactivatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account is deactivated pending cleanup. Signing you out safely...'**
  String get shellAccessRestrictedDeactivatedSubtitle;

  /// No description provided for @shellAccessRestrictedBannedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account access is restricted. Signing you out safely...'**
  String get shellAccessRestrictedBannedSubtitle;

  /// No description provided for @shellRouteNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Route not found'**
  String get shellRouteNotFoundTitle;

  /// No description provided for @shellMessagesLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load your messages right now. Retry shortly to refresh the latest conversations.'**
  String get shellMessagesLoadFailureMessage;

  /// No description provided for @shellMessagesBookingStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, submitted {Submitted} approved {Approved} rejected {Rejected} pending {Pending} unknown {Unknown} other {Unknown}}'**
  String shellMessagesBookingStatusValue(String status);

  /// No description provided for @truckerLoadDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Load Detail'**
  String get truckerLoadDetailTitle;

  /// No description provided for @truckerLoadDetailLoadNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Load not found'**
  String get truckerLoadDetailLoadNotFoundTitle;

  /// No description provided for @truckerLoadDetailLoadNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This marketplace load is no longer available or you no longer have access to it.'**
  String get truckerLoadDetailLoadNotFoundSubtitle;

  /// No description provided for @truckerLoadDetailBackToFindLoadsAction.
  ///
  /// In en, this message translates to:
  /// **'Back to find loads'**
  String get truckerLoadDetailBackToFindLoadsAction;

  /// No description provided for @truckerLoadDetailLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load freight detail'**
  String get truckerLoadDetailLoadFailureTitle;

  /// No description provided for @truckerLoadDetailLoadFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this freight detail right now. Retry shortly to refresh the current route, pricing, and booking context.'**
  String get truckerLoadDetailLoadFailureMessage;

  /// No description provided for @truckerLoadDetailSupportUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Some supporting load details are unavailable'**
  String get truckerLoadDetailSupportUnavailableTitle;

  /// No description provided for @truckerLoadDetailSupportFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Some supporting load details are temporarily unavailable. Retry shortly to refresh the latest freight context.'**
  String get truckerLoadDetailSupportFailureMessage;

  /// No description provided for @truckerLoadDetailActionFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Action unavailable'**
  String get truckerLoadDetailActionFailureTitle;

  /// No description provided for @truckerLoadDetailActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'The latest load action could not be completed right now. Review the current load details and retry shortly.'**
  String get truckerLoadDetailActionFailureMessage;

  /// No description provided for @truckerLoadDetailBookingSubmitFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not submit this booking request right now. Review the selected truck and retry shortly.'**
  String get truckerLoadDetailBookingSubmitFailureMessage;

  /// No description provided for @truckerLoadDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup {pickupDate}'**
  String truckerLoadDetailHeroSubtitle(Object pickupDate);

  /// No description provided for @truckerLoadDetailPriceBadge.
  ///
  /// In en, this message translates to:
  /// **'₹{priceAmount} - {priceType}'**
  String truckerLoadDetailPriceBadge(Object priceAmount, Object priceType);

  /// No description provided for @truckerLoadDetailTruckMatchAvailable.
  ///
  /// In en, this message translates to:
  /// **'Truck match available'**
  String get truckerLoadDetailTruckMatchAvailable;

  /// No description provided for @truckerLoadDetailMaterialSummary.
  ///
  /// In en, this message translates to:
  /// **'{material} - {weightTonnes}T - Advance {advancePercentage}%'**
  String truckerLoadDetailMaterialSummary(
    Object advancePercentage,
    Object material,
    Object weightTonnes,
  );

  /// No description provided for @truckerLoadDetailSuperLoadGuarantee.
  ///
  /// In en, this message translates to:
  /// **'Super Load - Payment Guarantee'**
  String get truckerLoadDetailSuperLoadGuarantee;

  /// No description provided for @truckerLoadDetailRoutePriceSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Route and price summary'**
  String get truckerLoadDetailRoutePriceSummaryTitle;

  /// No description provided for @truckerLoadDetailRouteMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Route map'**
  String get truckerLoadDetailRouteMapTitle;

  /// No description provided for @truckerLoadDetailPickupLabel.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {pickupDate}'**
  String truckerLoadDetailPickupLabel(Object pickupDate);

  /// No description provided for @truckerLoadDetailPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price: ₹{priceAmount} - {priceType}'**
  String truckerLoadDetailPriceLabel(Object priceAmount, Object priceType);

  /// No description provided for @truckerLoadDetailDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance} km'**
  String truckerLoadDetailDistanceLabel(Object distance);

  /// No description provided for @truckerLoadDetailDriveTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated drive time: {minutes} min'**
  String truckerLoadDetailDriveTimeLabel(Object minutes);

  /// No description provided for @truckerLoadDetailTruckRequirementTitle.
  ///
  /// In en, this message translates to:
  /// **'Truck requirement summary'**
  String get truckerLoadDetailTruckRequirementTitle;

  /// No description provided for @truckerLoadDetailBodyTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Body type: {bodyType}'**
  String truckerLoadDetailBodyTypeLabel(Object bodyType);

  /// No description provided for @truckerLoadDetailTyresLabel.
  ///
  /// In en, this message translates to:
  /// **'Tyres: {tyres}'**
  String truckerLoadDetailTyresLabel(Object tyres);

  /// No description provided for @truckerLoadDetailTrucksNeededLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucks needed: {booked}/{needed} booked'**
  String truckerLoadDetailTrucksNeededLabel(Object booked, Object needed);

  /// No description provided for @truckerLoadDetailPerTruckWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Per truck: {weight}T'**
  String truckerLoadDetailPerTruckWeightLabel(Object weight);

  /// No description provided for @truckerLoadDetailCapacityRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Acceptable truck: {minT}T – {maxT}T'**
  String truckerLoadDetailCapacityRangeLabel(Object maxT, Object minT);

  /// No description provided for @truckerLoadDetailSlotsOpenLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} slots open'**
  String truckerLoadDetailSlotsOpenLabel(Object count);

  /// No description provided for @truckerLoadDetailNoApprovedTruckSelected.
  ///
  /// In en, this message translates to:
  /// **'No approved truck selected'**
  String get truckerLoadDetailNoApprovedTruckSelected;

  /// No description provided for @truckerLoadDetailSelectedTruckMatches.
  ///
  /// In en, this message translates to:
  /// **'Selected truck matches this load'**
  String get truckerLoadDetailSelectedTruckMatches;

  /// No description provided for @truckerLoadDetailSelectedTruckMayNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Selected truck may not match this load'**
  String get truckerLoadDetailSelectedTruckMayNotMatch;

  /// No description provided for @truckerLoadDetailCargoScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Cargo and schedule details'**
  String get truckerLoadDetailCargoScheduleTitle;

  /// No description provided for @truckerLoadDetailMaterialLabel.
  ///
  /// In en, this message translates to:
  /// **'Material: {material}'**
  String truckerLoadDetailMaterialLabel(Object material);

  /// No description provided for @truckerLoadDetailWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight: {weight} tonnes'**
  String truckerLoadDetailWeightLabel(Object weight);

  /// No description provided for @truckerLoadDetailOriginCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin city: {city}'**
  String truckerLoadDetailOriginCityLabel(Object city);

  /// No description provided for @truckerLoadDetailDestinationCityLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination city: {city}'**
  String truckerLoadDetailDestinationCityLabel(Object city);

  /// No description provided for @truckerLoadDetailTripCostEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip cost estimate'**
  String get truckerLoadDetailTripCostEstimateTitle;

  /// No description provided for @truckerLoadDetailTripCostUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip cost unavailable'**
  String get truckerLoadDetailTripCostUnavailableTitle;

  /// No description provided for @truckerLoadDetailTripCostUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Distance is unavailable for this load right now, so the trip cost estimate cannot be calculated yet.'**
  String get truckerLoadDetailTripCostUnavailableMessage;

  /// No description provided for @truckerLoadDetailSupplierSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier summary'**
  String get truckerLoadDetailSupplierSummaryTitle;

  /// No description provided for @truckerLoadDetailVerifiedSupplier.
  ///
  /// In en, this message translates to:
  /// **'Verified supplier'**
  String get truckerLoadDetailVerifiedSupplier;

  /// No description provided for @truckerLoadDetailSupplierProfile.
  ///
  /// In en, this message translates to:
  /// **'Supplier profile'**
  String get truckerLoadDetailSupplierProfile;

  /// No description provided for @truckerLoadDetailStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active {Active} assigned_partial {Assigned partial} unknown {Unknown} other {Unknown}}'**
  String truckerLoadDetailStatusValue(String status);

  /// No description provided for @truckerLoadDetailBookingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking status: {status}'**
  String truckerLoadDetailBookingStatusLabel(Object status);

  /// No description provided for @truckerLoadDetailBookingFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking feedback'**
  String get truckerLoadDetailBookingFeedbackTitle;

  /// No description provided for @truckerLoadDetailBookingBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking is blocked'**
  String get truckerLoadDetailBookingBlockedTitle;

  /// No description provided for @truckerLoadDetailUsingTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Using {truckNumber}'**
  String truckerLoadDetailUsingTruckLabel(Object truckNumber);

  /// No description provided for @truckerLoadDetailSelectedTruckSummary.
  ///
  /// In en, this message translates to:
  /// **'This load will be booked with {truckNumber} - {bodyType} - {tyres} tyres.'**
  String truckerLoadDetailSelectedTruckSummary(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  );

  /// No description provided for @truckerLoadDetailApprovedTruckLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved truck for this request'**
  String get truckerLoadDetailApprovedTruckLabel;

  /// No description provided for @truckerLoadDetailTruckOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'{truckNumber} - {bodyType} - {tyres} tyres'**
  String truckerLoadDetailTruckOptionLabel(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  );

  /// No description provided for @truckerLoadDetailNoApprovedTrucksAvailable.
  ///
  /// In en, this message translates to:
  /// **'No approved trucks are available yet.'**
  String get truckerLoadDetailNoApprovedTrucksAvailable;

  /// No description provided for @truckerLoadDetailAddTruckFirstAction.
  ///
  /// In en, this message translates to:
  /// **'Add a Truck First'**
  String get truckerLoadDetailAddTruckFirstAction;

  /// No description provided for @truckerLoadDetailRequestSubmittedAction.
  ///
  /// In en, this message translates to:
  /// **'Request Submitted'**
  String get truckerLoadDetailRequestSubmittedAction;

  /// No description provided for @truckerLoadDetailBookedAction.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get truckerLoadDetailBookedAction;

  /// No description provided for @truckerLoadDetailBookThisLoadAction.
  ///
  /// In en, this message translates to:
  /// **'Book This Load'**
  String get truckerLoadDetailBookThisLoadAction;

  /// No description provided for @truckerLoadDetailLoadBookedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load booked! Waiting for supplier approval'**
  String get truckerLoadDetailLoadBookedSuccess;

  /// No description provided for @truckerLoadDetailShareLoadAction.
  ///
  /// In en, this message translates to:
  /// **'Share load'**
  String get truckerLoadDetailShareLoadAction;

  /// No description provided for @truckerLoadDetailShareLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Share load'**
  String get truckerLoadDetailShareLoadTitle;

  /// No description provided for @truckerLoadDetailShareLoadMessage.
  ///
  /// In en, this message translates to:
  /// **'Share a safe summary-first load card without exposing direct phone numbers or private operational notes.'**
  String get truckerLoadDetailShareLoadMessage;

  /// No description provided for @truckerLoadDetailSystemShareAction.
  ///
  /// In en, this message translates to:
  /// **'System share'**
  String get truckerLoadDetailSystemShareAction;

  /// No description provided for @truckerLoadDetailShareToWhatsAppAction.
  ///
  /// In en, this message translates to:
  /// **'Share to WhatsApp'**
  String get truckerLoadDetailShareToWhatsAppAction;

  /// No description provided for @truckerLoadDetailWhatsAppUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is unavailable on this device. Use system share instead.'**
  String get truckerLoadDetailWhatsAppUnavailableMessage;

  /// No description provided for @truckerLoadDetailReportSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Trucker load - {routeLabel}'**
  String truckerLoadDetailReportSourceLabel(Object routeLabel);

  /// No description provided for @truckerLoadDetailVerificationRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete trucker verification before booking loads or starting supplier chat. Verification requires approved identity documents and profile review.'**
  String get truckerLoadDetailVerificationRequiredMessage;

  /// No description provided for @truckerLoadDetailTruckApprovalRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Add and approve at least one truck before booking this load or unlocking supplier chat.'**
  String get truckerLoadDetailTruckApprovalRequiredMessage;

  /// No description provided for @truckerLoadDetailAddTruckDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a truck first'**
  String get truckerLoadDetailAddTruckDialogTitle;

  /// No description provided for @truckerLoadDetailAddTruckDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You need at least one approved truck before you can book this load. Open Fleet now to add or complete truck approval?'**
  String get truckerLoadDetailAddTruckDialogMessage;

  /// No description provided for @truckerLoadDetailNotNowAction.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get truckerLoadDetailNotNowAction;

  /// No description provided for @truckerLoadDetailOpenFleetAction.
  ///
  /// In en, this message translates to:
  /// **'Open Fleet'**
  String get truckerLoadDetailOpenFleetAction;

  /// No description provided for @truckerLoadDetailConfirmBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm load booking'**
  String get truckerLoadDetailConfirmBookingTitle;

  /// No description provided for @truckerLoadDetailConfirmBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Book {material} {routeLabel} with {truckNumber}?'**
  String truckerLoadDetailConfirmBookingMessage(
    Object material,
    Object routeLabel,
    Object truckNumber,
  );

  /// No description provided for @authTtsSplashWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to TranZfort. I will help you finish a quick setup before you continue.'**
  String get authTtsSplashWelcome;

  /// No description provided for @authSessionRefreshFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not refresh your session right now. Please continue and try again if needed.'**
  String get authSessionRefreshFailureMessage;

  /// No description provided for @authConfigIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup incomplete'**
  String get authConfigIncompleteTitle;

  /// No description provided for @postLoadValidationOriginCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the origin city'**
  String get postLoadValidationOriginCityRequired;

  /// No description provided for @postLoadValidationOriginLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the pickup location'**
  String get postLoadValidationOriginLocationRequired;

  /// No description provided for @postLoadValidationDestinationCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Select the destination city'**
  String get postLoadValidationDestinationCityRequired;

  /// No description provided for @postLoadValidationDestinationLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the drop location'**
  String get postLoadValidationDestinationLocationRequired;

  /// No description provided for @postLoadValidationMaterialRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the material name'**
  String get postLoadValidationMaterialRequired;

  /// No description provided for @postLoadValidationWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 0 and 100 tonnes'**
  String get postLoadValidationWeightRange;

  /// No description provided for @postLoadValidationTrucksNeeded.
  ///
  /// In en, this message translates to:
  /// **'At least one truck is required'**
  String get postLoadValidationTrucksNeeded;

  /// No description provided for @postLoadValidationPricePositive.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price greater than zero'**
  String get postLoadValidationPricePositive;

  /// No description provided for @postLoadValidationPriceType.
  ///
  /// In en, this message translates to:
  /// **'Select a valid price type'**
  String get postLoadValidationPriceType;

  /// No description provided for @postLoadValidationPickupDatePast.
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

  /// No description provided for @pushIssuePermissionRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Permission request failed.'**
  String get pushIssuePermissionRequestFailed;

  /// No description provided for @pushIssueLocalInitFailed.
  ///
  /// In en, this message translates to:
  /// **'Local notification setup failed.'**
  String get pushIssueLocalInitFailed;

  /// No description provided for @pushIssueDisplayFailed.
  ///
  /// In en, this message translates to:
  /// **'Notification display failed.'**
  String get pushIssueDisplayFailed;

  /// No description provided for @pushIssueTokenSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Token sync failed.'**
  String get pushIssueTokenSyncFailed;

  /// No description provided for @offlineSyncPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get offlineSyncPending;

  /// No description provided for @offlineSyncRetrying.
  ///
  /// In en, this message translates to:
  /// **'retrying'**
  String get offlineSyncRetrying;

  /// No description provided for @offlineSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get offlineSyncFailed;

  /// No description provided for @offlineSyncExhausted.
  ///
  /// In en, this message translates to:
  /// **'exhausted (max retries)'**
  String get offlineSyncExhausted;

  /// No description provided for @validationProfilePhotoRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile photo is required'**
  String get validationProfilePhotoRequired;

  /// No description provided for @validationAadhaarRequired.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar number is required'**
  String get validationAadhaarRequired;

  /// No description provided for @validationTruckNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'Truck number is required'**
  String get validationTruckNumberRequired;

  /// No description provided for @validationTruckCapacityRequired.
  ///
  /// In en, this message translates to:
  /// **'Truck capacity is required'**
  String get validationTruckCapacityRequired;

  /// No description provided for @validationRcDocumentRequired.
  ///
  /// In en, this message translates to:
  /// **'RC document is required'**
  String get validationRcDocumentRequired;

  /// No description provided for @validationCompanyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Company name is required'**
  String get validationCompanyNameRequired;

  /// No description provided for @validationBusinessLicenseNumberRequired.
  ///
  /// In en, this message translates to:
  /// **'License number is required'**
  String get validationBusinessLicenseNumberRequired;

  /// No description provided for @validationBusinessLicenseRequired.
  ///
  /// In en, this message translates to:
  /// **'License document is required'**
  String get validationBusinessLicenseRequired;

  /// No description provided for @validationVerificationLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification location is required'**
  String get validationVerificationLocationRequired;

  /// No description provided for @validationVerificationCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification city is required'**
  String get validationVerificationCityRequired;

  /// No description provided for @validationDocumentPathRequired.
  ///
  /// In en, this message translates to:
  /// **'Document path is required'**
  String get validationDocumentPathRequired;

  /// No description provided for @validationProfileIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Profile id is required'**
  String get validationProfileIdRequired;

  /// No description provided for @validationCameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required. Enable it in app settings.'**
  String get validationCameraPermissionRequired;

  /// No description provided for @validationPhotoAccessRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo access is required. Enable it in app settings.'**
  String get validationPhotoAccessRequired;

  /// No description provided for @validationTruckRequired.
  ///
  /// In en, this message translates to:
  /// **'Truck is required'**
  String get validationTruckRequired;

  /// No description provided for @validationOwnerIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Owner id is required'**
  String get validationOwnerIdRequired;

  /// No description provided for @validationTruckIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Truck id is required'**
  String get validationTruckIdRequired;

  /// No description provided for @validationTripIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Trip id is required'**
  String get validationTripIdRequired;

  /// No description provided for @backendNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get backendNetworkError;

  /// No description provided for @backendServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get backendServerError;

  /// No description provided for @backendTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get backendTimeoutError;

  /// No description provided for @backendUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get backendUnknownError;

  /// No description provided for @backendUnauthorizedError.
  ///
  /// In en, this message translates to:
  /// **'Unauthorized. Please log in again.'**
  String get backendUnauthorizedError;

  /// No description provided for @backendForbiddenError.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get backendForbiddenError;

  /// No description provided for @backendNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'The requested resource was not found.'**
  String get backendNotFoundError;

  /// No description provided for @backendConflictError.
  ///
  /// In en, this message translates to:
  /// **'This action conflicts with existing data.'**
  String get backendConflictError;

  /// No description provided for @permissionLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Enable it in app settings.'**
  String get permissionLocationDenied;

  /// No description provided for @permissionLocationPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Enable it in app settings.'**
  String get permissionLocationPermanentlyDenied;

  /// No description provided for @permissionCameraDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied. Enable it in app settings.'**
  String get permissionCameraDenied;

  /// No description provided for @permissionCameraPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission permanently denied. Enable it in app settings.'**
  String get permissionCameraPermanentlyDenied;

  /// No description provided for @permissionStorageDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission denied. Enable it in app settings.'**
  String get permissionStorageDenied;

  /// No description provided for @permissionStoragePermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Storage permission permanently denied. Enable it in app settings.'**
  String get permissionStoragePermanentlyDenied;

  /// No description provided for @permissionNotificationsDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Enable it in app settings.'**
  String get permissionNotificationsDenied;

  /// No description provided for @marketplaceLoadValue.
  ///
  /// In en, this message translates to:
  /// **'LOAD VALUE'**
  String get marketplaceLoadValue;

  /// No description provided for @marketplaceEstProfit.
  ///
  /// In en, this message translates to:
  /// **'EST. PROFIT'**
  String get marketplaceEstProfit;

  /// No description provided for @marketplaceEstLoss.
  ///
  /// In en, this message translates to:
  /// **'EST. LOSS'**
  String get marketplaceEstLoss;

  /// No description provided for @chatNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get chatNewMessage;

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @truckerFleetReturnToVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Return to verification'**
  String get truckerFleetReturnToVerificationTitle;

  /// No description provided for @truckerFleetReturnToVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Add or update your truck, then return to verification to continue.'**
  String get truckerFleetReturnToVerificationMessage;

  /// No description provided for @truckerFleetBackToVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Back to verification'**
  String get truckerFleetBackToVerificationAction;

  /// No description provided for @truckerFleetTruckSavedReturnMessage.
  ///
  /// In en, this message translates to:
  /// **'Truck saved. Return to verification to continue.'**
  String get truckerFleetTruckSavedReturnMessage;

  /// No description provided for @truckerLoadDetailProfileLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking your profile. Please wait...'**
  String get truckerLoadDetailProfileLoadingMessage;

  /// No description provided for @supplierLoadDetailNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Load not found'**
  String get supplierLoadDetailNotFoundTitle;

  /// No description provided for @supplierLoadDetailNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This load detail is not available right now. Return to My Loads and try again.'**
  String get supplierLoadDetailNotFoundSubtitle;

  /// No description provided for @supplierLoadDetailLoadFailureTitle.
  ///
  /// In en, this message translates to:
  /// **'Unable to load load detail'**
  String get supplierLoadDetailLoadFailureTitle;

  /// No description provided for @supplierLoadDetailFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not load this load detail. Please try again.'**
  String get supplierLoadDetailFailureMessage;

  /// No description provided for @supplierLoadDetailScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Load detail'**
  String get supplierLoadDetailScreenTitle;

  /// No description provided for @supplierLoadDetailHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup: {pickupDate}'**
  String supplierLoadDetailHeroSubtitle(Object pickupDate);

  /// No description provided for @supplierLoadDetailLinkedExecutionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked execution data unavailable'**
  String get supplierLoadDetailLinkedExecutionUnavailableTitle;

  /// No description provided for @supplierLoadSupportFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh bookings or trips right now. Please retry.'**
  String get supplierLoadSupportFailureMessage;

  /// No description provided for @supplierLoadDetailStatusAndActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Status and actions'**
  String get supplierLoadDetailStatusAndActionsTitle;

  /// Label showing current load status. Placeholder {status} is the status name.
  ///
  /// In en, this message translates to:
  /// **'Current status: {status}'**
  String supplierLoadDetailCurrentStatus(Object status);

  /// No description provided for @supplierLoadDetailActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use these actions only after checking the latest status.'**
  String get supplierLoadDetailActionsSubtitle;

  /// No description provided for @supplierLoadDetailActionUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Action unavailable'**
  String get supplierLoadDetailActionUnavailableTitle;

  /// No description provided for @supplierLoadActionFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not complete that load action right now. Please try again.'**
  String get supplierLoadActionFailureMessage;

  /// No description provided for @supplierLoadDetailCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel load'**
  String get supplierLoadDetailCancelAction;

  /// No description provided for @supplierLoadDetailCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load cancelled successfully'**
  String get supplierLoadDetailCancelledSuccess;

  /// No description provided for @supplierLoadCancelFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel this load right now. Please try again.'**
  String get supplierLoadCancelFailureMessage;

  /// No description provided for @supplierLoadDetailCloseFilledOutsideAction.
  ///
  /// In en, this message translates to:
  /// **'Close as filled outside app'**
  String get supplierLoadDetailCloseFilledOutsideAction;

  /// No description provided for @supplierLoadDetailClosedFilledOutsideSuccess.
  ///
  /// In en, this message translates to:
  /// **'Load marked as filled outside the app'**
  String get supplierLoadDetailClosedFilledOutsideSuccess;

  /// No description provided for @supplierLoadCloseFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not close this load right now. Please try again.'**
  String get supplierLoadCloseFailureMessage;

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

  /// No description provided for @supplierLoadDetailRoutePreviewUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Route preview unavailable'**
  String get supplierLoadDetailRoutePreviewUnavailableTitle;

  /// No description provided for @supplierLoadDetailRoutePreviewUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Route preview details are unavailable for this load right now.'**
  String get supplierLoadDetailRoutePreviewUnavailableMessage;

  /// No description provided for @supplierLoadDetailCargoAndRequirementsTitle.
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

  /// No description provided for @supplierLoadDetailBookingAndTripLinkageTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking and trip linkage'**
  String get supplierLoadDetailBookingAndTripLinkageTitle;

  /// No description provided for @supplierLoadDetailBookingLinkageEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No booking requests or linked trips are available on this load yet.'**
  String get supplierLoadDetailBookingLinkageEmptyDescription;

  /// No description provided for @supplierLoadDetailBookingLinkageDescription.
  ///
  /// In en, this message translates to:
  /// **'See booking requests and linked trips together.'**
  String get supplierLoadDetailBookingLinkageDescription;

  /// No description provided for @supplierLoadDetailNoBookingRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'No booking requests yet'**
  String get supplierLoadDetailNoBookingRequestsTitle;

  /// No description provided for @supplierLoadDetailNoBookingRequestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Booking requests will appear here once truckers respond to this load.'**
  String get supplierLoadDetailNoBookingRequestsSubtitle;

  /// No description provided for @supplierLoadDetailLinkedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked trips'**
  String get supplierLoadDetailLinkedTripsTitle;

  /// No description provided for @supplierLoadDetailNoLinkedTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'No linked trips yet'**
  String get supplierLoadDetailNoLinkedTripsTitle;

  /// No description provided for @supplierLoadDetailNoLinkedTripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trips will appear here after you approve a booking.'**
  String get supplierLoadDetailNoLinkedTripsSubtitle;

  /// No description provided for @supplierLoadDetailActivityTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity timeline'**
  String get supplierLoadDetailActivityTimelineTitle;

  /// No description provided for @supplierLoadDetailTimelineCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load created'**
  String get supplierLoadDetailTimelineCreatedTitle;

  /// No description provided for @supplierLoadDetailTimelineCreatedDescription.
  ///
  /// In en, this message translates to:
  /// **'This load was created.'**
  String get supplierLoadDetailTimelineCreatedDescription;

  /// No description provided for @supplierLoadDetailTimelinePublishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Load published'**
  String get supplierLoadDetailTimelinePublishedTitle;

  /// No description provided for @supplierLoadDetailTimelinePublishedDescription.
  ///
  /// In en, this message translates to:
  /// **'This load is published and visible to truckers.'**
  String get supplierLoadDetailTimelinePublishedDescription;

  /// No description provided for @supplierLoadDetailTimelineUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get supplierLoadDetailTimelineUpdatedTitle;

  /// No description provided for @supplierLoadDetailTimelineUpdatedDescription.
  ///
  /// In en, this message translates to:
  /// **'Current status: {status}.'**
  String supplierLoadDetailTimelineUpdatedDescription(Object status);

  /// No description provided for @supplierBookingVerifiedLabel.
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

  /// No description provided for @supplierBookingApprovedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking approved successfully'**
  String get supplierBookingApprovedSuccessMessage;

  /// No description provided for @supplierLoadApproveBookingFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not approve this booking right now. Please try again.'**
  String get supplierLoadApproveBookingFailureMessage;

  /// No description provided for @supplierBookingRejectedSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking rejected successfully'**
  String get supplierBookingRejectedSuccessMessage;

  /// No description provided for @supplierLoadRejectBookingFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not reject this booking right now. Please try again.'**
  String get supplierLoadRejectBookingFailureMessage;

  /// No description provided for @supplierBookingApproveDialogTitle.
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

  /// No description provided for @supplierBookingRejectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject booking'**
  String get supplierBookingRejectDialogTitle;

  /// No description provided for @supplierBookingRejectDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a short reason before rejecting this booking.'**
  String get supplierBookingRejectDialogSubtitle;

  /// No description provided for @supplierBookingRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get supplierBookingRejectReasonLabel;

  /// No description provided for @supplierBookingRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Example: vehicle mismatch or route timing issue'**
  String get supplierBookingRejectReasonHint;

  /// No description provided for @verificationFieldBusinessLicenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Business licence number'**
  String get verificationFieldBusinessLicenceNumber;

  /// No description provided for @verificationFieldGstOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get verificationFieldGstOptional;

  /// No description provided for @verificationSavePacketAction.
  ///
  /// In en, this message translates to:
  /// **'Save details'**
  String get verificationSavePacketAction;

  /// No description provided for @verificationSaveSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Verification details saved'**
  String get verificationSaveSuccessMessage;

  /// No description provided for @verificationSaveFailureMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not save verification details'**
  String get verificationSaveFailureMessage;

  /// No description provided for @verificationLockedVerifiedGuidance.
  ///
  /// In en, this message translates to:
  /// **'Your verification is already approved, so these fields are locked.'**
  String get verificationLockedVerifiedGuidance;

  /// No description provided for @verificationLockedPendingGuidance.
  ///
  /// In en, this message translates to:
  /// **'Your verification is under review, so these fields are locked until a decision is made.'**
  String get verificationLockedPendingGuidance;

  /// No description provided for @verificationUnlockedSupplierGuidance.
  ///
  /// In en, this message translates to:
  /// **'Enter your business and identity details, then upload the required documents.'**
  String get verificationUnlockedSupplierGuidance;

  /// No description provided for @verificationUnlockedTruckerGuidance.
  ///
  /// In en, this message translates to:
  /// **'Enter your identity details and keep at least one truck ready for verification.'**
  String get verificationUnlockedTruckerGuidance;

  /// No description provided for @verificationBlockedAlreadyComplete.
  ///
  /// In en, this message translates to:
  /// **'Verification is already complete.'**
  String get verificationBlockedAlreadyComplete;

  /// No description provided for @verificationBlockedUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Your verification is already under review.'**
  String get verificationBlockedUnderReview;

  /// No description provided for @verificationBlockedMissingIdentity.
  ///
  /// In en, this message translates to:
  /// **'Add your Aadhaar and PAN numbers first.'**
  String get verificationBlockedMissingIdentity;

  /// No description provided for @verificationBlockedMissingCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Enter your company name first.'**
  String get verificationBlockedMissingCompanyName;

  /// No description provided for @verificationBlockedMissingBusinessNumbers.
  ///
  /// In en, this message translates to:
  /// **'Enter your business licence details first.'**
  String get verificationBlockedMissingBusinessNumbers;

  /// Error message when required document is missing. Placeholder {documentType} is the document type name.
  ///
  /// In en, this message translates to:
  /// **'Upload {documentType} to continue.'**
  String verificationBlockedMissingDocument(Object documentType);

  /// No description provided for @verificationBlockedMissingLocation.
  ///
  /// In en, this message translates to:
  /// **'Add your verification location first.'**
  String get verificationBlockedMissingLocation;

  /// No description provided for @verificationBlockedMissingTruck.
  ///
  /// In en, this message translates to:
  /// **'Add at least one truck before submitting verification.'**
  String get verificationBlockedMissingTruck;

  /// Shows count of verification-ready trucks. Placeholder {count} is the truck count.
  ///
  /// In en, this message translates to:
  /// **'Verification-ready trucks: {count}'**
  String verificationReadyTruckCount(Object count);

  /// No description provided for @appBarLanguageToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch language'**
  String get appBarLanguageToggleTooltip;

  /// No description provided for @connectivityOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Features may be limited.'**
  String get connectivityOfflineBanner;

  /// No description provided for @connectivityOfflineActionsMessage.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Actions that need network access should stay disabled.'**
  String get connectivityOfflineActionsMessage;

  /// No description provided for @onboardingGateTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading is taking longer than expected.'**
  String get onboardingGateTimeoutMessage;

  /// Success message after sending password reset. Placeholder {email} is the recipient email.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to {email}. Check your inbox.'**
  String authPasswordResetSentSuccess(Object email);

  /// No description provided for @authPasswordResetSentFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to send reset link. Please try again.'**
  String get authPasswordResetSentFailure;

  /// No description provided for @chatPreviewLocation.
  ///
  /// In en, this message translates to:
  /// **'Location shared'**
  String get chatPreviewLocation;

  /// No description provided for @chatPreviewDocument.
  ///
  /// In en, this message translates to:
  /// **'Document shared'**
  String get chatPreviewDocument;

  /// No description provided for @chatPreviewMapCard.
  ///
  /// In en, this message translates to:
  /// **'Route card shared'**
  String get chatPreviewMapCard;

  /// No description provided for @chatPreviewTruckCard.
  ///
  /// In en, this message translates to:
  /// **'Truck details shared'**
  String get chatPreviewTruckCard;

  /// Report source label for supplier load. Placeholder {routeLabel} is the route description.
  ///
  /// In en, this message translates to:
  /// **'Supplier load - {routeLabel}'**
  String reportSourceSupplierLoad(Object routeLabel);

  /// No description provided for @truckCount.
  ///
  /// In en, this message translates to:
  /// **'{count} truck{count, plural, one {} other {s}}'**
  String truckCount(int count);

  /// No description provided for @authRecommendedChip.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get authRecommendedChip;

  /// No description provided for @authFastestMostSecure.
  ///
  /// In en, this message translates to:
  /// **'Fastest · Most secure'**
  String get authFastestMostSecure;

  /// No description provided for @authOneTapNoPasswordSecure.
  ///
  /// In en, this message translates to:
  /// **'One-tap · No password · Secure'**
  String get authOneTapNoPasswordSecure;

  /// No description provided for @commonMuteVoice.
  ///
  /// In en, this message translates to:
  /// **'Mute voice'**
  String get commonMuteVoice;

  /// No description provided for @commonTurnVoiceOn.
  ///
  /// In en, this message translates to:
  /// **'Turn voice on'**
  String get commonTurnVoiceOn;

  /// No description provided for @commonSuggestionSourceGooglePlaces.
  ///
  /// In en, this message translates to:
  /// **'Google Places'**
  String get commonSuggestionSourceGooglePlaces;

  /// No description provided for @commonSuggestionSourceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline database'**
  String get commonSuggestionSourceOffline;

  /// No description provided for @truckerLoadDetailCostTileDieselLabel.
  ///
  /// In en, this message translates to:
  /// **'DIESEL'**
  String get truckerLoadDetailCostTileDieselLabel;

  /// No description provided for @truckerLoadDetailCostTileTollLabel.
  ///
  /// In en, this message translates to:
  /// **'TOLL (₹11/km)'**
  String get truckerLoadDetailCostTileTollLabel;

  /// No description provided for @truckerLoadDetailCostTileDriverLabel.
  ///
  /// In en, this message translates to:
  /// **'DRIVER (₹5/km)'**
  String get truckerLoadDetailCostTileDriverLabel;

  /// No description provided for @truckerLoadDetailCostTileMiscLabel.
  ///
  /// In en, this message translates to:
  /// **'MISC (₹2/km)'**
  String get truckerLoadDetailCostTileMiscLabel;

  /// No description provided for @truckerLoadDetailCostTileDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimates assume ₹11/km toll, ₹5/km driver, ₹2/km misc. Actual costs vary.'**
  String get truckerLoadDetailCostTileDisclaimer;

  /// No description provided for @truckerLoadDetailEarningsEstimateTitle.
  ///
  /// In en, this message translates to:
  /// **'TRIP EARNINGS ESTIMATE'**
  String get truckerLoadDetailEarningsEstimateTitle;

  /// No description provided for @truckerLoadDetailTotalFareLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL FARE (LOAD VALUE)'**
  String get truckerLoadDetailTotalFareLabel;

  /// No description provided for @truckerLoadDetailTotalExpenseLabel.
  ///
  /// In en, this message translates to:
  /// **'TOTAL EXPENSE'**
  String get truckerLoadDetailTotalExpenseLabel;

  /// No description provided for @truckerLoadDetailEstimatedNetProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED NET PROFIT'**
  String get truckerLoadDetailEstimatedNetProfitLabel;

  /// No description provided for @truckerLoadDetailEstimatedNetLossLabel.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED NET LOSS'**
  String get truckerLoadDetailEstimatedNetLossLabel;

  /// No description provided for @truckerLoadDetailNetProfitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After all expenses deducted from total fare'**
  String get truckerLoadDetailNetProfitSubtitle;

  /// No description provided for @truckerLoadDetailNetLossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses exceed total fare'**
  String get truckerLoadDetailNetLossSubtitle;

  /// No description provided for @truckerLoadDetailCostBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'COST BREAKDOWN'**
  String get truckerLoadDetailCostBreakdownLabel;

  /// No description provided for @trustScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust & Reviews'**
  String get trustScoreTitle;

  /// No description provided for @trustScoreOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'out of 5'**
  String get trustScoreOutOfFive;

  /// No description provided for @trustScoreReviews.
  ///
  /// In en, this message translates to:
  /// **'reviews'**
  String get trustScoreReviews;

  /// No description provided for @trustScoreNoRatingYet.
  ///
  /// In en, this message translates to:
  /// **'No rating yet'**
  String get trustScoreNoRatingYet;

  /// No description provided for @trustScoreReviewsReceived.
  ///
  /// In en, this message translates to:
  /// **'Reviews received'**
  String get trustScoreReviewsReceived;

  /// No description provided for @trustScoreTripsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trips completed'**
  String get trustScoreTripsCompleted;

  /// No description provided for @trustScoreLoadsPosted.
  ///
  /// In en, this message translates to:
  /// **'Loads posted'**
  String get trustScoreLoadsPosted;

  /// No description provided for @trustScoreTrucksInFleet.
  ///
  /// In en, this message translates to:
  /// **'Trucks in fleet'**
  String get trustScoreTrucksInFleet;

  /// No description provided for @trustScoreSuperLoadEligible.
  ///
  /// In en, this message translates to:
  /// **'Super Load eligible'**
  String get trustScoreSuperLoadEligible;

  /// No description provided for @loadHistoryFailedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get loadHistoryFailedToLoad;

  /// No description provided for @loadHistoryNoLoads.
  ///
  /// In en, this message translates to:
  /// **'No loads to display'**
  String get loadHistoryNoLoads;

  /// No description provided for @loadHistoryStatusValue.
  ///
  /// In en, this message translates to:
  /// **'{status, select, active {Active} completed {Completed} assigned_partial {Partial} assigned_full {Assigned} other {{status}}}'**
  String loadHistoryStatusValue(String status);

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews & Comments'**
  String get reviewsTitle;

  /// No description provided for @reviewsAverage.
  ///
  /// In en, this message translates to:
  /// **'average'**
  String get reviewsAverage;

  /// No description provided for @reviewsTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get reviewsTotal;

  /// No description provided for @reviewsUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reviews'**
  String get reviewsUnableToLoad;

  /// No description provided for @reviewsRetryMessage.
  ///
  /// In en, this message translates to:
  /// **'Please retry to load the latest reviews.'**
  String get reviewsRetryMessage;

  /// No description provided for @reviewsNoReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsNoReviewsYet;

  /// No description provided for @reviewsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Reviews will appear here after interactions'**
  String get reviewsWillAppearHere;

  /// No description provided for @reviewsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More Reviews'**
  String get reviewsLoadMore;

  /// No description provided for @replyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Reply to Review'**
  String get replyDialogTitle;

  /// No description provided for @replyDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'You can reply to this review once. Your response will be visible to everyone who views your profile.'**
  String get replyDialogDescription;

  /// Hint text in the reply text field with placeholder for reviewer name.
  ///
  /// In en, this message translates to:
  /// **'Write your reply to {name}...'**
  String replyDialogHint(String name);

  /// No description provided for @replyDialogSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Reply'**
  String get replyDialogSubmit;

  /// No description provided for @reviewPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate Your Interaction'**
  String get reviewPromptTitle;

  /// Subtitle asking about the experience with the other user.
  ///
  /// In en, this message translates to:
  /// **'How was your experience with {name}?'**
  String reviewPromptSubtitle(String name);

  /// No description provided for @reviewPromptCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)...'**
  String get reviewPromptCommentHint;

  /// No description provided for @reviewPromptSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get reviewPromptSubmit;

  /// No description provided for @reviewPromptSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get reviewPromptSkip;

  /// No description provided for @reviewPromptSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Submitted!'**
  String get reviewPromptSuccessTitle;

  /// No description provided for @reviewPromptSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for sharing your experience.'**
  String get reviewPromptSuccessMessage;

  /// No description provided for @reviewPromptDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reviewPromptDone;

  /// No description provided for @publicProfileScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get publicProfileScreenTitle;

  /// No description provided for @truckerProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Trucker Profile'**
  String get truckerProfileTitle;

  /// No description provided for @supplierProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Supplier Profile'**
  String get supplierProfileTitle;

  /// No description provided for @raiseDisputeDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Dispute?'**
  String get raiseDisputeDiscardTitle;

  /// No description provided for @raiseDisputeDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved dispute details. Do you want to discard them?'**
  String get raiseDisputeDiscardMessage;

  /// No description provided for @postLoadDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get postLoadDiscardTitle;

  /// No description provided for @postLoadDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved load details. Do you want to discard them?'**
  String get postLoadDiscardMessage;

  /// No description provided for @ttsHindiVoice.
  ///
  /// In en, this message translates to:
  /// **'Hindi Voice'**
  String get ttsHindiVoice;

  /// No description provided for @ttsEnglishVoice.
  ///
  /// In en, this message translates to:
  /// **'English Voice'**
  String get ttsEnglishVoice;

  /// No description provided for @ttsNoHindiVoices.
  ///
  /// In en, this message translates to:
  /// **'No Hindi voices available on this device.'**
  String get ttsNoHindiVoices;

  /// No description provided for @ttsNoEnglishVoices.
  ///
  /// In en, this message translates to:
  /// **'No English voices available on this device.'**
  String get ttsNoEnglishVoices;

  /// No description provided for @supplierRatingAlreadySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Your rating is already being submitted'**
  String get supplierRatingAlreadySubmitting;

  /// No description provided for @supplierTripActionAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Another supplier trip action is already in progress'**
  String get supplierTripActionAlreadyInProgress;

  /// No description provided for @truckerRatingAlreadySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Your rating is already being submitted'**
  String get truckerRatingAlreadySubmitting;

  /// No description provided for @truckerTripActionAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Another trip action is already in progress'**
  String get truckerTripActionAlreadyInProgress;

  /// No description provided for @truckerTripCannotAdvanceFromCurrentStage.
  ///
  /// In en, this message translates to:
  /// **'This trip can no longer be advanced from its current stage'**
  String get truckerTripCannotAdvanceFromCurrentStage;

  /// No description provided for @truckerTripPodUploadOnlyAfterDelivery.
  ///
  /// In en, this message translates to:
  /// **'POD can only be uploaded after the load has been delivered'**
  String get truckerTripPodUploadOnlyAfterDelivery;

  /// No description provided for @truckerTripLrUploadOnlyDuringPickup.
  ///
  /// In en, this message translates to:
  /// **'LR can only be uploaded during pickup stages'**
  String get truckerTripLrUploadOnlyDuringPickup;

  /// No description provided for @truckerLoadDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Load detail is unavailable'**
  String get truckerLoadDetailUnavailable;

  /// No description provided for @truckerBookingAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Booking request is already in progress'**
  String get truckerBookingAlreadyInProgress;

  /// No description provided for @truckerTruckRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a truck to continue'**
  String get truckerTruckRequired;

  /// No description provided for @truckerTruckSaveAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Truck save is already in progress'**
  String get truckerTruckSaveAlreadyInProgress;

  /// No description provided for @truckerTruckValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Please correct the highlighted truck details'**
  String get truckerTruckValidationFailed;

  /// No description provided for @truckerTruckNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected truck was not found'**
  String get truckerTruckNotFound;

  /// No description provided for @chatVoiceConversationIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Conversation id is required'**
  String get chatVoiceConversationIdRequired;

  /// No description provided for @chatVoiceRecordingAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'A voice recording is already in progress'**
  String get chatVoiceRecordingAlreadyInProgress;

  /// No description provided for @chatVoiceMicrophonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record a voice message'**
  String get chatVoiceMicrophonePermissionRequired;

  /// No description provided for @chatVoiceNoActiveRecording.
  ///
  /// In en, this message translates to:
  /// **'No active voice recording is available for this conversation'**
  String get chatVoiceNoActiveRecording;

  /// No description provided for @chatMessageAlreadyBeingSent.
  ///
  /// In en, this message translates to:
  /// **'Another message is already being sent'**
  String get chatMessageAlreadyBeingSent;

  /// No description provided for @notificationNotificationIdRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification id is required'**
  String get notificationNotificationIdRequired;

  /// No description provided for @profileUserIdRequired.
  ///
  /// In en, this message translates to:
  /// **'User ID is required'**
  String get profileUserIdRequired;

  /// No description provided for @reviewValidationFailed.
  ///
  /// In en, this message translates to:
  /// **'Please correct the review details'**
  String get reviewValidationFailed;

  /// No description provided for @reviewSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review'**
  String get reviewSubmitFailed;

  /// No description provided for @reviewAddReplyFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add reply. You may have already replied or are not the reviewed user'**
  String get reviewAddReplyFailed;

  /// No description provided for @verificationDetailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Verification detail is unavailable'**
  String get verificationDetailUnavailable;

  /// No description provided for @verificationActionAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Another verification action is already in progress'**
  String get verificationActionAlreadyInProgress;

  /// No description provided for @verificationLocationCaptureOnlySupplier.
  ///
  /// In en, this message translates to:
  /// **'Verification location capture is only available for supplier verification'**
  String get verificationLocationCaptureOnlySupplier;

  /// No description provided for @verificationLocationCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to capture your verification location right now. Check location services and try again'**
  String get verificationLocationCaptureFailed;

  /// No description provided for @verificationCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Verification city is required'**
  String get verificationCityRequired;

  /// No description provided for @verificationSubmissionBlocked.
  ///
  /// In en, this message translates to:
  /// **'Verification submission is blocked'**
  String get verificationSubmissionBlocked;
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
