import '../../../l10n/tts_localizations.dart';
import '../../supplier/data/supplier_trip_repository.dart';
import '../../supplier/data/supplier_trip_repository_models.dart';
import '../../trucker/data/trucker_trip_repository_models.dart';
import 'tts_utterance_utils.dart';

class TripDetailTtsBuilder {
  const TripDetailTtsBuilder();

  String buildTruckerOverview({
    required TruckerTripDetail detail,
    required TtsLocalizations tts,
    required String stageLabel,
    required String proofLabel,
  }) {
    return joinTtsClauses([
      tts.ttsTripDetailRouteStage(detail.routeLabel.trim(), stageLabel.trim()),
      tts.ttsLoadCardMaterial(detail.material.trim()),
      tts.ttsTripDetailTruck(detail.truckNumber.trim()),
      tts.ttsTripDetailProofStatus(proofLabel.trim()),
    ]);
  }

  String buildTruckerNextStep({
    required TtsLocalizations tts,
    required String stepTitle,
    required String stepDetail,
  }) {
    return joinTtsClauses([
      tts.ttsTripDetailNextStepTitle,
      '$stepTitle. $stepDetail',
    ]);
  }

  String buildSupplierOverview({
    required SupplierTrip trip,
    required TtsLocalizations tts,
    required String stageLabel,
    required String proofLabel,
    String truckNumber = '',
  }) {
    final truck = truckNumber.trim().isEmpty ? '-' : truckNumber.trim();
    return joinTtsClauses([
      tts.ttsTripDetailRouteStage(trip.routeLabel.trim(), stageLabel.trim()),
      tts.ttsLoadCardMaterial(trip.material.trim()),
      tts.ttsTripDetailTruck(truck),
      tts.ttsTripDetailProofStatus(proofLabel.trim()),
    ]);
  }

  String buildSupplierDetailOverview({
    required SupplierTripDetail detail,
    required TtsLocalizations tts,
    required String stageLabel,
    required String proofLabel,
  }) {
    return joinTtsClauses([
      tts.ttsTripDetailRouteStage(detail.routeLabel.trim(), stageLabel.trim()),
      tts.ttsLoadCardMaterial(detail.material.trim()),
      tts.ttsTripDetailTruck(detail.truckNumber.trim().isEmpty ? '-' : detail.truckNumber.trim()),
      tts.ttsTripDetailProofStatus(proofLabel.trim()),
    ]);
  }
}
