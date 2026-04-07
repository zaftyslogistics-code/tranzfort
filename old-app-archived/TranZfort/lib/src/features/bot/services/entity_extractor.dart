import '../models/bot_intent.dart';

class EntityExtractor {
  static const _materials = [
    'coal',
    'steel',
    'cement',
    'iron ore',
    'sand',
    'grain',
    'fertilizer',
    'timber',
  ];

  static BotIntent determineIntent(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('load dhundho') ||
        lower.contains('find load') ||
        lower.contains('load chahiye')) {
      return BotIntent.findLoad;
    }
    if (lower.contains('load dalna hai') ||
        lower.contains('post load') ||
        lower.contains('naya load')) {
      return BotIntent.postLoad;
    }
    if (lower.contains('meri loads') ||
        lower.contains('my loads') ||
        lower.contains('posted loads')) {
      return BotIntent.myLoads;
    }
    if (lower.contains('meri trips') ||
        lower.contains('my trips') ||
        lower.contains('trip status')) {
      return BotIntent.myTrips;
    }
    if (lower.contains('booking ka status') ||
        lower.contains('check status') ||
        lower.contains('kya hua')) {
      return BotIntent.checkStatus;
    }
    if (lower.contains('help') ||
        lower.contains('madad') ||
        lower.contains('kya kar sakte ho')) {
      return BotIntent.help;
    }
    if (lower.contains('namaste') ||
        lower.contains('hello') ||
        lower.contains('hi')) {
      return BotIntent.greeting;
    }

    return BotIntent.unknown;
  }

  static String? extractCity(String text, List<String> cityCatalog) {
    final lower = text.toLowerCase();
    for (final city in cityCatalog) {
      if (lower.contains(city.toLowerCase())) {
        return city;
      }
    }
    return null;
  }

  static String? extractMaterial(String text) {
    final lower = text.toLowerCase();
    for (final mat in _materials) {
      if (lower.contains(mat)) {
        return mat;
      }
    }
    return null;
  }

  static double? extractWeight(String text) {
    final regex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(ton|tonne|t)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  static double? extractPrice(String text) {
    final lakhRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(lakh|l)',
      caseSensitive: false,
    );
    final lakhMatch = lakhRegex.firstMatch(text);
    if (lakhMatch != null) {
      final val = double.tryParse(lakhMatch.group(1) ?? '');
      if (val != null) return val * 100000;
    }

    final kRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(k|thousand|hazar)',
      caseSensitive: false,
    );
    final kMatch = kRegex.firstMatch(text);
    if (kMatch != null) {
      final val = double.tryParse(kMatch.group(1) ?? '');
      if (val != null) return val * 1000;
    }

    final exactRegex = RegExp(
      r'(?:rs|rupees|₹)?\s*(\d{3,})',
      caseSensitive: false,
    );
    final exactMatch = exactRegex.firstMatch(text);
    if (exactMatch != null) {
      return double.tryParse(exactMatch.group(1) ?? '');
    }

    return null;
  }
}
