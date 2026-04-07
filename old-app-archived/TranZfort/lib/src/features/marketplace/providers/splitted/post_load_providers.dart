import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/error_logger.dart';
import '../../../../core/services/city_search_service.dart' show CitySearchService, CitySuggestion;
import '../../../../core/services/weather_service.dart' show WeatherService, WeatherSnapshot;
import '../../utils/load_pricing.dart';
import 'find_loads_providers.dart' show myLoadsProvider;
import 'shared_providers.dart';

class PostLoadState {
  final bool isPosting;
  final bool isPosted;
  final String? error;
  final Map<String, dynamic> postedLoad;

  final int currentStep;
  final String? requiredTruckType;
  final List<int> requiredTyres;
  final double price;
  final String priceType;
  final int advancePercentage;
  final DateTime pickupDate;
  final int trucksNeeded;

  final bool isSubmitting;
  final String? originCity;
  final String? originState;
  final double? originLat;
  final double? originLng;
  final String? destinationCity;
  final String? destinationState;
  final double? destinationLat;
  final double? destinationLng;
  final double? distanceKm;
  final double? durationHours;
  final double? tollEstimate;
  final String material;
  final double weightTonnes;

  PostLoadState({
    this.isPosting = false,
    this.isPosted = false,
    this.error,
    this.postedLoad = const {},
    this.currentStep = 0,
    this.requiredTruckType,
    this.requiredTyres = const [],
    this.price = 62500,
    this.priceType = LoadPricing.fixed,
    this.advancePercentage = 80,
    DateTime? pickupDate,
    this.trucksNeeded = 1,
    this.isSubmitting = false,
    this.originCity,
    this.originState,
    this.originLat,
    this.originLng,
    this.destinationCity,
    this.destinationState,
    this.destinationLat,
    this.destinationLng,
    this.distanceKm,
    this.durationHours,
    this.tollEstimate,
    this.material = 'Coal',
    this.weightTonnes = 25,
  }) : pickupDate = pickupDate ?? DateTime.now().add(const Duration(days: 1));

  bool get canGoNextStepOne =>
      (originCity?.trim().isNotEmpty ?? false) &&
      (destinationCity?.trim().isNotEmpty ?? false);

  bool get canSubmit =>
      canGoNextStepOne &&
      material.trim().isNotEmpty &&
      requiredTyres.isNotEmpty &&
      weightTonnes > 0 &&
      price > 0 &&
      trucksNeeded >= 1;

  PostLoadState copyWith({
    bool? isPosting,
    bool? isPosted,
    String? error,
    Map<String, dynamic>? postedLoad,
    int? currentStep,
    String? requiredTruckType,
    List<int>? requiredTyres,
    double? price,
    String? priceType,
    int? advancePercentage,
    DateTime? pickupDate,
    int? trucksNeeded,
    bool? isSubmitting,
    String? originCity,
    String? originState,
    double? originLat,
    double? originLng,
    String? destinationCity,
    String? destinationState,
    double? destinationLat,
    double? destinationLng,
    double? distanceKm,
    double? durationHours,
    double? tollEstimate,
    String? material,
    double? weightTonnes,
    bool clearOriginMeta = false,
    bool clearDestinationMeta = false,
    bool clearRouteMeta = false,
  }) {
    return PostLoadState(
      isPosting: isPosting ?? this.isPosting,
      isPosted: isPosted ?? this.isPosted,
      error: error,
      postedLoad: postedLoad ?? this.postedLoad,
      currentStep: currentStep ?? this.currentStep,
      requiredTruckType: requiredTruckType ?? this.requiredTruckType,
      requiredTyres: requiredTyres ?? this.requiredTyres,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
      advancePercentage: advancePercentage ?? this.advancePercentage,
      pickupDate: pickupDate ?? this.pickupDate,
      trucksNeeded: trucksNeeded ?? this.trucksNeeded,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      originCity: originCity ?? this.originCity,
      originState: clearOriginMeta ? null : (originState ?? this.originState),
      originLat: clearOriginMeta ? null : (originLat ?? this.originLat),
      originLng: clearOriginMeta ? null : (originLng ?? this.originLng),
      destinationCity: destinationCity ?? this.destinationCity,
      destinationState:
          clearDestinationMeta ? null : (destinationState ?? this.destinationState),
      destinationLat:
          clearDestinationMeta ? null : (destinationLat ?? this.destinationLat),
      destinationLng:
          clearDestinationMeta ? null : (destinationLng ?? this.destinationLng),
      distanceKm: clearRouteMeta ? null : (distanceKm ?? this.distanceKm),
      durationHours: clearRouteMeta ? null : (durationHours ?? this.durationHours),
      tollEstimate: clearRouteMeta ? null : (tollEstimate ?? this.tollEstimate),
      material: material ?? this.material,
      weightTonnes: weightTonnes ?? this.weightTonnes,
    );
  }
}

