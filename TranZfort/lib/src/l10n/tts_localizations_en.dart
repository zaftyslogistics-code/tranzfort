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
      'Choose your role. Are you a trucker or a supplier?';

  @override
  String get ttsOnboardingCompleteProfile =>
      'Complete your profile. Enter your details to continue.';

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
  String get ttsNotificationRowHint => 'Listen to notification';
}
