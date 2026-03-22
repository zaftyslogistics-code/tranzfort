import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tranzfort/src/features/trucker/data/trip_proof_upload_service.dart';

void main() {
  test('trip proof upload service returns null success when user cancels picking image', () async {
    final service = TripProofUploadService(
      null,
      pickImageFn: (_) async => null,
      readBytesFn: (_) async => throw StateError('unused'),
      compressImageFn: (_) => throw StateError('unused'),
      uploadBinaryFn: (client, storagePath, bytes) async => throw StateError('unused'),
    );

    final result = await service.pickCompressAndUploadPod(
      tripId: 'trip-1',
      source: ImageSource.gallery,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('trip proof upload service maps invalid compressed payload to business rule failure', () async {
    final service = TripProofUploadService(
      null,
      pickImageFn: (_) async => XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'pod.jpg', mimeType: 'image/jpeg'),
      readBytesFn: (_) async => Uint8List.fromList([1, 2, 3]),
      compressImageFn: (_) => null,
      uploadBinaryFn: (client, storagePath, bytes) async => throw StateError('unused'),
    );

    final result = await service.pickCompressAndUploadPod(
      tripId: 'trip-1',
      source: ImageSource.camera,
    );

    expect(result.failureOrNull?.message, 'We could not prepare the POD image. Please try another photo.');
  });
}
