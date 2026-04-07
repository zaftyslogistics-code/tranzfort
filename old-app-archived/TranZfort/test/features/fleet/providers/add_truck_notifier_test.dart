import 'dart:io';

import 'package:app/src/core/error/app_failure.dart';
import 'package:app/src/core/error/result.dart';
import 'package:app/src/core/services/database_service.dart';
import 'package:app/src/core/services/storage_service.dart';
import 'package:app/src/features/fleet/providers/fleet_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDatabaseService implements DatabaseService {
  _FakeDatabaseService();

  Result<Map<String, dynamic>>? insertResult;
  Map<String, dynamic>? lastInsertPayload;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  Future<Result<Map<String, dynamic>>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    lastInsertPayload = {'table': table, ...data};
    return insertResult ?? const Success(<String, dynamic>{'id': 'truck-1'});
  }

  @override
  Future<Result<void>> delete(String table, String id) async {
    return const Success(null);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> get(
    String table, {
    String? filterColumn,
    filterValue,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<Map<String, dynamic>>> getSingle(
    String table, {
    required String filterColumn,
    required filterValue,
  }) async {
    return Failure(AppFailureType.unknown);
  }

  @override
  Future<Result<Map<String, dynamic>>> update(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    lastUpdatePayload = {'table': table, 'id': id, ...data};
    return Success({'id': id, ...data});
  }
}

class _FakeStorageService implements StorageService {
  Result<String>? uploadAtPathResult;

  @override
  Future<Result<String>> createSignedUrl({
    required String bucketName,
    required String filePath,
    int expiresInSeconds = 3600,
  }) async {
    return Failure(AppFailureType.unknown);
  }

  @override
  Future<Result<void>> deleteFile({
    required String bucketName,
    required String filePath,
  }) async {
    return const Success(null);
  }

  @override
  Future<Result<String>> uploadFile({
    required String bucketName,
    required String folderPath,
    required File file,
    required String fileNamePrefix,
  }) async {
    return Failure(AppFailureType.unknown);
  }

  @override
  Future<Result<String>> uploadFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return uploadAtPathResult ?? const Success('https://example.com/file.jpg');
  }

  @override
  Future<Result<String>> uploadPrivateFileAtPath({
    required String bucketName,
    required String fullPath,
    required File file,
  }) async {
    return const Success('private/path');
  }
}

void main() {
  group('AddTruckNotifier', () {
    test('sets AsyncError when user is not authenticated', () async {
      final notifier = AddTruckNotifier(
        _FakeDatabaseService(),
        _FakeStorageService(),
        null,
      );

      await notifier.addTruck(
        truckNumber: 'MH12AB1234',
        bodyType: 'open',
        tyres: 10,
        capacityTonnes: 21,
      );

      expect(notifier.state, isA<AsyncError<void>>());
      expect((notifier.state as AsyncError<void>).error, 'User not authenticated');
    });

    test('inserts truck and completes when authenticated', () async {
      final fakeDb = _FakeDatabaseService();
      final fakeStorage = _FakeStorageService();
      final notifier = AddTruckNotifier(
        fakeDb,
        fakeStorage,
        'user-1',
      );

      await notifier.addTruck(
        truckNumber: 'MH12AB1234',
        bodyType: 'open',
        tyres: 10,
        capacityTonnes: 21,
      );

      expect(notifier.state, isA<AsyncData<void>>());
      expect(fakeDb.lastInsertPayload?['table'], 'trucks');
      expect(fakeDb.lastInsertPayload?['owner_id'], 'user-1');
      expect(fakeDb.lastInsertPayload?['truck_number'], 'MH12AB1234');
    });

    test('sets AsyncError when RC upload fails after truck insert', () async {
      final fakeDb = _FakeDatabaseService();
      final fakeStorage = _FakeStorageService()
        ..uploadAtPathResult = Failure(
          AppFailureType.unknown,
          debugMessage: 'Unsupported RC file type',
        );
      final notifier = AddTruckNotifier(fakeDb, fakeStorage, 'user-1');

      await notifier.addTruck(
        truckNumber: 'MH12AB1234',
        bodyType: 'open',
        tyres: 10,
        capacityTonnes: 21,
        rcPhotoFile: File('test/resources/unsupported.bin'),
      );

      expect(notifier.state, isA<AsyncError<void>>());
      expect(
        (notifier.state as AsyncError<void>).error,
        'Unsupported RC file type',
      );
      expect(fakeDb.lastInsertPayload?['table'], 'trucks');
    });

    test('uploads RC and updates truck row when rcPhotoFile is provided', () async {
      final fakeDb = _FakeDatabaseService();
      final fakeStorage = _FakeStorageService();
      final notifier = AddTruckNotifier(fakeDb, fakeStorage, 'user-1');

      await notifier.addTruck(
        truckNumber: 'MH12AB1234',
        bodyType: 'open',
        tyres: 10,
        capacityTonnes: 21,
        rcPhotoFile: File('test/resources/rc.jpg'),
      );

      expect(notifier.state, isA<AsyncData<void>>());
      expect(fakeDb.lastInsertPayload?['table'], 'trucks');
      expect(fakeDb.lastUpdatePayload?['table'], 'trucks');
      expect(fakeDb.lastUpdatePayload?['id'], 'truck-1');
      expect(
        fakeDb.lastUpdatePayload?['rc_photo_url'],
        'https://example.com/file.jpg',
      );
    });
  });
}
