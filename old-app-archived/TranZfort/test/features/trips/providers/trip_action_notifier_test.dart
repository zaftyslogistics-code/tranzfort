import 'dart:io';

import 'package:app/src/core/config/maps_config.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/repositories/load_repository.dart';
import 'package:app/src/core/services/google_routes_service.dart';
import 'package:app/src/core/services/location_service.dart';
import 'package:app/src/core/services/osrm_service.dart';
import 'package:app/src/core/services/storage_service.dart';
import 'package:app/src/features/marketplace/providers/marketplace_providers.dart';
import 'package:app/src/features/trips/providers/trips_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeLoadRepository extends LoadRepository {
  _FakeLoadRepository()
      : super(
          SupabaseClient(
            'http://127.0.0.1:1',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dGVzdA.sig',
          ),
        );

  double? lastStartLat;
  double? lastStartLng;
  double? lastDeliveredLat;
  double? lastDeliveredLng;
  double? lastPodLat;
  double? lastPodLng;
  String? lastUploadLrTripId;
  String? lastUploadLrUrl;
  String? lastUploadPodTripId;
  String? lastUploadPodUrl;

  Map<String, dynamic> tripDetail = const {
    'load': {'id': 'load-1'}
  };

  @override
  Future<Result<void>> startTrip({
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    lastStartLat = lat;
    lastStartLng = lng;
    return const Success(null);
  }

  @override
  Future<Result<void>> markDelivered({
    required String tripId,
    double? lat,
    double? lng,
  }) async {
    lastDeliveredLat = lat;
    lastDeliveredLng = lng;
    return const Success(null);
  }

  @override
  Future<Result<Map<String, dynamic>>> getTripDetail(String tripId) async {
    return Success(tripDetail);
  }

  @override
  Future<Result<void>> uploadLr({
    required String tripId,
    required String lrPhotoUrl,
  }) async {
    lastUploadLrTripId = tripId;
    lastUploadLrUrl = lrPhotoUrl;
    return const Success(null);
  }

  @override
  Future<Result<void>> uploadPod({
    required String tripId,
    required String podPhotoUrl,
    double? lat,
    double? lng,
  }) async {
    lastUploadPodTripId = tripId;
    lastUploadPodUrl = podPhotoUrl;
    lastPodLat = lat;
    lastPodLng = lng;
    return const Success(null);
  }

  @override
  Future<Result<void>> submitRating({
    required String loadId,
    required String reviewerId,
    required String revieweeId,
    required String reviewerRole,
    required int score,
    String? comment,
  }) async {
    return const Success(null);
  }
}

class _FakeLocationService extends LocationService {
  const _FakeLocationService();

  @override
  Future<CapturedLocation?> captureCurrentLocation() async {
    return const CapturedLocation(lat: 19.076, lng: 72.8777);
  }
}

class _FakeTripRoutesService extends GoogleRoutesService {
  _FakeTripRoutesService()
      : super(
          const MapsConfig(
            apiKey: '',
            enableGooglePlaces: false,
            enableGoogleRoutes: false,
            enableGoogleGeocoding: false,
            enableOsrmFallback: true,
          ),
          OsrmService(),
        );

  @override
  Future<ReverseGeocodeResult?> reverseGeocode(double lat, double lng) async {
    return const ReverseGeocodeResult(city: 'Mumbai', state: 'Maharashtra');
  }
}

class _FakeStorageService extends StorageService {
  _FakeStorageService()
      : super(
          SupabaseClient(
            'http://127.0.0.1:1',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dGVzdA.sig',
          ),
        );

  String? lastBucketName;
  String? lastFullPath;

  @override
  Future<Result<String>> uploadFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    lastBucketName = bucketName;
    lastFullPath = fullPath;
    return Success('https://example.com/$fullPath');
  }
}

