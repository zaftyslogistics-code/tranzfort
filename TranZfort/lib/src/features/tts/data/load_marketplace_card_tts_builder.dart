import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../../trucker/data/trucker_marketplace_repository.dart';
import 'tts_term_localizer.dart';

/// Builds natural-language utterances for [MarketplaceLoadItem] cards (not UI headlines).
class LoadMarketplaceCardTtsBuilder {
  const LoadMarketplaceCardTtsBuilder();

  String build({
    required MarketplaceLoadItem load,
    required TtsLocalizations tts,
    required AppLocalizations ui,
    String? pickupDateLabel,
    String languageCode = 'en',
  }) {
    final material = TtsTermLocalizer.material(
      load.material.trim(),
      languageCode: languageCode,
      ui: ui,
    );
    final parts = <String>[
      tts.ttsLoadCardRoute(_cleanCity(load.originCity), _cleanCity(load.destinationCity)),
      if (material.isNotEmpty) tts.ttsLoadCardMaterial(material),
      ..._truckClauses(load, tts, ui, languageCode),
      _rateClause(load, tts),
      _pickupClause(load, tts, pickupDateLabel: pickupDateLabel),
      if (load.advancePercentage > 0)
        tts.ttsLoadCardAdvance('${load.advancePercentage}'),
    ];
    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _truckClauses(
    MarketplaceLoadItem load,
    TtsLocalizations tts,
    AppLocalizations ui,
    String languageCode,
  ) {
    final clauses = <String>[];
    final tyres = load.requiredTyres.toList()..sort();
    if (tyres.length >= 2) {
      clauses.add(tts.ttsLoadCardTruckTyres('${tyres.first}', '${tyres.last}'));
    } else if (tyres.length == 1) {
      clauses.add(tts.ttsLoadCardTruckTyres('${tyres.first}', '${tyres.first}'));
    }

    final minCap = load.derivedMinTruckCapacityTonnes;
    final maxCap = load.derivedMaxTruckCapacityTonnes;
    if (minCap != null && maxCap != null) {
      clauses.add(
        tts.ttsLoadCardTruckCapacityTonnes(
          _formatTonnes(minCap),
          _formatTonnes(maxCap),
        ),
      );
    }

    final bodyType = (load.requiredBodyType ?? '').trim();
    if (bodyType.isNotEmpty) {
      clauses.add(
        tts.ttsLoadCardBodyType(
          TtsTermLocalizer.bodyType(bodyType, languageCode: languageCode, ui: ui),
        ),
      );
    }
    return clauses;
  }

  String _rateClause(MarketplaceLoadItem load, TtsLocalizations tts) {
    final amount = _formatAmount(load.priceAmount);
    if (load.priceType.trim().toLowerCase() == 'per_ton') {
      return tts.ttsLoadCardRatePerTon(amount);
    }
    return tts.ttsLoadCardRateFixed(amount);
  }

  String _pickupClause(
    MarketplaceLoadItem load,
    TtsLocalizations tts, {
    String? pickupDateLabel,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickupDay = DateTime(
      load.pickupDate.year,
      load.pickupDate.month,
      load.pickupDate.day,
    );
    final daysUntil = pickupDay.difference(today).inDays;
    if (daysUntil == 0) {
      return tts.ttsLoadCardPickupToday;
    }
    if (daysUntil == 1) {
      return tts.ttsLoadCardPickupTomorrow;
    }
    final label = (pickupDateLabel ?? '').trim();
    if (label.isNotEmpty) {
      return tts.ttsLoadCardPickupOnDate(label);
    }
    return tts.ttsLoadCardPickupOnDate(
      '${load.pickupDate.day}/${load.pickupDate.month}/${load.pickupDate.year}',
    );
  }

  static String _cleanCity(String city) => city.trim();

  static String _formatTonnes(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  static String _formatAmount(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(0);
  }
}
