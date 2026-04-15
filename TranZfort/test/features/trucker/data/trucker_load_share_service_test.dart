import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_detail_repository.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_load_share_service.dart';
import 'package:tranzfort/src/features/trucker/data/trucker_marketplace_repository.dart';
import 'package:tranzfort/src/l10n/app_localizations_en.dart';

TruckerLoadDetail _detail({String? requiredBodyType = 'Open', List<int> requiredTyres = const [10, 12], String priceType = 'negotiable'}) {
  return TruckerLoadDetail(
    summary: MarketplaceLoadItem(
      id: 'load-1',
      supplierId: 'supplier-1',
      originLabel: 'Chandrapur, Maharashtra',
      originCity: 'Chandrapur',
      originState: 'Maharashtra',
      originLat: 19.9615,
      originLng: 79.2961,
      destinationLabel: 'Mumbai, Maharashtra',
      destinationCity: 'Mumbai',
      destinationState: 'Maharashtra',
      destinationLat: 19.0760,
      destinationLng: 72.8777,
      routeDistanceKm: 820,
      routeDurationMinutes: 780,
      material: 'Coal',
      weightTonnes: 22,
      requiredBodyType: requiredBodyType,
      requiredTyres: requiredTyres,
      trucksNeeded: 2,
      trucksBooked: 1,
      priceAmount: 54000,
      priceType: priceType,
      advancePercentage: 30,
      pickupDate: DateTime(2026, 3, 12),
      status: 'active',
      isSuperLoad: true,
      superStatus: 'active',
      createdAt: DateTime(2026, 3, 8),
    ),
    supplierId: 'supplier-1',
    supplier: const TruckerSupplierSummary(
      id: 'supplier-1',
      fullName: 'Amit Supplier',
      companyName: 'Amit Logistics',
      verificationStatus: 'verified',
    ),
    originCity: 'Chandrapur',
    originState: 'Maharashtra',
    originLat: 19.95,
    originLng: 79.30,
    destinationCity: 'Mumbai',
    destinationState: 'Maharashtra',
    destinationLat: 19.07,
    destinationLng: 72.87,
    routeDistanceKm: 820,
    routeDurationMinutes: 780,
    routePolyline: null,
    routeSnapshotSource: 'osrm',
    parentLoadId: null,
    assignedTruckerId: null,
    assignedTruckId: null,
    createdAt: DateTime(2026, 3, 8, 12),
    updatedAt: DateTime(2026, 3, 8, 13),
    latestBookingRequest: null,
  );
}

void main() {
  test('builds a summary-first share payload without sensitive details', () {
    final l10n = AppLocalizationsEn();
    const localizedPickupDate = '12 Mar 2026';
    final service = TruckerLoadShareService(
      canLaunchUrlFn: (_) async => true,
      launchUrlFn: (_) async => true,
      shareSystemTextFn: (_, subject) async {},
    );

    final payload = service.buildPayload(l10n, localizedPickupDate, _detail(priceType: 'per_ton'));

    expect(payload.subject, 'TranZfort Load load-1');
    expect(payload.text, contains('TranZfort load: Chandrapur > Mumbai'));
    expect(payload.text, contains('Material: Coal'));
    expect(payload.text, contains('Weight: 22 tonnes'));
    expect(payload.text, contains('Truck: Open - 10/12 tyres'));
    expect(payload.text, contains('Pickup 12 Mar 2026'));
    expect(payload.text, contains('Price: ₹54000 - Per Ton'));
    expect(payload.text, contains('Super Load - Payment Guarantee'));
    expect(payload.text, contains('Load reference: load-1'));
    expect(payload.text, isNot(contains('Amit Supplier')));
    expect(payload.text, isNot(contains('+91')));
    expect(payload.whatsappUri.toString(), contains('wa.me'));
  });

  test('builds localized Any fallbacks for body type and tyres in share payload', () {
    final l10n = AppLocalizationsEn();
    const localizedPickupDate = '12 Mar 2026';
    final service = TruckerLoadShareService(
      canLaunchUrlFn: (_) async => true,
      launchUrlFn: (_) async => true,
      shareSystemTextFn: (_, subject) async {},
    );

    final payload = service.buildPayload(
      l10n,
      localizedPickupDate,
      _detail(requiredBodyType: null, requiredTyres: const <int>[], priceType: 'fixed'),
    );

    expect(payload.text, contains('Truck: Any body - Any tyres'));
    expect(payload.text, contains('Price: ₹54000 - Fixed'));
  });
}