void main() {
  ProviderContainer createContainer({
    required _FakeLoadRepository loadRepository,
    required _FakeStorageService storageService,
    required _FakeLocationService locationService,
  }) {
    return ProviderContainer(
      overrides: [
        loadRepositoryProvider.overrideWithValue(loadRepository),
        tripStorageServiceProvider.overrideWithValue(storageService),
        locationServiceProvider.overrideWithValue(locationService),
        tripRoutesServiceProvider.overrideWithValue(_FakeTripRoutesService()),
        authSessionProvider.overrideWith(
          (ref) => Stream<AuthState>.value(
            const AuthState(AuthChangeEvent.signedOut, null),
          ),
        ),
      ],
    );
  }

  group('TripActionNotifier action paths', () {
    test('startTrip captures location and returns success', () async {
      final loadRepository = _FakeLoadRepository();
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);

      final ok = await notifier.startTrip('trip-1');

      expect(ok, isTrue);
      expect(loadRepository.lastStartLat, 19.076);
      expect(loadRepository.lastStartLng, 72.8777);
      expect(container.read(tripActionProvider), isA<AsyncData<void>>());
    });

    test('markDelivered captures location and returns success', () async {
      final loadRepository = _FakeLoadRepository();
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);

      final ok = await notifier.markDelivered('trip-1');

      expect(ok, isTrue);
      expect(loadRepository.lastDeliveredLat, 19.076);
      expect(loadRepository.lastDeliveredLng, 72.8777);
      expect(container.read(tripActionProvider), isA<AsyncData<void>>());
    });

    test('uploadLr uses storage upload and load repository', () async {
      final loadRepository = _FakeLoadRepository();
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);
      final file = File('${Directory.systemTemp.path}/lr_test.jpg')
        ..writeAsBytesSync([1, 2, 3]);

      final ok = await notifier.uploadLr(tripId: 'trip-1', lrFile: file);

      expect(ok, isTrue);
      expect(storageService.lastFullPath, 'load-1/lr.jpg');
      expect(loadRepository.lastUploadLrTripId, 'trip-1');
      expect(loadRepository.lastUploadLrUrl, 'https://example.com/load-1/lr.jpg');
    });

    test('uploadPod uses storage upload and captures location', () async {
      final loadRepository = _FakeLoadRepository();
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);
      final file = File('${Directory.systemTemp.path}/pod_test.jpg')
        ..writeAsBytesSync([4, 5, 6]);

      final ok = await notifier.uploadPod(tripId: 'trip-1', podFile: file);

      expect(ok, isTrue);
      expect(storageService.lastFullPath, 'load-1/pod.jpg');
      expect(loadRepository.lastUploadPodTripId, 'trip-1');
      expect(loadRepository.lastUploadPodUrl, 'https://example.com/load-1/pod.jpg');
      expect(loadRepository.lastPodLat, 19.076);
      expect(loadRepository.lastPodLng, 72.8777);
    });

    test('uploadLr fails when related load id is missing in trip detail', () async {
      final loadRepository = _FakeLoadRepository()
        ..tripDetail = const {
          'load': <String, dynamic>{},
        };
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);
      final file = File('${Directory.systemTemp.path}/lr_missing_load.jpg')
        ..writeAsBytesSync([7, 8, 9]);

      final ok = await notifier.uploadLr(tripId: 'trip-1', lrFile: file);

      expect(ok, isFalse);
      expect(storageService.lastFullPath, isNull);
      expect(loadRepository.lastUploadLrTripId, isNull);
      expect(container.read(tripActionProvider), isA<AsyncError<void>>());
    });

    test('uploadPod fails when related load id is missing in trip detail', () async {
      final loadRepository = _FakeLoadRepository()
        ..tripDetail = const {
          'load': <String, dynamic>{},
        };
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);
      final file = File('${Directory.systemTemp.path}/pod_missing_load.jpg')
        ..writeAsBytesSync([10, 11, 12]);

      final ok = await notifier.uploadPod(tripId: 'trip-1', podFile: file);

      expect(ok, isFalse);
      expect(storageService.lastFullPath, isNull);
      expect(loadRepository.lastUploadPodTripId, isNull);
      expect(container.read(tripActionProvider), isA<AsyncError<void>>());
    });

    test('submitRating fails when no auth session is present', () async {
      final loadRepository = _FakeLoadRepository();
      final storageService = _FakeStorageService();
      final locationService = _FakeLocationService();
      final container = createContainer(
        loadRepository: loadRepository,
        storageService: storageService,
        locationService: locationService,
      );
      addTearDown(container.dispose);

      final notifier = container.read(tripActionProvider.notifier);

      final ok = await notifier.submitRating(
        loadId: 'load-1',
        revieweeId: 'trucker-1',
        reviewerRole: 'supplier',
        score: 5,
      );

      expect(ok, isFalse);
      expect(container.read(tripActionProvider), isA<AsyncError<void>>());
    });
  });
}
