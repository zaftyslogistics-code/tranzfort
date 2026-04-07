import '../../../core/utils/coordinate_utils.dart';

class LoadPricing {
  static const String fixed = 'fixed';
  static const String perTon = 'per_ton';
  static const String legacyNegotiable = 'negotiable';

  static String normalizePriceType(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase();
    if (value == perTon || value == legacyNegotiable) {
      return perTon;
    }
    return fixed;
  }

  static String serializeForDatabase(dynamic raw) {
    final normalized = normalizePriceType(raw);
    if (normalized == perTon) {
      return legacyNegotiable;
    }
    return fixed;
  }

  static bool isPerTon(dynamic raw) {
    return normalizePriceType(raw) == perTon;
  }

  static double? priceValue(dynamic raw) {
    return CoordinateUtils.parseDouble(raw);
  }

  static double? weightTonnes(dynamic raw) {
    return CoordinateUtils.parseDouble(raw);
  }

  static double? ratePerTonFromMap(Map<String, dynamic> load) {
    final price = priceValue(load['price']);
    if (price == null) {
      return null;
    }
    if (isPerTon(load['price_type'])) {
      return price;
    }

    final weight = weightTonnes(load['weight_tonnes']);
    if (weight == null || weight <= 0) {
      return null;
    }
    return price / weight;
  }

  static double? totalPriceFromMap(Map<String, dynamic> load) {
    final price = priceValue(load['price']);
    if (price == null) {
      return null;
    }
    if (!isPerTon(load['price_type'])) {
      return price;
    }

    final weight = weightTonnes(load['weight_tonnes']);
    if (weight == null || weight <= 0) {
      return null;
    }
    return price * weight;
  }

  static double? advanceAmountFromMap(Map<String, dynamic> load) {
    final percent = (load['advance_percentage'] as num?)?.toDouble();
    final total = totalPriceFromMap(load);
    if (percent == null || total == null) {
      return null;
    }
    return total * (percent / 100);
  }
}
