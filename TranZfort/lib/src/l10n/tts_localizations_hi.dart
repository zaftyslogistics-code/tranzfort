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
    return '$origin se $destination jaane wali load.';
  }

  @override
  String ttsLoadCardMaterial(Object material) {
    return 'Maal $material.';
  }

  @override
  String ttsLoadCardTruckTyres(Object minTyres, Object maxTyres) {
    return 'Truck $minTyres se $maxTyres chakka chahiye.';
  }

  @override
  String ttsLoadCardTruckCapacityTonnes(Object minTonnes, Object maxTonnes) {
    return 'Truck $minTonnes se $maxTonnes ton capacity.';
  }

  @override
  String ttsLoadCardBodyType(Object bodyType) {
    return 'Body type $bodyType.';
  }

  @override
  String ttsLoadCardRatePerTon(Object amount) {
    return 'Bhada $amount rupaye prati ton.';
  }

  @override
  String ttsLoadCardRateFixed(Object amount) {
    return 'Poori load ka bhada $amount rupaye.';
  }

  @override
  String get ttsLoadCardPickupToday => 'Pickup aaj.';

  @override
  String get ttsLoadCardPickupTomorrow => 'Pickup kal.';

  @override
  String ttsLoadCardPickupOnDate(Object dateLabel) {
    return 'Pickup $dateLabel.';
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
    return '$origin se $destination load. Maal $material. $weightTonnes ton. Bhada $amount rupaye. Status $status.';
  }

  @override
  String ttsTripCardSummary(
    Object route,
    Object material,
    Object stage,
    Object truckNumber,
  ) {
    return 'Trip $route. Maal $material. Stage $stage. Truck $truckNumber.';
  }

  @override
  String get ttsBookingRejected =>
      'Booking reject ho gaya. Doosra load dhundein.';

  @override
  String get ttsBookingApproved =>
      'Booking manjoor ho gaya. Pickup ki taraf chalein.';

  @override
  String get ttsLoadDetailTruckRequirementsTitle => 'Truck ki zaroorat.';

  @override
  String ttsLoadDetailPerTruckWeight(Object tonnes) {
    return 'Har truck par $tonnes ton.';
  }

  @override
  String ttsLoadDetailStatus(Object status) {
    return 'Status $status.';
  }

  @override
  String ttsLoadDetailMaterialWeight(Object material, Object tonnes) {
    return 'Maal $material, kul $tonnes ton.';
  }

  @override
  String ttsLoadDetailTrucksBooked(Object booked, Object needed) {
    return '$booked mein se $needed truck book.';
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
  String get ttsTripDetailNextStepTitle => 'Agla step.';

  @override
  String ttsFindLoadsIntro(Object count) {
    return '$count load uplabdh.';
  }

  @override
  String ttsFindLoadsFilteredIntro(Object count) {
    return 'Filter par $count load mili.';
  }

  @override
  String get ttsOnboardingChooseRole =>
      'Apna role chunein. Aap trucker hain ya supplier?';

  @override
  String get ttsOnboardingCompleteProfile =>
      'Profile poori karein. Aage badhne ke liye details bharein.';

  @override
  String get ttsAuthWelcomeShort =>
      'TranZfort mein aapka swagat hai. Aage badhne ke liye sign in karein.';

  @override
  String get ttsVerificationStepPhoto =>
      'Pehla step. Saaf profile photo upload karein.';

  @override
  String get ttsVerificationStepIdentity =>
      'Doosra step. Aadhaar aur PAN details aur documents upload karein.';

  @override
  String get ttsVerificationStepTruck =>
      'Teesra step. Truck number, capacity aur RC document upload karein.';

  @override
  String get ttsVerificationStepBusiness =>
      'Teesra step. Company aur licence details aur location capture karein.';

  @override
  String get ttsVerificationStepReview =>
      'Review step. Submit se pehle sab details aur terms confirm karein.';

  @override
  String get ttsNotificationRowHint => 'Notification sunein';
}
