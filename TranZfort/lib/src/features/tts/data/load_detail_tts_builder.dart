import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../../supplier/data/supplier_load_models.dart';
import '../../trucker/data/trucker_load_detail_repository.dart';
import 'load_marketplace_card_tts_builder.dart';
import 'tts_utterance_utils.dart';

class LoadDetailTtsBuilder {
  const LoadDetailTtsBuilder();

  String buildTruckerOverview({
    required TruckerLoadDetail detail,
    required TtsLocalizations tts,
    required AppLocalizations ui,
  }) {
    return const LoadMarketplaceCardTtsBuilder().build(
      load: detail.summary,
      tts: tts,
      ui: ui,
    );
  }

  String buildTruckerTruckRequirements({
    required TruckerLoadDetail detail,
    required TtsLocalizations tts,
    required AppLocalizations ui,
  }) {
    final load = detail.summary;
    final tyres = load.requiredTyres.toList()..sort();
    final minTyres = tyres.isEmpty ? ui.commonAnyLabel : '${tyres.first}';
    final maxTyres = tyres.isEmpty ? ui.commonAnyLabel : '${tyres.last}';
    final minCap = load.derivedMinTruckCapacityTonnes;
    final maxCap = load.derivedMaxTruckCapacityTonnes;
    return joinTtsClauses([
      tts.ttsLoadDetailTruckRequirementsTitle,
      tts.ttsLoadCardMaterial(load.material.trim()),
      tts.ttsLoadDetailPerTruckWeight(_formatTonnes(load.perTruckWeightTonnes)),
      if (minCap != null && maxCap != null)
        tts.ttsLoadCardTruckCapacityTonnes(_formatTonnes(minCap), _formatTonnes(maxCap)),
      tts.ttsLoadCardTruckTyres(minTyres, maxTyres),
      if ((load.requiredBodyType ?? '').trim().isNotEmpty)
        tts.ttsLoadCardBodyType(
          ui.truckerFindLoadsBodyTypeValue(load.requiredBodyType!.trim().toLowerCase()),
        ),
    ]);
  }

  String buildTruckerAll({
    required TruckerLoadDetail detail,
    required TtsLocalizations tts,
    required AppLocalizations ui,
  }) {
    return joinTtsClauses([
      buildTruckerOverview(detail: detail, tts: tts, ui: ui),
      buildTruckerTruckRequirements(detail: detail, tts: tts, ui: ui),
    ]);
  }

  String buildSupplierRouteAndPrice({
    required LoadDetail detail,
    required TtsLocalizations tts,
    required AppLocalizations ui,
    required String statusLabel,
  }) {
    final summary = detail.summary;
    return joinTtsClauses([
      tts.ttsLoadCardRoute(
        _cleanCity(summary.originLabel),
        _cleanCity(summary.destinationLabel),
      ),
      tts.ttsLoadCardMaterial(summary.material.trim()),
      summary.priceType.trim().toLowerCase() == 'per_ton'
          ? tts.ttsLoadCardRatePerTon(_formatAmount(summary.priceAmount))
          : tts.ttsLoadCardRateFixed(_formatAmount(summary.priceAmount)),
      tts.ttsLoadDetailStatus(statusLabel),
    ]);
  }

  String buildSupplierMaterialAndTrucks({
    required LoadDetail detail,
    required TtsLocalizations tts,
  }) {
    final summary = detail.summary;
    return joinTtsClauses([
      tts.ttsLoadDetailMaterialWeight(
        summary.material.trim(),
        _formatTonnes(summary.weightTonnes),
      ),
      tts.ttsLoadDetailTrucksBooked('${summary.trucksBooked}', '${summary.trucksNeeded}'),
    ]);
  }

  String buildSupplierAll({
    required LoadDetail detail,
    required TtsLocalizations tts,
    required AppLocalizations ui,
    required String statusLabel,
  }) {
    return joinTtsClauses([
      buildSupplierRouteAndPrice(detail: detail, tts: tts, ui: ui, statusLabel: statusLabel),
      buildSupplierMaterialAndTrucks(detail: detail, tts: tts),
    ]);
  }

  static String _cleanCity(String label) {
    final parts = label.split(',').first.trim();
    return parts.isEmpty ? label.trim() : parts;
  }

  static String _formatTonnes(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatAmount(double value) => value.toStringAsFixed(0);
}
