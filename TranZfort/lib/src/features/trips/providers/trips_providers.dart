import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../../core/error/result.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/storage_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../marketplace/providers/marketplace_providers.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return const LocationService();
});

final tripStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final myTripsProvider = FutureProvider.family<List<Map<String, dynamic>>, bool>(
  (ref, completed) async {
    final user = ref.watch(authSessionProvider).value?.session?.user;
    if (user == null) {
      return const [];
    }

    final result = await ref
        .watch(loadRepositoryProvider)
        .getMyTrips(truckerId: user.id, completed: completed);

    return switch (result) {
      Success(data: final data) => data,
      Failure() => const <Map<String, dynamic>>[],
    };
  },
);

final existingRatingProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, loadId) async {
      final userId = ref.watch(authSessionProvider).value?.session?.user.id;
      if (userId == null || loadId.isEmpty) {
        return null;
      }

      final result = await ref
          .watch(loadRepositoryProvider)
          .getRatingForLoad(loadId: loadId, reviewerId: userId);

      return switch (result) {
        Success(data: final data) => data,
        Failure() => null,
      };
    });

final tripDetailProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, tripId) async {
    final result = await ref.watch(loadRepositoryProvider).getTripDetail(tripId);
    return switch (result) {
      Success(data: final data) => data,
      Failure() => null,
    };
  },
);

class TripActionNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TripActionNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> startTrip(String tripId) async {
    state = const AsyncLoading();

    CapturedLocation? captured;
    try {
      captured = await _ref.read(locationServiceProvider).captureCurrentLocation();
    } catch (_) {
      captured = null;
    }

    final result = await _ref
        .read(loadRepositoryProvider)
        .startTrip(tripId: tripId, lat: captured?.lat, lng: captured?.lng);

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(tripDetailProvider(tripId));
        _ref.invalidate(myTripsProvider(false));
        _ref.invalidate(myTripsProvider(true));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Unable to start trip', StackTrace.current);
        return false;
    }
  }

  Future<bool> markDelivered(String tripId) async {
    state = const AsyncLoading();

    CapturedLocation? captured;
    try {
      captured = await _ref.read(locationServiceProvider).captureCurrentLocation();
    } catch (_) {
      captured = null;
    }

    final result = await _ref
        .read(loadRepositoryProvider)
        .markDelivered(tripId: tripId, lat: captured?.lat, lng: captured?.lng);

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(tripDetailProvider(tripId));
        _ref.invalidate(myTripsProvider(false));
        _ref.invalidate(myTripsProvider(true));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Unable to mark delivered', StackTrace.current);
        return false;
    }
  }

  Future<bool> uploadLr({required String tripId, required File lrFile}) async {
    state = const AsyncLoading();

    final detailResult = await _ref.read(loadRepositoryProvider).getTripDetail(tripId);
    late final Map<String, dynamic> detail;
    switch (detailResult) {
      case Success(data: final data):
        detail = data;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not load trip', StackTrace.current);
        return false;
    }

    final load = (detail['load'] as Map<String, dynamic>? ?? const {});
    final loadId = (load['id'] ?? '').toString();
    if (loadId.isEmpty) {
      state = AsyncError('Could not resolve related load', StackTrace.current);
      return false;
    }

    final uploadResult = await _ref.read(tripStorageServiceProvider).uploadFileAtPath(
      bucketName: 'load-documents',
      fullPath: '$loadId/lr.jpg',
      file: lrFile,
    );

    late final String lrUrl;
    switch (uploadResult) {
      case Success(data: final url):
        lrUrl = url;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not upload LR', StackTrace.current);
        return false;
    }

    final result = await _ref
        .read(loadRepositoryProvider)
        .uploadLr(tripId: tripId, lrPhotoUrl: lrUrl);

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(tripDetailProvider(tripId));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not upload LR', StackTrace.current);
        return false;
    }
  }

  Future<bool> uploadPod({required String tripId, required File podFile}) async {
    state = const AsyncLoading();

    final detailResult = await _ref.read(loadRepositoryProvider).getTripDetail(tripId);
    late final Map<String, dynamic> detail;
    switch (detailResult) {
      case Success(data: final data):
        detail = data;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not load trip', StackTrace.current);
        return false;
    }

    final load = (detail['load'] as Map<String, dynamic>? ?? const {});
    final loadId = (load['id'] ?? '').toString();
    if (loadId.isEmpty) {
      state = AsyncError('Could not resolve related load', StackTrace.current);
      return false;
    }

    final uploadResult = await _ref.read(tripStorageServiceProvider).uploadFileAtPath(
      bucketName: 'load-documents',
      fullPath: '$loadId/pod.jpg',
      file: podFile,
    );

    late final String podUrl;
    switch (uploadResult) {
      case Success(data: final url):
        podUrl = url;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not upload POD', StackTrace.current);
        return false;
    }

    CapturedLocation? captured;
    try {
      captured = await _ref.read(locationServiceProvider).captureCurrentLocation();
    } catch (_) {
      captured = null;
    }

    final result = await _ref.read(loadRepositoryProvider).uploadPod(
      tripId: tripId,
      podPhotoUrl: podUrl,
      lat: captured?.lat,
      lng: captured?.lng,
    );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(tripDetailProvider(tripId));
        _ref.invalidate(myTripsProvider(false));
        _ref.invalidate(myTripsProvider(true));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not upload POD', StackTrace.current);
        return false;
    }
  }

  Future<bool> submitRating({
    required String loadId,
    required String revieweeId,
    required String reviewerRole,
    required int score,
    String? comment,
  }) async {
    final reviewerId = _ref.read(authSessionProvider).value?.session?.user.id;
    if (reviewerId == null || revieweeId.isEmpty) {
      state = AsyncError('Could not submit rating', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    final result = await _ref.read(loadRepositoryProvider).submitRating(
      loadId: loadId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      reviewerRole: reviewerRole,
      score: score,
      comment: comment,
    );

    switch (result) {
      case Success():
        state = const AsyncData(null);
        _ref.invalidate(existingRatingProvider(loadId));
        return true;
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Could not submit rating', StackTrace.current);
        return false;
    }
  }
}

final tripActionProvider =
    StateNotifierProvider<TripActionNotifier, AsyncValue<void>>((ref) {
      return TripActionNotifier(ref);
    });
