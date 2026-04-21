import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripCostEstimate {
  final double dieselCost;
  final double tollCost;
  final double driverCost;
  final double miscCost;
  final double totalCost; // alias of totalExpense for backward compat
  final double totalExpense;
  final double totalLoadValue;
  final double netProfit;
  final double mileageUsed;
  final int tollPlazas;
  final double dieselPricePerLitre;
  final double distanceKm;

  const TripCostEstimate({
    required this.dieselCost,
    required this.tollCost,
    required this.driverCost,
    required this.miscCost,
    required this.totalCost,
    required this.totalExpense,
    required this.totalLoadValue,
    required this.netProfit,
    required this.mileageUsed,
    required this.tollPlazas,
    required this.dieselPricePerLitre,
    required this.distanceKm,
  });

  String get compactLabel => '⛽ Est. Cost: ₹${totalExpense.round()}';
  String get profitLabel => netProfit >= 0
      ? '💰 Profit: ₹${netProfit.round()}'
      : '⚠️ Loss: ₹${netProfit.abs().round()}';
  bool get isProfitable => netProfit > 0;
}

class TripCostingService {
  // ─── Phase 5 Cost Constants ───
  static const double defaultDieselPricePerLitre = 90; // ₹90/L default
  static const double defaultMileageKmpl = 2.5; // 2.5 km/L average
  static const int defaultAxles = 4;
  static const double tollPerKm = 11; // Phase 5: ₹11/km realistic highway toll
  static const double driverCostPerKm = 5; // ₹5/km: driver allowance + batta + food
  static const double miscCostPerKm = 2; // ₹2/km: maintenance/misc/tyre wear

  const TripCostingService();

  TripCostEstimate? estimate({
    required double? distanceKm,
    required double? loadWeightTonnes,
    required double? dieselPricePerLitre,
    double? priceAmountPerTonne,
    double? mileageEmptyKmpl,
    double? mileageLoadedKmpl,
    double? payloadKg,
    int? axles,
  }) {
    if (distanceKm == null) {
      return null;
    }

    final mileage = _dynamicMileage(
      loadWeightTonnes: loadWeightTonnes,
      mileageEmptyKmpl: mileageEmptyKmpl,
      mileageLoadedKmpl: mileageLoadedKmpl,
      payloadKg: payloadKg,
    );
    final dieselPrice = dieselPricePerLitre ?? defaultDieselPricePerLitre;
    final dieselCost = (distanceKm / mileage) * dieselPrice;
    // Phase 5: distance-based toll (₹11/km) - more realistic than plaza-based
    final tollCost = distanceKm * tollPerKm;
    final driverCost = distanceKm * driverCostPerKm;
    final miscCost = distanceKm * miscCostPerKm;
    final totalExpense = dieselCost + tollCost + driverCost + miscCost;

    // Legacy toll plaza calculation for backward compatibility
    final tollPlazas = (distanceKm / 60).round().clamp(0, 50);

    // Net profit (only if we know load value)
    final totalLoadValue = (priceAmountPerTonne ?? 0) * (loadWeightTonnes ?? 0);
    final netProfit = totalLoadValue - totalExpense;

    return TripCostEstimate(
      dieselCost: dieselCost,
      tollCost: tollCost,
      driverCost: driverCost,
      miscCost: miscCost,
      totalCost: totalExpense,
      totalExpense: totalExpense,
      totalLoadValue: totalLoadValue,
      netProfit: netProfit,
      mileageUsed: mileage,
      tollPlazas: tollPlazas,
      dieselPricePerLitre: dieselPrice,
      distanceKm: distanceKm,
    );
  }

  double _dynamicMileage({
    required double? loadWeightTonnes,
    required double? mileageEmptyKmpl,
    required double? mileageLoadedKmpl,
    required double? payloadKg,
  }) {
    if (mileageEmptyKmpl == null || mileageLoadedKmpl == null || payloadKg == null || payloadKg <= 0) {
      return defaultMileageKmpl;
    }

    final loadWeightKg = (loadWeightTonnes ?? 0) * 1000;
    final loadRatio = (loadWeightKg / payloadKg).clamp(0.0, 1.0);
    return mileageEmptyKmpl - (loadRatio * (mileageEmptyKmpl - mileageLoadedKmpl));
  }

}

final tripCostingServiceProvider = Provider<TripCostingService>((ref) {
  return const TripCostingService();
});
