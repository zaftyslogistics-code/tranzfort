import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripCostEstimate {
  final double dieselCost;
  final double tollCost;
  final double totalCost;
  final double mileageUsed;
  final int tollPlazas;
  final double dieselPricePerLitre;

  const TripCostEstimate({
    required this.dieselCost,
    required this.tollCost,
    required this.totalCost,
    required this.mileageUsed,
    required this.tollPlazas,
    required this.dieselPricePerLitre,
  });

  String get compactLabel => '⛽ Est. Cost: ₹${totalCost.round()}';
}

class TripCostingService {
  static const double defaultDieselPricePerLitre = 90;
  static const double defaultMileageKmpl = 2.5;
  static const int defaultAxles = 4;

  const TripCostingService();

  TripCostEstimate? estimate({
    required double? distanceKm,
    required double? loadWeightTonnes,
    required double? dieselPricePerLitre,
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
    final tollPlazas = (distanceKm / 60).round().clamp(0, 50);
    final tollRate = _tollRatePerPlaza(axles ?? defaultAxles);
    final tollCost = tollPlazas * tollRate;

    return TripCostEstimate(
      dieselCost: dieselCost,
      tollCost: tollCost.toDouble(),
      totalCost: dieselCost + tollCost,
      mileageUsed: mileage,
      tollPlazas: tollPlazas,
      dieselPricePerLitre: dieselPrice,
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

  int _tollRatePerPlaza(int axles) {
    return switch (axles) {
      2 => 115,
      3 => 190,
      4 => 280,
      5 => 380,
      6 => 475,
      _ => 280,
    };
  }
}

final tripCostingServiceProvider = Provider<TripCostingService>((ref) {
  return const TripCostingService();
});
