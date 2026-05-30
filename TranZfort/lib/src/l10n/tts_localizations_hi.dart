// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'tts_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class TtsLocalizationsHi extends TtsLocalizations {
  TtsLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get ttsListenToLoadHint => 'लोड की जानकारी सुनें';

  @override
  String ttsLoadCardRoute(Object origin, Object destination) {
    return '$origin से $destination के लिए लोड।';
  }

  @override
  String ttsLoadCardMaterial(Object material) {
    return 'माल $material है।';
  }

  @override
  String ttsLoadCardTruckTyres(Object minTyres, Object maxTyres) {
    return 'ट्रक $minTyres से $maxTyres चक्के का चाहिए।';
  }

  @override
  String ttsLoadCardTruckCapacityTonnes(Object minTonnes, Object maxTonnes) {
    return 'वजन क्षमता $minTonnes से $maxTonnes टन।';
  }

  @override
  String ttsLoadCardBodyType(Object bodyType) {
    return 'बॉडी का प्रकार $bodyType है।';
  }

  @override
  String ttsLoadCardRatePerTon(Object amount) {
    return 'भाड़ा $amount रुपये प्रति टन है।';
  }

  @override
  String ttsLoadCardRateFixed(Object amount) {
    return 'पूरी गाड़ी का भाड़ा $amount रुपये फिक्स है।';
  }

  @override
  String get ttsLoadCardPickupToday => 'पिकअप आज का है।';

  @override
  String get ttsLoadCardPickupTomorrow => 'पिकअप कल का है।';

  @override
  String ttsLoadCardPickupOnDate(Object dateLabel) {
    return 'पिकअप $dateLabel को है।';
  }

  @override
  String ttsLoadCardAdvance(Object percent) {
    return 'एडवांस $percent परसेंट मिलेगा।';
  }

  @override
  String ttsSupplierLoadListSummary(
    Object origin,
    Object destination,
    Object material,
    Object weightTonnes,
    Object amount,
    Object status,
  ) {
    return '$origin से $destination का लोड। माल $material है। $weightTonnes टन वजन। भाड़ा $amount रुपये। स्टेटस $status है।';
  }

  @override
  String ttsTripCardSummary(
    Object route,
    Object material,
    Object stage,
    Object truckNumber,
  ) {
    return 'ट्रिप $route। माल $material। स्टेज $stage है। गाड़ी नंबर $truckNumber है।';
  }

  @override
  String get ttsBookingRejected => 'बुकिंग रिजेक्ट हो गई है। दूसरा लोड खोजें।';

  @override
  String get ttsBookingApproved =>
      'बुकिंग मंजूर हो गई है। पिकअप के लिए निकलें।';

  @override
  String get ttsLoadDetailTruckRequirementsTitle => 'ट्रक की ज़रूरत।';

  @override
  String ttsLoadDetailPerTruckWeight(Object tonnes) {
    return 'हर ट्रक पर $tonnes टन।';
  }

  @override
  String ttsLoadDetailStatus(Object status) {
    return 'स्टेटस $status है।';
  }

  @override
  String ttsLoadDetailMaterialWeight(Object material, Object tonnes) {
    return 'माल $material, कुल $tonnes टन है।';
  }

  @override
  String ttsLoadDetailTrucksBooked(Object booked, Object needed) {
    return '$booked में से $needed ट्रक बुक हो गए हैं।';
  }

  @override
  String get ttsLoadDetailChatOrBookHint =>
      'सप्लायर से बातचीत करें या लोड बुक करें।';

  @override
  String ttsLoadDetailTripEstimate(Object amount) {
    return 'इस ट्रिप पर आपका मुनाफा लगभग $amount रुपये है।';
  }

  @override
  String ttsTripDetailRouteStage(Object route, Object stage) {
    return 'ट्रिप $route। स्टेज $stage है।';
  }

  @override
  String ttsTripDetailTruck(Object truckNumber) {
    return 'गाड़ी नंबर $truckNumber है।';
  }

  @override
  String ttsTripDetailProofStatus(Object status) {
    return 'प्रूफ स्टेटस $status है।';
  }

  @override
  String get ttsTripDetailNextStepTitle => 'अगला स्टेप।';

  @override
  String ttsFindLoadsIntro(Object count) {
    return '$count लोड मिले हैं।';
  }

  @override
  String ttsFindLoadsFilteredIntro(Object count) {
    return 'आपके फिल्टर के हिसाब से $count लोड मिले हैं।';
  }

  @override
  String get ttsOnboardingChooseRole =>
      'अपना काम चुनें। अगर आप ट्रक चलाते हैं और भाड़ा खोजना चाहते हैं, तो भाड़ा खोजें चुनें। अगर आपको माल भेजना है और ट्रक चाहिए, तो भाड़ा पोस्ट करें चुनें।';

  @override
  String get ttsOnboardingFindLoadsCard =>
      'अगर आप ट्रक चलाते हैं और भाड़ा खोजना चाहते हैं, तो भाड़ा खोजें चुनें। यहाँ से आपको लोड मिलेंगे।';

  @override
  String get ttsOnboardingPostLoadCard =>
      'अगर आपको माल भेजना है और ट्रक चाहिए, तो भाड़ा पोस्ट करें चुनें। यहाँ से आप अपना लोड डाल सकते हैं।';

  @override
  String get ttsOnboardingCompleteProfile =>
      'अपनी प्रोफाइल पूरी करें। अपना नाम, मोबाइल नंबर और शहर भरकर आगे बढ़ें।';

  @override
  String get ttsOnboardingProfileFullName =>
      'यहाँ अपना पूरा नाम लिखें, जैसा आपके कागज़ात या डॉक्यूमेंट्स में लिखा है।';

  @override
  String get ttsOnboardingProfileMobile =>
      'यहाँ अपना मोबाइल नंबर लिखें। इसी नंबर पर आपको कॉल और मैसेज आएंगे।';

  @override
  String get ttsOnboardingProfileLocation =>
      'अपना शहर या गाँव चुनें। अपनी सही लोकेशन डालने के लिए लोकेशन बटन दबाएं या खुद नाम लिखकर खोजें।';

  @override
  String get ttsAuthWelcomeShort =>
      'ट्रैंज़फ़ोर्ट में आपका स्वागत है। आगे बढ़ने के लिए साइन इन करें।';

  @override
  String get ttsVerificationStepPhoto =>
      'पहला कदम। अपनी साफ फोटो खींचकर या गैलरी से अपलोड करें।';

  @override
  String get ttsVerificationStepIdentity =>
      'दूसरा कदम। अपना आधार कार्ड और पैन कार्ड नंबर डालें और उनकी फोटो अपलोड करें।';

  @override
  String get ttsVerificationStepTruck =>
      'तीसरा कदम। गाड़ी नंबर, वजन उठाने की क्षमता और आर सी की फोटो अपलोड करें।';

  @override
  String get ttsVerificationStepBusiness =>
      'तीसरा कदम। कंपनी का नाम, लाइसेंस डिटेल्स और अपनी दुकान या ऑफिस की लोकेशन डालें।';

  @override
  String get ttsVerificationStepReview =>
      'आखिरी कदम। भेजने से पहले सभी डिटेल्स एक बार अच्छी तरह जांच लें।';

  @override
  String get ttsFieldUploadAadhaarFrontPrompt =>
      'आधार कार्ड के आगे के हिस्से की साफ फोटो खींचकर यहाँ अपलोड करें। नाम और नंबर साफ दिखने चाहिए।';

  @override
  String get ttsFieldUploadAadhaarBackPrompt =>
      'आधार कार्ड के पीछे के हिस्से की साफ फोटो खींचकर यहाँ अपलोड करें।';

  @override
  String get ttsFieldUploadPanPrompt =>
      'पैन कार्ड की साफ फोटो अपलोड करें। चारों कोने और आपका फोटो साफ दिखना चाहिए।';

  @override
  String get ttsFieldUploadRcPrompt =>
      'गाड़ी की आर सी बुक यानी रजिस्ट्रेशन सर्टिफिकेट की साफ फोटो खींचकर अपलोड करें।';

  @override
  String get ttsFieldUploadProfilePhotoPrompt =>
      'अपनी साफ चेहरे की फोटो खींचकर अपलोड करें। ध्यान रखें कि चेहरा साफ दिखे।';

  @override
  String get ttsFieldAadhaarInputDescription =>
      'यहाँ अपना बारह अंकों का आधार नंबर लिखें।';

  @override
  String get ttsFieldPanInputDescription => 'यहाँ अपना पैन कार्ड नंबर लिखें।';

  @override
  String get ttsFieldTruckNumberInputDescription =>
      'यहाँ अपनी गाड़ी का नंबर लिखें, जैसा आपके आर सी में लिखा है।';

  @override
  String get ttsFieldTruckBodyTypeDescription =>
      'अपनी गाड़ी का बॉडी टाइप चुनें, जैसे खुला, बंद, या कंटेनर।';

  @override
  String get ttsFieldTruckTyresDescription =>
      'अपनी गाड़ी में कितने चक्के हैं, वो चुनें। इससे सही लोड मिलने में मदद मिलती है।';

  @override
  String get ttsFieldTruckCapacityInputDescription =>
      'अपनी गाड़ी कितने टन वजन उठा सकती है, वो यहाँ लिखें।';

  @override
  String get ttsFieldUploadTruckPhotoPrompt =>
      'अगर चाहें तो अपनी गाड़ी की साइड से साफ फोटो भी अपलोड कर सकते हैं। यह ज़रूरी नहीं है।';

  @override
  String ttsShellTruckerDashboardIntro(
    Object approvedTrucks,
    Object inTransitTrips,
  ) {
    return 'डैशबोर्ड। आपके $approvedTrucks वेरिफाइड ट्रक हैं और $inTransitTrips ट्रिप रास्ते में हैं।';
  }

  @override
  String ttsShellSupplierDashboardIntro(
    Object activeLoads,
    Object pendingBookings,
  ) {
    return 'सप्लायर डैशबोर्ड। आपके $activeLoads लोड चालू हैं और $pendingBookings बुकिंग रिक्वेस्ट बाकी हैं।';
  }

  @override
  String ttsShellMessagesIntro(Object unreadCount) {
    return 'मैसेज स्क्रीन। आपके $unreadCount नए मैसेज हैं।';
  }

  @override
  String ttsShellTripsIntro(Object upcomingTrips, Object inTransitTrips) {
    return 'आपकी ट्रिप्स। $upcomingTrips आने वाली और $inTransitTrips रास्ते में हैं।';
  }

  @override
  String get ttsNotificationRowHint => 'नोटिफिकेशन सुनें';
}
