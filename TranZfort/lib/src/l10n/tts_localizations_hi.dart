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
}
