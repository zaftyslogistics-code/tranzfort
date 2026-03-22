import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tranzfort/src/core/error/app_failure.dart';
import 'package:tranzfort/src/core/error/result.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_models.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_load_repository.dart';
import 'package:tranzfort/src/features/supplier/data/supplier_location_services.dart';
import 'package:tranzfort/src/features/supplier/providers/post_load_provider.dart';

class _FakeSupplierLoadBackend implements SupplierLoadBackend {
  String createdId = 'load-42';
  Map<String, dynamic>? createParams;
  Object? error;

  @override
  Future<String> createLoad(Map<String, dynamic> params) async {
    if (error != null) {
      throw error!;
    }
    createParams = params;
    return createdId;
  }

  @override
  Future<void> cancelLoad(String loadId) async {}

  @override
  Future<void> closeLoadFilledOutsideApp(String loadId) async {}

  @override
  Future<Map<String, dynamic>?> fetchLoadDetail({required String supplierId, required String loadId}) async => null;

  @override
  Future<List<Map<String, dynamic>>> fetchBookingRequests({
    required String supplierId,
    required String loadId,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchLinkedTrips({
    required String supplierId,
    required String loadId,
  }) async => const <Map<String, dynamic>>[];

  @override
  Future<List<Map<String, dynamic>>> fetchMyLoads({required String supplierId, required LoadFilters filters, required int page, required int pageSize}) async => const [];

  @override
  Future<String> approveBookingRequest(String bookingId) async => 'trip-1';

  @override
  Future<void> rejectBookingRequest(String bookingId, {String? reason}) async {}
}

class _FakeLocationService implements SupplierLocationService {
  List<PlaceSuggestion> searchResults = const <PlaceSuggestion>[];
  RoutePreview? routePreview;

  @override
  Future<RoutePreview?> fetchRoutePreview({required PlaceSuggestion origin, required PlaceSuggestion destination}) async {
    return routePreview;
  }

  @override
  Future<PlaceSuggestion> resolveSuggestion(PlaceSuggestion suggestion) async {
    return suggestion;
  }

  @override
  Future<List<PlaceSuggestion>> searchCities(String query) async {
    return searchResults;
  }
}

void main() {
  test('post load provider validates required fields', () async {
    final controller = PostLoadController(
      SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
      _FakeLocationService(),
    );

    final result = await controller.submit();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(controller.state.fieldErrors, contains('origin_city'));
    expect(controller.state.fieldErrors, contains('price_amount'));
  });

  test('post load provider searches and selects route suggestions', () async {
    final locationService = _FakeLocationService()
      ..searchResults = const <PlaceSuggestion>[
        PlaceSuggestion(
          label: 'Chandrapur, Maharashtra',
          city: 'Chandrapur',
          state: 'Maharashtra',
          lat: 19.95,
          lng: 79.29,
          placeId: 'origin-1',
          source: 'google_places',
        ),
      ]
      ..routePreview = const RoutePreview(distanceKm: 820, durationMinutes: 840, source: 'osrm');
    final controller = PostLoadController(
      SupplierLoadRepository(_FakeSupplierLoadBackend(), () => 'supplier-1'),
      locationService,
    );

    await controller.searchOriginCity('Chand');
    expect(controller.state.originSuggestions, hasLength(1));
    await controller.selectOriginSuggestion(locationService.searchResults.first);

    controller.setDestinationLocation('Nhava Sheva Port');
    locationService.searchResults = const <PlaceSuggestion>[
      PlaceSuggestion(
        label: 'Mumbai, Maharashtra',
        city: 'Mumbai',
        state: 'Maharashtra',
        lat: 19.07,
        lng: 72.87,
        placeId: 'dest-1',
        source: 'google_places',
      ),
    ];
    await controller.searchDestinationCity('Mumbai');
    await controller.selectDestinationSuggestion(controller.state.destinationSuggestions.first);

    expect(controller.state.selectedOrigin?.city, 'Chandrapur');
    expect(controller.state.selectedDestination?.city, 'Mumbai');
    expect(controller.state.routePreview?.distanceKm, 820);
  });

  test('post load provider submits through supplier load repository', () async {
    final backend = _FakeSupplierLoadBackend();
    final locationService = _FakeLocationService()
      ..routePreview = const RoutePreview(distanceKm: 820, durationMinutes: 840, source: 'osrm');
    final controller = PostLoadController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      locationService,
    );

    controller.setOriginLocation('Ballarpur Yard');
    controller.setDestinationLocation('Nhava Sheva Port');
    controller.setWeightTonnes('22');
    controller.setTrucksNeeded('2');
    controller.setPriceAmount('54000');
    await controller.selectOriginSuggestion(
      const PlaceSuggestion(
        label: 'Chandrapur, Maharashtra',
        city: 'Chandrapur',
        state: 'Maharashtra',
        lat: 19.95,
        lng: 79.29,
        placeId: 'origin-1',
        source: 'google_places',
      ),
    );
    await controller.selectDestinationSuggestion(
      const PlaceSuggestion(
        label: 'Mumbai, Maharashtra',
        city: 'Mumbai',
        state: 'Maharashtra',
        lat: 19.07,
        lng: 72.87,
        placeId: 'dest-1',
        source: 'google_places',
      ),
    );

    final result = await controller.submit();

    expect(result, isA<Success<String>>());
    expect(controller.state.lastCreatedLoadId, 'load-42');
    expect(backend.createParams?['p_origin_city'], 'Chandrapur');
    expect(backend.createParams?['p_price_amount'], 54000.0);
  });

  test('post load provider prevents double submit and surfaces failure state', () async {
    final completer = Completer<String>();
    final backend = _SlowSupplierLoadBackend(completer.future);
    final controller = PostLoadController(
      SupplierLoadRepository(backend, () => 'supplier-1'),
      _FakeLocationService()..routePreview = const RoutePreview(distanceKm: 820, durationMinutes: 840, source: 'osrm'),
    );

    controller.setOriginLocation('Ballarpur Yard');
    controller.setDestinationLocation('Nhava Sheva Port');
    controller.setWeightTonnes('22');
    controller.setTrucksNeeded('2');
    controller.setPriceAmount('54000');
    await controller.selectOriginSuggestion(
      const PlaceSuggestion(
        label: 'Chandrapur, Maharashtra',
        city: 'Chandrapur',
        state: 'Maharashtra',
        lat: 19.95,
        lng: 79.29,
        placeId: 'origin-1',
        source: 'google_places',
      ),
    );
    await controller.selectDestinationSuggestion(
      const PlaceSuggestion(
        label: 'Mumbai, Maharashtra',
        city: 'Mumbai',
        state: 'Maharashtra',
        lat: 19.07,
        lng: 72.87,
        placeId: 'dest-1',
        source: 'google_places',
      ),
    );

    final firstSubmit = controller.submit();
    final secondSubmit = await controller.submit();

    expect(secondSubmit.isFailure, isTrue);
    expect(secondSubmit.failureOrNull, isA<BusinessRuleFailure>());

    completer.complete('load-77');
    final firstResult = await firstSubmit;
    expect(firstResult.isSuccess, isTrue);
  });
}

class _SlowSupplierLoadBackend extends _FakeSupplierLoadBackend {
  final Future<String> pendingResult;

  _SlowSupplierLoadBackend(this.pendingResult);

  @override
  Future<String> createLoad(Map<String, dynamic> params) async {
    createParams = params;
    return pendingResult;
  }
}
