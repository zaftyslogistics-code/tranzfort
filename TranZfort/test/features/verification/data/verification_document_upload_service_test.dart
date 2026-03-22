import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tranzfort/src/features/verification/data/verification_document_upload_service.dart';
import 'package:tranzfort/src/features/verification/data/verification_repository.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  test('verification upload service returns null success when user cancels picking image', () async {
    final service = VerificationDocumentUploadService(
      null,
      pickImageFn: (_) async => null,
      readBytesFn: (_) async => throw StateError('unused'),
      compressImageFn: (_) => throw StateError('unused'),
      uploadBinaryFn: (client, storagePath, bytes) async => throw StateError('unused'),
    );

    final result = await service.pickCompressAndUploadDocument(
      profileId: 'profile-1',
      type: VerificationDocumentType.pan,
      source: ImageSource.gallery,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isNull);
  });

  test('verification upload service writes deterministic storage path for supplier business licence', () async {
    String? capturedPath;
    final client = _MockSupabaseClient();
    final service = VerificationDocumentUploadService(
      client,
      pickImageFn: (_) async => XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'doc.jpg', mimeType: 'image/jpeg'),
      readBytesFn: (_) async => Uint8List.fromList([1, 2, 3]),
      compressImageFn: (bytes) => bytes,
      uploadBinaryFn: (client, storagePath, bytes) async {
        capturedPath = storagePath;
      },
    );

    final result = await service.pickCompressAndUploadDocument(
      profileId: 'supplier-1',
      type: VerificationDocumentType.businessLicence,
      source: ImageSource.camera,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, 'supplier-1/business_licence/business_licence.jpg');
    expect(capturedPath, 'supplier-1/business_licence/business_licence.jpg');
  });
}
