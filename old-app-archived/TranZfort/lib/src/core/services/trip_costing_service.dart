import '../error/app_failure.dart';
import '../error/result.dart';

class TripCostEstimate {
  final double dieselCost;
  final double tollCost;
  final double totalCost;
  final double estimatedMileage;

  const TripCostEstimate({
    required this.dieselCost,
    required this.tollCost,
    required this.totalCost,
    required this.estimatedMileage,
  });
}

class TripCostingService {
  static const double _fallbackDieselPrice = 90;
  static const double _fallbackMileage = 2.5;

  Result<TripCostEstimate> estimate({
    required double? distanceKm,
    required double? loadWeightTonnes,
    required double? payloadKg,
    required double? emptyMileageKmpl,
    required double? loadedMileageKmpl,
    required int axleCount,
    double? dieselPricePerLitre,
  }) {
    if (distanceKm == null || distanceKm <= 0) {
      return const Failure(
        AppFailureType.validation,
        debugMessage: 'Distance unavailable',
      );
    }

    final effectiveDieselPrice =
        (dieselPricePerLitre != null && dieselPricePerLitre > 0)
        ? dieselPricePerLitre
        : _fallbackDieselPrice;

    final estimatedMileage = _dynamicMileage(
      loadWeightTonnes: loadWeightTonnes,
      payloadKg: payloadKg,
      emptyMileageKmpl: emptyMileageKmpl,
      loadedMileageKmpl: loadedMileageKmpl,
    );

    final dieselCost = (distanceKm / estimatedMileage) * effectiveDieselPrice;
    final tollPlazas = (distanceKm / 60).ceil();
    final tollCost = tollPlazas * _tollRatePerPlaza(axleCount);
    final totalCost = dieselCost + tollCost;

    return Success(
      TripCostEstimate(
        dieselCost: dieselCost,
        tollCost: tollCost,
        totalCost: totalCost,
        estimatedMileage: estimatedMileage,
      ),
    );
  }

  double _dynamicMileage({
    required double? loadWeightTonnes,
    required double? payloadKg,
    required double? emptyMileageKmpl,
    required double? loadedMileageKmpl,
  }) {
    final emptyMileage = (emptyMileageKmpl != null && emptyMileageKmpl > 0)
        ? emptyMileageKmpl
        : _fallbackMileage;
    final loadedMileage = (loadedMileageKmpl != null && loadedMileageKmpl > 0)
        ? loadedMileageKmpl
        : _fallbackMileage;

    if (payloadKg == null || payloadKg <= 0 || loadWeightTonnes == null) {
      return loadedMileage;
    }

    final ratio = (loadWeightTonnes * 1000 / payloadKg).clamp(0, 1);
    final interpolated =
        emptyMileage - ((emptyMileage - loadedMileage) * ratio);
    return interpolated <= 0 ? _fallbackMileage : interpolated;
  }

  double _tollRatePerPlaza(int axleCount) {
    if (axleCount <= 2) return 115;
    if (axleCount == 3) return 190;
    if (axleCount == 4) return 245;
    return 300;
  }
}