class PostLoadNotifier extends StateNotifier<PostLoadState> {
  final Ref _ref;

  PostLoadNotifier(this._ref) : super(PostLoadState());

  Future<bool> postLoad({
    required String originCity,
    required String destinationCity,
    required String material,
    required String truckType,
    required double capacity,
    required double pricePerTon,
    String? description,
  }) async {
    state = state.copyWith(isPosting: true, error: null);

    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      state = state.copyWith(
        isPosting: false,
        error: 'Not authenticated',
      );
      return false;
    }

    final originResolved = await _resolveCityByName(originCity);
    final destinationResolved = await _resolveCityByName(destinationCity);

    final originLat = originResolved?.lat;
    final originLng = originResolved?.lng;
    final destinationLat = destinationResolved?.lat;
    final destinationLng = destinationResolved?.lng;

    if (originLat == null ||
        originLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      state = state.copyWith(
        isPosting: false,
        error: 'Invalid city locations',
      );
      return false;
    }

    final fallbackDistance = _haversineKm(
      originLat,
      originLng,
      destinationLat,
      destinationLng,
    );

    final payload = {
      'origin_city': originCity,
      'origin_state': originResolved?.state,
      'dest_city': destinationCity,
      'dest_state': destinationResolved?.state,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'dest_lat': destinationLat,
      'dest_lng': destinationLng,
      'distance_km': fallbackDistance,
      'material': material,
      'required_truck_type': truckType,
      'weight_tonnes': capacity,
      'price': pricePerTon,
      'description': description,
    };

    final result = await _ref.read(loadRepositoryProvider).createLoad(
      supplierId: user.id,
      payload: payload,
    );

