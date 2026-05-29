import '../../../l10n/app_localizations.dart';
import '../../../l10n/tts_localizations.dart';
import '../../trucker/data/trucker_marketplace_repository.dart';

/// Builds natural-language utterances for [MarketplaceLoadItem] cards (not UI headlines).
class LoadMarketplaceCardTtsBuilder {
  const LoadMarketplaceCardTtsBuilder();

  String build({
    required MarketplaceLoadItem load,
    required TtsLocalizations tts,
    required AppLocalizations ui,
  }) {
    final parts = <String>[
      tts.ttsLoadCardRoute(_cleanCity(load.originCity), _cleanCity(load.destinationCity)),
      if (load.material.trim().isNotEmpty)
        tts.ttsLoadCardMaterial(load.material.trim()),
      ..._truckClauses(load, tts, ui),
      _rateClause(load, tts),
      _pickupClause(load, tts),
      if (load.advancePercentage > 0)
        tts.ttsLoadCardAdvance('${load.advancePercentage}'),
    ];
    return parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _truckClauses(
    MarketplaceLoadItem load,
    TtsLocalizations tts,
    AppLocalizations ui,
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
          ui.truckerFindLoadsBodyTypeValue(bodyType.toLowerCase()),
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

  String _pickupClause(MarketplaceLoadItem load, TtsLocalizations tts) {
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
    final label = '${load.pickupDate.day}/${load.pickupDate.month}';
    return tts.ttsLoadCardPickupOnDate(label);
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
