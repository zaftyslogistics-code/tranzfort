import '../../trucker/data/trucker_marketplace_repository.dart';
import 'supplier_load_models.dart';

/// Maps supplier [Load] list rows to [MarketplaceLoadItem] for shared dark cards.
extension SupplierLoadMarketplaceMapping on Load {
  MarketplaceLoadItem toMarketplaceItem({required String supplierId}) {
    return MarketplaceLoadItem(
      id: id,
      supplierId: supplierId,
      originLabel: originLabel,
      originCity: _labelCity(originLabel),
      originState: _labelState(originLabel),
      originLat: null,
      originLng: null,
      destinationLabel: destinationLabel,
      destinationCity: _labelCity(destinationLabel),
      destinationState: _labelState(destinationLabel),
      destinationLat: null,
      destinationLng: null,
      routeDistanceKm: null,
      routeDurationMinutes: null,
      material: material,
      weightTonnes: weightTonnes,
      requiredBodyType: requiredBodyType,
      requiredTyres: requiredTyres,
      trucksNeeded: trucksNeeded,
      trucksBooked: trucksBooked,
      priceAmount: priceAmount,
      priceType: priceType,
      advancePercentage: 0,
      pickupDate: pickupDate,
      status: status,
      isSuperLoad: isSuperLoad,
      superStatus: superStatus,
      createdAt: publishedAt ?? pickupDate,
    );
  }

  static String _labelCity(String label) {
    final parts = label.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? label.trim() : parts.first;
  }

  static String? _labelState(String label) {
    final parts = label.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return null;
    return parts.last;
  }
}