    switch (result) {
      case Success(data: final loadData):
        state = state.copyWith(
          isPosting: false,
          isPosted: true,
          postedLoad: loadData,
        );
        return true;
      case Failure(debugMessage: final error):
        state = state.copyWith(
          isPosting: false,
          error: error ?? 'Failed to create load',
        );
        return false;
    }
  }

  Future<CitySuggestion?> _resolveCityByName(String cityName, {String? stateName}) async {
    final trimmedCity = cityName.trim();
    final trimmedState = stateName?.trim() ?? '';
    if (trimmedCity.isEmpty) {
      return null;
    }

    final service = _ref.read(citySearchServiceProvider);
    final query = [trimmedCity, trimmedState]
        .where((part) => part.isNotEmpty)
        .join(' ');
    final result = await service.search(query);
    if (result.suggestions.isEmpty) {
      return null;
    }

    CitySuggestion selected;
    try {
      selected = result.suggestions.firstWhere(
        (item) =>
            item.city.toLowerCase() == trimmedCity.toLowerCase() &&
            (trimmedState.isEmpty ||
                item.state.toLowerCase() == trimmedState.toLowerCase()),
      );
    } catch (_) {
      selected = result.suggestions.first;
    }

    return service.resolveSelection(selected);
  }

  void reset() {
    state = PostLoadState();
  }

  void setTruckType(String? value) {
    state = state.copyWith(requiredTruckType: value);
  }

  void toggleTyre(int tyre) {
    final current = List<int>.from(state.requiredTyres);
    if (current.contains(tyre)) {
      current.remove(tyre);
    } else {
      current.add(tyre);
    }
    state = state.copyWith(requiredTyres: current);
  }

  void setPrice(double price) {
    state = state.copyWith(price: price);
  }

  void setPriceType(String type) {
    state = state.copyWith(priceType: LoadPricing.normalizePriceType(type));
  }

  void setAdvance(int percentage) {
    state = state.copyWith(advancePercentage: percentage);
  }

  void setPickupDate(DateTime date) {
    state = state.copyWith(pickupDate: date);
  }

  void setTrucksNeeded(int count) {
    state = state.copyWith(trucksNeeded: count < 1 ? 1 : count);
  }

  void setOrigin(String city) {
    state = state.copyWith(
      originCity: city,
      clearOriginMeta: true,
      clearRouteMeta: true,
    );
  }

  void setOriginSuggestion(CitySuggestion city) {
    state = state.copyWith(
      originCity: city.city,
      originState: city.state,
      originLat: city.lat,
      originLng: city.lng,
    );
    unawaited(_recalculateDistance());
  }

  void setDestination(String city) {
    state = state.copyWith(
      destinationCity: city,
      clearDestinationMeta: true,
      clearRouteMeta: true,
    );
  }

  void setDestinationSuggestion(CitySuggestion city) {
    state = state.copyWith(
      destinationCity: city.city,
      destinationState: city.state,
      destinationLat: city.lat,
      destinationLng: city.lng,
    );
    unawaited(_recalculateDistance());
  }

  void setMaterial(String material) {
    state = state.copyWith(material: material);
  }

  void setWeight(double weight) {
    state = state.copyWith(weightTonnes: weight);
  }

  void nextStep() {
    if (state.currentStep == 0 && !state.canGoNextStepOne) {
      return;
    }
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<bool> submitLoad() async {
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      ErrorLogger.logWarning(
        'Post load submit blocked: unauthenticated user',
        context: {
          'module': 'marketplace',
          'flow': 'post_load_submit',
        },
      );
      state = state.copyWith(error: 'Not authenticated');
      return false;
    }

    final profile = await _ref.read(userProfileProvider.future);
    final verificationStatus = (profile?['verification_status'] ?? '').toString().toLowerCase();
    if (verificationStatus != 'verified') {
      ErrorLogger.logWarning(
        'Post load submit blocked: supplier is not verified',
        context: {
          'module': 'marketplace',
          'flow': 'post_load_submit',
          'userId': user.id,
          'verificationStatus': verificationStatus,
          'profileRole': profile?['user_role_type'],
        },
      );
      state = state.copyWith(error: 'You must be verified to post loads');
      return false;
    }

    if (!state.canSubmit) {
      ErrorLogger.logWarning(
        'Post load submit blocked: missing required load details',
        context: {
          'module': 'marketplace',
          'flow': 'post_load_submit',
          'userId': user.id,
          'originCity': state.originCity,
          'destinationCity': state.destinationCity,
          'material': state.material,
          'requiredTruckType': state.requiredTruckType,
          'requiredTyresCount': state.requiredTyres.length,
          'weightTonnes': state.weightTonnes,
          'price': state.price,
          'trucksNeeded': state.trucksNeeded,
        },
      );
      state = state.copyWith(error: 'Missing required load details');
      return false;
    }

    ErrorLogger.logInfo(
      'Post load submit started',
      context: {
        'module': 'marketplace',
        'flow': 'post_load_submit',
        'userId': user.id,
        'originCity': state.originCity,
        'destinationCity': state.destinationCity,
        'material': state.material,
        'requiredTruckType': state.requiredTruckType,
        'requiredTyres': state.requiredTyres.join(','),
        'price': state.price,
        'trucksNeeded': state.trucksNeeded,
      },
    );

    state = state.copyWith(isSubmitting: true, error: null);

    final originResolved = await _ensureOriginResolved();
    final destinationResolved = await _ensureDestinationResolved();
    if (originResolved == null || destinationResolved == null) {
      ErrorLogger.logWarning(
        'Post load submit blocked: unable to resolve route cities',
        context: {
          'module': 'marketplace',
          'flow': 'post_load_submit',
          'userId': user.id,
          'originCity': state.originCity,
          'originState': state.originState,
          'originLat': state.originLat,
          'originLng': state.originLng,
          'destinationCity': state.destinationCity,
          'destinationState': state.destinationState,
          'destinationLat': state.destinationLat,
          'destinationLng': state.destinationLng,
        },
      );
      state = state.copyWith(
        isSubmitting: false,
        error: 'Unable to resolve route cities',
      );
      return false;
    }

    final payload = <String, dynamic>{
      'origin_city': state.originCity,
      'origin_state': state.originState,
      'origin_lat': state.originLat,
      'origin_lng': state.originLng,
      'dest_city': state.destinationCity,
      'dest_state': state.destinationState,
      'dest_lat': state.destinationLat,
      'dest_lng': state.destinationLng,
      'distance_km': state.distanceKm,
      'duration_hours': state.durationHours,
      'material': state.material,
      'weight_tonnes': state.weightTonnes,
      'required_truck_type': state.requiredTruckType,
      'required_tyres': state.requiredTyres,
      'price': state.price,
      'price_type': LoadPricing.serializeForDatabase(state.priceType),
      'advance_percentage': state.advancePercentage,
      'pickup_date': state.pickupDate.toIso8601String().split('T').first,
      'trucks_needed': state.trucksNeeded,
    };

    ErrorLogger.logDebug(
      'Post load payload prepared',
      context: {
        'module': 'marketplace',
        'flow': 'post_load_submit',
        'userId': user.id,
        'origin_state': payload['origin_state'],
        'dest_state': payload['dest_state'],
        'origin_lat': payload['origin_lat'],
        'origin_lng': payload['origin_lng'],
        'dest_lat': payload['dest_lat'],
        'dest_lng': payload['dest_lng'],
        'distance_km': payload['distance_km'],
        'duration_hours': payload['duration_hours'],
        'pickup_date': payload['pickup_date'],
        'price_type': payload['price_type'],
        'advance_percentage': payload['advance_percentage'],
      },
    );

    final result = await _ref.read(loadRepositoryProvider).createLoad(
      supplierId: user.id,
      payload: payload,
    );

    switch (result) {
      case Success(data: final loadData):
        ErrorLogger.logInfo(
          'Post load submit succeeded',
          context: {
            'module': 'marketplace',
            'flow': 'post_load_submit',
            'userId': user.id,
            'loadId': loadData['id'],
            'status': loadData['status'],
          },
        );
        state = PostLoadState(isPosted: true, postedLoad: loadData);
        _ref.invalidate(myLoadsProvider(false));
        return true;
      case Failure(debugMessage: final error):
        ErrorLogger.logError(
          'Post load submit failed in repository',
          error: error,
          context: {
            'module': 'marketplace',
            'flow': 'post_load_submit',
            'userId': user.id,
            'originCity': state.originCity,
            'destinationCity': state.destinationCity,
            'material': state.material,
            'requiredTruckType': state.requiredTruckType,
          },
        );
        state = state.copyWith(
          isSubmitting: false,
          error: error ?? 'Failed to create load',
        );
        return false;
    }
  }

  Future<void> resolveOriginInput(String rawValue) async {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      setOrigin('');
      return;
    }

    final parsed = _parseCityState(trimmed);
    final resolved = await _resolveCityByName(
      parsed.city,
      stateName: parsed.state,
    );
    if (resolved == null) {
      setOrigin(parsed.city);
      return;
    }

    setOriginSuggestion(resolved);
  }

  Future<void> resolveDestinationInput(String rawValue) async {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      setDestination('');
      return;
    }

    final parsed = _parseCityState(trimmed);
    final resolved = await _resolveCityByName(
      parsed.city,
      stateName: parsed.state,
    );
    if (resolved == null) {
      setDestination(parsed.city);
      return;
    }

    setDestinationSuggestion(resolved);
  }

  Future<CitySuggestion?> _ensureOriginResolved() async {
    if ((state.originCity?.trim().isEmpty ?? true)) {
      return null;
    }
    if (state.originLat != null && state.originLng != null) {
      return CitySuggestion(
        city: state.originCity!,
        state: state.originState ?? '',
        lat: state.originLat,
        lng: state.originLng,
      );
    }

    final resolved = await _resolveCityByName(
      state.originCity!,
      stateName: state.originState,
    );
    if (resolved == null || resolved.lat == null || resolved.lng == null) {
      return null;
    }
    setOriginSuggestion(resolved);
    return resolved;
  }

  Future<CitySuggestion?> _ensureDestinationResolved() async {
    if ((state.destinationCity?.trim().isEmpty ?? true)) {
      return null;
    }
    if (state.destinationLat != null && state.destinationLng != null) {
      return CitySuggestion(
        city: state.destinationCity!,
        state: state.destinationState ?? '',
        lat: state.destinationLat,
        lng: state.destinationLng,
      );
    }

    final resolved = await _resolveCityByName(
      state.destinationCity!,
      stateName: state.destinationState,
    );
    if (resolved == null || resolved.lat == null || resolved.lng == null) {
      return null;
    }
    setDestinationSuggestion(resolved);
    return resolved;
  }

  Future<void> _recalculateDistance() async {
    final originLat = state.originLat;
    final originLng = state.originLng;
    final destinationLat = state.destinationLat;
    final destinationLng = state.destinationLng;

    if (originLat == null ||
        originLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      state = state.copyWith(clearRouteMeta: true);
      return;
    }

    final fallbackKm = _haversineKm(
      originLat,
      originLng,
      destinationLat,
      destinationLng,
    );
    final fallbackDurationHours = fallbackKm / 48;
    state = state.copyWith(
      distanceKm: fallbackKm,
      durationHours: fallbackDurationHours,
      tollEstimate: null,
    );

    try {
      final route = await _ref.read(googleRoutesServiceProvider).computeRoute(
        LatLng(originLat, originLng),
        LatLng(destinationLat, destinationLng),
      );

      if (!mounted) {
        return;
      }

      if (route.distanceKm != null && route.durationHours != null) {
        state = state.copyWith(
          distanceKm: route.distanceKm,
          durationHours: route.durationHours,
          tollEstimate: route.tollEstimate,
        );
      }
    } catch (_) {
      return;
    }
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = _sinHalfSquared(dLat) +
        (_cos(lat1) * _cos(lat2) * _sinHalfSquared(dLon));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  ({String city, String? state}) _parseCityState(String rawValue) {
    final parts = rawValue
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return (city: rawValue.trim(), state: null);
    }

    return (
      city: parts.first,
      state: parts.length > 1 ? parts[1] : null,
    );
  }

  double _degreesToRadians(double degrees) => degrees * 0.017453292519943295;

  double _cos(double degrees) => math.cos(_degreesToRadians(degrees));

  double _sinHalfSquared(double angle) {
    final sinHalf = math.sin(angle / 2);
    return sinHalf * sinHalf;
  }
}

