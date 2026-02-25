import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import '../../auth/providers/auth_providers.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/error/result.dart';
import '../services/truck_model_service.dart';

final fleetDatabaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService(ref.watch(supabaseClientProvider));
});

final truckModelServiceProvider = Provider<TruckModelService>((ref) {
  return TruckModelService(ref.watch(supabaseClientProvider));
});

final fleetStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

final truckCatalogProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.watch(truckModelServiceProvider).getTruckModels();
});

final fleetProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authSessionProvider).value?.session?.user;
  if (user == null) return const [];

  final result = await ref
      .watch(fleetDatabaseServiceProvider)
      .get('trucks', filterColumn: 'owner_id', filterValue: user.id);

  return switch (result) {
    Success(data: final data) => data,
    Failure() => const <Map<String, dynamic>>[],
  };
});

final addTruckProvider =
    StateNotifierProvider<AddTruckNotifier, AsyncValue<void>>((ref) {
      return AddTruckNotifier(
        ref.watch(fleetDatabaseServiceProvider),
        ref.watch(fleetStorageServiceProvider),
        ref.watch(authSessionProvider).value?.session?.user.id,
      );
    });

class AddTruckNotifier extends StateNotifier<AsyncValue<void>> {
  AddTruckNotifier(this._db, this._storage, this._userId)
    : super(const AsyncData(null));

  final DatabaseService _db;
  final StorageService _storage;
  final String? _userId;

  Future<void> addTruck({
    required String truckNumber,
    required String bodyType,
    required int tyres,
    required double capacityTonnes,
    String? truckModelId,
    File? rcPhotoFile,
  }) async {
    if (_userId == null) {
      state = AsyncError('User not authenticated', StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    final result = await _db.insert('trucks', {
      'owner_id': _userId,
      'truck_model_id': truckModelId,
      'truck_number': truckNumber,
      'body_type': bodyType,
      'tyres': tyres,
      'capacity_tonnes': capacityTonnes,
      'status': 'pending',
    });

    switch (result) {
      case Success(data: final insertedTruck):
        if (rcPhotoFile != null) {
          final truckId = insertedTruck['id']?.toString();
          if (truckId != null && truckId.isNotEmpty) {
            final uploadResult = await _storage.uploadFileAtPath(
              bucketName: 'truck-photos',
              fullPath: '$truckId/rc.jpg',
              file: rcPhotoFile,
            );

            switch (uploadResult) {
              case Success(data: final rcUrl):
                await _db.update('trucks', truckId, {'rc_photo_url': rcUrl});
              case Failure(debugMessage: final msg):
                state = AsyncError(
                  msg ?? 'Truck added but RC upload failed',
                  StackTrace.current,
                );
                return;
            }
          }
        }

        state = const AsyncData(null);
      case Failure(debugMessage: final msg):
        state = AsyncError(msg ?? 'Failed to add truck', StackTrace.current);
    }
  }
}
