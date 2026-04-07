// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'ट्रांसज़फोर्ट';

  @override
  String get splashTagline => 'भारत भर में भरोसेमंद लोड मूवमेंट।';

  @override
  String get splashFirstOpenGreeting => 'ट्रांसज़फोर्ट में आपका स्वागत है।';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsScreenTtsContext =>
      'सेटिंग्स स्क्रीन। भाषा, वॉइस मार्गदर्शन, नोटिफिकेशन और अकाउंट विकल्प प्रबंधित करें।';

  @override
  String get appBarTtsMutedSnack => 'वॉइस मार्गदर्शन बंद कर दिया गया';

  @override
  String get appBarTtsEnabledSnack => 'वॉइस मार्गदर्शन चालू कर दिया गया';

  @override
  String get appBarLanguageChangedHindi => 'भाषा बदली: हिंदी';

  @override
  String get appBarLanguageChangedEnglish => 'भाषा बदली: अंग्रेज़ी';

  @override
  String appBarTtsTooltipMute(Object screen) {
    return 'वॉइस मार्गदर्शन बंद करें ($screen)';
  }

  @override
  String get appBarTtsTooltipEnable => 'वॉइस मार्गदर्शन चालू करें';

  @override
  String get appBarLanguageToggleTooltip => 'भाषा बदलें';

  @override
  String get appBarNotificationsTooltip => 'नोटिफिकेशन';

  @override
  String get appDrawerProfileTitle => 'प्रोफ़ाइल';

  @override
  String get appDrawerSupplierWorkspace => 'सप्लायर वर्कस्पेस';

  @override
  String get appDrawerTruckerWorkspace => 'ट्रकर वर्कस्पेस';

  @override
  String get appDrawerHome => 'होम';

  @override
  String get appDrawerDashboard => 'डैशबोर्ड';

  @override
  String get appDrawerVerification => 'सत्यापन';

  @override
  String get appDrawerBotChat => 'बॉट चैट';

  @override
  String get dashboardVerificationStatusVerified => 'सत्यापन पूरा हो गया';

  @override
  String get dashboardVerificationStatusPending => 'सत्यापन समीक्षा में है';

  @override
  String get dashboardVerificationStatusUnverified =>
      'सत्यापन शुरू नहीं हुआ है';

  @override
  String get dashboardVerificationStatusRejected =>
      'सत्यापन में सुधार जरूरी है';

  @override
  String get dashboardVerificationStatusUnknown => 'सत्यापन स्थिति उपलब्ध नहीं';

  @override
  String dashboardVerificationRejectedReason(Object reason) {
    return 'सुधार आवश्यक: $reason';
  }

  @override
  String get sharedLoadingSuffix => 'लोड हो रहा है';

  @override
  String get languageLabel => 'भाषा';

  @override
  String get languageEnglish => 'अंग्रेज़ी';

  @override
  String get languageHindi => 'हिंदी';

  @override
  String get postLoadTitle => 'लोड पोस्ट करें';

  @override
  String get loadDetailTitle => 'लोड विवरण';

  @override
  String get viewRouteMap => 'रूट मैप देखें';

  @override
  String get actionsTitle => 'कार्रवाइयाँ';

  @override
  String get loadNotFound => 'लोड नहीं मिला';

  @override
  String get couldNotStartChatRetry =>
      'चैट शुरू नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get verifyAction => 'सत्यापित करें';

  @override
  String get completeTruckerVerificationToChat =>
      'सप्लायर से चैट शुरू करने के लिए ट्रकर सत्यापन पूरा करें।';

  @override
  String get createLoadQuickSteps => '4 आसान स्टेप्स में लोड बनाएं';

  @override
  String get createLoadSubtitle =>
      'रूट, माल, ट्रक आवश्यकता और कीमत की जानकारी जोड़ें।';

  @override
  String get postLoadSuperLoadReadinessTitle => 'सुपर लोड तैयारी';

  @override
  String get postLoadSuperLoadReadinessSubtitle =>
      'सुपर लोड सपोर्ट के लिए सप्लायर सत्यापन और तैयार पेआउट प्रोफ़ाइल आवश्यक है।';

  @override
  String get loadPostedSuccess => 'लोड सफलतापूर्वक पोस्ट हो गया';

  @override
  String get loadPostFailure => 'लोड पोस्ट नहीं हो सका। कृपया फिर प्रयास करें।';

  @override
  String get postLoadSubmitAction => 'लोड पोस्ट करें';

  @override
  String get nextAction => 'अगला';

  @override
  String get backAction => 'वापस';

  @override
  String get postLoadStepRouteTitle => 'रूट';

  @override
  String get postLoadStepCargoTitle => 'कार्गो';

  @override
  String get postLoadStepVehicleTitle => 'वाहन';

  @override
  String get postLoadStepPriceScaleTitle => 'कीमत और स्केल';

  @override
  String postLoadStepSummary(Object current, Object total, Object label) {
    return 'चरण $current / $total — $label';
  }

  @override
  String get postLoadOriginCityLabel => 'मूल शहर';

  @override
  String get postLoadDestinationCityLabel => 'गंतव्य शहर';

  @override
  String postLoadApproxRouteInfo(Object km, Object hours) {
    return 'अनुमानित रूट: $km किमी · $hours घंटे';
  }

  @override
  String get postLoadDistanceUnavailableFallback =>
      'दूरी उपलब्ध नहीं है (ऑफलाइन बैकअप मोड चालू है)';

  @override
  String get postLoadMaterialLabel => 'माल का प्रकार';

  @override
  String get postLoadWeightPerTruckLabel => 'प्रति ट्रक वजन (टन)';

  @override
  String get postLoadTruckBodyTypeLabel => 'ट्रक बॉडी प्रकार';

  @override
  String get postLoadTruckTypeAny => 'कोई भी';

  @override
  String get postLoadTruckTypeOpen => 'ओपन';

  @override
  String get postLoadTruckTypeContainer => 'कंटेनर';

  @override
  String get postLoadTruckTypeTrailer => 'ट्रेलर';

  @override
  String get postLoadTruckTypeTanker => 'टैंकर';

  @override
  String get postLoadTruckTypeRefrigerated => 'रेफ्रिजरेटेड';

  @override
  String get postLoadPriceTotalLabel => 'कुल कीमत (₹)';

  @override
  String get postLoadPriceTypeFixed => 'फिक्स्ड';

  @override
  String get postLoadPriceTypeNegotiable => 'प्रति टन';

  @override
  String postLoadAdvanceLabel(int percentage) {
    return 'अग्रिम: $percentage%';
  }

  @override
  String get postLoadPickupDateLabel => 'पिकअप तारीख';

  @override
  String get postLoadChangeAction => 'बदलें';

  @override
  String get postLoadTrucksNeededLabel => 'कितने ट्रक चाहिए?';

  @override
  String get findLoadsTitle => 'लोड खोजें';

  @override
  String get searchLoads => 'लोड खोजें';

  @override
  String get resetAction => 'रीसेट';

  @override
  String get editAction => 'संपादित करें';

  @override
  String get loadsFound => 'लोड मिले';

  @override
  String get mapViewComingSoonTitle => 'मैप व्यू जल्द आ रहा है';

  @override
  String get mapViewComingSoonSubtitle =>
      'उपलब्ध लोड बुक करने के लिए लिस्ट व्यू पर वापस जाएं।';

  @override
  String get noLoadsFoundTitle => 'कोई लोड नहीं मिली';

  @override
  String get noLoadsFoundSubtitle => 'फ़िल्टर बदलें या बाद में फिर जांचें।';

  @override
  String get myLoadsTitle => 'मेरे लोड';

  @override
  String get myLoadsDashboardTts => 'मेरे लोड डैशबोर्ड';

  @override
  String get myLoadsScreenTtsContext =>
      'मेरे लोड डैशबोर्ड। सक्रिय और पूर्ण लोड, बुकिंग गतिविधि और पूर्ति प्रगति देखें।';

  @override
  String myLoadsScreenTtsContextDetailed(int active, int inTransit) {
    return 'आपका लोड डैशबोर्ड। $active सक्रिय लोड, $inTransit ट्रांजिट में।';
  }

  @override
  String get supplierOverview => 'सप्लायर ओवरव्यू';

  @override
  String get myLoadsOverviewSubtitle =>
      'सक्रिय लोड्स, बुकिंग और पूर्ति प्रगति ट्रैक करें।';

  @override
  String get myLoadsActiveLabel => 'सक्रिय लोड्स';

  @override
  String get myLoadsInTransitLabel => 'ट्रांजिट में';

  @override
  String myLoadsRequiresActionBanner(int count) {
    return '$count लोड पर आपकी कार्रवाई लंबित है।';
  }

  @override
  String get activeTab => 'सक्रिय';

  @override
  String get completedTab => 'पूर्ण';

  @override
  String get postLoadAction => 'लोड पोस्ट करें';

  @override
  String get noCompletedLoads => 'कोई पूर्ण लोड नहीं';

  @override
  String get noActiveLoads => 'कोई सक्रिय लोड नहीं';

  @override
  String get completedLoadsHere => 'पूर्ण/रद्द लोड यहां दिखेंगी।';

  @override
  String get postFirstLoadPrompt =>
      'बुकिंग शुरू करने के लिए अपनी पहली लोड पोस्ट करें।';

  @override
  String get loadDeactivated => 'लोड निष्क्रिय की गई';

  @override
  String get couldNotDeactivateLoad => 'लोड निष्क्रिय नहीं हो सकी';

  @override
  String get deactivateAction => 'निष्क्रिय करें';

  @override
  String myLoadsTrucksBookedSummary(int booked, int needed) {
    return '$booked/$needed ट्रक बुक';
  }

  @override
  String get myLoadsLoadErrorPrefix => 'आपकी लोड्स लोड नहीं हो सकीं';

  @override
  String get myLoadsStatusCompleted => 'पूर्ण';

  @override
  String get myLoadsStatusCancelled => 'रद्द';

  @override
  String get myLoadsStatusWaiting => 'प्रतीक्षा में';

  @override
  String get myLoadsStatusFullyBooked => 'पूरी तरह बुक';

  @override
  String get myLoadsStatusFulfilling => 'पूर्ति जारी';

  @override
  String get loadBookedAwaitingApproval =>
      'लोड बुक हो गई! सप्लायर अनुमोदन की प्रतीक्षा करें।';

  @override
  String get bookingFailedTryAgain => 'बुकिंग असफल हुई। कृपया फिर कोशिश करें।';

  @override
  String get loadBookTtsSuccess =>
      'बुकिंग अनुरोध भेज दिया गया है। सप्लायर अनुमोदन की प्रतीक्षा करें।';

  @override
  String get loadBookTtsFailure => 'बुकिंग असफल हुई। कृपया फिर कोशिश करें।';

  @override
  String get authTtsPromptGoogleOrPhone => 'Google या फोन नंबर से आगे बढ़ें।';

  @override
  String get authErrorNetwork => 'कृपया अपना इंटरनेट कनेक्शन जांचें।';

  @override
  String get authErrorAuthFailed =>
      'प्रमाणीकरण विफल रहा। कृपया फिर कोशिश करें।';

  @override
  String get authErrorConflict => 'यह खाता पहले से पंजीकृत है। साइन-इन करें।';

  @override
  String get authErrorValidation => 'कृपया दर्ज विवरण जांचें।';

  @override
  String get authErrorGeneric => 'कुछ गलत हुआ। कृपया फिर कोशिश करें।';

  @override
  String get authOneFinalStep => 'बस एक अंतिम चरण';

  @override
  String get authWelcomeTitle => 'ट्रांसज़फोर्ट में आपका स्वागत है';

  @override
  String get authGoogleDoneAddMobile =>
      'Google साइन-इन पूरा। आगे बढ़ने के लिए मोबाइल नंबर जोड़ें।';

  @override
  String get authWelcomeSubtitle =>
      'सप्लायर और ट्रकर के लिए भारत का भरोसेमंद लोड-मैचिंग प्लेटफ़ॉर्म।';

  @override
  String get authContinueJourney => 'अपनी यात्रा जारी रखें';

  @override
  String get authChooseSignInMethod => 'अपना पसंदीदा साइन-इन तरीका चुनें।';

  @override
  String get authOr => 'या';

  @override
  String get authContinueWithPhone => 'फोन से जारी रखें';

  @override
  String get authContinueWithGoogle => 'Google से जारी रखें';

  @override
  String get authTermsAgreement =>
      'आगे बढ़कर आप हमारी सेवा शर्तों और गोपनीयता नीति से सहमत होते हैं।';

  @override
  String get phoneInvalidNumber => 'कृपया सही फोन नंबर दर्ज करें';

  @override
  String get phoneSaveErrorAuth =>
      'मोबाइल नंबर सेव नहीं हो सका। कृपया फिर कोशिश करें।';

  @override
  String get phoneSaveErrorConflict =>
      'यह नंबर किसी अन्य खाते से जुड़ा है। दूसरा नंबर आज़माएँ।';

  @override
  String get phoneSaveErrorValidation => 'कृपया सही मोबाइल नंबर दर्ज करें।';

  @override
  String get phoneEnterMobileTitle => 'अपना मोबाइल नंबर दर्ज करें';

  @override
  String get phoneEnterMobileSubtitle =>
      'आगे बढ़ने के लिए नंबर जोड़ें। अभी OTP सत्यापन स्थगित है।';

  @override
  String get phoneVerificationSetup => 'मोबाइल सत्यापन सेटअप';

  @override
  String get phoneVerificationSetupSubtitle =>
      'बुकिंग और ट्रिप अलर्ट पाने के लिए सक्रिय नंबर उपयोग करें।';

  @override
  String get phoneLabelMobileNumber => 'मोबाइल नंबर';

  @override
  String get commonContinue => 'जारी रखें';

  @override
  String get otpTtsPrompt => 'अपने फोन पर भेजा गया 6 अंकों का OTP दर्ज करें।';

  @override
  String get otpVerificationDeferredMessage =>
      'अभी OTP सत्यापन स्थगित है। कृपया मोबाइल कैप्चर फ्लो से जारी रखें।';

  @override
  String get otpVerificationDeferredTitle => 'OTP सत्यापन फिलहाल स्थगित है';

  @override
  String get otpVerificationDeferredSubtitle =>
      'ऑनबोर्डिंग जारी रखने के लिए मोबाइल कैप्चर फ्लो का उपयोग करें।';

  @override
  String get otpVerify => 'सत्यापित करें';

  @override
  String get otpResendDeferred => 'अभी OTP पुनः भेजना स्थगित है।';

  @override
  String get otpResendCode => 'कोड दोबारा भेजें';

  @override
  String get roleTtsPrompt => 'क्या आप सप्लायर हैं या ट्रकर? कृपया चुनें।';

  @override
  String get roleErrorAuth =>
      'आपका सत्र समाप्त हो गया है। कृपया फिर साइन-इन करें।';

  @override
  String get roleErrorConflict => 'रोल सेटअप पहले ही पूरा हो चुका है।';

  @override
  String get roleErrorValidation => 'कृपया एक मान्य रोल चुनें।';

  @override
  String get roleErrorGeneric => 'रोल सेव नहीं हो सका। कृपया फिर कोशिश करें।';

  @override
  String get roleTitle => 'आप ट्रांसज़फोर्ट का उपयोग कैसे करेंगे?';

  @override
  String get roleSubtitle =>
      'डैशबोर्ड और कार्रवाइयों को व्यक्तिगत बनाने के लिए अपना रोल चुनें।';

  @override
  String get roleSupplierTitle => 'मैं सप्लायर / कन्साइनर हूँ';

  @override
  String get roleSupplierSubtitle =>
      'मैं लोड पोस्ट करना और ट्रक ढूंढना चाहता हूँ';

  @override
  String get roleTruckerTitle => 'मैं ट्रकर / ट्रांसपोर्टर हूँ';

  @override
  String get roleTruckerSubtitle =>
      'मैं लोड ढूंढना और अपना बेड़ा प्रबंधित करना चाहता हूँ';

  @override
  String get roleCompleteSetup => 'सेटअप पूरा करें';

  @override
  String get myTripsTitle => 'मेरी ट्रिप्स';

  @override
  String get myTripsDashboardTts => 'मेरी ट्रिप्स डैशबोर्ड';

  @override
  String get myTripsScreenTtsContext =>
      'मेरी ट्रिप्स डैशबोर्ड। वर्तमान ट्रिप्स, पूर्ण डिलीवरी और स्टेज अपडेट ट्रैक करें।';

  @override
  String myTripsScreenTtsContextDetailed(
    int active,
    Object origin,
    Object destination,
  ) {
    return 'आपकी ट्रिप्स। $active सक्रिय। वर्तमान ट्रिप: $origin से $destination।';
  }

  @override
  String get truckerOverview => 'ट्रकर ओवरव्यू';

  @override
  String get truckerDashboardActiveBidsLabel => 'सक्रिय बोलियां';

  @override
  String get truckerDashboardUpcomingTripsLabel => 'आगामी ट्रिप्स';

  @override
  String get truckerDashboardPendingBidsTitle => 'लंबित बोलियां';

  @override
  String get truckerDashboardUpcomingActiveTripsTitle =>
      'आगामी और सक्रिय ट्रिप्स';

  @override
  String get tripOverviewSubtitle =>
      'सक्रिय ट्रिप्स और स्टेज प्रगति पर नज़र रखें।';

  @override
  String get activeTripStatus => 'सक्रिय ट्रिप स्थिति';

  @override
  String get tripMilestonesSubtitle =>
      'अगला स्टेज देखें और दस्तावेज़ तैयार रखें।';

  @override
  String get noCompletedTrips => 'कोई पूर्ण ट्रिप नहीं';

  @override
  String get noActiveTrips => 'कोई सक्रिय ट्रिप नहीं';

  @override
  String get completedTripsHere => 'पूर्ण ट्रिप्स यहां दिखेंगी।';

  @override
  String get bookLoadPrompt =>
      'अपनी पहली ट्रिप शुरू करने के लिए Find Loads से लोड बुक करें।';

  @override
  String get findLoadsAction => 'लोड खोजें';

  @override
  String get tripsLoadError =>
      'ट्रिप्स लोड नहीं हो सकीं। कृपया फिर प्रयास करें।';

  @override
  String get tripRecentlyUpdated => 'हाल ही में अपडेट';

  @override
  String get tripCompletedPrefix => 'पूर्ण';

  @override
  String get tripStartedPrefix => 'शुरू';

  @override
  String get tripApprovedPrefix => 'स्वीकृत';

  @override
  String get tripDeliveredPrefix => 'डिलीवर';

  @override
  String get tripPodUploadedPrefix => 'POD अपलोड';

  @override
  String get tripUpdatedPrefix => 'अपडेट';

  @override
  String get tripStageCompleted => 'पूर्ण';

  @override
  String get tripStageInTransit => 'ट्रांजिट में';

  @override
  String get tripStageAtPickup => 'पिकअप पर';

  @override
  String get tripStageDelivered => 'डिलीवर';

  @override
  String get tripStagePodUploaded => 'POD अपलोड';

  @override
  String get tripStageUnknown => 'अज्ञात';

  @override
  String get messagesTitle => 'संदेश';

  @override
  String get chatInboxTts => 'संदेश इनबॉक्स';

  @override
  String get chatInboxScreenTtsContext =>
      'संदेश इनबॉक्स। सप्लायर और ट्रकर के साथ बातचीत खोलें और हाल के अपडेट देखें।';

  @override
  String chatInboxScreenTtsContextCount(int count) {
    return 'आपके संदेश। $count बातचीत।';
  }

  @override
  String get chatNoMessagesTitle => 'अभी कोई संदेश नहीं';

  @override
  String get chatSupplierInboxSubtitle => 'लोड से जुड़कर चैट शुरू करें।';

  @override
  String get chatTruckerInboxSubtitle => 'लोड बुक करके चैट शुरू करें।';

  @override
  String get chatTapToOpenConversation => 'कन्वर्सेशन खोलने के लिए टैप करें';

  @override
  String get chatTapToViewConversation => 'कन्वर्सेशन देखने के लिए टैप करें';

  @override
  String get chatConversationsSuffix => 'ट्रकर कन्वर्सेशन';

  @override
  String get chatFailedLoadMessages => 'संदेश लोड नहीं हो सके';

  @override
  String get chatTruckerFallbackName => 'ट्रकर';

  @override
  String get chatSupplierFallbackName => 'सप्लायर';

  @override
  String get chatOpenConversationPrefix => 'कन्वर्सेशन खोलें';

  @override
  String get tripDetailTitle => 'ट्रिप विवरण';

  @override
  String get tripNotFound => 'ट्रिप नहीं मिली';

  @override
  String get tripSnapshotTitle => 'ट्रिप स्नैपशॉट';

  @override
  String get tripSnapshotTruck => 'ट्रक';

  @override
  String get tripSnapshotWeight => 'वजन';

  @override
  String get tripSnapshotDistance => 'दूरी';

  @override
  String get tripSnapshotPrice => 'कीमत';

  @override
  String get tripPickupActions => 'पिकअप कार्रवाइयाँ';

  @override
  String get tripTransitAction => 'ट्रांजिट कार्रवाई';

  @override
  String get tripDeliveryProof => 'डिलीवरी प्रमाण';

  @override
  String get tripLoadError =>
      'ट्रिप विवरण लोड नहीं हो सके। कृपया फिर प्रयास करें।';

  @override
  String get tripPodUploaded => 'POD अपलोड';

  @override
  String get tripPodUploadedWaiting =>
      'सप्लायर द्वारा डिलीवरी पुष्टि की प्रतीक्षा है।';

  @override
  String get tripTimelinePickup => 'पिकअप';

  @override
  String get tripTimelineTransit => 'ट्रांजिट';

  @override
  String get tripTimelineDelivered => 'डिलीवर';

  @override
  String get tripTimelinePodUploaded => 'POD अपलोड';

  @override
  String get tripTimelineCompleted => 'पूर्ण';

  @override
  String get tripRouteToolsTitle => 'रूट टूल्स';

  @override
  String get tripViewRoutePreviewAction => 'रूट प्रीव्यू देखें';

  @override
  String get tripOpenNavigationAction => 'नेविगेशन खोलें';

  @override
  String get tripNavigateToPickupAction => 'पिकअप तक नेविगेट करें';

  @override
  String get tripNavigateToDestinationAction => 'गंतव्य तक नेविगेट करें';

  @override
  String get tripNavigationUnavailable =>
      'नेविगेशन के लिए गंतव्य निर्देशांक उपलब्ध नहीं हैं।';

  @override
  String get tripLocationCaptured => 'लोकेशन कैप्चर हो गई।';

  @override
  String tripLocationCapturedAt(Object location) {
    return 'लोकेशन $location पर कैप्चर की गई।';
  }

  @override
  String get tripYourRatingPrefix => 'आपकी रेटिंग';

  @override
  String get tripRateThisPrefix => 'रेट करें';

  @override
  String get tripCommentOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get tripSubmitRating => 'रेटिंग सबमिट करें';

  @override
  String get tripRatingSubmitted => 'रेटिंग सबमिट हो गई।';

  @override
  String get tripRatingSubmitError =>
      'रेटिंग सबमिट नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get tripStartAction => 'शुरू करें';

  @override
  String get tripStartDialogTitle => 'ट्रिप शुरू करें';

  @override
  String get tripStartDialogMessage =>
      'क्या आपने कार्गो लोड कर लिया है और शुरू करने के लिए तैयार हैं?';

  @override
  String get tripCancelAction => 'रद्द करें';

  @override
  String get tripStartSuccess => 'ट्रिप सफलतापूर्वक शुरू हुई।';

  @override
  String get tripStartError => 'ट्रिप शुरू नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get tripStartTtsSuccess => 'ट्रिप सफलतापूर्वक शुरू हुई।';

  @override
  String get tripStartTtsFailure =>
      'ट्रिप शुरू नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get tripUploadLrOptional => 'LR अपलोड करें (वैकल्पिक)';

  @override
  String get tripLrUploadSuccess => 'LR सफलतापूर्वक अपलोड हुई।';

  @override
  String get tripLrUploadError =>
      'LR अपलोड नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get tripMarkDelivered => 'डिलीवर मार्क करें';

  @override
  String get tripMarkDeliveredDialogTitle => 'डिलीवर मार्क करें';

  @override
  String get tripMarkDeliveredDialogMessage =>
      'क्या कार्गो गंतव्य पर उतार दी गई है?';

  @override
  String get tripConfirmAction => 'पुष्टि करें';

  @override
  String get tripMarkedDeliveredNextPod =>
      'डिलीवर मार्क किया गया। अब POD अपलोड करें।';

  @override
  String get tripMarkDeliveredError =>
      'डिलीवर मार्क नहीं हो सकी। कृपया फिर प्रयास करें।';

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
  String get tripUploadProofOfDelivery => 'डिलीवरी का प्रमाण अपलोड करें';

  @override
  String get tripUploadPodPhoto => 'POD फोटो अपलोड करें';

  @override
  String get tripPodUploadSuccessWaiting =>
      'POD अपलोड हो गई। सप्लायर पुष्टि की प्रतीक्षा करें।';

  @override
  String get tripPodUploadError =>
      'POD अपलोड नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String get tripPodUploadTtsSuccess =>
      'डिलीवरी प्रमाण अपलोड हो गया। पुष्टि की प्रतीक्षा करें।';

  @override
  String get tripPodUploadTtsFailure =>
      'डिलीवरी प्रमाण अपलोड नहीं हो सका। कृपया फिर प्रयास करें।';

  @override
  String get chatTitle => 'चैट';

  @override
  String get chatMicrophonePermissionRequired => 'माइक्रोफोन अनुमति आवश्यक है';

  @override
  String get chatVoiceRecordingEmpty => 'वॉइस रिकॉर्डिंग खाली थी';

  @override
  String get chatCouldNotReadRecordedFile =>
      'रिकॉर्ड की गई फ़ाइल पढ़ी नहीं जा सकी';

  @override
  String get chatVoiceMessageSent => 'वॉइस संदेश भेजा गया';

  @override
  String get chatVoiceMessageSendFailed => 'वॉइस संदेश भेजने में विफल';

  @override
  String get chatVoiceFileUnavailable => 'वॉइस फ़ाइल उपलब्ध नहीं';

  @override
  String get chatUnablePlayVoiceMessage => 'वॉइस संदेश चलाया नहीं जा सका';

  @override
  String get chatLocationShared => 'लोकेशन साझा की गई';

  @override
  String get chatCouldNotShareLocation => 'लोकेशन साझा नहीं हो सकी';

  @override
  String get chatBookingActionShared => 'बुकिंग कार्रवाई साझा की गई';

  @override
  String get chatCouldNotShareBookingAction =>
      'बुकिंग कार्रवाई साझा नहीं हो सकी';

  @override
  String get chatBookingRequestSentFromChat => 'चैट से बुकिंग अनुरोध भेजा गया।';

  @override
  String get chatCouldNotBookFromChat => 'चैट से बुक नहीं हो सकी।';

  @override
  String get chatAttachShareLocation => 'वर्तमान लोकेशन साझा करें (मैप कार्ड)';

  @override
  String get chatAttachShareBookingAction => 'बुकिंग कार्रवाई साझा करें';

  @override
  String get chatMapCardTitleLocationShared => 'लोकेशन साझा की गई';

  @override
  String get chatMapCoordinatesUnavailable => 'कोऑर्डिनेट उपलब्ध नहीं';

  @override
  String chatMapLatLng(Object lat, Object lng) {
    return 'अक्षांश $lat, देशांतर $lng';
  }

  @override
  String get chatBookThisLoad => 'यह लोड बुक करें';

  @override
  String get chatBookingActionDescription =>
      'इस चैट से बुकिंग अनुरोध भेजने के लिए नीचे टैप करें।';

  @override
  String get chatFailedSendMessage => 'संदेश भेजने में विफल';

  @override
  String get chatNoMessagesYet => 'अभी कोई संदेश नहीं।';

  @override
  String get chatAttach => 'अटैच';

  @override
  String get chatTypeMessageHint => 'संदेश लिखें...';

  @override
  String get chatSendMessageTooltip => 'संदेश भेजें';

  @override
  String get chatStopRecordingTooltip => 'रिकॉर्डिंग रोकें';

  @override
  String get chatStartRecordingTooltip => 'रिकॉर्डिंग शुरू करें';

  @override
  String get chatVoiceLabel => 'वॉइस';

  @override
  String get chatPlayAction => 'चलाएँ';

  @override
  String get chatStopAction => 'रोकें';

  @override
  String get chatOpenMap => 'मैप खोलें';

  @override
  String get verificationSupplierPrompt => 'सप्लायर सत्यापन पूरा करें';

  @override
  String get verificationTruckerPrompt => 'ट्रकर सत्यापन पूरा करें';

  @override
  String get verificationRequired => 'सत्यापन आवश्यक';

  @override
  String get verificationPendingReview => 'सत्यापन समीक्षा में है';

  @override
  String get verificationPendingMessage =>
      'आपका खाता समीक्षा में है। स्वीकृति के बाद लोड पोस्टिंग सक्षम होगी।';

  @override
  String get verificationRequiredMessage =>
      'लोड पोस्ट करने और पूरी मार्केटप्लेस सुविधा के लिए सप्लायर सत्यापन पूरा करें।';

  @override
  String get completeVerification => 'सत्यापन पूरा करें';

  @override
  String get chatWithSupplier => 'सप्लायर से चैट करें';

  @override
  String get callSupplierAction => 'सप्लायर को कॉल करें';

  @override
  String get callSupplierUnavailable =>
      'अभी सप्लायर का फोन नंबर उपलब्ध नहीं है।';

  @override
  String get callSupplierLaunchFailed =>
      'फोन ऐप नहीं खुल सकी। कृपया फिर प्रयास करें।';

  @override
  String get postedByPrefix => 'पोस्ट किया गया';

  @override
  String get settingsTtsPreviewText => 'सेटिंग्स स्क्रीन';

  @override
  String get settingsHeroTitle => 'अपने TranZfort वर्कस्पेस को व्यक्तिगत बनाएं';

  @override
  String get settingsHeroSubtitle =>
      'भाषा, वॉइस, नोटिफिकेशन और अकाउंट एक्सेस को एक ही जगह से नियंत्रित करें।';

  @override
  String get settingsGeneralSection => 'सामान्य';

  @override
  String get settingsLanguageSubtitle =>
      'ऐप लेबल और प्रॉम्प्ट्स की इंटरफ़ेस भाषा।';

  @override
  String get settingsVoiceNotificationsSection => 'वॉइस और नोटिफिकेशन';

  @override
  String get settingsTtsSpeedLabel => 'बोलने की गति';

  @override
  String settingsTtsSpeedValue(Object speed) {
    return 'वर्तमान गति: ${speed}x';
  }

  @override
  String get settingsTtsLanguageLabel => 'TTS भाषा';

  @override
  String get settingsTtsLanguageAuto => 'ऑटो (ऐप भाषा के अनुसार)';

  @override
  String get settingsTtsPreviewAction => 'आवाज़ सुनें';

  @override
  String get settingsTtsMuteTitle => 'TTS म्यूट';

  @override
  String get settingsTtsMuteSubtitle => 'सभी ऑटोमैटिक वॉइस बंद करता है';

  @override
  String get settingsPushNotificationsTitle => 'पुश नोटिफिकेशन';

  @override
  String get settingsPushNotificationsSubtitle =>
      'लोड, ट्रिप और सत्यापन के अपडेट तुरंत पाएं।';

  @override
  String get settingsAccountSupportSection => 'अकाउंट और सहायता';

  @override
  String get settingsMyProfileTitle => 'मेरा प्रोफ़ाइल';

  @override
  String get settingsMyProfileSubtitle =>
      'अपनी भूमिका और सत्यापन स्थिति देखें।';

  @override
  String get settingsPayoutProfileTitle => 'पेआउट प्रोफ़ाइल';

  @override
  String get settingsPayoutProfileSubtitle =>
      'खाता और पेआउट विवरण प्रबंधित करें।';

  @override
  String get payoutAccountHolderLabel => 'अकाउंट होल्डर';

  @override
  String get payoutAccountLast4Label => 'अकाउंट अंतिम अंक';

  @override
  String get payoutIfscLabel => 'IFSC';

  @override
  String get payoutStatusLabel => 'स्थिति';

  @override
  String get payoutNoProfileTitle => 'अभी कोई पेआउट प्रोफ़ाइल नहीं';

  @override
  String get payoutNoProfileSubtitle =>
      'जब आपकी वित्तीय प्रोफ़ाइल उपलब्ध होगी, पेआउट विवरण यहाँ दिखाई देंगे।';

  @override
  String get payoutLoadError => 'पेआउट प्रोफ़ाइल लोड नहीं हो सकी।';

  @override
  String get settingsHelpSupportTitle => 'मदद और सहायता';

  @override
  String get settingsHelpSupportSubtitle =>
      'ऐप समस्या या अकाउंट मदद के लिए सपोर्ट लें।';

  @override
  String get supportScreenTtsContext =>
      'सपोर्ट स्क्रीन। टिकट बनाएं, अपडेट ट्रैक करें, और सपोर्ट टीम को जवाब दें।';

  @override
  String get supportHeroTitle => 'TranZfort सपोर्ट टीम से मदद लें';

  @override
  String get supportHeroSubtitle =>
      'बुकिंग, ट्रिप, सत्यापन, अकाउंट, या पेआउट समस्याओं के लिए टिकट बनाएं और जवाब यहीं ट्रैक करें।';

  @override
  String get supportCreateTicketTitle => 'सपोर्ट टिकट बनाएं';

  @override
  String get supportCategoryLabel => 'श्रेणी';

  @override
  String get supportCategoryTechnicalBug => 'तकनीकी बग';

  @override
  String get supportCategoryBookingIssue => 'बुकिंग समस्या';

  @override
  String get supportCategoryTripIssue => 'ट्रिप समस्या';

  @override
  String get supportCategoryPaymentPayout => 'पेमेंट या पेआउट';

  @override
  String get supportCategoryVerification => 'सत्यापन';

  @override
  String get supportCategoryAccountAccess => 'अकाउंट एक्सेस';

  @override
  String get supportCategoryOther => 'अन्य';

  @override
  String get supportSubjectLabel => 'विषय';

  @override
  String get supportSubjectHint => 'समस्या का छोटा सारांश';

  @override
  String get supportDescriptionLabel => 'विवरण';

  @override
  String get supportDescriptionHint =>
      'बताएं क्या हुआ और आपको किस तरह की मदद चाहिए।';

  @override
  String get supportSubmitTicketAction => 'टिकट सबमिट करें';

  @override
  String get supportMyTicketsTitle => 'मेरे टिकट';

  @override
  String get supportEmptyTitle => 'अभी कोई सपोर्ट टिकट नहीं है';

  @override
  String get supportEmptySubtitle =>
      'अपना पहला टिकट बनाएं और सपोर्ट टीम के अपडेट यहीं ट्रैक करें।';

  @override
  String get supportLoadError =>
      'सपोर्ट टिकट लोड नहीं हो सके। कृपया फिर प्रयास करें।';

  @override
  String get supportSubjectRequired => 'कृपया अपने टिकट के लिए विषय दर्ज करें।';

  @override
  String get supportDescriptionRequired =>
      'कृपया अपने टिकट के लिए विवरण दर्ज करें।';

  @override
  String get supportCreateFailed =>
      'सपोर्ट टिकट सबमिट नहीं हो सका। कृपया फिर प्रयास करें।';

  @override
  String get supportTicketSubmitted => 'सपोर्ट टिकट सफलतापूर्वक सबमिट हो गया।';

  @override
  String get supportCreatedLabel => 'बनाया गया';

  @override
  String get supportResolvedLabel => 'समाधान हुआ';

  @override
  String get supportTicketIdLabel => 'टिकट आईडी';

  @override
  String get supportStatusOpen => 'खुला';

  @override
  String get supportStatusInProgress => 'प्रगति में';

  @override
  String get supportStatusResolved => 'समाधान हुआ';

  @override
  String get supportPriorityLow => 'कम';

  @override
  String get supportPriorityMedium => 'मध्यम';

  @override
  String get supportPriorityHigh => 'उच्च';

  @override
  String get supportPriorityUrgent => 'तत्काल';

  @override
  String get supportTicketDetailTitle => 'सपोर्ट टिकट';

  @override
  String get supportTicketNotFoundTitle => 'सपोर्ट टिकट नहीं मिला';

  @override
  String get supportTicketNotFoundSubtitle =>
      'यह टिकट उपलब्ध नहीं है या आपके अकाउंट से अब एक्सेस नहीं हो सकता।';

  @override
  String get supportResolutionNotesTitle => 'समाधान नोट्स';

  @override
  String get supportConversationTitle => 'वार्तालाप';

  @override
  String get supportNoMessagesYet =>
      'अभी कोई जवाब नहीं है। सपोर्ट टीम यहीं जवाब देगी।';

  @override
  String get supportReplySectionTitle => 'जवाब भेजें';

  @override
  String get supportTicketResolvedReplyClosed =>
      'यह टिकट हल हो चुका है। अभी जवाब बंद हैं।';

  @override
  String get supportReplyHint =>
      'अधिक जानकारी जोड़ें या सपोर्ट टीम को जवाब दें';

  @override
  String get supportSendReplyAction => 'जवाब भेजें';

  @override
  String get supportResolvedTicketReadOnlyAction => 'समाधान हो चुका टिकट';

  @override
  String get supportReplyRequired => 'कृपया भेजने से पहले जवाब दर्ज करें।';

  @override
  String get supportReplyFailed =>
      'आपका जवाब भेजा नहीं जा सका। कृपया फिर प्रयास करें।';

  @override
  String get supportReplySent => 'जवाब सफलतापूर्वक भेज दिया गया।';

  @override
  String get supportYouLabel => 'आप';

  @override
  String get supportSupportTeamLabel => 'सपोर्ट टीम';

  @override
  String get settingsSupportPending =>
      'सपोर्ट स्क्रीन Sprint 9 में जोड़ी जाएगी';

  @override
  String get settingsAppVersionTitle => 'ऐप संस्करण';

  @override
  String get settingsCurrentBuildPrefix => 'वर्तमान बिल्ड';

  @override
  String get settingsDangerZone => 'डेंजर ज़ोन';

  @override
  String get settingsDeleteAccountTitle => 'खाता स्थायी रूप से हटाएँ';

  @override
  String get settingsDeleteAccountSubtitle =>
      'खाता डिलीट रिक्वेस्ट जाएगी और आप तुरंत साइन आउट हो जाएंगे।';

  @override
  String get settingsDeleteAccountAction => 'खाता हटाएँ';

  @override
  String get settingsDeleteAccountDialogTitle => 'खाता हटाएँ?';

  @override
  String get settingsDeleteAccountDialogContent =>
      'यह आपका खाता और पूरा डेटा हमेशा के लिए मिटा देगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get settingsDeleteAction => 'हटाएँ';

  @override
  String get settingsDeleteAccountFailed =>
      'खाता हटाने का अनुरोध नहीं हो सका, फिर प्रयास करें';

  @override
  String get settingsSignOutAction => 'साइन आउट';

  @override
  String get verificationSubmitSuccess => 'सत्यापन सफलतापूर्वक सबमिट हुआ!';

  @override
  String get verificationLoadError =>
      'सत्यापन विवरण लोड नहीं हो सका। कृपया फिर प्रयास करें।';

  @override
  String get retryAction => 'पुनः प्रयास';

  @override
  String get verificationUploadMandatory =>
      'कृपया सभी अनिवार्य दस्तावेज़ अपलोड करें।';

  @override
  String get verificationSupplierTitle => 'सप्लायर सत्यापन';

  @override
  String get verificationTruckerTitle => 'ट्रकर सत्यापन';

  @override
  String get verificationSupplierSubtitle =>
      'पूरी मार्केटप्लेस पहुंच के लिए व्यवसाय और पहचान दस्तावेज़ जमा करें।';

  @override
  String get verificationTruckerSubtitle =>
      'ट्रिप संचालन सक्रिय करने के लिए पहचान और ड्राइविंग दस्तावेज़ अपलोड करें।';

  @override
  String verificationDocumentsUploadedSummary(int uploaded, int total) {
    return '$uploaded में से $total दस्तावेज़ अपलोड हुए';
  }

  @override
  String get verificationChooseImageSourceTitle => 'इमेज स्रोत चुनें';

  @override
  String get verificationUseCamera => 'कैमरा इस्तेमाल करें';

  @override
  String get verificationUseGallery => 'गैलरी से चुनें';

  @override
  String get verificationAadhaarHelper =>
      'आधार के अनुसार पूरे 12 अंक सही-सही दर्ज करें।';

  @override
  String get verificationPanHelper => 'PAN प्रारूप: ABCDE1234F';

  @override
  String get verificationPanInvalid => 'मान्य PAN दर्ज करें (जैसे ABCDE1234F)';

  @override
  String get verificationDlHelper =>
      'ड्राइविंग लाइसेंस नंबर जैसा है वैसा ही दर्ज करें।';

  @override
  String get verificationTruckRequiredMessage =>
      'सत्यापन से पहले नंबर, बॉडी टाइप, टायर, क्षमता और RC फोटो सहित कम-से-कम एक पूरा ट्रक जोड़ें।';

  @override
  String get verificationVerifiedLockedTitle => 'सत्यापन पहले से स्वीकृत है';

  @override
  String get verificationVerifiedLockedBody =>
      'सत्यापन स्वीकृत होने के कारण आपकी जानकारी लॉक है। केवल दोबारा सत्यापन के लिए बदलाव करने पर एडिट करें।';

  @override
  String get verificationEditAndResubmitAction =>
      'एडिट करें और दोबारा सबमिट करें';

  @override
  String get verificationReverificationNotice =>
      'बदलाव के बाद आपका प्रोफ़ाइल दोबारा समीक्षा के लिए पेंडिंग में चला जाएगा।';

  @override
  String get verificationImageQualityHint =>
      'ध्यान दें: फोटो साफ, पढ़ने योग्य और पूरी तरह दिखाई देनी चाहिए।';

  @override
  String get documentAttachedTapReplace =>
      'दस्तावेज़ संलग्न है। बदलने के लिए टैप करें।';

  @override
  String get documentTapUploadRequired =>
      'आवश्यक दस्तावेज़ अपलोड करने के लिए टैप करें';

  @override
  String get retakeAction => 'फिर से लें';

  @override
  String get uploadAction => 'अपलोड करें';

  @override
  String get findLoadsVerifiedTruckRequiredTitle => 'सत्यापित ट्रक आवश्यक है';

  @override
  String get findLoadsVerifiedTruckRequiredBody =>
      'लोड बुक करने के लिए सत्यापित ट्रक चाहिए। क्या अभी ट्रक जोड़ना है?';

  @override
  String get findLoadsNotNow => 'अभी नहीं';

  @override
  String get findLoadsAddTruck => 'ट्रक जोड़ें';

  @override
  String get findLoadsAnyMaterial => 'कोई भी माल';

  @override
  String get findLoadsSelectedTruck => 'चयनित ट्रक';

  @override
  String get findLoadsConfirmBookingTitle => 'बुकिंग की पुष्टि करें';

  @override
  String get findLoadsBookConfirmPrefix => 'क्या आप';

  @override
  String get findLoadsBookConfirmFrom => 'लोड';

  @override
  String get findLoadsBookConfirmTo => 'तक';

  @override
  String get findLoadsBookConfirmWith => 'को';

  @override
  String get findLoadsAllRoutes => 'सभी रूट';

  @override
  String get findLoadsAny => 'कोई भी';

  @override
  String get findLoadsAnyTruck => 'कोई भी ट्रक';

  @override
  String get findLoadsSelectTruckForLoad => 'इस लोड के लिए ट्रक चुनें';

  @override
  String get findLoadsUnknownTruckType => 'ट्रक प्रकार अज्ञात';

  @override
  String get findLoadsTyresSuffix => 'टायर';

  @override
  String get findLoadsMatchLabel => 'मैच';

  @override
  String get findLoadsMismatchLabel => 'मेल नहीं';

  @override
  String get findLoadsDashboardTts => 'लोड खोज डैशबोर्ड';

  @override
  String get findLoadsScreenTtsContext =>
      'लोड खोज डैशबोर्ड। उपलब्ध लोड खोजें, रूट फ़िल्टर लागू करें और सर्वोत्तम मैच देखें।';

  @override
  String findLoadsScreenTtsContextCount(int count) {
    return 'लोड मार्केटप्लेस। $count लोड मिलीं।';
  }

  @override
  String get findLoadsHeroTitle => 'सही लोड जल्दी खोजें';

  @override
  String get findLoadsHeroSubtitle =>
      'रूट, माल और ट्रक फ़िल्टर से बेहतर मैच चुनें।';

  @override
  String get findLoadsFromLabel => 'से';

  @override
  String get findLoadsToLabel => 'तक';

  @override
  String get findLoadsAdvancedFilters => 'उन्नत फ़िल्टर';

  @override
  String get findLoadsListViewLabel => 'सूची';

  @override
  String get findLoadsMapViewLabel => 'मैप';

  @override
  String get botCancelResponse =>
      'ठीक है, मैंने प्रोसेस कैंसल कर दिया है। और कुछ?';

  @override
  String get botMyLoadsResponse => 'यहाँ आपके लोड्स हैं।';

  @override
  String get botViewLoadsAction => 'लोड्स देखें';

  @override
  String get botMyTripsResponse => 'यहाँ आपके ट्रिप्स हैं।';

  @override
  String get botViewTripsAction => 'ट्रिप्स देखें';

  @override
  String get botCheckStatusResponse => 'यहाँ अपनी बुकिंग स्थिति देखें।';

  @override
  String get botCheckStatusAction => 'स्थिति देखें';

  @override
  String get botHelpResponse =>
      'मैं आपकी लोड ढूंढने, पोस्ट करने और ट्रिप्स चेक करने में मदद कर सकता हूँ। बोल कर देखें \'लोड ढूंढो\'।';

  @override
  String get botGreetingResponse =>
      'नमस्ते! मैं TranZfort बॉट हूँ। आज मैं आपकी क्या मदद कर सकता हूँ?';

  @override
  String get botUnknownResponse =>
      'मैं समझ नहीं पाया। आप \'लोड ढूंढो\', \'लोड डालना है\', या \'ट्रिप स्टेटस\' बोल सकते हैं।';

  @override
  String get botAskOrigin => 'कहाँ से? (शहर का नाम बताएँ)';

  @override
  String get botAskDestination => 'कहाँ तक? (शहर का नाम बताएँ)';

  @override
  String botFindLoadSummary(String origin, String dest) {
    return '$origin से $dest के लिए लोड्स ढूँढ रहा हूँ। देखें?';
  }

  @override
  String get botAskPostOrigin => 'आप लोड कहाँ से भेज रहे हैं?';

  @override
  String get botAskPostDestination => 'आप इसे कहाँ भेज रहे हैं?';

  @override
  String get botAskPostMaterial =>
      'आप कौन सा माल भेज रहे हैं? (जैसे: कोयला, स्टील)';

  @override
  String botPostLoadSummary(String material, String origin, String dest) {
    return 'क्या $material को $origin से $dest भेजने के लिए लोड पोस्ट करें?';
  }

  @override
  String get supplierDashboardTitle => 'सप्लायर डैशबोर्ड';

  @override
  String get supplierDashboardTts => 'सप्लायर डैशबोर्ड';

  @override
  String get supplierDashboardTtsContext =>
      'सप्लायर डैशबोर्ड। अपने सक्रिय लोड, पेंडिंग बुकिंग्स और कुल प्रगति की समीक्षा करें।';

  @override
  String get supplierDashboardPendingBookingsLabel => 'पेंडिंग बुकिंग्स';

  @override
  String get supplierDashboardNeedsActionTitle => 'आपकी कार्रवाई आवश्यक है';

  @override
  String get supplierDashboardRecentLoadsTitle => 'हाल के लोड अपडेट';

  @override
  String get supplierDashboardNoRecentLoads =>
      'अभी कोई हाल का लोड अपडेट नहीं है।';

  @override
  String get truckerDashboardTitle => 'ट्रकर डैशबोर्ड';

  @override
  String get truckerDashboardTts => 'ट्रकर डैशबोर्ड';

  @override
  String get truckerDashboardTtsContext =>
      'ट्रकर डैशबोर्ड। अपनी सक्रिय बोलियों, आगामी ट्रिप्स और कुल प्रगति को ट्रैक करें।';

  @override
  String get findLoadsOriginCity => 'Origin City';

  @override
  String get findLoadsSortByLabel => 'क्रमबद्ध करें';

  @override
  String get findLoadsSortNewest => 'नवीनतम';

  @override
  String get findLoadsSortPriceHighLow => 'कीमत: अधिक से कम';

  @override
  String get findLoadsSortPriceLowHigh => 'कीमत: कम से अधिक';

  @override
  String get findLoadsSortPickupDate => 'पिकअप तारीख';

  @override
  String get findLoadsMaterialLabel => 'माल';

  @override
  String get findLoadsTruckLabel => 'ट्रक';

  @override
  String findLoadsActiveFiltersSummary(int count) {
    return '$count फ़िल्टर सक्रिय';
  }

  @override
  String get findLoadsMaterialCoal => 'कोयला';

  @override
  String get findLoadsMaterialSteel => 'स्टील';

  @override
  String get findLoadsMaterialCement => 'सीमेंट';

  @override
  String get findLoadsMaterialSand => 'रेत';

  @override
  String get findLoadsViewListLabel => 'सूची';

  @override
  String get findLoadsViewMapLabel => 'मैप';

  @override
  String get findLoadsSaveSearchAction => 'खोज सेव करें';

  @override
  String get findLoadsSavedSearchesLabel => 'सेव की गई खोजें';

  @override
  String get findLoadsSavedSearchSaved => 'खोज सेव हो गई।';

  @override
  String get findLoadsSavedSearchSaveFailed => 'खोज सेव नहीं हो सकी।';

  @override
  String get findLoadsSavedSearchDeleted => 'सेव की गई खोज हटा दी गई।';

  @override
  String get findLoadsSavedSearchDeleteFailed =>
      'सेव की गई खोज हटाई नहीं जा सकी।';

  @override
  String get myFleetTitle => 'मेरा फ्लीट';

  @override
  String get myFleetAddTruckTooltip => 'ट्रक जोड़ें';

  @override
  String get myFleetDashboardTts => 'फ्लीट डैशबोर्ड';

  @override
  String get myFleetScreenTtsContext =>
      'फ्लीट डैशबोर्ड। ट्रक, अनुपालन विवरण और वर्तमान उपलब्धता प्रबंधित करें।';

  @override
  String myFleetScreenTtsContextCount(int count) {
    return 'आपका फ्लीट। $count ट्रक।';
  }

  @override
  String get myFleetEmptyTitle => 'अभी तक कोई ट्रक नहीं';

  @override
  String get myFleetEmptySubtitle => '+ दबाकर अपना पहला ट्रक जोड़ें।';

  @override
  String get myFleetLoadError => 'फ्लीट लोड नहीं हो सका';

  @override
  String get myFleetHeroTitle => 'अपने फ्लीट को हमेशा सत्यापन-तैयार रखें';

  @override
  String get myFleetHeroSubtitle =>
      'लोड बुक करने से पहले स्टेटस, रिजेक्शन कारण और ट्रक विवरण जांचें।';

  @override
  String myFleetBodyLabel(Object body) {
    return 'बॉडी: $body';
  }

  @override
  String myFleetTyresLabel(Object tyres) {
    return 'टायर: $tyres';
  }

  @override
  String myFleetCapacityLabel(Object capacity) {
    return 'क्षमता: $capacity टन';
  }

  @override
  String myFleetRejectionReasonLabel(Object reason) {
    return 'अस्वीकृति कारण: $reason';
  }

  @override
  String get myFleetRcExpiredWarning =>
      'RC की समय-सीमा समाप्त हो चुकी है। डिस्पैच समस्या से बचने के लिए दस्तावेज़ नवीनीकृत करें।';

  @override
  String myFleetRcExpiryWarningDays(int days) {
    return 'RC $days दिन में समाप्त होगी। कृपया जल्द नवीनीकरण करें।';
  }

  @override
  String get addTruckTitle => 'ट्रक जोड़ें';

  @override
  String get addTruckHeroTitle => 'अपने ट्रक का विवरण जोड़ें';

  @override
  String get addTruckHeroSubtitle =>
      'फ्लीट जानकारी पूरी रखें ताकि बुकिंग भरोसा बढ़े।';

  @override
  String get addTruckIdentitySection => 'ट्रक पहचान';

  @override
  String get addTruckNumberLabel => 'ट्रक नंबर';

  @override
  String get addTruckNumberRequired => 'ट्रक नंबर जरूरी है';

  @override
  String get addTruckBodyTypeLabel => 'बॉडी प्रकार';

  @override
  String get addTruckModelManualEntryOption => 'सूची में नहीं / मैनुअल एंट्री';

  @override
  String get addTruckModelOptionalLabel => 'ट्रक मॉडल (वैकल्पिक)';

  @override
  String get addTruckCatalogLoadError =>
      'ट्रक कैटलॉग लोड नहीं हुआ। फिर प्रयास करें।';

  @override
  String get addTruckSpecificationsSection => 'स्पेसिफिकेशन';

  @override
  String get addTruckTyresLabel => 'टायर';

  @override
  String get addTruckTyresRangeError => '4 से 22 के बीच टायर दर्ज करें';

  @override
  String get addTruckCapacityLabel => 'क्षमता (टन)';

  @override
  String get addTruckCapacityInvalid => 'सही क्षमता दर्ज करें';

  @override
  String get addTruckDocumentsSection => 'दस्तावेज़';

  @override
  String get addTruckUploadRcPhoto => 'RC फोटो अपलोड करें';

  @override
  String get addTruckRcExpiryDateLabel => 'RC समाप्ति तिथि';

  @override
  String get addTruckSelectDateAction => 'तारीख चुनें';

  @override
  String get addTruckRcUploadedReplace =>
      'RC अपलोड हो गई। बदलने के लिए टैप करें।';

  @override
  String get addTruckRcRequired =>
      'ट्रक विवरण पूरा रखने के लिए RC फोटो अनिवार्य है।';

  @override
  String get addTruckSaveAction => 'ट्रक सेव करें';

  @override
  String get addTruckSelectBodyTypeError => 'कृपया बॉडी प्रकार चुनें';

  @override
  String get addTruckSaveFailed => 'ट्रक जोड़ना विफल रहा। फिर प्रयास करें।';

  @override
  String get loadDetailLoadError => 'विवरण लोड नहीं हो सका';

  @override
  String get loadDetailTripCostUnavailable => 'ट्रिप लागत उपलब्ध नहीं';

  @override
  String get loadDetailTripCostBreakdown => 'ट्रिप लागत विवरण';

  @override
  String get loadDetailTripCostDiesel => 'डीज़ल';

  @override
  String get loadDetailTripCostTolls => 'टोल';

  @override
  String get loadDetailTripCostTotal => 'कुल';

  @override
  String get loadDetailTripCostMileage => 'माइलेज';

  @override
  String get loadDetailPendingApproval => 'अनुमोदन लंबित';

  @override
  String get loadDetailBookingApproved => 'बुकिंग स्वीकृत';

  @override
  String get loadDetailApproveFailed => 'स्वीकृति विफल';

  @override
  String get loadDetailBookingRejected => 'बुकिंग अस्वीकृत';

  @override
  String get loadDetailRejectFailed => 'अस्वीकृति विफल';

  @override
  String get loadDetailNoPendingBookings => 'कोई लंबित बुकिंग नहीं।';

  @override
  String get loadDetailInTransit => 'ट्रांजिट में';

  @override
  String get loadDetailTripInTransit => 'ट्रिप ट्रांजिट में है';

  @override
  String get loadDetailPodUploaded => 'POD अपलोड';

  @override
  String get loadDetailConfirmDelivery => 'डिलीवरी की पुष्टि करें';

  @override
  String get loadDetailDeliveryConfirmed => 'डिलीवरी पुष्टि हो गई।';

  @override
  String get loadDetailDeliveryConfirmFailed => 'डिलीवरी पुष्टि नहीं हो पाई।';

  @override
  String get loadDetailDelivered => 'डिलीवर';

  @override
  String get loadDetailTruckLabel => 'ट्रक';

  @override
  String get loadDetailApproveAction => 'स्वीकृत करें';

  @override
  String get loadDetailRejectAction => 'अस्वीकार करें';

  @override
  String get loadDetailStatusPrefix => 'स्थिति';

  @override
  String richLoadCardTripCostEstimate(Object amount) {
    return 'अनुमानित ट्रिप लागत: $amount';
  }

  @override
  String get richLoadCardSuperLoadLabel => 'सुपर लोड';

  @override
  String get richLoadCardVerifiedSupplierFallback => 'सत्यापित सप्लायर';

  @override
  String get richLoadCardPickupPrefix => 'पिकअप';

  @override
  String richLoadCardTrucksNeededSummary(int needed, int booked) {
    return '$needed ट्रक चाहिए · $booked बुक हो चुके';
  }

  @override
  String get richLoadCardAdvanceUnavailable => 'अग्रिम: -';

  @override
  String richLoadCardAdvanceLabel(int percentage, Object amount) {
    return 'अग्रिम: $percentage% ($amount)';
  }

  @override
  String get richLoadCardJustNow => 'अभी';

  @override
  String get profileScreenTts => 'प्रोफ़ाइल स्क्रीन';

  @override
  String get profileNotFound => 'कोई प्रोफ़ाइल नहीं मिली।';

  @override
  String get profileDefaultUserName => 'TranZfort यूज़र';

  @override
  String get profileVerifiedChip => 'सत्यापित';

  @override
  String profileVerificationChip(Object status) {
    return 'सत्यापन $status';
  }

  @override
  String get profileSummaryTitle => 'प्रोफ़ाइल सारांश';

  @override
  String get profileRoleLabel => 'भूमिका';

  @override
  String get profileStatusLabel => 'स्थिति';

  @override
  String get profileMobileLabel => 'मोबाइल';

  @override
  String get profileValueNa => 'NA';

  @override
  String get profileValueSet => 'सेट';

  @override
  String get profileIdentityDetailsTitle => 'पहचान विवरण';

  @override
  String get profileFullNameLabel => 'पूरा नाम';

  @override
  String get profileVerificationLabel => 'सत्यापन';

  @override
  String get profileQuickActionsTitle => 'त्वरित कार्रवाइयाँ';

  @override
  String get profileDocumentExpiryTitle => 'दस्तावेज़ समाप्ति अलर्ट';

  @override
  String get profileDlExpiredWarning =>
      'ड्राइविंग लाइसेंस की समय-सीमा समाप्त हो चुकी है। कृपया सत्यापन दस्तावेज़ अपडेट करें।';

  @override
  String profileDlExpiryWarningDays(int days) {
    return 'ड्राइविंग लाइसेंस $days दिन में समाप्त होगा। कृपया नवीनीकरण करके पुनः अपलोड करें।';
  }

  @override
  String get profileSupplierVerificationAction => 'सप्लायर सत्यापन';

  @override
  String get profileTruckerVerificationAction => 'ट्रकर सत्यापन';

  @override
  String get profileVerificationActionSubtitle =>
      'अपने सत्यापन दस्तावेज़ देखें और प्रबंधित करें।';

  @override
  String get profileSettingsActionSubtitle =>
      'ऐप प्राथमिकताएँ और अकाउंट नियंत्रण खोलें।';

  @override
  String get profileLoadError => 'प्रोफ़ाइल लोड नहीं हो सकी।';

  @override
  String get notificationsMarkAllAsRead => 'सभी को पढ़ा हुआ मार्क करें';

  @override
  String get notificationsScreenTts => 'नोटिफिकेशन स्क्रीन';

  @override
  String notificationsScreenTtsCount(int count) {
    return '$count नए नोटिफिकेशन।';
  }

  @override
  String get notificationsAllCaughtUpTitle => 'सब अपडेट है!';

  @override
  String get notificationsAllCaughtUpSubtitle =>
      'आपके पास कोई नया नोटिफिकेशन नहीं है।';

  @override
  String notificationsUnreadUpdates(int count) {
    return '$count अपठित अपडेट';
  }

  @override
  String get notificationsCaughtUpBanner => 'आप पूरी तरह अपडेट हैं';

  @override
  String get notificationsRealtimeHint =>
      'ट्रिप, लोड और चैट अलर्ट यहाँ रियल-टाइम में दिखते हैं।';

  @override
  String get notificationsLoadError => 'नोटिफिकेशन लोड नहीं हो सके';

  @override
  String notificationsTimeDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String notificationsTimeHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String notificationsTimeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String get notificationsTimeJustNow => 'अभी';

  @override
  String get routePreviewOpenMapsFailed => 'Google Maps नहीं खुल पाया';

  @override
  String get routePreviewTitle => 'रूट प्रीव्यू';

  @override
  String get routePreviewDetailsUnavailable => 'रूट विवरण उपलब्ध नहीं है।';

  @override
  String get routePreviewFallbackWarning =>
      'सीधी लाइन दिखाई जा रही है। वास्तविक रूट गणना विफल रही।';

  @override
  String get routePreviewStartNavigation =>
      'Google Maps में नेविगेशन शुरू करें';

  @override
  String get routePreviewLoadError => 'रूट लोड करने में त्रुटि हुई।';

  @override
  String routePreviewScreenTtsContext(Object origin, Object destination) {
    return 'रूट $origin से $destination तक।';
  }

  @override
  String get postLoadStepTtsRoute => 'चरण 1: पिकअप और डिलीवरी शहर दर्ज करें।';

  @override
  String get postLoadStepTtsCargo => 'चरण 2: माल चुनें और वजन दर्ज करें।';

  @override
  String get postLoadStepTtsSchedule =>
      'चरण 3: ट्रक प्रकार और टायर आकार चुनें।';

  @override
  String get postLoadStepTtsPricing =>
      'चरण 4: अपनी कीमत, अग्रिम और पिकअप तारीख सेट करें।';

  @override
  String get postLoadTtsSuccess => 'लोड सफलतापूर्वक पोस्ट हो गई।';

  @override
  String get postLoadTtsFailure =>
      'लोड पोस्ट नहीं हो सकी। कृपया फिर प्रयास करें।';

  @override
  String loadDetailScreenTtsContext(
    Object origin,
    Object destination,
    Object material,
    Object weight,
    Object price,
  ) {
    return 'लोड $origin से $destination तक। $material, $weight टन। कीमत: $price रुपये।';
  }

  @override
  String tripDetailScreenTtsContext(
    Object origin,
    Object destination,
    Object stage,
    Object nextAction,
  ) {
    return 'ट्रिप $origin से $destination तक। चरण: $stage। अगला: $nextAction।';
  }

  @override
  String get verificationCompanyDetailsSection => 'कंपनी विवरण';

  @override
  String get verificationProfilePhotoLabel => 'प्रोफ़ाइल फोटो अपलोड करें';

  @override
  String get verificationCompanyNameLabel => 'कंपनी का नाम';

  @override
  String get verificationGstNumberLabel => 'GST नंबर';

  @override
  String get verificationUploadGstCertificate => 'GST प्रमाणपत्र अपलोड करें';

  @override
  String get verificationTaxDetailsSection => 'कर विवरण';

  @override
  String get verificationIdentityDetailsSection => 'पहचान विवरण';

  @override
  String get verificationPanNumberLabel => 'PAN नंबर';

  @override
  String get verificationUploadPanCard => 'PAN कार्ड अपलोड करें';

  @override
  String get verificationTanNumberLabel => 'TAN नंबर';

  @override
  String get verificationTanHelper => 'TAN प्रारूप: 10 अक्षर अल्फ़ान्यूमेरिक';

  @override
  String get verificationTanInvalid => 'मान्य TAN दर्ज करें (10 अक्षर)';

  @override
  String get verificationGstInvalid => 'मान्य GST नंबर दर्ज करें (15 अक्षर)';

  @override
  String get verificationUploadTanCard => 'TAN कार्ड अपलोड करें';

  @override
  String get verificationAadhaarNumberLabel => 'आधार नंबर';

  @override
  String get verificationUploadAadhaarFront => 'आधार फ्रंट अपलोड करें';

  @override
  String get verificationUploadAadhaarBack => 'आधार बैक अपलोड करें';

  @override
  String get verificationOptionalBusinessProofSection =>
      'वैकल्पिक व्यवसाय प्रमाण';

  @override
  String get verificationBusinessLicenceNumberLabel => 'व्यवसाय लाइसेंस नंबर';

  @override
  String get verificationUploadBusinessLicence => 'व्यवसाय लाइसेंस अपलोड करें';

  @override
  String get verificationDrivingLicenseSection => 'ड्राइविंग लाइसेंस विवरण';

  @override
  String get verificationDlNumberLabel => 'DL नंबर';

  @override
  String get verificationDlExpiryDateLabel => 'DL समाप्ति तिथि';

  @override
  String get verificationSelectDateAction => 'तारीख चुनें';

  @override
  String get verificationUploadDlFront => 'DL फ्रंट अपलोड करें';

  @override
  String get verificationUploadDlBack => 'DL बैक अपलोड करें';

  @override
  String get verificationSupplierTtsProfilePhoto =>
      'अपनी सप्लायर प्रोफ़ाइल फोटो अपलोड करें।';

  @override
  String get verificationSupplierTtsCompanyName =>
      'अपनी पंजीकृत कंपनी का नाम दर्ज करें।';

  @override
  String get verificationSupplierTtsGstNumber => 'अपना जीएसटी नंबर दर्ज करें।';

  @override
  String get verificationSupplierTtsTanNumber => 'अपना TAN नंबर दर्ज करें।';

  @override
  String get verificationSupplierTtsGstCertificate =>
      'अपना जीएसटी प्रमाणपत्र अपलोड करें।';

  @override
  String get verificationSupplierTtsTanCard =>
      'अपने TAN कार्ड की फोटो अपलोड करें।';

  @override
  String get verificationSupplierTtsPanNumber =>
      'अपना PAN नंबर A B C D E 1 2 3 4 F प्रारूप में दर्ज करें।';

  @override
  String get verificationSupplierTtsPanCard => 'अपना पैन कार्ड अपलोड करें।';

  @override
  String get verificationSupplierTtsAadhaarNumber =>
      'अपना 12 अंकों का आधार नंबर दर्ज करें।';

  @override
  String get verificationSupplierTtsAadhaarFront =>
      'आधार कार्ड का फ्रंट साइड अपलोड करें।';

  @override
  String get verificationSupplierTtsAadhaarBack =>
      'आधार कार्ड का बैक साइड अपलोड करें।';

  @override
  String get verificationSupplierTtsBusinessLicenceNumber =>
      'यदि उपलब्ध हो तो व्यवसाय लाइसेंस नंबर दर्ज करें।';

  @override
  String get verificationSupplierTtsBusinessLicenceDoc =>
      'यदि उपलब्ध हो तो व्यवसाय लाइसेंस दस्तावेज़ अपलोड करें।';

  @override
  String get verificationTruckerTtsProfilePhoto =>
      'अपनी ट्रकर प्रोफ़ाइल फोटो अपलोड करें।';

  @override
  String get verificationTruckerTtsAadhaarNumber =>
      'अपना 12 अंकों का आधार नंबर दर्ज करें।';

  @override
  String get verificationTruckerTtsAadhaarFront =>
      'आधार कार्ड का फ्रंट साइड अपलोड करें।';

  @override
  String get verificationTruckerTtsAadhaarBack =>
      'आधार कार्ड का बैक साइड अपलोड करें।';

  @override
  String get verificationTruckerTtsPanNumber =>
      'अपना पैन नंबर दर्ज करें, प्रारूप ए बी सी डी ई 1 2 3 4 एफ।';

  @override
  String get verificationTruckerTtsPanCard => 'अपना पैन कार्ड अपलोड करें।';

  @override
  String get verificationTruckerTtsDlNumber =>
      'अपना ड्राइविंग लाइसेंस नंबर जैसा छपा है वैसा ही दर्ज करें।';

  @override
  String get verificationTruckerTtsDlFront =>
      'ड्राइविंग लाइसेंस का फ्रंट साइड अपलोड करें।';

  @override
  String get verificationTruckerTtsDlBack =>
      'ड्राइविंग लाइसेंस का बैक साइड अपलोड करें।';
}
