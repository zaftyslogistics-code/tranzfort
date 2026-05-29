import '../../../l10n/tts_localizations.dart';

class TripListCardTtsBuilder {
  const TripListCardTtsBuilder();

  String build({
    required TtsLocalizations tts,
    required String routeLabel,
    required String material,
    required String stageLabel,
    required String truckNumber,
  }) {
    return tts.ttsTripCardSummary(
      routeLabel.trim(),
      material.trim(),
      stageLabel.trim(),
      truckNumber.trim().isEmpty ? '-' : truckNumber.trim(),
    );
  }
}
