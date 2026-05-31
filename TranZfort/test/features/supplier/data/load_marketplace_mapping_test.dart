import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/supplier/data/load_marketplace_mapping.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';

void main() {
  test('Load maps to MarketplaceLoadItem for compact cards', () {
    final item = Load(
      id: 'load-1',
      originLabel: 'Pune, Maharashtra',
      destinationLabel: 'Mumbai, Maharashtra',
      material: 'Steel',
      weightTonnes: 10,
      trucksNeeded: 3,
      trucksBooked: 1,
      priceAmount: 25000,
      priceType: 'fixed',
      pickupDate: DateTime(2026, 6, 1),
      status: 'active',
      requiredBodyType: 'open',
      requiredTyres: [10],
      isSuperLoad: false,
      superStatus: 'none',
      publishedAt: null,
      isOnMarketplace: true,
    ).toMarketplaceItem(supplierId: 'supplier-1');

    expect(item.originCity, 'Pune');
    expect(item.destinationCity, 'Mumbai');
    expect(item.trucksBooked, 1);
    expect(item.trucksNeeded, 3);
  });
}
