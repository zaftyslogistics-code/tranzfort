// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'tts_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class TtsLocalizationsEn extends TtsLocalizations {
  TtsLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get ttsListenToLoadHint => 'Listen to load details';

  @override
  String ttsLoadCardRoute(Object origin, Object destination) {
    return 'Load from $origin to $destination.';
  }

  @override
  String ttsLoadCardMaterial(Object material) {
    return 'Material $material.';
  }

  @override
  String ttsLoadCardTruckTyres(Object minTyres, Object maxTyres) {
    return 'Truck from $minTyres to $maxTyres wheels required.';
  }

  @override
  String ttsLoadCardTruckCapacityTonnes(Object minTonnes, Object maxTonnes) {
    return 'Truck capacity from $minTonnes to $maxTonnes tonnes.';
  }

  @override
  String ttsLoadCardBodyType(Object bodyType) {
    return 'Body type $bodyType.';
  }

  @override
  String ttsLoadCardRatePerTon(Object amount) {
    return 'Rate $amount rupees per ton.';
  }

  @override
  String ttsLoadCardRateFixed(Object amount) {
    return 'Fixed rate $amount rupees for the load.';
  }

  @override
  String get ttsLoadCardPickupToday => 'Pickup today.';

  @override
  String get ttsLoadCardPickupTomorrow => 'Pickup tomorrow.';

  @override
  String ttsLoadCardPickupOnDate(Object dateLabel) {
    return 'Pickup on $dateLabel.';
  }

  @override
  String ttsLoadCardAdvance(Object percent) {
    return 'Advance $percent percent.';
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
    return 'Load $origin to $destination. Material $material. $weightTonnes tonnes. Rate $amount rupees. Status $status.';
  }

  @override
  String ttsTripCardSummary(
    Object route,
    Object material,
    Object stage,
    Object truckNumber,
  ) {
    return 'Trip $route. Material $material. Stage $stage. Truck $truckNumber.';
  }

  @override
  String get ttsBookingRejected =>
      'Booking was rejected. Look for another load.';

  @override
  String get ttsBookingApproved => 'Booking approved. Head to pickup.';

  @override
  String get ttsLoadDetailTruckRequirementsTitle => 'Truck requirements.';

  @override
  String ttsLoadDetailPerTruckWeight(Object tonnes) {
    return 'Weight per truck $tonnes tonnes.';
  }

  @override
  String ttsLoadDetailStatus(Object status) {
    return 'Status $status.';
  }

  @override
  String ttsLoadDetailMaterialWeight(Object material, Object tonnes) {
    return 'Material $material, total $tonnes tonnes.';
  }

  @override
  String ttsLoadDetailTrucksBooked(Object booked, Object needed) {
    return '$booked of $needed trucks booked.';
  }

  @override
  String get ttsLoadDetailChatOrBookHint =>
      'Chat with the supplier or book this load.';

  @override
  String ttsLoadDetailTripEstimate(Object amount) {
    return 'Estimated profit on this trip is about $amount rupees.';
  }

  @override
  String ttsTripDetailRouteStage(Object route, Object stage) {
    return 'Trip $route. Stage $stage.';
  }

  @override
  String ttsTripDetailTruck(Object truckNumber) {
    return 'Truck $truckNumber.';
  }

  @override
  String ttsTripDetailProofStatus(Object status) {
    return 'Proof status $status.';
  }

  @override
  String get ttsTripDetailNextStepTitle => 'Next step.';

  @override
  String ttsFindLoadsIntro(Object count) {
    return '$count loads available.';
  }

  @override
  String ttsFindLoadsFilteredIntro(Object count) {
    return '$count loads match your filters.';
  }

  @override
  String get ttsOnboardingChooseRole =>
      'Choose what you do. Do you want to find loads or post a load? Tap Find Loads, bhada khoje, to search for loads to carry. Tap Post a Load, bhada post kare, to list goods that need trucks.';

  @override
  String get ttsOnboardingFindLoadsCard =>
      'If you drive a truck and want to find loads to carry, choose Find Loads, bhada khoje. You will see loads looking for trucks.';

  @override
  String get ttsOnboardingPostLoadCard =>
      'If you have goods to send and need trucks, choose Post a Load, bhada post kare. You can list your load here.';

  @override
  String get ttsOnboardingCompleteProfile =>
      'Complete your profile. Enter your name, mobile number, and location to continue.';

  @override
  String get ttsOnboardingProfileFullName => 'Enter your full name.';

  @override
  String get ttsOnboardingProfileMobile => 'Enter your mobile number.';

  @override
  String get ttsOnboardingProfileLocation =>
      'Add your city location. Use current location or search manually.';

  @override
  String get ttsAuthWelcomeShort =>
      'Welcome to TranZfort. Sign in or create an account to continue.';

  @override
  String get ttsVerificationStepPhoto =>
      'Step one. Upload a clear profile photo.';

  @override
  String get ttsVerificationStepIdentity =>
      'Step two. Enter Aadhaar and PAN details and upload documents.';

  @override
  String get ttsVerificationStepTruck =>
      'Step three. Enter truck number, capacity, and upload the RC document.';

  @override
  String get ttsVerificationStepBusiness =>
      'Step three. Enter company and business licence details and capture location.';

  @override
  String get ttsVerificationStepReview =>
      'Review step. Confirm all details and accept terms before submit.';

  @override
  String get ttsFieldUploadAadhaarFrontPrompt =>
      'Upload a clear photo of the front side of your Aadhaar card. Name and number must be visible.';

  @override
  String get ttsFieldUploadAadhaarBackPrompt =>
      'Upload a clear photo of the back side of your Aadhaar card.';

  @override
  String get ttsFieldUploadPanPrompt =>
      'Upload a clear photo of your PAN card. All four corners and your photo must be visible.';

  @override
  String get ttsFieldUploadRcPrompt =>
      'Upload a clear photo of your vehicle RC book or registration certificate.';

  @override
  String get ttsFieldUploadProfilePhotoPrompt =>
      'Upload a clear photo of your face. Make sure your face is fully visible.';

  @override
  String get ttsFieldAadhaarInputDescription =>
      'Enter your twelve-digit Aadhaar number here.';

  @override
  String get ttsFieldPanInputDescription => 'Enter your PAN card number here.';

  @override
  String get ttsFieldTruckNumberInputDescription =>
      'Enter your vehicle registration number here, as printed on your RC book.';

  @override
  String get ttsFieldTruckBodyTypeDescription =>
      'Choose your truck body type, such as open, closed, or container.';

  @override
  String get ttsFieldTruckTyresDescription =>
      'Select how many tyres your truck has. This helps match suitable loads.';

  @override
  String get ttsFieldTruckCapacityInputDescription =>
      'Enter how many tonnes of weight your truck can carry.';

  @override
  String get ttsFieldUploadTruckPhotoPrompt =>
      'You may upload a clear side photo of your truck. This is optional but helpful.';

  @override
  String ttsShellTruckerDashboardIntro(
    Object approvedTrucks,
    Object inTransitTrips,
  ) {
    return 'Dashboard. You have $approvedTrucks approved trucks and $inTransitTrips trips in transit.';
  }

  @override
  String ttsShellSupplierDashboardIntro(
    Object activeLoads,
    Object pendingBookings,
  ) {
    return 'Supplier dashboard. You have $activeLoads active loads and $pendingBookings pending booking requests.';
  }

  @override
  String ttsShellMessagesIntro(Object unreadCount) {
    return 'Messages. You have $unreadCount new messages.';
  }

  @override
  String ttsShellTripsIntro(Object upcomingTrips, Object inTransitTrips) {
    return 'Your trips. $upcomingTrips upcoming and $inTransitTrips in transit.';
  }

  @override
  String get ttsNotificationRowHint => 'Listen to notification';
}