// Provider declarations
final postLoadProvider =
    StateNotifierProvider<PostLoadNotifier, PostLoadState>((ref) {
  return PostLoadNotifier(ref);
});

final citySearchServiceProvider = Provider<CitySearchService>((ref) {
  return CitySearchService(ref.watch(mapsConfigProvider));
});

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService(ref.watch(mapsConfigProvider));
});

final verifiedTrucksProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) {
    return const [];
  }

  final result = await ref
      .watch(loadRepositoryProvider)
      .getVerifiedTrucks(user.id);

  switch (result) {
    case Success(data: final data):
      return data;
    case Failure():
      return <Map<String, dynamic>>[];
  }
});

final weatherByLocationProvider =
    FutureProvider.family<WeatherSnapshot?, ({double lat, double lng})>((
      ref,
      location,
    ) {
      return ref
          .watch(weatherServiceProvider)
          .getCurrentWeather(lat: location.lat, lng: location.lng);
    });

final loadRouteMetaProvider =
    FutureProvider.family<Map<String, dynamic>?, ({double lat, double lng})>((
      ref,
      location,
    ) async {
      try {
        final origin = LatLng(location.lat, location.lng); // Mock origin for now, usually it needs real origin
        final routeDataResult = await ref
            .watch(osrmServiceProvider)
            .getRouteData(origin, LatLng(location.lat, location.lng));
        
        switch (routeDataResult) {
          case Success(data: final data):
            return {
              'driveTimeMinutes': (data.durationSeconds / 60).round(),
              'distanceKm': data.distanceMeters / 1000.0,
            };
          case Failure():
            return null;
        }
      } catch (_) {
        return null;
      }
    });

