import '../../../l10n/tts_localizations.dart';
import '../../supplier/data/supplier_load_models.dart';

class SupplierLoadListCardTtsBuilder {
  const SupplierLoadListCardTtsBuilder();

  String build({
    required Load load,
    required TtsLocalizations tts,
    required String statusLabel,
  }) {
    final tonnes = load.weightTonnes % 1 == 0
        ? load.weightTonnes.toStringAsFixed(0)
        : load.weightTonnes.toStringAsFixed(1);
    return tts.ttsSupplierLoadListSummary(
      load.originLabel.trim(),
      load.destinationLabel.trim(),
      load.material.trim(),
      tonnes,
      load.priceAmount.toStringAsFixed(0),
      statusLabel.trim(),
    );
  }
}
