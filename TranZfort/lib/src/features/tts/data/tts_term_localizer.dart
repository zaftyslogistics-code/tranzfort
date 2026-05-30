import '../../../l10n/app_localizations.dart';

/// Maps English DB/API terms to Hindi spoken labels for TTS (hi-IN).
class TtsTermLocalizer {
  TtsTermLocalizer._();

  static const Map<String, String> _materialHi = {
    'coal': 'कोयला',
    'steel': 'स्टील',
    'cement': 'सीमेंट',
    'grains': 'अनाज',
    'fertilizer': 'खाद',
    'machinery': 'मशीनरी',
    'iron ore': 'लोहे का माल',
    'iron': 'लोहे का माल',
    'bricks': 'ईंट',
    'sand': 'रेत',
    'stone': 'पत्थर',
    'marble': 'संगमरमर',
    'food': 'खाने का सामान',
    'fruits': 'फल',
    'vegetables': 'सब्ज़ी',
    'cotton': 'कपास',
    'textile': 'कपड़ा',
    'plastic': 'प्लास्टिक',
    'chemical': 'केमिकल',
    'other': 'अन्य माल',
  };

  static const Map<String, String> _bodyTypeHi = {
    'open': 'खुला',
    'closed': 'बंद',
    'container': 'कंटेनर',
    'flatbed': 'फ्लैटबेड',
    'trailer': 'ट्रेलर',
    'tanker': 'टैंकर',
    'refrigerated': 'फ्रिज वाला',
  };

  static String material(String raw, {required String languageCode, AppLocalizations? ui}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (languageCode != 'hi') {
      return trimmed;
    }
    final key = trimmed.toLowerCase();
    return _materialHi[key] ?? trimmed;
  }

  static String bodyType(String raw, {required String languageCode, AppLocalizations? ui}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (ui != null) {
      try {
        return ui.truckerFindLoadsBodyTypeValue(trimmed.toLowerCase());
      } catch (_) {
        // Fall through to static map.
      }
    }
    if (languageCode != 'hi') {
      return trimmed;
    }
    return _bodyTypeHi[trimmed.toLowerCase()] ?? trimmed;
  }
}