final loadDestinationWeatherProvider =
    FutureProvider.family<WeatherSnapshot?, ({double lat, double lng})>((
      ref,
      location,
    ) async {
      return await ref
          .watch(weatherServiceProvider)
          .getCurrentWeather(lat: location.lat, lng: location.lng);
    });

final savedSearchesProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) async {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    if (user == null) return [];

    final result = await ref.read(loadRepositoryProvider).getSavedSearches(user.id);
    switch (result) {
      case Success(data: final data):
        return data;
      case Failure():
        return <Map<String, dynamic>>[];
    }
  },
);

class SavedSearchActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SavedSearchActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> saveSearch({
    required String originCity,
    required String destinationCity,
    required String material,
    required String truckType,
    required String sortBy,
  }) async {
    state = const AsyncLoading();
    
    final user = _ref.read(authSessionProvider).value?.session?.user;
    if (user == null) {
      state = AsyncError('Not authenticated', StackTrace.current);
      return false;
    }

    final result = await _ref.read(loadRepositoryProvider).saveSearch(
      userId: user.id,
      originCity: originCity,
      destinationCity: destinationCity,
      material: material,
      truckType: truckType,
      sortBy: sortBy,
    );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(savedSearchesProvider);
        return true;
      case Failure(debugMessage: final error):
        state = AsyncError(error ?? 'Failed to save search', StackTrace.current);
        return false;
    }
  }

  Future<bool> deleteSearch(String searchId) async {
    state = const AsyncLoading();
    
    final result = await _ref.read(loadRepositoryProvider).deleteSavedSearch(searchId);

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(savedSearchesProvider);
        return true;
      case Failure(debugMessage: final error):
        state = AsyncError(error ?? 'Failed to delete search', StackTrace.current);
        return false;
    }
  }
}

final savedSearchActionProvider =
    StateNotifierProvider<SavedSearchActionNotifier, AsyncValue<void>>((ref) {
      return SavedSearchActionNotifier(ref);
    });

final citySearchProvider =
    FutureProvider.family<List<CitySuggestion>, String>((ref, query) async {
      if (query.trim().length < 2) return [];
      final result = await ref.read(citySearchServiceProvider).search(query);
      return result.suggestions;
    });

class RouteCalculationUtils {
  static double calculateDistance(LatLng p1, LatLng p2) {
    return const Distance().as(LengthUnit.Kilometer, p1, p2);
  }

  static double calculateEstimatedPrice(
    double distance,
    double basePricePerTon,
    double capacity,
  ) {
    final basePrice = distance * basePricePerTon;
    final capacityMultiplier = math.min(capacity / 25.0, 2.0);
    return basePrice * capacityMultiplier;
  }

  static Duration calculateEstimatedDuration(double distanceKm) {
    final avgSpeedKmh = 60.0;
    final hours = distanceKm / avgSpeedKmh;
    return Duration(hours: hours.round());
  }
}
