// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'TranZfort';

  @override
  String get authGoogleFailureMessage =>
      'अभी Google से continue नहीं हो सका। थोड़ी देर बाद फिर कोशिश करें या उसकी जगह email sign-in इस्तेमाल करें।';

  @override
  String get authWelcomeTitle => 'TranZfort में आपका स्वागत है';

  @override
  String get authWelcomeSubtitle =>
      'अपने सप्लायर या ट्रकर कार्यक्षेत्र में जाने के लिए Google या email sign-in चुनें।';

  @override
  String get authEmailHint => 'you@example.com';

  @override
  String get authForgotPasswordAction => 'पासवर्ड भूल गए?';

  @override
  String get authConfigIncompleteSignInMessage =>
      'इस build में Supabase configured नहीं है, इसलिए sign-in और live account data तब तक उपलब्ध नहीं होंगे जब तक environment ठीक नहीं किया जाता।';

  @override
  String get authContinueWithGoogle => 'Google से continue करें';

  @override
  String get authOrWithEmail => 'या ईमेल से जारी रखें';

  @override
  String get authPasswordTitle => 'Email और password';

  @override
  String get authPasswordSubtitle =>
      'अपने email और password से sign in करें, या आगे बढ़ने के लिए नया TranZfort account बनाएँ।';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordConfirmLabel => 'Password की पुष्टि करें';

  @override
  String get authPasswordHint => 'कम से कम 8 characters दर्ज करें';

  @override
  String get authPasswordModeSignIn => 'साइन इन';

  @override
  String get commonCreateAccountAction => 'खाता बनाएं';

  @override
  String get authPasswordSwitchToSignIn => 'पहले से account है? साइन इन करें';

  @override
  String get authPasswordSwitchToSignUp => 'TranZfort पर नए हैं? खाता बनाएं';

  @override
  String get authPasswordSignInAction => 'Password से sign in करें';

  @override
  String get authPasswordInvalidEmailMessage => 'वैध email address दर्ज करें।';

  @override
  String get authPasswordTooShortMessage =>
      'कम से कम 8 characters वाला password दर्ज करें।';

  @override
  String get authPasswordConfirmMismatchMessage =>
      'Password confirmation मेल नहीं खाती।';

  @override
  String get authPasswordSignInFailureMessage =>
      'अभी email और password से sign in नहीं हो सका। थोड़ी देर बाद फिर कोशिश करें या कोई दूसरा sign-in तरीका इस्तेमाल करें।';

  @override
  String get authPasswordSignUpFailureMessage =>
      'अभी आपका account नहीं बन सका। यही details लेकर थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get authPasswordCheckEmailTitle => 'अपना email देखें';

  @override
  String authPasswordCheckEmailSubtitle(Object email) {
    return 'हमने $email पर verification link भेजा है। उस email को खोलें, verification पूरा करें, और फिर यहां वापस आकर sign in करें।';
  }

  @override
  String get authPasswordResendVerificationAction =>
      'Verification email फिर भेजें';

  @override
  String authPasswordResendVerificationSuccessMessage(Object email) {
    return 'हमने $email पर एक नया verification email भेजा है। उसे खोलें, verification पूरा करें, और फिर sign in करें।';
  }

  @override
  String get authPasswordResendVerificationFailureMessage =>
      'अभी verification email फिर नहीं भेजा जा सका। थोड़ी देर बाद फिर कोशिश करें या कोई दूसरा email इस्तेमाल करें।';

  @override
  String get commonBackToSignInAction => 'Sign in पर वापस जाएँ';

  @override
  String get authPasswordUseDifferentEmailAction =>
      'कोई दूसरा email इस्तेमाल करें';

  @override
  String get authErrorEmailRequired => 'Email आवश्यक है';

  @override
  String get authErrorEmailInvalid => 'कृपया एक वैध email दर्ज करें';

  @override
  String get authErrorPasswordRequired => 'Password आवश्यक है';

  @override
  String get authErrorPasswordTooShort =>
      'Password कम से कम 8 characters का होना चाहिए';

  @override
  String get authErrorUserNotFound => 'User नहीं मिला';

  @override
  String get authErrorWrongPassword => 'गलत password';

  @override
  String get authErrorEmailAlreadyInUse => 'Email पहले से registered है';

  @override
  String get authErrorWeakPassword => 'Password बहुत कमजोर है';

  @override
  String get authRoleRequired => 'जारी रखने के लिए एक मान्य भूमिका चुनें';

  @override
  String get authNameTooShort => 'अपना पूरा नाम दर्ज करें';

  @override
  String get authMobileRequired => 'एक मान्य मोबाइल नंबर दर्ज करें';

  @override
  String get authLanguageUnsupported => 'एक समर्थित भाषा चुनें';

  @override
  String get authUnexpectedResponse =>
      'खाता हटाने अनुरोध से अप्रत्याशित प्रतिक्रिया प्रारूप';

  @override
  String get authGoogleNotConfigured =>
      'Google sign-in configured नहीं है। App environment में GOOGLE_WEB_CLIENT_ID सेट करें और फिर कोशिश करें।';

  @override
  String get authGoogleSignInCancelled =>
      'Google sign in cancel हो गया। फिर कोशिश करें।';

  @override
  String get authGoogleTokenFetchFailed =>
      'Google sign-in token लाने में असमर्थ। फिर कोशिश करें।';

  @override
  String get onboardingDiscardRoleTitle => 'Role selection छोड़ें?';

  @override
  String get onboardingDiscardRoleMessage => 'आपका चयनित role खो जाएगा';

  @override
  String get onboardingDiscardChangesTitle => 'Changes छोड़ें?';

  @override
  String get onboardingDiscardChangesMessage => 'आपका unsaved changes खो जाएगा';

  @override
  String get locationServicesDisabled => 'Location services बंद हैं';

  @override
  String get locationPermissionRequired => 'Location permission आवश्यक है';

  @override
  String get locationPermissionDenied => 'Location permission denied हो गया';

  @override
  String get locationEnableGps => 'GPS enable करें';

  @override
  String get locationEnableServicesMessage =>
      'Current location capture करने के लिए location services (GPS) enable करें।';

  @override
  String get locationGrantPermissionMessage =>
      'Current location capture करने के लिए location permission grant करें।';

  @override
  String get locationOpenSettings => 'Settings खोलें';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Location permission permanently denied हो गया। App settings में enable करें।';

  @override
  String get searchYourLocation => 'अपनी location खोजें';

  @override
  String get useCurrentLocation => 'Current location इस्तेमाल करें';

  @override
  String get addManually => 'Manually जोड़ें';

  @override
  String get clearLocation => 'Location साफ करें';

  @override
  String get routePreviewInvalidError => 'Route preview load नहीं हो सका';

  @override
  String get publicProfileLoadErrorTitle => 'प्रोफाइल लोड करने में विफल';

  @override
  String get publicProfileNotFoundTitle => 'प्रोफाइल नहीं मिली';

  @override
  String get supplierPostLoadSpecifyMaterialLabel => 'Material specify करें';

  @override
  String get supplierPostLoadSpecifyMaterialHint =>
      'जैसे, Fruits, Iron Ore, Bricks';

  @override
  String get supplierPostLoadMaterialCoal => 'कोयला';

  @override
  String get supplierPostLoadMaterialSteel => 'स्टील';

  @override
  String get supplierPostLoadMaterialCement => 'सीमेंट';

  @override
  String get supplierPostLoadMaterialGrains => 'अनाज';

  @override
  String get supplierPostLoadMaterialFertilizer => 'खाद';

  @override
  String get supplierPostLoadMaterialMachinery => 'मशीनरी';

  @override
  String get supplierPostLoadMaterialOther => 'अन्य';

  @override
  String get supplierPostLoadBodyTypeAny => 'कोई भी';

  @override
  String get supplierPostLoadBodyTypeOpen => 'खुला';

  @override
  String get supplierPostLoadBodyTypeContainer => 'कंटेनर';

  @override
  String get supplierPostLoadBodyTypeTrailer => 'ट्रेलर';

  @override
  String get supplierPostLoadBodyTypeTanker => 'टैंकर';

  @override
  String get supplierPostLoadBodyTypeRefrigerated => 'रेफ्रिजरेटेड';

  @override
  String get postLoadValidationCustomMaterialRequired =>
      'कृपया material specify करें';

  @override
  String get supplierLoadSubmissionAlreadyInProgress =>
      'लोड जमा करना पहले से प्रगति पर है';

  @override
  String get truckerFleetValidationTruckNumber =>
      'एक वैध truck number दर्ज करें';

  @override
  String get truckerFleetValidationTyreCount => 'एक वैध tyre count चुनें';

  @override
  String get truckerFleetValidationCapacityTonnes =>
      'Capacity 0 और 100 tonnes के बीच होनी चाहिए';

  @override
  String get truckerFleetValidationRcDocument => 'RC document आवश्यक है';

  @override
  String get truckerFleetErrorTruckNotFound => 'चयनित truck नहीं मिला';

  @override
  String get truckerFleetErrorSaveAlreadyInProgress =>
      'Truck save पहले से ही progress में है';

  @override
  String get truckerFleetErrorValidationFailed =>
      'highlighted truck details को सुधारें';

  @override
  String get truckerFleetBodyTypeOpen => 'खुला';

  @override
  String get truckerFleetBodyTypeContainer => 'कंटेनर';

  @override
  String get truckerFleetBodyTypeTrailer => 'ट्रेलर';

  @override
  String get truckerFleetBodyTypeTanker => 'टैंकर';

  @override
  String get truckerFleetBodyTypeRefrigerated => 'रेफ्रिजरेटेड';

  @override
  String chatTonnesCompact(Object value) {
    return '${value}T';
  }

  @override
  String get verificationCompleteAllFields => 'सभी आवश्यक फ़ील्ड पूरी करें';

  @override
  String get verificationLocationSourceManualCityEntry =>
      'मैन्युअल रूप से जोड़ा गया';

  @override
  String get verificationLocationSourceGoogleGeocode =>
      'GPS के माध्यम से कैप्चर किया गया';

  @override
  String get verificationLocationSourceOfflineNearestCity => 'ऑफ़लाइन स्थान';

  @override
  String get supportCategoryGeneral => 'सामान्य';

  @override
  String get supportCategoryAccount => 'खाता';

  @override
  String get supportCategoryLoad => 'लोड';

  @override
  String get supportCategoryTrip => 'यात्रा';

  @override
  String get supportCategoryPayment => 'भुगतान';

  @override
  String get supportCategoryTechnical => 'तकनीकल';

  @override
  String get supportCategoryOther => 'अन्य';

  @override
  String get reportIssueCategorySpamOrScam => 'स्पैम या घोटाला';

  @override
  String get reportIssueCategoryFakePayoutProof => 'फर्जी payout प्रूफ';

  @override
  String get reportIssueCategoryNonPayment => 'गैर-भुगतान';

  @override
  String get reportIssueCategoryAbusiveBehavior => 'दुर्व्यवहार';

  @override
  String get reportIssueContextSourceLabel => 'वर्तमान बातचीत या यात्रा संदर्भ';

  @override
  String get onboardingSelectRoleError =>
      'चुनें कि आप supplier के रूप में जुड़ रहे हैं या trucker के रूप में।';

  @override
  String get onboardingRoleWorkspaceFailure =>
      'अभी आपका role workspace तैयार नहीं हो सका। अपना role फिर चुनकर थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get onboardingRoleSaveFailure =>
      'अभी आपका role save नहीं हो सका। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get onboardingChooseRoleTitle => 'Role चुनें';

  @override
  String get onboardingRoleQuestion => 'आपके काम के लिए कौन-सा role सही है?';

  @override
  String get onboardingRoleSubtitle =>
      'आपकी भूमिका तय करेगी कि TranZfort आपके लिए कौन-से tools, डैशबोर्ड और workflows तैयार करेगा।';

  @override
  String get onboardingSupplierTitle => 'सप्लायर';

  @override
  String get onboardingSupplierSubtitle =>
      'लोड्स पोस्ट करें, बुकिंग्स रिव्यू करें, ट्रिप्स मैनेज करें और डिलीवरी फॉलो-थ्रू ट्रैक करें।';

  @override
  String get onboardingTruckerTitle => 'ट्रकर';

  @override
  String get onboardingTruckerSubtitle =>
      'लोड्स खोजें, फ्लीट रेडिनेस मैनेज करें और सक्रिय ट्रिप्स एक जगह से चलाएँ।';

  @override
  String get onboardingContinue => 'आगे बढ़ें';

  @override
  String get onboardingProfileSaveFailure =>
      'अभी आपकी प्रोफ़ाइल सेव नहीं हो सकी। विवरण जांचकर थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get onboardingCompleteProfileTitle => 'Profile पूरी करें';

  @override
  String get onboardingCompleteProfileHeading => 'अपनी basic profile पूरी करें';

  @override
  String get onboardingCompleteProfileSubtitle =>
      'वह मुख्य संपर्क विवरण जोड़ें जो सत्यापन और दैनिक संचालन में काम आएँगी।';

  @override
  String get onboardingFullNameLabel => 'पूरा नाम';

  @override
  String get onboardingFullNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get onboardingMobileLabel => 'मोबाइल नंबर';

  @override
  String get onboardingTermsAcceptance =>
      'आगे बढ़कर आप पुष्टि करते हैं कि आपकी basic profile details सही हैं और आप platform terms से सहमत हैं।';

  @override
  String get onboardingSaveAndContinue => 'सहेजकर आगे बढ़ें';

  @override
  String get commonRetryAction => 'फिर कोशिश करें';

  @override
  String get shellPressBackAgainToExit =>
      'बाहर निकलने के लिए फिर से वापस दबाएं';

  @override
  String get commonNotificationsLabel => 'सूचनाएँ';

  @override
  String get supplierMyLoadsTitle => 'मेरे लोड्स';

  @override
  String get supplierMyLoadsSubtitle =>
      'एक ही जगह से सक्रिय सप्लायर लोड्स, बुकिंग डिमांड, और पूर्ण लोड इतिहास देखें।';

  @override
  String get commonActiveLabel => 'सक्रिय';

  @override
  String get commonCompletedLabel => 'पूर्ण';

  @override
  String get supplierMyLoadsLoadFailureTitle =>
      'आपके सप्लायर लोड्स लोड नहीं हो सके';

  @override
  String get supplierMyLoadsFailureMessage =>
      'अभी आपके सप्लायर लोड्स लोड नहीं हो सके। नवीनतम लोड सूची रीफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierMyLoadsEmptyActiveTitle => 'अभी कोई सक्रिय लोड नहीं है';

  @override
  String get supplierMyLoadsEmptyCompletedTitle => 'अभी कोई पूर्ण लोड नहीं है';

  @override
  String get supplierMyLoadsEmptyActiveSubtitle =>
      'अपना पहला लोड पोस्ट करें ताकि बुकिंग अनुरोध और कार्यान्वयन अपडेट्स यहाँ दिखने लगें।';

  @override
  String get supplierMyLoadsEmptyCompletedSubtitle =>
      'पूर्ण, रद्द, समाप्त, और ऐप के बाहर भरे लोड सक्रिय कार्य बंद होने पर यहाँ दिखाई देंगे।';

  @override
  String get supplierMyLoadsOpenActiveLoads => 'सक्रिय लोड्स खोलें';

  @override
  String get supplierMyLoadsMoreUnavailableTitle =>
      'और supplier loads लोड नहीं हो सके';

  @override
  String get supplierMyLoadsPaginationFailureMessage =>
      'अभी और supplier loads लोड नहीं हो सके। Latest load history refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierMyLoadsLoadingMore => 'और loads लोड हो रही हैं...';

  @override
  String get supplierMyLoadsLoadMore => 'और loads लोड करें';

  @override
  String supplierLoadCardPickupDate(Object value) {
    return 'Pickup $value';
  }

  @override
  String supplierLoadCardTrucks(Object booked, Object needed) {
    return '$booked/$needed ट्रक बुक हुए';
  }

  @override
  String get supplierLoadCardTrackLoad => 'लोड ट्रैक करें';

  @override
  String get supplierLoadCardViewHistory => 'इतिहास देखें';

  @override
  String get commonViewDetailsAction => 'विवरण देखें';

  @override
  String get supplierRecentLoadsTitle => 'हाल के लोड्स';

  @override
  String supplierDashboardWelcomeBack(Object name) {
    return 'फिर से स्वागत है, $name';
  }

  @override
  String get commonDashboardOverviewTitle => 'डैशबोर्ड ओवरव्यू';

  @override
  String get supplierDashboardSuperLoadReadinessTitle => 'सुपर लोड तैयारी';

  @override
  String get commonQuickActionsTitle => 'त्वरित कार्रवाइयाँ';

  @override
  String get commonChatLabel => 'चैट';

  @override
  String get commonPostLoadAction => 'लोड पोस्ट करें';

  @override
  String get supplierDashboardStatsActiveLoadsLabel => 'सक्रिय लोड्स';

  @override
  String get supplierDashboardStatsPendingBookingsLabel => 'लंबित बुकिंग्स';

  @override
  String get supplierDashboardStatsInTransitTripsLabel => 'चल रही ट्रिप्स';

  @override
  String get supplierDashboardStatsCompletedTripsLabel => 'पूरी हुई ट्रिप्स';

  @override
  String get commonOpenMyLoadsAction => 'मेरे लोड्स खोलें';

  @override
  String get supplierDashboardLoadFailureTitle =>
      'आपका supplier dashboard लोड नहीं हो सका';

  @override
  String get supplierDashboardLoadFailureMessage =>
      'अभी आपका supplier dashboard लोड नहीं हो सका। Latest overview metrics refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierDashboardAccountStateUnavailableTitle =>
      'सप्लायर अकाउंट स्टेट उपलब्ध नहीं है';

  @override
  String get supplierDashboardAccountStateUnavailableMessage =>
      'अभी आपकी current supplier account state लोड नहीं हो सकी। Latest verification और company details restore करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierDashboardRecentLoadsUnavailableTitle =>
      'रीसेंट लोड्स उपलब्ध नहीं हैं';

  @override
  String get supplierDashboardRecentLoadsUnavailableMessage =>
      'अभी आपके recent supplier loads लोड नहीं हो सके। Latest load list refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierDashboardNoLoadsPostedTitle =>
      'अभी कोई load post नहीं किया गया';

  @override
  String get supplierDashboardNoLoadsPostedSubtitle =>
      'अपना पहला supplier load post करें ताकि booking requests और linked trip activity शुरू हो सके।';

  @override
  String get shellTabHome => 'होम';

  @override
  String get shellTitleSupplierDashboard => 'सप्लायर डैशबोर्ड';

  @override
  String get shellTabLoads => 'लोड्स';

  @override
  String get shellTitleMyLoads => 'मेरे लोड्स';

  @override
  String get commonTripsLabel => 'ट्रिप्स';

  @override
  String get commonDashboardLabel => 'डैशबोर्ड';

  @override
  String get shellTabFind => 'खोजें';

  @override
  String get shellTitleFindLoads => 'लोड्स खोजें';

  @override
  String get shellDrawerSupplierWorkspace => 'सप्लायर वर्कस्पेस';

  @override
  String get shellDrawerTruckerWorkspace => 'ट्रकर वर्कस्पेस';

  @override
  String get commonFleetLabel => 'फ्लीट';

  @override
  String get commonSupportLabel => 'सहायता';

  @override
  String get commonProfileLabel => 'प्रोफ़ाइल';

  @override
  String get commonSignOutAction => 'साइन आउट';

  @override
  String get shellSignOutFailureMessage =>
      'अभी साइन आउट नहीं हो सका। थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get shellMessagesTitle => 'संदेश';

  @override
  String get shellMessagesSupplierSubtitle =>
      'एक ही जगह से लोड-लिंक्ड ट्रकर बातचीत ट्रैक करें और जल्दी जवाब दें।';

  @override
  String get shellMessagesTruckerSubtitle =>
      'एक इनबॉक्स में सप्लायर अपडेट्स, रूट संदर्भ और बुकिंग फॉलो-थ्रू पर नज़र रखें।';

  @override
  String get shellMessagesSupplierGroupedInbox => 'ग्रुप्ड इनबॉक्स';

  @override
  String get shellMessagesTruckerFlatInbox => 'फ्लैट इनबॉक्स';

  @override
  String shellMessagesUnreadThreads(int count) {
    return '$count अनरीड थ्रेड्स';
  }

  @override
  String get shellMessagesLoadFailureTitle => 'संदेश लोड नहीं हो सके';

  @override
  String get shellMessagesEmptyTitle => 'अभी कोई बातचीत नहीं है';

  @override
  String get shellMessagesSupplierEmptySubtitle =>
      'पहला संदेश आने के बाद यहाँ लोड-लिंक्ड ट्रकर बातचीत दिखेंगी।';

  @override
  String get shellMessagesTruckerEmptySubtitle =>
      'किसी लोड पर चैट शुरू करें और आपकी सप्लायर बातचीत यहाँ दिखेंगी।';

  @override
  String shellMessagesActiveConversations(int count, Object preview) {
    return '$count सक्रिय बातचीत - $preview';
  }

  @override
  String get shellMessagesUnreadStatus => 'अनरीड';

  @override
  String get shellMessagesReadStatus => 'पढ़ा';

  @override
  String get shellMessagesHideTruckerConversations => 'ट्रकर बातचीत छिपाएँ';

  @override
  String shellMessagesLatestBy(Object name, Object timestamp) {
    return 'Latest by $name - $timestamp';
  }

  @override
  String get truckerChatSupplierAction => 'Supplier से chat करें';

  @override
  String get truckerLoadChatStartFailureMessage =>
      'अभी यह supplier chat शुरू नहीं हो सकी। थोड़ी देर बाद load detail से फिर कोशिश करें।';

  @override
  String get truckerTripChatStartFailureMessage =>
      'अभी यह supplier chat शुरू नहीं हो सकी। थोड़ी देर बाद trip detail से फिर कोशिश करें।';

  @override
  String truckerChatLockedLabel(Object reason) {
    return 'Chat उपलब्ध नहीं है: $reason';
  }

  @override
  String get chatTitleFallback => 'बातचीत';

  @override
  String get commonCallAction => 'कॉल';

  @override
  String chatReportSourceLabel(Object source) {
    return 'Chat - $source';
  }

  @override
  String get chatMenuMarkConversationRead => 'Conversation को read mark करें';

  @override
  String get chatMenuRefreshThread => 'Thread refresh करें';

  @override
  String get commonReportSpamOrAbuseAction => 'स्पैम या दुरुपयोग रिपोर्ट करें';

  @override
  String get chatConversationUnavailableTitle => 'Conversation उपलब्ध नहीं है';

  @override
  String get chatConversationUnavailableSubtitle =>
      'अभी यह conversation नहीं मिल सकी। Refresh करें या inbox पर लौटें।';

  @override
  String get chatBackToInboxAction => 'संदेशों पर वापस जाएं';

  @override
  String get chatBookingActionUnavailableTitle =>
      'Booking action उपलब्ध नहीं है';

  @override
  String get chatBookingActionFailureMessage =>
      'अभी इस chat से latest booking action पूरा नहीं हो सका। Booking state review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get chatApproveBookingDialogTitle => 'Booking approve करें?';

  @override
  String get chatApproveBookingDialogMessage =>
      'यह chat context से trucker booking request approve करेगा।';

  @override
  String get chatRejectBookingDialogTitle => 'Booking reject करें?';

  @override
  String get chatRejectBookingDialogMessage =>
      'यह chat context से trucker booking request reject करेगा।';

  @override
  String get commonCancelAction => 'रद्द करें';

  @override
  String get commonDiscardAction => 'छोड़ें';

  @override
  String get chatActionApprove => 'स्वीकृत करें';

  @override
  String get chatActionReject => 'अस्वीकृत करें';

  @override
  String get chatBookingApprovedSuccess => 'Booking approve हो गई!';

  @override
  String get chatBookingRejectedSuccess => 'Booking reject हो गई।';

  @override
  String get chatTextSendFailureMessage =>
      'अभी आपका message भेजा नहीं जा सका। थोड़ी देर बाद इसी chat से फिर कोशिश करें।';

  @override
  String get chatVoiceStartFailureMessage =>
      'अभी voice recording शुरू नहीं हो सकी। थोड़ी देर बाद इसी chat से फिर कोशिश करें।';

  @override
  String get chatVoiceUploadFailureMessage =>
      'अभी यह voice message upload नहीं हो सका। थोड़ी देर बाद इसी chat से फिर कोशिश करें।';

  @override
  String get chatVoiceSendFailureMessage =>
      'अभी यह voice message भेजा नहीं जा सका। थोड़ी देर बाद इसी chat से फिर कोशिश करें।';

  @override
  String get chatApproveBookingFailureMessage =>
      'अभी यह booking approve नहीं हो सकी। थोड़ी देर बाद इसी chat से फिर कोशिश करें।';

  @override
  String get chatRejectBookingFailureMessage =>
      'अभी यह booking reject नहीं हो सकी। थोड़ी देर बाद इसी chat से फिर कोशिश करें।';

  @override
  String get chatLoadContextTitle => 'लोड संदर्भ';

  @override
  String get chatCollapseLoadContextTooltip => 'लोड संदर्भ संक्षिप्त करें';

  @override
  String get chatExpandLoadContextTooltip => 'लोड संदर्भ विस्तृत करें';

  @override
  String chatMaterialLabel(Object value) {
    return 'सामग्री: $value';
  }

  @override
  String chatPriceLabel(Object value) {
    return 'मूल्य: $value';
  }

  @override
  String chatPickupLabel(Object value) {
    return 'पिकअप: $value';
  }

  @override
  String get chatBookingStatusApproved => 'स्वीकृत';

  @override
  String get commonUnknownLabel => 'अज्ञात';

  @override
  String get chatMessagesLoadFailureTitle => 'संदेश लोड नहीं हो सके';

  @override
  String get chatMessagesLoadFailureMessage =>
      'अभी यह बातचीत लोड नहीं हो सकी। नवीनतम संदेश और बुकिंग संदर्भ रीफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get chatNoMessagesTitle => 'अभी कोई संदेश नहीं है';

  @override
  String get chatNoMessagesSubtitle =>
      'यह बातचीत शुरू करने के लिए संदेश भेजें।';

  @override
  String get commonSystemUpdateLabel => 'सिस्टम अपडेट';

  @override
  String get chatSendingLabel => 'भेजा जा रहा है...';

  @override
  String get chatPauseVoiceMessageTooltip => 'Voice message pause करें';

  @override
  String get chatPlayVoiceMessageTooltip => 'Voice message चलाएँ';

  @override
  String get commonVoiceMessageLabel => 'आवाज़ संदेश';

  @override
  String get chatVoicePlaybackUnavailable =>
      'अभी voice playback उपलब्ध नहीं है।';

  @override
  String get chatVoicePlaybackFailed => 'अभी यह voice message चल नहीं सकी।';

  @override
  String get chatLocationSharedFallback => 'स्थान साझा किया गया';

  @override
  String get chatMapPreviewUnavailable => 'Map preview उपलब्ध नहीं है';

  @override
  String get chatOpenInMapsAction => 'Maps में खोलें';

  @override
  String get chatDocumentSharedFallback => 'दस्तावेज़ साझा किया गया';

  @override
  String get chatAttachmentSavedSubtitle =>
      'Attachment इस conversation में सेव है।';

  @override
  String get chatOpenDocumentAction => 'दस्तावेज़ खोलें';

  @override
  String get chatRouteSummaryFallback => 'मार्ग सारांश';

  @override
  String get chatViewRouteAction => 'मार्ग देखें';

  @override
  String get commonTruckDetailsLabel => 'ट्रक विवरण';

  @override
  String chatTruckTyresLabel(Object value) {
    return '$value टायर';
  }

  @override
  String get chatTypeMessageHint => 'संदेश टाइप करें...';

  @override
  String get chatStopRecordingTooltip => 'रिकॉर्डिंग रोकें';

  @override
  String get chatVoiceRecordingTooltip => 'आवाज रिकॉर्डिंग';

  @override
  String get chatSendAction => 'भेजें';

  @override
  String get commonHearSummary => 'सारांश सुनें';

  @override
  String get commonVoiceMuted => 'इस डिवाइस पर आवाज मार्गदर्शन म्यूट है।';

  @override
  String get commonVoiceUnavailable => 'अभी आवाज मार्गदर्शन उपलब्ध नहीं है।';

  @override
  String get notificationsMarkedAllReadSuccess =>
      'सभी सूचनाओं को पढ़ा मार्क कर दिया गया';

  @override
  String get notificationsMarkAllRead => 'सभी पढ़ें';

  @override
  String get notificationsLoadFailureTitle => 'सूचनाएँ लोड नहीं हो सकीं';

  @override
  String get notificationsMarkAllReadFailureMessage =>
      'अभी सभी सूचनाओं को पढ़ा मार्क नहीं किया जा सका। थोड़ी देर बाद सूचना स्क्रीन से फिर कोशिश करें।';

  @override
  String get notificationsLoadFailureMessage =>
      'अभी आपकी सूचनाएँ लोड नहीं हो सकीं। नए अलर्ट और अपडेट्स रीफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get notificationsEmptyTitle => 'आप पूरी तरह up to date हैं!';

  @override
  String get notificationsEmptySubtitle => 'कोई नई सूचनाएँ नहीं हैं।';

  @override
  String get notificationsOverviewTitle => 'अवलोकन';

  @override
  String notificationsUnreadCountLabel(int count) {
    return '$count अनरीड';
  }

  @override
  String notificationsHighPriorityCountLabel(int count) {
    return '$count उच्च प्राथमिकता';
  }

  @override
  String get commonLoadMoreAction => 'और लोड करें';

  @override
  String notificationsTtsSummary(int unreadCount, int highPriorityUnreadCount) {
    return 'सूचना स्क्रीन। आपके पास $unreadCount अनरीड सूचनाएँ हैं और $highPriorityUnreadCount उच्च प्राथमिकता अलर्ट समीक्षा के लिए लंबित हैं।';
  }

  @override
  String get notificationsGroupToday => 'आज';

  @override
  String get notificationsGroupYesterday => 'कल';

  @override
  String get notificationsPriorityHighLabel => 'उच्च';

  @override
  String get notificationsBodyFallback =>
      'पूरे संदर्भ के लिए लिंक्ड वर्कफ़्लो खोलें।';

  @override
  String notificationFallbackValue(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'verification_update': 'सत्यापन अपडेट',
      'booking_update': 'बुकिंग अपडेट',
      'trip_update': 'ट्रिप अपडेट',
      'proof_update': 'प्रमाण अपडेट',
      'super_load_update': 'Super Load अपडेट',
      'message_received': 'नया संदेश',
      'support_update': 'सहायता अपडेट',
      'dispute_update': 'विवाद अपडेट',
      'account_update': 'खाता अपडेट',
      'system_notice': 'सिस्टम सूचना',
      'load_expiry_warning': 'लोड समाप्ति चेतावनी',
      'other': 'सूचना',
    });
    return '$_temp0';
  }

  @override
  String get navDeleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountRequestedOnLabel => 'Deletion अनुरोध किया गया';

  @override
  String get deleteAccountGracePeriodEndsLabel => 'Grace period समाप्ति';

  @override
  String get deleteAccountGracePeriodPassedLabel =>
      'Grace-period की अंतिम तारीख बीत चुकी है। स्थायी deletion प्रक्रिया किसी भी समय हो सकती है।';

  @override
  String get deleteAccountGracePeriodLessThanOneDayLabel =>
      'Grace period समाप्त होने में 1 दिन से कम बाकी है।';

  @override
  String deleteAccountGracePeriodRemainingDaysLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Grace period समाप्त होने में $count दिन बाकी हैं।',
      one: 'Grace period समाप्त होने में $count दिन बाकी है।',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccountLifecycleFailureMessage =>
      'खाता deletion lifecycle अभी अस्थायी रूप से उपलब्ध नहीं है। नवीनतम deletion स्थिति रीफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get deleteAccountCancelFailureMessage =>
      'अभी यह deletion अनुरोध रद्द नहीं हो सका। Deletion lifecycle स्क्रीन से थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get deleteAccountRequestFailureMessage =>
      'अभी यह deletion अनुरोध प्रक्रिया नहीं हो सका। वर्तमान खाता स्थिति देखें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get deleteAccountAcceptedSignOutFailureMessage =>
      'Deletion स्वीकार हो गया, लेकिन अभी साइन आउट पूरा नहीं हो सका। खाता सत्र रीफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get deleteAccountBlockedSummaryMessage =>
      'यह deletion अनुरोध अभी आगे नहीं बढ़ सकता क्योंकि एक और खाता निर्भरता पर अभी ध्यान देना बाकी है।';

  @override
  String get deleteAccountCancelledMessage =>
      'आपका deletion अनुरोध रद्द कर दिया गया। Lifecycle सक्रिय होने तक खाता पहुँच बहाल की जा सकती है।';

  @override
  String get deleteAccountAcceptedMessage =>
      'आपका deletion अनुरोध स्वीकार हो गया। खाता cleanup की प्रतीक्षा में आने पर आपको साइन आउट कर दिया गया है।';

  @override
  String get deleteAccountBlockerRecoveryGuidanceActiveTrips =>
      'पहले हर सक्रिय ट्रिप पूरी करें या रद्द करें, फिर deletion अनुरोध दोबारा दें।';

  @override
  String get deleteAccountBlockerRecoveryGuidanceDispute =>
      'दोबारा deletion अनुरोध देने से पहले अनसुलझे विवाद की समीक्षा या समाधान होने तक प्रतीक्षा करें।';

  @override
  String get deleteAccountBlockerRecoveryGuidanceCompliance =>
      'कुछ रिकॉर्ड अभी compliance या retention नीति के लिए प्लेटफ़ॉर्म पर रहने चाहिए। रोक के बारे में स्पष्टीकरण के लिए सहायता का उपयोग करें।';

  @override
  String get deleteAccountBlockerRecoveryGuidanceDefault =>
      'पहले अवरोधक निर्भरता हल करें, फिर दोबारा deletion अनुरोध दें।';

  @override
  String get deleteAccountBlockerActionOpenTrips => 'ट्रिप्स खोलें';

  @override
  String get commonOpenSupportAction => 'सहायता खोलें';

  @override
  String get deleteAccountBlockerTitleActiveTrips =>
      'पहले सक्रिय ट्रिप्स पूरी करें';

  @override
  String get deleteAccountBlockerTitleDispute => 'पहले खुला विवाद हल करें';

  @override
  String get deleteAccountBlockerTitleCompliance =>
      'Compliance रोक हटने की प्रतीक्षा करें';

  @override
  String get deleteAccountBlockerTitleDefault => 'पहले अवरोधक हल करें';

  @override
  String get deleteAccountBlockerBodyActiveTrips =>
      'इस खाते से अभी भी सक्रिय ट्रिप कार्य जुड़ा है। वर्तमान ट्रिप सूची देखें, कोई भी वैध सक्रिय कार्य पूरा करें, और फिर deletion अनुरोध दोबारा दें।';

  @override
  String get deleteAccountBlockerBodyDispute =>
      'इस खाते पर अभी भी एक अनसुलझा विवाद या समीक्षा निर्भरता है। अवरोधक विवाद हल होने तक वर्तमान केस follow करने के लिए सहायता का उपयोग करें।';

  @override
  String get deleteAccountBlockerBodyCompliance =>
      'यह खाता अभी भी compliance या retention रोक के तहत है। सहायता वर्तमान रोक स्पष्ट कर सकती है, लेकिन प्लेटफ़ॉर्म retention आवश्यकता को बायपास नहीं कर सकता।';

  @override
  String get deleteAccountBlockerBodyDefault =>
      'वर्तमान अवरोधक की ध्यानपूर्वक समीक्षा करें और deletion अनुरोध दोबारा देने से पहले इसे हल करें।';

  @override
  String get deleteAccountSupportTitle => 'पहले मदद चाहिए?';

  @override
  String get deleteAccountSupportBodyPendingCleanup =>
      'अगर pending-cleanup स्थिति, grace-period समयरेखा, या इस खाते के लिए रद्दीकरण सही अगला कदम है, इसके बारे में स्पष्टीकरण चाहिए तो सहायता का उपयोग करें।';

  @override
  String get deleteAccountSupportBodyDefault =>
      'अगर आपको सक्रिय ट्रिप्स, अनसुलझे विवाद, या compliance रोक जैसे अवरोधक होने की उम्मीद है और deletion अनुरोध दोबारा देने से पहले स्पष्टीकरण चाहिए तो सहायता का उपयोग करें।';

  @override
  String get deleteAccountSupportDetailPendingCleanup =>
      'सहायता वर्तमान lifecycle स्थिति स्पष्ट कर सकती है, लेकिन स्थायी deletion प्रक्रिया से पहले उन्हें retention और compliance नीति का पालन करना पड़ सकता है।';

  @override
  String get deleteAccountSupportDetailDefault =>
      'सहायता वर्तमान अवरोधक या retention आवश्यकता समझा सकती है, लेकिन वे आवश्यक cleanup, विवाद समीक्षा, या compliance नीति को बायपास नहीं कर सकती।';

  @override
  String get commonWhatHappensNextTitle => 'आगे क्या होगा';

  @override
  String get deleteAccountWhatHappensNextBodyPendingCleanup =>
      'आपका खाता पहले से pending-cleanup स्थिति में है। अगर स्थायी deletion प्रक्रिया से पहले खाता सक्रिय बहाल करना चाहते हैं तो अनुरोध रद्द करें।';

  @override
  String get deleteAccountWhatHappensNextBodyDefault =>
      'अगर कोई अवरोधक नहीं है, तो आपका खाता निष्क्रिय pending cleanup में चला जाता है और आपको सुरक्षित रूप से साइन आउट कर दिया जाता है।';

  @override
  String get deleteAccountWhatHappensNextDetailPendingCleanup =>
      'अगर अभी रद्द करते हैं, तो खाता deletion स्थिति सक्रिय हो जाती है और सामान्य पहुँच बहाल हो जाती है।';

  @override
  String get deleteAccountWhatHappensNextDetailDefault =>
      'अगर अवरोधक हैं, तो प्लेटफ़ॉर्म आपका खाता सक्रिय रखता है और बताता है कि कौन-सी निर्भरता पहले हल करनी होगी।';

  @override
  String get deleteAccountWhatHappensNextFootnotePendingCleanup =>
      'सहायता नीति के अनुसार आंतरिक रिकॉर्ड रख सकती है, लेकिन उपयोगकर्ता का deletion अनुरोध रद्द कर दिया जाएगा।';

  @override
  String get deleteAccountWhatHappensNextFootnoteDefault =>
      'स्थायी deletion प्रक्रिया से पहले जब तक खाता pending-cleanup lifecycle में है, deletion अनुरोध रद्द किया जा सकता है।';

  @override
  String get deleteAccountLifecycleUnavailableTitle =>
      'खाता deletion lifecycle उपलब्ध नहीं है';

  @override
  String get deleteAccountCancelledTitle => 'Deletion अनुरोध रद्द हो गया';

  @override
  String get deleteAccountAlreadyRequestedTitle =>
      'Deletion पहले से अनुरोधित है';

  @override
  String get deleteAccountAlreadyRequestedMessage =>
      'यह खाता वर्तमान में निष्क्रिय pending cleanup में है। Grace-period lifecycle के दौरान पहुँच बहाल करनी हो तो नीचे अनुरोध रद्द करें।';

  @override
  String get commonCancelDeletionRequestAction => 'Deletion अनुरोध रद्द करें';

  @override
  String get deleteAccountCancellingButton => 'Deletion रद्द हो रहा है...';

  @override
  String get deleteAccountUnavailableTitle => 'खाता deletion उपलब्ध नहीं है';

  @override
  String get deleteAccountBlockedTitle => 'Deletion अवरुद्ध है';

  @override
  String get deleteAccountConfirmRequestTitle =>
      'Deletion अनुरोध की पुष्टि करें';

  @override
  String get deleteAccountRequestingButton => 'Deletion अनुरोध हो रहा है...';

  @override
  String get deleteAccountScreenTitle => 'खाता हटाएँ';

  @override
  String get deleteAccountHeroTitlePendingCleanup =>
      'खाता deletion cleanup की प्रतीक्षा में';

  @override
  String get deleteAccountHeroTitleDefault => 'खाता deletion का अनुरोध करें';

  @override
  String get deleteAccountHeroSubtitlePendingCleanup =>
      'आपका खाता वर्तमान में निष्क्रिय pending cleanup में है। जब तक खाता स्थायी रूप से हटाया नहीं जाता, grace-period lifecycle के दौरान आप यह अनुरोध रद्द कर सकते हैं।';

  @override
  String get deleteAccountHeroSubtitleDefault =>
      'अगर कोई सक्रिय अवरोधक नहीं है तो यह कार्रवाई आपका खाता तुरंत निष्क्रिय कर सकती है। आगे बढ़ने से पहले परिणामों की ध्यानपूर्वक समीक्षा करें।';

  @override
  String get deleteAccountHeroBodyPendingCleanup =>
      'Deletion अनुरोध पहले ही स्वीकार हो चुका है और खाता pending-cleanup स्थिति में है। स्थायी deletion प्रक्रिया से पहले सामान्य खाता पहुँच बहाल करनी हो तो अनुरोध रद्द करें।';

  @override
  String get deleteAccountHeroBodyDefault =>
      'Deletion आगे बढ़ने से पहले, प्लेटफ़ॉर्म सक्रिय ट्रिप्स, अनसुलझे विवाद, और compliance या सत्यापन रिकॉर्ड जिन्हें अभी रखना ज़रूरी है, की जाँच करता है।';

  @override
  String get accountSignOutFailureMessage =>
      'अभी आपको sign out नहीं किया जा सका। थोड़ी देर बाद इसी screen से फिर कोशिश करें।';

  @override
  String accountRoleValue(String role) {
    String _temp0 = intl.Intl.selectLogic(role, {
      'supplier': 'सप्लायर',
      'trucker': 'ट्रकर',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String get accountStatusTitle => 'खाता स्थिति';

  @override
  String get accountProfileStatusLabel => 'प्रोफ़ाइल स्थिति';

  @override
  String get accountProfileStatusComplete => 'पूर्ण';

  @override
  String get accountProfileStatusNeedsAttention => 'ध्यान देना आवश्यक';

  @override
  String get accountAccountStateLabel => 'खाता स्थिति';

  @override
  String accountStateValue(String state) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'deactivated_pending_cleanup': 'निष्क्रिय, cleanup लंबित',
      'restricted': 'प्रतिबंधित',
      'active': 'सक्रिय',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String get accountLoadFailureTitle => 'Account details उपलब्ध नहीं हैं';

  @override
  String get accountLoadFailureMessage =>
      'अभी आपकी account details लोड नहीं हो सकीं। थोड़ी देर बाद इसी screen से फिर कोशिश करें।';

  @override
  String get accountManageTitle => 'खाता प्रबंधित करें';

  @override
  String get accountVerificationLabel => 'सत्यापन';

  @override
  String get accountSettingsLabel => 'सेटिंग्स';

  @override
  String get accountSessionTitle => 'वर्तमान सत्र';

  @override
  String get accountSignedInAsLabel => 'इस रूप में साइन इन';

  @override
  String get accountCurrentAuthenticatedSession => 'वर्तमान प्रमाणित सत्र';

  @override
  String get profileLoadFailureTitle => 'Profile उपलब्ध नहीं है';

  @override
  String get profileLoadFailureMessage =>
      'अभी आपकी profile लोड नहीं हो सकी। थोड़ी देर बाद इसी screen से फिर कोशिश करें।';

  @override
  String get profileSummaryTitle => 'प्रोफ़ाइल सारांश';

  @override
  String get profileNameLabel => 'नाम';

  @override
  String get profileValueNotSet => 'सेट नहीं है';

  @override
  String get profilePhoneLabel => 'फ़ोन';

  @override
  String get profileValueNotProvided => 'उपलब्ध नहीं';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileRoleLabel => 'भूमिका';

  @override
  String get profileLocationLabel => 'स्थान';

  @override
  String get profileLocationNotSet => 'सेट नहीं है';

  @override
  String get profileReadinessTitle => 'प्रोफ़ाइल तैयारी';

  @override
  String get profileCompletenessLabel => 'पूर्णता';

  @override
  String get profileCompletenessComplete => 'पूर्ण';

  @override
  String get profileCompletenessNeedsUpdates => 'अपडेट ज़रूरी';

  @override
  String get profileDeletionStatusLabel => 'Deletion स्थिति';

  @override
  String get profileOpenFleetReadiness => 'फ्लीट तैयारी खोलें';

  @override
  String get profileRequestAccountDeletion => 'खाता deletion का अनुरोध करें';

  @override
  String profileTtsSummary(
    Object roleLabel,
    Object trustStatus,
    Object deletionStatus,
  ) {
    return 'Profile screen. Role $roleLabel है. Trust and safety status $trustStatus है. Account deletion status $deletionStatus है. ज़रूरत हो तो इसी screen से deletion follow-up या support guidance खोली जा सकती है.';
  }

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsPreferencesTitle => 'प्राथमिकताएँ';

  @override
  String get settingsRoleContextLabel => 'भूमिका संदर्भ';

  @override
  String settingsTtsSummary(Object selectedLanguageLabel, Object roleSentence) {
    return 'सेटिंग्स स्क्रीन। भाषा $selectedLanguageLabel पर सेट है। आवाज मार्गदर्शन अभी मैनुअल है। सूचनाएँ इन-ऐप इनबॉक्स के माध्यम से सक्षम हैं।$roleSentence';
  }

  @override
  String get settingsVoiceAssistanceLabel => 'आवाज सहायता';

  @override
  String get settingsVoiceAssistanceValue =>
      'समर्थित स्क्रीन पर मैनुअल संदर्भित सारांश उपलब्ध हैं।';

  @override
  String get settingsNotificationsValue =>
      'इन-ऐप इनबॉक्स और पुश स्थिति नियंत्रण यहाँ उपलब्ध हैं।';

  @override
  String get settingsConnectedSurfacesTitle => 'जुड़े सतह';

  @override
  String get settingsPushNotificationsTitle => 'पुश सूचनाएँ';

  @override
  String get settingsPushStatusLabel => 'स्थिति';

  @override
  String get settingsPushRequestPermission => 'अनुमति अनुरोध';

  @override
  String get settingsPushRefreshStatus => 'स्थिति रीफ्रेश';

  @override
  String get settingsPushStatusUnavailableTitle =>
      'पुश सूचना स्थिति उपलब्ध नहीं है';

  @override
  String get settingsPushStatusUnavailableMessage =>
      'अभी डिवाइस सूचना अनुमति नहीं पढ़ी जा सकी। फायरबेस/डिवाइस सहायता उपलब्ध होने के बाद रीफ्रेश करें।';

  @override
  String settingsPushStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'allowed': 'अनुमति दी गई',
      'allowed_quietly': 'शांत रूप से अनुमति दी गई',
      'blocked': 'सिस्टम सेटिंग्स में ब्लॉक है',
      'not_requested': 'अभी तक अनुरोध नहीं किया गया',
      'unavailable': 'इस डिवाइस/build पर उपलब्ध नहीं',
      'other': 'इस डिवाइस/build पर उपलब्ध नहीं',
    });
    return '$_temp0';
  }

  @override
  String settingsPushGuidanceValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'allowed':
          'फायरबेस डिलीवरी कॉन्फ़िगर होने पर अग्रभूमि और खुली पुश प्रवाह सक्षम रहते हैं।',
      'allowed_quietly':
          'पुश शांत रूप से अनुमति दी गई है। ज़रूरत हो तो डिवाइस सूचना सेटिंग्स में अलर्ट प्रमोट कर सकते हैं।',
      'blocked':
          'पुश सूचनाएँ ब्लॉक हैं। अलर्ट फिर से सक्षम करने के लिए TranZfort की डिवाइस सूचना सेटिंग्स खोलें।',
      'not_requested':
          'इस device session पर push permission अभी request नहीं की गई है।',
      'unavailable':
          'Firebase/device support पूरी तरह configured होने तक यहाँ push runtime उपलब्ध नहीं है।',
      'other':
          'Firebase/device support पूरी तरह configured होने तक यहाँ push runtime उपलब्ध नहीं है।',
    });
    return '$_temp0';
  }

  @override
  String supportActiveTicketCount(Object count, Object s) {
    return '$count ticket$s';
  }

  @override
  String get supportScreenTitle => 'सहायता और विवाद फॉलो-अप';

  @override
  String get supportHeroTitle => 'अपनी नवीनतम सहायता गतिविधि समीक्षा करें';

  @override
  String get supportHeroSubtitleSupplier =>
      'सप्लायर गतिविधि से जुड़े विवाद प्रगति, भुगतान फॉलो-अप, और नवीनतम दृश्यमान टिकट अपडेट्स समीक्षा करने के लिए सहायता का उपयोग करें।';

  @override
  String get supportHeroSubtitleTrucker =>
      'ट्रकर गतिविधि से जुड़े विवाद प्रगति, फ्रेट फॉलो-अप, और नवीनतम दृश्यमान टिकट अपडेट्स समीक्षा करने के लिए सहायता का उपयोग करें।';

  @override
  String get supportNoActiveTickets => 'कोई सक्रिय टिकट नहीं';

  @override
  String get supportCreateTicketAction => 'सहायता टिकट बनाएँ';

  @override
  String get supportIntroMessage =>
      'अपनी latest support और dispute tickets यहाँ follow करें, visible workflow updates review करें, और support द्वारा मांगी गई clarification या proof के साथ reply करें।';

  @override
  String get supportTicketSummaryTitle => 'सपोर्ट सारांश';

  @override
  String get supportEscalationPathLabel => 'एस्केलेशन पथ';

  @override
  String get supportEscalationPathSupplier => 'सप्लायर सपोर्ट';

  @override
  String get supportEscalationPathTrucker => 'ट्रकर सपोर्ट';

  @override
  String get supportCurrentTrustStatusLabel => 'वर्तमान ट्रस्ट स्थिति';

  @override
  String get supportMyTicketsTitle => 'मेरी tickets';

  @override
  String get supportSelectedTicketAndReplyTitle => 'चुनी गई ticket और reply';

  @override
  String get supportSelectTicketTitle => 'एक ticket चुनें';

  @override
  String get supportSelectTicketSubtitle =>
      'Visible thread, workflow state, और reply options review करने के लिए list से एक support ticket चुनें।';

  @override
  String get supportTicketsUnavailableTitle =>
      'Support tickets अभी उपलब्ध नहीं हैं';

  @override
  String get supportNoTicketsTitle => 'अभी कोई support ticket नहीं है';

  @override
  String get supportNoTicketsSubtitle =>
      'नई support या dispute follow-up शुरू करने और future updates यहीं track करने के लिए support ticket बनाएँ।';

  @override
  String get supportLoadingOlderTickets => 'पुरानी tickets लोड हो रही हैं...';

  @override
  String get supportLoadOlderTickets => 'पुरानी tickets लोड करें';

  @override
  String get supportTicketsLoadFailureMessage =>
      'अभी आपकी support tickets लोड नहीं हो सकीं। Latest support और dispute activity refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supportOpenTripAction => 'ट्रिप खोलें';

  @override
  String get supportOpenLoadAction => 'लोड खोलें';

  @override
  String get supportViewingThisTicket => 'यह ticket देखी जा रही है';

  @override
  String get supportOpenTicketAction => 'Ticket खोलें';

  @override
  String get supportDetailUnavailableTitle => 'Ticket detail उपलब्ध नहीं है';

  @override
  String get supportDetailUnavailableMessage =>
      'अभी यह ticket detail लोड नहीं हो सकी। Latest visible thread और workflow status refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supportTicketUnavailableTitle => 'Ticket उपलब्ध नहीं है';

  @override
  String get supportTicketUnavailableSubtitle =>
      'यह support ticket अभी इस account के लिए उपलब्ध नहीं है।';

  @override
  String supportTicketStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'open': 'खुली',
      'in_progress': 'Review में',
      'waiting_for_you': 'आपके reply का इंतजार',
      'resolved': 'समाधान हो गया',
      'closed': 'बंद',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String supportTicketPriorityValue(String priority) {
    String _temp0 = intl.Intl.selectLogic(priority, {
      'low': 'कम',
      'medium': 'मध्यम',
      'high': 'उच्च',
      'urgent': 'अत्यावश्यक',
      'not_set': 'set नहीं है',
      'other': 'set नहीं है',
    });
    return '$_temp0';
  }

  @override
  String get supportTicketTitleTripDisputeReview => 'ट्रिप विवाद समीक्षा';

  @override
  String get supportTicketTitleLoadedQuantityMismatchReport =>
      'लोडेड मात्रा बेमेल रिपोर्ट';

  @override
  String get supportTicketTitleUnloadedQuantityMismatchReport =>
      'अनलोडेड मात्रा बेमेल रिपोर्ट';

  @override
  String get supportTicketTitleDocumentMismatchReport =>
      'दस्तावेज बेमेल रिपोर्ट';

  @override
  String get supportTicketTitleSpamOrScamReport => 'स्पैम या स्कैम रिपोर्ट';

  @override
  String get supportTicketTitleAbusiveBehaviorReport => 'दुर्व्यवहार रिपोर्ट';

  @override
  String get supportTicketTitleFakePayoutProofReport =>
      'नकली भुगतान प्रमाण रिपोर्ट';

  @override
  String get supportTicketTitleNonPaymentReport => 'गैर-भुगतान रिपोर्ट';

  @override
  String get supportTicketTitleDelayOrNoShowReport => 'देरी या नो-शो रिपोर्ट';

  @override
  String get supportTicketTitleDamageOrShortageReport => 'क्षति या कमी रिपोर्ट';

  @override
  String get supportTicketTitleOtherReport => 'अन्य रिपोर्ट';

  @override
  String get supportDisputeCategoryTripDispute => 'ट्रिप विवाद';

  @override
  String get supportDisputeCategoryLoadedQuantityMismatch =>
      'लोडेड मात्रा बेमेल';

  @override
  String get supportDisputeCategoryUnloadedQuantityMismatch =>
      'अनलोडेड मात्रा बेमेल';

  @override
  String get supportDisputeCategoryDocumentMismatch => 'दस्तावेज बेमेल';

  @override
  String get supportDisputeCategoryNonPayment => 'गैर-भुगतान';

  @override
  String get supportDisputeCategoryFakePayoutProof => 'नकली भुगतान प्रमाण';

  @override
  String get supportDisputeCategoryDelayOrNoShow => 'Delay या no-show';

  @override
  String get supportDisputeCategoryDamageOrShortage => 'Damage या shortage';

  @override
  String get supportDisputeCategoryAbusiveBehavior => 'दुर्व्यवहार';

  @override
  String get supportDisputeCategorySpamOrScam => 'Spam या scam';

  @override
  String get supportDisputeCategoryOther => 'अन्य';

  @override
  String supportUpdatedAt(Object value) {
    return 'अपडेट किया गया: $value';
  }

  @override
  String get supportTicketReference => 'सपोर्ट टिकट';

  @override
  String get supportTripReference => 'लिंक की गई ट्रिप';

  @override
  String supportOpenedAt(Object value) {
    return 'खोला गया: $value';
  }

  @override
  String supportDisputeCategoryLabel(Object category) {
    return 'विवाद श्रेणी: $category';
  }

  @override
  String get supportTicketIdValue => 'सपोर्ट टिकट रिकॉर्ड में है';

  @override
  String supportPriorityValue(Object priority) {
    return 'Priority: $priority';
  }

  @override
  String supportLastUpdatedValue(Object value) {
    return 'अंतिम अपडेट: $value';
  }

  @override
  String get supportRelatedTripValue => 'संबंधित ट्रिप लिंक की गई है';

  @override
  String get supportRelatedLoadValue => 'संबंधित लोड लिंक की गई है';

  @override
  String get supportOpenRelatedTripAction => 'Related trip खोलें';

  @override
  String get supportOpenRelatedLoadAction => 'Related load खोलें';

  @override
  String get supportWorkflowGuidanceOpen =>
      'Support को यह ticket मिल चुकी है और review जल्द शुरू होनी चाहिए। ज़रूरत हो तो visible replies में missing context जोड़ें।';

  @override
  String get supportWorkflowGuidanceInProgress =>
      'Support या operations इस ticket को actively review कर रहे हैं। Visible replies देखते रहें और ज़रूरत पड़ने पर timeline या proof साफ़ रखें।';

  @override
  String get supportWorkflowGuidanceWaitingForUser =>
      'Support आपके clarification या proof का इंतजार कर रही है। इस ticket पर reply करें ताकि review बिना अनावश्यक देरी के जारी रहे।';

  @override
  String get supportWorkflowGuidanceResolved =>
      'यह ticket final support outcome तक पहुँच चुकी है। नया follow-up खोलने से पहले recorded resolution review करें।';

  @override
  String get supportWorkflowGuidanceUnknown =>
      'Current workflow state के लिए latest visible ticket updates review करें।';

  @override
  String get commonDisputeReviewClosedTitle => 'विवाद समीक्षा बंद हो गई है';

  @override
  String get supportDisputeBannerTitleWaiting =>
      'Dispute आपके reply का इंतजार कर रही है';

  @override
  String get supportDisputeBannerTitleInProgress => 'विवाद समीक्षा जारी है';

  @override
  String supportDisputeBannerMessageClosed(Object category) {
    return 'Category: $category. यह trip dispute final support outcome तक पहुँच चुकी है। दोनों sides recorded ticket context follow कर सकती हैं, लेकिन raw evidence access restricted रह सकती है।';
  }

  @override
  String supportDisputeBannerMessageWaiting(Object category) {
    return 'Category: $category. यह trip dispute आपके clarification या proof का इंतजार कर रही है। दोनों sides visible status updates follow कर सकती हैं, लेकिन review के दौरान raw evidence access restricted रह सकती है।';
  }

  @override
  String supportDisputeBannerMessageInProgress(Object category) {
    return 'Category: $category. यह trip dispute active support review में है। दोनों sides visible status updates follow कर सकती हैं, लेकिन review के दौरान raw evidence access restricted रह सकती है।';
  }

  @override
  String get supportEvidenceVisibilitySummaryClosed =>
      'दोनों parties recorded dispute category, final workflow state, और visible support replies को इस ticket पर अभी भी follow कर सकती हैं।';

  @override
  String get supportEvidenceVisibilitySummaryInProgress =>
      'दोनों parties dispute category, workflow status, और support replies को follow कर सकती हैं जो इस ticket पर intentionally visible रखी गई हैं।';

  @override
  String get supportRestrictedEvidenceMessageClosed =>
      'Review outcome record होने के बाद भी raw attachments और sensitive proof restricted रह सकती हैं।';

  @override
  String get supportRestrictedEvidenceMessageInProgress =>
      'जब तक यह review active है, raw attachments और sensitive proof restricted रह सकती हैं।';

  @override
  String get supportAdditionalProofGuidanceClosed =>
      'अगर आपको लगता है कि closure से पहले important proof consider नहीं हुई, तो fresh support follow-up तभी शुरू करें जब आपके पास वास्तव में नई issue या clarification हो।';

  @override
  String get supportAdditionalProofGuidanceInProgress =>
      'अगर आपकी dispute current single-image flow से आगे additional documents या screenshots पर निर्भर है, तो missing proofs को visible reply में साफ़ लिखें ताकि support जान सके कि और क्या review करना है।';

  @override
  String get supportAttachmentVisibilityMessageClosed =>
      'इस reply में evidence attached है। Review outcome record होने के बाद भी raw file access restricted रह सकती है।';

  @override
  String get supportAttachmentVisibilityMessageInProgress =>
      'इस reply में evidence attached है। Review के दौरान raw file access restricted रह सकती है।';

  @override
  String get supportAttachmentGuidanceMessageClosed =>
      'अगर closure के बाद भी दूसरे supporting proofs का reference देना है, तो fresh follow-up तभी खोलें जब आपके पास वास्तव में नई context हो जो इस ticket पर capture नहीं हुई थी।';

  @override
  String get supportAttachmentGuidanceMessageInProgress =>
      'अगर दूसरे supporting proofs यहाँ attached नहीं हैं, तो उन्हें visible reply text में summarize करें ताकि support उन्हें safely request या review कर सके।';

  @override
  String get supportSupportTeamLabel => 'सपोर्ट टीम';

  @override
  String get supportYouLabel => 'आप';

  @override
  String get supportEmptyThreadSubtitleOpen =>
      'इस support ticket पर अभी कोई visible thread post नहीं की गई है।';

  @override
  String get supportEmptyThreadSubtitleInProgress =>
      'जब तक यह ticket active review में है, visible thread अभी उपलब्ध नहीं है।';

  @override
  String get supportEmptyThreadSubtitleWaiting =>
      'Visible thread अभी उपलब्ध नहीं है। इस ticket पर reply करें ताकि review जारी रह सके।';

  @override
  String get supportEmptyThreadSubtitleResolved =>
      'इस ticket के resolved या closed होने से पहले कोई visible thread record नहीं की गई थी।';

  @override
  String get supportEmptyThreadSubtitleUnknown =>
      'इस support ticket के लिए अभी कोई visible thread उपलब्ध नहीं है।';

  @override
  String get supportEvidenceVisibilityTitle => 'प्रमाण दृश्यता';

  @override
  String get supportVisibleThreadSummaryTitle => 'दृश्यमान थ्रेड सारांश';

  @override
  String supportVisibleRepliesCount(int count) {
    return 'दृश्यमान उत्तर: $count';
  }

  @override
  String get supportLastVisibleUpdateNone =>
      'अंतिम दृश्यमान अपडेट: अभी कोई दृश्यमान उत्तर नहीं है।';

  @override
  String supportLastVisibleUpdate(Object value) {
    return 'अंतिम दृश्यमान अपडेट: $value';
  }

  @override
  String get supportLatestVisibleSenderNone =>
      'नवीनतम दृश्यमान प्रेषक: अभी कोई दृश्यमान प्रेषक नहीं है।';

  @override
  String supportLatestVisibleSender(Object value) {
    return 'नवीनतम दृश्यमान प्रेषक: $value';
  }

  @override
  String get supportVisibleAttachmentSummaryPresent =>
      'Visible attachment summary: एक या अधिक visible replies में attachment reference शामिल है।';

  @override
  String get supportVisibleAttachmentSummaryAbsent =>
      'Visible attachment summary: अभी किसी visible reply में attachment reference नहीं है।';

  @override
  String get supportNoVisibleThreadTitle => 'अभी कोई visible thread नहीं है';

  @override
  String get supportCurrentWorkflowTitle => 'वर्तमान वर्कफ़्लो';

  @override
  String get supportResolutionOutcomeTitle => 'समाधान परिणाम';

  @override
  String supportResolvedOn(Object value) {
    return 'समाधान हुआ: $value';
  }

  @override
  String get supportWaitingForReplyTitle =>
      'Support आपके reply का इंतजार कर रही है';

  @override
  String get supportWaitingForReplyMessage =>
      'इस ticket पर requested clarification या proof के साथ reply करें ताकि review जारी रह सके।';

  @override
  String get supportReplyGuidanceTitle => 'उत्तर मार्गदर्शन';

  @override
  String get supportRepliesClosedTitle => 'इस ticket के लिए replies बंद हैं';

  @override
  String get supportRepliesClosedMessage =>
      'यह ticket final support outcome तक पहुँच चुकी है और अब further replies स्वीकार नहीं करती।';

  @override
  String get supportReplyStatusReply => 'उत्तर';

  @override
  String get supportReplyStatusSubmitted => 'जमा किया गया';

  @override
  String get supportNoMessageTextProvided => 'कोई message text उपलब्ध नहीं है।';

  @override
  String get supportTrustStatusLoading => 'Trust status लोड हो रही है';

  @override
  String supportResolutionValue(Object value) {
    return 'समाधान: $value';
  }

  @override
  String get supportReplyGuidancePrimaryOpenDispute =>
      'अपनी visible reply में dispute timeline, पहले से attached proof, और support को सबसे पहले क्या review करना चाहिए यह साफ़ लिखें।';

  @override
  String get supportReplyGuidancePrimaryOpenDefault =>
      'अपनी reply में current blocker साफ़ लिखें ताकि support review जारी रख सके।';

  @override
  String get supportReplyGuidancePrimaryInProgressDispute =>
      'अपनी अगली reply को dispute timeline, proof gaps, और support को किस follow-up पर ध्यान देना चाहिए इस पर केंद्रित रखें।';

  @override
  String get supportReplyGuidancePrimaryInProgressDefault =>
      'Support ने जो अगला operational detail या clarification मांगी है, वही reply करें ताकि review जारी रह सके।';

  @override
  String get supportReplyGuidancePrimaryWaitingDispute =>
      'Support ने जो missing clarification या proof मांगी है, उसे reply करें ताकि dispute review बिना अनावश्यक देरी के जारी रह सके।';

  @override
  String get supportReplyGuidancePrimaryWaitingDefault =>
      'Support ने जो missing clarification मांगी है, उसे reply करें ताकि ticket आगे बढ़ सके।';

  @override
  String get supportReplyGuidancePrimaryResolved =>
      'यह ticket पहले ही resolved है। Fresh follow-up तभी शुरू करें जब वास्तव में नई issue सामने आए।';

  @override
  String get supportReplyGuidancePrimaryUnknown =>
      'अगर support और जानकारी मांगे तो सबसे साफ़ अगला detail reply करें जो आप साझा कर सकते हैं।';

  @override
  String get supportReplyGuidanceSecondaryOpenInProgressDispute =>
      'अगर proof current single-image flow में missing है, तो बाकी context को visible text में साफ़ summarize करें ताकि support जान सके कि और क्या request या review करना है।';

  @override
  String get supportReplyGuidanceSecondaryOpenInProgressDefault =>
      'Reply को concise, specific, और उस load या trip context से जुड़ा रखें जिसे support review कर रही है।';

  @override
  String get supportReplyGuidanceSecondaryWaitingDispute =>
      'अगर एक से ज़्यादा proof महत्वपूर्ण हैं, तो पहले सबसे मजबूत proof attach करें और बाकी context को visible reply में summarize करें।';

  @override
  String get supportReplyGuidanceSecondaryWaitingDefault =>
      'Latest support prompt का सीधा जवाब दें ताकि अगला review step साफ़ हो।';

  @override
  String get supportReplyGuidanceSecondaryResolved =>
      'Recorded resolution को reference के लिए रखें और नया ticket केवल genuinely new follow-up के लिए उपयोग करें।';

  @override
  String get supportReplyGuidanceSecondaryUnknown =>
      'अपनी reply को साफ़ और उन्हीं facts तक सीमित रखें जिन्हें support अगले step में verify कर सकती है।';

  @override
  String supportTicketTitleWithPriority(Object title, Object priority) {
    return '$title - $priority priority';
  }

  @override
  String supportTrustStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'normal': 'सामान्य',
      'warned': 'चेतावनी प्राप्त',
      'restricted': 'प्रतिबंधित',
      'suspended': 'निलंबित',
      'banned': 'प्रतिबंधित',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String supportTrustBadge(Object status) {
    return 'ट्रस्ट: $status';
  }

  @override
  String get trustSafetyLabel => 'विश्वास और सुरक्षा';

  @override
  String get trustSafetyWarningTitle => 'विश्वास और सुरक्षा चेतावनी सक्रिय है';

  @override
  String get trustSafetyWarningMessage =>
      'आपके account पर warning दर्ज है। Marketplace और support surfaces उपलब्ध हैं, लेकिन आगे violations से बचें और warning या next-step expectations की clarity के लिए support का उपयोग करें।';

  @override
  String get trustSafetyRestrictionTitle =>
      'विश्वास और सुरक्षा प्रतिबंध सक्रिय है';

  @override
  String get trustSafetyRestrictionFallback =>
      'यह restriction active रहने तक कुछ platform actions limited हो सकती हैं। कौन-सी actions limited हैं और review से पहले क्या changes ज़रूरी हैं, यह confirm करने के लिए support का उपयोग करें।';

  @override
  String get trustSafetySuspensionTitle =>
      'विश्वास और सुरक्षा निलंबन सक्रिय है';

  @override
  String get trustSafetySuspensionFallback =>
      'यह suspension active रहने तक key platform actions paused हो सकती हैं। Required next steps पूरी होने के बाद policy-allowed review updates या reinstatement guidance के लिए support का उपयोग करें।';

  @override
  String get trustSafetyBanTitle => 'विश्वास और सुरक्षा प्रतिबंध सक्रिय है';

  @override
  String get trustSafetyBanFallback =>
      'यह account सामान्य platform use के लिए blocked है। केवल policy-allowed clarification या final review outcome questions के लिए support का उपयोग करें।';

  @override
  String get trustSafetyHealthyMessageLine1 =>
      'आपके account पर अभी कोई active trust या safety enforcement नहीं है। यह status normal बना रहे, इसके लिए delivery proofs, payout confirmations और marketplace communication सही रखें।';

  @override
  String get trustSafetyHealthyMessageLine2 =>
      'अगर इस account पर कभी policy या moderation questions आएँ, तो blocked actions दोबारा try करने से पहले clarification के लिए support खोलें।';

  @override
  String trustSafetyCurrentStatus(Object displayLabel, Object fallback) {
    return 'वर्तमान स्थिति: $displayLabel. $fallback';
  }

  @override
  String trustSafetyCurrentStatusWithReason(
    Object displayLabel,
    Object reasonSummary,
    Object fallback,
  ) {
    return 'वर्तमान स्थिति: $displayLabel. कारण सारांश: $reasonSummary. $fallback';
  }

  @override
  String get settingsLanguageLabel => 'भाषा';

  @override
  String get settingsLanguageHelper =>
      'लॉन्च पर डिफ़ॉल्ट भाषा हिंदी है। चाहें तो यहाँ से English चुन सकते हैं।';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageHindi => 'हिंदी';

  @override
  String get settingsLanguageSavedEnglish => 'भाषा सेव हुई: English';

  @override
  String get settingsLanguageSavedHindi => 'भाषा सेव हुई: हिंदी';

  @override
  String get settingsLanguageSaveFailed =>
      'अभी आपकी भाषा पसंद सेव नहीं हो सकी। थोड़ी देर बाद settings से फिर कोशिश करें।';

  @override
  String get settingsLanguageSaving => 'भाषा पसंद सेव की जा रही है...';

  @override
  String truckerDashboardWelcomeBack(Object fullName) {
    return 'वापसी पर स्वागत है, $fullName';
  }

  @override
  String get truckerDashboardTitle => 'ट्रकर डैशबोर्ड';

  @override
  String get truckerDashboardQuickActionTripsLabel => 'मेरी ट्रिप्स';

  @override
  String get truckerDashboardRecentActivityTitle => 'हाल की गतिविधि';

  @override
  String get truckerDashboardReadinessNextStepsTitle => 'तैयारी और अगले कदम';

  @override
  String get truckerDashboardReadinessUnavailableTitle =>
      'तैयारी स्थिति उपलब्ध नहीं है';

  @override
  String get truckerDashboardReadinessFailureMessage =>
      'अभी आपकी ट्रकर तैयारी स्थिति उपलब्ध नहीं है। सत्यापन और फ्लीट तैयारी रीफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get commonVerificationPendingTitle => 'सत्यापन लंबित';

  @override
  String get commonOpenVerificationAction => 'सत्यापन खोलें';

  @override
  String get commonVerificationNeedsAttentionTitle =>
      'वेरिफिकेशन पर ध्यान देने की आवश्यकता है';

  @override
  String get truckerDashboardFixVerificationAction => 'वेरिफिकेशन ठीक करें';

  @override
  String get truckerDashboardCompleteFleetVerificationTitle =>
      'Fleet और verification setup पूरा करें';

  @override
  String get truckerDashboardOpenFleetVerificationAction =>
      'फ़्लीट और वेरिफिकेशन खोलें';

  @override
  String get truckerDashboardAddApproveFirstTruckTitle =>
      'अपना पहला truck जोड़ें और approve कराएँ';

  @override
  String get truckerDashboardOpenFleetAction => 'फ़्लीट खोलें';

  @override
  String get truckerDashboardCompleteVerificationTitle =>
      'Trucker verification पूरी करें';

  @override
  String get truckerDashboardLoadFailureTitle =>
      'अभी आपका trucker dashboard लोड नहीं हो सका';

  @override
  String get truckerDashboardLoadFailureMessage =>
      'अभी आपका trucker dashboard लोड नहीं हो सका। Latest KPIs और activity summary refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerDashboardSetupInProgress => 'सेटअप जारी है';

  @override
  String truckerDashboardApprovedTruckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count स्वीकृत ट्रक',
      one: '$count स्वीकृत ट्रक',
    );
    return '$_temp0';
  }

  @override
  String get truckerDashboardStatActiveBidsLabel => 'सक्रिय बोलियाँ';

  @override
  String get truckerDashboardStatUpcomingTripsLabel => 'आगामी ट्रिप्स';

  @override
  String get truckerDashboardStatInTransitLabel => 'रास्ते में';

  @override
  String get truckerDashboardRecentActivityUnavailableTitle =>
      'Recent activity उपलब्ध नहीं है';

  @override
  String get truckerDashboardRecentActivityUnavailableMessage =>
      'अभी आपकी latest booking, trip और fleet activity लोड नहीं हो सकी।';

  @override
  String get truckerDashboardNoRecentActivityTitle =>
      'अभी कोई recent activity नहीं है';

  @override
  String get truckerDashboardNoRecentActivitySubtitle =>
      'काम शुरू होने पर आपकी booking requests, trip movement और fleet review updates यहाँ दिखेंगी।';

  @override
  String get truckerDashboardBookingActivityTitle => 'बुकिंग गतिविधि';

  @override
  String truckerDashboardBookingActivitySubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active bids supplier review का इंतज़ार कर रही हैं',
      one: '$count active bid supplier review का इंतज़ार कर रही है',
    );
    return '$_temp0';
  }

  @override
  String get truckerDashboardTripActivityTitle => 'ट्रिप गतिविधि';

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
      'फ़्लीट समीक्षा गतिविधि';

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
      'Trucker readiness उपलब्ध नहीं है';

  @override
  String get truckerDashboardReadinessSummaryUnavailableMessage =>
      'अभी आपकी readiness summary लोड नहीं हो सकी।';

  @override
  String get truckerDashboardProfileSetupInProgressTitle =>
      'Profile setup अभी जारी है';

  @override
  String get truckerDashboardProfileSetupInProgressSubtitle =>
      'आपकी trucker profile पूरी तरह लोड होने के बाद dashboard readiness details दिखाएगा।';

  @override
  String get truckerDashboardVerificationStatusTitle => 'वेरिफिकेशन स्थिति';

  @override
  String truckerDashboardDlLabel(Object value) {
    return 'DL: $value';
  }

  @override
  String get truckerDashboardFleetReadinessTitle => 'फ़्लीट तैयारियाँ';

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
  String get truckerDashboardActionNeededStatus => 'कार्रवाई आवश्यक';

  @override
  String truckerDashboardTruckAwaitingReview(int count) {
    return '$count समीक्षा की प्रतीक्षा में';
  }

  @override
  String truckerDashboardTruckRejected(int count) {
    return '$count rejected';
  }

  @override
  String truckerDashboardTruckPendingReapproval(int count) {
    return '$count पुनः स्वीकृति लंबित';
  }

  @override
  String truckerDashboardTruckLifecycleAttention(Object segments) {
    return 'ट्रक लाइफसाइकल पर ध्यान दें: $segments. Review clear होने तक non-approved trucks नई booking workflows के लिए blocked रहती हैं।';
  }

  @override
  String get truckerTripsTitle => 'मेरी ट्रिप्स';

  @override
  String get truckerTripsSubtitle =>
      'Assigned trips track करें, proof deadlines monitor करें, और सही trip stage पर सही action लें।';

  @override
  String tripStageValue(String stage) {
    String _temp0 = intl.Intl.selectLogic(stage, {
      'assigned': 'असाइन किया गया',
      'pickup_pending': 'पिकअप लंबित',
      'picked_up': 'पिक किया गया',
      'in_transit': 'रास्ते में',
      'delivered': 'डिलीवर किया गया',
      'proof_submitted': 'प्रूफ जमा किया गया',
      'completed': 'पूर्ण',
      'disputed': 'विवादित',
      'cancelled': 'रद्द',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String proofStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pod_uploaded': 'पीओडी अपलोड किया गया',
      'lr_uploaded': 'एलआर अपलोड किया गया',
      'awaiting_pod': 'पीओडी का इंतजार',
      'proof_submitted': 'प्रूफ जमा किया गया',
      'other': 'प्रूफ लंबित',
    });
    return '$_temp0';
  }

  @override
  String get truckerTripsLoadFailureTitle => 'Trips लोड नहीं हो सकीं';

  @override
  String get truckerTripsLoadFailureMessage =>
      'अभी आपकी trips लोड नहीं हो सकीं। Latest execution timeline refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripsEmptyActiveTitle => 'अभी कोई trip नहीं है';

  @override
  String get truckerTripsEmptyCompletedTitle =>
      'अभी कोई completed trip नहीं है';

  @override
  String get truckerTripsEmptyActiveSubtitle =>
      'अपनी पहली trip शुरू करने के लिए load book करें और supplier approval का इंतज़ार करें।';

  @override
  String get truckerTripsEmptyCompletedSubtitle =>
      'Execution close होने के बाद completed और cancelled trips यहाँ दिखेंगी।';

  @override
  String get truckerTripsEmptyActiveAction => 'लोड्स ढूंढें';

  @override
  String get truckerTripsEmptyCompletedAction => 'सक्रिय ट्रिप्स देखें';

  @override
  String get truckerTripDetailNotFoundTitle => 'ट्रिप नहीं मिली';

  @override
  String get truckerTripDetailNotFoundSubtitle =>
      'यह assigned trip अब उपलब्ध नहीं है या अब आपके पास इसका access नहीं है।';

  @override
  String get truckerTripDetailBackToTripsAction => 'मेरी ट्रिप्स पर वापस जाएं';

  @override
  String truckerTripsTimeContextAssigned(Object date) {
    return 'असाइन किया गया $date';
  }

  @override
  String truckerTripsTimeContextDelivered(Object date) {
    return 'डिलीवर किया गया $date';
  }

  @override
  String truckerTripsTimeContextPodUploaded(Object date) {
    return 'POD अपलोड किया गया $date';
  }

  @override
  String truckerTripsTimeContextCompleted(Object date) {
    return 'पूर्ण हुआ $date';
  }

  @override
  String truckerTripsTruckLabel(Object truckNumber) {
    return 'Truck $truckNumber';
  }

  @override
  String get truckerFleetHeroTitle => 'Truck readiness manage करें';

  @override
  String get truckerFleetHeroSubtitle =>
      'Truck approval ट्रैक करें, rejection guidance review करें और RC details updated रखें ताकि booking-ready trucks उपलब्ध रहें।';

  @override
  String get truckerFleetEditingTruckAction => 'ट्रक संपादित किया जा रहा है';

  @override
  String get truckerFleetAddTruckAction => 'ट्रक जोड़ें';

  @override
  String truckerFleetTruckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ट्रक',
      one: '$count ट्रक',
    );
    return '$_temp0';
  }

  @override
  String truckerFleetApprovedCount(int count) {
    return '$count approved';
  }

  @override
  String get truckerFleetActionAttentionTitle =>
      'ट्रक कार्रवाई पर ध्यान देना आवश्यक है';

  @override
  String get truckerFleetActionFailureMessage =>
      'अभी latest truck action पूरी नहीं हो सकी। Truck details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerFleetEditTruckTitle => 'ट्रक संपादित करें';

  @override
  String get truckerFleetAddOrUpdateTruckTitle => 'ट्रक जोड़ें या अपडेट करें';

  @override
  String get commonTruckNumberLabel => 'ट्रक नंबर';

  @override
  String get truckerFleetTruckNumberHint => 'MH12AB1234';

  @override
  String get truckerFleetBodyTypeLabel => 'बॉडी प्रकार';

  @override
  String truckerFleetBodyTypeOption(Object value) {
    return '$value';
  }

  @override
  String get truckerFleetTyresLabel => 'टायर';

  @override
  String truckerFleetTyresOption(int tyres) {
    return '$tyres tyres';
  }

  @override
  String get truckerFleetCapacityLabel => 'क्षमता (टन)';

  @override
  String get truckerFleetCapacityHint => '25';

  @override
  String get truckerFleetRcDocumentTitle => 'RC दस्तावेज़';

  @override
  String get truckerFleetRcUploadedSubtitle =>
      'RC image upload होकर इस truck draft से linked है।';

  @override
  String get truckerFleetRcRequiredSubtitle =>
      'इस truck को save करने से पहले truck RC upload करें।';

  @override
  String get truckerFleetUploadedStatus => 'uploaded';

  @override
  String get truckerFleetRequiredStatus => 'required';

  @override
  String truckerFleetStoredPath(Object path) {
    return 'संग्रहीत पथ: $path';
  }

  @override
  String get truckerFleetReplaceRcAction => 'RC दस्तावेज़ बदलें';

  @override
  String get truckerFleetUploadRcAction => 'RC दस्तावेज़ अपलोड करें';

  @override
  String get truckerFleetRcUploadedSuccess => 'RC सफलतापूर्वक upload हो गई';

  @override
  String get truckerFleetRcUpdatedSuccess =>
      'RC document सफलतापूर्वक update हो गई';

  @override
  String get truckerFleetSaveTruckUpdatesAction => 'ट्रक अपडेट सहेजें';

  @override
  String get truckerFleetSaveTruckAction => 'ट्रक सहेजें';

  @override
  String get truckerFleetTruckUpdatedSuccess =>
      'Truck सफलतापूर्वक update हो गया';

  @override
  String get truckerFleetTruckAddedSuccess => 'Truck सफलतापूर्वक जोड़ दिया गया';

  @override
  String get truckerFleetMyTrucksTitle => 'मेरे ट्रक';

  @override
  String get truckerFleetUnavailableTitle => 'Fleet उपलब्ध नहीं है';

  @override
  String get truckerFleetLoadFailureMessage =>
      'अभी आपकी fleet लोड नहीं हो सकी। Latest truck readiness और approval state refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerFleetNoTrucksTitle => 'अभी कोई truck नहीं जोड़ी गई';

  @override
  String get truckerFleetNoTrucksSubtitle =>
      'अपना पहला truck उसकी RC document के साथ जोड़ें ताकि trucker verification approval की ओर बढ़ सके।';

  @override
  String get truckerFleetSelectRcSourceTitle => 'RC दस्तावेज़ अपलोड करें';

  @override
  String get commonTakePhotoAction => 'फ़ोटो लें';

  @override
  String get commonChooseFromGalleryAction => 'गैलरी से चुनें';

  @override
  String get truckerFleetRcUploadFailureMessage =>
      'अभी RC document upload नहीं हो सकी। कोई दूसरी image आज़माएँ या थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerFleetSaveFailureMessage =>
      'अभी यह ट्रक सेव नहीं हो सका। ट्रक विवरण देखें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerFleetTruckNumberConflictMessage =>
      'यह ट्रक नंबर पहले से उपयोग में है। नंबर जाँचें और फिर कोशिश करें।';

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
    return 'समीक्षा सारांश: $value';
  }

  @override
  String truckerFleetNextStepLabel(Object value) {
    return 'अगला चरण: $value';
  }

  @override
  String get truckerFleetBlockedBookingMessage =>
      'Review clear होने तक यह truck approval-dependent booking workflows के लिए blocked है।';

  @override
  String get truckerFleetFixResubmitAction =>
      'ट्रक ठीक करें और फिर से जमा करें';

  @override
  String get truckerFleetEditTruckAction => 'ट्रक संपादित करें';

  @override
  String truckerFleetStatusLabelValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pending': 'समीक्षा लंबित',
      'verified': 'स्वीकृत',
      'rejected': 'अस्वीकृत',
      'edited_pending_reapproval': 'पुनः स्वीकृति लंबित',
      'archived': 'संग्रहीत',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String truckerFleetStatusMessageValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'pending':
          'आपका truck admin review का इंतज़ार कर रहा है। Booking में इस्तेमाल करने से पहले approval ज़रूरी है।',
      'verified':
          'यह truck approved है और verification-dependent workflows के लिए उपलब्ध है।',
      'rejected':
          'यह truck reject हुई थी। नीचे दी गई guidance review करें और affected details या RC document update करें।',
      'edited_pending_reapproval':
          'यह truck visible रहती है, लेकिन recent edits के कारण दोबारा approval से पहले reapproval में चली गई है।',
      'archived':
          'यह truck archived है और सामान्य booking workflows के लिए अब उपलब्ध नहीं है।',
      'unknown': 'Truck review state अभी उपलब्ध नहीं है।',
      'other': 'Truck review state अभी उपलब्ध नहीं है।',
    });
    return '$_temp0';
  }

  @override
  String get truckerFindLoadsHeroSubtitle =>
      'Compact freight cards देखें, filters को tight रखें और route interest से load evaluation तक जल्दी बढ़ें।';

  @override
  String get truckerFindLoadsAdvancedFiltersAction => 'उन्नत फ़िल्टर';

  @override
  String get truckerFindLoadsOriginHint => 'मूल शहर';

  @override
  String get truckerFindLoadsDestinationHint => 'गंतव्य शहर';

  @override
  String get truckerFindLoadsMaterialHint => 'सामग्री';

  @override
  String get truckerFindLoadsSortByLabel => 'क्रमबद्ध करें';

  @override
  String get truckerFindLoadsSortNewest => 'नवीनतम';

  @override
  String get truckerFindLoadsSortPriceHighToLow => 'मूल्य उच्च से निम्न';

  @override
  String get truckerFindLoadsSortPriceLowToHigh => 'मूल्य निम्न से उच्च';

  @override
  String get truckerFindLoadsSortPickupDate => 'पिकअप तिथि';

  @override
  String get truckerFindLoadsAllLoadsTab => 'सभी लोड्स';

  @override
  String get truckerFindLoadsSuperLoadsTab => 'सुपर लोड्स';

  @override
  String get truckerFindLoadsLoadFailureTitle => 'Freight लोड नहीं हो सकी';

  @override
  String get truckerFindLoadsLoadFailureMessage =>
      'अभी marketplace freight लोड नहीं हो सकी। Latest load search results refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerFindLoadsEmptyTitle => 'कोई load नहीं मिली';

  @override
  String get truckerFindLoadsEmptySubtitle =>
      'Marketplace search को widen करने के लिए अपनी city, material या advanced filters adjust करें।';

  @override
  String get truckerFindLoadsLoadMoreFailureTitle => 'और loads उपलब्ध नहीं हैं';

  @override
  String get truckerFindLoadsLoadMoreFailureMessage =>
      'अभी और freight लोड नहीं हो सकी। Marketplace search जारी रखने के लिए थोड़ी देर बाद फिर कोशिश करें।';

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
  String get truckerFindLoadsSummarySuperLoads => 'सुपर लोड्स';

  @override
  String truckerFindLoadsSummaryAllLoads(int resultCount) {
    return 'सभी लोड्स दिखाए जा रहे हैं - $resultCount परिणाम';
  }

  @override
  String truckerFindLoadsSummaryFiltered(Object pieces, int resultCount) {
    return '$pieces - $resultCount result(s)';
  }

  @override
  String get truckerFindLoadsResetFiltersAction => 'फ़िल्टर रीसेट करें';

  @override
  String get truckerFindLoadsAnyBodyFallback => 'कोई भी बॉडी';

  @override
  String truckerFindLoadsStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'सक्रिय',
      'assigned_partial': 'आंशिक रूप से असाइन',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String get truckerFindLoadsAdvancedFiltersTitle => 'उन्नत फ़िल्टर';

  @override
  String get truckerFindLoadsTruckBodyTypeLabel => 'ट्रक बॉडी प्रकार';

  @override
  String truckerFindLoadsBodyTypeValue(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'open': 'ओपन',
      'trailer': 'ट्रेलर',
      'container': 'कंटेनर',
      'tanker': 'टैंकर',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String get truckerFindLoadsTyreRequirementTitle => 'टायर आवश्यकता';

  @override
  String get truckerFindLoadsMinPriceLabel => 'न्यूनतम कीमत (₹)';

  @override
  String get truckerFindLoadsMaxPriceLabel => 'अधिकतम कीमत (₹)';

  @override
  String get truckerFindLoadsApplyFiltersAction => 'फ़िल्टर लागू करें';

  @override
  String get truckerFindLoadsResetAdvancedFiltersAction =>
      'उन्नत फ़िल्टर रीसेट करें';

  @override
  String get supplierPostLoadHeroTitle => 'सप्लायर लोड बनाएं';

  @override
  String get supplierPostLoadHeroSubtitle =>
      'Route, cargo, vehicle requirements, pricing और pickup timing define करने के लिए एक clean scrolling form का उपयोग करें।';

  @override
  String get supplierPostLoadHeroHelper =>
      'अगर route services preview नहीं लौटातीं तब भी manual city entry काम करती है। Validation या submission failure पर आपका form data सुरक्षित रहता है।';

  @override
  String get supplierPostLoadPostingBlockedTitle => 'पोस्टिंग अवरुद्ध है';

  @override
  String get supplierPostLoadRouteTimingTitle => 'मार्ग और समय';

  @override
  String get supplierPostLoadOriginCityLabel => 'मूल शहर';

  @override
  String get supplierPostLoadSearchCityHint => 'शहर खोजें';

  @override
  String get supplierPostLoadOriginExactLocationLabel => 'मूल सटीक स्थान';

  @override
  String get supplierPostLoadOriginExactLocationHint => 'गोदाम / पिकअप बिंदु';

  @override
  String get supplierPostLoadDestinationCityLabel => 'गंतव्य शहर';

  @override
  String get supplierPostLoadDestinationExactLocationLabel =>
      'गंतव्य सटीक स्थान';

  @override
  String get supplierPostLoadDestinationExactLocationHint =>
      'ड्रॉप बिंदु / डिलीवरी बिंदु';

  @override
  String get supplierPostLoadPickupDateLabel => 'पिकअप तिथि';

  @override
  String get supplierPostLoadRoutePreviewTitle => 'मार्ग पूर्वावलोकन';

  @override
  String supplierPostLoadDistanceLabel(Object value) {
    return 'दूरी: $value किमी';
  }

  @override
  String supplierPostLoadDriveTimeLabel(int minutes) {
    return 'अनुमानित ड्राइव समय: $minutes मिनट';
  }

  @override
  String get supplierPostLoadRoutePreviewUnavailableTitle =>
      'मार्ग पूर्वावलोकन अनुपलब्ध';

  @override
  String get supplierPostLoadRoutePreviewUnavailableMessage =>
      'अभी route distance और duration derive नहीं हो सके। आप manual city-based posting के साथ फिर भी आगे बढ़ सकते हैं।';

  @override
  String get supplierPostLoadCargoDetailsTitle => 'कार्गो विवरण';

  @override
  String get supplierPostLoadMaterialLabel => 'सामग्री';

  @override
  String get supplierPostLoadWeightLabel => 'वजन (टन)';

  @override
  String get supplierPostLoadWeightHint => '22';

  @override
  String get supplierPostLoadVehicleRequirementsTitle => 'वाहन आवश्यकताएं';

  @override
  String get supplierPostLoadTruckBodyTypeLabel => 'ट्रक बॉडी प्रकार';

  @override
  String get supplierPostLoadTyreRequirementTitle => 'टायर आवश्यकता';

  @override
  String get commonAnyLabel => 'कोई भी';

  @override
  String get supplierPostLoadTrucksNeededTitle => 'ट्रकों की आवश्यकता';

  @override
  String get supplierPostLoadTrucksNeededLabel => 'ट्रकों की आवश्यकता';

  @override
  String get supplierPostLoadTrucksNeededHint => '1';

  @override
  String get supplierPostLoadPricingScheduleTitle => 'मूल्य और अनुसूची';

  @override
  String get supplierPostLoadPriceAmountLabel => 'मूल्य राशि (₹)';

  @override
  String get supplierPostLoadPriceAmountHint => '54000';

  @override
  String get supplierPostLoadPriceTypeTitle => 'मूल्य प्रकार';

  @override
  String supplierPostLoadPriceTypeValue(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'fixed': 'निश्चित',
      'per_ton': 'प्रति टन',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String supplierPostLoadAdvancePercentageLabel(int value) {
    return 'अग्रिम प्रतिशत: $value%';
  }

  @override
  String supplierPostLoadAdvanceBalanceLabel(
    Object advanceAmount,
    Object balanceAmount,
  ) {
    return 'Advance: ₹$advanceAmount - Balance: ₹$balanceAmount';
  }

  @override
  String get supplierPostLoadReviewSummaryTitle => 'सारांश समीक्षा करें';

  @override
  String get supplierPostLoadOriginPending => 'मूल लंबित';

  @override
  String get supplierPostLoadDestinationPending => 'गंतव्य लंबित';

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
  String get supplierPostLoadSubmissionFailedTitle => 'सबमिशन विफल रहा';

  @override
  String get supplierPostLoadCompleteVerificationAction =>
      'लोड पोस्ट करने के लिए वेरिफिकेशन पूरा करें';

  @override
  String get supplierPostLoadCreatedSuccess => 'लोड सफलतापूर्वक बनाया गया';

  @override
  String get supplierPostLoadSubmissionFailureMessage =>
      'अभी यह load submission तैयार नहीं हो सकी। Load details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierPostLoadSubmitFailureMessage =>
      'अभी यह load create नहीं हो सकी। Load details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierPostLoadVerificationCheckingMessage =>
      'Load posting enable करने से पहले supplier verification जांची जा रही है।';

  @override
  String get supplierPostLoadVerificationUnavailableMessage =>
      'अभी supplier verification confirm नहीं हो सकी। थोड़ी देर बाद फिर कोशिश करें या अपनी trust status review करने के लिए verification खोलें।';

  @override
  String get supplierPostLoadProfileUnavailableMessage =>
      'अभी supplier profile उपलब्ध नहीं है। यह load post करने से पहले थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierPostLoadVerificationRequiredMessage =>
      'Loads post करने से पहले supplier verification पूरी करें। Identity और business documents upload करें, फिर उन्हें review के लिए submit करें।';

  @override
  String get commonAadhaarNumberLabel => 'आधार नंबर';

  @override
  String get commonPanNumberLabel => 'पैन नंबर';

  @override
  String get verificationReadinessCheckAadhaarFrontPhoto =>
      'आधार सामने का फोटो';

  @override
  String get verificationReadinessCheckAadhaarBackPhoto => 'आधार पीछे का फोटो';

  @override
  String get verificationReadinessCheckPanPhoto => 'पैन फोटो';

  @override
  String get commonCompanyNameLabel => 'कंपनी का नाम';

  @override
  String get verificationReadinessCheckBusinessLicenceNumber =>
      'व्यवसाय लाइसेंस नंबर';

  @override
  String get verificationReadinessCheckBusinessLicenceDocument =>
      'व्यवसाय लाइसेंस दस्तावेज़';

  @override
  String get verificationReadinessCheckLocation => 'सत्यापन स्थान';

  @override
  String get verificationReadinessCheckTruckWithRcDocument =>
      'RC document वाला truck';

  @override
  String get verificationSubmitSectionTitle =>
      'Verification के लिए submit करें';

  @override
  String get verificationSubmitSectionTitleTrucker =>
      'Step 3: Verification के लिए submit करें';

  @override
  String get verificationSubmitSectionSubtitle =>
      'नीचे दिए गए सभी items पूरे करें, फिर अपने documents को admin review के लिए भेजने हेतु Submit पर tap करें।';

  @override
  String verificationReadinessCompletedCount(int doneCount, int totalCount) {
    return '$doneCount / $totalCount पूरे';
  }

  @override
  String get verificationOpenFleetHint =>
      'Fleet screen से RC document वाला truck जोड़ें या manage करें।';

  @override
  String supplierPostLoadSuggestionSubtitle(Object label, Object source) {
    return '$label - $source';
  }

  @override
  String get supplierVerificationPendingMessage =>
      'आपका वेरिफिकेशन समीक्षा में है। यदि सपोर्ट टीम स्पष्टीकरण मांगे तो दस्तावेज़ तैयार रखें।';

  @override
  String get supplierVerificationNeedsAttentionDescription =>
      'Latest verification feedback review करें, जरूरी documents update करें, और तैयार होने पर फिर submit करें।';

  @override
  String get supplierReviewVerification => 'सत्यापन समीक्षा करें';

  @override
  String get supplierFixVerification => 'सत्यापन ठीक करें';

  @override
  String get supplierCompleteSetupTitle => 'अपना सप्लायर सेटअप पूरा करें';

  @override
  String get supplierCompleteSetupMessage =>
      'Full supplier workspace use करने से पहले supplier verification पूरी करें और अपनी company details जोड़ें।';

  @override
  String get supplierCompleteVerification => 'सत्यापन पूरा करें';

  @override
  String get supplierDashboardSuperLoadVerificationComplete => 'सत्यापन पूर्ण';

  @override
  String get supplierDashboardSuperLoadBusinessLicenceOnFile =>
      'व्यवसाय लाइसेंस दर्ज है';

  @override
  String get supplierDashboardSuperLoadBusinessLicenceMissing =>
      'व्यवसाय लाइसेंस अनुपस्थित है';

  @override
  String get supplierDashboardSuperLoadCompanyAgeUnavailable =>
      'वर्तमान ऐप डेटा में कंपनी-आयु तैयारी उपलब्ध नहीं है';

  @override
  String supplierLoadStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'सक्रिय',
      'assigned_partial': 'आंशिक रूप से असाइन',
      'assigned_full': 'पूरी तरह असाइन',
      'in_transit': 'रास्ते में',
      'completed': 'पूर्ण',
      'filled_outside_app': 'ऐप के बाहर भरा गया',
      'cancelled': 'रद्द',
      'expired': 'समाप्त',
      'deactivated': 'निष्क्रिय',
      'unknown': 'Unknown',
      'other': 'Unknown',
    });
    return '$_temp0';
  }

  @override
  String supplierDashboardTrucksBooked(int booked, int needed) {
    return '$booked/$needed ट्रक बुक हुए';
  }

  @override
  String supplierDashboardLoadPickup(Object value) {
    return 'Pickup $value';
  }

  @override
  String get supplierDashboardOpenLoadsWorkspace => 'लोड्स वर्कस्पेस खोलें';

  @override
  String supplierDashboardSuperLoadStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'request_submitted': 'अनुरोध जमा किया गया',
      'under_review': 'समीक्षा में',
      'approved_payment_pending': 'स्वीकृत - भुगतान लंबित',
      'rejected': 'अस्वीकृत',
      'expired_or_closed': 'बंद',
      'active': 'सक्रिय',
      'not_requested': 'अनुरोध नहीं किया गया',
      'other': 'अनुरोध नहीं किया गया',
    });
    return '$_temp0';
  }

  @override
  String supplierDashboardSuperLoadBadge(Object status) {
    return 'सुपर लोड - $status';
  }

  @override
  String supplierDashboardSuperLoadGuidanceValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'request_submitted':
          'यह Super Load request submit हो चुकी है और admin review का इंतज़ार कर रही है। Dedicated supplier-side eligibility controls अभी pending हैं, इसलिए current state admin-managed है।',
      'under_review':
          'यह Super Load request admin review में है। Review progress में रहने तक load details stable रखें।',
      'approved_payment_pending':
          'यह Super Load request approved है, लेकिन activation अभी भी off-platform payment confirmation step पर निर्भर है।',
      'rejected':
          'यह Super Load request approve नहीं हुई। Dedicated supplier readiness surface अभी pending है, इसलिए follow-up चाहिए तो support का उपयोग करें।',
      'expired_or_closed':
          'यह Super Load lifecycle बंद हो चुकी है। Current load status review करें और follow-up चाहिए तो support का उपयोग करें।',
      'active':
          'यह load current lifecycle में Super Load के रूप में marked है। Dedicated supplier-side eligibility controls अभी भी expand की जा रही हैं।',
      'not_requested': 'इस load के लिए Super Load state active नहीं है।',
      'other': 'इस load के लिए Super Load state active नहीं है।',
    });
    return '$_temp0';
  }

  @override
  String supplierLinkedTripAssignedLabel(Object date) {
    return 'असाइन किया गया: $date';
  }

  @override
  String supplierLinkedTripProofLabel(Object status) {
    return 'प्रमाण स्थिति: $status';
  }

  @override
  String get supplierLinkedTripTrackAction => 'ट्रिप ट्रैक करें';

  @override
  String get supplierTripDetailTitle => 'ट्रिप विवरण';

  @override
  String get supplierTripDetailLoadFailureTitle =>
      'सप्लायर ट्रिप विवरण लोड नहीं हो सका';

  @override
  String get supplierTripDetailLoadFailureMessage =>
      'अभी यह supplier trip detail load नहीं हो सकी। Latest trip status और proof review context refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierTripDetailRatingFailureMessage =>
      'Supplier rating state अभी उपलब्ध नहीं है। Rating submit करने से पहले थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierTripDetailRatingSubmitFailureMessage =>
      'अभी यह supplier rating submit नहीं हो सकी। Rating review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierTripDetailActionFailureMessage =>
      'Latest supplier trip action अभी पूरी नहीं हो सकी। Trip detail refresh होने के बाद थोड़ी देर में फिर कोशिश करें।';

  @override
  String get supplierTripDetailActionSubmitFailureMessage =>
      'अभी यह supplier trip action पूरी नहीं हो सकी। Latest trip status जांचकर थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierTripDetailRatingSectionTitle => 'इस ट्रिप को रेट करें';

  @override
  String get supplierTripDetailRatingAlreadySubmitted =>
      'आप इस ट्रिप को पहले ही रेट कर चुके हैं।';

  @override
  String supplierTripDetailRatingSubmittedOn(Object date) {
    return 'जमा किया गया: $date';
  }

  @override
  String get supplierTripDetailRatingPrompt =>
      'Delivery complete हो चुकी है। इस trip के लिए trucker को rate करें।';

  @override
  String get supplierTripDetailCommentLabel => 'टिप्पणी (वैकल्पिक)';

  @override
  String get supplierTripDetailCommentHint =>
      'Trip outcome के बारे में useful feedback साझा करें';

  @override
  String get supplierTripDetailRatingUnavailableTitle =>
      'रेटिंग उपलब्ध नहीं है';

  @override
  String get supplierTripDetailSubmitRatingAction => 'रेटिंग जमा करें';

  @override
  String get supplierTripDetailRatingSubmittedSuccess =>
      'रेटिंग सफलतापूर्वक जमा हो गई।';

  @override
  String supplierTripDetailRatingStarTooltip(int count, Object s) {
    return '$count star$s';
  }

  @override
  String supplierTripDetailHeroSubtitle(Object truckNumber) {
    return 'ट्रक $truckNumber';
  }

  @override
  String supplierTripDetailMaterialTruckerSummary(
    Object material,
    Object truckerName,
  ) {
    return '$material - Trucker $truckerName';
  }

  @override
  String get commonNextStepTitle => 'अगला चरण';

  @override
  String get supplierTripDetailNextStepReviewTitle =>
      'समीक्षा करें और डिलीवरी की पुष्टि करें';

  @override
  String get supplierTripDetailNextStepReviewMessage =>
      'Trucker ने POD upload कर दिया है। Proof review करें और trip close करने के लिए delivery confirm करें।';

  @override
  String get supplierTripDetailNextStepCompletedTitle => 'ट्रिप पूर्ण हुई';

  @override
  String get supplierTripDetailNextStepCompletedMessage =>
      'Delivery confirm हो चुकी है। Rating और post-trip follow-up इसी completed state से जारी रहते हैं।';

  @override
  String get commonDisputeInProgressTitle => 'विवाद समीक्षा जारी है';

  @override
  String get supplierTripDetailNextStepDisputedMessage =>
      'यह trip dispute review में है और support या operations resolution का इंतजार कर रही है।';

  @override
  String get supplierTripDetailNextStepDefaultTitle => 'कार्यान्वयन ट्रैक करें';

  @override
  String get supplierTripDetailNextStepDefaultMessage =>
      'इस supplier execution view से current trip status, timestamps और proof progress review करें।';

  @override
  String get supplierTripDetailDisputeStatusTitle => 'विवाद स्थिति';

  @override
  String get supplierTripDetailDisputeStateRaised =>
      'वर्तमान स्थिति: विवाद दर्ज किया गया';

  @override
  String supplierTripDetailDisputeCategorySummary(Object category) {
    return 'श्रेणी: $category';
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
    return 'वर्तमान स्थिति: $status';
  }

  @override
  String supplierTripDetailDisputeLastUpdatedLabel(Object date) {
    return 'अंतिम अपडेट: $date';
  }

  @override
  String get supplierTripDetailActionUnavailableTitle =>
      'सप्लायर ट्रिप कार्रवाई उपलब्ध नहीं है';

  @override
  String get supplierTripDetailProofDocumentsTitle => 'प्रमाण दस्तावेज़';

  @override
  String get supplierTripDetailPodPhotoTitle => 'POD फ़ोटो';

  @override
  String get supplierTripDetailPreviewUnavailable =>
      'प्रीव्यू खोला नहीं जा सका';

  @override
  String get supplierTripDetailOpenPodPhotoAction => 'POD फ़ोटो खोलें';

  @override
  String get supplierTripDetailOpenLrDocumentAction => 'LR दस्तावेज़ खोलें';

  @override
  String get supplierTripDetailActionsTitle => 'कार्रवाइयाँ';

  @override
  String get supplierTripDetailConfirmDeliveryAction =>
      'डिलीवरी की पुष्टि करें';

  @override
  String get supplierTripDetailConfirmDeliverySuccess =>
      'डिलीवरी की पुष्टि हो गई। ट्रिप अब पूर्ण हो गई है।';

  @override
  String get supplierTripDetailDisputePodAction => 'POD पर विवाद दर्ज करें';

  @override
  String supplierTripDetailReportSourceLabel(Object routeLabel) {
    return 'Supplier trip - $routeLabel';
  }

  @override
  String get commonRouteAndScheduleTitle => 'रूट और शेड्यूल';

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
    return 'ड्राइव समय: $minutes मिनट';
  }

  @override
  String supplierTripDetailPickupDateLabel(Object date) {
    return 'पिकअप तारीख: $date';
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
  String get supplierTripDetailTruckerTruckTitle => 'ट्रकर और ट्रक';

  @override
  String supplierTripDetailTruckerLabel(Object name) {
    return 'ट्रकर: $name';
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
  String get commonPendingLabel => 'लंबित';

  @override
  String get supplierTripDetailDisputeStatusGuidanceOpen =>
      'Support को यह dispute मिल चुकी है और review जल्द शुरू होनी चाहिए। अगर और proof context चाहिए हो तो related support replies साफ रखें।';

  @override
  String get supplierTripDetailDisputeStatusGuidanceInProgress =>
      'Support या operations इस dispute को actively review कर रहे हैं। Visible updates या clarification requests के लिए related support ticket देखें।';

  @override
  String get supplierTripDetailDisputeStatusGuidanceWaitingForUser =>
      'Support आपके clarification या additional context का इंतजार कर रही है। Review जारी रखने के लिए related support ticket पर reply करें।';

  @override
  String get supplierTripDetailDisputeStatusGuidanceResolved =>
      'यह dispute final review state तक पहुंच चुकी है। कोई नया follow-up issue उठाने से पहले linked support ticket outcome देखें।';

  @override
  String get supplierTripDetailDisputeStatusGuidanceDefault =>
      'Latest visible review updates के लिए related support ticket को follow करते रहें।';

  @override
  String get supplierTripDetailDisputeBannerWaitingTitle =>
      'विवाद समीक्षा आपके उत्तर की प्रतीक्षा कर रही है';

  @override
  String get supplierTripDetailDisputeBannerInProgressTitle =>
      'विवाद समीक्षा जारी है';

  @override
  String get supplierTripDetailDisputeBannerNoSummaryMessage =>
      'इस trip पर dispute raise की गई है। Support और operations delivery context review कर रहे हैं, जबकि raw evidence access review के दौरान restricted रह सकती है।';

  @override
  String supplierTripDetailDisputeBannerWaitingMessage(Object category) {
    return 'श्रेणी: $category. यह ट्रिप विवाद आपके स्पष्टीकरण या प्रमाण की प्रतीक्षा कर रहा है, जबकि समीक्षा के दौरान raw evidence access restricted रह सकती है।';
  }

  @override
  String supplierTripDetailDisputeBannerClosedMessage(Object category) {
    return 'श्रेणी: $category. यह ट्रिप विवाद अंतिम समीक्षा परिणाम तक पहुंच चुका है। Recorded status updates visible रहती हैं, जबकि raw evidence access restricted रह सकती है।';
  }

  @override
  String supplierTripDetailDisputeBannerInProgressMessage(
    Object category,
    Object status,
  ) {
    return 'श्रेणी: $category. स्थिति: $status. Support और operations इस ट्रिप विवाद की समीक्षा कर रहे हैं, जबकि समीक्षा के दौरान raw evidence access restricted रह सकती है।';
  }

  @override
  String get supplierTripDetailSharedVisibilityClosed =>
      'दोनों parties recorded dispute category, final workflow state और visible support replies को इस trip dispute पर अभी भी follow कर सकती हैं।';

  @override
  String get supplierTripDetailSharedVisibilityInProgress =>
      'दोनों parties dispute category, workflow status और support replies को follow कर सकती हैं जो review के दौरान intentionally visible रखी गई हैं।';

  @override
  String get supplierTripDetailActionGuidanceClosed =>
      'यह dispute final review state तक पहुंच चुकी है। किसी genuinely नए follow-up issue को खोलने से पहले linked support ticket पर recorded outcome देखें।';

  @override
  String get supplierTripDetailActionGuidanceInProgress =>
      'जब तक यह dispute review में है, तब तक delivery-confirmation action उपलब्ध नहीं है। अगर support clarification या additional context मांगे तो linked support ticket follow करें।';

  @override
  String get supplierTripDetailProofGuidanceClosed =>
      'अगर आपको लगता है कि closure से पहले important proof consider नहीं हुई, तो fresh support follow-up तभी शुरू करें जब आपके पास वास्तव में नई dispute context हो।';

  @override
  String get supplierTripDetailProofGuidanceInProgress =>
      'अगर यह dispute current single-image flow से आगे additional documents पर निर्भर करती है, तो उन missing proofs को related support ticket replies में साफ summarize करें।';

  @override
  String get verificationTitle => 'वेरिफिकेशन';

  @override
  String get verificationTitleSupplier => 'सप्लायर वेरिफिकेशन';

  @override
  String get verificationTitleTrucker => 'ट्रकर वेरिफिकेशन';

  @override
  String get verificationLoadFailureTitle =>
      'वेरिफिकेशन स्थिति लोड नहीं हो सकी';

  @override
  String get verificationLoadFailureMessage =>
      'अभी आपका verification status load नहीं हो सका। Latest verification state refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get verificationDetailsUnavailableTitle =>
      'वेरिफिकेशन विवरण उपलब्ध नहीं है';

  @override
  String get verificationDetailsUnavailableSubtitle =>
      'हम इस account के लिए current verification record नहीं ढूंढ सके। कृपया थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get verificationResubmitForReviewAction =>
      'समीक्षा के लिए फिर से जमा करें';

  @override
  String get verificationSubmitForReviewAction => 'समीक्षा के लिए जमा करें';

  @override
  String get verificationResubmittedSuccess =>
      'वेरिफिकेशन समीक्षा के लिए फिर से जमा कर दिया गया है';

  @override
  String get verificationSubmittedSuccess =>
      'वेरिफिकेशन समीक्षा के लिए जमा कर दिया गया है';

  @override
  String get verificationSubmitFailureMessage =>
      'अभी यह verification packet submit नहीं हो सका। Current checklist review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get verificationWhatHappensNextMessage =>
      'आपका verification packet review के लिए queue में है। हमारी team correction request के साथ case reject नहीं करती तब तक आपको कुछ भी resubmit करने की ज़रूरत नहीं है।';

  @override
  String get verificationTimelinePacketSubmittedTitle => 'Packet जमा किया गया';

  @override
  String get verificationTimelinePacketSubmittedDescription =>
      'आपके current documents और readiness data पहले से verification case से attached हैं।';

  @override
  String get verificationTimelineReviewInProgressTitle => 'समीक्षा जारी है';

  @override
  String get verificationTimelineReviewInProgressTimestamp => 'अभी';

  @override
  String get verificationTimelineReviewInProgressDescription =>
      'हमारी operations team submitted identity, business और readiness evidence review कर रही है।';

  @override
  String get verificationTimelineNotifiedTitle => 'आपको सूचित किया जाएगा';

  @override
  String get verificationTimelineNotifiedTimestamp => 'अगला';

  @override
  String get verificationTimelineNotifiedDescription =>
      'Review approve होने या correction के लिए वापस भेजे जाने पर हम आपका verification state यहीं update करेंगे।';

  @override
  String get verificationWizardStepPhoto => 'फोटो';

  @override
  String get verificationWizardStepIdentity => 'पहचान';

  @override
  String get verificationWizardStepTruck => 'ट्रक';

  @override
  String get verificationWizardStepBusiness => 'व्यवसाय';

  @override
  String get verificationWizardStepReview => 'समीक्षा';

  @override
  String get verificationWizardBackAction => 'वापस';

  @override
  String get verificationWizardBackTitle => 'वापस जाएं?';

  @override
  String get verificationWizardBackMessage =>
      'आप इस चरण पर अपनी प्रगति खो देंगे। क्या आप वापस जाना चाहते हैं?';

  @override
  String get verificationWizardSaveAndExitAction => 'सहेजें और बाहर निकलें';

  @override
  String get verificationWizardExitTitle => 'वेरिफिकेशन से बाहर निकलें?';

  @override
  String get verificationWizardExitMessage =>
      'आप अभी इस प्रक्रिया से बाहर निकल सकते हैं और बाद में जारी रख सकते हैं।';

  @override
  String get verificationWizardExitAction => 'बाहर निकलें';

  @override
  String get verificationWizardProfileTitle => 'प्रोफ़ाइल फ़ोटो';

  @override
  String get verificationWizardProfileSubtitle =>
      'वेरिफिकेशन के लिए एक स्पष्ट प्रोफ़ाइल फ़ोटो अपलोड करें।';

  @override
  String get verificationWizardProfileHint =>
      'अच्छी रोशनी के साथ सामने से ली गई स्पष्ट फ़ोटो का उपयोग करें।';

  @override
  String get verificationWizardIdentityTitle => 'पहचान दस्तावेज़';

  @override
  String get verificationWizardIdentitySubtitle =>
      'दस्तावेज़ अपलोड के साथ आधार और पैन विवरण जोड़ें।';

  @override
  String get verificationWizardPanDocumentLabel => 'पैन दस्तावेज़';

  @override
  String get verificationWizardTruckSubtitle =>
      'एक ट्रक जोड़ें और उसका RC दस्तावेज़ अपलोड करें।';

  @override
  String get verificationWizardTruckInfo =>
      'ट्रकर वेरिफिकेशन के लिए RC दस्तावेज़ वाला कम-से-कम एक ट्रक आवश्यक है।';

  @override
  String get verificationWizardBodyTypeLabel => 'बॉडी टाइप';

  @override
  String get verificationWizardTyresLabel => 'टायर';

  @override
  String get verificationWizardCapacityLabel => 'क्षमता';

  @override
  String get verificationWizardCapacityHint => '16';

  @override
  String get verificationWizardRcDocumentLabel => 'RC दस्तावेज़';

  @override
  String get verificationWizardRequiredForVerification =>
      'वेरिफिकेशन के लिए आवश्यक';

  @override
  String get verificationWizardTruckPhotoLabel => 'ट्रक फ़ोटो';

  @override
  String get verificationWizardTruckPhotoHint => 'आपके ट्रक की वैकल्पिक फ़ोटो';

  @override
  String get verificationWizardBusinessTitle => 'व्यवसाय विवरण';

  @override
  String get verificationWizardBusinessSubtitle =>
      'अपनी कंपनी, लाइसेंस, वैकल्पिक GST और वेरिफिकेशन स्थान जोड़ें।';

  @override
  String get verificationWizardCompanyNameHint => 'अपनी कंपनी का नाम दर्ज करें';

  @override
  String get verificationWizardLicenseNumberLabel => 'लाइसेंस नंबर';

  @override
  String get verificationWizardLicenseNumberHint =>
      'अपना व्यवसाय लाइसेंस नंबर दर्ज करें';

  @override
  String get verificationWizardLicenseDocumentLabel =>
      'व्यवसाय लाइसेंस दस्तावेज़';

  @override
  String get verificationWizardGstDetailsTitle => 'GST विवरण';

  @override
  String get verificationWizardGstDetailsAdded => 'GST विवरण जोड़ दिए गए';

  @override
  String get verificationWizardGstOptional => 'GST वैकल्पिक है';

  @override
  String get commonGstNumberLabel => 'GST नंबर';

  @override
  String get verificationWizardGstCertificateLabel => 'GST प्रमाणपत्र';

  @override
  String get verificationWizardSearchCityTitle => 'शहर खोजें';

  @override
  String get verificationWizardSearchCityHint => 'शहर का नाम लिखें';

  @override
  String get verificationWizardUseCurrentLocation =>
      'वर्तमान स्थान का उपयोग करें';

  @override
  String verificationWizardNoCitiesFound(Object query) {
    return '\"$query\" के लिए कोई शहर नहीं मिला';
  }

  @override
  String get verificationWizardTryDifferentSearch => 'कोई अलग खोज शब्द आज़माएँ';

  @override
  String get verificationWizardLocationServicesOffTitle =>
      'लोकेशन सेवाएँ बंद हैं';

  @override
  String get verificationWizardLocationServicesOffMessage =>
      'कृपया GPS/लोकेशन सेवाएँ चालू करें और फिर कोशिश करें।';

  @override
  String get verificationWizardLocationPermissionTitle =>
      'लोकेशन अनुमति आवश्यक है';

  @override
  String get verificationWizardLocationPermissionMessage =>
      'जारी रखने के लिए कृपया ऐप सेटिंग्स में लोकेशन अनुमति दें।';

  @override
  String get verificationWizardOpenSettingsAction => 'सेटिंग्स खोलें';

  @override
  String get verificationWizardCapturedViaGps =>
      'GPS के माध्यम से कैप्चर किया गया';

  @override
  String get verificationWizardAddedManually => 'मैन्युअली जोड़ा गया';

  @override
  String get verificationWizardReviewTitle => 'समीक्षा करें और जमा करें';

  @override
  String get verificationWizardReviewSubtitle =>
      'वेरिफिकेशन पैकेट भेजने से पहले अपने विवरण की पुष्टि करें।';

  @override
  String get verificationWizardReviewProfileUploaded =>
      'प्रोफ़ाइल फ़ोटो अपलोड की गई';

  @override
  String get verificationWizardReviewProfileMissing =>
      'प्रोफ़ाइल फ़ोटो नहीं है';

  @override
  String get verificationWizardReviewIdentity => 'पहचान';

  @override
  String get verificationWizardReviewDocumentsUploaded =>
      'दस्तावेज़ अपलोड किए गए';

  @override
  String get verificationWizardReviewTruck => 'ट्रक';

  @override
  String get verificationWizardReviewRcUploaded =>
      'RC दस्तावेज़ अपलोड किया गया';

  @override
  String get verificationWizardReviewTruckPhotoUploaded =>
      'ट्रक फ़ोटो अपलोड की गई';

  @override
  String get verificationWizardReviewBusiness => 'व्यवसाय';

  @override
  String get verificationWizardReviewLicenseNumber => 'लाइसेंस नंबर';

  @override
  String get verificationWizardReviewLocation => 'स्थान';

  @override
  String get verificationWizardReviewTimelineMessage =>
      'टीम द्वारा जमा किए गए पैकेट की जांच के बाद समीक्षा सामान्यतः पूरी होती है।';

  @override
  String get verificationWizardTermsText =>
      'मैं पुष्टि करता/करती हूँ कि दी गई जानकारी और अपलोड किए गए दस्तावेज़ सही हैं और वेरिफिकेशन समीक्षा के लिए तैयार हैं।';

  @override
  String get verificationWizardValidationError =>
      'जमा करने से पहले कृपया आवश्यक फ़ील्ड पूर्ण करें।';

  @override
  String get verificationWizardUnauthorizedError =>
      'आपका सत्र उपलब्ध नहीं है। कृपया फिर से साइन इन करें।';

  @override
  String get verificationWizardUnknownError =>
      'वेरिफिकेशन जमा करते समय कुछ गलत हो गया।';

  @override
  String get verificationActionNeedsAttentionTitle =>
      'वेरिफिकेशन कार्रवाई पर ध्यान देने की आवश्यकता है';

  @override
  String get verificationActionFailureMessage =>
      'Latest verification action अभी पूरी नहीं हो सकी। Current checklist review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get verificationLatestRejectionReasonTitle => 'नवीनतम अस्वीकृति कारण';

  @override
  String get verificationLocationTitle => 'वेरिफिकेशन स्थान';

  @override
  String get verificationLocationCapturedTitle => 'स्थान कैप्चर किया गया';

  @override
  String get verificationLocationRequiredTitle => 'स्थान अभी भी आवश्यक है';

  @override
  String get verificationLocationRequiredMessage =>
      'Supplier verification के लिए submission से पहले city-level location capture जरूरी है।';

  @override
  String get verificationLocationCapturedStatus => 'कैप्चर किया गया';

  @override
  String get verificationLocationRequiredStatus => 'आवश्यक';

  @override
  String get verificationLocationCapturedFooter =>
      'Captured location supplier verification packet के साथ review के लिए attached रहती है।';

  @override
  String get verificationLocationCaptureGuidanceFooter =>
      'हम GPS capture की कोशिश करते हैं और संभव होने पर nearest city-level location resolve करते हैं।';

  @override
  String get verificationRefreshLocationAction => 'स्थान रीफ़्रेश करें';

  @override
  String get verificationCaptureLocationAction => 'Location capture करें';

  @override
  String get verificationLocationCapturedSuccess =>
      'वेरिफिकेशन स्थान कैप्चर कर लिया गया';

  @override
  String get verificationLocationFailureMessage =>
      'अभी verification location capture नहीं हो सकी। इसी verification screen से थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get verificationGpsDisabledTitle => 'GPS बंद है';

  @override
  String get verificationGpsDisabledMessage =>
      'लोकेशन सेवाएँ बंद हैं। अपना वेरिफिकेशन स्थान कैप्चर करने के लिए कृपया डिवाइस सेटिंग्स में GPS चालू करें।';

  @override
  String get verificationOpenSettingsAction => 'सेटिंग्स खोलें';

  @override
  String get verificationPermissionDeniedTitle => 'लोकेशन अनुमति आवश्यक है';

  @override
  String get verificationPermissionDeniedMessage =>
      'लोकेशन एक्सेस स्थायी रूप से अस्वीकृत है। जारी रखने के लिए कृपया ऐप सेटिंग्स में लोकेशन अनुमति सक्षम करें।';

  @override
  String get verificationOpenAppSettingsAction => 'ऐप सेटिंग्स खोलें';

  @override
  String get verificationManualLocationAction => 'Location manually जोड़ें';

  @override
  String get verificationDocTypeAadhaarFront => 'आधार सामने';

  @override
  String get verificationDocTypeAadhaarBack => 'आधार पीछे';

  @override
  String get verificationDocTypePan => 'PAN कार्ड';

  @override
  String get verificationDocTypeProfilePhoto => 'प्रोफ़ाइल फोटो';

  @override
  String get verificationDocTypeBusinessLicence => 'व्यवसाय लाइसेंस';

  @override
  String get verificationDocTypeGstCertificate => 'जीएसटी प्रमाणपत्र';

  @override
  String get verificationDocumentChecklistTitle => 'दस्तावेज़ चेकलिस्ट';

  @override
  String verificationDocumentUploadedSuccess(Object label) {
    return '$label सफलतापूर्वक अपलोड किया गया';
  }

  @override
  String get verificationDocumentUploadFailureMessage =>
      'अभी वह verification document upload नहीं हो सकी। कोई दूसरी image आज़माएँ या थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get verificationStatusVerified => 'सत्यापित';

  @override
  String get verificationStatusRejected => 'अस्वीकृत';

  @override
  String get verificationStatusUnverified => 'असत्यापित';

  @override
  String get verificationPacketDetailsSectionTitle =>
      'Verification packet विवरण';

  @override
  String verificationReadyTruckCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'trucks',
      one: 'truck',
    );
    return '$count तैयार $_temp0';
  }

  @override
  String get verificationTruckReadyWithRcFooter =>
      'आपके पास पहले से कम-से-कम एक पूरा truck packet RC document के साथ मौजूद है।';

  @override
  String get verificationTruckPacketStillRequiredTitle =>
      'Truck packet अभी भी जरूरी है';

  @override
  String get verificationTruckPacketStillRequiredMessage =>
      'पहला truck जोड़ने या RC document upload करने के लिए fleet खोलें ताकि trucker verification एक ही packet के रूप में submit हो सके।';

  @override
  String get verificationOpenFleetAction => 'फ़्लीट खोलें';

  @override
  String get verificationChatAndCallGatingBadge => 'चैट और कॉल प्रतिबंध';

  @override
  String verificationUploadSourceTitle(Object documentLabel) {
    return '$documentLabel अपलोड करें';
  }

  @override
  String verificationRejectionSummaryWithMarkers(Object summary) {
    return '$summary\n\nRejected documents नीचे document-specific correction notes के साथ marked हैं।';
  }

  @override
  String verificationRejectionSummaryPacketLevel(Object summary) {
    return '$summary\n\nजब document-specific review markers उपलब्ध नहीं होते, तब current review feedback एक packet-level reason के रूप में लौटती है।';
  }

  @override
  String get verificationPendingBannerDescription =>
      'आपका verification packet पहले से review में है। Review pending रहने तक आप browsing जारी रख सकते हैं।';

  @override
  String get verificationCompleteBannerTitle => 'वेरिफिकेशन पूर्ण है';

  @override
  String get verificationCompleteBannerDescription =>
      'आपका account पहले से verified है। आप नीचे uploaded document checklist फिर भी review कर सकते हैं।';

  @override
  String get verificationNeedsAttentionBannerDescription =>
      'Rejection summary review करें, affected documents replace करें, और ready होने पर packet resubmit करें।';

  @override
  String get verificationNotSubmittedTitle =>
      'वेरिफिकेशन अभी जमा नहीं किया गया है';

  @override
  String get verificationNotSubmittedSupplierMessage =>
      'Supplier verification submit करने से पहले Aadhaar, PAN, profile photo और business licence upload करें।';

  @override
  String get verificationNotSubmittedTruckerMessage =>
      'Trucker verification submit करने से पहले Aadhaar, PAN, profile photo upload करें और सुनिश्चित करें कि कम-से-कम एक approved truck मौजूद हो।';

  @override
  String get verificationLockedStatusSectionTitle => 'वेरिफिकेशन स्थिति';

  @override
  String verificationLockedStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'verified_title': 'सत्यापित',
      'pending_title': 'समीक्षा के अंतर्गत',
      'verified_message':
          'आपकी verification approve हो चुकी है। अभी किसी action की ज़रूरत नहीं है।',
      'pending_message':
          'आपके documents review में हैं। Review पूरी होने पर आपको notify किया जाएगा।',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String get verificationSubmitLockedFooter =>
      'Submit होने के बाद आपकी details admin review पूरी होने तक locked रहेंगी।';

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
      'Verification resubmit होने से पहले इस document में correction जरूरी है।';

  @override
  String get verificationDocumentUploadedSubtitle =>
      'Document upload हो चुकी है और आपकी verification record से linked है।';

  @override
  String get verificationDocumentRequiredSubtitle =>
      'Verification submit होने से पहले यह required है।';

  @override
  String get verificationDocumentOptionalSubtitle =>
      'Current verification packet के लिए optional है।';

  @override
  String verificationReviewNoteLabel(Object reason) {
    return 'समीक्षा नोट: $reason';
  }

  @override
  String verificationStoredPathLabel(Object path) {
    return 'संग्रहीत पथ: $path';
  }

  @override
  String get verificationDocumentMissingMessage =>
      'यह document current packet में अभी भी missing है।';

  @override
  String get verificationReplaceDocumentAction => 'दस्तावेज़ बदलें';

  @override
  String get verificationUploadDocumentAction => 'दस्तावेज़ अपलोड करें';

  @override
  String get truckerTripDetailTitle => 'ट्रिप विवरण';

  @override
  String get truckerTripDetailLoadFailureTitle => 'ट्रिप विवरण लोड नहीं हो सका';

  @override
  String get truckerTripDetailLoadFailureMessage =>
      'अभी यह trip detail load नहीं हो सकी। Latest trip status और actions refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripDetailRatingFailureMessage =>
      'आपकी trip rating state अभी उपलब्ध नहीं है। Rating submit करने से पहले थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripDetailRatingSubmitFailureMessage =>
      'अभी आपकी rating submit नहीं हो सकी। Rating review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripDetailActionFailureMessage =>
      'Latest trip action अभी पूरी नहीं हो सकी। Trip detail refresh होने के बाद थोड़ी देर में फिर कोशिश करें।';

  @override
  String get truckerTripDetailActionSubmitFailureMessage =>
      'अभी वह trip action पूरी नहीं हो सकी। Latest trip status जांचकर थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripDetailLrUploadFailureMessage =>
      'अभी LR proof upload नहीं हो सकी। कोई दूसरी image आज़माएँ या थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripDetailPodUploadFailureMessage =>
      'अभी POD proof upload नहीं हो सकी। कोई दूसरी image आज़माएँ या थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerTripDetailRatingSectionTitle => 'इस ट्रिप को रेट करें';

  @override
  String get truckerTripDetailRatingAlreadySubmitted =>
      'आप इस ट्रिप को पहले ही रेट कर चुके हैं।';

  @override
  String truckerTripDetailRatingSubmittedOn(Object date) {
    return 'जमा किया गया: $date';
  }

  @override
  String get truckerTripDetailRatingPrompt =>
      'Delivery complete हो चुकी है। इस trip के लिए supplier को rate करें।';

  @override
  String get truckerTripDetailCommentLabel => 'टिप्पणी (वैकल्पिक)';

  @override
  String get truckerTripDetailCommentHint =>
      'Trip outcome के बारे में useful feedback साझा करें';

  @override
  String get truckerTripDetailRatingUnavailableTitle => 'रेटिंग उपलब्ध नहीं है';

  @override
  String get truckerTripDetailSubmitRatingAction => 'रेटिंग जमा करें';

  @override
  String get truckerTripDetailRatingSubmittedSuccess =>
      'रेटिंग सफलतापूर्वक जमा हो गई।';

  @override
  String truckerTripDetailRatingStarTooltip(Object count, Object s) {
    return '$count star$s';
  }

  @override
  String get truckerTripDetailAutoCompleteDueNow =>
      'ऑटो-कम्प्लीट का समय अभी हो गया है।';

  @override
  String truckerTripDetailAutoCompleteDuration(Object hours, Object minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String truckerTripDetailAutoCompleteIn(Object duration) {
    return 'ऑटो-कम्प्लीट में: $duration';
  }

  @override
  String truckerTripDetailHeroSubtitle(Object truckNumber) {
    return 'ट्रक $truckNumber';
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
      'ट्रिप कार्रवाई उपलब्ध नहीं है';

  @override
  String get truckerTripDetailActionsTitle => 'कार्रवाइयाँ';

  @override
  String get truckerTripDetailReplaceLrUploadAction => 'LR अपलोड बदलें';

  @override
  String get truckerTripDetailUploadLrOptionalAction =>
      'LR अपलोड करें (वैकल्पिक)';

  @override
  String get truckerTripDetailUploadLrImageTitle => 'LR चित्र अपलोड करें';

  @override
  String get truckerTripDetailLrUploadedSuccess =>
      'LR सफलतापूर्वक अपलोड हो गया।';

  @override
  String get truckerTripDetailUploadPodPhotoAction => 'POD फ़ोटो अपलोड करें';

  @override
  String get truckerTripDetailUploadPodPhotoTitle => 'POD फ़ोटो अपलोड करें';

  @override
  String get truckerTripDetailPodUploadedSuccess =>
      'POD सफलतापूर्वक अपलोड हो गया। अब सप्लायर की पुष्टि लंबित है।';

  @override
  String get truckerTripDetailCallSupplierAction => 'सप्लायर को कॉल करें';

  @override
  String get commonOpenInGoogleMapsAction => 'गूगल मैप्स में खोलें';

  @override
  String truckerTripDetailReportSourceLabel(
    Object destinationLabel,
    Object originLabel,
  ) {
    return 'ट्रकर ट्रिप - $originLabel से $destinationLabel';
  }

  @override
  String get truckerTripDetailReviewCountdownTitle =>
      'डिलीवरी समीक्षा काउंटडाउन';

  @override
  String get truckerTripDetailReviewCountdownMessage =>
      'Supplier confirmation pending है। अगर कोई action नहीं ली जाती, तो POD upload के 48 घंटे बाद यह trip auto-complete हो जाती है।';

  @override
  String get truckerTripDetailDisputeStatusTitle => 'विवाद स्थिति';

  @override
  String get truckerTripDetailDisputeStateRaised =>
      'वर्तमान स्थिति: विवाद दर्ज किया गया';

  @override
  String truckerTripDetailDisputeCurrentStateLabel(Object status) {
    return 'वर्तमान स्थिति: $status';
  }

  @override
  String truckerTripDetailDisputeCategoryLabel(Object category) {
    return '$category';
  }

  @override
  String truckerTripDetailDisputeLastUpdatedLabel(Object date) {
    return 'अंतिम अपडेट: $date';
  }

  @override
  String get truckerTripDetailDisputeStatusGuidanceOpen =>
      'Support को यह dispute मिल चुकी है और review जल्द शुरू होनी चाहिए। अगर और proof context चाहिए हो तो related support replies साफ रखें।';

  @override
  String get truckerTripDetailDisputeStatusGuidanceInProgress =>
      'Support या operations इस dispute को actively review कर रहे हैं। Visible updates या clarification requests के लिए related support ticket देखें।';

  @override
  String get truckerTripDetailDisputeStatusGuidanceWaitingForUser =>
      'Support आपके clarification या additional context का इंतजार कर रही है। Review जारी रखने के लिए related support ticket पर reply करें।';

  @override
  String get truckerTripDetailDisputeStatusGuidanceResolved =>
      'यह dispute final review state तक पहुंच चुकी है। कोई नया follow-up issue उठाने से पहले linked support ticket outcome देखें।';

  @override
  String get truckerTripDetailDisputeStatusGuidanceDefault =>
      'Latest visible review updates के लिए related support ticket को follow करते रहें।';

  @override
  String get truckerTripDetailDisputeBannerWaitingTitle =>
      'विवाद आपके उत्तर की प्रतीक्षा कर रहा है';

  @override
  String get truckerTripDetailDisputeBannerNoSummaryMessage =>
      'इस trip पर dispute raise की गई है। Submitted proof और delivery context को support या operations review कर रहे हैं। दोनों sides dispute status देख सकती हैं, लेकिन sensitive evidence review के दौरान restricted रह सकती है।';

  @override
  String truckerTripDetailDisputeBannerWaitingMessage(Object category) {
    return 'इस trip पर $category के तहत dispute raise की गई है और यह आपके clarification या proof का इंतजार कर रही है। Sensitive evidence review के दौरान restricted रह सकती है।';
  }

  @override
  String truckerTripDetailDisputeBannerClosedMessage(Object category) {
    return 'इस trip पर $category के तहत raise की गई dispute final review outcome तक पहुंच चुकी है। Recorded status updates visible रहती हैं, जबकि sensitive evidence restricted रह सकती है।';
  }

  @override
  String truckerTripDetailDisputeBannerInProgressMessage(Object category) {
    return 'इस trip पर $category के तहत dispute raise की गई है। Delivery context को support या operations review कर रहे हैं, और sensitive evidence review के दौरान restricted रह सकती है।';
  }

  @override
  String get truckerTripDetailDisputeActionGuidanceClosed =>
      'यह dispute final review state तक पहुंच चुकी है। Recorded outcome के लिए इस trip detail को रखें और genuinely नई issue दिखे तभी fresh follow-up शुरू करें।';

  @override
  String get truckerTripDetailDisputeActionGuidanceInProgress =>
      'जब तक dispute resolve नहीं होती, तब तक कोई further trip-stage action उपलब्ध नहीं है। Status updates के लिए इस trip detail को रखें और support निर्देश दे तो उन्हें follow करें।';

  @override
  String get truckerTripDetailSharedVisibilityClosed =>
      'दोनों parties recorded dispute category, final workflow state और visible support replies को इस trip dispute पर अभी भी follow कर सकती हैं।';

  @override
  String get truckerTripDetailSharedVisibilityInProgress =>
      'दोनों parties dispute category, workflow status और support replies को follow कर सकती हैं जो review के दौरान intentionally visible रखी गई हैं।';

  @override
  String get truckerTripDetailProofGuidanceClosed =>
      'अगर आपको लगता है कि closure से पहले important proof consider नहीं हुई, तो fresh support follow-up तभी शुरू करें जब आपके पास वास्तव में नई dispute context हो।';

  @override
  String get truckerTripDetailProofGuidanceInProgress =>
      'अगर additional supporting proofs current single-image flow में attached नहीं हैं, तो related support replies साफ रखें ताकि support और operations समझ सकें कि और क्या review करना है।';

  @override
  String get truckerTripDetailCancelledTitle => 'ट्रिप रद्द हो गई';

  @override
  String get truckerTripDetailCancelledMessage =>
      'यह trip completion से पहले cancel हो गई थी। कोई further execution action उपलब्ध नहीं है, और यह detail अब cancelled movement का record है।';

  @override
  String get truckerTripDetailCancellationSummaryTitle => 'रद्दीकरण सारांश';

  @override
  String get truckerTripDetailCancellationCurrentState =>
      'वर्तमान स्थिति: रद्द';

  @override
  String truckerTripDetailRouteLabel(Object route) {
    return 'Route: $route';
  }

  @override
  String truckerTripDetailMaterialLabel(Object material) {
    return 'सामग्री: $material';
  }

  @override
  String truckerTripDetailAssignedOnLabel(Object dateTime) {
    return 'Assigned on: $dateTime';
  }

  @override
  String get truckerTripDetailCancellationFollowupMessage =>
      'अगर support या operations follow-up instructions साझा करें, तो context के लिए इस trip reference और existing trip timeline का इस्तेमाल करें।';

  @override
  String get truckerTripDetailTripSummaryTitle => 'ट्रिप सारांश';

  @override
  String get truckerTripDetailTripSummaryMessage =>
      'यह trip complete हो चुकी है और execution workflow से close out हो गई है।';

  @override
  String truckerTripDetailCompletedOnLabel(Object dateTime) {
    return 'Completed on: $dateTime';
  }

  @override
  String truckerTripDetailOriginLabel(Object origin) {
    return 'मूल: $origin';
  }

  @override
  String truckerTripDetailDestinationLabel(Object destination) {
    return 'गंतव्य: $destination';
  }

  @override
  String truckerTripDetailDistanceLabel(Object distance) {
    return 'दूरी: $distance किमी';
  }

  @override
  String truckerTripDetailDriveTimeLabel(Object minutes) {
    return 'ड्राइव समय: $minutes मिनट';
  }

  @override
  String truckerTripDetailAssignedLabel(Object dateTime) {
    return 'असाइन किया गया: $dateTime';
  }

  @override
  String truckerTripDetailStartedLabel(Object dateTime) {
    return 'शुरू हुआ: $dateTime';
  }

  @override
  String truckerTripDetailDeliveredLabel(Object dateTime) {
    return 'डिलीवर किया गया: $dateTime';
  }

  @override
  String truckerTripDetailPodUploadedLabel(Object dateTime) {
    return 'POD अपलोड किया गया: $dateTime';
  }

  @override
  String truckerTripDetailCompletedLabel(Object dateTime) {
    return 'पूर्ण हुआ: $dateTime';
  }

  @override
  String get truckerTripDetailTruckSupplierTitle => 'ट्रक और सप्लायर';

  @override
  String truckerTripDetailTruckNumberLabel(Object truckNumber) {
    return 'ट्रक नंबर: $truckNumber';
  }

  @override
  String truckerTripDetailBodyTypeLabel(Object bodyType) {
    return 'बॉडी प्रकार: $bodyType';
  }

  @override
  String truckerTripDetailTyresLabel(Object tyres) {
    return 'टायर: $tyres';
  }

  @override
  String truckerTripDetailSupplierLabel(Object name) {
    return 'सप्लायर: $name';
  }

  @override
  String truckerTripDetailCompanyLabel(Object companyName) {
    return 'कंपनी: $companyName';
  }

  @override
  String truckerTripDetailMobileLabel(Object mobile) {
    return 'मोबाइल: $mobile';
  }

  @override
  String get truckerTripDetailHeadToPickupAction => 'पिकअप के लिए निकलें';

  @override
  String get truckerTripDetailHeadToPickupSuccess =>
      'Pickup movement शुरू हो गई है। Supplier अब देख सकती है कि आप pickup की ओर जा रहे हैं।';

  @override
  String get truckerTripDetailCargoLoadedAction => 'कार्गो लोड हो गया';

  @override
  String get truckerTripDetailCargoLoadedSuccess =>
      'इस trip के लिए cargo loading confirm हो गई है।';

  @override
  String get truckerTripDetailStartTripAction => 'ट्रिप शुरू करें';

  @override
  String get truckerTripDetailStartTripSuccess =>
      'Trip successfully शुरू हो गई है। यह load अब in transit है।';

  @override
  String get truckerTripDetailMarkDeliveredAction =>
      'डिलीवर के रूप में चिन्हित करें';

  @override
  String get truckerTripDetailMarkDeliveredSuccess =>
      'Delivery record हो गई है। Proof flow complete करने के लिए अगले step में POD upload करें।';

  @override
  String get truckerTripDetailNextStepAssignedTitle => 'पिकअप के लिए निकलें';

  @override
  String get truckerTripDetailNextStepAssignedMessage =>
      'यह trip assigned है और pickup movement शुरू होने का इंतजार कर रही है।';

  @override
  String get truckerTripDetailNextStepPickupPendingTitle =>
      'लोडिंग की पुष्टि करें';

  @override
  String get truckerTripDetailNextStepPickupPendingMessage =>
      'Trip pickup पर है और cargo loading confirmation का इंतजार कर रही है।';

  @override
  String get truckerTripDetailNextStepPickedUpTitle => 'ट्रिप शुरू करें';

  @override
  String get truckerTripDetailNextStepPickedUpMessage =>
      'Cargo load हो चुकी है और अगला operational milestone transit में जाना है।';

  @override
  String get truckerTripDetailNextStepInTransitTitle => 'गंतव्य तक पहुँचें';

  @override
  String get truckerTripDetailNextStepInTransitMessage =>
      'Trip in transit है और अगला milestone delivery confirmation है।';

  @override
  String get truckerTripDetailNextStepDeliveredTitle => 'POD अपलोड करें';

  @override
  String get truckerTripDetailNextStepDeliveredMessage =>
      'Delivery record हो चुकी है और proof of delivery अगला required step है।';

  @override
  String get truckerTripDetailNextStepProofSubmittedTitle =>
      'सप्लायर पुष्टि की प्रतीक्षा करें';

  @override
  String get truckerTripDetailNextStepProofSubmittedMessage =>
      'Proof submit हो चुकी है और trip supplier review या auto-completion का इंतजार कर रही है।';

  @override
  String get truckerTripDetailNextStepCompletedTitle => 'ट्रिप पूर्ण हुई';

  @override
  String get truckerTripDetailNextStepCompletedMessage =>
      'Execution close हो चुकी है और यह trip अब historical record है।';

  @override
  String get truckerTripDetailNextStepDisputedMessage =>
      'इस trip पर dispute active है और closure से पहले operational review जरूरी है।';

  @override
  String get truckerTripDetailNextStepCancelledTitle => 'ट्रिप रद्द हुई';

  @override
  String get truckerTripDetailNextStepCancelledMessage =>
      'यह trip normal completion से पहले cancel हो गई थी और अब कोई further execution steps नहीं बचीं।';

  @override
  String get truckerTripDetailNextStepDefaultTitle =>
      'कार्यान्वयन स्थिति जांचें';

  @override
  String get truckerTripDetailNextStepDefaultMessage =>
      'Latest movement समझने के लिए current trip state और recent timestamps review करें।';

  @override
  String get supplierRaiseDisputeTitle => 'विवाद दर्ज करें';

  @override
  String get supplierRaiseDisputeTripUnavailableTitle =>
      'ट्रिप विवरण उपलब्ध नहीं है';

  @override
  String get supplierRaiseDisputeTripLoadFailureMessage =>
      'अभी यह trip detail load नहीं हो सकी। Latest dispute context review करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierRaiseDisputeHeroTitle =>
      'डिलीवरी प्रमाण पर विवाद दर्ज करें';

  @override
  String get supplierRaiseDisputeHeroSubtitle =>
      'Submitted POD में क्या गलत है यह समझाएँ, ताकि current trip के खिलाफ dispute खोली जा सके और support review में भेजी जा सके।';

  @override
  String get supplierRaiseDisputeTripBadge => 'समीक्षा में ट्रिप';

  @override
  String supplierRaiseDisputeHeroSummary(Object material, Object routeLabel) {
    return '$routeLabel - $material';
  }

  @override
  String get supplierRaiseDisputeHeroGuidance =>
      'जो issue सबसे सही बैठती हो वह dispute category चुनें, written explanation जोड़ें, और जरूरत हो तो support review के लिए एक supporting evidence image attach करें।';

  @override
  String get supplierRaiseDisputePartialContextUnavailableTitle =>
      'ट्रिप विवरण का कुछ संदर्भ उपलब्ध नहीं है';

  @override
  String get supplierRaiseDisputeTripContextFailureMessage =>
      'कुछ dispute context अभी उपलब्ध नहीं है। Latest trip detail और proof review state refresh करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierRaiseDisputeSummaryTitle => 'विवाद सारांश';

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
      'विवाद जमा करना अवरुद्ध है';

  @override
  String get supplierRaiseDisputeSubmissionBlockedMessage =>
      'आप यह POD dispute तभी raise कर सकते हैं जब trip proof submitted state में हो।';

  @override
  String get supplierRaiseDisputeSubmissionUnavailableTitle =>
      'विवाद जमा करना उपलब्ध नहीं है';

  @override
  String get supplierRaiseDisputeSubmitFailureMessage =>
      'अभी यह dispute submit नहीं हो सकी। Dispute details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierRaiseDisputeProblemTitle => 'POD में क्या गलत है?';

  @override
  String get supplierRaiseDisputeCategoryLabel => 'विवाद श्रेणी';

  @override
  String get supplierRaiseDisputeReasonLabel => 'विवाद का कारण';

  @override
  String get supplierRaiseDisputeReasonHint =>
      'बताएँ कि submitted proof में क्या गलत है और support को क्या review करना चाहिए।';

  @override
  String get supplierRaiseDisputeHelpfulDetailsTitle =>
      'शामिल करने योग्य उपयोगी विवरण';

  @override
  String get supplierRaiseDisputeHelpfulDetailsMessage =>
      'Current dispute flow अभी भी एक optional image स्वीकार करती है। इन prompts का उपयोग करके अपने written explanation में दूसरी या तीसरी proof capture करें।';

  @override
  String get supplierRaiseDisputeEvidenceOptionalTitle => 'प्रमाण (वैकल्पिक)';

  @override
  String get supplierRaiseDisputeNoEvidenceAttached =>
      'अभी कोई evidence image attached नहीं है। Current flow में आप एक supporting image attach कर सकते हैं।';

  @override
  String get supplierRaiseDisputeEvidenceAttached =>
      'Review के लिए एक supporting evidence image attached है।';

  @override
  String get supplierRaiseDisputeVisibleToOtherPartyMessage =>
      'दूसरी party को visible: सिर्फ dispute category और status. Raw evidence review के दौरान restricted रह सकती है।';

  @override
  String get supplierRaiseDisputeUseCameraAction => 'कैमरा उपयोग करें';

  @override
  String get supplierRaiseDisputeChoosePhotoAction => 'फ़ोटो चुनें';

  @override
  String get supplierRaiseDisputeRemoveEvidenceAction => 'प्रमाण हटाएँ';

  @override
  String get supplierRaiseDisputeSubmitAction => 'विवाद जमा करें';

  @override
  String get supplierRaiseDisputeCategoryError => 'एक मान्य विवाद श्रेणी चुनें';

  @override
  String get supplierRaiseDisputeReasonError =>
      'POD की समस्या को कम-से-कम 10 अक्षरों में समझाएँ';

  @override
  String get supplierRaiseDisputeSubmittedSuccess =>
      'विवाद जमा हो गया। समीक्षा के लिए सपोर्ट टिकट बनाया गया है।';

  @override
  String get supplierRaiseDisputeAttachmentAttachedSuccess =>
      'प्रमाण सफलतापूर्वक संलग्न किया गया';

  @override
  String get commonAttachmentFailureMessage =>
      'अभी वह सबूत इमेज अटैच नहीं हो सकी। कोई दूसरी इमेज आज़माएँ या थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceLoadedQuantityMismatch =>
      'Recommended evidence: loaded bilty या loading proof जो dispatched quantity दिखाए। अभी सिर्फ एक image attach की जा सकती है।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceUnloadedQuantityMismatch =>
      'Recommended evidence: unloaded bilty, weighbridge slip, या unloading proof जो received quantity दिखाए। अभी सिर्फ एक image attach की जा सकती है।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceDocumentMismatch =>
      'Recommended evidence: सबसे clear POD, bilty, या related proof image जो document mismatch दिखाए। अभी सिर्फ एक image attach की जा सकती है।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceNonPayment =>
      'Recommended evidence: एक proof image जो non-payment claim को सबसे अच्छे से support करे। Full payment workflow evidence अभी current flow में limited है।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceFakePayoutProof =>
      'Recommended evidence: एक payout-proof image जो fake या inconsistent payment claim को सबसे अच्छे से दिखाए।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceDelayOrNoShow =>
      'Recommended evidence: एक supporting image या screenshot जो delay या no-show context दिखाए।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceDamageOrShortage =>
      'Recommended evidence: एक image जो delivery पर damage, shortage, या affected goods को सबसे अच्छे से दिखाए।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceAbusiveBehavior =>
      'Recommended evidence: एक supporting image या screenshot, अगर वह abusive-behavior claim के लिए safe और relevant हो।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceSpamOrScam =>
      'Recommended evidence: एक screenshot या proof image जो spam या scam report को सबसे अच्छे से support करे।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceOther =>
      'Dispute की clear explanation दें और जरूरत हो तो सबसे relevant supporting image attach करें।';

  @override
  String get supplierRaiseDisputeEvidenceGuidanceFallback =>
      'इस dispute category के लिए उपलब्ध सबसे relevant supporting image attach करें।';

  @override
  String get supplierRaiseDisputeBestImageGuidanceDocumentCategory =>
      'सबसे clear single document image चुनें जहाँ quantities, signatures, stamps, या POD details एक frame में readable हों।';

  @override
  String get supplierRaiseDisputeBestImageGuidancePaymentCategory =>
      'वह single screenshot या payout-proof image चुनें जो mismatch, missing payment, या fake confirmation को सबसे साफ दिखाए।';

  @override
  String get supplierRaiseDisputeBestImageGuidanceTimelineCategory =>
      'वह single screenshot या photo चुनें जो strongest timeline या behavior context एक image में दे।';

  @override
  String get supplierRaiseDisputeBestImageGuidanceDamageCategory =>
      'वह single image चुनें जो handover के समय damaged goods, shortage, या delivered condition को सबसे अच्छे से दिखाए।';

  @override
  String get supplierRaiseDisputeBestImageGuidanceOther =>
      'वह एक image चुनें जो आपके written reason में बताए गए issue की strongest proof support को दे।';

  @override
  String get supplierRaiseDisputeBestImageGuidanceFallback =>
      'वह एक सबसे clear image चुनें जो support को पहले review करने के लिए strongest proof दे।';

  @override
  String get supplierRaiseDisputePromptDispatchQuantityShownOnProof =>
      'प्रमाण पर दिखाई गई डिस्पैच मात्रा:';

  @override
  String get supplierRaiseDisputePromptQuantityActuallyChallenged =>
      'वास्तव में विवादित मात्रा:';

  @override
  String get supplierRaiseDisputePromptOtherLoadingProofNotAttached =>
      'अन्य लोडिंग प्रमाण संलग्न नहीं है लेकिन सपोर्ट द्वारा समीक्षा किया गया:';

  @override
  String get supplierRaiseDisputePromptQuantityReceivedAtUnloading =>
      'अनलोडिंग पर प्राप्त मात्रा:';

  @override
  String get supplierRaiseDisputePromptQuantityExpectedFromDispatchProof =>
      'डिस्पैच प्रमाण के अनुसार अपेक्षित मात्रा:';

  @override
  String get supplierRaiseDisputePromptExtraUnloadProofNotAttached =>
      'अतिरिक्त अनलोड प्रमाण संलग्न नहीं है लेकिन उपलब्ध है:';

  @override
  String get supplierRaiseDisputePromptDocumentFieldDoesNotMatch =>
      'दस्तावेज़ का कौन-सा फ़ील्ड मेल नहीं खाता:';

  @override
  String get supplierRaiseDisputePromptCorrectTripOrPodDetailShouldBe =>
      'सही ट्रिप या POD विवरण क्या होना चाहिए:';

  @override
  String get supplierRaiseDisputePromptOtherRelatedDocumentNotAttached =>
      'अन्य संबंधित दस्तावेज़ संलग्न नहीं है लेकिन प्रासंगिक है:';

  @override
  String get supplierRaiseDisputePromptAmountStillUnpaid => 'अब भी बकाया राशि:';

  @override
  String get supplierRaiseDisputePromptPaymentDueDateOrMilestone =>
      'भुगतान की नियत तारीख या माइलस्टोन:';

  @override
  String get supplierRaiseDisputePromptOtherPaymentProofNotAttached =>
      'अन्य भुगतान प्रमाण संलग्न नहीं है लेकिन प्रासंगिक है:';

  @override
  String get supplierRaiseDisputePromptWhyPayoutProofLooksFake =>
      'भुगतान प्रमाण नकली या असंगत क्यों लगता है:';

  @override
  String get supplierRaiseDisputePromptWhatPaymentStatusShouldBe =>
      'इसके बजाय भुगतान स्थिति क्या होनी चाहिए:';

  @override
  String get supplierRaiseDisputePromptOtherProofOrChatContextNotAttached =>
      'अन्य प्रमाण या चैट संदर्भ संलग्न नहीं है:';

  @override
  String get supplierRaiseDisputePromptExpectedReportingOrArrivalTime =>
      'अपेक्षित रिपोर्टिंग या आगमन समय:';

  @override
  String get supplierRaiseDisputePromptActualDelayOrNoShowOutcome =>
      'वास्तविक देरी या नो-शो का परिणाम:';

  @override
  String get supplierRaiseDisputePromptOtherTimingProofNotAttached =>
      'अन्य समय-संबंधी प्रमाण संलग्न नहीं है लेकिन प्रासंगिक है:';

  @override
  String get supplierRaiseDisputePromptGoodsAffectedByDamageOrShortage =>
      'नुकसान या कमी से प्रभावित माल:';

  @override
  String get supplierRaiseDisputePromptQuantityOrConditionDifferenceNoticed =>
      'मात्रा या स्थिति में क्या अंतर देखा गया:';

  @override
  String get supplierRaiseDisputePromptOtherSupportingProofNotAttached =>
      'अन्य सहायक प्रमाण संलग्न नहीं है लेकिन प्रासंगिक है:';

  @override
  String get supplierRaiseDisputePromptWhatHappenedDuringIncident =>
      'घटना के दौरान क्या हुआ:';

  @override
  String get supplierRaiseDisputePromptWhenOrWhereBehaviorOccurred =>
      'व्यवहार कब या कहाँ हुआ:';

  @override
  String get supplierRaiseDisputePromptWhatScamOrSpamBehaviorOccurred =>
      'क्या स्कैम या स्पैम व्यवहार हुआ:';

  @override
  String get supplierRaiseDisputePromptWhatMisleadingClaimWasMade =>
      'क्या भ्रामक दावा किया गया:';

  @override
  String get supplierRaiseDisputePromptMainIssueSupportShouldReview =>
      'सपोर्ट को कौन-सा मुख्य मुद्दा समीक्षा करना चाहिए:';

  @override
  String get supplierRaiseDisputePromptWhatOutcomeOrCorrectionNeeded =>
      'कौन-सा परिणाम या सुधार चाहिए:';

  @override
  String get supplierRaiseDisputePromptStrongestMissingProofNotAttached =>
      'सबसे मजबूत गायब प्रमाण संलग्न नहीं है:';

  @override
  String get supplierRaiseDisputeChecklistLoadedReadableQuantity =>
      'Uploaded image में dispatched quantity readable रखें।';

  @override
  String get supplierRaiseDisputeChecklistLoadedPreferBilty =>
      'दूरी की photo की बजाय bilty, loading slip, या marked proof शामिल करें।';

  @override
  String get supplierRaiseDisputeChecklistLoadedUseWrittenReason =>
      'Image में visible न हो सकने वाली additional document context को written reason में लिखें।';

  @override
  String get supplierRaiseDisputeChecklistUnloadedKeepReceivedQuantity =>
      'Image में received quantity या unload record readable रखें।';

  @override
  String get supplierRaiseDisputeChecklistUnloadedPreferWeighbridge =>
      'Generic cargo photo की बजाय weighbridge slip, unload bilty, या marked proof को prefer करें।';

  @override
  String get supplierRaiseDisputeChecklistUnloadedUseWrittenReason =>
      'Current single-image flow में fit न होने वाले second document को written reason में explain करें।';

  @override
  String get supplierRaiseDisputeChecklistDocumentReadableFields =>
      'यह सुनिश्चित करें कि key document fields एक frame में readable हों।';

  @override
  String get supplierRaiseDisputeChecklistDocumentPreferSpecificPage =>
      'वह specific POD या bilty page prefer करें जहाँ mismatch दिखाई देती है।';

  @override
  String get supplierRaiseDisputeChecklistDocumentUseWrittenReason =>
      'Written reason में बताएं कि कौन-सा field या proof trip से match नहीं कर रही।';

  @override
  String get supplierRaiseDisputeChecklistPaymentPreferClearestScreenshot =>
      'सबसे clear payout-related screenshot या proof image prefer करें।';

  @override
  String get supplierRaiseDisputeChecklistPaymentUseWrittenReason =>
      'Written reason में बताएं कि कौन-सा payment अभी भी missing है और वह कब due थी।';

  @override
  String get supplierRaiseDisputeChecklistPaymentUploadStrongestFirst =>
      'अगर multiple proofs हैं, तो strongest proof पहले upload करें और बाकी को text में summarize करें।';

  @override
  String get supplierRaiseDisputeChecklistFakePreferScreenshot =>
      'वह payout screenshot या proof image prefer करें जो सबसे साफ fake या inconsistent लगे।';

  @override
  String get supplierRaiseDisputeChecklistFakeUseWrittenReason =>
      'Written reason में बताएं कि proof में क्या suspicious है।';

  @override
  String get supplierRaiseDisputeChecklistFakeSummarizeChatContext =>
      'अगर supporting chat context है, तो उसे text में summarize करें जब वह single-image flow में fit न हो सके।';

  @override
  String get supplierRaiseDisputeChecklistDelayChooseClearestTiming =>
      'वह clearest screenshot या photo चुनें जो missed timing या no-show context दिखाए।';

  @override
  String get supplierRaiseDisputeChecklistDelayUseWrittenReason =>
      'Written reason में expected time और actual outcome explain करें।';

  @override
  String get supplierRaiseDisputeChecklistDelayKeepFocusedImage =>
      'Uploaded image को unrelated media की बजाय timing/location evidence पर focused रखें।';

  @override
  String get supplierRaiseDisputeChecklistDamageChooseImage =>
      'वह image चुनें जो delivery पर damage, shortage, या affected goods को सबसे अच्छे से दिखाए।';

  @override
  String get supplierRaiseDisputeChecklistDamageKeepAffectedGoods =>
      'Frame में affected goods या missing quantity context visible रखें।';

  @override
  String get supplierRaiseDisputeChecklistDamageUseWrittenReason =>
      'Written reason में बताएं कि single uploaded image में क्या नहीं दिखाया जा सकता।';

  @override
  String get supplierRaiseDisputeChecklistAbusiveUploadIfSafe =>
      'Evidence सिर्फ तभी upload करें जब वह safe और case के लिए relevant हो।';

  @override
  String get supplierRaiseDisputeChecklistAbusivePreferClearestScreenshot =>
      'उस clearest screenshot या image को prefer करें जो abusive incident से directly जुड़ी हो।';

  @override
  String get supplierRaiseDisputeChecklistAbusiveUseWrittenReason =>
      'Written reason में events का sequence explain करें, बिना sensitive internal notes जोड़े।';

  @override
  String get supplierRaiseDisputeChecklistSpamChooseScreenshot =>
      'वह screenshot या image चुनें जो scam या spam behavior को सबसे अच्छे से दिखाए।';

  @override
  String get supplierRaiseDisputeChecklistSpamPreferStrongestProof =>
      'Partial conversation fragment की बजाय strongest proof of deception prefer करें।';

  @override
  String get supplierRaiseDisputeChecklistSpamUseWrittenReason =>
      'Written reason में extra scam context summarize करें जो एक image में fit नहीं हो सकती।';

  @override
  String get supplierRaiseDisputeChecklistOtherChooseStrongestImage =>
      'वह एक strongest image चुनें जो आपकी explanation को support करे।';

  @override
  String get supplierRaiseDisputeChecklistOtherKeepIssueReadable =>
      'Uploaded image में issue-specific detail readable रखें।';

  @override
  String get supplierRaiseDisputeChecklistOtherUseWrittenReason =>
      'Current flow में fit न होने वाली बाकी evidence को written reason में explain करें।';

  @override
  String get supplierRaiseDisputeChecklistFallbackChooseClearestImage =>
      'उपलब्ध सबसे clear supporting image चुनें।';

  @override
  String get supplierRaiseDisputeChecklistFallbackKeepReadableProof =>
      'Frame में important proof readable रखें।';

  @override
  String get supplierRaiseDisputeChecklistFallbackUseWrittenReason =>
      'Image में visible न होने वाली additional evidence को written reason में describe करें।';

  @override
  String get reportIssueTitle => 'समस्या रिपोर्ट करें';

  @override
  String get reportIssueHeroTitle => 'स्पैम, स्कैम या दुरुपयोग रिपोर्ट करें';

  @override
  String get reportIssueHeroSubtitle =>
      'Current operational context से जुड़ा trust-safety ticket खोलें ताकि support issue को जल्दी review कर सके।';

  @override
  String get reportIssueHeroMessage =>
      'अगर आपके पास हो तो एक evidence image attach करें। Report अभी भी linked load/trip context का उपयोग करके live support-ticket workflow से submit होती है, और fake payout-proof या non-payment issues भी capture कर सकती है।';

  @override
  String get reportIssueSubmissionUnavailableTitle =>
      'रिपोर्ट जमा करना उपलब्ध नहीं है';

  @override
  String get reportIssueFailureMessage =>
      'अभी यह report तैयार या submit नहीं हो सकी। Linked context review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get reportIssueLinkedContextTitle => 'लिंक्ड संदर्भ';

  @override
  String reportIssueSourceLabel(Object sourceLabel) {
    return 'स्रोत: $sourceLabel';
  }

  @override
  String get reportIssueRelatedLoadLabel => 'संबंधित लोड लिंक की गई है';

  @override
  String get reportIssueRelatedTripLabel => 'संबंधित ट्रिप लिंक की गई है';

  @override
  String get reportIssueNotLinked => 'लिंक नहीं किया गया';

  @override
  String get reportIssueDetailsTitle => 'रिपोर्ट विवरण';

  @override
  String get reportIssueTypeLabel => 'समस्या का प्रकार';

  @override
  String get reportIssueWhatHappenedLabel => 'क्या हुआ?';

  @override
  String get reportIssueWhatHappenedHint =>
      'बताएँ कि spam, fake proof, non-payment, payout deception, या abusive behavior में क्या हुआ जिसे support को review करना चाहिए।';

  @override
  String get reportIssueHelpfulDetailsTitle => 'शामिल करने के लिए सहायक विवरण';

  @override
  String get reportIssueEvidenceOptionalTitle => 'सबूत (आवश्यक)';

  @override
  String get reportIssueNoEvidenceAttached =>
      'इस रिपोर्ट को सबमिट करने से पहले एक सबूत इमेज अटैच करें।';

  @override
  String get reportIssueEvidenceAttached =>
      'समीक्षा के लिए एक सबूत इमेज अटैच की गई है।';

  @override
  String get reportIssueUseCameraAction => 'कैमरा का उपयोग करें';

  @override
  String get reportIssueChoosePhotoAction => 'फोटो चुनें';

  @override
  String get reportIssueRemoveEvidenceAction => 'सबूत हटाएं';

  @override
  String get reportIssueSubmitAction => 'रिपोर्ट सबमिट करें';

  @override
  String get reportIssueSubmittedSuccess => 'रिपोर्ट सफलतापूर्वक सबमिट की गई';

  @override
  String get reportIssueSubmitFailureMessage =>
      'अभी यह report submit नहीं हो सकी। Details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get reportIssueAttachmentAttachedSuccess =>
      'सबूत सफलतापूर्वक अटैच किया गया';

  @override
  String get reportIssueCategorySpamOrScamLabel => 'स्पैम या स्कैम';

  @override
  String get reportIssueCategoryAbusiveBehaviorLabel => 'दुरुपयोग व्यवहार';

  @override
  String get reportIssueCategoryFakePayoutProofLabel => 'नकली भुगतान प्रमाण';

  @override
  String get reportIssueCategoryNonPaymentLabel => 'गैर-भुगतान';

  @override
  String get reportIssueCategoryGuidanceSpamOrScam =>
      'Spam, scam, या misleading behavior को साफ़ लिखें और एक evidence image attach करें जो support को report review करने में मदद करे।';

  @override
  String get reportIssueCategoryGuidanceAbusiveBehavior =>
      'Abusive या unsafe behavior को साफ़ लिखें, जिसमें यह भी शामिल हो कि वह कहाँ हुआ और support को कौन-सा context review करना चाहिए।';

  @override
  String get reportIssueCategoryGuidanceFakePayoutProof =>
      'बताएँ कि payout proof fake या misleading क्यों लगती है और एक evidence image attach करें जिसमें सबसे उपयोगी payment context दिखता हो।';

  @override
  String get reportIssueCategoryGuidanceNonPayment =>
      'Non-payment issue को साफ़ लिखें, जिसमें क्या due था, पहले क्या follow-up हुआ, और एक evidence image attach करें जिसमें सबसे मजबूत payment proof हो।';

  @override
  String get supportCreateTicketScreenTitle => 'सपोर्ट टिकट बनाएँ';

  @override
  String get supportCreateTicketHeroTitle => 'सपोर्ट अनुरोध खोलें';

  @override
  String get supportCreateTicketHeroSubtitle =>
      'अपनी समस्या साफ़-साफ़ लिखें ताकि support उसे जल्दी route कर सके और आपका follow-up सही context से जुड़ा रहे।';

  @override
  String get supportCreateTicketHeroMessage =>
      'अगर समस्या किसी खास operational flow से जुड़ी है तो आप वैकल्पिक रूप से related load या trip id जोड़ सकते हैं। अगर इससे review तेज़ होगी तो आप एक evidence image भी attach कर सकते हैं।';

  @override
  String get supportCreateTicketFailureTitle => 'सपोर्ट अनुरोध पर ध्यान चाहिए';

  @override
  String get supportCreateTicketFailureMessage =>
      'अभी आपका support request तैयार या submit नहीं हो सका। Issue details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supportCreateTicketDetailsTitle => 'टिकट विवरण';

  @override
  String get supportComposeCategoryLabel => 'श्रेणी';

  @override
  String get supportComposeCategoryGeneral => 'सामान्य';

  @override
  String get supportComposeCategoryAccount => 'खाता';

  @override
  String get supportComposeCategoryLoad => 'लोड';

  @override
  String get supportComposeCategoryTrip => 'ट्रिप';

  @override
  String get supportComposeCategoryPayment => 'भुगतान';

  @override
  String get supportComposeCategoryTechnical => 'तकनीकी';

  @override
  String get supportComposeCategoryOther => 'अन्य';

  @override
  String get supportCreateTicketRelatedLoadIdLabel =>
      'संबंधित load id (वैकल्पिक)';

  @override
  String get supportCreateTicketRelatedLoadIdHint => 'load-123';

  @override
  String get supportCreateTicketRelatedTripIdLabel =>
      'संबंधित trip id (वैकल्पिक)';

  @override
  String get supportCreateTicketRelatedTripIdHint => 'trip-123';

  @override
  String get supportCreateTicketDescriptionLabel => 'समस्या का विवरण दें';

  @override
  String get supportCreateTicketDescriptionHint =>
      'बताएँ क्या हुआ, क्या ब्लॉक है, और आपको किस follow-up की ज़रूरत है।';

  @override
  String get supportComposeAttachmentOptionalTitle => 'अटैचमेंट (वैकल्पिक)';

  @override
  String get supportComposeNoAttachment => 'अभी कोई सबूत इमेज अटैच नहीं है।';

  @override
  String get supportComposeAttachmentAttached =>
      'सपोर्ट समीक्षा के लिए एक सबूत इमेज अटैच है।';

  @override
  String get supportComposeRemoveAttachmentAction => 'अटैचमेंट हटाएँ';

  @override
  String get supportComposeAttachmentAddedSuccess =>
      'अटैचमेंट सफलतापूर्वक जोड़ा गया';

  @override
  String get supportCreateTicketInvalidCategoryMessage =>
      'एक मान्य सपोर्ट श्रेणी चुनें';

  @override
  String get supportCreateTicketDescriptionTooShortMessage =>
      'समस्या को कम-से-कम 10 अक्षरों में लिखें';

  @override
  String get reportIssueInvalidCategoryMessage =>
      'एक मान्य रिपोर्ट श्रेणी चुनें';

  @override
  String get reportIssueDescriptionTooShortMessage =>
      'समस्या को कम-से-कम 10 अक्षरों में लिखें';

  @override
  String get reportIssueAttachmentRequiredMessage =>
      'यह रिपोर्ट जमा करने से पहले एक प्रमाण चित्र संलग्न करें';

  @override
  String get supportReplyMessageTooShortMessage =>
      'उत्तर में कम-से-कम 2 अक्षर होने चाहिए';

  @override
  String get supportCreateTicketSubmitAction => 'टिकट सबमिट करें';

  @override
  String get supportCreateTicketSubmittedSuccess =>
      'सपोर्ट टिकट सफलतापूर्वक बनाया गया';

  @override
  String get supportCreateTicketSubmitFailureMessage =>
      'अभी यह support ticket बनाई नहीं जा सकी। Details review करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supportReplyFailureTitle => 'रिप्लाई पर ध्यान चाहिए';

  @override
  String get supportReplyFailureMessage =>
      'अभी आपकी नवीनतम सपोर्ट रिप्लाई तैयार या सबमिट नहीं हो सकी। मैसेज समीक्षा करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supportReplyLabel => 'सपोर्ट को रिप्लाई करें';

  @override
  String get supportReplyHint =>
      'Support ने जो अगला detail या response मांगा है, वह जोड़ें।';

  @override
  String get supportReplySendAction => 'रिप्लाई भेजें';

  @override
  String get supportReplySentSuccess => 'रिप्लाई सफलतापूर्वक भेजी गई';

  @override
  String get supportReplySubmitFailureMessage =>
      'अभी आपकी रिप्लाई भेजी नहीं जा सकी। मैसेज समीक्षा करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierTripsSectionTitle => 'सप्लायर ट्रिप्स';

  @override
  String get supplierTripsSectionSubtitle =>
      'एक ही supplier execution surface से active movements और recent trip outcomes ट्रैक करें।';

  @override
  String get supplierTripsLoadFailureTitle =>
      'सप्लायर ट्रिप्स लोड नहीं हो सकीं';

  @override
  String get supplierTripsLoadFailureMessage =>
      'अभी आपकी सप्लायर ट्रिप्स लोड नहीं हो सकीं। नवीनतम ट्रिप सूची और स्थिति रिफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get supplierTripsEmptyActiveTitle => 'अभी कोई सक्रिय ट्रिप नहीं है';

  @override
  String get supplierTripsEmptyCompletedTitle => 'अभी कोई पूर्ण ट्रिप नहीं है';

  @override
  String get supplierTripsEmptyActiveSubtitle =>
      'जब कोई लोड असाइन्ड एक्जिक्यूशन में जाएगी, तब ट्रिप्स यहाँ दिखाई देंगी।';

  @override
  String get supplierTripsEmptyCompletedSubtitle =>
      'जब डिलिवरीज़ क्लोज आउट हो जाएँगी, तब पूर्ण सप्लायर ट्रिप्स यहाँ दिखाई देंगी।';

  @override
  String get supplierTripsEmptyCompletedAction => 'सक्रिय ट्रिप्स देखें';

  @override
  String supplierTripsAssignedLabel(Object date) {
    return 'असाइन किया गया $date';
  }

  @override
  String supplierTripsTruckerTruckLabel(Object truckId, Object truckerId) {
    return 'ट्रकर $truckerId - ट्रक $truckId';
  }

  @override
  String get supplierTripsTrackTripAction => 'ट्रिप ट्रैक करें';

  @override
  String get supplierTripDetailNotFoundTitle => 'ट्रिप नहीं मिली';

  @override
  String get supplierTripDetailNotFoundSubtitle =>
      'यह सप्लायर ट्रिप अब उपलब्ध नहीं है या अब आपके पास इसका एक्सेस नहीं है।';

  @override
  String get supplierTripDetailBackToTripsAction =>
      'सप्लायर ट्रिप्स पर वापस जाएं';

  @override
  String get shellAccessRestrictedTitle => 'एक्सेस प्रतिबंधित';

  @override
  String get shellAccessRestrictedDeactivatedSubtitle =>
      'आपका खाता क्लीनअप पेंडिंग होने तक डिएक्टिवेटेड है। आपको सुरक्षित रूप से साइन आउट किया जा रहा है...';

  @override
  String get shellAccessRestrictedBannedSubtitle =>
      'आपके खाते एक्सेस पर प्रतिबंध है। आपको सुरक्षित रूप से साइन आउट किया जा रहा है...';

  @override
  String get shellRouteNotFoundTitle => 'मार्ग नहीं मिला';

  @override
  String get shellMessagesLoadFailureMessage =>
      'अभी आपके संदेश लोड नहीं हो सके। नवीनतम बातचीत रिफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String shellMessagesBookingStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'submitted': 'जमा किया गया',
      'approved': 'स्वीकृत',
      'rejected': 'अस्वीकृत',
      'pending': 'लंबित',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String get truckerLoadDetailTitle => 'लोड विवरण';

  @override
  String get truckerLoadDetailLoadNotFoundTitle => 'लोड नहीं मिला';

  @override
  String get truckerLoadDetailLoadNotFoundSubtitle =>
      'यह मार्केटप्लेस लोड अब उपलब्ध नहीं है या अब आपके पास इसका एक्सेस नहीं है।';

  @override
  String get truckerLoadDetailBackToFindLoadsAction => 'लोड खोजें पर वापस जाएं';

  @override
  String get truckerLoadDetailLoadFailureTitle => 'लोड विवरण लोड नहीं हो सका';

  @override
  String get truckerLoadDetailLoadFailureMessage =>
      'अभी यह फ्रेट विवरण लोड नहीं हो सका। वर्तमान रूट, कीमत और बुकिंग संदर्भ रीफ़्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerLoadDetailSupportUnavailableTitle =>
      'कुछ सहायक लोड विवरण उपलब्ध नहीं हैं';

  @override
  String get truckerLoadDetailSupportFailureMessage =>
      'कुछ सहायक लोड विवरण अभी उपलब्ध नहीं हैं। नवीनतम लोड संदर्भ को रिफ्रेश करने के लिए थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerLoadDetailActionFailureTitle => 'कार्रवाई उपलब्ध नहीं है';

  @override
  String get truckerLoadDetailActionFailureMessage =>
      'नवीनतम लोड कार्रवाई अभी पूरी नहीं हो सकी। वर्तमान बुकिंग स्थिति की समीक्षा करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get truckerLoadDetailBookingSubmitFailureMessage =>
      'अभी यह बुकिंग अनुरोध सबमिट नहीं हो सका। चुने गए ट्रक की समीक्षा करें और थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String truckerLoadDetailHeroSubtitle(Object pickupDate) {
    return 'पिकअप $pickupDate';
  }

  @override
  String truckerLoadDetailPriceBadge(Object priceAmount, Object priceType) {
    return '₹$priceAmount - $priceType';
  }

  @override
  String get truckerLoadDetailTruckMatchAvailable => 'ट्रक मैच उपलब्ध है';

  @override
  String truckerLoadDetailMaterialSummary(
    Object advancePercentage,
    Object material,
    Object weightTonnes,
  ) {
    return '$material - ${weightTonnes}T - अग्रिम $advancePercentage%';
  }

  @override
  String get truckerLoadDetailSuperLoadGuarantee => 'सुपर लोड - भुगतान गारंटी';

  @override
  String get truckerLoadDetailRoutePriceSummaryTitle => 'मार्ग और कीमत सारांश';

  @override
  String get truckerLoadDetailRouteMapTitle => 'Route map';

  @override
  String truckerLoadDetailPickupLabel(Object pickupDate) {
    return 'पिकअप: $pickupDate';
  }

  @override
  String truckerLoadDetailPriceLabel(Object priceAmount, Object priceType) {
    return 'कीमत: ₹$priceAmount - $priceType';
  }

  @override
  String truckerLoadDetailDistanceLabel(Object distance) {
    return 'दूरी: $distance किमी';
  }

  @override
  String truckerLoadDetailDriveTimeLabel(Object minutes) {
    return 'अनुमानित ड्राइव समय: $minutes मिनट';
  }

  @override
  String get truckerLoadDetailTruckRequirementTitle => 'ट्रक आवश्यकता सारांश';

  @override
  String truckerLoadDetailBodyTypeLabel(Object bodyType) {
    return 'बॉडी टाइप: $bodyType';
  }

  @override
  String truckerLoadDetailTyresLabel(Object tyres) {
    return 'टायर: $tyres';
  }

  @override
  String truckerLoadDetailTrucksNeededLabel(Object booked, Object needed) {
    return 'ट्रक चाहिए: $booked/$needed बुक किए गए';
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
      'कोई स्वीकृत ट्रक नहीं चुना गया';

  @override
  String get truckerLoadDetailSelectedTruckMatches =>
      'चुना गया ट्रक इस लोड से मेल खाता है';

  @override
  String get truckerLoadDetailSelectedTruckMayNotMatch =>
      'चुना गया ट्रक इस लोड से मेल नहीं खा सकता';

  @override
  String get truckerLoadDetailCargoScheduleTitle => 'कार्गो और शेड्यूल विवरण';

  @override
  String truckerLoadDetailMaterialLabel(Object material) {
    return 'सामग्री: $material';
  }

  @override
  String truckerLoadDetailWeightLabel(Object weight) {
    return 'वजन: $weight टन';
  }

  @override
  String truckerLoadDetailOriginCityLabel(Object city) {
    return 'मूल शहर: $city';
  }

  @override
  String truckerLoadDetailDestinationCityLabel(Object city) {
    return 'गंतव्य शहर: $city';
  }

  @override
  String get truckerLoadDetailTripCostEstimateTitle => 'ट्रिप लागत अनुमान';

  @override
  String get truckerLoadDetailTripCostUnavailableTitle =>
      'ट्रिप लागत उपलब्ध नहीं';

  @override
  String get truckerLoadDetailTripCostUnavailableMessage =>
      'अभी इस लोड के लिए दूरी उपलब्ध नहीं है, इसलिए ट्रिप लागत अनुमान की गणना नहीं हो सकती।';

  @override
  String get truckerLoadDetailSupplierSummaryTitle => 'सप्लायर सारांश';

  @override
  String get truckerLoadDetailVerifiedSupplier => 'सत्यापित सप्लायर';

  @override
  String get truckerLoadDetailSupplierProfile => 'सप्लायर प्रोफ़ाइल';

  @override
  String truckerLoadDetailStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'सक्रिय',
      'assigned_partial': 'आंशिक रूप से असाइन',
      'unknown': 'अज्ञात',
      'other': 'अज्ञात',
    });
    return '$_temp0';
  }

  @override
  String truckerLoadDetailBookingStatusLabel(Object status) {
    return 'बुकिंग स्थिति: $status';
  }

  @override
  String get truckerLoadDetailBookingFeedbackTitle => 'बुकिंग फीडबैक';

  @override
  String get truckerLoadDetailBookingBlockedTitle => 'बुकिंग अवरुद्ध है';

  @override
  String truckerLoadDetailUsingTruckLabel(Object truckNumber) {
    return '$truckNumber का उपयोग किया जा रहा है';
  }

  @override
  String truckerLoadDetailSelectedTruckSummary(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  ) {
    return 'यह लोड $truckNumber - $bodyType - $tyres टायर वाले ट्रक से बुक किया जाएगा।';
  }

  @override
  String get truckerLoadDetailApprovedTruckLabel =>
      'इस अनुरोध के लिए स्वीकृत ट्रक';

  @override
  String truckerLoadDetailTruckOptionLabel(
    Object bodyType,
    Object truckNumber,
    Object tyres,
  ) {
    return '$truckNumber - $bodyType - $tyres टायर';
  }

  @override
  String get truckerLoadDetailNoApprovedTrucksAvailable =>
      'अभी तक कोई अनुमोदित ट्रक उपलब्ध नहीं है।';

  @override
  String get truckerLoadDetailAddTruckFirstAction => 'पहले एक ट्रक जोड़ें';

  @override
  String get truckerLoadDetailRequestSubmittedAction => 'अनुरोध जमा किया गया';

  @override
  String get truckerLoadDetailBookedAction => 'बुक किया गया';

  @override
  String get truckerLoadDetailBookThisLoadAction => 'इस लोड को बुक करें';

  @override
  String get truckerLoadDetailLoadBookedSuccess =>
      'लोड बुक किया गया! सप्लायर की मंजूरी की प्रतीक्षा में';

  @override
  String get truckerLoadDetailShareLoadAction => 'लोड साझा करें';

  @override
  String get truckerLoadDetailShareLoadTitle => 'लोड साझा करें';

  @override
  String get truckerLoadDetailShareLoadMessage =>
      'सीधे फोन नंबर या निजी ऑपरेशनल नोट्स को उजागर किए बिना सुरक्षित सारांश-पहले लोड कार्ड साझा करें।';

  @override
  String get truckerLoadDetailSystemShareAction => 'सिस्टम साझा करें';

  @override
  String get truckerLoadDetailShareToWhatsAppAction => 'व्हाट्सएप पर साझा करें';

  @override
  String get truckerLoadDetailWhatsAppUnavailableMessage =>
      'इस डिवाइस पर व्हाट्सएप उपलब्ध नहीं है। इसके बजाय सिस्टम साझा का उपयोग करें।';

  @override
  String truckerLoadDetailReportSourceLabel(Object routeLabel) {
    return 'ट्रक लोड - $routeLabel';
  }

  @override
  String get truckerLoadDetailVerificationRequiredMessage =>
      'लोड बुक करने या सप्लायर चैट शुरू करने से पहले ट्रकर सत्यापन पूरा करें। सत्यापन के लिए अनुमोदित पहचान दस्तावेज और प्रोफ़ाइल समीक्षा आवश्यक है।';

  @override
  String get truckerLoadDetailTruckApprovalRequiredMessage =>
      'इस लोड को बुक करने या सप्लायर चैट अनलॉक करने से पहले कम से कम एक ट्रक जोड़ें और अनुमोदित करें।';

  @override
  String get truckerLoadDetailAddTruckDialogTitle => 'पहले एक ट्रक जोड़ें';

  @override
  String get truckerLoadDetailAddTruckDialogMessage =>
      'इस लोड को बुक करने से पहले आपको कम से कम एक अनुमोदित ट्रक चाहिए। ट्रक जोड़ने या अनुमोदन पूरा करने के लिए अभी फ्लीट खोलें?';

  @override
  String get truckerLoadDetailNotNowAction => 'अब नहीं';

  @override
  String get truckerLoadDetailOpenFleetAction => 'फ़्लीट खोलें';

  @override
  String get truckerLoadDetailConfirmBookingTitle =>
      'लोड बुकिंग की पुष्टि करें';

  @override
  String truckerLoadDetailConfirmBookingMessage(
    Object material,
    Object routeLabel,
    Object truckNumber,
  ) {
    return '$truckNumber के साथ $material $routeLabel बुक करें?';
  }

  @override
  String get authTtsSplashWelcome =>
      'TranZfort में आपका स्वागत है। आगे बढ़ने से पहले मैं आपकी छोटी सी सेटअप में मदद करूंगा।';

  @override
  String get authSessionRefreshFailureMessage =>
      'हम आपका सत्र अभी रीफ्रेश नहीं कर सके। जरूरत हो तो आगे बढ़ें और बाद में फिर प्रयास करें।';

  @override
  String get authConfigIncompleteTitle => 'सेटअप अधूरा है';

  @override
  String get postLoadValidationOriginCityRequired => 'मूल शहर चुनें';

  @override
  String get postLoadValidationOriginLocationRequired =>
      'पिकअप स्थान दर्ज करें';

  @override
  String get postLoadValidationDestinationCityRequired => 'गंतव्य शहर चुनें';

  @override
  String get postLoadValidationDestinationLocationRequired =>
      'ड्रॉप स्थान दर्ज करें';

  @override
  String get postLoadValidationMaterialRequired => 'सामग्री का नाम दर्ज करें';

  @override
  String get postLoadValidationWeightRange =>
      '0 से 100 टन के बीच वजन दर्ज करें';

  @override
  String get postLoadValidationTrucksNeeded => 'कम से कम एक ट्रक आवश्यक है';

  @override
  String get postLoadValidationPricePositive =>
      'शून्य से अधिक सही कीमत दर्ज करें';

  @override
  String get postLoadValidationPriceType => 'सही कीमत प्रकार चुनें';

  @override
  String get postLoadValidationPickupDatePast =>
      'पिकअप तारीख पिछली नहीं हो सकती';

  @override
  String settingsRoleSentenceHi(Object roleLabel) {
    return 'वर्तमान भूमिका: $roleLabel।';
  }

  @override
  String settingsRoleSentenceEn(Object roleLabel) {
    return 'वर्तमान भूमिका: $roleLabel।';
  }

  @override
  String get pushIssuePermissionRequestFailed => 'अनुमति अनुरोध विफल हुआ।';

  @override
  String get pushIssueLocalInitFailed => 'लोकल नोटिफिकेशन सेटअप विफल हुआ।';

  @override
  String get pushIssueDisplayFailed => 'नोटिफिकेशन दिखाना विफल हुआ।';

  @override
  String get pushIssueTokenSyncFailed => 'टोकन सिंक विफल हुआ।';

  @override
  String get offlineSyncPending => 'लंबित';

  @override
  String get offlineSyncRetrying => 'पुनः प्रयास';

  @override
  String get offlineSyncFailed => 'विफल';

  @override
  String get offlineSyncExhausted => 'समाप्त (अधिकतम पुनः प्रयास)';

  @override
  String get validationProfilePhotoRequired => 'प्रोफाइल फोटो आवश्यक है';

  @override
  String get validationAadhaarRequired => 'आधार नंबर आवश्यक है';

  @override
  String get validationTruckNumberRequired => 'ट्रक नंबर आवश्यक है';

  @override
  String get validationTruckCapacityRequired => 'ट्रक क्षमता आवश्यक है';

  @override
  String get validationRcDocumentRequired => 'आरसी दस्तावेज आवश्यक है';

  @override
  String get validationCompanyNameRequired => 'कंपनी नाम आवश्यक है';

  @override
  String get validationBusinessLicenseNumberRequired =>
      'लाइसेंस नंबर आवश्यक है';

  @override
  String get validationBusinessLicenseRequired => 'लाइसेंस दस्तावेज आवश्यक है';

  @override
  String get validationVerificationLocationRequired =>
      'वेरिफिकेशन स्थान आवश्यक है';

  @override
  String get validationVerificationCityRequired => 'वेरिफिकेशन शहर आवश्यक है';

  @override
  String get validationDocumentPathRequired => 'दस्तावेज पथ आवश्यक है';

  @override
  String get validationProfileIdRequired => 'प्रोफाइल आईडी आवश्यक है';

  @override
  String get validationCameraPermissionRequired =>
      'कैमरा अनुमति आवश्यक है। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get validationPhotoAccessRequired =>
      'फोटो एक्सेस आवश्यक है। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get validationTruckRequired => 'ट्रक आवश्यक है';

  @override
  String get validationOwnerIdRequired => 'मालिक आईडी आवश्यक है';

  @override
  String get validationTruckIdRequired => 'ट्रक आईडी आवश्यक है';

  @override
  String get validationTripIdRequired => 'ट्रिप आईडी आवश्यक है';

  @override
  String get backendNetworkError =>
      'नेटवर्क त्रुटि। कृपया अपना कनेक्शन जांचें।';

  @override
  String get backendServerError =>
      'सर्वर त्रुटि। कृपया बाद में पुनः प्रयास करें।';

  @override
  String get backendTimeoutError =>
      'अनुरोध समय सीमा समाप्त। कृपया पुनः प्रयास करें।';

  @override
  String get backendUnknownError =>
      'एक अप्रत्याशित त्रुटि हुई। कृपया पुनः प्रयास करें।';

  @override
  String get backendUnauthorizedError => 'अनधिकृत। कृपया पुनः लॉग इन करें।';

  @override
  String get backendForbiddenError =>
      'आपके पास इस कार्रवाई करने की अनुमति नहीं है।';

  @override
  String get backendNotFoundError => 'अनुरोधित संसाधन नहीं मिला।';

  @override
  String get backendConflictError =>
      'यह कार्रवाई मौजूदा डेटा के साथ विरोध करती है।';

  @override
  String get permissionLocationDenied =>
      'स्थान अनुमति अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get permissionLocationPermanentlyDenied =>
      'स्थान अनुमति स्थायी रूप से अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get permissionCameraDenied =>
      'कैमरा अनुमति अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get permissionCameraPermanentlyDenied =>
      'कैमरा अनुमति स्थायी रूप से अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get permissionStorageDenied =>
      'स्टोरेज अनुमति अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get permissionStoragePermanentlyDenied =>
      'स्टोरेज अनुमति स्थायी रूप से अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get permissionNotificationsDenied =>
      'नोटिफिकेशन अनुमति अस्वीकृत। ऐप सेटिंग्स में सक्षम करें।';

  @override
  String get marketplaceLoadValue => 'लोड मूल्य';

  @override
  String get marketplaceEstProfit => 'अनुमानित लाभ';

  @override
  String get marketplaceEstLoss => 'अनुमानित हानि';

  @override
  String get chatNewMessage => 'नया संदेश';

  @override
  String get chatToday => 'आज';

  @override
  String get chatYesterday => 'कल';

  @override
  String get truckerFleetReturnToVerificationTitle => 'वेरिफिकेशन पर लौटें';

  @override
  String get truckerFleetReturnToVerificationMessage =>
      'अपना ट्रक जोड़ें या अपडेट करें, फिर आगे बढ़ने के लिए वेरिफिकेशन पर लौटें।';

  @override
  String get truckerFleetBackToVerificationAction => 'वापस वेरिफिकेशन पर';

  @override
  String get truckerFleetTruckSavedReturnMessage =>
      'ट्रक सेव हो गया। आगे बढ़ने के लिए वेरिफिकेशन पर लौटें।';

  @override
  String get truckerLoadDetailProfileLoadingMessage =>
      'आपकी प्रोफाइल जांची जा रही है। कृपया प्रतीक्षा करें...';

  @override
  String get supplierLoadDetailNotFoundTitle => 'लोड नहीं मिला';

  @override
  String get supplierLoadDetailNotFoundSubtitle =>
      'यह लोड विवरण अभी उपलब्ध नहीं है। मेरे लोड्स पर लौटें और फिर प्रयास करें।';

  @override
  String get supplierLoadDetailLoadFailureTitle => 'लोड विवरण लोड नहीं हो सका';

  @override
  String get supplierLoadDetailFailureMessage =>
      'लोड विवरण नहीं खुल पाया। कृपया फिर से कोशिश करें।';

  @override
  String get supplierLoadDetailScreenTitle => 'लोड विवरण';

  @override
  String supplierLoadDetailHeroSubtitle(Object pickupDate) {
    return 'पिकअप: $pickupDate';
  }

  @override
  String get supplierLoadDetailLinkedExecutionUnavailableTitle =>
      'लिंक्ड निष्पादन डेटा उपलब्ध नहीं है';

  @override
  String get supplierLoadSupportFailureMessage =>
      'बुकिंग या ट्रिप अभी रिफ्रेश नहीं हुई। कृपया फिर से प्रयास करें।';

  @override
  String get supplierLoadDetailStatusAndActionsTitle => 'स्थिति और कार्रवाई';

  @override
  String supplierLoadDetailCurrentStatus(Object status) {
    return 'वर्तमान स्थिति: $status';
  }

  @override
  String get supplierLoadDetailActionsSubtitle =>
      'कार्रवाई करने से पहले नवीनतम स्थिति देखें।';

  @override
  String get supplierLoadDetailActionUnavailableTitle =>
      'कार्रवाई उपलब्ध नहीं है';

  @override
  String get supplierLoadActionFailureMessage =>
      'यह लोड कार्रवाई अभी पूरी नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get supplierLoadDetailCancelAction => 'लोड रद्द करें';

  @override
  String get supplierLoadDetailCancelledSuccess =>
      'लोड सफलतापूर्वक रद्द किया गया';

  @override
  String get supplierLoadCancelFailureMessage =>
      'यह लोड अभी रद्द नहीं हो सका। कृपया फिर प्रयास करें।';

  @override
  String get supplierLoadDetailCloseFilledOutsideAction =>
      'ऐप के बाहर भरा हुआ दिखाकर बंद करें';

  @override
  String get supplierLoadDetailClosedFilledOutsideSuccess =>
      'लोड को ऐप के बाहर भरा हुआ चिन्हित किया गया';

  @override
  String get supplierLoadCloseFailureMessage =>
      'यह लोड अभी बंद नहीं हो सका। कृपया फिर प्रयास करें।';

  @override
  String supplierLoadDetailOriginCity(Object value) {
    return 'मूल शहर: $value';
  }

  @override
  String supplierLoadDetailOriginPoint(Object value) {
    return 'मूल स्थान: $value';
  }

  @override
  String supplierLoadDetailDestinationCity(Object value) {
    return 'गंतव्य शहर: $value';
  }

  @override
  String supplierLoadDetailDestinationPoint(Object value) {
    return 'गंतव्य स्थान: $value';
  }

  @override
  String supplierLoadDetailPickupDate(Object value) {
    return 'पिकअप तारीख: $value';
  }

  @override
  String supplierLoadDetailDistance(Object value) {
    return 'दूरी: $value';
  }

  @override
  String supplierLoadDetailDriveTime(Object value) {
    return 'ड्राइव समय: $value';
  }

  @override
  String get supplierLoadDetailRoutePreviewUnavailableTitle =>
      'रूट प्रीव्यू उपलब्ध नहीं है';

  @override
  String get supplierLoadDetailRoutePreviewUnavailableMessage =>
      'इस लोड का रूट प्रीव्यू अभी उपलब्ध नहीं है।';

  @override
  String get supplierLoadDetailCargoAndRequirementsTitle =>
      'कार्गो और आवश्यकताएं';

  @override
  String supplierLoadDetailMaterial(Object value) {
    return 'सामग्री: $value';
  }

  @override
  String supplierLoadDetailWeight(Object value) {
    return 'वजन: $value';
  }

  @override
  String supplierLoadDetailBodyType(Object value) {
    return 'बॉडी टाइप: $value';
  }

  @override
  String supplierLoadDetailTyres(Object value) {
    return 'टायर: $value';
  }

  @override
  String get supplierLoadDetailBookingAndTripLinkageTitle =>
      'बुकिंग और ट्रिप लिंक';

  @override
  String get supplierLoadDetailBookingLinkageEmptyDescription =>
      'इस लोड पर अभी कोई बुकिंग अनुरोध या लिंक्ड ट्रिप नहीं हैं।';

  @override
  String get supplierLoadDetailBookingLinkageDescription =>
      'बुकिंग अनुरोध और लिंक्ड ट्रिप यहां साथ में देखें।';

  @override
  String get supplierLoadDetailNoBookingRequestsTitle =>
      'अभी कोई बुकिंग अनुरोध नहीं';

  @override
  String get supplierLoadDetailNoBookingRequestsSubtitle =>
      'ट्रकर प्रतिक्रिया देंगे तो बुकिंग अनुरोध यहां दिखेंगे।';

  @override
  String get supplierLoadDetailLinkedTripsTitle => 'लिंक्ड ट्रिप';

  @override
  String get supplierLoadDetailNoLinkedTripsTitle =>
      'अभी कोई लिंक्ड ट्रिप नहीं';

  @override
  String get supplierLoadDetailNoLinkedTripsSubtitle =>
      'बुकिंग स्वीकृत होने के बाद ट्रिप यहां दिखेंगी।';

  @override
  String get supplierLoadDetailActivityTimelineTitle => 'गतिविधि टाइमलाइन';

  @override
  String get supplierLoadDetailTimelineCreatedTitle => 'लोड बनाया गया';

  @override
  String get supplierLoadDetailTimelineCreatedDescription =>
      'यह लोड बनाया गया।';

  @override
  String get supplierLoadDetailTimelinePublishedTitle => 'लोड प्रकाशित';

  @override
  String get supplierLoadDetailTimelinePublishedDescription =>
      'यह लोड प्रकाशित है और ट्रकर को दिख रहा है।';

  @override
  String get supplierLoadDetailTimelineUpdatedTitle => 'स्थिति अपडेट';

  @override
  String supplierLoadDetailTimelineUpdatedDescription(Object status) {
    return 'वर्तमान स्थिति: $status।';
  }

  @override
  String get supplierBookingVerifiedLabel => 'सत्यापित';

  @override
  String supplierBookingRatingLabel(Object rating) {
    return 'रेटिंग: $rating';
  }

  @override
  String supplierBookingTyres(Object tyres) {
    return '$tyres टायर';
  }

  @override
  String supplierBookingSubmittedAt(Object truckLabel, Object submittedAt) {
    return '$truckLabel - जमा किया गया $submittedAt';
  }

  @override
  String supplierBookingDecisionRecorded(Object decidedAt) {
    return 'निर्णय दर्ज किया गया $decidedAt';
  }

  @override
  String supplierLinkedTripSubtitle(
    Object material,
    Object truckerId,
    Object truckId,
  ) {
    return '$material - ट्रकर $truckerId - ट्रक $truckId';
  }

  @override
  String get supplierBookingApprovedSuccessMessage =>
      'बुकिंग सफलतापूर्वक स्वीकृत हुई';

  @override
  String get supplierLoadApproveBookingFailureMessage =>
      'यह बुकिंग अभी स्वीकृत नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get supplierBookingRejectedSuccessMessage =>
      'बुकिंग सफलतापूर्वक अस्वीकृत हुई';

  @override
  String get supplierLoadRejectBookingFailureMessage =>
      'यह बुकिंग अभी अस्वीकृत नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get supplierBookingApproveDialogTitle => 'बुकिंग स्वीकृत करें';

  @override
  String supplierBookingApproveDialogMessage(
    Object material,
    Object origin,
    Object destination,
  ) {
    return '$material के लिए $origin से $destination तक की बुकिंग स्वीकृत करें?';
  }

  @override
  String get supplierBookingRejectDialogTitle => 'बुकिंग अस्वीकृत करें';

  @override
  String get supplierBookingRejectDialogSubtitle =>
      'बुकिंग अस्वीकृत करने से पहले छोटा कारण लिखें।';

  @override
  String get supplierBookingRejectReasonLabel => 'कारण';

  @override
  String get supplierBookingRejectReasonHint =>
      'उदाहरण: वाहन मेल नहीं खाता या समय समस्या';

  @override
  String get verificationFieldBusinessLicenceNumber => 'बिजनेस लाइसेंस नंबर';

  @override
  String get verificationFieldGstOptional => 'वैकल्पिक';

  @override
  String get verificationSavePacketAction => 'विवरण सेव करें';

  @override
  String get verificationSaveSuccessMessage => 'वेरिफिकेशन विवरण सेव हो गया';

  @override
  String get verificationSaveFailureMessage =>
      'वेरिफिकेशन विवरण सेव नहीं हो सका';

  @override
  String get verificationLockedVerifiedGuidance =>
      'आपका वेरिफिकेशन पहले से स्वीकृत है, इसलिए ये फ़ील्ड लॉक हैं।';

  @override
  String get verificationLockedPendingGuidance =>
      'आपका वेरिफिकेशन समीक्षा में है, इसलिए निर्णय होने तक ये फ़ील्ड लॉक हैं।';

  @override
  String get verificationUnlockedSupplierGuidance =>
      'अपने बिजनेस और पहचान विवरण भरें, फिर आवश्यक दस्तावेज़ अपलोड करें।';

  @override
  String get verificationUnlockedTruckerGuidance =>
      'अपने पहचान विवरण भरें और कम से कम एक ट्रक वेरिफिकेशन के लिए तैयार रखें।';

  @override
  String get verificationBlockedAlreadyComplete =>
      'वेरिफिकेशन पहले से पूरा है।';

  @override
  String get verificationBlockedUnderReview =>
      'आपका वेरिफिकेशन पहले से समीक्षा में है।';

  @override
  String get verificationBlockedMissingIdentity =>
      'पहले अपना आधार और पैन नंबर जोड़ें।';

  @override
  String get verificationBlockedMissingCompanyName =>
      'पहले अपनी कंपनी का नाम भरें।';

  @override
  String get verificationBlockedMissingBusinessNumbers =>
      'पहले बिजनेस लाइसेंस विवरण भरें।';

  @override
  String verificationBlockedMissingDocument(Object documentType) {
    return 'जारी रखने के लिए $documentType अपलोड करें।';
  }

  @override
  String get verificationBlockedMissingLocation =>
      'पहले अपना वेरिफिकेशन स्थान जोड़ें।';

  @override
  String get verificationBlockedMissingTruck =>
      'वेरिफिकेशन जमा करने से पहले कम से कम एक ट्रक जोड़ें।';

  @override
  String verificationReadyTruckCount(Object count) {
    return 'वेरिफिकेशन-रेडी ट्रक: $count';
  }

  @override
  String get appBarLanguageToggleTooltip => 'भाषा बदलें';

  @override
  String get connectivityOfflineBanner =>
      'आप ऑफ़लाइन हैं। कुछ सुविधाएँ सीमित हो सकती हैं।';

  @override
  String get connectivityOfflineActionsMessage =>
      'आप ऑफ़लाइन हैं। नेटवर्क की ज़रूरत वाली कार्रवाइयाँ अभी काम नहीं करेंगी।';

  @override
  String get onboardingGateTimeoutMessage =>
      'लोडिंग में सामान्य से अधिक समय लग रहा है।';

  @override
  String authPasswordResetSentSuccess(Object email) {
    return '$email पर पासवर्ड रीसेट लिंक भेजा गया है। अपना inbox देखें।';
  }

  @override
  String get authPasswordResetSentFailure =>
      'रीसेट लिंक नहीं भेजा जा सका। कृपया फिर कोशिश करें।';

  @override
  String get chatPreviewLocation => 'स्थान साझा किया गया';

  @override
  String get chatPreviewDocument => 'दस्तावेज़ साझा किया गया';

  @override
  String get chatPreviewMapCard => 'मार्ग कार्ड साझा किया गया';

  @override
  String get chatPreviewTruckCard => 'ट्रक विवरण साझा किए गए';

  @override
  String reportSourceSupplierLoad(Object routeLabel) {
    return 'सप्लायर लोड - $routeLabel';
  }

  @override
  String truckCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '',
      one: '',
    );
    return '$count ट्रक$_temp0';
  }

  @override
  String get authRecommendedChip => 'सुझाया गया';

  @override
  String get authFastestMostSecure => 'सबसे तेज़ · सबसे सुरक्षित';

  @override
  String get authOneTapNoPasswordSecure => 'एक-टैप · पासवर्ड नहीं · सुरक्षित';

  @override
  String get commonMuteVoice => 'आवाज़ बंद करें';

  @override
  String get commonTurnVoiceOn => 'आवाज़ चालू करें';

  @override
  String get commonSuggestionSourceGooglePlaces => 'Google Places';

  @override
  String get commonSuggestionSourceOffline => 'ऑफ़लाइन डेटाबेस';

  @override
  String get truckerLoadDetailCostTileDieselLabel => 'डीज़ल';

  @override
  String get truckerLoadDetailCostTileTollLabel => 'टोल (₹11/किमी)';

  @override
  String get truckerLoadDetailCostTileDriverLabel => 'ड्राइवर (₹5/किमी)';

  @override
  String get truckerLoadDetailCostTileMiscLabel => 'अन्य (₹2/किमी)';

  @override
  String get truckerLoadDetailCostTileDisclaimer =>
      'अनुमान ₹11/किमी टोल, ₹5/किमी ड्राइवर, ₹2/किमी अन्य के आधार पर हैं। वास्तविक लागत भिन्न हो सकती है।';

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
  String get trustScoreTitle => 'विश्वास और समीक्षाएं';

  @override
  String get trustScoreOutOfFive => '5 में से';

  @override
  String get trustScoreReviews => 'समीक्षाएं';

  @override
  String get trustScoreNoRatingYet => 'अभी तक कोई रेटिंग नहीं';

  @override
  String get trustScoreReviewsReceived => 'प्राप्त समीक्षाएं';

  @override
  String get trustScoreTripsCompleted => 'पूर्ण की गई यात्राएं';

  @override
  String get trustScoreLoadsPosted => 'पोस्ट किए गए लोड';

  @override
  String get trustScoreTrucksInFleet => 'बेड़े में ट्रक';

  @override
  String get trustScoreSuperLoadEligible => 'सुपर लोड पात्र';

  @override
  String get loadHistoryFailedToLoad => 'इतिहास लोड करने में विफल';

  @override
  String get loadHistoryNoLoads => 'प्रदर्शित करने के लिए कोई लोड नहीं';

  @override
  String loadHistoryStatusValue(String status) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'active': 'सक्रिय',
      'completed': 'पूर्ण',
      'assigned_partial': 'आंशिक',
      'assigned_full': 'सौंपा गया',
      'other': '$status',
    });
    return '$_temp0';
  }

  @override
  String get reviewsTitle => 'समीक्षाएं और टिप्पणियां';

  @override
  String get reviewsAverage => 'औसत';

  @override
  String get reviewsTotal => 'कुल';

  @override
  String get reviewsUnableToLoad => 'समीक्षाएं लोड करने में असमर्थ';

  @override
  String get reviewsRetryMessage =>
      'कृपया नवीनतम समीक्षाएं लोड करने के लिए पुनः प्रयास करें।';

  @override
  String get reviewsNoReviewsYet => 'अभी तक कोई समीक्षा नहीं';

  @override
  String get reviewsWillAppearHere =>
      'इंटरैक्शन के बाद यहां समीक्षाएं दिखाई देंगी';

  @override
  String get reviewsLoadMore => 'और समीक्षाएं लोड करें';

  @override
  String get replyDialogTitle => 'समीक्षा का जवाब दें';

  @override
  String get replyDialogDescription =>
      'आप इस समीक्षा का एक बार जवाब दे सकते हैं। आपकी प्रतिक्रिया आपकी प्रोफ़ाइल देखने वाले सभी को दिखाई देगी।';

  @override
  String replyDialogHint(String name) {
    return '$name को अपना जवाब लिखें...';
  }

  @override
  String get replyDialogSubmit => 'जवाब भेजें';

  @override
  String get reviewPromptTitle => 'अपने इंटरैक्शन को रेट करें';

  @override
  String reviewPromptSubtitle(String name) {
    return '$name के साथ आपका अनुभव कैसा रहा?';
  }

  @override
  String get reviewPromptCommentHint => 'टिप्पणी जोड़ें (वैकल्पिक)...';

  @override
  String get reviewPromptSubmit => 'समीक्षा जमा करें';

  @override
  String get reviewPromptSkip => 'छोड़ें';

  @override
  String get reviewPromptSuccessTitle => 'समीक्षा जमा हो गई!';

  @override
  String get reviewPromptSuccessMessage =>
      'अपना अनुभव साझा करने के लिए धन्यवाद।';

  @override
  String get reviewPromptDone => 'हो गया';

  @override
  String get publicProfileScreenTitle => 'प्रोफाइल';

  @override
  String get truckerProfileTitle => 'ट्रकर प्रोफाइल';

  @override
  String get supplierProfileTitle => 'सप्लायर प्रोफाइल';

  @override
  String get raiseDisputeDiscardTitle => 'विवाद छोड़ें?';

  @override
  String get raiseDisputeDiscardMessage =>
      'आपके असहेजित विवाद विवरण हैं। क्या आप उन्हें छोड़ना चाहते हैं?';

  @override
  String get postLoadDiscardTitle => 'परिवर्तन छोड़ें?';

  @override
  String get postLoadDiscardMessage =>
      'आपके असहेजित लोड विवरण हैं। क्या आप उन्हें छोड़ना चाहते हैं?';

  @override
  String get ttsHindiVoice => 'हिंदी आवाज़';

  @override
  String get ttsEnglishVoice => 'अंग्रेज़ी आवाज़';

  @override
  String get ttsNoHindiVoices => 'इस डिवाइस पर कोई हिंदी आवाज़ उपलब्ध नहीं है।';

  @override
  String get ttsNoEnglishVoices =>
      'इस डिवाइस पर कोई अंग्रेज़ी आवाज़ उपलब्ध नहीं है।';

  @override
  String get supplierRatingAlreadySubmitting =>
      'आपकी रेटिंग पहले ही जमा की जा रही है';

  @override
  String get supplierTripActionAlreadyInProgress =>
      'एक अन्य सप्लायर ट्रिप कार्रवाई पहले से प्रगति पर है';

  @override
  String get truckerRatingAlreadySubmitting =>
      'आपकी रेटिंग पहले ही जमा की जा रही है';

  @override
  String get truckerTripActionAlreadyInProgress =>
      'एक अन्य ट्रिप कार्रवाई पहले से प्रगति पर है';

  @override
  String get truckerTripCannotAdvanceFromCurrentStage =>
      'इस ट्रिप को अपने वर्तमान चरण से आगे नहीं बढ़ाया जा सकता';

  @override
  String get truckerTripPodUploadOnlyAfterDelivery =>
      'POD केवल लोड डिलीवरी के बाद अपलोड किया जा सकता है';

  @override
  String get truckerTripLrUploadOnlyDuringPickup =>
      'LR केवल पिकअप चरणों के दौरान अपलोड किया जा सकता है';

  @override
  String get truckerLoadDetailUnavailable => 'लोड विवरण उपलब्ध नहीं है';

  @override
  String get truckerBookingAlreadyInProgress =>
      'बुकिंग अनुरोध पहले से प्रगति पर है';

  @override
  String get truckerTruckRequired => 'जारी रखने के लिए एक ट्रक चुनें';

  @override
  String get truckerTruckSaveAlreadyInProgress =>
      'ट्रक सहेजना पहले से प्रगति पर है';

  @override
  String get truckerTruckValidationFailed =>
      'कृपया हाइलाइट किए गए ट्रक विवरणों को सुधारें';

  @override
  String get truckerTruckNotFound => 'चयनित ट्रक नहीं मिला';

  @override
  String get chatVoiceConversationIdRequired => 'वार्तालाप आईडी आवश्यक है';

  @override
  String get chatVoiceRecordingAlreadyInProgress =>
      'एक वॉइस रिकॉर्डिंग पहले से प्रगति पर है';

  @override
  String get chatVoiceMicrophonePermissionRequired =>
      'वॉइस संदेश रिकॉर्ड करने के लिए माइक्रोफोन अनुमति आवश्यक है';

  @override
  String get chatVoiceNoActiveRecording =>
      'इस वार्तालाप के लिए कोई सक्रिय वॉइस रिकॉर्डिंग उपलब्ध नहीं है';

  @override
  String get chatMessageAlreadyBeingSent =>
      'एक अन्य संदेश पहले ही भेजा जा रहा है';

  @override
  String get notificationNotificationIdRequired => 'अधिसूचना आईडी आवश्यक है';

  @override
  String get profileUserIdRequired => 'उपयोगकर्ता आईडी आवश्यक है';

  @override
  String get reviewValidationFailed => 'कृपया समीक्षा विवरणों को सुधारें';

  @override
  String get reviewSubmitFailed => 'समीक्षा जमा करने में विफल';

  @override
  String get reviewAddReplyFailed =>
      'उत्तर जोड़ने में विफल। आपने पहले ही उत्तर दिया हो सकता है या आप समीक्षित उपयोगकर्ता नहीं हैं';

  @override
  String get verificationDetailUnavailable => 'वेरिफिकेशन विवरण उपलब्ध नहीं है';

  @override
  String get verificationActionAlreadyInProgress =>
      'एक अन्य वेरिफिकेशन कार्रवाई पहले से प्रगति पर है';

  @override
  String get verificationLocationCaptureOnlySupplier =>
      'वेरिफिकेशन लोकेशन कैप्चर केवल सप्लायर वेरिफिकेशन के लिए उपलब्ध है';

  @override
  String get verificationLocationCaptureFailed =>
      'अभी आपका वेरिफिकेशन स्थान कैप्चर नहीं किया जा सका। लोकेशन सेवाएँ जांचें और पुनः प्रयास करें';

  @override
  String get verificationCityRequired => 'वेरिफिकेशन शहर आवश्यक है';

  @override
  String get verificationSubmissionBlocked => 'वेरिफिकेशन जमा करना अवरुद्ध है';
}
